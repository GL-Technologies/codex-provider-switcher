import AppKit
import SwiftUI

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Button {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "main")
        } label: {
            Label(L10n.text("menu.open"), systemImage: "macwindow")
        }

        Divider()

        if let active = store.activeProfile, !store.isOpenAIActive {
            Label("\(L10n.text("menu.active")): \(active.name)", systemImage: "checkmark.circle.fill")
            Label(
                store.bridgedProfileID == active.id ? L10n.text("menu.bridge_active") : L10n.text("menu.direct_active"),
                systemImage: store.bridgedProfileID == active.id ? "point.3.connected.trianglepath.dotted" : "bolt.horizontal.circle"
            )
        } else {
            Label("\(L10n.text("menu.active")): \(L10n.text("menu.openai"))", systemImage: "checkmark.circle.fill")
            Label(L10n.text("menu.direct_active"), systemImage: "bolt.horizontal.circle")
        }

        Toggle(L10n.text("bridge.auto"), isOn: Binding(
            get: { store.autoBridgeEnabled },
            set: { store.setAutoBridgeEnabled($0) }
        ))
        .disabled(store.isBusy)

        Divider()

        Menu {
            Button {
                store.activateOpenAI()
            } label: {
                if store.isOpenAIActive {
                    Label(L10n.text("menu.openai"), systemImage: "checkmark")
                } else {
                    Label(L10n.text("menu.openai"), systemImage: "sparkles")
                }
            }
            .disabled(store.isBusy)

            if !store.profiles.isEmpty {
                Divider()
            }

            ForEach(store.profiles) { profile in
                Button {
                    store.activate(profile)
                } label: {
                    if !store.isOpenAIActive && store.activeProfileID == profile.id {
                        Label(profile.name, systemImage: "checkmark")
                    } else if !store.hasKey(for: profile) {
                        Label(profile.name, systemImage: "key.slash")
                    } else {
                        Text(profile.name)
                    }
                }
                .disabled(store.isBusy || !store.hasKey(for: profile))
            }
        } label: {
            Label(L10n.text("menu.providers"), systemImage: "arrow.triangle.2.circlepath")
        }

        if store.isBusy {
            Label(L10n.text("menu.switching"), systemImage: "hourglass")
        }

        Divider()

        Button {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } label: {
            Label(L10n.text("menu.settings"), systemImage: "gearshape")
        }

        Button {
            NSApp.terminate(nil)
        } label: {
            Label(L10n.text("menu.quit"), systemImage: "power")
        }
        .keyboardShortcut("q")
    }
}
