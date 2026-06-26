import SwiftUI

struct InfoBannerView: View {
    enum Tone {
        case neutral
        case info
        case success
        case warning
        case error

        var iconColor: Color {
            switch self {
            case .neutral:
                IrshadTheme.Colors.secondaryText
            case .info:
                IrshadTheme.Colors.primaryAccent
            case .success:
                IrshadTheme.Colors.success
            case .warning:
                IrshadTheme.Colors.warning
            case .error:
                .red
            }
        }

        var background: Color {
            switch self {
            case .neutral:
                IrshadTheme.Colors.surfaceElevated
            case .info:
                IrshadTheme.Colors.surfaceTint
            case .success:
                IrshadTheme.Colors.verifiedTint
            case .warning:
                IrshadTheme.Colors.unverifiedTint
            case .error:
                IrshadTheme.Colors.missingTint
            }
        }
    }

    let message: String
    var systemImage: String
    var tone: Tone
    var actionTitle: String?
    var onAction: (() -> Void)?
    var onDismiss: (() -> Void)?

    init(
        message: String,
        systemImage: String = "info.circle.fill",
        tone: Tone = .info,
        actionTitle: String? = nil,
        onAction: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.message = message
        self.systemImage = systemImage
        self.tone = tone
        self.actionTitle = actionTitle
        self.onAction = onAction
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingStandard) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tone.iconColor)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)

            Text(message)
                .font(IrshadTheme.Typography.secondaryLabel)
                .foregroundStyle(IrshadTheme.Colors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let actionTitle, let onAction {
                Button(actionTitle, action: onAction)
                    .font(IrshadTheme.Typography.statusMicrocopy)
                    .foregroundStyle(tone.iconColor)
                    .buttonStyle(.plain)
                    .padding(.top, 2)
            }

            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .foregroundStyle(IrshadTheme.Colors.secondaryText)
                .accessibilityLabel(Text("Dismiss banner"))
                .accessibilityHint(Text("Closes this information banner."))
            }
        }
        .padding(IrshadTheme.Layout.bannerPadding)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                .fill(tone.background)
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                        .stroke(tone.iconColor.opacity(0.16), lineWidth: 1)
                }
        )
        .accessibilityElement(children: .contain)
    }
}
