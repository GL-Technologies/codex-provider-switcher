import SwiftUI

struct AccessSetupView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 14) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 48, height: 48)
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.text("guide.title"))
                        .font(.title2.weight(.semibold))
                    Text(L10n.text("guide.subtitle"))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 0) {
                setupRow(number: "1", title: L10n.text("guide.step_open"), detail: L10n.text("guide.step_open_detail"))
                Divider().padding(.leading, 54)
                setupRow(number: "2", title: L10n.text("guide.step_security"), detail: L10n.text("guide.step_security_detail"))
                Divider().padding(.leading, 54)
                setupRow(number: "3", title: L10n.text("guide.step_config"), detail: L10n.text("guide.step_config_detail"))
            }
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 1)
            }

            HStack(spacing: 10) {
                Button(L10n.text("guide.open_security")) {
                    store.systemAccess.openPrivacyAndSecurity()
                }
                Spacer()
                Button(L10n.text("access.continue")) {
                    store.completeAccessSetup()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(26)
        .frame(width: 650)
    }

    private func setupRow(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(Color(nsColor: .quaternaryLabelColor).opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.body.weight(.medium))
                Text(detail).font(.callout).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
    }
}
