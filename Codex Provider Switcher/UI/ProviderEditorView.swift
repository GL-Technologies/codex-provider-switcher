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
            Form {
                Section {
                    LabeledContent(L10n.text("field.name")) {
                        TextField(L10n.text("placeholder.name"), text: $draft.name)
                            .frame(width: 320)
                    }
                    LabeledContent(L10n.text("field.base_url")) {
                        TextField(L10n.text("placeholder.base_url"), text: $draft.baseURL)
                            .frame(width: 320)
                    }
                    LabeledContent(L10n.text("field.model")) {
                        TextField(L10n.text("placeholder.model"), text: $draft.model)
                            .frame(width: 320)
                    }
                }

                Section {
                    LabeledContent(L10n.text("field.authentication")) {
                        Picker("", selection: $draft.authentication) {
                            Text(L10n.text("auth.api_key")).tag(AuthenticationMode.bearer)
                            Text(L10n.text("auth.none")).tag(AuthenticationMode.none)
                        }
                        .labelsHidden()
                        .frame(width: 220)
                    }

                    if draft.authentication == .bearer {
                        LabeledContent(L10n.text("field.api_key")) {
                            HStack(spacing: 6) {
                                Group {
                                    if showKey {
                                        TextField(L10n.text("placeholder.api_key"), text: $apiKey)
                                    } else {
                                        SecureField(L10n.text("placeholder.api_key"), text: $apiKey)
                                    }
                                }
                                .textFieldStyle(.roundedBorder)
                                Button {
                                    showKey.toggle()
                                } label: {
                                    Image(systemName: showKey ? "eye.slash" : "eye")
                                }
                                .buttonStyle(.borderless)
                                .help(showKey ? L10n.text("action.hide_key") : L10n.text("action.show_key"))
                            }
                            .frame(width: 320)
                        }
                    }
                }

                Section {
                    LabeledContent(L10n.text("field.reasoning")) {
                        Picker("", selection: $draft.reasoningEffort) {
                            ForEach(ReasoningEffort.allCases) { value in
                                Text(L10n.reasoning(value)).tag(value)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 220)
                    }
                    LabeledContent(L10n.text("field.notes")) {
                        TextField(L10n.text("placeholder.notes"), text: $draft.note, axis: .vertical)
                            .lineLimit(2...4)
                            .frame(width: 320)
                    }
                }
            }
            .padding(.top, 8)

            if let testResult {
                ConnectionResultView(report: testResult)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
            }

            Divider()
            HStack {
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
        .frame(width: 590, height: testResult == nil ? 520 : 650)
        .navigationTitle(original == nil ? L10n.text("editor.add_title") : L10n.text("editor.edit_title"))
        .onAppear {
            showKey = store.preferences.showKeysByDefault
            if let original, original.authentication == .bearer {
                apiKey = store.key(for: original)
            }
        }
        .onChange(of: draft.baseURL) { _ in testResult = nil }
        .onChange(of: draft.model) { _ in testResult = nil }
        .onChange(of: draft.authentication) { _ in testResult = nil }
        .onChange(of: apiKey) { _ in testResult = nil }
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
