import SwiftUI

/// Shared visual language for the macOS app.
/// Keep values centralized so the sidebar, sheets, detail pages and settings
/// evolve as one system instead of accumulating one-off spacing and surfaces.
enum AppDesign {
    static let pageMaxWidth: CGFloat = 920
    static let pagePadding: CGFloat = 28
    static let sectionSpacing: CGFloat = 18
    static let cardPadding: CGFloat = 18
    static let cardRadius: CGFloat = 14
    static let compactRadius: CGFloat = 10
    static let labelColumnWidth: CGFloat = 140

    static var pageBackground: Color { Color(nsColor: .windowBackgroundColor) }
    static var surface: Color { Color(nsColor: .controlBackgroundColor) }
    static var secondarySurface: Color { Color(nsColor: .underPageBackgroundColor) }
    static var separator: Color { Color(nsColor: .separatorColor).opacity(0.48) }
    static var subtleFill: Color { Color(nsColor: .quaternaryLabelColor).opacity(0.10) }
}

enum AppStatusTone {
    case accent
    case success
    case warning
    case danger
    case neutral

    var color: Color {
        switch self {
        case .accent: return .accentColor
        case .success: return .green
        case .warning: return .orange
        case .danger: return .red
        case .neutral: return .secondary
        }
    }
}

struct AppCard<Content: View>: View {
    private let content: Content
    private let padding: CGFloat

    init(padding: CGFloat = AppDesign.cardPadding, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppDesign.surface, in: RoundedRectangle(cornerRadius: AppDesign.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppDesign.cardRadius, style: .continuous)
                    .strokeBorder(AppDesign.separator, lineWidth: 1)
            }
    }
}

struct AppStatusPill: View {
    let text: String
    var tone: AppStatusTone = .neutral
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.bold))
            }
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(tone.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tone.color.opacity(0.11), in: Capsule())
    }
}

struct AppIconTile: View {
    let systemImage: String
    var tone: AppStatusTone = .accent
    var size: CGFloat = 42

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(tone.color.opacity(0.12))
            Image(systemName: systemImage)
                .font(.system(size: size * 0.43, weight: .semibold))
                .foregroundStyle(tone.color)
        }
        .frame(width: size, height: size)
    }
}

struct AppSectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline)
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct AppEmptyState: View {
    let systemImage: String
    let title: String
    var message: String? = nil

    var body: some View {
        VStack(spacing: 10) {
            AppIconTile(systemImage: systemImage, tone: .neutral, size: 48)
            Text(title)
                .font(.headline)
            if let message, !message.isEmpty {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .padding(.vertical, 14)
    }
}

struct AppInlineStatus: View {
    let title: String
    var detail: String? = nil
    let systemImage: String
    var tone: AppStatusTone = .neutral

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tone.color)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.weight(.semibold))
                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(tone.color.opacity(0.075), in: RoundedRectangle(cornerRadius: AppDesign.compactRadius, style: .continuous))
    }
}
