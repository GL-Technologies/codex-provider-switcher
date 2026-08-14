import CryptoKit
import Foundation

/// Stateless protocol conversion used by the localhost bridge.
///
/// The design intentionally keeps network routing separate from protocol transformation so the
/// conversion rules can be unit tested. It supports the Codex tool shapes most commonly seen in
/// current clients: functions, custom/freeform tools, tool search, and tool namespaces.
public enum BridgeTransformer {
    public enum TransformError: LocalizedError {
        case invalidChatResponse(String)

        public var errorDescription: String? {
            switch self {
            case .invalidChatResponse(let message): return message
            }
        }
    }

    public enum ToolKind: Equatable, Sendable {
        case function
        case custom
        case toolSearch
        case namespace
    }

    public struct ToolSpec: Sendable {
        public let kind: ToolKind
        public let originalName: String
        public let namespace: String?
    }

    public struct ToolContext: Sendable {
        fileprivate var byChatName: [String: ToolSpec] = [:]
        fileprivate var responseNameToChatName: [String: String] = [:]

        public init() {}

        fileprivate func spec(for chatName: String) -> ToolSpec? { byChatName[chatName] }

        fileprivate func chatName(for responseName: String, namespace: String? = nil) -> String {
            if let namespace, let mapped = responseNameToChatName["\(namespace)\u{1f}\(responseName)"] { return mapped }
            return responseNameToChatName[responseName] ?? responseName
        }
    }

    public struct RequestConversion {
        public let body: [String: Any]
        public let toolContext: ToolContext
    }

    private static let customInputKey = "input"
    private static let toolSearchName = "tool_search"
    private static let maxChatToolNameLength = 64

    public static func makeChatRequest(
        from responseRequest: [String: Any],
        profile: ProviderProfile
    ) -> RequestConversion {
        var context = buildToolContext(from: responseRequest)
        var messages: [[String: Any]] = []

        if let instructions = stringContent(responseRequest["instructions"]), !instructions.isEmpty {
            messages.append(["role": "system", "content": instructions])
        }

        if let input = responseRequest["input"] as? String {
            messages.append(["role": "user", "content": input])
        } else if let items = responseRequest["input"] as? [[String: Any]] {
            appendInputItems(items, to: &messages, context: &context)
        }

        messages = collapseSystemMessages(messages)
        if messages.isEmpty { messages = [["role": "user", "content": ""]] }

        var body: [String: Any] = [
            "model": profile.model,
            "messages": messages,
            "stream": false
        ]

        if let max = integerValue(responseRequest["max_output_tokens"]) { body["max_tokens"] = max }
        if let max = integerValue(responseRequest["max_tokens"]) { body["max_tokens"] = max }
        if let max = integerValue(responseRequest["max_completion_tokens"]) { body["max_completion_tokens"] = max }

        for key in ["temperature", "top_p", "frequency_penalty", "presence_penalty", "seed", "stop", "response_format", "n"] {
            if let value = responseRequest[key] { body[key] = value }
        }

        let chatTools = chatTools(from: responseRequest, context: context)
        if !chatTools.isEmpty {
            body["tools"] = chatTools
            if let choice = chatToolChoice(responseRequest["tool_choice"], context: context) { body["tool_choice"] = choice }
            if let parallel = responseRequest["parallel_tool_calls"] as? Bool { body["parallel_tool_calls"] = parallel }
        }

        applyReasoningHint(responseRequest: responseRequest, profile: profile, body: &body)
        return RequestConversion(body: body, toolContext: context)
    }

    public static func makeResponsesObject(
        from chat: [String: Any],
        model fallbackModel: String,
        toolContext: ToolContext
    ) throws -> [String: Any] {
        guard let choices = chat["choices"] as? [[String: Any]], let choice = choices.first,
              let message = choice["message"] as? [String: Any] else {
            throw TransformError.invalidChatResponse("Chat Completions response did not contain choices[0].message")
        }

        let responseID = responseID(from: chat["id"] as? String)
        let model = (chat["model"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? fallbackModel
        let created = integerValue(chat["created"]) ?? Int(Date().timeIntervalSince1970)
        let finishReason = choice["finish_reason"] as? String
        let status = finishReason == "length" ? "incomplete" : "completed"
        var output: [[String: Any]] = []

        let split = splitReasoningAndAnswer(message: message)
        if let reasoning = split.reasoning, !reasoning.isEmpty {
            output.append([
                "id": "rs_\(shortID())",
                "type": "reasoning",
                "summary": [["type": "summary_text", "text": reasoning]]
            ])
        }

        if !split.answer.isEmpty {
            output.append([
                "id": "msg_\(shortID())",
                "type": "message",
                "status": "completed",
                "role": "assistant",
                "content": [["type": "output_text", "text": split.answer, "annotations": []]]
            ])
        }

        if let toolCalls = message["tool_calls"] as? [[String: Any]] {
            for (index, call) in toolCalls.enumerated() {
                guard let function = call["function"] as? [String: Any],
                      let chatName = function["name"] as? String,
                      !chatName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
                let callID = (call["id"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "call_\(index)"
                let arguments = canonicalArguments(function["arguments"])
                output.append(responseToolCall(callID: callID, chatName: chatName, arguments: arguments, context: toolContext))
            }
        } else if let function = message["function_call"] as? [String: Any], let chatName = function["name"] as? String {
            output.append(responseToolCall(callID: "call_0", chatName: chatName, arguments: canonicalArguments(function["arguments"]), context: toolContext))
        }

        var response: [String: Any] = [
            "id": responseID,
            "object": "response",
            "created_at": created,
            "status": status,
            "model": model,
            "output": output,
            "usage": responsesUsage(chat["usage"])
        ]
        if status == "incomplete" { response["incomplete_details"] = ["reason": "max_output_tokens"] }
        return response
    }

    // MARK: - Request tools

    private static func buildToolContext(from request: [String: Any]) -> ToolContext {
        var context = ToolContext()
        if let tools = request["tools"] as? [[String: Any]] {
            tools.forEach { addResponseTool($0, to: &context) }
        }
        collectToolSearchOutputTools(request["input"], context: &context)
        return context
    }

    private static func addResponseTool(_ tool: [String: Any], to context: inout ToolContext) {
        let type = tool["type"] as? String ?? ""
        switch type {
        case "function":
            guard let name = toolName(tool) else { return }
            register(chatName: safeChatName(name), kind: .function, originalName: name, namespace: nil, context: &context)
        case "custom":
            guard let name = toolName(tool) else { return }
            register(chatName: safeChatName(name), kind: .custom, originalName: name, namespace: nil, context: &context)
        case "tool_search":
            register(chatName: toolSearchName, kind: .toolSearch, originalName: toolSearchName, namespace: nil, context: &context)
        case "namespace":
            guard let namespace = tool["name"] as? String,
                  let children = (tool["tools"] ?? tool["children"]) as? [[String: Any]] else { return }
            for child in children where (child["type"] as? String) == "function" {
                guard let name = toolName(child) else { continue }
                let chatName = safeChatName("\(namespace)__\(name)")
                register(chatName: chatName, kind: .namespace, originalName: name, namespace: namespace, context: &context)
            }
        default:
            break
        }
    }

    private static func register(chatName: String, kind: ToolKind, originalName: String, namespace: String?, context: inout ToolContext) {
        guard context.byChatName[chatName] == nil else { return }
        context.byChatName[chatName] = ToolSpec(kind: kind, originalName: originalName, namespace: namespace)
        if let namespace { context.responseNameToChatName["\(namespace)\u{1f}\(originalName)"] = chatName }
        else { context.responseNameToChatName[originalName] = chatName }
    }

    private static func chatTools(from request: [String: Any], context: ToolContext) -> [[String: Any]] {
        guard let tools = request["tools"] as? [[String: Any]] else { return [] }
        var result: [[String: Any]] = []
        for tool in tools {
            let type = tool["type"] as? String ?? ""
            switch type {
            case "function":
                guard let name = toolName(tool) else { continue }
                let chatName = context.chatName(for: name)
                result.append(chatFunctionTool(source: tool, chatName: chatName))
            case "custom":
                guard let name = toolName(tool) else { continue }
                let chatName = context.chatName(for: name)
                let definition = compactJSONString(tool)
                result.append([
                    "type": "function",
                    "function": [
                        "name": chatName,
                        "description": "Freeform Codex tool. Preserve the original input exactly. Original tool definition: \(definition)",
                        "parameters": [
                            "type": "object",
                            "properties": [customInputKey: ["type": "string", "description": "Raw tool input"]],
                            "required": [customInputKey]
                        ]
                    ]
                ])
            case "tool_search":
                result.append([
                    "type": "function",
                    "function": [
                        "name": toolSearchName,
                        "description": "Search and load tools for the current task.",
                        "parameters": [
                            "type": "object",
                            "properties": [
                                "query": ["type": "string"],
                                "limit": ["type": "integer"]
                            ],
                            "required": ["query"]
                        ]
                    ]
                ])
            case "namespace":
                guard let namespace = tool["name"] as? String,
                      let children = (tool["tools"] ?? tool["children"]) as? [[String: Any]] else { continue }
                for child in children where (child["type"] as? String) == "function" {
                    guard let name = toolName(child) else { continue }
                    result.append(chatFunctionTool(source: child, chatName: context.chatName(for: name, namespace: namespace)))
                }
            default:
                break
            }
        }
        return result
    }

    private static func chatFunctionTool(source: [String: Any], chatName: String) -> [String: Any] {
        var function = (source["function"] as? [String: Any]) ?? [:]
        function["name"] = chatName
        if function["description"] == nil, let description = source["description"] { function["description"] = description }
        function["parameters"] = normalizedParameters(function["parameters"] ?? source["parameters"])
        if function["strict"] == nil, let strict = source["strict"] { function["strict"] = strict }
        return ["type": "function", "function": function]
    }

    private static func chatToolChoice(_ value: Any?, context: ToolContext) -> Any? {
        if let string = value as? String { return string }
        guard let object = value as? [String: Any] else { return nil }
        let type = object["type"] as? String
        switch type {
        case "function":
            guard let name = object["name"] as? String else { return nil }
            return ["type": "function", "function": ["name": context.chatName(for: name, namespace: object["namespace"] as? String)]]
        case "custom":
            guard let name = object["name"] as? String else { return nil }
            return ["type": "function", "function": ["name": context.chatName(for: name)]]
        case "tool_search":
            return ["type": "function", "function": ["name": toolSearchName]]
        default:
            return object
        }
    }

    // MARK: - Request messages

    private static func appendInputItems(_ items: [[String: Any]], to messages: inout [[String: Any]], context: inout ToolContext) {
        var pendingToolCalls: [[String: Any]] = []

        func flush() {
            guard !pendingToolCalls.isEmpty else { return }
            messages.append(["role": "assistant", "content": NSNull(), "tool_calls": pendingToolCalls])
            pendingToolCalls.removeAll()
        }

        for item in items {
            let type = item["type"] as? String ?? "message"
            switch type {
            case "message":
                flush()
                let responseRole = item["role"] as? String ?? "user"
                let role = responseRole == "developer" ? "system" : responseRole
                messages.append(["role": role, "content": chatContent(item["content"])])

            case "function_call":
                let callID = stringValue(item["call_id"]) ?? stringValue(item["id"]) ?? "call_\(shortID())"
                let name = stringValue(item["name"]) ?? "tool"
                let namespace = stringValue(item["namespace"])
                pendingToolCalls.append([
                    "id": callID,
                    "type": "function",
                    "function": [
                        "name": context.chatName(for: name, namespace: namespace),
                        "arguments": canonicalArguments(item["arguments"])
                    ]
                ])

            case "custom_tool_call":
                let callID = stringValue(item["call_id"]) ?? stringValue(item["id"]) ?? "call_\(shortID())"
                let name = stringValue(item["name"]) ?? "tool"
                let input = stringContent(item["input"]) ?? ""
                pendingToolCalls.append([
                    "id": callID,
                    "type": "function",
                    "function": ["name": context.chatName(for: name), "arguments": compactJSONString([customInputKey: input])]
                ])

            case "tool_search_call":
                let callID = stringValue(item["call_id"]) ?? stringValue(item["id"]) ?? "call_\(shortID())"
                pendingToolCalls.append([
                    "id": callID,
                    "type": "function",
                    "function": ["name": toolSearchName, "arguments": compactJSONString(item["arguments"] ?? [:])]
                ])

            case "function_call_output", "custom_tool_call_output", "tool_search_output":
                flush()
                let callID = stringValue(item["call_id"]) ?? ""
                messages.append(["role": "tool", "tool_call_id": callID, "content": stringContent(item["output"]) ?? compactJSONString(item["output"] ?? "")])
                if type == "tool_search_output", let tools = item["tools"] as? [[String: Any]] {
                    tools.forEach { addResponseTool($0, to: &context) }
                }

            case "reasoning":
                // Reasoning items belong to the prior assistant turn. Most Chat-compatible
                // upstreams do not accept them as independent messages, so they are omitted.
                continue

            default:
                if item["role"] != nil || item["content"] != nil {
                    flush()
                    let responseRole = item["role"] as? String ?? "user"
                    messages.append(["role": responseRole == "developer" ? "system" : responseRole, "content": chatContent(item["content"])])
                }
            }
        }
        flush()
    }

    private static func collapseSystemMessages(_ messages: [[String: Any]]) -> [[String: Any]] {
        var system: [String] = []
        var rest: [[String: Any]] = []
        for message in messages {
            if (message["role"] as? String) == "system", let text = stringContent(message["content"]), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                system.append(text)
            } else {
                rest.append(message)
            }
        }
        guard !system.isEmpty else { return rest }
        return [["role": "system", "content": system.joined(separator: "\n\n")]] + rest
    }

    private static func chatContent(_ value: Any?) -> Any {
        if let string = value as? String { return string }
        guard let parts = value as? [[String: Any]] else { return stringContent(value) ?? "" }
        var chatParts: [[String: Any]] = []
        var containsMedia = false
        for part in parts {
            let type = part["type"] as? String ?? ""
            switch type {
            case "input_text", "output_text", "text":
                if let text = stringValue(part["text"]) { chatParts.append(["type": "text", "text": text]) }
            case "input_image":
                if let imageURL = part["image_url"] {
                    let normalized: Any = (imageURL as? [String: Any]) ?? ["url": stringContent(imageURL) ?? ""]
                    chatParts.append(["type": "image_url", "image_url": normalized])
                    containsMedia = true
                }
            default:
                break
            }
        }
        if containsMedia { return chatParts }
        return chatParts.compactMap { $0["text"] as? String }.joined(separator: "\n")
    }

    // MARK: - Response tools and reasoning

    private static func responseToolCall(callID: String, chatName: String, arguments: String, context: ToolContext) -> [String: Any] {
        guard let spec = context.spec(for: chatName) else {
            return [
                "id": "fc_\(shortID())", "type": "function_call", "status": "completed",
                "call_id": callID, "name": chatName, "arguments": arguments
            ]
        }
        switch spec.kind {
        case .custom:
            return [
                "id": "ctc_\(shortID())", "type": "custom_tool_call", "status": "completed",
                "call_id": callID, "name": spec.originalName, "input": customInput(from: arguments)
            ]
        case .toolSearch:
            return [
                "type": "tool_search_call", "call_id": callID, "status": "completed", "execution": "client",
                "arguments": argumentsObject(arguments)
            ]
        case .namespace, .function:
            var item: [String: Any] = [
                "id": "fc_\(shortID())", "type": "function_call", "status": "completed",
                "call_id": callID, "name": spec.originalName, "arguments": arguments
            ]
            if let namespace = spec.namespace { item["namespace"] = namespace }
            return item
        }
    }

    private static func splitReasoningAndAnswer(message: [String: Any]) -> (reasoning: String?, answer: String) {
        var reasoning = stringValue(message["reasoning_content"])
            ?? stringValue(message["reasoning"])
            ?? stringValue(message["thinking"])
        var answer = stringContent(message["content"]) ?? ""

        if reasoning == nil, let range = leadingThinkRange(in: answer) {
            reasoning = String(answer[range.reasoning])
            answer = String(answer[range.answer])
        }
        return (reasoning?.trimmingCharacters(in: .whitespacesAndNewlines), answer)
    }

    private static func leadingThinkRange(in text: String) -> (reasoning: Range<String.Index>, answer: Range<String.Index>)? {
        let trimmedStart = text.drop(while: { $0.isWhitespace })
        guard trimmedStart.hasPrefix("<think>"),
              let openEnd = trimmedStart.range(of: "<think>")?.upperBound,
              let close = trimmedStart.range(of: "</think>", range: openEnd..<trimmedStart.endIndex) else { return nil }
        let reasoning = openEnd..<close.lowerBound
        let answerStart = close.upperBound
        return (reasoning, answerStart..<trimmedStart.endIndex)
    }

    private static func responsesUsage(_ value: Any?) -> [String: Any] {
        guard let usage = value as? [String: Any] else {
            return ["input_tokens": 0, "output_tokens": 0, "total_tokens": 0]
        }
        let input = integerValue(usage["prompt_tokens"]) ?? integerValue(usage["input_tokens"]) ?? 0
        let output = integerValue(usage["completion_tokens"]) ?? integerValue(usage["output_tokens"]) ?? 0
        var result: [String: Any] = [
            "input_tokens": input,
            "output_tokens": output,
            "total_tokens": integerValue(usage["total_tokens"]) ?? input + output
        ]
        if let details = usage["prompt_tokens_details"] as? [String: Any], let cached = integerValue(details["cached_tokens"]) {
            result["input_tokens_details"] = ["cached_tokens": cached]
        }
        if let details = usage["completion_tokens_details"] as? [String: Any], let reasoning = integerValue(details["reasoning_tokens"]) {
            result["output_tokens_details"] = ["reasoning_tokens": reasoning]
        }
        return result
    }

    private static func applyReasoningHint(responseRequest: [String: Any], profile: ProviderProfile, body: inout [String: Any]) {
        let requestEffort = (responseRequest["reasoning"] as? [String: Any]).flatMap { $0["effort"] as? String }
        let effort = requestEffort ?? (profile.reasoningEffort == .automatic ? nil : profile.reasoningEffort.rawValue)
        guard let effort else { return }

        // Keep provider-specific behavior conservative. OpenRouter has a documented normalized
        // reasoning object. For other OpenAI-compatible gateways, only pass the generic field
        // when the user explicitly selected an effort in this app.
        if profile.resolvedBrand == .openRouter {
            let mapped = effort == "max" ? "xhigh" : effort
            body["reasoning"] = ["effort": mapped]
        } else if profile.reasoningEffort != .automatic {
            body["reasoning_effort"] = effort
        }
    }

    // MARK: - Utilities

    private static func toolName(_ tool: [String: Any]) -> String? {
        if let function = tool["function"] as? [String: Any], let name = function["name"] as? String, !name.isEmpty { return name }
        if let name = tool["name"] as? String, !name.isEmpty { return name }
        return nil
    }

    private static func normalizedParameters(_ value: Any?) -> [String: Any] {
        var object = value as? [String: Any] ?? [:]
        object["type"] = "object"
        if object["properties"] == nil { object["properties"] = [:] }
        return object
    }

    private static func safeChatName(_ value: String) -> String {
        if value.utf8.count <= maxChatToolNameLength { return value }
        let digest = SHA256.hash(data: Data(value.utf8)).prefix(4).map { String(format: "%02x", $0) }.joined()
        let suffix = "__\(digest)"
        var prefix = ""
        for character in value {
            let candidate = prefix + String(character)
            if candidate.utf8.count + suffix.utf8.count > maxChatToolNameLength { break }
            prefix = candidate
        }
        return prefix + suffix
    }

    private static func collectToolSearchOutputTools(_ value: Any?, context: inout ToolContext) {
        if let array = value as? [Any] {
            array.forEach { collectToolSearchOutputTools($0, context: &context) }
        } else if let object = value as? [String: Any] {
            if (object["type"] as? String) == "tool_search_output", let tools = object["tools"] as? [[String: Any]] {
                tools.forEach { addResponseTool($0, to: &context) }
            }
            object.values.forEach { collectToolSearchOutputTools($0, context: &context) }
        }
    }

    private static func customInput(from arguments: String) -> String {
        guard let data = arguments.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let input = stringContent(object[customInputKey]) else { return arguments }
        return input
    }

    private static func argumentsObject(_ arguments: String) -> [String: Any] {
        guard let data = arguments.data(using: .utf8), let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ["query": arguments]
        }
        return object
    }

    private static func canonicalArguments(_ value: Any?) -> String {
        if let string = value as? String {
            guard let data = string.data(using: .utf8), let object = try? JSONSerialization.jsonObject(with: data) else { return string }
            return compactJSONString(object)
        }
        return compactJSONString(value ?? [:])
    }

    private static func compactJSONString(_ value: Any) -> String {
        guard JSONSerialization.isValidJSONObject(value),
              let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]),
              let string = String(data: data, encoding: .utf8) else { return "{}" }
        return string
    }

    private static func integerValue(_ value: Any?) -> Int? {
        if let int = value as? Int { return int }
        if let number = value as? NSNumber { return number.intValue }
        if let string = value as? String { return Int(string) }
        return nil
    }

    private static func stringValue(_ value: Any?) -> String? { value as? String }

    private static func stringContent(_ value: Any?) -> String? {
        if let string = value as? String { return string }
        if value == nil || value is NSNull { return nil }
        if let parts = value as? [[String: Any]] {
            return parts.compactMap { part in
                stringValue(part["text"]) ?? stringValue(part["output_text"]) ?? stringValue(part["input_text"]) ?? stringValue(part["refusal"])
            }.joined(separator: "\n")
        }
        if JSONSerialization.isValidJSONObject(value as Any) { return compactJSONString(value as Any) }
        return String(describing: value!)
    }

    private static func responseID(from chatID: String?) -> String {
        guard let chatID, !chatID.isEmpty else { return "resp_bridge_\(shortID())" }
        if chatID.hasPrefix("resp_") { return chatID }
        let clean = chatID.replacingOccurrences(of: "chatcmpl-", with: "")
        return "resp_\(clean)"
    }

    private static func shortID() -> String { UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased() }
}
