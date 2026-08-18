import AppKit
import Foundation

final class ConfigManager {
    let homeURL: URL
    let codexURL: URL
    let stateURL: URL
    let backupURL: URL
    let profilesURL: URL

    private let configURL: URL
    private let envURL: URL
    private let baselineConfigURL: URL
    private let baselineEnvURL: URL
    private let baselineMetadataURL: URL
    private let activeStateURL: URL
    private let runtimeCredentialURL: URL

    private let legacyManagerURL: URL
    private let legacySwitcherURL: URL

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        homeURL = FileManager.default.homeDirectoryForCurrentUser
        codexURL = homeURL.appendingPathComponent(".codex", isDirectory: true)
        stateURL = codexURL.appendingPathComponent("provider-switcher", isDirectory: true)
        backupURL = stateURL.appendingPathComponent("backups", isDirectory: true)
        profilesURL = stateURL.appendingPathComponent("profiles.json")

        configURL = codexURL.appendingPathComponent("config.toml")
        envURL = codexURL.appendingPathComponent(".env")
        baselineConfigURL = stateURL.appendingPathComponent("baseline.config.toml")
        baselineEnvURL = stateURL.appendingPathComponent("baseline.env")
        baselineMetadataURL = stateURL.appendingPathComponent("baseline.json")
        activeStateURL = stateURL.appendingPathComponent("active.json")
        runtimeCredentialURL = stateURL.appendingPathComponent("runtime-credentials", isDirectory: true)

        legacyManagerURL = codexURL.appendingPathComponent("interface-manager", isDirectory: true)
        legacySwitcherURL = codexURL.appendingPathComponent("interface-switcher", isDirectory: true)

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func prepareDirectories() throws {
        try FileManager.default.createDirectory(at: codexURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: stateURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: backupURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: runtimeCredentialURL, withIntermediateDirectories: true)
        try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: stateURL.path)
        try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: backupURL.path)
        try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: runtimeCredentialURL.path)
        try migrateFromV31IfNeeded()
        try migrateFromV2IfNeeded()
    }

    func isManaged() -> Bool {
        guard let text = try? String(contentsOf: configURL, encoding: .utf8) else { return false }
        return text.contains(ConfigComposer.managedMarker) || ConfigComposer.legacyManagedMarkers.contains { text.contains($0) }
    }

    func isOpenAIConfigured() -> Bool {
        guard FileManager.default.fileExists(atPath: configURL.path) else { return true }
        guard let text = try? String(contentsOf: configURL, encoding: .utf8) else { return false }
        return ConfigComposer.isOpenAIConfig(text)
    }

    func activeProfileID() -> UUID? {
        if let text = try? String(contentsOf: configURL, encoding: .utf8) {
            for line in text.components(separatedBy: .newlines) {
                if line.hasPrefix(ConfigComposer.activeMarkerPrefix) {
                    let raw = String(line.dropFirst(ConfigComposer.activeMarkerPrefix.count)).trimmingCharacters(in: .whitespaces)
                    if let id = UUID(uuidString: raw) { return id }
                }
            }
        }
        guard let state = loadActiveState(), state.mode == "provider" else { return nil }
        return state.profileID
    }

    func baselineAvailable() -> Bool {
        FileManager.default.fileExists(atPath: baselineMetadataURL.path)
    }

    func switchToProvider(_ profile: ProviderProfile, apiKey: String?) throws {
        try prepareDirectories()

        let cleanKey = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines)
        if profile.authentication == .bearer {
            guard let cleanKey, !cleanKey.isEmpty else {
                throw NSError(domain: "ConfigManager", code: 1, userInfo: [NSLocalizedDescriptionKey: L10n.text("error.missing_key")])
            }
            guard !cleanKey.contains("\n") && !cleanKey.contains("\r") else {
                throw NSError(domain: "ConfigManager", code: 2, userInfo: [NSLocalizedDescriptionKey: L10n.text("error.key_newline")])
            }
        }

        try backupCurrent(reason: "switch")
        if !isManaged() {
            try captureBaseline()
        } else if !baselineAvailable() {
            throw NSError(domain: "ConfigManager", code: 3, userInfo: [NSLocalizedDescriptionKey: L10n.text("error.missing_baseline")])
        }

        try clearRuntimeCredentials()
        var credentialArguments: [String] = []
        var credentialCommand: String?
        if profile.authentication == .bearer, let cleanKey {
            let tokenURL = runtimeCredentialURL.appendingPathComponent("\(profile.id.uuidString.lowercased()).token")
            try atomicWrite(cleanKey + "\n", to: tokenURL, permissions: 0o600)
            credentialCommand = "/bin/cat"
            credentialArguments = [tokenURL.path]
        }

        // Build from the current config so unrelated Codex preferences are retained while the
        // previous managed provider block/model keys are replaced.
        let currentConfig = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
        let config = ConfigComposer.buildConfig(
            base: currentConfig,
            profile: profile,
            credentialCommandPath: credentialCommand,
            credentialCommandArguments: credentialArguments
        )
        try atomicWrite(config, to: configURL, permissions: 0o600)

        // Remove legacy environment-key material. New direct providers use Codex's supported
        // command-backed bearer-token auth, and bridge providers require no Codex-side key.
        let currentEnv = (try? String(contentsOf: envURL, encoding: .utf8)) ?? ""
        let env = ConfigComposer.buildEnvironment(base: currentEnv, apiKey: nil)
        if env.isEmpty {
            try? FileManager.default.removeItem(at: envURL)
        } else {
            try atomicWrite(env, to: envURL, permissions: 0o600)
        }

        try saveActiveState(ActiveState(mode: "provider", profileID: profile.id, updatedAt: Date()))
    }

    func switchToOpenAI() throws {
        try prepareDirectories()
        try backupCurrent(reason: "restore")
        let metadata = loadBaselineMetadata()

        let sourceConfig: String
        if let text = try? String(contentsOf: configURL, encoding: .utf8) {
            sourceConfig = text
        } else if metadata?.configExisted == true,
                  FileManager.default.fileExists(atPath: baselineConfigURL.path),
                  let text = try? String(contentsOf: baselineConfigURL, encoding: .utf8) {
            sourceConfig = text
        } else {
            sourceConfig = ""
        }

        let officialConfig = ConfigComposer.buildOpenAIConfig(base: sourceConfig)
        if officialConfig.isEmpty {
            try? FileManager.default.removeItem(at: configURL)
        } else {
            try atomicWrite(officialConfig + "\n", to: configURL, permissions: 0o600)
        }

        let sourceEnv: String
        if let text = try? String(contentsOf: envURL, encoding: .utf8) {
            sourceEnv = text
        } else if metadata?.envExisted == true,
                  FileManager.default.fileExists(atPath: baselineEnvURL.path),
                  let text = try? String(contentsOf: baselineEnvURL, encoding: .utf8) {
            sourceEnv = text
        } else {
            sourceEnv = ""
        }

        let officialEnv = ConfigComposer.buildEnvironment(base: sourceEnv, apiKey: nil)
        if officialEnv.isEmpty {
            try? FileManager.default.removeItem(at: envURL)
        } else {
            try atomicWrite(officialEnv, to: envURL, permissions: 0o600)
        }
        try clearRuntimeCredentials()

        guard isOpenAIConfigured() else {
            throw NSError(domain: "ConfigManager", code: 7, userInfo: [NSLocalizedDescriptionKey: "Codex configuration still selects a custom model provider after restore."])
        }
        try saveActiveState(ActiveState(mode: "openai", profileID: nil, updatedAt: Date()))
    }

    func revealCodexFolder() { NSWorkspace.shared.activateFileViewerSelecting([configURL]) }
    func revealBackupFolder() { NSWorkspace.shared.open(backupURL) }
    func codexPath() -> String { codexURL.path }
    func backupPath() -> String { backupURL.path }

    func legacyProfileSeed() -> ProviderProfile? {
        let modelURL = legacySwitcherURL.appendingPathComponent("model.txt")
        let baseURL = legacySwitcherURL.appendingPathComponent("base_url.txt")
        guard let model = try? String(contentsOf: modelURL, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines), !model.isEmpty,
              let base = try? String(contentsOf: baseURL, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines), !base.isEmpty else { return nil }
        let effortRaw = ((try? String(contentsOf: legacySwitcherURL.appendingPathComponent("reasoning_effort.txt"), encoding: .utf8)) ?? "automatic").trimmingCharacters(in: .whitespacesAndNewlines)
        return ProviderProfile(name: "Imported Provider", model: model, baseURL: base, authentication: .bearer, reasoningEffort: ReasoningEffort(rawValue: effortRaw) ?? .automatic)
    }

    private func captureBaseline() throws {
        let configExists = FileManager.default.fileExists(atPath: configURL.path)
        let envExists = FileManager.default.fileExists(atPath: envURL.path)
        if configExists { try atomicWrite(Data(contentsOf: configURL), to: baselineConfigURL, permissions: 0o600) }
        else { try? FileManager.default.removeItem(at: baselineConfigURL) }
        if envExists { try atomicWrite(Data(contentsOf: envURL), to: baselineEnvURL, permissions: 0o600) }
        else { try? FileManager.default.removeItem(at: baselineEnvURL) }
        let metadata = BaselineMetadata(configExisted: configExists, envExisted: envExists, capturedAt: Date())
        try atomicWrite(try encoder.encode(metadata), to: baselineMetadataURL, permissions: 0o600)
    }

    private func backupCurrent(reason: String) throws {
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let folder = backupURL.appendingPathComponent("\(stamp)-\(reason)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: configURL.path) { try FileManager.default.copyItem(at: configURL, to: folder.appendingPathComponent("config.toml")) }
        if FileManager.default.fileExists(atPath: envURL.path) { try FileManager.default.copyItem(at: envURL, to: folder.appendingPathComponent(".env")) }
    }

    private func clearRuntimeCredentials() throws {
        guard FileManager.default.fileExists(atPath: runtimeCredentialURL.path) else { return }
        for item in try FileManager.default.contentsOfDirectory(at: runtimeCredentialURL, includingPropertiesForKeys: nil) {
            try? FileManager.default.removeItem(at: item)
        }
    }

    private func loadBaselineMetadata() -> BaselineMetadata? {
        guard let data = try? Data(contentsOf: baselineMetadataURL) else { return nil }
        return try? decoder.decode(BaselineMetadata.self, from: data)
    }
    private func loadActiveState() -> ActiveState? {
        guard let data = try? Data(contentsOf: activeStateURL) else { return nil }
        return try? decoder.decode(ActiveState.self, from: data)
    }
    private func saveActiveState(_ state: ActiveState) throws {
        try atomicWrite(try encoder.encode(state), to: activeStateURL, permissions: 0o600)
    }

    private func atomicWrite(_ text: String, to url: URL, permissions: Int) throws { try atomicWrite(Data(text.utf8), to: url, permissions: permissions) }
    private func atomicWrite(_ data: Data, to url: URL, permissions: Int) throws {
        let temp = url.deletingLastPathComponent().appendingPathComponent(".\(url.lastPathComponent).\(UUID().uuidString).tmp")
        try data.write(to: temp, options: .atomic)
        try? FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: temp.path)
        if FileManager.default.fileExists(atPath: url.path) { _ = try FileManager.default.replaceItemAt(url, withItemAt: temp) }
        else { try FileManager.default.moveItem(at: temp, to: url) }
        try? FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: url.path)
    }

    private func migrateFromV31IfNeeded() throws {
        guard FileManager.default.fileExists(atPath: legacyManagerURL.path) else { return }
        let mappings = [("profiles.json", profilesURL), ("baseline.config.toml", baselineConfigURL), ("baseline.env", baselineEnvURL), ("baseline.json", baselineMetadataURL), ("active.json", activeStateURL)]
        for (name, destination) in mappings where !FileManager.default.fileExists(atPath: destination.path) {
            let source = legacyManagerURL.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: source.path) { try FileManager.default.copyItem(at: source, to: destination) }
        }
    }

    private func migrateFromV2IfNeeded() throws {
        guard !FileManager.default.fileExists(atPath: baselineMetadataURL.path) else { return }
        let configFlagURL = legacySwitcherURL.appendingPathComponent("official.config.exists")
        let envFlagURL = legacySwitcherURL.appendingPathComponent("official.env.exists")
        guard FileManager.default.fileExists(atPath: configFlagURL.path), FileManager.default.fileExists(atPath: envFlagURL.path) else { return }
        let configFlag = ((try? String(contentsOf: configFlagURL, encoding: .utf8)) ?? "0").trimmingCharacters(in: .whitespacesAndNewlines) == "1"
        let envFlag = ((try? String(contentsOf: envFlagURL, encoding: .utf8)) ?? "0").trimmingCharacters(in: .whitespacesAndNewlines) == "1"
        let oldConfig = legacySwitcherURL.appendingPathComponent("official.config.toml")
        let oldEnv = legacySwitcherURL.appendingPathComponent("official.env")
        if configFlag, FileManager.default.fileExists(atPath: oldConfig.path) { try atomicWrite(Data(contentsOf: oldConfig), to: baselineConfigURL, permissions: 0o600) }
        if envFlag, FileManager.default.fileExists(atPath: oldEnv.path) { try atomicWrite(Data(contentsOf: oldEnv), to: baselineEnvURL, permissions: 0o600) }
        let metadata = BaselineMetadata(configExisted: configFlag, envExisted: envFlag, capturedAt: Date())
        try atomicWrite(try encoder.encode(metadata), to: baselineMetadataURL, permissions: 0o600)
    }
}
