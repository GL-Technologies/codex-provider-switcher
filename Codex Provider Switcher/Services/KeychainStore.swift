import Foundation

/// Compatibility wrapper retained so existing app code does not need to change names.
///
/// GitHub release builds are currently ad-hoc signed. A rebuilt app can therefore fail
/// macOS Keychain's caller identity check and cause a login-keychain password prompt on
/// every update or launch. Until releases use a stable Developer ID signature, credentials
/// are stored in an owner-only local file under ~/.codex/provider-switcher (0600).
final class KeychainStore {
    private let local: LocalCredentialStore

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let file = home
            .appendingPathComponent(".codex", isDirectory: true)
            .appendingPathComponent("provider-switcher", isDirectory: true)
            .appendingPathComponent("credentials.json")
        local = LocalCredentialStore(fileURL: file)
    }

    func key(for id: UUID) -> String? {
        local.key(for: id)
    }

    func hasKey(for id: UUID) -> Bool {
        local.hasKey(for: id)
    }

    func save(_ value: String, for id: UUID) throws {
        try local.save(value, for: id)
    }

    func delete(for id: UUID) {
        local.delete(for: id)
    }

    /// Legacy Keychain migration is intentionally no longer automatic. Reading the old
    /// Keychain item is exactly what can trigger the recurring authorization dialog in
    /// ad-hoc builds. Existing users only need to paste each provider key once into 0.3.6.
    func migrateLegacyGlobalKey(to id: UUID) {
        // No-op by design. See comment above.
    }
}
