import Foundation

public enum ConfigComposer {
    public static let managedMarker = "# Managed by Codex Provider Switcher"
    public static let activeMarkerPrefix = "# Active profile: "
    public static let providerID = "codex_compat_active"
    public static let providerDisplayName = "OpenAI Responses Compatible"
    public static let keyEnvironment = "CODEX_COMPAT_API_KEY"

    public static let legacyManagedMarkers = [
        "# Managed by Codex Interface Manager v3",
        "# Managed by Codex Interface Switcher"
    ]

    public static func buildConfig(base: String, profile: ProviderProfile) -> String {
        let cleanBase = stripManagedContent(from: base)
        let normalizedBaseURL = EndpointBuilder.normalizedBaseURL(from: profile.baseURL)?.absoluteString ?? profile.baseURL
        var lines: [String] = [
            managedMarker,
            activeMarkerPrefix + profile.id.uuidString.lowercased(),
            "model = \"\(tomlEscape(profile.model))\"",
            "model_provider = \"\(providerID)\""
        ]

        if profile.reasoningEffort != .automatic {
            lines.append("model_reasoning_effort = \"\(profile.reasoningEffort.rawValue)\"")
        }

        if !cleanBase.isEmpty {
            lines.append("")
            lines.append(cleanBase)
        }

        lines.append("")
        lines.append("[model_providers.\(providerID)]")
        lines.append("name = \"\(tomlEscape(profile.name.isEmpty ? providerDisplayName : profile.name))\"")
        lines.append("base_url = \"\(tomlEscape(normalizedBaseURL))\"")
        if profile.authentication == .bearer {
            lines.append("env_key = \"\(keyEnvironment)\"")
        }
        lines.append("wire_api = \"responses\"")
        lines.append("")
        return lines.joined(separator: "\n")
    }

    public static func buildEnvironment(base: String, apiKey: String?) -> String {
        let rawLines = base.components(separatedBy: .newlines)
        let prefix = keyEnvironment + "="
        var lines = rawLines.filter { line in
            !line.trimmingCharacters(in: .whitespaces).hasPrefix(prefix)
        }
        while lines.last?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            lines.removeLast()
        }

        if let apiKey, !apiKey.isEmpty {
            if !lines.isEmpty { lines.append("") }
            lines.append("\(keyEnvironment)=\"\(dotenvEscape(apiKey))\"")
        }
        if lines.isEmpty { return "" }
        return lines.joined(separator: "\n") + "\n"
    }

    public static func stripManagedContent(from text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var output: [String] = []
        var topLevel = true
        var skippingManagedProvider = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("[") {
                topLevel = false
                if isManagedProviderHeader(trimmed) {
                    skippingManagedProvider = true
                    continue
                }
                skippingManagedProvider = false
            }

            if skippingManagedProvider { continue }

            if trimmed == managedMarker || legacyManagedMarkers.contains(trimmed) || trimmed.hasPrefix(activeMarkerPrefix) {
                continue
            }

            if topLevel && isTopLevelModelKey(trimmed) {
                continue
            }

            output.append(line)
        }

        while output.first?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            output.removeFirst()
        }
        while output.last?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            output.removeLast()
        }
        return output.joined(separator: "\n")
    }

    private static func isTopLevelModelKey(_ line: String) -> Bool {
        let keys = ["model", "model_provider", "model_reasoning_effort"]
        return keys.contains { key in
            guard line.hasPrefix(key) else { return false }
            let rest = line.dropFirst(key.count)
            return rest.trimmingCharacters(in: .whitespaces).hasPrefix("=")
        }
    }

    private static func isManagedProviderHeader(_ line: String) -> Bool {
        line == "[model_providers.\(providerID)]" || line.hasPrefix("[model_providers.\(providerID).")
    }

    private static func tomlEscape(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
    }

    private static func dotenvEscape(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
    }
}
