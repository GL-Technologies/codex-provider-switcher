import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppDesign.sectionSpacing) {
                settingsCard(
                    title: L10n.text("settings.general"),
                    systemImage: "gearshape"
                ) {
                    VStack(alignment: .leading, spacing: 14) {
                        Toggle(L10n.text("settings.offer_restart"), isOn: $store.preferences.offerRestartAfterSwitch)
                        Toggle(L10n.text("settings.show_keys"), isOn: $store.preferences.showKeysByDefault)
                        Divider()
                        Button {
                            store.showAccessSetup()
                        } label: {
                            Label(L10n.text("guide.title"), systemImage: "checkmark.shield")
                        }
                    }
                }

                settingsCard(
                    title: L10n.text("settings.bridge"),
                    systemImage: "arrow.triangle.branch"
                ) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 12) {
                            AppIconTile(
                                systemImage: "point.3.connected.trianglepath.dotted",
                                tone: store.autoBridgeEnabled ? .success : .neutral,
                                size: 40
                            )

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

                        AppInlineStatus(
                            title: L10n.text("settings.bridge_detail"),
                            detail: L10n.text("bridge.keep_running"),
                            systemImage: "info.circle.fill",
                            tone: .neutral
                        )
                    }
                }

                settingsCard(
                    title: L10n.text("settings.credentials"),
                    systemImage: "key"
                ) {
                    AppInlineStatus(
                        title: L10n.text("settings.credentials"),
                        detail: L10n.text("settings.credentials_detail"),
                        systemImage: "lock.shield.fill",
                        tone: .accent
                    )
                    .textSelection(.enabled)
                }

                settingsCard(
                    title: L10n.text("settings.storage"),
                    systemImage: "externaldrive"
                ) {
                    VStack(spacing: 0) {
                        storageRow(
                            title: L10n.text("settings.codex_folder"),
                            path: store.configManager.codexPath(),
                            action: store.configManager.revealCodexFolder
                        )
                        Divider().padding(.leading, 150)
                        storageRow(
                            title: L10n.text("settings.backups"),
                            path: store.configManager.backupPath(),
                            action: store.configManager.revealBackupFolder
                        )
                    }
                }
            }
            .padding(20)
        }
        .frame(width: 700, height: 560)
        .background(AppDesign.pageBackground)
    }

    @ViewBuilder
    private func settingsCard<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.secondary)
            AppCard {
                content()
            }
        }
    }

    private func storageRow(title: String, path: String, action: @escaping () -> Void) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 130, alignment: .leading)

            Text(path)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(L10n.text("action.reveal"), action: action)
                .controlSize(.small)
        }
        .padding(.vertical, 10)
    }
}
