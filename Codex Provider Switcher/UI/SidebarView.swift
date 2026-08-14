import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var store: AppStore
    @Binding var selection: SidebarSelection

    var body: some View {
        List(selection: $selection) {
            Section {
                providerRow(
                    title: "OpenAI",
                    subtitle: L10n.text("official.sidebar_subtitle"),
                    brand: .openAI,
                    active: store.isOpenAIActive,
                    warning: false
                )
                .tag(SidebarSelection.openAI)
            }

            Section(L10n.text("sidebar.providers")) {
                ForEach(store.profiles) { profile in
                    providerRow(
                        title: profile.name,
                        subtitle: profile.model,
                        brand: profile.resolvedBrand,
                        active: !store.isOpenAIActive && store.activeProfileID == profile.id,
                        warning: !store.hasKey(for: profile)
                    )
                    .tag(SidebarSelection.provider(profile.id))
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                bridgeControl

                HStack(spacing: 8) {
                    Button {
                        NotificationCenter.default.post(name: .addProviderRequested, object: nil)
                    } label: {
                        Label(L10n.text("action.add_provider"), systemImage: "plus")
                            .labelStyle(.iconOnly)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.borderless)
                    .help(L10n.text("action.add_provider"))

                    Spacer()

                    Button {
                        store.showAccessSetup()
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.borderless)
                    .help(L10n.text("guide.title"))
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 9)
            .background(.bar)
        }
    }

    private var bridgeControl: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(store.autoBridgeEnabled ? Color.green.opacity(0.14) : Color.secondary.opacity(0.10))
                    .frame(width: 32, height: 32)
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(store.autoBridgeEnabled ? .green : .secondary)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(L10n.text("bridge.auto"))
                    .font(.caption.weight(.semibold))
                Text(store.autoBridgeEnabled ? L10n.text("bridge.active") : L10n.text("bridge.inactive"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Toggle("", isOn: Binding(
                get: { store.autoBridgeEnabled },
                set: { store.setAutoBridgeEnabled($0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.mini)
            .disabled(store.isBusy)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 1)
        }
        .help(L10n.text("bridge.auto_help"))
    }

    private func providerRow(title: String, subtitle: String, brand: ProviderBrand, active: Bool, warning: Bool) -> some View {
        HStack(spacing: 10) {
            ProviderIconView(brand: brand, size: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(active ? .semibold : .medium))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            if warning {
                Image(systemName: "key.slash.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .help(L10n.text("key.missing"))
            } else if active {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .help(L10n.text("status.active"))
            }
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
    }
}
