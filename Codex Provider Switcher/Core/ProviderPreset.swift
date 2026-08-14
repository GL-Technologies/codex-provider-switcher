import Foundation

public enum ProviderPreset {
    public static func baseURL(for brand: ProviderBrand) -> String? {
        switch brand {
        case .openAI: return "https://api.openai.com/v1"
        case .deepSeek: return "https://api.deepseek.com"
        case .zhipu: return "https://open.bigmodel.cn/api/paas/v4"
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

    public static func suggestedModels(for brand: ProviderBrand) -> [String] {
        switch brand {
        case .deepSeek: return ["deepseek-v4-pro", "deepseek-v4-flash"]
        case .zhipu: return ["glm-5.2", "glm-5.1", "glm-4.7"]
        default: return []
        }
    }
}
