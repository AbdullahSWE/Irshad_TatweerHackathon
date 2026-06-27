import SwiftUI

/// Scrolling spine of the journey: header for orientation, the service-provided
/// card at the centre of attention, progressive profile context, and the output
/// stage. Keeps the active card reachable and moves VoiceOver focus to it
/// whenever the service supplies a new step.
struct JourneyContentView: View {
    var viewModel: JourneyViewModel

    private enum AnchorID: Hashable {
        case card
        case output
    }

    @AccessibilityFocusState private var cardFocused: Bool

    /// Bottom inset so the anchored input dock never covers scrolling content.
    private var bottomInset: CGFloat {
        if viewModel.isChoiceQuestionActive {
            return IrshadTheme.Layout.spacingMajor
        }

        return IrshadTheme.Layout.bottomDockHeight + IrshadTheme.Layout.spacingMajor * 2
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

                    DynamicCardRendererView(viewModel: viewModel)
                        .id(AnchorID.card)
                        .accessibilityFocused($cardFocused)

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
                focusActiveCard(using: proxy)
            }
            .onChange(of: viewModel.currentCard?.id) { _, _ in
                focusActiveCard(using: proxy)
            }
            .onChange(of: viewModel.journeyStatus) { _, newValue in
                revealOutputIfNeeded(for: newValue, using: proxy)
            }
        }
    }

    /// Keep the freshly supplied card in view and hand VoiceOver focus to its
    /// rendered surface so users always land on the current step.
    private func focusActiveCard(using proxy: ScrollViewProxy) {
        withAnimation(IrshadTheme.Animations.cardReveal) {
            proxy.scrollTo(AnchorID.card, anchor: .top)
        }
        cardFocused = true
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
