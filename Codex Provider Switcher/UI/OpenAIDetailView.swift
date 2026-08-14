import SwiftUI

struct OpenAIDetailView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 14) {
                    ProviderIconView(brand: .openAI, size: 52)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("OpenAI")
                                .font(.title2.weight(.semibold))
                            if store.isOpenAIActive {
                                Text(L10n.text("status.active"))
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.green.opacity(0.10), in: Capsule())
                            }
                        }
                        Text(L10n.text("official.subtitle"))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        store.activateOpenAI()
                    } label: {
                        Label(L10n.text("action.use_openai"), systemImage: "arrow.uturn.backward")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(store.isOpenAIActive || store.isBusy)
                }

                VStack(spacing: 0) {
                    infoRow(L10n.text("details.provider"), "OpenAI")
                    Divider().padding(.leading, 170)
                    infoRow(L10n.text("official.configuration"), L10n.text("official.original_config"))
                    Divider().padding(.leading, 170)
                    infoRow(L10n.text("details.auth"), L10n.text("official.chatgpt_account"))
                    Divider().padding(.leading, 170)
                    infoRow(L10n.text("official.history"), L10n.text("official.history_value"))
                }
                .padding(.horizontal, 18)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 1)
                }
            }
            .padding(26)
            .frame(maxWidth: 880, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 24) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 145, alignment: .leading)
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 13)
    }
}
