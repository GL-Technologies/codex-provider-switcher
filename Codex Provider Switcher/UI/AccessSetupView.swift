import SwiftUI

struct AccessSetupView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                AppIconTile(systemImage: "checkmark.shield.fill", tone: .accent, size: 48)

                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.text("guide.title"))
                        .font(.title2.weight(.semibold))
                    Text(L10n.text("guide.subtitle"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            AppCard(padding: 0) {
                VStack(spacing: 0) {
                    setupRow(number: "1", title: L10n.text("guide.step_open"), detail: L10n.text("guide.step_open_detail"))
                    Divider().padding(.leading, 64)
                    setupRow(number: "2", title: L10n.text("guide.step_security"), detail: L10n.text("guide.step_security_detail"))
                    Divider().padding(.leading, 64)
                    setupRow(number: "3", title: L10n.text("guide.step_config"), detail: L10n.text("guide.step_config_detail"))
                }
            }

            HStack(spacing: 10) {
                Button {
                    store.systemAccess.openPrivacyAndSecurity()
                } label: {
                    Label(L10n.text("guide.open_security"), systemImage: "gearshape")
                }

                Spacer()

                Button(L10n.text("access.continue")) {
                    store.completeAccessSetup()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(26)
        .frame(width: 650)
        .background(AppDesign.pageBackground)
    }

    private func setupRow(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 30, height: 30)
                .background(Color.accentColor.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
    }
}
