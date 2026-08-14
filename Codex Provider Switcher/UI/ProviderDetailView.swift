import SwiftUI

struct ProviderDetailView: View {
    @EnvironmentObject private var store: AppStore
    let profile: ProviderProfile
    let onEdit: () -> Void

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
            VStack(alignment: .leading, spacing: AppDesign.sectionSpacing) {
                header
                routeCard

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
            .padding(AppDesign.pagePadding)
            .frame(maxWidth: AppDesign.pageMaxWidth, alignment: .leading)
        }
        .background(AppDesign.pageBackground)
    }

    private var header: some View {
        HStack(spacing: 16) {
            ProviderIconView(brand: profile.resolvedBrand, size: 58)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(profile.name)
                        .font(.title2.weight(.semibold))
                    if isActive {
                        AppStatusPill(text: L10n.text("status.active"), tone: .success, systemImage: "checkmark")
                    }
                    if isBridged {
                        AppStatusPill(text: L10n.text("bridge.badge"), tone: .warning, systemImage: "arrow.triangle.branch")
                    }
                }
                Text(profile.model)
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            Spacer()

            Button {
                onEdit()
            } label: {
                Label(L10n.text("action.edit"), systemImage: "pencil")
            }

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

            if !isActive {
                Button {
                    store.activate(profile)
                } label: {
                    Label(L10n.text("action.use"), systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.isBusy)
            }
        }
    }

    private var routeCard: some View {
        AppCard(padding: 15) {
            HStack(spacing: 14) {
                AppIconTile(
                    systemImage: isBridged ? "point.3.connected.trianglepath.dotted" : (isActive ? "bolt.horizontal.circle.fill" : "network"),
                    tone: isBridged ? .warning : (isActive ? .success : .neutral),
                    size: 42
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(routeTitle)
                        .font(.headline)
                    Text(routeDetail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .textSelection(.enabled)
                }

                Spacer()

                if isBridged {
                    AppStatusPill(text: L10n.text("bridge.badge"), tone: .warning, systemImage: "arrow.triangle.branch")
                } else if isActive {
                    AppStatusPill(text: L10n.text("menu.direct_active"), tone: .success, systemImage: "bolt.horizontal.circle")
                }
            }
        }
    }

    private var routeTitle: String {
        if isBridged { return L10n.text("bridge.active") }
        if isActive { return L10n.text("menu.direct_active") }
        return profile.resolvedBrand.displayName
    }

    private var routeDetail: String {
        if isBridged { return L10n.text("bridge.keep_running") }
        return profile.baseURL
    }

    private var configurationCard: some View {
        AppCard {
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
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    AppSectionHeader(title: L10n.text("details.connection_test"))
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
                    AppEmptyState(
                        systemImage: "waveform.path.ecg",
                        title: L10n.text("test.not_run")
                    )
                }
            }
        }
    }

    private func detailRow(_ label: String, _ value: String, monospaced: Bool = false) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: AppDesign.labelColumnWidth, alignment: .leading)
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
