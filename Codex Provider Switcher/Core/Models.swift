import Foundation

public enum ReasoningEffort: String, Codable, CaseIterable, Identifiable, Sendable {
    case automatic
    case minimal
    case low
    case medium
    case high
    case xhigh

    public var id: String { rawValue }
}

public enum AuthenticationMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case bearer
    case none

    public var id: String { rawValue }
}

public struct ProviderProfile: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var model: String
    public var baseURL: String
    public var authentication: AuthenticationMode
    public var reasoningEffort: ReasoningEffort
    public var note: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        model: String,
        baseURL: String,
        authentication: AuthenticationMode = .bearer,
        reasoningEffort: ReasoningEffort = .automatic,
        note: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.model = model
        self.baseURL = baseURL
        self.authentication = authentication
        self.reasoningEffort = reasoningEffort
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, model, baseURL, authentication, reasoningEffort, note, createdAt, updatedAt
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        model = try c.decode(String.self, forKey: .model)
        baseURL = try c.decode(String.self, forKey: .baseURL)
        authentication = try c.decodeIfPresent(AuthenticationMode.self, forKey: .authentication) ?? .bearer
        reasoningEffort = try c.decodeIfPresent(ReasoningEffort.self, forKey: .reasoningEffort) ?? .automatic
        note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }
}

public struct BaselineMetadata: Codable, Sendable {
    public var configExisted: Bool
    public var envExisted: Bool
    public var capturedAt: Date

    public init(configExisted: Bool, envExisted: Bool, capturedAt: Date) {
        self.configExisted = configExisted
        self.envExisted = envExisted
        self.capturedAt = capturedAt
    }
}

public struct ActiveState: Codable, Sendable {
    public var mode: String
    public var profileID: UUID?
    public var updatedAt: Date

    public init(mode: String, profileID: UUID?, updatedAt: Date) {
        self.mode = mode
        self.profileID = profileID
        self.updatedAt = updatedAt
    }
}
