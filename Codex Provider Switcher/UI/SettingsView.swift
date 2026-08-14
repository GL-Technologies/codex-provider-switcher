import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var accessStatus: SystemAccessStatus?

    var body: some View {
        Form {
            Section(L10n.text("settings.general")) {
                Toggle(L10n.text("settings.offer_restart"), isOn: $store.preferences.offerRestartAfterSwitch)
                Toggle(L10n.text("settings.show_keys"), isOn: $store.preferences.showKeysByDefault)
            }

            Section(L10n.text("access.title")) {
                LabeledContent(L10n.text("access.codex_access")) {
                    HStack(spacing: 8) {
                        Image(systemName: (accessStatus?.canWriteCodexDirectory ?? false) ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle((accessStatus?.canWriteCodexDirectory ?? false) ? .green : .orange)
                        Text((accessStatus?.canWriteCodexDirectory ?? false) ? L10n.text("access.ready") : L10n.text("access.check_needed"))
                    }
                }

                HStack {
                    Button(L10n.text("access.check")) { refreshAccess() }
                    Button(L10n.text("access.open_privacy")) { store.systemAccess.openPrivacyAndSecurity() }
                    Button(L10n.text("access.open_full_disk")) { store.systemAccess.openFullDiskAccess() }
                }
            }

            Section(L10n.text("settings.storage")) {
                LabeledContent(L10n.text("settings.codex_folder")) {
                    HStack {
                        Text(store.configManager.codexPath())
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                        Button(L10n.text("action.reveal")) { store.configManager.revealCodexFolder() }
                    }
                }
                LabeledContent(L10n.text("settings.backups")) {
                    HStack {
                        Text(store.configManager.backupPath())
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                        Button(L10n.text("action.reveal")) { store.configManager.revealBackupFolder() }
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 650, height: 420)
        .onAppear { refreshAccess() }
    }

    private func refreshAccess() {
        accessStatus = store.systemAccess.checkCodexDirectoryAccess()
    }
}
