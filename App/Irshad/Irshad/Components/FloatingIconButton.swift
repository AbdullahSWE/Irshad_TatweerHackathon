import SwiftUI

struct FloatingIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    var accessibilityHint: String?
    var isEnabled: Bool
    var isActive: Bool
    var onTap: () -> Void

    @GestureState private var isPressed = false

    init(
        systemImage: String,
        accessibilityLabel: String,
        accessibilityHint: String? = nil,
        isEnabled: Bool = true,
        isActive: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.isEnabled = isEnabled
        self.isActive = isActive
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(
                    width: IrshadTheme.Layout.minimumTapTarget,
                    height: IrshadTheme.Layout.minimumTapTarget
                )
                .background(background)
                .scaleEffect(isPressed ? 0.95 : 1)
                .opacity(isEnabled ? 1 : 0.48)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text(accessibilityHint ?? (isEnabled ? "Activates this control." : "This control is currently unavailable.")))
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressed) { _, state, _ in
                    state = isEnabled
                }
        )
        .animation(IrshadTheme.Animations.buttonFeedback, value: isPressed)
        .animation(IrshadTheme.Animations.buttonFeedback, value: isEnabled)
    }

    private var iconColor: Color {
        if !isEnabled {
            return IrshadTheme.Colors.tertiaryText
        }
        return isActive ? IrshadTheme.Colors.primaryAccent : IrshadTheme.Colors.primaryText
    }

    private var background: some View {
        Circle()
            .fill(IrshadTheme.Colors.surface)
            .overlay {
                Circle()
                    .stroke(
                        isActive ? IrshadTheme.Colors.primaryAccent.opacity(0.38) : IrshadTheme.Colors.primaryAccent.opacity(0.16),
                        lineWidth: 1
                    )
            }
            .overlay {
                Circle()
                    .fill(IrshadTheme.Colors.surfaceTint.opacity(isActive ? 0.95 : 0.38))
                    .padding(1)
            }
            .irshadShadow(IrshadTheme.Shadows.floatingControlShadow)
    }
}
