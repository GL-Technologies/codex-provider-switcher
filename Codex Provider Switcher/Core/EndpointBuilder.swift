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

    /// Returns conservative Base URL candidates, ordered from most explicit to inferred.
    /// We never replace an existing version path such as /v4. If the user entered only
    /// a host/root path, /v1 is tried as a compatibility fallback.
    public static func candidateBaseURLs(from rawURL: String, brand: ProviderBrand = .automatic) -> [URL] {
        guard let normalized = normalizedBaseURL(from: rawURL) else { return [] }
        var candidates: [URL] = []

        func append(_ url: URL?) {
            guard let url else { return }
            let canonical = url.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard !candidates.contains(where: { $0.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/")) == canonical }) else { return }
            candidates.append(url)
        }

        append(normalized)

        let path = normalized.path
        if path.isEmpty || path == "/" {
            append(appendingPath("v1", to: normalized))
        }

        let resolvedBrand = brand == .automatic
            ? ProviderBrand.detected(name: "", baseURL: normalized.absoluteString)
            : brand
        if let preset = ProviderPreset.baseURL(for: resolvedBrand),
           let presetURL = normalizedBaseURL(from: preset),
           presetURL.host?.lowercased() == normalized.host?.lowercased() {
            append(presetURL)
        }

        return candidates
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
}
