import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var store: AppStore
    @Binding var selection: SidebarSelection

    var body: some View {
        List(selection: $selection) {
            Section {
                row(
                    title: "OpenAI",
                    subtitle: L10n.text("official.sidebar_subtitle"),
                    systemImage: "sparkles",
                    active: store.isOpenAIActive,
                    warning: false
                )
                .tag(SidebarSelection.openAI)
            }

            Section(L10n.text("sidebar.providers")) {
                ForEach(store.profiles) { profile in
                    row(
                        title: profile.name,
                        subtitle: profile.model,
                        systemImage: "network",
                        active: !store.isOpenAIActive && store.activeProfileID == profile.id,
                        warning: !store.hasKey(for: profile)
                    )
                    .tag(SidebarSelection.provider(profile.id))
                }
            }
        }
        .listStyle(.sidebar)
    }

    private func row(title: String, subtitle: String, systemImage: String, active: Bool, warning: Bool) -> some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .frame(width: 18)
                .foregroundStyle(active ? Color.accentColor : Color.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if warning {
                Image(systemName: "key.slash")
                    .foregroundStyle(.orange)
                    .help(L10n.text("key.missing"))
            } else if active {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 2)
    }
}
