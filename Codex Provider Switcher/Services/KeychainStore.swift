import Foundation
import Security

final class KeychainStore {
    private let account = NSUserName()
    private let servicePrefix = "io.github.GL-Technologies.CodexProviderSwitcher.provider."
    private let legacyServicePrefix = "codex-interface-manager.provider."
    private let legacyGlobalService = "codex-openai-compatible-api-key"

    func key(for id: UUID) -> String? {
        if let value = read(service: service(for: id)) { return value }
        if let legacy = read(service: legacyService(for: id)) {
            try? save(legacy, for: id)
            return legacy
        }
        return nil
    }

    func hasKey(for id: UUID) -> Bool {
        guard let value = key(for: id) else { return false }
        return !value.isEmpty
    }

    func save(_ value: String, for id: UUID) throws {
        let clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        guard !clean.contains("\n") && !clean.contains("\r") else {
            throw NSError(domain: "KeychainStore", code: 1, userInfo: [NSLocalizedDescriptionKey: L10n.text("error.key_newline")])
        }

        let service = service(for: id)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: Data(clean.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var newItem = query
            attributes.forEach { newItem[$0.key] = $0.value }
            let addStatus = SecItemAdd(newItem as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw keychainError(addStatus) }
        } else if status != errSecSuccess {
            throw keychainError(status)
        }
    }

    func delete(for id: UUID) {
        delete(service: service(for: id))
        delete(service: legacyService(for: id))
    }

    func migrateLegacyGlobalKey(to id: UUID) {
        guard !hasKey(for: id), let value = read(service: legacyGlobalService), !value.isEmpty else { return }
        try? save(value, for: id)
    }

    private func service(for id: UUID) -> String {
        servicePrefix + id.uuidString.lowercased()
    }

    private func legacyService(for id: UUID) -> String {
        legacyServicePrefix + id.uuidString.lowercased()
    }

    private func read(service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(service: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    private func keychainError(_ status: OSStatus) -> NSError {
        let detail = SecCopyErrorMessageString(status, nil) as String? ?? "OSStatus \(status)"
        return NSError(domain: "KeychainStore", code: Int(status), userInfo: [NSLocalizedDescriptionKey: L10n.format("error.keychain", detail)])
    }
}
