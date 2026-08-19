import Foundation

public enum ProviderEndpointFamily: Sendable {
    case responses
    case chatCompletions
    case models
}

public enum ProviderPreset {
    /// Primary Base URL shown when a user chooses a known provider.
    /// Prefer native Responses because Codex can use it directly without the local bridge.
    public static func baseURL(for brand: ProviderBrand) -> String? {
        baseURLs(for: brand, family: .responses).first
            ?? baseURLs(for: brand, family: .chatCompletions).first
    }

    /// Documented protocol-specific Base URLs for providers whose OpenAI-compatible
    /// protocols do not necessarily share the same root path.
    ///
    /// These are discovery hints only. ConnectionTester still performs a real request
    /// with the selected model before deciding whether a route is usable.
    public static func baseURLs(for brand: ProviderBrand, family: ProviderEndpointFamily) -> [String] {
        switch brand {
        case .zhipu:
            switch family {
            case .responses:
                return ["https://open.bigmodel.cn/api/v1"]
            case .chatCompletions:
                return ["https://open.bigmodel.cn/api/paas/v4"]
            case .models:
                // Model listing support can vary by protocol/version, so probe both roots.
                return [
                    "https://open.bigmodel.cn/api/v1",
                    "https://open.bigmodel.cn/api/paas/v4"
                ]
            }

        default:
            guard let common = commonBaseURL(for: brand) else { return [] }
            return [common]
        }
    }

    public static func suggestedModels(for brand: ProviderBrand) -> [String] {
        switch brand {
        case .deepSeek:
            return ["deepseek-v4-pro", "deepseek-v4-flash"]
        case .zhipu:
            return ["glm-5.3", "glm-5.2", "glm-5.1", "glm-4.7"]
        default:
            return []
        }
    }

    private static func commonBaseURL(for brand: ProviderBrand) -> String? {
        switch brand {
        case .openAI: return "https://api.openai.com/v1"
        case .deepSeek: return "https://api.deepseek.com"
        case .openRouter: return "https://openrouter.ai/api/v1"
        case .groq: return "https://api.groq.com/openai/v1"
        case .mistral: return "https://api.mistral.ai/v1"
        case .moonshot: return "https://api.moonshot.cn/v1"
        case .together: return "https://api.together.xyz/v1"
        case .siliconFlow: return "https://api.siliconflow.cn/v1"
        case .xAI: return "https://api.x.ai/v1"
        case .ollama: return "http://127.0.0.1:11434/v1"
        default: return nil
        }
    }
}
