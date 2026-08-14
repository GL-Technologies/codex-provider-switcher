import SwiftUI

struct AccessSetupView: View {
    @EnvironmentObject private var store: AppStore
    @State private var status: SystemAccessStatus?

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 14) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 48, height: 48)
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.text("access.title"))
                        .font(.title2.weight(.semibold))
                    Text(L10n.text("access.subtitle"))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 0) {
                setupRow(number: "1", title: L10n.text("access.step_config"), detail: L10n.text("access.step_config_detail"))
                Divider().padding(.leading, 54)
                setupRow(number: "2", title: L10n.text("access.step_keychain"), detail: L10n.text("access.step_keychain_detail"))
                Divider().padding(.leading, 54)
                setupRow(number: "3", title: L10n.text("access.step_privacy"), detail: L10n.text("access.step_privacy_detail"))
            }
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 1)
            }

            if let status {
                HStack(spacing: 10) {
                    Image(systemName: status.canWriteCodexDirectory ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(status.canWriteCodexDirectory ? .green : .orange)
                    Text(status.message)
                        .font(.callout)
                    Spacer()
                }
                .padding(12)
                .background(status.canWriteCodexDirectory ? Color.green.opacity(0.08) : Color.orange.opacity(0.09), in: RoundedRectangle(cornerRadius: 10))
            }

            HStack(spacing: 10) {
                Button(L10n.text("access.check")) { check() }
                Button(L10n.text("access.open_privacy")) { store.systemAccess.openPrivacyAndSecurity() }
                Button(L10n.text("access.open_full_disk")) { store.systemAccess.openFullDiskAccess() }
                Spacer()
                Button(L10n.text("access.continue")) { store.completeAccessSetup() }
                    .buttonStyle(.borderedProminent)
                    .disabled(status?.canWriteCodexDirectory == false)
            }
        }
        .padding(26)
        .frame(width: 650)
        .onAppear { check() }
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

    private func check() {
        status = store.systemAccess.checkCodexDirectoryAccess()
    }
}
