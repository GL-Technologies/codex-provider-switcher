import Foundation

struct ProviderDraft {
    var name = ""
    var model = ""
    var baseURL = ""
    var brand: ProviderBrand = .automatic
    var authentication: AuthenticationMode = .bearer
    var reasoningEffort: ReasoningEffort = .automatic
    var note = ""

    init() {}

    init(profile: ProviderProfile) {
        name = profile.name
        model = profile.model
        baseURL = profile.baseURL
        brand = profile.brand
        authentication = profile.authentication
        reasoningEffort = profile.reasoningEffort
        note = profile.note
    }

    var resolvedBrand: ProviderBrand {
        brand == .automatic ? ProviderBrand.detected(name: name, baseURL: baseURL) : brand
    }
}

enum SidebarSelection: Hashable {
    case openAI
    case provider(UUID)
}

struct AppNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

enum DetectedAPIKind {
    case responses
    case chatCompletions
    case unknown
}

struct ConnectionTestReport: Identifiable {
    let id = UUID()
    let success: Bool
    let codexCompatible: Bool
    let detectedAPI: DetectedAPIKind
    let title: String
    let message: String
    let endpoint: String
    let resolvedBaseURL: String?
    let statusCode: Int?
    let durationMilliseconds: Int?
    let responsePreview: String?
}

struct ModelDiscoveryReport {
    let models: [String]
    let resolvedBaseURL: String?
    let endpoint: String?
    let message: String

    var success: Bool { !models.isEmpty }
}
