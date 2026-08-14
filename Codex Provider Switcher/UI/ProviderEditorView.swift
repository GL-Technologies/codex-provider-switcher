import SwiftUI

struct ProviderEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    let original: ProviderProfile?
    @State private var draft: ProviderDraft
    @State private var apiKey = ""
    @State private var showKey = true
    @State private var isTesting = false
    @State private var isDiscoveringModels = false
    @State private var discoveredModels: [String] = []
    @State private var modelDiscoveryMessage: String?
    @State private var testResult: ConnectionTestReport?
    @State private var applyingDetection = false

    init(profile: ProviderProfile?) {
        original = profile
        _draft = State(initialValue: profile.map(ProviderDraft.init(profile:)) ?? ProviderDraft())
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    card {
                        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 13) {
                            fieldRow(L10n.text("field.brand")) {
                                HStack(spacing: 10) {
                                    ProviderIconView(brand: draft.resolvedBrand, size: 30)
                                    Picker("", selection: $draft.brand) {
                                        Text(L10n.text("brand.auto")).tag(ProviderBrand.automatic)
                                        Divider()
                                        ForEach(ProviderBrand.selectableCases) { brand in
                                            Text(brand.displayName).tag(brand)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }

                            fieldRow(L10n.text("field.name")) {
                                TextField(L10n.text("placeholder.name"), text: $draft.name)
                                    .textFieldStyle(.roundedBorder)
                            }

                            fieldRow(L10n.text("field.base_url")) {
                                HStack(spacing: 8) {
                                    TextField(L10n.text("placeholder.base_url"), text: $draft.baseURL)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.body.monospaced())

                                    Button {
                                        discoverModels()
                                    } label: {
                                        if isDiscoveringModels {
                                            ProgressView().controlSize(.small)
                                        } else {
                                            Label(L10n.text("models.discover"), systemImage: "magnifyingglass")
                                        }
                                    }
                                    .disabled(isDiscoveringModels || draft.baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                            }

                            fieldRow(L10n.text("field.model")) {
                                HStack(spacing: 8) {
                                    TextField(L10n.text("placeholder.model"), text: $draft.model)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.body.monospaced())

                                    if !discoveredModels.isEmpty {
                                        Menu {
                                            ForEach(discoveredModels, id: \.self) { model in
                                                Button {
                                                    draft.model = model
                                                } label: {
                                                    if draft.model == model {
                                                        Label(model, systemImage: "checkmark")
                                                    } else {
                                                        Text(model)
                                                    }
                                                }
                                            }
                                        } label: {
                                            Text(L10n.format("models.count", discoveredModels.count))
                                        }
                                        .menuStyle(.borderlessButton)
                                        .fixedSize()
                                    }
                                }
                            }
                        }

                        if let modelDiscoveryMessage {
                            Text(modelDiscoveryMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 10)
                                .padding(.leading, 143)
                                .textSelection(.enabled)
                        }
                    }

                    card {
                        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 13) {
                            fieldRow(L10n.text("field.authentication")) {
                                Picker("", selection: $draft.authentication) {
                                    Text(L10n.text("auth.api_key")).tag(AuthenticationMode.bearer)
                                    Text(L10n.text("auth.none")).tag(AuthenticationMode.none)
                                }
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            if draft.authentication == .bearer {
                                fieldRow(L10n.text("field.api_key")) {
                                    HStack(spacing: 8) {
                                        Group {
                                            if showKey {
                                                TextField(L10n.text("placeholder.api_key"), text: $apiKey)
                                            } else {
                                                SecureField(L10n.text("placeholder.api_key"), text: $apiKey)
                                            }
                                        }
                                        .textFieldStyle(.roundedBorder)
                                        .font(.body.monospaced())

                                        Button {
                                            showKey.toggle()
                                        } label: {
                                            Image(systemName: showKey ? "eye.slash" : "eye")
                                                .frame(width: 18)
                                        }
                                        .buttonStyle(.borderless)
                                        .help(showKey ? L10n.text("action.hide_key") : L10n.text("action.show_key"))
                                    }
                                }
                            }

                            fieldRow(L10n.text("field.reasoning")) {
                                Picker("", selection: $draft.reasoningEffort) {
                                    ForEach(ReasoningEffort.allCases) { value in
                                        Text(L10n.reasoning(value)).tag(value)
                                    }
                                }
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    card {
                        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 13) {
                            fieldRow(L10n.text("field.notes"), alignment: .top) {
                                TextField(L10n.text("placeholder.notes"), text: $draft.note, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(3...5)
                            }
                        }
                    }

                    if let testResult {
                        ConnectionResultView(report: testResult)
                    }
                }
                .padding(20)
            }

            Divider()
            footer
        }
        .frame(width: 760, height: testResult == nil ? 640 : 750)
        .onAppear {
            showKey = store.preferences.showKeysByDefault
            if let original, original.authentication == .bearer {
                apiKey = store.key(for: original)
            }
        }
        .onChange(of: draft.brand) { brand in
            if draft.baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               let preset = ProviderPreset.baseURL(for: brand) {
                draft.baseURL = preset
            }
            if draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               brand != .automatic, brand != .custom {
                draft.name = brand.displayName
            }
            clearDetectionResults()
        }
        .onChange(of: draft.baseURL) { _ in
            if !applyingDetection { clearDetectionResults() }
        }
        .onChange(of: draft.model) { _ in testResult = nil }
        .onChange(of: draft.authentication) { _ in clearDetectionResults() }
        .onChange(of: apiKey) { _ in clearDetectionResults() }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ProviderIconView(brand: draft.resolvedBrand, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(original == nil ? L10n.text("editor.add_title") : L10n.text("editor.edit_title"))
                    .font(.title3.weight(.semibold))
                Text(L10n.text("editor.subtitle"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button {
                runTest()
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

            Spacer()
            Button(L10n.text("action.cancel")) { dismiss() }
                .keyboardShortcut(.cancelAction)
            Button(L10n.text("action.save")) {
                if store.saveProfile(original: original, draft: draft, apiKey: apiKey) {
                    dismiss()
                }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
        .padding(16)
    }

    @ViewBuilder
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 1)
            }
    }

    private func fieldRow<Content: View>(_ label: String, alignment: VerticalAlignment = .center, @ViewBuilder content: () -> Content) -> some View {
        GridRow(alignment: alignment) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 125, alignment: .trailing)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func clearDetectionResults() {
        testResult = nil
        discoveredModels = []
        modelDiscoveryMessage = nil
    }

    private func adoptResolvedBaseURL(_ baseURL: String?) {
        guard let baseURL, baseURL != draft.baseURL else { return }
        applyingDetection = true
        draft.baseURL = baseURL
        DispatchQueue.main.async { applyingDetection = false }
    }

    private func discoverModels() {
        guard !isDiscoveringModels else { return }
        isDiscoveringModels = true
        modelDiscoveryMessage = nil
        Task {
            let report = await store.discoverModels(draft: draft, apiKey: apiKey)
            adoptResolvedBaseURL(report.resolvedBaseURL)
            discoveredModels = report.models
            modelDiscoveryMessage = report.message
            if draft.model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               let first = report.models.first {
                draft.model = first
            }
            isDiscoveringModels = false
        }
    }

    private func runTest() {
        guard !isTesting else { return }
        isTesting = true
        testResult = nil
        Task {
            let report = await store.test(draft: draft, apiKey: apiKey)
            adoptResolvedBaseURL(report.resolvedBaseURL)
            testResult = report
            isTesting = false
        }
    }
}
