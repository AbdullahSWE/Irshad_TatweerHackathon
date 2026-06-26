import SwiftUI

/// Composes the mature-journey output cards (analysis, license, banking,
/// verification, next steps, final roadmap) into a single ordered stage. A card
/// appears only when the ViewModel supplies its state, or while that stage is
/// actively generating — so users never face a wall of locked placeholders.
/// Each card owns its own surface, loading, partial, and error chrome.
struct JourneyOutputStageView: View {
    var viewModel: JourneyViewModel

    private var isGeneratingOutput: Bool {
        viewModel.isBackendBusy && (
            viewModel.journeyStatus == .processing
                || viewModel.journeyStatus == .gateOpen
                || viewModel.journeyStatus == .showingResults
        )
    }

    private var hasAnalysis: Bool { viewModel.analysisSummary != nil }
    private var hasLicense: Bool { viewModel.licenseRecommendation != nil }
    private var hasBanking: Bool { viewModel.bankingRecommendations != nil }
    private var hasVerification: Bool {
        viewModel.verificationSummary != nil
            || !viewModel.verifiedFacts.isEmpty
            || !viewModel.unverifiedFacts.isEmpty
    }
    private var hasNextSteps: Bool { !viewModel.nextStepChecklist.isEmpty }
    private var hasFinalPlan: Bool { viewModel.finalPlan != nil }

    private var showsStage: Bool {
        hasAnalysis || hasLicense || hasBanking || hasVerification
            || hasNextSteps || hasFinalPlan || isGeneratingOutput
    }

    var body: some View {
        if showsStage {
            VStack(spacing: IrshadTheme.Layout.spacingComfortable) {
                if hasAnalysis || isGeneratingOutput {
                    AnalysisSummaryCardView(viewModel: viewModel)
                }

                if hasLicense {
                    LicenseRecommendationCardView(viewModel: viewModel)
                }

                if hasBanking {
                    BankRecommendationListView(viewModel: viewModel)
                }

                if hasVerification {
                    VerificationCardView(viewModel: viewModel)
                }

                if hasNextSteps {
                    NextStepChecklistView(viewModel: viewModel)
                }

                if hasFinalPlan {
                    FinalRoadmapView(viewModel: viewModel)
                }

                if viewModel.savedPlanSummary != nil {
                    savedPlanAccess
                }
            }
            .transition(IrshadTheme.Animations.cardRevealTransition)
            .animation(IrshadTheme.Animations.cardReveal, value: viewModel.journeyStatus)
            .accessibilityElement(children: .contain)
        }
    }

    private var savedPlanAccess: some View {
        Button {
            viewModel.openSavedPlan()
        } label: {
            Label("View saved plan", systemImage: "tray.full")
                .font(IrshadTheme.Typography.secondaryLabel)
                .frame(maxWidth: .infinity, minHeight: IrshadTheme.Layout.minimumTapTarget)
        }
        .buttonStyle(.plain)
        .foregroundStyle(IrshadTheme.Colors.primaryAccent)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surfaceTint)
        )
    }
}

#Preview {
    ScrollView {
        JourneyOutputStageView(viewModel: AppEnvironment.live.makeJourneyViewModel())
            .padding()
    }
    .background(IrshadTheme.Colors.appBackgroundGradient.ignoresSafeArea())
}
