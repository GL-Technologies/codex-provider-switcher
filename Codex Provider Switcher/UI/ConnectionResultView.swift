import SwiftUI

struct ConnectionResultView: View {
    let report: ConnectionTestReport

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: report.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(report.success ? Color.green : Color.red)
                Text(report.title).fontWeight(.medium)
                Spacer()
                if let ms = report.durationMilliseconds {
                    Text("\(ms) ms").foregroundStyle(.secondary)
                }
            }
            Text(report.message)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            if let code = report.statusCode {
                Text("HTTP \(code) · \(report.endpoint)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            if let preview = report.responsePreview, !preview.isEmpty {
                DisclosureGroup(L10n.text("test.response")) {
                    Text(preview)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                        .padding(.top, 4)
                }
                .font(.caption)
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
    }
}
