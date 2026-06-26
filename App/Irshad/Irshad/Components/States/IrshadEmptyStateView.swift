import SwiftUI

/// Shown when no session exists yet. Explains the single next action and
/// offers both voice and text ways to begin. Never a blank canvas.
struct IrshadEmptyStateView: View {
    var viewModel: JourneyViewModel

    var title: String = "Start your business journey"
    var message: String = "Tell Irshad what you want to set up. You can speak or type — Irshad guides the rest one step at a time."

    private var textBinding: Binding<String> {
        Binding(
            get: { viewModel.textFallbackValue },
            set: { viewModel.updateTextFallback($0) }
        )
    }

    var body: some View {
        VStack(spacing: IrshadTheme.Layout.spacingSection) {
            VStack(spacing: IrshadTheme.Layout.spacingComfortable) {
                Image(systemName: "sparkles")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(IrshadTheme.Colors.primaryAccent)
                    .frame(width: 72, height: 72)
                    .background {
                        Circle().fill(IrshadTheme.Colors.surfaceTint)
                    }
                    .accessibilityHidden(true)

                Text(title)
                    .font(IrshadTheme.Typography.sectionTitle)
                    .foregroundStyle(IrshadTheme.Colors.primaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(message)
                    .font(IrshadTheme.Typography.primaryBody)
                    .foregroundStyle(IrshadTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                viewModel.startJourneyWithVoice()
            } label: {
                Label("Start with voice", systemImage: "mic.fill")
                    .font(IrshadTheme.Typography.statusMicrocopy)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: IrshadTheme.Layout.minimumTapTarget)
            }
            .buttonStyle(DynamicCardPrimaryButtonStyle())
            .accessibilityHint(Text("Begins a new voice journey."))

            TextFallbackInputView(
                text: textBinding,
                isExpanded: false,
                isProcessing: viewModel.isBackendBusy,
                submitTitle: "Start with text"
            ) {
                viewModel.startJourneyWithText(viewModel.textFallbackValue)
            }
        }
        .padding(IrshadTheme.Layout.outerMarginCompact)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                        .stroke(IrshadTheme.Colors.separator, lineWidth: 1)
                }
        )
        .accessibilityElement(children: .contain)
    }
}
