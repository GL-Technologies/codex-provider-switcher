import SwiftUI

struct OpenAIDetailView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppDesign.sectionSpacing) {
                header
                statusCard
                configurationCard
            }
            .padding(AppDesign.pagePadding)
            .frame(maxWidth: AppDesign.pageMaxWidth, alignment: .leading)
        }
        .background(AppDesign.pageBackground)
    }

    private var header: some View {
        HStack(spacing: 16) {
            ProviderIconView(brand: .openAI, size: 58)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text("OpenAI")
                        .font(.title2.weight(.semibold))
                    if store.isOpenAIActive {
                        AppStatusPill(text: L10n.text("status.active"), tone: .success, systemImage: "checkmark")
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
        AppCard(padding: 15) {
            HStack(spacing: 14) {
                AppIconTile(
                    systemImage: store.isOpenAIActive ? "bolt.horizontal.circle.fill" : "circle.dashed",
                    tone: store.isOpenAIActive ? .success : .neutral,
                    size: 42
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(store.isOpenAIActive ? L10n.text("menu.direct_active") : L10n.text("official.original_config"))
                        .font(.headline)
                    Text(L10n.text("official.original_config"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }

    private var configurationCard: some View {
        AppCard {
            VStack(spacing: 0) {
                infoRow(L10n.text("details.provider"), "OpenAI")
                Divider().padding(.leading, 170)
                infoRow(L10n.text("official.configuration"), L10n.text("official.original_config"))
                Divider().padding(.leading, 170)
                infoRow(L10n.text("details.auth"), L10n.text("official.chatgpt_account"))
                Divider().padding(.leading, 170)
                infoRow(L10n.text("official.history"), L10n.text("official.history_value"))
            }
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 24) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: AppDesign.labelColumnWidth, alignment: .leading)
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
    }
}
