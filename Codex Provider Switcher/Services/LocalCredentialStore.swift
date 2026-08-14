import Foundation

/// Stores provider credentials in the app's private Codex state directory.
///
/// GitHub release builds are currently ad-hoc signed. macOS Keychain ACLs can therefore
/// treat a rebuilt app as a different caller and repeatedly ask for login-keychain approval.
/// Until releases use a stable Developer ID signature, the default store is a local file
/// protected with owner-only POSIX permissions (0600).
final class LocalCredentialStore {
    private let fileURL: URL
    private let queue = DispatchQueue(label: "CodexProviderSwitcher.LocalCredentialStore")

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func key(for id: UUID) -> String? {
        queue.sync {
            load()[id.uuidString.lowercased()]
        }
    }

    func hasKey(for id: UUID) -> Bool {
        guard let value = key(for: id) else { return false }
        return !value.isEmpty
    }

    func save(_ value: String, for id: UUID) throws {
        let clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        guard !clean.contains("\n") && !clean.contains("\r") else {
            throw NSError(
                domain: "LocalCredentialStore",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: L10n.text("error.key_newline")]
            )
        }

        try queue.sync {
            var values = load()
            values[id.uuidString.lowercased()] = clean
            try persist(values)
        }
    }

    func delete(for id: UUID) {
        queue.sync {
            var values = load()
            values.removeValue(forKey: id.uuidString.lowercased())
            try? persist(values)
        }
    }

    private func load() -> [String: String] {
        guard let data = try? Data(contentsOf: fileURL),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return [:]
        }
        return object
    }

    private func persist(_ values: [String: String]) throws {
        let parent = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        let data = try JSONSerialization.data(withJSONObject: values, options: [.prettyPrinted, .sortedKeys])
        let temp = parent.appendingPathComponent(".credentials.\(UUID().uuidString).tmp")
        try data.write(to: temp, options: .atomic)
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: temp.path)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            _ = try FileManager.default.replaceItemAt(fileURL, withItemAt: temp)
        } else {
            try FileManager.default.moveItem(at: temp, to: fileURL)
        }
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }
}
