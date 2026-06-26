import SwiftUI

/// Scrolling spine of the journey: header for orientation, the current prompt and
/// active card at the centre of attention, progressive profile context, and the
/// output stage. Keeps the active prompt/card reachable and moves VoiceOver focus
/// to it whenever the backend supplies a new step.
struct JourneyContentView: View {
    var viewModel: JourneyViewModel

    private enum AnchorID: Hashable {
        case prompt
        case output
    }

    @AccessibilityFocusState private var promptFocused: Bool

    /// Bottom inset so the anchored input dock never covers scrolling content.
    private var bottomInset: CGFloat {
        IrshadTheme.Layout.bottomDockHeight + IrshadTheme.Layout.spacingMajor * 2
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: IrshadTheme.Layout.spacingSection) {
                    JourneyHeaderView(
                        viewModel: viewModel,
                        onRetry: { viewModel.retryCurrentStep() },
                        onCancel: { viewModel.cancelCurrentOperation() }
                    )

                    CurrentPromptView(
                        currentPrompt: viewModel.currentPrompt,
                        framingMessage: viewModel.framingMessage,
                        currentAssistantMessage: viewModel.currentAssistantMessage,
                        isBackendBusy: viewModel.isBackendBusy,
                        journeyStatus: viewModel.journeyStatus
                    )
                    .id(AnchorID.prompt)
                    .accessibilityFocused($promptFocused)
                    .accessibilityAddTraits(.isHeader)

                    DynamicCardRendererView(viewModel: viewModel)

                    BusinessProfileSummaryView(viewModel: viewModel)

                    JourneyOutputStageView(viewModel: viewModel)
                        .id(AnchorID.output)
                }
                .padding(.horizontal, IrshadTheme.Layout.outerMarginCompact)
                .padding(.top, IrshadTheme.Layout.spacingComfortable)
                .padding(.bottom, bottomInset)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.currentPrompt) { _, _ in
                focusActivePrompt(using: proxy)
            }
            .onChange(of: viewModel.currentCard?.id) { _, _ in
                focusActivePrompt(using: proxy)
            }
            .onChange(of: viewModel.journeyStatus) { _, newValue in
                revealOutputIfNeeded(for: newValue, using: proxy)
            }
        }
    }

    /// Keep the freshly supplied prompt/card in view and hand VoiceOver focus to
    /// its title so users always land on the current step.
    private func focusActivePrompt(using proxy: ScrollViewProxy) {
        withAnimation(IrshadTheme.Animations.cardReveal) {
            proxy.scrollTo(AnchorID.prompt, anchor: .top)
        }
        promptFocused = true
    }

    private func revealOutputIfNeeded(for status: JourneyStatus, using proxy: ScrollViewProxy) {
        switch status {
        case .showingResults, .complete, .partial:
            withAnimation(IrshadTheme.Animations.cardReveal) {
                proxy.scrollTo(AnchorID.output, anchor: .top)
            }
        default:
            break
        }
    }
}

#Preview {
    JourneyContentView(viewModel: AppEnvironment.live.makeJourneyViewModel())
        .background(IrshadTheme.Colors.appBackgroundGradient.ignoresSafeArea())
}
