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

    private var isBridged: Bool {
        store.bridgedProfileID == profile.id
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                statusCard

                Picker("", selection: $section) {
                    Text(L10n.text("details.configuration")).tag(0)
                    Text(L10n.text("details.test_result")).tag(1)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 330)

                if section == 0 {
                    configurationCard
                } else {
                    testCard
                }
            }
            .padding(28)
            .frame(maxWidth: 900, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 16) {
            ProviderIconView(brand: profile.resolvedBrand, size: 56)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(profile.name)
                        .font(.title2.weight(.semibold))
                    if isActive {
                        statusBadge(L10n.text("status.active"), color: .green)
                    }
                    if isBridged {
                        statusBadge(L10n.text("bridge.badge"), color: .orange)
                    }
                }
                Text(profile.model)
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                runTest()
                section = 1
            } label: {
                if isTesting {
                    HStack(spacing: 7) {
                        ProgressView().controlSize(.small)
                        Text(L10n.text("test.testing"))
                    }
                } else {
                    Label(L10n.text("action.test"), systemImage: "waveform.path.ecg")
                }
            }
            .disabled(isTesting)

            Button {
                store.activate(profile)
            } label: {
                Label(L10n.text("action.use"), systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.borderedProminent)
            .disabled(isActive || store.isBusy)

            Menu {
                Button(L10n.text("action.edit"), action: onEdit)
                Button(L10n.text("action.duplicate"), action: onDuplicate)
                Divider()
                Button(L10n.text("action.delete"), role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 20, height: 20)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 30)
        }
    }

    private var statusCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isBridged ? Color.orange.opacity(0.12) : Color.green.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: isBridged ? "point.3.connected.trianglepath.dotted" : "bolt.horizontal.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isBridged ? .orange : .green)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(isBridged ? L10n.text("bridge.active") : L10n.text("bridge.inactive"))
                    .font(.headline)
                Text(isBridged ? L10n.text("bridge.keep_running") : profile.baseURL)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(L10n.text("bridge.auto"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Toggle("", isOn: Binding(
                    get: { store.autoBridgeEnabled },
                    set: { store.setAutoBridgeEnabled($0) }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .disabled(store.isBusy)
            }
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.50), lineWidth: 1)
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
                detailRow(L10n.text("bridge.status"), isBridged ? L10n.text("bridge.active") : L10n.text("bridge.inactive"))
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
                            HStack(spacing: 7) {
                                ProgressView().controlSize(.small)
                                Text(L10n.text("test.testing"))
                            }
                        } else {
                            Text(testResult == nil ? L10n.text("action.test") : L10n.text("action.test_again"))
                        }
                    }
                    .disabled(isTesting)
                }

                if let testResult {
                    ConnectionResultView(report: testResult)
                        .environmentObject(store)
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text(L10n.text("test.not_run"))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 22)
                }
            }
        }
    }

    private func statusBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.10), in: Capsule())
    }

    @ViewBuilder
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.50), lineWidth: 1)
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
