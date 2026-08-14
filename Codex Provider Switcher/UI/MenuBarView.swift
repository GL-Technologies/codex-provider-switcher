import AppKit
import SwiftUI

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Button(L10n.text("menu.open")) {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "main")
        }

        Divider()

        if let active = store.activeProfile, !store.isOpenAIActive {
            Label("\(L10n.text("menu.active")): \(active.name)", systemImage: "checkmark.circle.fill")
            Text(store.bridgedProfileID == active.id ? L10n.text("menu.bridge_active") : L10n.text("menu.direct_active"))
        } else {
            Label("\(L10n.text("menu.active")): \(L10n.text("menu.openai"))", systemImage: "checkmark.circle.fill")
        }

        Toggle(L10n.text("bridge.auto"), isOn: Binding(
            get: { store.autoBridgeEnabled },
            set: { store.setAutoBridgeEnabled($0) }
        ))
        .disabled(store.isBusy)

        Divider()

        Menu(L10n.text("menu.providers")) {
            Button {
                store.activateOpenAI()
            } label: {
                if store.isOpenAIActive {
                    Label(L10n.text("menu.openai"), systemImage: "checkmark")
                } else {
                    Text(L10n.text("menu.openai"))
                }
            }
            .disabled(store.isBusy)

            Divider()

            ForEach(store.profiles) { profile in
                Button {
                    store.activate(profile)
                } label: {
                    if !store.isOpenAIActive && store.activeProfileID == profile.id {
                        Label(profile.name, systemImage: "checkmark")
                    } else {
                        Text(profile.name)
                    }
                }
                .disabled(store.isBusy || !store.hasKey(for: profile))
            }
        }

        if store.isBusy {
            Text(L10n.text("menu.switching"))
        }

        Divider()

        Button(L10n.text("menu.settings")) {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }

        Button(L10n.text("menu.quit")) {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
