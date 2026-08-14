import SwiftUI

struct ConnectionResultView: View {
    @EnvironmentObject private var store: AppStore
    let report: ConnectionTestReport

    private var bridgeReady: Bool {
        report.success && report.detectedAPI == .chatCompletions && store.autoBridgeEnabled
    }

    private var usable: Bool { report.codexCompatible || bridgeReady }

    private var statusColor: Color {
        if usable { return .green }
        if report.success { return .orange }
        return .red
    }

    private var statusImage: String {
        if usable { return "checkmark.circle.fill" }
        if report.success { return "exclamationmark.triangle.fill" }
        return "xmark.circle.fill"
    }

    private var displayTitle: String {
        if bridgeReady { return L10n.text("bridge.test_ready_title") }
        if report.success && report.detectedAPI == .chatCompletions { return L10n.text("bridge.off_title") }
        return report.title
    }

    private var displayMessage: String {
        if bridgeReady { return L10n.text("bridge.test_ready_message") }
        if report.success && report.detectedAPI == .chatCompletions { return L10n.text("bridge.off_message") }
        return report.message
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: statusImage)
                    .foregroundStyle(statusColor)
                Text(displayTitle).fontWeight(.medium)
                Spacer()
                if let ms = report.durationMilliseconds {
                    Text("\(ms) ms").foregroundStyle(.secondary)
                }
            }

            Text(displayMessage)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            HStack(spacing: 7) {
                Text(L10n.text("test.detected_protocol"))
                    .foregroundStyle(.secondary)
                Text(protocolName)
                    .fontWeight(.medium)

                if report.codexCompatible {
                    statusBadge(L10n.text("bridge.direct_ready"), color: .green)
                } else if bridgeReady {
                    statusBadge(L10n.text("bridge.route_ready"), color: .green)
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

    private func statusBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
    }

    private var protocolName: String {
        switch report.detectedAPI {
        case .responses: return "Responses API"
        case .chatCompletions: return "Chat Completions"
        case .unknown: return L10n.text("test.protocol_unknown")
        }
    }
}
