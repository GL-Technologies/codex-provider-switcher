import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Form {
            Section(L10n.text("settings.general")) {
                Toggle(L10n.text("settings.offer_restart"), isOn: $store.preferences.offerRestartAfterSwitch)
                Toggle(L10n.text("settings.show_keys"), isOn: $store.preferences.showKeysByDefault)
                Button(L10n.text("guide.title")) { store.showAccessSetup() }
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
        .frame(width: 650, height: 330)
    }
}
