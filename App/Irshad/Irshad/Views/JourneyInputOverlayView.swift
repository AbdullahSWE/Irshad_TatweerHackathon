import SwiftUI

/// Anchored bottom layer of the journey: the voice/text input dock with toasts
/// floating just above it. Stays reachable near the lower safe area, respects the
/// keyboard, and never lets transient feedback cover the primary input actions.
struct JourneyInputOverlayView: View {
    var viewModel: JourneyViewModel

    var body: some View {
        VStack(spacing: IrshadTheme.Layout.spacingStandard) {
            if let toast = viewModel.toast {
                IrshadToastView(
                    message: toast.message,
                    systemImage: "info.circle.fill",
                    onDismiss: viewModel.dismissToast
                )
                .padding(.horizontal, IrshadTheme.Layout.outerMarginCompact)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if !viewModel.isChoiceQuestionActive && !viewModel.isAdditionalContextPromptActive {
                InputDockView(viewModel: viewModel, isWelcome: false)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .bottom)
        .animation(IrshadTheme.Animations.cardReveal, value: viewModel.toast)
        .animation(IrshadTheme.Animations.cardReveal, value: viewModel.isChoiceQuestionActive)
        .animation(IrshadTheme.Animations.cardReveal, value: viewModel.isAdditionalContextPromptActive)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        IrshadTheme.Colors.appBackgroundGradient.ignoresSafeArea()
        JourneyInputOverlayView(viewModel: AppEnvironment.live.makeJourneyViewModel())
    }
}
