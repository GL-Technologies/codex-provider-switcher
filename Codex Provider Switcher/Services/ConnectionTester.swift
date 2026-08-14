import Foundation

actor ConnectionTester {
    func test(profile: ProviderProfile, apiKey: String?) async -> ConnectionTestReport {
        guard let endpoint = EndpointBuilder.responsesURL(from: profile.baseURL) else {
            return failure(titleKey: "test.invalid", messageKey: "test.invalid_url", endpoint: profile.baseURL)
        }
        let model = profile.model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !model.isEmpty else {
            return failure(titleKey: "test.invalid", messageKey: "test.missing_model", endpoint: endpoint.absoluteString)
        }
        if profile.authentication == .bearer {
            guard let apiKey, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return failure(titleKey: "test.invalid", messageKey: "test.missing_key", endpoint: endpoint.absoluteString)
            }
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("CodexProviderSwitcher/0.3.2", forHTTPHeaderField: "User-Agent")
        if profile.authentication == .bearer, let apiKey {
            request.setValue("Bearer \(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "model": model,
            "input": "Reply with OK.",
            "max_output_tokens": 32
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            return failure(titleKey: "test.failed", messageKey: "test.request_error", endpoint: endpoint.absoluteString)
        }
        request.httpBody = bodyData

        let started = Date()
        do {
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 20
            config.timeoutIntervalForResource = 25
            let session = URLSession(configuration: config)
            defer { session.invalidateAndCancel() }
            let (data, response) = try await session.data(for: request)
            let elapsed = Int(Date().timeIntervalSince(started) * 1000)
            guard let http = response as? HTTPURLResponse else {
                return ConnectionTestReport(success: false, title: L10n.text("test.failed"), message: L10n.text("test.invalid_response"), endpoint: endpoint.absoluteString, statusCode: nil, durationMilliseconds: elapsed, responsePreview: preview(data))
            }

            let status = http.statusCode
            if (200...299).contains(status) {
                return ConnectionTestReport(success: true, title: L10n.text("test.success"), message: outputText(from: data) ?? L10n.text("test.success_message"), endpoint: endpoint.absoluteString, statusCode: status, durationMilliseconds: elapsed, responsePreview: preview(data))
            }

            return ConnectionTestReport(success: false, title: L10n.text("test.failed"), message: httpMessage(status: status, server: serverMessage(from: data)), endpoint: endpoint.absoluteString, statusCode: status, durationMilliseconds: elapsed, responsePreview: preview(data))
        } catch {
            let elapsed = Int(Date().timeIntervalSince(started) * 1000)
            let ns = error as NSError
            let message = ns.domain == NSURLErrorDomain && ns.code == NSURLErrorTimedOut
                ? L10n.text("test.timeout")
                : L10n.format("test.network", error.localizedDescription)
            return ConnectionTestReport(success: false, title: L10n.text("test.failed"), message: message, endpoint: endpoint.absoluteString, statusCode: nil, durationMilliseconds: elapsed, responsePreview: nil)
        }
    }

    private func failure(titleKey: String, messageKey: String, endpoint: String) -> ConnectionTestReport {
        ConnectionTestReport(success: false, title: L10n.text(titleKey), message: L10n.text(messageKey), endpoint: endpoint, statusCode: nil, durationMilliseconds: nil, responsePreview: nil)
    }

    private func httpMessage(status: Int, server: String?) -> String {
        let base: String
        switch status {
        case 400: base = L10n.text("test.http_400")
        case 401: base = L10n.text("test.http_401")
        case 403: base = L10n.text("test.http_403")
        case 404: base = L10n.text("test.http_404")
        case 429: base = L10n.text("test.http_429")
        case 500...599: base = L10n.format("test.http_5xx", status)
        default: base = L10n.format("test.http_other", status)
        }
        guard let server, !server.isEmpty else { return base }
        return base + "\n" + server
    }

    private func serverMessage(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let error = object["error"] as? [String: Any], let message = error["message"] as? String { return message }
        if let message = object["message"] as? String { return message }
        if let detail = object["detail"] as? String { return detail }
        return nil
    }

    private func outputText(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let text = object["output_text"] as? String, !text.isEmpty { return compact(text, limit: 180) }
        guard let output = object["output"] as? [[String: Any]] else { return nil }
        var fragments: [String] = []
        for item in output {
            guard let content = item["content"] as? [[String: Any]] else { continue }
            for part in content {
                if let text = part["text"] as? String, !text.isEmpty { fragments.append(text) }
                if let text = part["output_text"] as? String, !text.isEmpty { fragments.append(text) }
            }
        }
        let joined = fragments.joined(separator: " ")
        return joined.isEmpty ? nil : compact(joined, limit: 180)
    }

    private func preview(_ data: Data) -> String? {
        guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return nil }
        return compact(text, limit: 700)
    }

    private func compact(_ text: String, limit: Int) -> String {
        let collapsed = text.replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
        guard collapsed.count > limit else { return collapsed }
        let index = collapsed.index(collapsed.startIndex, offsetBy: limit)
        return String(collapsed[..<index]) + "…"
    }
}
