import SwiftUI

struct IrshadToastView: View {
    let message: String
    var systemImage: String?
    var actionTitle: String?
    var onAction: (() -> Void)?
    var onDismiss: (() -> Void)?

    init(
        message: String,
        systemImage: String? = nil,
        actionTitle: String? = nil,
        onAction: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.onAction = onAction
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(spacing: IrshadTheme.Layout.spacingStandard) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(IrshadTheme.Colors.primaryAccent)
                    .accessibilityHidden(true)
            }

            Text(message)
                .font(IrshadTheme.Typography.secondaryLabel)
                .foregroundStyle(IrshadTheme.Colors.primaryText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: IrshadTheme.Layout.spacingTight)

            if let actionTitle, let onAction {
                Button(actionTitle, action: onAction)
                    .font(IrshadTheme.Typography.statusMicrocopy)
                    .foregroundStyle(IrshadTheme.Colors.primaryAccent)
                    .buttonStyle(.plain)
            }

            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .foregroundStyle(IrshadTheme.Colors.secondaryText)
                .accessibilityLabel(Text("Dismiss message"))
                .accessibilityHint(Text("Closes this feedback message."))
            }
        }
        .padding(.horizontal, IrshadTheme.Layout.spacingComfortable)
        .padding(.vertical, IrshadTheme.Layout.spacingStandard)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                        .stroke(IrshadTheme.Colors.separator, lineWidth: 1)
                }
                .irshadShadow(IrshadTheme.Shadows.cardShadow)
        )
        .transition(IrshadTheme.Animations.cardRevealTransition)
        .animation(IrshadTheme.Animations.cardReveal, value: message)
        .accessibilityElement(children: .contain)
    }
}
