import AppKit
import Foundation
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var profiles: [ProviderProfile] = []
    @Published private(set) var activeProfileID: UUID?
    @Published private(set) var bridgedProfileID: UUID?
    @Published private(set) var autoBridgeEnabled: Bool
    @Published var notice: AppNotice?
    @Published var shouldOfferRestart = false
    @Published var shouldShowAccessSetup = false
    @Published var isBusy = false
    @Published var commandProfileID: UUID?

    var preferences: AppPreferences
    let configManager = ConfigManager()
    let keychain = KeychainStore()
    let tester = ConnectionTester()
    let modelDiscovery = ModelDiscoveryService()
    let systemAccess = SystemAccessService()
    let bridge = ChatCompletionsBridge()
    private lazy var repository = ProfileRepository(fileURL: configManager.profilesURL)

    init() {
        let preferences = AppPreferences()
        self.preferences = preferences
        self.autoBridgeEnabled = preferences.autoBridgeEnabled

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

        Task { @MainActor [weak self] in
            await self?.restoreBridgeIfNeeded()
        }
    }

    var isOpenAIActive: Bool { configManager.isOpenAIConfigured() }

    var activeProfile: ProviderProfile? {
        guard let activeProfileID else { return nil }
        return profiles.first(where: { $0.id == activeProfileID })
    }

    var commandProfile: ProviderProfile? {
        guard let commandProfileID else { return nil }
        return profiles.first(where: { $0.id == commandProfileID })
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

    func setAutoBridgeEnabled(_ enabled: Bool) {
        autoBridgeEnabled = enabled
        preferences.autoBridgeEnabled = enabled

        if !enabled, bridgedProfileID != nil {
            activateOpenAI()
        }
    }

    func saveProfile(original: ProviderProfile?, draft: ProviderDraft, apiKey: String) -> Bool {
        let model = draft.model.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseURL = draft.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        var name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !model.isEmpty else { return failSave("error.model_required") }
        guard EndpointBuilder.normalizedBaseURL(from: baseURL) != nil else { return failSave("error.url_invalid") }

        if name.isEmpty {
            name = generatedName(for: draft)
        }

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
                activate(profile)
            }
            refreshState()
            return true
        } catch {
            notice = AppNotice(title: L10n.text("error.save_title"), message: error.localizedDescription)
            return false
        }
    }

    /// Resolves protocol support before writing Codex configuration.
    /// Native Responses stays direct. Chat-Completions-only providers use the local bridge
    /// automatically when Auto Bridge is enabled.
    func activate(_ profile: ProviderProfile) {
        guard !isBusy else { return }
        let apiKey = profile.authentication == .bearer ? keychain.key(for: profile.id) : nil
        if profile.authentication == .bearer && (apiKey?.isEmpty ?? true) {
            notice = AppNotice(title: L10n.text("error.missing_key_title"), message: L10n.text("error.missing_key"))
            return
        }

        isBusy = true
        Task {
            let report = await tester.test(profile: profile, apiKey: apiKey)
            do {
                if report.codexCompatible {
                    bridge.stop()
                    bridgedProfileID = nil
                    var resolved = profile
                    if let base = report.resolvedBaseURL { resolved.baseURL = base }
                    try configManager.switchToProvider(resolved, apiKey: apiKey)
                } else if report.success && report.detectedAPI == .chatCompletions {
                    guard autoBridgeEnabled else {
                        throw NSError(domain: "ProviderActivation", code: 2, userInfo: [NSLocalizedDescriptionKey: L10n.text("bridge.off_message")])
                    }
                    try await activateThroughBridge(profile, resolvedBaseURL: report.resolvedBaseURL, apiKey: apiKey)
                } else {
                    throw NSError(domain: "ProviderActivation", code: 1, userInfo: [NSLocalizedDescriptionKey: report.message])
                }
                refreshState()
                offerRestartIfEnabled()
            } catch {
                notice = AppNotice(title: L10n.text("error.switch_title"), message: error.localizedDescription)
            }
            isBusy = false
        }
    }

    func activateOpenAI() {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            try configManager.switchToOpenAI()
            bridge.stop()
            bridgedProfileID = nil
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
                bridge.stop()
                bridgedProfileID = nil
                offerRestartIfEnabled()
            }
            profiles.removeAll { $0.id == profile.id }
            try repository.save(profiles)
            keychain.delete(for: profile.id)
            if commandProfileID == profile.id {
                commandProfileID = nil
            }
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

    /// Restarts the actual Codex Desktop bundle and opens a fresh thread afterwards.
    ///
    /// Codex Desktop records the model provider on a thread when that thread is created.
    /// Reopening an older OpenAI thread after switching the global config can therefore keep
    /// the old provider binding. Starting a new thread after the restart makes the new
    /// `model_provider` selection effective without modifying Codex's local thread database.
    func restartCodex() {
        let workspace = NSWorkspace.shared
        let running = workspace.runningApplications.filter { app in
            app.bundleIdentifier == "com.openai.codex"
        }
        let appURLs = Array(Set(running.compactMap(\.bundleURL)))

        Task { @MainActor in
            for app in running where !app.isTerminated {
                _ = app.terminate()
            }

            for _ in 0..<40 {
                if running.allSatisfy(\.isTerminated) { break }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }

            for app in running where !app.isTerminated {
                _ = app.forceTerminate()
            }

            for _ in 0..<20 {
                if running.allSatisfy(\.isTerminated) { break }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }

            let configuration = NSWorkspace.OpenConfiguration()
            if appURLs.isEmpty {
                // The URL scheme is registered by Codex Desktop and also launches the app if it
                // is currently closed.
                if let newThreadURL = URL(string: "codex://threads/new") {
                    workspace.open(newThreadURL)
                }
                return
            }

            for url in appURLs {
                await withCheckedContinuation { continuation in
                    workspace.openApplication(at: url, configuration: configuration) { _, _ in
                        continuation.resume()
                    }
                }
            }

            // Give the newly launched app a brief moment to register its URL handler before
            // requesting a fresh thread. This avoids resuming a stale thread whose provider was
            // captured before the switch.
            try? await Task.sleep(nanoseconds: 700_000_000)
            if let newThreadURL = URL(string: "codex://threads/new") {
                workspace.open(newThreadURL)
            }
        }
    }

    private func activateThroughBridge(_ profile: ProviderProfile, resolvedBaseURL: String?, apiKey: String?) async throws {
        var upstream = profile
        if let resolvedBaseURL { upstream.baseURL = resolvedBaseURL }
        let localBase = try await bridge.start(profile: upstream, apiKey: apiKey)
        let bridged = ProviderProfile(
            id: profile.id,
            name: profile.name + " Bridge",
            model: profile.model,
            baseURL: localBase,
            brand: profile.brand,
            authentication: .none,
            reasoningEffort: profile.reasoningEffort,
            note: profile.note,
            createdAt: profile.createdAt,
            updatedAt: Date()
        )
        try configManager.switchToProvider(bridged, apiKey: nil)
        bridgedProfileID = profile.id
    }

    private func restoreBridgeIfNeeded() async {
        guard configManager.isManaged(), configManager.isConfiguredForLocalBridge(), let id = activeProfileID, let profile = profile(id: id) else {
            return
        }

        guard autoBridgeEnabled else {
            activateOpenAI()
            return
        }

        let apiKey = profile.authentication == .bearer ? keychain.key(for: profile.id) : nil
        guard profile.authentication == .none || !(apiKey?.isEmpty ?? true) else { return }

        do {
            try await activateThroughBridge(profile, resolvedBaseURL: nil, apiKey: apiKey)
            refreshState()
        } catch {
            notice = AppNotice(title: L10n.text("error.switch_title"), message: error.localizedDescription)
        }
    }

    private func generatedName(for draft: ProviderDraft) -> String {
        if draft.brand != .automatic && draft.brand != .custom { return draft.brand.displayName }
        if let host = URL(string: draft.baseURL)?.host, !host.isEmpty {
            let parts = host.split(separator: ".")
            if parts.count >= 2 { return String(parts[parts.count - 2]).capitalized }
            return host
        }
        return draft.model.isEmpty ? "Provider" : draft.model
    }

    private func refreshState() {
        if configManager.isOpenAIConfigured() {
            activeProfileID = nil
            bridgedProfileID = nil
            return
        }

        activeProfileID = configManager.activeProfileID()
        if !configManager.isConfiguredForLocalBridge() {
            bridgedProfileID = nil
        }
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
