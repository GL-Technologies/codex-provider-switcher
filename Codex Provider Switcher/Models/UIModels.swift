import Foundation

struct ProviderDraft {
    var name = ""
    var model = ""
    var baseURL = ""
    var authentication: AuthenticationMode = .bearer
    var reasoningEffort: ReasoningEffort = .automatic
    var note = ""

    init() {}

    init(profile: ProviderProfile) {
        name = profile.name
        model = profile.model
        baseURL = profile.baseURL
        authentication = profile.authentication
        reasoningEffort = profile.reasoningEffort
        note = profile.note
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

struct ConnectionTestReport: Identifiable {
    let id = UUID()
    let success: Bool
    let title: String
    let message: String
    let endpoint: String
    let statusCode: Int?
    let durationMilliseconds: Int?
    let responsePreview: String?
}
