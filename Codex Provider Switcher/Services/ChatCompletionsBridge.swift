import Foundation
import Network

/// Localhost-only Responses API bridge for OpenAI-compatible Chat Completions providers.
///
/// Networking and protocol transformation are intentionally separated. `BridgeTransformer`
/// contains the stateless conversion rules while this class owns the local listener and upstream
/// HTTP transport. The listener never binds to a public interface.
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

    private struct HTTPRequest {
        let method: String
        let path: String
        let body: Data
    }

    private let queue = DispatchQueue(label: "CodexProviderSwitcher.ChatBridge")
    private let maximumRequestBytes = 64 * 1024 * 1024
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
                port = try await startListener(port: UInt16(candidate))
                return baseURL
            } catch {
                lastError = error
                listener?.cancel()
                listener = nil
            }
        }
        configuration = nil
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
            listener.newConnectionHandler = { [weak self] connection in self?.accept(connection) }
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

            if next.count > maximumRequestBytes {
                sendJSON(connection, status: 413, object: ["error": ["message": "Local bridge request is too large"]])
                return
            }

            if let request = parseHTTPRequest(next) {
                handle(request, connection: connection)
                return
            }

            if error != nil || isComplete {
                sendJSON(connection, status: 400, object: ["error": ["message": "Invalid local bridge request"]])
                return
            }
            receive(connection, buffer: next)
        }
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

        guard length >= 0, length <= maximumRequestBytes else { return nil }
        let bodyStart = headerRange.upperBound
        guard data.count >= bodyStart + length else { return nil }
        let body = length > 0 ? data.subdata(in: bodyStart..<(bodyStart + length)) : Data()
        return HTTPRequest(method: method, path: path, body: body)
    }

    private func handle(_ request: HTTPRequest, connection: NWConnection) {
        if request.method == "GET", request.path == "/health" || request.path == "/v1/health" {
            sendJSON(connection, status: configuration == nil ? 503 : 200, object: [
                "status": configuration == nil ? "not_configured" : "ok",
                "bridge": "codex-provider-switcher",
                "port": Int(port)
            ])
            return
        }

        if request.method == "GET", request.path == "/models" || request.path == "/v1/models" {
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
                guard let input = try JSONSerialization.jsonObject(with: request.body) as? [String: Any] else {
                    throw BridgeError.invalidRequest("Responses request must be a JSON object")
                }
                let wantsStream = input["stream"] as? Bool ?? false
                let conversion = BridgeTransformer.makeChatRequest(from: input, profile: configuration.profile)
                let upstream = try await callUpstream(body: conversion.body, configuration: configuration)
                let response = try BridgeTransformer.makeResponsesObject(
                    from: upstream,
                    model: configuration.profile.model,
                    toolContext: conversion.toolContext
                )
                if wantsStream { sendSSE(connection, response: response) }
                else { sendJSON(connection, status: 200, object: response) }
            } catch {
                sendJSON(connection, status: 502, object: [
                    "error": ["message": error.localizedDescription, "type": "bridge_error"]
                ])
            }
        }
    }

    private func callUpstream(body: [String: Any], configuration: UpstreamConfiguration) async throws -> [String: Any] {
        guard let endpoint = EndpointBuilder.chatCompletionsURL(from: configuration.profile.baseURL) else {
            throw BridgeError.upstream("Invalid upstream Chat Completions URL")
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 180
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("CodexProviderSwitcher-Bridge/0.3.7", forHTTPHeaderField: "User-Agent")
        if configuration.profile.authentication == .bearer, let apiKey = configuration.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = 180
        sessionConfig.timeoutIntervalForResource = 300
        let session = URLSession(configuration: sessionConfig)
        defer { session.invalidateAndCancel() }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BridgeError.upstream("Invalid upstream response") }
        guard (200...299).contains(http.statusCode) else {
            let detail = String(data: data, encoding: .utf8) ?? ""
            throw BridgeError.upstream("Upstream HTTP \(http.statusCode): \(detail.prefix(1200))")
        }
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BridgeError.upstream("Upstream returned invalid JSON")
        }
        return object
    }

    // MARK: - Responses SSE

    private func sendSSE(_ connection: NWConnection, response: [String: Any]) {
        var events: [[String: Any]] = []
        var created = response
        created["output"] = []
        created["status"] = "in_progress"
        events.append(["type": "response.created", "response": created])

        if let output = response["output"] as? [[String: Any]] {
            for (index, item) in output.enumerated() {
                var added = item
                added["status"] = "in_progress"
                events.append(["type": "response.output_item.added", "output_index": index, "item": added])

                switch item["type"] as? String {
                case "message":
                    if let content = item["content"] as? [[String: Any]] {
                        for (contentIndex, part) in content.enumerated() {
                            if (part["type"] as? String) == "output_text", let text = part["text"] as? String {
                                events.append(["type": "response.content_part.added", "item_id": item["id"] ?? "", "output_index": index, "content_index": contentIndex, "part": ["type": "output_text", "text": "", "annotations": []]])
                                if !text.isEmpty {
                                    events.append(["type": "response.output_text.delta", "item_id": item["id"] ?? "", "output_index": index, "content_index": contentIndex, "delta": text])
                                }
                                events.append(["type": "response.output_text.done", "item_id": item["id"] ?? "", "output_index": index, "content_index": contentIndex, "text": text])
                                events.append(["type": "response.content_part.done", "item_id": item["id"] ?? "", "output_index": index, "content_index": contentIndex, "part": part])
                            }
                        }
                    }
                case "function_call":
                    let args = item["arguments"] as? String ?? "{}"
                    if !args.isEmpty {
                        events.append(["type": "response.function_call_arguments.delta", "item_id": item["id"] ?? "", "output_index": index, "delta": args])
                    }
                    events.append(["type": "response.function_call_arguments.done", "item_id": item["id"] ?? "", "output_index": index, "arguments": args])
                case "custom_tool_call":
                    let input = item["input"] as? String ?? ""
                    if !input.isEmpty {
                        events.append(["type": "response.custom_tool_call_input.delta", "item_id": item["id"] ?? "", "output_index": index, "delta": input])
                    }
                    events.append(["type": "response.custom_tool_call_input.done", "item_id": item["id"] ?? "", "output_index": index, "input": input])
                default:
                    break
                }

                events.append(["type": "response.output_item.done", "output_index": index, "item": item])
            }
        }
        events.append(["type": "response.completed", "response": response])

        let payload = events.compactMap { event -> String? in
            guard let data = try? JSONSerialization.data(withJSONObject: event), let json = String(data: data, encoding: .utf8) else { return nil }
            return "event: \(event["type"] as? String ?? "message")\ndata: \(json)\n\n"
        }.joined() + "data: [DONE]\n\n"

        sendRaw(connection, status: 200, contentType: "text/event-stream; charset=utf-8", body: Data(payload.utf8), extraHeaders: [
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no"
        ])
    }

    // MARK: - HTTP response helpers

    private func sendJSON(_ connection: NWConnection, status: Int, object: [String: Any]) {
        let data = (try? JSONSerialization.data(withJSONObject: object)) ?? Data("{}".utf8)
        sendRaw(connection, status: status, contentType: "application/json; charset=utf-8", body: data)
    }

    private func sendRaw(_ connection: NWConnection, status: Int, contentType: String, body: Data, extraHeaders: [String: String] = [:]) {
        let reason: String
        switch status {
        case 200: reason = "OK"
        case 400: reason = "Bad Request"
        case 404: reason = "Not Found"
        case 413: reason = "Payload Too Large"
        case 502: reason = "Bad Gateway"
        case 503: reason = "Service Unavailable"
        default: reason = "Error"
        }

        var header = "HTTP/1.1 \(status) \(reason)\r\nContent-Type: \(contentType)\r\nContent-Length: \(body.count)\r\nConnection: close\r\n"
        for (key, value) in extraHeaders { header += "\(key): \(value)\r\n" }
        header += "\r\n"

        var packet = Data(header.utf8)
        packet.append(body)
        connection.send(content: packet, completion: .contentProcessed { _ in connection.cancel() })
    }
}
