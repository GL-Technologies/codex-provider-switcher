import SwiftUI

struct ProviderIconView: View {
    let brand: ProviderBrand
    var size: CGFloat = 34

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(LinearGradient(colors: [brand.tint, brand.tint.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                        .strokeBorder(.white.opacity(0.18), lineWidth: 0.7)
                }

            if let monogram = brand.monogram {
                Text(monogram)
                    .font(.system(size: size * 0.40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            } else {
                Image(systemName: brand.systemImage)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(brand.displayName)
    }
}

extension ProviderBrand {
    fileprivate var tint: Color {
        switch self {
        case .automatic, .custom: return Color(red: 0.34, green: 0.39, blue: 0.46)
        case .openAI: return Color(red: 0.05, green: 0.62, blue: 0.49)
        case .anthropic: return Color(red: 0.82, green: 0.43, blue: 0.30)
        case .gemini: return Color(red: 0.27, green: 0.45, blue: 0.96)
        case .deepSeek: return Color(red: 0.29, green: 0.42, blue: 0.98)
        case .mistral: return Color(red: 0.96, green: 0.42, blue: 0.14)
        case .qwen: return Color(red: 0.38, green: 0.34, blue: 0.89)
        case .groq: return Color(red: 0.94, green: 0.28, blue: 0.18)
        case .openRouter: return Color(red: 0.43, green: 0.36, blue: 0.90)
        case .ollama: return Color(red: 0.22, green: 0.24, blue: 0.27)
        case .perplexity: return Color(red: 0.08, green: 0.62, blue: 0.65)
        case .xAI: return Color(red: 0.12, green: 0.13, blue: 0.15)
        case .azure: return Color(red: 0.00, green: 0.47, blue: 0.84)
        case .cohere: return Color(red: 0.24, green: 0.45, blue: 0.35)
        case .moonshot: return Color(red: 0.15, green: 0.20, blue: 0.47)
        case .together: return Color(red: 0.66, green: 0.30, blue: 0.87)
        case .siliconFlow: return Color(red: 0.00, green: 0.61, blue: 0.78)
        case .zhipu: return Color(red: 0.18, green: 0.39, blue: 0.87)
        case .volcengine: return Color(red: 0.93, green: 0.31, blue: 0.18)
        }
    }

    fileprivate var monogram: String? {
        switch self {
        case .anthropic: return "A"
        case .mistral: return "M"
        case .qwen: return "Q"
        case .perplexity: return "P"
        case .xAI: return "X"
        case .cohere: return "C"
        case .zhipu: return "Z"
        default: return nil
        }
    }

    fileprivate var systemImage: String {
        switch self {
        case .automatic, .custom: return "network"
        case .openAI: return "sparkles"
        case .anthropic: return "a.circle.fill"
        case .gemini: return "diamond.fill"
        case .deepSeek: return "waveform.path.ecg"
        case .mistral: return "m.square.fill"
        case .qwen: return "q.circle.fill"
        case .groq: return "bolt.fill"
        case .openRouter: return "arrow.triangle.branch"
        case .ollama: return "terminal.fill"
        case .perplexity: return "scope"
        case .xAI: return "xmark"
        case .azure: return "cloud.fill"
        case .cohere: return "c.circle.fill"
        case .moonshot: return "moon.fill"
        case .together: return "point.3.connected.trianglepath.dotted"
        case .siliconFlow: return "waveform"
        case .zhipu: return "z.circle.fill"
        case .volcengine: return "flame.fill"
        }
    }
}
