import Foundation

actor ConnectionTester {
    private struct Attempt {
        let success: Bool
        let baseURL: String
        let endpoint: String
        let statusCode: Int?
        let durationMilliseconds: Int
        let data: Data
        let errorMessage: String?
    }

    func test(profile: ProviderProfile, apiKey: String?) async -> ConnectionTestReport {
        let candidates = EndpointBuilder.candidateBaseURLs(from: profile.baseURL, brand: profile.resolvedBrand)
        guard !candidates.isEmpty else {
            return failure(titleKey: "test.invalid", messageKey: "test.invalid_url", endpoint: profile.baseURL)
        }

        let model = profile.model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !model.isEmpty else {
            return failure(titleKey: "test.invalid", messageKey: "test.missing_model", endpoint: profile.baseURL)
        }
        if profile.authentication == .bearer {
            guard let apiKey, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return failure(titleKey: "test.invalid", messageKey: "test.missing_key", endpoint: profile.baseURL)
            }
        }

        let responsesBody: [String: Any] = [
            "model": model,
            "input": "Reply with OK.",
            "max_output_tokens": 32
        ]

        var responseAttempts: [Attempt] = []
        for base in candidates {
            guard let endpoint = EndpointBuilder.responsesURL(from: base) else { continue }
            let attempt = await perform(baseURL: base, endpoint: endpoint, body: responsesBody, profile: profile, apiKey: apiKey)
            responseAttempts.append(attempt)
            if attempt.success {
                return ConnectionTestReport(
                    success: true,
                    codexCompatible: true,
                    detectedAPI: .responses,
                    title: L10n.text("test.responses_ready"),
                    message: outputText(from: attempt.data) ?? L10n.text("test.responses_ready_message"),
                    endpoint: attempt.endpoint,
                    resolvedBaseURL: attempt.baseURL,
                    statusCode: attempt.statusCode,
                    durationMilliseconds: totalDuration(responseAttempts),
                    responsePreview: preview(attempt.data)
                )
            }
        }

        let chatBody: [String: Any] = [
            "model": model,
            "messages": [["role": "user", "content": "Reply with OK."]],
            "max_tokens": 32,
            "stream": false
        ]

        var chatAttempts: [Attempt] = []
        for base in candidates {
            guard let endpoint = EndpointBuilder.chatCompletionsURL(from: base) else { continue }
            let attempt = await perform(baseURL: base, endpoint: endpoint, body: chatBody, profile: profile, apiKey: apiKey)
            chatAttempts.append(attempt)
            if attempt.success {
                return ConnectionTestReport(
                    success: true,
                    codexCompatible: false,
                    detectedAPI: .chatCompletions,
                    title: L10n.text("test.chat_only"),
                    message: L10n.text("test.chat_only_message"),
                    endpoint: attempt.endpoint,
                    resolvedBaseURL: attempt.baseURL,
                    statusCode: attempt.statusCode,
                    durationMilliseconds: totalDuration(responseAttempts) + totalDuration(chatAttempts),
                    responsePreview: preview(attempt.data)
                )
            }
        }

        let responsesDiagnostic = responseAttempts.map(diagnosticMessage).joined(separator: " | ")
        let chatDiagnostic = chatAttempts.map(diagnosticMessage).joined(separator: " | ")
        let first = responseAttempts.first ?? chatAttempts.first
        return ConnectionTestReport(
            success: false,
            codexCompatible: false,
            detectedAPI: .unknown,
            title: L10n.text("test.failed"),
            message: L10n.format("test.auto_failed", responsesDiagnostic, chatDiagnostic),
            endpoint: first?.endpoint ?? profile.baseURL,
            resolvedBaseURL: nil,
            statusCode: first?.statusCode,
            durationMilliseconds: totalDuration(responseAttempts) + totalDuration(chatAttempts),
            responsePreview: responseAttempts.compactMap { preview($0.data) }.first ?? chatAttempts.compactMap { preview($0.data) }.first
        )
    }

    private func perform(baseURL: URL, endpoint: URL, body: [String: Any], profile: ProviderProfile, apiKey: String?) async -> Attempt {
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            return Attempt(success: false, baseURL: baseURL.absoluteString, endpoint: endpoint.absoluteString, statusCode: nil, durationMilliseconds: 0, data: Data(), errorMessage: L10n.text("test.request_error"))
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("CodexProviderSwitcher/0.3.5", forHTTPHeaderField: "User-Agent")
        if profile.authentication == .bearer, let apiKey {
            request.setValue("Bearer \(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = bodyData

        let started = Date()
        do {
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 15
            config.timeoutIntervalForResource = 20
            let session = URLSession(configuration: config)
            defer { session.invalidateAndCancel() }
            let (data, response) = try await session.data(for: request)
            let elapsed = Int(Date().timeIntervalSince(started) * 1000)
            guard let http = response as? HTTPURLResponse else {
                return Attempt(success: false, baseURL: baseURL.absoluteString, endpoint: endpoint.absoluteString, statusCode: nil, durationMilliseconds: elapsed, data: data, errorMessage: L10n.text("test.invalid_response"))
            }
            return Attempt(success: (200...299).contains(http.statusCode), baseURL: baseURL.absoluteString, endpoint: endpoint.absoluteString, statusCode: http.statusCode, durationMilliseconds: elapsed, data: data, errorMessage: nil)
        } catch {
            let elapsed = Int(Date().timeIntervalSince(started) * 1000)
            let ns = error as NSError
            let message = ns.domain == NSURLErrorDomain && ns.code == NSURLErrorTimedOut
                ? L10n.text("test.timeout")
                : L10n.format("test.network", error.localizedDescription)
            return Attempt(success: false, baseURL: baseURL.absoluteString, endpoint: endpoint.absoluteString, statusCode: nil, durationMilliseconds: elapsed, data: Data(), errorMessage: message)
        }
    }

    private func failure(titleKey: String, messageKey: String, endpoint: String) -> ConnectionTestReport {
        ConnectionTestReport(success: false, codexCompatible: false, detectedAPI: .unknown, title: L10n.text(titleKey), message: L10n.text(messageKey), endpoint: endpoint, resolvedBaseURL: nil, statusCode: nil, durationMilliseconds: nil, responsePreview: nil)
    }

    private func totalDuration(_ attempts: [Attempt]) -> Int {
        attempts.reduce(0) { $0 + $1.durationMilliseconds }
    }

    private func diagnosticMessage(for attempt: Attempt) -> String {
        if let errorMessage = attempt.errorMessage { return "\(attempt.endpoint): \(errorMessage)" }
        guard let status = attempt.statusCode else { return "\(attempt.endpoint): \(L10n.text("test.invalid_response"))" }
        return "\(attempt.endpoint): \(httpMessage(status: status, server: serverMessage(from: attempt.data)))"
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
        return base + " " + server
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
