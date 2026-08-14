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

        for suffix in ["/chat/completions", "/responses"] {
            if path.lowercased().hasSuffix(suffix) {
                path.removeLast(suffix.count)
                break
            }
        }

        if path.isEmpty { path = "" }
        components.path = path
        components.query = nil
        components.fragment = nil
        return components.url
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
