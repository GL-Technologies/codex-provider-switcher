import Foundation

public enum ProviderBrand: String, Codable, CaseIterable, Identifiable, Sendable {
    case automatic
    case openAI
    case anthropic
    case gemini
    case deepSeek
    case mistral
    case qwen
    case groq
    case openRouter
    case ollama
    case perplexity
    case xAI
    case azure
    case cohere
    case moonshot
    case together
    case siliconFlow
    case zhipu
    case volcengine
    case custom

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .automatic: return "Auto"
        case .openAI: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .gemini: return "Google Gemini"
        case .deepSeek: return "DeepSeek"
        case .mistral: return "Mistral AI"
        case .qwen: return "Qwen"
        case .groq: return "Groq"
        case .openRouter: return "OpenRouter"
        case .ollama: return "Ollama"
        case .perplexity: return "Perplexity"
        case .xAI: return "xAI"
        case .azure: return "Azure OpenAI"
        case .cohere: return "Cohere"
        case .moonshot: return "Moonshot / Kimi"
        case .together: return "Together AI"
        case .siliconFlow: return "SiliconFlow"
        case .zhipu: return "Zhipu AI"
        case .volcengine: return "Volcengine"
        case .custom: return "Custom"
        }
    }

    public static var selectableCases: [ProviderBrand] {
        allCases.filter { $0 != .automatic }
    }

    public static func detected(name: String, baseURL: String) -> ProviderBrand {
        let text = (name + " " + baseURL).lowercased()
        let rules: [(ProviderBrand, [String])] = [
            (.deepSeek, ["deepseek"]),
            (.anthropic, ["anthropic", "claude"]),
            (.gemini, ["gemini", "generativelanguage.googleapis", "google ai"]),
            (.mistral, ["mistral"]),
            (.qwen, ["qwen", "dashscope", "aliyun"]),
            (.groq, ["groq"]),
            (.openRouter, ["openrouter"]),
            (.ollama, ["ollama", "11434"]),
            (.perplexity, ["perplexity", "pplx"]),
            (.xAI, ["x.ai", "xai", "grok"]),
            (.azure, ["azure", "openai.azure"]),
            (.cohere, ["cohere"]),
            (.moonshot, ["moonshot", "kimi"]),
            (.together, ["together.ai", "together"]),
            (.siliconFlow, ["siliconflow"]),
            (.zhipu, ["zhipu", "bigmodel", "glm"]),
            (.volcengine, ["volcengine", "ark.cn-beijing", "doubao"]),
            (.openAI, ["api.openai.com", "openai"])
        ]

        for (brand, needles) in rules where needles.contains(where: text.contains) {
            return brand
        }
        return .custom
    }
}
