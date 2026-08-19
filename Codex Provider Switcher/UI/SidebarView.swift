import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var store: AppStore
    @Binding var selection: SidebarSelection
    let onAdd: () -> Void
    let onEdit: (ProviderProfile) -> Void
    let onDuplicate: (ProviderProfile) -> Void
    let onDelete: (ProviderProfile) -> Void

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
                .contextMenu {
                    if !store.isOpenAIActive {
                        Button {
                            store.activateOpenAI()
                        } label: {
                            Label(L10n.text("action.use_openai"), systemImage: "arrow.uturn.backward")
                        }
                        .disabled(store.isBusy)
                    }
                }
            }

            Section(L10n.text("sidebar.providers")) {
                ForEach(store.profiles) { profile in
                    let active = !store.isOpenAIActive && store.activeProfileID == profile.id
                    providerRow(
                        title: profile.name,
                        subtitle: profile.model,
                        brand: profile.resolvedBrand,
                        active: active,
                        warning: !store.hasKey(for: profile)
                    )
                    .tag(SidebarSelection.provider(profile.id))
                    .contextMenu {
                        if !active && store.hasKey(for: profile) {
                            Button {
                                store.activate(profile)
                            } label: {
                                Label(L10n.text("action.use"), systemImage: "arrow.triangle.2.circlepath")
                            }
                            .disabled(store.isBusy)

                            Divider()
                        }

                        Button {
                            onEdit(profile)
                        } label: {
                            Label(L10n.text("action.edit"), systemImage: "pencil")
                        }

                        Button {
                            onDuplicate(profile)
                        } label: {
                            Label(L10n.text("action.duplicate"), systemImage: "plus.square.on.square")
                        }

                        Divider()

                        Button(role: .destructive) {
                            onDelete(profile)
                        } label: {
                            Label(L10n.text("action.delete"), systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 9) {
                addProviderButton
                bridgeControl

                HStack {
                    Spacer()
                    Button {
                        store.showAccessSetup()
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.callout)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.borderless)
                    .help(L10n.text("guide.title"))
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 10)
            .padding(.top, 9)
            .padding(.bottom, 10)
            .background(.bar)
        }
    }

    private var addProviderButton: some View {
        Button(action: onAdd) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
                Text(L10n.text("action.add_provider"))
                    .font(.callout.weight(.medium))
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 4)
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .disabled(store.isBusy)
        .help(L10n.text("action.add_provider"))
    }

    private var bridgeControl: some View {
        HStack(spacing: 10) {
            AppIconTile(
                systemImage: "point.3.connected.trianglepath.dotted",
                tone: store.autoBridgeEnabled ? .success : .neutral,
                size: 34
            )

            VStack(alignment: .leading, spacing: 2) {
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
        .background(AppDesign.surface, in: RoundedRectangle(cornerRadius: AppDesign.compactRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppDesign.compactRadius, style: .continuous)
                .strokeBorder(AppDesign.separator, lineWidth: 1)
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
