import SwiftUI

struct ProviderDetailView: View {
    @EnvironmentObject private var store: AppStore
    let profile: ProviderProfile
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    @State private var isTesting = false
    @State private var testResult: ConnectionTestReport?
    @State private var section = 0

    private var isActive: Bool {
        !store.isOpenAIActive && store.activeProfileID == profile.id
    }

    private var detectedIncompatible: Bool {
        testResult?.success == true && testResult?.codexCompatible == false
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                Picker("", selection: $section) {
                    Text(L10n.text("details.configuration")).tag(0)
                    Text(L10n.text("details.test_result")).tag(1)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 310)

                if section == 0 {
                    configurationCard
                } else {
                    testCard
                }
            }
            .padding(26)
            .frame(maxWidth: 880, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 14) {
            ProviderIconView(brand: profile.resolvedBrand, size: 52)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(profile.name)
                        .font(.title2.weight(.semibold))
                    if isActive {
                        Text(L10n.text("status.active"))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.10), in: Capsule())
                    }
                }
                Text(profile.model)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                runTest()
                section = 1
            } label: {
                Label(L10n.text("action.test"), systemImage: "waveform.path.ecg")
            }
            .disabled(isTesting)

            Button {
                store.activate(profile)
            } label: {
                Label(L10n.text("action.use"), systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.borderedProminent)
            .disabled(isActive || store.isBusy || detectedIncompatible)
            .help(detectedIncompatible ? L10n.text("test.chat_only_message") : "")

            Menu {
                Button(L10n.text("action.edit"), action: onEdit)
                Button(L10n.text("action.duplicate"), action: onDuplicate)
                Divider()
                Button(L10n.text("action.delete"), role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 28)
        }
    }

    private var configurationCard: some View {
        card {
            Grid(alignment: .leading, horizontalSpacing: 22, verticalSpacing: 0) {
                detailRow(L10n.text("details.provider"), profile.resolvedBrand.displayName)
                dividerRow
                detailRow(L10n.text("details.model"), profile.model, monospaced: true)
                dividerRow
                detailRow(L10n.text("details.base_url"), profile.baseURL, monospaced: true)
                dividerRow
                detailRow(L10n.text("details.auth"), L10n.authentication(profile.authentication))
                if profile.authentication == .bearer {
                    dividerRow
                    detailRow(L10n.text("details.api_key"), store.hasKey(for: profile) ? L10n.text("key.stored") : L10n.text("key.missing"))
                }
                dividerRow
                detailRow(L10n.text("details.reasoning"), L10n.reasoning(profile.reasoningEffort))
                dividerRow
                detailRow(L10n.text("details.test_endpoint"), EndpointBuilder.responsesURL(from: profile.baseURL)?.absoluteString ?? "—", monospaced: true)
                if !profile.note.isEmpty {
                    dividerRow
                    detailRow(L10n.text("details.notes"), profile.note)
                }
            }
        }
    }

    private var testCard: some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(L10n.text("details.connection_test"))
                        .font(.headline)
                    Spacer()
                    Button {
                        runTest()
                    } label: {
                        if isTesting {
                            ProgressView().controlSize(.small)
                        } else {
                            Text(testResult == nil ? L10n.text("action.test") : L10n.text("action.test_again"))
                        }
                    }
                    .disabled(isTesting)
                }

                if let testResult {
                    ConnectionResultView(report: testResult)
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundStyle(.secondary)
                        Text(L10n.text("test.not_run"))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 18)
                }
            }
        }
    }

    @ViewBuilder
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 1)
            }
    }

    private func detailRow(_ label: String, _ value: String, monospaced: Bool = false) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 140, alignment: .leading)
                .padding(.vertical, 11)
            Group {
                if monospaced {
                    Text(value).font(.body.monospaced())
                } else {
                    Text(value)
                }
            }
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 11)
        }
    }

    private var dividerRow: some View {
        GridRow {
            Color.clear.frame(height: 1)
            Divider()
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
