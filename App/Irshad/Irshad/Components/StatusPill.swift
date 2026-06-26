import SwiftUI

struct StatusPill: View {
    enum Tone {
        case neutral
        case active
        case success
        case warning
        case error
        case secondary

        var tint: Color {
            switch self {
            case .neutral:
                IrshadTheme.Colors.unknownTint
            case .active:
                IrshadTheme.Colors.estimatedTint
            case .success:
                IrshadTheme.Colors.verifiedTint
            case .warning:
                IrshadTheme.Colors.unverifiedTint
            case .error:
                IrshadTheme.Colors.missingTint
            case .secondary:
                IrshadTheme.Colors.secondaryStatus.opacity(0.12)
            }
        }

        var foreground: Color {
            switch self {
            case .neutral:
                IrshadTheme.Colors.secondaryText
            case .active:
                IrshadTheme.Colors.primaryAccent
            case .success:
                IrshadTheme.Colors.success
            case .warning:
                IrshadTheme.Colors.warning
            case .error:
                .red
            case .secondary:
                IrshadTheme.Colors.secondaryStatus
            }
        }
    }

    let title: String
    var systemImage: String?
    var tone: Tone
    var showsSpinner: Bool

    init(
        _ title: String,
        systemImage: String? = nil,
        tone: Tone = .neutral,
        showsSpinner: Bool = false
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tone = tone
        self.showsSpinner = showsSpinner
    }

    var body: some View {
        HStack(spacing: 6) {
            if showsSpinner {
                ProgressView()
                    .controlSize(.mini)
                    .tint(tone.foreground)
                    .accessibilityHidden(true)
            } else if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .accessibilityHidden(true)
            }

            Text(title)
                .font(IrshadTheme.Typography.statusMicrocopy)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(tone.foreground)
        .padding(.horizontal, IrshadTheme.Layout.spacingStandard)
        .frame(minHeight: IrshadTheme.Layout.statusPillHeight)
        .background(
            Capsule(style: .continuous)
                .fill(tone.tint)
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(tone.foreground.opacity(0.16), lineWidth: 1)
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(showsSpinner ? "In progress" : statusValue))
    }

    private var statusValue: String {
        switch tone {
        case .neutral:
            "Neutral status"
        case .active:
            "Active status"
        case .success:
            "Success status"
        case .warning:
            "Warning status"
        case .error:
            "Error status"
        case .secondary:
            "Informational status"
        }
    }
}
