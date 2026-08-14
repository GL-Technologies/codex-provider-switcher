import AppKit
import Foundation

struct SystemAccessStatus {
    let canWriteCodexDirectory: Bool
    let message: String
}

final class SystemAccessService {
    private let fileManager = FileManager.default

    func checkCodexDirectoryAccess() -> SystemAccessStatus {
        let directory = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".codex", isDirectory: true)
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let probe = directory.appendingPathComponent(".provider-switcher-access-check-\(UUID().uuidString)")
            try Data("ok".utf8).write(to: probe, options: .atomic)
            try? fileManager.removeItem(at: probe)
            return SystemAccessStatus(canWriteCodexDirectory: true, message: L10n.text("access.ready_message"))
        } catch {
            return SystemAccessStatus(canWriteCodexDirectory: false, message: L10n.format("access.blocked_message", error.localizedDescription))
        }
    }

    func openPrivacyAndSecurity() {
        openSettingsURL("x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension")
    }

    func openFullDiskAccess() {
        openSettingsURL("x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")
    }

    private func openSettingsURL(_ string: String) {
        if let url = URL(string: string), NSWorkspace.shared.open(url) {
            return
        }
        NSWorkspace.shared.openApplication(
            at: URL(fileURLWithPath: "/System/Applications/System Settings.app"),
            configuration: NSWorkspace.OpenConfiguration(),
            completionHandler: nil
        )
    }
}
