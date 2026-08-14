import Foundation

enum L10n {
    static func text(_ key: String) -> String {
        if let value = RuntimeStrings.value(for: key) { return value }
        if let value = BridgeStrings.value(for: key) { return value }
        if let value = AdaptiveStrings.value(for: key) { return value }
        return NSLocalizedString(key, tableName: "Localizable", bundle: .main, value: key, comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: Locale.current, arguments: arguments)
    }

    static func reasoning(_ value: ReasoningEffort) -> String {
        switch value {
        case .automatic: return text("reasoning.auto")
        case .minimal: return "minimal"
        case .low: return "low"
        case .medium: return "medium"
        case .high: return "high"
        case .xhigh: return "xhigh"
        }
    }

    static func authentication(_ value: AuthenticationMode) -> String {
        switch value {
        case .bearer: return text("auth.api_key")
        case .none: return text("auth.none")
        }
    }
}
