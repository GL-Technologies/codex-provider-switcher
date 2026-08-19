import Foundation

public enum EndpointBuilder {
    public static func normalizedBaseURL(from rawURL: String) -> URL? {
        let trimmed = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmed),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              components.host != nil else {
            return nil
        }

        var path = components.path
        while path.count > 1 && path.hasSuffix("/") { path.removeLast() }

        for suffix in ["/chat/completions", "/responses", "/models"] {
            if path.lowercased().hasSuffix(suffix) {
                path.removeLast(suffix.count)
                break
            }
        }

        components.path = path
        components.query = nil
        components.fragment = nil
        return components.url
    }

    /// Returns Base URL candidates for a particular protocol family.
    ///
    /// The user's explicit URL is always tried first. For known providers we then add
    /// documented protocol-specific roots. This matters for vendors such as Zhipu, where
    /// Chat Completions and Responses intentionally live under different Base URLs.
    /// Finally, `/v1` is inferred only from a bare host/root URL.
    public static func candidateBaseURLs(
        from rawURL: String,
        brand: ProviderBrand = .automatic,
        family: ProviderEndpointFamily
    ) -> [URL] {
        guard let normalized = normalizedBaseURL(from: rawURL) else { return [] }
        var candidates: [URL] = []

        func append(_ url: URL?) {
            guard let url else { return }
            let canonical = canonicalString(url)
            guard !candidates.contains(where: { canonicalString($0) == canonical }) else { return }
            candidates.append(url)
        }

        append(normalized)

        let resolvedBrand = brand == .automatic
            ? ProviderBrand.detected(name: "", baseURL: normalized.absoluteString)
            : brand

        for preset in ProviderPreset.baseURLs(for: resolvedBrand, family: family) {
            guard let presetURL = normalizedBaseURL(from: preset),
                  presetURL.host?.lowercased() == normalized.host?.lowercased() else { continue }
            append(presetURL)
        }

        let path = normalized.path
        if path.isEmpty || path == "/" {
            append(appendingPath("v1", to: normalized))
        }

        return candidates
    }

    /// Backward-compatible generic candidates. Prefer protocol-specific overloads for
    /// connection testing and model discovery.
    public static func candidateBaseURLs(from rawURL: String, brand: ProviderBrand = .automatic) -> [URL] {
        candidateBaseURLs(from: rawURL, brand: brand, family: .responses)
    }

    public static func responsesURL(from baseURL: String) -> URL? {
        endpoint(from: baseURL, suffix: "/responses")
    }

    public static func chatCompletionsURL(from baseURL: String) -> URL? {
        endpoint(from: baseURL, suffix: "/chat/completions")
    }

    public static func modelsURL(from baseURL: String) -> URL? {
        endpoint(from: baseURL, suffix: "/models")
    }

    public static func responsesURL(from baseURL: URL) -> URL? {
        endpoint(from: baseURL.absoluteString, suffix: "/responses")
    }

    public static func chatCompletionsURL(from baseURL: URL) -> URL? {
        endpoint(from: baseURL.absoluteString, suffix: "/chat/completions")
    }

    public static func modelsURL(from baseURL: URL) -> URL? {
        endpoint(from: baseURL.absoluteString, suffix: "/models")
    }

    private static func appendingPath(_ component: String, to base: URL) -> URL? {
        guard var components = URLComponents(url: base, resolvingAgainstBaseURL: false) else { return nil }
        var path = components.path
        while path.count > 1 && path.hasSuffix("/") { path.removeLast() }
        path = (path.isEmpty || path == "/") ? "/\(component)" : "\(path)/\(component)"
        components.path = path
        return components.url
    }

    private static func endpoint(from rawURL: String, suffix: String) -> URL? {
        guard var components = normalizedBaseURL(from: rawURL).flatMap({ URLComponents(url: $0, resolvingAgainstBaseURL: false) }) else {
            return nil
        }
        var path = components.path
        while path.count > 1 && path.hasSuffix("/") { path.removeLast() }
        path = (path.isEmpty || path == "/") ? suffix : path + suffix
        components.path = path
        return components.url
    }

    private static func canonicalString(_ url: URL) -> String {
        url.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
}
