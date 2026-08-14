import SwiftUI

struct ConnectionResultView: View {
    @EnvironmentObject private var store: AppStore
    let report: ConnectionTestReport

    private var bridgeReady: Bool {
        report.success && report.detectedAPI == .chatCompletions && store.autoBridgeEnabled
    }

    private var usable: Bool { report.codexCompatible || bridgeReady }

    private var tone: AppStatusTone {
        if usable { return .success }
        if report.success { return .warning }
        return .danger
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                AppIconTile(systemImage: statusImage, tone: tone, size: 38)

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayTitle)
                        .font(.body.weight(.semibold))
                    Text(displayMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                Spacer(minLength: 12)

                if let ms = report.durationMilliseconds {
                    Text("\(ms) ms")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack(spacing: 8) {
                Text(L10n.text("test.detected_protocol"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                AppStatusPill(
                    text: protocolName,
                    tone: report.codexCompatible ? .success : (bridgeReady ? .accent : .neutral)
                )

                if report.codexCompatible {
                    AppStatusPill(text: L10n.text("bridge.direct_ready"), tone: .success, systemImage: "bolt.fill")
                } else if bridgeReady {
                    AppStatusPill(text: L10n.text("bridge.route_ready"), tone: .accent, systemImage: "arrow.triangle.branch")
                }

                Spacer()
            }

            if let resolved = report.resolvedBaseURL {
                metadataRow(label: "Base URL", value: resolved)
            }

            if let code = report.statusCode {
                metadataRow(label: "HTTP", value: "\(code) · \(report.endpoint)")
            }

            if let preview = report.responsePreview, !preview.isEmpty {
                DisclosureGroup(L10n.text("test.response")) {
                    ScrollView(.horizontal) {
                        Text(preview)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                            .padding(.top, 6)
                    }
                }
                .font(.caption)
            }
        }
        .padding(14)
        .background(tone.color.opacity(0.07), in: RoundedRectangle(cornerRadius: AppDesign.compactRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppDesign.compactRadius, style: .continuous)
                .strokeBorder(tone.color.opacity(0.16), lineWidth: 1)
        }
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 62, alignment: .leading)
            Text(value)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var protocolName: String {
        switch report.detectedAPI {
        case .responses: return "Responses API"
        case .chatCompletions: return "Chat Completions"
        case .unknown: return L10n.text("test.protocol_unknown")
        }
    }
}
