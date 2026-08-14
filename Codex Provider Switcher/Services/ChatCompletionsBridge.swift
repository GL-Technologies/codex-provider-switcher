import Foundation
import Network

/// A small localhost-only bridge that lets Codex speak Responses API to providers that
/// only implement OpenAI Chat Completions.
///
/// The first version is intentionally stateless: Codex sends the conversation/tool-loop
/// items in each request and the bridge converts those items to Chat Completions messages.
/// Upstream requests are non-streaming; when Codex asks for streaming, the completed
/// upstream response is emitted as a valid Responses SSE lifecycle.
final class ChatCompletionsBridge {
    enum BridgeError: LocalizedError {
        case unavailable
        case notConfigured
        case invalidRequest(String)
        case upstream(String)

        var errorDescription: String? {
            switch self {
            case .unavailable: return "The local Responses bridge could not start."
            case .notConfigured: return "The local Responses bridge is not configured."
            case .invalidRequest(let message): return message
            case .upstream(let message): return message
            }
        }
    }

    private struct UpstreamConfiguration {
        let profile: ProviderProfile
        let apiKey: String?
    }

    private let queue = DispatchQueue(label: "CodexProviderSwitcher.ChatBridge")
    private var listener: NWListener?
    private var configuration: UpstreamConfiguration?
    private(set) var port: UInt16 = 24864

    var baseURL: String { "http://127.0.0.1:\(port)/v1" }
    var isRunning: Bool { listener != nil }

    func start(profile: ProviderProfile, apiKey: String?) async throws -> String {
        configuration = UpstreamConfiguration(profile: profile, apiKey: apiKey)
        if listener != nil { return baseURL }

        var lastError: Error?
        for candidate in 24864...24874 {
            do {
                let resolvedPort = try await startListener(port: UInt16(candidate))
                port = resolvedPort
                return baseURL
            } catch {
                lastError = error
                stop()
            }
        }
        throw lastError ?? BridgeError.unavailable
    }

    func stop() {
        listener?.cancel()
        listener = nil
        configuration = nil
    }

    private func startListener(port: UInt16) async throws -> UInt16 {
        guard let nwPort = NWEndpoint.Port(rawValue: port) else { throw BridgeError.unavailable }
        let listener = try NWListener(using: .tcp, on: nwPort)
        self.listener = listener

        return try await withCheckedThrowingContinuation { continuation in
            var completed = false
            listener.stateUpdateHandler = { [weak self] state in
                guard let self else { return }
                switch state {
                case .ready:
                    guard !completed else { return }
                    completed = true
                    continuation.resume(returning: port)
                case .failed(let error):
                    guard !completed else { return }
                    completed = true
                    self.listener = nil
                    continuation.resume(throwing: error)
                default:
                    break
                }
            }
            listener.newConnectionHandler = { [weak self] connection in
                self?.accept(connection)
            }
            listener.start(queue: queue)
        }
    }

    private func accept(_ connection: NWConnection) {
        connection.start(queue: queue)
        receive(connection, buffer: Data())
    }

    private func receive(_ connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1_048_576) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            var next = buffer
            if let data { next.append(data) }

            if let request = self.parseHTTPRequest(next) {
                self.handle(request, connection: connection)
                return
            }

            if error != nil || isComplete || next.count > 4_194_304 {
                self.sendJSON(connection, status: 400, object: ["error": ["message": "Invalid local bridge request"]])
                return
            }
            self.receive(connection, buffer: next)
        }
    }

    private struct HTTPRequest {
        let method: String
        let path: String
        let body: Data
    }

    private func parseHTTPRequest(_ data: Data) -> HTTPRequest? {
        let separator = Data("\r\n\r\n".utf8)
        guard let headerRange = data.range(of: separator),
              let headerText = String(data: data[..<headerRange.lowerBound], encoding: .utf8) else { return nil }

        let lines = headerText.components(separatedBy: "\r\n")
        guard let first = lines.first else { return nil }
        let pieces = first.split(separator: " ")
        guard pieces.count >= 2 else { return nil }
        let method = String(pieces[0]).uppercased()
        let path = String(pieces[1]).components(separatedBy: "?").first ?? String(pieces[1])

        var length = 0
        for line in lines.dropFirst() {
            let parts = line.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { continue }
            if parts[0].trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "content-length" {
                length = Int(parts[1].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            }
        }

        let bodyStart = headerRange.upperBound
        guard data.count >= bodyStart + length else { return nil }
        let body = length > 0 ? data.subdata(in: bodyStart..<(bodyStart + length)) : Data()
        return HTTPRequest(method: method, path: path, body: body)
    }

    private func handle(_ request: HTTPRequest, connection: NWConnection) {
        if request.method == "GET" && (request.path == "/models" || request.path == "/v1/models") {
            guard let profile = configuration?.profile else {
                sendJSON(connection, status: 503, object: ["error": ["message": "Bridge is not configured"]])
                return
            }
            sendJSON(connection, status: 200, object: [
                "object": "list",
                "data": [["id": profile.model, "object": "model", "owned_by": profile.name]]
            ])
            return
        }

        guard request.method == "POST", request.path == "/responses" || request.path == "/v1/responses" else {
            sendJSON(connection, status: 404, object: ["error": ["message": "Not found"]])
            return
        }
        guard let configuration else {
            sendJSON(connection, status: 503, object: ["error": ["message": "Bridge is not configured"]])
            return
        }

        Task {
            do {
                let input = try JSONSerialization.jsonObject(with: request.body) as? [String: Any] ?? [:]
                let wantsStream = input["stream"] as? Bool ?? false
                let upstreamBody = try makeChatRequest(from: input, profile: configuration.profile)
                let upstream = try await callUpstream(body: upstreamBody, configuration: configuration)
                let response = try makeResponsesObject(from: upstream, model: configuration.profile.model)
                if wantsStream {
                    sendSSE(connection, response: response)
                } else {
                    sendJSON(connection, status: 200, object: response)
                }
            } catch {
                sendJSON(connection, status: 502, object: [
                    "error": [
                        "message": error.localizedDescription,
                        "type": "bridge_error"
                    ]
                ])
            }
        }
    }

    private func makeChatRequest(from responseRequest: [String: Any], profile: ProviderProfile) throws -> [String: Any] {
        var messages: [[String: Any]] = []
        if let instructions = responseRequest["instructions"] as? String, !instructions.isEmpty {
            messages.append(["role": "system", "content": instructions])
        }

        if let input = responseRequest["input"] as? String {
            messages.append(["role": "user", "content": input])
        } else if let items = responseRequest["input"] as? [[String: Any]] {
            appendInputItems(items, to: &messages)
        }

        if messages.isEmpty {
            messages.append(["role": "user", "content": ""])
        }

        var body: [String: Any] = [
            "model": profile.model,
            "messages": messages,
            "stream": false
        ]
        if let max = responseRequest["max_output_tokens"] as? Int { body["max_tokens"] = max }
        if let temperature = responseRequest["temperature"] { body["temperature"] = temperature }
        if let topP = responseRequest["top_p"] { body["top_p"] = topP }

        if let tools = responseRequest["tools"] as? [[String: Any]] {
            let converted = tools.compactMap(convertTool)
            if !converted.isEmpty { body["tools"] = converted }
        }
        if let toolChoice = convertToolChoice(responseRequest["tool_choice"]) {
            body["tool_choice"] = toolChoice
        }
        if let parallel = responseRequest["parallel_tool_calls"] as? Bool {
            body["parallel_tool_calls"] = parallel
        }
        return body
    }

    private func appendInputItems(_ items: [[String: Any]], to messages: inout [[String: Any]]) {
        var pendingAssistantToolCalls: [[String: Any]] = []

        func flushToolCalls() {
            guard !pendingAssistantToolCalls.isEmpty else { return }
            messages.append(["role": "assistant", "content": NSNull(), "tool_calls": pendingAssistantToolCalls])
            pendingAssistantToolCalls.removeAll()
        }

        for item in items {
            let type = item["type"] as? String ?? "message"
            switch type {
            case "message":
                flushToolCalls()
                let role = item["role"] as? String ?? "user"
                let content = textContent(item["content"])
                messages.append(["role": role == "developer" ? "system" : role, "content": content])

            case "function_call":
                let callID = (item["call_id"] as? String) ?? (item["id"] as? String) ?? "call_\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
                let name = item["name"] as? String ?? "tool"
                let arguments = item["arguments"] as? String ?? "{}"
                pendingAssistantToolCalls.append([
                    "id": callID,
                    "type": "function",
                    "function": ["name": name, "arguments": arguments]
                ])

            case "function_call_output":
                flushToolCalls()
                let callID = (item["call_id"] as? String) ?? ""
                let output = textContent(item["output"])
                messages.append(["role": "tool", "tool_call_id": callID, "content": output])

            default:
                if let role = item["role"] as? String {
                    flushToolCalls()
                    messages.append(["role": role, "content": textContent(item["content"])])
                }
            }
        }
        flushToolCalls()
    }

    private func textContent(_ value: Any?) -> String {
        if let string = value as? String { return string }
        if value is NSNull || value == nil { return "" }
        if let parts = value as? [[String: Any]] {
            return parts.compactMap { part in
                if let text = part["text"] as? String { return text }
                if let text = part["output_text"] as? String { return text }
                if let text = part["input_text"] as? String { return text }
                return nil
            }.joined(separator: "\n")
        }
        if let data = try? JSONSerialization.data(withJSONObject: value as Any),
           let string = String(data: data, encoding: .utf8) { return string }
        return String(describing: value ?? "")
    }

    private func convertTool(_ tool: [String: Any]) -> [String: Any]? {
        guard (tool["type"] as? String) == "function" else { return nil }
        if let function = tool["function"] as? [String: Any] {
            return ["type": "function", "function": function]
        }
        guard let name = tool["name"] as? String else { return nil }
        var function: [String: Any] = ["name": name]
        if let description = tool["description"] { function["description"] = description }
        function["parameters"] = tool["parameters"] ?? ["type": "object", "properties": [:]]
        return ["type": "function", "function": function]
    }

    private func convertToolChoice(_ value: Any?) -> Any? {
        if let text = value as? String { return text }
        guard let object = value as? [String: Any] else { return nil }
        if (object["type"] as? String) == "function", let name = object["name"] as? String {
            return ["type": "function", "function": ["name": name]]
        }
        return nil
    }

    private func callUpstream(body: [String: Any], configuration: UpstreamConfiguration) async throws -> [String: Any] {
        guard let endpoint = EndpointBuilder.chatCompletionsURL(from: configuration.profile.baseURL) else {
            throw BridgeError.upstream("Invalid upstream Chat Completions URL")
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("CodexProviderSwitcher-Bridge/0.3.6", forHTTPHeaderField: "User-Agent")
        if configuration.profile.authentication == .bearer, let apiKey = configuration.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = 120
        sessionConfig.timeoutIntervalForResource = 180
        let session = URLSession(configuration: sessionConfig)
        defer { session.invalidateAndCancel() }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BridgeError.upstream("Invalid upstream response") }
        guard (200...299).contains(http.statusCode) else {
            let detail = String(data: data, encoding: .utf8) ?? ""
            throw BridgeError.upstream("Upstream HTTP \(http.statusCode): \(detail.prefix(800))")
        }
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BridgeError.upstream("Upstream returned invalid JSON")
        }
        return object
    }

    private func makeResponsesObject(from chat: [String: Any], model: String) throws -> [String: Any] {
        guard let choices = chat["choices"] as? [[String: Any]],
              let choice = choices.first,
              let message = choice["message"] as? [String: Any] else {
            throw BridgeError.upstream("Chat Completions response did not contain choices[0].message")
        }

        let responseID = "resp_bridge_\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())"
        var output: [[String: Any]] = []

        if let content = message["content"] as? String, !content.isEmpty {
            output.append([
                "id": "msg_\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())",
                "type": "message",
                "status": "completed",
                "role": "assistant",
                "content": [["type": "output_text", "text": content, "annotations": []]]
            ])
        }

        if let toolCalls = message["tool_calls"] as? [[String: Any]] {
            for toolCall in toolCalls {
                guard let function = toolCall["function"] as? [String: Any],
                      let name = function["name"] as? String else { continue }
                output.append([
                    "id": "fc_\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())",
                    "type": "function_call",
                    "status": "completed",
                    "call_id": (toolCall["id"] as? String) ?? "call_\(UUID().uuidString)",
                    "name": name,
                    "arguments": (function["arguments"] as? String) ?? "{}"
                ])
            }
        }

        let usage = chat["usage"] as? [String: Any] ?? [:]
        let inputTokens = usage["prompt_tokens"] as? Int ?? 0
        let outputTokens = usage["completion_tokens"] as? Int ?? 0
        let totalTokens = usage["total_tokens"] as? Int ?? inputTokens + outputTokens

        return [
            "id": responseID,
            "object": "response",
            "created_at": Int(Date().timeIntervalSince1970),
            "status": "completed",
            "model": model,
            "output": output,
            "parallel_tool_calls": true,
            "error": NSNull(),
            "incomplete_details": NSNull(),
            "usage": [
                "input_tokens": inputTokens,
                "input_tokens_details": ["cached_tokens": 0],
                "output_tokens": outputTokens,
                "output_tokens_details": ["reasoning_tokens": 0],
                "total_tokens": totalTokens
            ]
        ]
    }

    private func sendJSON(_ connection: NWConnection, status: Int, object: [String: Any]) {
        let data = (try? JSONSerialization.data(withJSONObject: object)) ?? Data("{}".utf8)
        let reason = status == 200 ? "OK" : (status == 404 ? "Not Found" : "Error")
        let header = "HTTP/1.1 \(status) \(reason)\r\nContent-Type: application/json\r\nContent-Length: \(data.count)\r\nConnection: close\r\n\r\n"
        var packet = Data(header.utf8)
        packet.append(data)
        connection.send(content: packet, completion: .contentProcessed { _ in connection.cancel() })
    }

    private func sendSSE(_ connection: NWConnection, response: [String: Any]) {
        let header = "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nCache-Control: no-cache\r\nConnection: close\r\n\r\n"
        connection.send(content: Data(header.utf8), completion: .contentProcessed { [weak self] error in
            guard error == nil, let self else { connection.cancel(); return }
            var sequence = 0
            var events: [[String: Any]] = []

            func event(_ type: String, _ fields: [String: Any] = [:]) {
                sequence += 1
                var object = fields
                object["type"] = type
                object["sequence_number"] = sequence
                events.append(object)
            }

            var created = response
            created["status"] = "in_progress"
            created["output"] = []
            event("response.created", ["response": created])

            if let outputs = response["output"] as? [[String: Any]] {
                for (index, item) in outputs.enumerated() {
                    event("response.output_item.added", ["output_index": index, "item": item])
                    if (item["type"] as? String) == "message",
                       let content = item["content"] as? [[String: Any]],
                       let part = content.first,
                       let text = part["text"] as? String,
                       let itemID = item["id"] as? String {
                        event("response.content_part.added", ["item_id": itemID, "output_index": index, "content_index": 0, "part": ["type": "output_text", "text": "", "annotations": []]])
                        event("response.output_text.delta", ["item_id": itemID, "output_index": index, "content_index": 0, "delta": text, "logprobs": []])
                        event("response.output_text.done", ["item_id": itemID, "output_index": index, "content_index": 0, "text": text, "logprobs": []])
                        event("response.content_part.done", ["item_id": itemID, "output_index": index, "content_index": 0, "part": part])
                    } else if (item["type"] as? String) == "function_call",
                              let itemID = item["id"] as? String,
                              let name = item["name"] as? String,
                              let arguments = item["arguments"] as? String {
                        event("response.function_call_arguments.delta", ["item_id": itemID, "output_index": index, "delta": arguments])
                        event("response.function_call_arguments.done", ["item_id": itemID, "output_index": index, "name": name, "arguments": arguments])
                    }
                    event("response.output_item.done", ["output_index": index, "item": item])
                }
            }
            event("response.completed", ["response": response])

            self.sendSSEEvents(events, at: 0, connection: connection)
        })
    }

    private func sendSSEEvents(_ events: [[String: Any]], at index: Int, connection: NWConnection) {
        guard index < events.count else {
            connection.send(content: Data("data: [DONE]\n\n".utf8), completion: .contentProcessed { _ in connection.cancel() })
            return
        }
        let event = events[index]
        guard let data = try? JSONSerialization.data(withJSONObject: event),
              let json = String(data: data, encoding: .utf8) else {
            sendSSEEvents(events, at: index + 1, connection: connection)
            return
        }
        connection.send(content: Data("data: \(json)\n\n".utf8), completion: .contentProcessed { [weak self] error in
            guard error == nil else { connection.cancel(); return }
            self?.sendSSEEvents(events, at: index + 1, connection: connection)
        })
    }
}
