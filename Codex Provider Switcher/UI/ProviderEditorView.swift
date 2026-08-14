import SwiftUI

struct ProviderEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    let original: ProviderProfile?
    @State private var draft: ProviderDraft
    @State private var apiKey = ""
    @State private var showKey = true
    @State private var isTesting = false
    @State private var testResult: ConnectionTestReport?

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
                                TextField(L10n.text("placeholder.base_url"), text: $draft.baseURL)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.body.monospaced())
                            }

                            fieldRow(L10n.text("field.model")) {
                                TextField(L10n.text("placeholder.model"), text: $draft.model)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.body.monospaced())
                            }
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
        .frame(width: 700, height: testResult == nil ? 610 : 720)
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
            testResult = nil
        }
        .onChange(of: draft.baseURL) { _ in testResult = nil }
        .onChange(of: draft.model) { _ in testResult = nil }
        .onChange(of: draft.authentication) { _ in testResult = nil }
        .onChange(of: apiKey) { _ in testResult = nil }
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

    private func runTest() {
        guard !isTesting else { return }
        isTesting = true
        testResult = nil
        Task {
            let report = await store.test(draft: draft, apiKey: apiKey)
            testResult = report
            isTesting = false
        }
    }
}
