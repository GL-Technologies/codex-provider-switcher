import Foundation

actor ModelDiscoveryService {
    func discover(baseURL: String, brand: ProviderBrand, authentication: AuthenticationMode, apiKey: String?) async -> ModelDiscoveryReport {
        let candidates = EndpointBuilder.candidateBaseURLs(
            from: baseURL,
            brand: brand,
            family: .models
        )
        guard !candidates.isEmpty else {
            return ModelDiscoveryReport(models: [], resolvedBaseURL: nil, endpoint: nil, message: L10n.text("models.invalid_url"))
        }

        if authentication == .bearer {
            guard let apiKey, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return ModelDiscoveryReport(models: [], resolvedBaseURL: nil, endpoint: nil, message: L10n.text("models.missing_key"))
            }
        }

        var diagnostics: [String] = []
        for candidate in candidates {
            guard let endpoint = EndpointBuilder.modelsURL(from: candidate) else { continue }
            var request = URLRequest(url: endpoint)
            request.httpMethod = "GET"
            request.timeoutInterval = 12
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("CodexProviderSwitcher/0.3.14", forHTTPHeaderField: "User-Agent")
            if authentication == .bearer, let apiKey {
                request.setValue("Bearer \(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")
            }

            do {
                let config = URLSessionConfiguration.ephemeral
                config.timeoutIntervalForRequest = 12
                config.timeoutIntervalForResource = 15
                let session = URLSession(configuration: config)
                defer { session.invalidateAndCancel() }
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    diagnostics.append("\(endpoint.absoluteString): invalid response")
                    continue
                }
                guard (200...299).contains(http.statusCode) else {
                    diagnostics.append("\(endpoint.absoluteString): HTTP \(http.statusCode)")
                    continue
                }

                let models = parseModels(data)
                if !models.isEmpty {
                    return ModelDiscoveryReport(
                        models: models,
                        resolvedBaseURL: candidate.absoluteString,
                        endpoint: endpoint.absoluteString,
                        message: L10n.format("models.found", models.count)
                    )
                }
                diagnostics.append("\(endpoint.absoluteString): no model IDs")
            } catch {
                diagnostics.append("\(endpoint.absoluteString): \(error.localizedDescription)")
            }
        }

        return ModelDiscoveryReport(
            models: [],
            resolvedBaseURL: nil,
            endpoint: nil,
            message: diagnostics.isEmpty ? L10n.text("models.unsupported") : L10n.format("models.failed", diagnostics.joined(separator: " | "))
        )
    }

    private func parseModels(_ data: Data) -> [String] {
        guard let object = try? JSONSerialization.jsonObject(with: data) else { return [] }
        var ids: [String] = []

        if let dict = object as? [String: Any] {
            if let data = dict["data"] as? [[String: Any]] {
                ids.append(contentsOf: data.compactMap { $0["id"] as? String })
            }
            if let models = dict["models"] as? [[String: Any]] {
                ids.append(contentsOf: models.compactMap { ($0["id"] as? String) ?? ($0["name"] as? String) })
            }
            if let modelStrings = dict["models"] as? [String] {
                ids.append(contentsOf: modelStrings)
            }
        } else if let array = object as? [[String: Any]] {
            ids.append(contentsOf: array.compactMap { ($0["id"] as? String) ?? ($0["name"] as? String) })
        }

        let cleaned = ids
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Array(Set(cleaned)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}
