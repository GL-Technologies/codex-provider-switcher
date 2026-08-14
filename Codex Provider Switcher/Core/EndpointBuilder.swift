import Foundation

public enum EndpointBuilder {
    public static func responsesURL(from baseURL: String) -> URL? {
        let trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmed),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              components.host != nil else {
            return nil
        }

        var path = components.path
        while path.count > 1 && path.hasSuffix("/") {
            path.removeLast()
        }
        if !path.lowercased().hasSuffix("/responses") {
            path = (path.isEmpty || path == "/") ? "/responses" : path + "/responses"
        }
        components.path = path
        return components.url
    }
}
