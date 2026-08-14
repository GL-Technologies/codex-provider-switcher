import AppKit
import Foundation
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var profiles: [ProviderProfile] = []
    @Published private(set) var activeProfileID: UUID?
    @Published var notice: AppNotice?
    @Published var shouldOfferRestart = false
    @Published var shouldShowAccessSetup = false
    @Published var isBusy = false

    var preferences = AppPreferences()
    let configManager = ConfigManager()
    let keychain = KeychainStore()
    let tester = ConnectionTester()
    let modelDiscovery = ModelDiscoveryService()
    let systemAccess = SystemAccessService()
    private lazy var repository = ProfileRepository(fileURL: configManager.profilesURL)

    init() {
        do {
            try configManager.prepareDirectories()
            profiles = repository.load()
            if profiles.isEmpty, let imported = configManager.legacyProfileSeed() {
                profiles = [imported]
                try repository.save(profiles)
                keychain.migrateLegacyGlobalKey(to: imported.id)
            }
            refreshState()
            shouldShowAccessSetup = !preferences.accessSetupCompleted
        } catch {
            notice = AppNotice(title: L10n.text("error.init_title"), message: error.localizedDescription)
        }
    }

    var isOpenAIActive: Bool { !configManager.isManaged() }

    var activeProfile: ProviderProfile? {
        guard let activeProfileID else { return nil }
        return profiles.first(where: { $0.id == activeProfileID })
    }

    func profile(id: UUID) -> ProviderProfile? {
        profiles.first(where: { $0.id == id })
    }

    func refresh() {
        profiles = repository.load()
        refreshState()
    }

    func key(for profile: ProviderProfile) -> String {
        keychain.key(for: profile.id) ?? ""
    }

    func hasKey(for profile: ProviderProfile) -> Bool {
        profile.authentication == .none || keychain.hasKey(for: profile.id)
    }

    func completeAccessSetup() {
        preferences.accessSetupCompleted = true
        shouldShowAccessSetup = false
    }

    func showAccessSetup() {
        shouldShowAccessSetup = true
    }

    func saveProfile(original: ProviderProfile?, draft: ProviderDraft, apiKey: String) -> Bool {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let model = draft.model.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseURL = draft.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty else { return failSave("error.name_required") }
        guard !model.isEmpty else { return failSave("error.model_required") }
        guard EndpointBuilder.normalizedBaseURL(from: baseURL) != nil else { return failSave("error.url_invalid") }

        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if draft.authentication == .bearer && cleanKey.isEmpty && original == nil {
            return failSave("error.missing_key")
        }

        let now = Date()
        var profile: ProviderProfile
        if var original {
            original.name = name
            original.model = model
            original.baseURL = baseURL
            original.brand = draft.brand == .automatic ? ProviderBrand.detected(name: name, baseURL: baseURL) : draft.brand
            original.authentication = draft.authentication
            original.reasoningEffort = draft.reasoningEffort
            original.note = draft.note.trimmingCharacters(in: .whitespacesAndNewlines)
            original.updatedAt = now
            profile = original
        } else {
            profile = ProviderProfile(
                name: name,
                model: model,
                baseURL: baseURL,
                brand: draft.brand,
                authentication: draft.authentication,
                reasoningEffort: draft.reasoningEffort,
                note: draft.note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }

        do {
            if draft.authentication == .bearer && !cleanKey.isEmpty {
                try keychain.save(cleanKey, for: profile.id)
            } else if draft.authentication == .none {
                keychain.delete(for: profile.id)
            }

            if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
                profiles[index] = profile
            } else {
                profiles.append(profile)
            }
            sortProfiles()
            try repository.save(profiles)

            if activeProfileID == profile.id && configManager.isManaged() {
                let key = profile.authentication == .bearer ? keychain.key(for: profile.id) : nil
                try configManager.switchToProvider(profile, apiKey: key)
                offerRestartIfEnabled()
            }
            refreshState()
            return true
        } catch {
            notice = AppNotice(title: L10n.text("error.save_title"), message: error.localizedDescription)
            return false
        }
    }

    func activate(_ profile: ProviderProfile) {
        let apiKey = profile.authentication == .bearer ? keychain.key(for: profile.id) : nil
        if profile.authentication == .bearer && (apiKey?.isEmpty ?? true) {
            notice = AppNotice(title: L10n.text("error.missing_key_title"), message: L10n.text("error.missing_key"))
            return
        }

        isBusy = true
        defer { isBusy = false }
        do {
            try configManager.switchToProvider(profile, apiKey: apiKey)
            refreshState()
            offerRestartIfEnabled()
        } catch {
            notice = AppNotice(title: L10n.text("error.switch_title"), message: error.localizedDescription)
        }
    }

    func activateOpenAI() {
        isBusy = true
        defer { isBusy = false }
        do {
            try configManager.switchToOpenAI()
            refreshState()
            offerRestartIfEnabled()
        } catch {
            notice = AppNotice(title: L10n.text("error.restore_title"), message: error.localizedDescription)
        }
    }

    func duplicate(_ profile: ProviderProfile) -> ProviderProfile? {
        let copy = ProviderProfile(
            name: L10n.format("provider.copy_name", profile.name),
            model: profile.model,
            baseURL: profile.baseURL,
            brand: profile.brand,
            authentication: profile.authentication,
            reasoningEffort: profile.reasoningEffort,
            note: profile.note
        )
        do {
            profiles.append(copy)
            sortProfiles()
            try repository.save(profiles)
            return copy
        } catch {
            notice = AppNotice(title: L10n.text("error.save_title"), message: error.localizedDescription)
            return nil
        }
    }

    func delete(_ profile: ProviderProfile) {
        do {
            if activeProfileID == profile.id && configManager.isManaged() {
                try configManager.switchToOpenAI()
                offerRestartIfEnabled()
            }
            profiles.removeAll { $0.id == profile.id }
            try repository.save(profiles)
            keychain.delete(for: profile.id)
            refreshState()
        } catch {
            notice = AppNotice(title: L10n.text("error.delete_title"), message: error.localizedDescription)
        }
    }

    func test(profile: ProviderProfile) async -> ConnectionTestReport {
        await tester.test(profile: profile, apiKey: profile.authentication == .bearer ? keychain.key(for: profile.id) : nil)
    }

    func test(draft: ProviderDraft, apiKey: String) async -> ConnectionTestReport {
        let profile = ProviderProfile(
            name: draft.name,
            model: draft.model,
            baseURL: draft.baseURL,
            brand: draft.brand,
            authentication: draft.authentication,
            reasoningEffort: draft.reasoningEffort,
            note: draft.note
        )
        return await tester.test(profile: profile, apiKey: draft.authentication == .bearer ? apiKey : nil)
    }

    func discoverModels(draft: ProviderDraft, apiKey: String) async -> ModelDiscoveryReport {
        await modelDiscovery.discover(
            baseURL: draft.baseURL,
            brand: draft.resolvedBrand,
            authentication: draft.authentication,
            apiKey: draft.authentication == .bearer ? apiKey : nil
        )
    }

    func restartCodex() {
        let workspace = NSWorkspace.shared
        let running = workspace.runningApplications.filter { app in
            app.localizedName == "Codex" || app.localizedName == "ChatGPT"
        }
        let appURLs = running.compactMap(\.bundleURL)
        running.forEach { $0.terminate() }

        guard !appURLs.isEmpty else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            let configuration = NSWorkspace.OpenConfiguration()
            for url in appURLs {
                workspace.openApplication(at: url, configuration: configuration) { _, _ in }
            }
        }
    }

    private func refreshState() {
        activeProfileID = configManager.activeProfileID()
    }

    private func sortProfiles() {
        profiles.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func failSave(_ key: String) -> Bool {
        notice = AppNotice(title: L10n.text("error.save_title"), message: L10n.text(key))
        return false
    }

    private func offerRestartIfEnabled() {
        if preferences.offerRestartAfterSwitch { shouldOfferRestart = true }
    }
}
