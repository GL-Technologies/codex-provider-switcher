import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Form {
            Section {
                Toggle(L10n.text("settings.offer_restart"), isOn: $store.preferences.offerRestartAfterSwitch)
                Toggle(L10n.text("settings.show_keys"), isOn: $store.preferences.showKeysByDefault)
                Button {
                    store.showAccessSetup()
                } label: {
                    Label(L10n.text("guide.title"), systemImage: "checkmark.shield")
                }
            } header: {
                Label(L10n.text("settings.general"), systemImage: "gearshape")
            }

            Section {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(store.autoBridgeEnabled ? Color.green.opacity(0.12) : Color.secondary.opacity(0.10))
                            .frame(width: 36, height: 36)
                        Image(systemName: "point.3.connected.trianglepath.dotted")
                            .foregroundStyle(store.autoBridgeEnabled ? .green : .secondary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.text("bridge.auto"))
                            .font(.body.weight(.medium))
                        Text(store.autoBridgeEnabled ? L10n.text("bridge.active") : L10n.text("bridge.inactive"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { store.autoBridgeEnabled },
                        set: { store.setAutoBridgeEnabled($0) }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .disabled(store.isBusy)
                }

                Text(L10n.text("settings.bridge_detail"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text(L10n.text("bridge.keep_running"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } header: {
                Label(L10n.text("settings.bridge"), systemImage: "arrow.triangle.branch")
            }

            Section {
                Text(L10n.text("settings.credentials_detail"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            } header: {
                Label(L10n.text("settings.credentials"), systemImage: "key")
            }

            Section {
                LabeledContent(L10n.text("settings.codex_folder")) {
                    HStack(spacing: 8) {
                        Text(store.configManager.codexPath())
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .textSelection(.enabled)
                        Button(L10n.text("action.reveal")) { store.configManager.revealCodexFolder() }
                            .controlSize(.small)
                    }
                }
                LabeledContent(L10n.text("settings.backups")) {
                    HStack(spacing: 8) {
                        Text(store.configManager.backupPath())
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .textSelection(.enabled)
                        Button(L10n.text("action.reveal")) { store.configManager.revealBackupFolder() }
                            .controlSize(.small)
                    }
                }
            } header: {
                Label(L10n.text("settings.storage"), systemImage: "externaldrive")
            }
        }
        .formStyle(.grouped)
        .padding(14)
        .frame(width: 700, height: 540)
    }
}
