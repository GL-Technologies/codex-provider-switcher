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

    public static func buildConfig(
        base: String,
        profile: ProviderProfile,
        credentialCommandPath: String? = nil
    ) -> String {
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

        // Prefer Codex's command-backed bearer-token support when the app can provide a
        // credential helper. This avoids depending on the desktop process importing a custom
        // environment variable. The bridge route uses `.none` authentication and therefore
        // intentionally has no Codex-side credential configuration at all.
        if profile.authentication == .bearer, credentialCommandPath == nil {
            lines.append("env_key = \"\(keyEnvironment)\"")
        }
        lines.append("wire_api = \"responses\"")

        if profile.authentication == .bearer, let credentialCommandPath {
            lines.append("")
            lines.append("[model_providers.\(providerID).auth]")
            lines.append("command = \"\(tomlEscape(credentialCommandPath))\"")
            lines.append("args = [\"\(tomlEscape(profile.id.uuidString.lowercased()))\"]")
            lines.append("refresh_interval_ms = 0")
            lines.append("timeout_ms = 5000")
        }

        lines.append("")
        return lines.joined(separator: "\n")
    }

    /// Builds a configuration that no longer selects a custom model provider.
    ///
    /// A historical baseline can itself contain a third-party provider (for example when
    /// an older release captured the baseline after the user had already customized Codex).
    /// Restoring that file byte-for-byte would make the UI say OpenAI while Codex still
    /// routes to the third party. This method removes the active custom-provider selection
    /// while preserving unrelated user configuration.
    public static func buildOpenAIConfig(base: String) -> String {
        let lines = base.components(separatedBy: .newlines)
        let selectedProvider = topLevelValue(for: "model_provider", in: lines)?.lowercased()
        let hadCustomProvider = selectedProvider.map { !officialProviderIDs.contains($0) } ?? false

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

            if topLevel {
                if isAssignment(trimmed, key: "model_provider") {
                    continue
                }
                if hadCustomProvider && (isAssignment(trimmed, key: "model") || isAssignment(trimmed, key: "model_reasoning_effort")) {
                    continue
                }
            }

            output.append(line)
        }

        trimBlankEdges(&output)
        return output.joined(separator: "\n")
    }

    public static func isOpenAIConfig(_ text: String) -> Bool {
        if text.contains(managedMarker) || legacyManagedMarkers.contains(where: { text.contains($0) }) {
            return false
        }
        let lines = text.components(separatedBy: .newlines)
        guard let provider = topLevelValue(for: "model_provider", in: lines)?.lowercased() else {
            return true
        }
        return officialProviderIDs.contains(provider)
    }

    public static func managedConfigUsesEnvironmentKey(_ text: String) -> Bool {
        guard text.contains("[model_providers.\(providerID)]") else { return false }
        return text.components(separatedBy: .newlines).contains { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return isAssignment(trimmed, key: "env_key") && trimmed.contains(keyEnvironment)
        }
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

        trimBlankEdges(&output)
        return output.joined(separator: "\n")
    }

    private static let officialProviderIDs: Set<String> = ["openai", "openai-chatgpt", "chatgpt"]

    private static func isTopLevelModelKey(_ line: String) -> Bool {
        let keys = ["model", "model_provider", "model_reasoning_effort"]
        return keys.contains { isAssignment(line, key: $0) }
    }

    private static func isAssignment(_ line: String, key: String) -> Bool {
        guard line.hasPrefix(key) else { return false }
        let rest = line.dropFirst(key.count)
        return rest.trimmingCharacters(in: .whitespaces).hasPrefix("=")
    }

    private static func topLevelValue(for key: String, in lines: [String]) -> String? {
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("[") { break }
            guard isAssignment(trimmed, key: key), let equal = trimmed.firstIndex(of: "=") else { continue }
            var value = String(trimmed[trimmed.index(after: equal)...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if value.hasPrefix("\"") && value.hasSuffix("\"") && value.count >= 2 {
                value.removeFirst()
                value.removeLast()
            }
            return value
        }
        return nil
    }

    private static func isManagedProviderHeader(_ line: String) -> Bool {
        line == "[model_providers.\(providerID)]" || line.hasPrefix("[model_providers.\(providerID).")
    }

    private static func trimBlankEdges(_ lines: inout [String]) {
        while lines.first?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            lines.removeFirst()
        }
        while lines.last?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            lines.removeLast()
        }
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
