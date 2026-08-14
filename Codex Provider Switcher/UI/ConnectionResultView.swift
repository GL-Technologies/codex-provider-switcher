import SwiftUI

struct ConnectionResultView: View {
    let report: ConnectionTestReport

    private var statusColor: Color {
        if report.codexCompatible { return .green }
        if report.success { return .orange }
        return .red
    }

    private var statusImage: String {
        if report.codexCompatible { return "checkmark.circle.fill" }
        if report.success { return "exclamationmark.triangle.fill" }
        return "xmark.circle.fill"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: statusImage)
                    .foregroundStyle(statusColor)
                Text(report.title).fontWeight(.medium)
                Spacer()
                if let ms = report.durationMilliseconds {
                    Text("\(ms) ms").foregroundStyle(.secondary)
                }
            }
            Text(report.message)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            HStack(spacing: 7) {
                Text(L10n.text("test.detected_protocol"))
                    .foregroundStyle(.secondary)
                Text(protocolName)
                    .fontWeight(.medium)
                if report.codexCompatible {
                    Text(L10n.text("test.codex_direct"))
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.12), in: Capsule())
                }
            }
            .font(.caption)

            if let resolved = report.resolvedBaseURL {
                Text("Base URL · \(resolved)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

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
        .background(statusColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
    }

    private var protocolName: String {
        switch report.detectedAPI {
        case .responses: return "Responses API"
        case .chatCompletions: return "Chat Completions"
        case .unknown: return L10n.text("test.protocol_unknown")
        }
    }
}
