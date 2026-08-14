import SwiftUI

struct OpenAIDetailView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                statusCard
                configurationCard
            }
            .padding(28)
            .frame(maxWidth: 900, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 16) {
            ProviderIconView(brand: .openAI, size: 56)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text("OpenAI")
                        .font(.title2.weight(.semibold))
                    if store.isOpenAIActive {
                        Text(L10n.text("status.active"))
                            .font(.caption.weight(.semibold))
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
    }

    private var statusCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: "bolt.horizontal.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.text("menu.direct_active"))
                    .font(.headline)
                Text(L10n.text("official.original_config"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.50), lineWidth: 1)
        }
    }

    private var configurationCard: some View {
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
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.50), lineWidth: 1)
        }
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
