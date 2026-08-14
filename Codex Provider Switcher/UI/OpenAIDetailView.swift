import SwiftUI

struct OpenAIDetailView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 8) {
                Text("OpenAI")
                    .font(.title2.weight(.semibold))
                if store.isOpenAIActive {
                    Text(L10n.text("status.active"))
                        .font(.caption)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                }
            }

            Text(L10n.text("official.subtitle"))
                .foregroundStyle(.secondary)

            Button(L10n.text("action.use_openai")) {
                store.activateOpenAI()
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.isOpenAIActive || store.isBusy)

            Spacer()
        }
        .padding(28)
    }
}
