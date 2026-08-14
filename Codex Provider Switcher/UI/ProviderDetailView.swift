import SwiftUI

struct ProviderDetailView: View {
    @EnvironmentObject private var store: AppStore
    let profile: ProviderProfile
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    @State private var isTesting = false
    @State private var testResult: ConnectionTestReport?

    private var isActive: Bool {
        !store.isOpenAIActive && store.activeProfileID == profile.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(profile.name)
                            .font(.title2.weight(.semibold))
                        if isActive {
                            Text(L10n.text("status.active"))
                                .font(.caption)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.12), in: Capsule())
                        }
                    }
                    Text(profile.model)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.bottom, 22)

            Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 12) {
                row(L10n.text("details.base_url"), profile.baseURL)
                row(L10n.text("details.auth"), L10n.authentication(profile.authentication))
                if profile.authentication == .bearer {
                    row(L10n.text("details.api_key"), store.hasKey(for: profile) ? L10n.text("key.stored") : L10n.text("key.missing"))
                }
                row(L10n.text("details.reasoning"), L10n.reasoning(profile.reasoningEffort))
                if !profile.note.isEmpty {
                    row(L10n.text("details.notes"), profile.note)
                }
            }

            HStack(spacing: 10) {
                Button(L10n.text("action.use")) {
                    store.activate(profile)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isActive || store.isBusy)

                Button {
                    runTest()
                } label: {
                    if isTesting {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text(L10n.text("test.testing"))
                        }
                    } else {
                        Text(L10n.text("action.test"))
                    }
                }
                .disabled(isTesting)

                Button(L10n.text("action.edit"), action: onEdit)

                Menu {
                    Button(L10n.text("action.duplicate"), action: onDuplicate)
                    Divider()
                    Button(L10n.text("action.delete"), role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
            }
            .padding(.top, 26)

            if let testResult {
                ConnectionResultView(report: testResult)
                    .padding(.top, 18)
                    .frame(maxWidth: 650)
            }

            Spacer()
        }
        .padding(28)
    }

    @ViewBuilder
    private func row(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .leading)
            Text(value)
                .textSelection(.enabled)
                .lineLimit(3)
        }
    }

    private func runTest() {
        guard !isTesting else { return }
        isTesting = true
        testResult = nil
        Task {
            testResult = await store.test(profile: profile)
            isTesting = false
        }
    }
}
