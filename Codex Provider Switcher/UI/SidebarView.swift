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
            HStack(spacing: 8) {
                Button {
                    NotificationCenter.default.post(name: .addProviderRequested, object: nil)
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help(L10n.text("action.add_provider"))

                Spacer()

                Button {
                    store.showAccessSetup()
                } label: {
                    Image(systemName: "lock.shield")
                }
                .buttonStyle(.borderless)
                .help(L10n.text("access.title"))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.bar)
        }
    }

    private func providerRow(title: String, subtitle: String, brand: ProviderBrand, active: Bool, warning: Bool) -> some View {
        HStack(spacing: 10) {
            ProviderIconView(brand: brand, size: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
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
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                    .help(L10n.text("status.active"))
            }
        }
        .padding(.vertical, 4)
    }
}
