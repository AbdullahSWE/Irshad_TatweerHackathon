import SwiftUI

/// Composes the mature-journey output cards (analysis, license, banking,
/// verification, next steps, final roadmap) into a single ordered stage. A card
/// appears only when the ViewModel supplies its state, or while that stage is
/// actively generating — so users never face a wall of locked placeholders.
/// Each card owns its own surface, loading, partial, and error chrome.
struct JourneyOutputStageView: View {
    var viewModel: JourneyViewModel

    private var isGeneratingOutput: Bool {
        viewModel.isServiceBusy && (
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
            || (viewModel.isServiceBusy && viewModel.currentPhase == .verify && !viewModel.shouldShowVerificationDecision)
    }
    private var hasNextSteps: Bool { !viewModel.nextStepChecklist.isEmpty }
    private var hasFinalPlan: Bool { viewModel.finalPlan != nil }

    private var showsStage: Bool {
        hasAnalysis || hasLicense || hasBanking || hasVerification
            || viewModel.shouldShowVerificationDecision || hasNextSteps || hasFinalPlan || isGeneratingOutput
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

                if viewModel.shouldShowVerificationDecision {
                    AuthorityVerificationChoiceView(viewModel: viewModel)
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

private struct AuthorityVerificationChoiceView: View {
    var viewModel: JourneyViewModel

    private var licenseName: String {
        viewModel.licenseRecommendation?.best?.type ?? "the recommended license"
    }

    private var authorityName: String? {
        viewModel.licenseRecommendation?.best?.metadata.string(for: ["authority"])
    }

    private var phone: String? {
        viewModel.licenseRecommendation?.best?.metadata.string(for: ["phone"])
    }

    private var contactURL: URL? {
        viewModel.licenseRecommendation?.best?.metadata.string(for: ["url"]).flatMap(URL.init(string:))
    }

    var body: some View {
        OutputStageContainerView(
            title: "Authority verification",
            subtitle: "Optional check before the final roadmap",
            systemImage: "phone.connection",
            state: .partial,
            hasContent: true,
            loadingLabel: "Preparing verification…",
            emptyLabel: "",
            partialNote: "Confirm fees, approvals, and timing before you apply.",
            recoverableError: nil,
            onRetry: nil
        ) {
            VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingComfortable) {
                Text("Do you want Irshad to prepare an authority verification summary for \(licenseName)?")
                    .font(IrshadTheme.Typography.secondaryLabel)
                    .foregroundStyle(IrshadTheme.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                if let authorityName {
                    OutputDetailRow(label: "Authority", value: authorityName, systemImage: "building.2")
                }

                HStack(spacing: IrshadTheme.Layout.spacingTight) {
                    if let contactURL {
                        Button {
                            viewModel.openURL(contactURL)
                        } label: {
                            Label("Authority page", systemImage: "safari")
                        }
                        .buttonStyle(DynamicCardSecondaryButtonStyle())
                    }

                    if let phone {
                        Button {
                            viewModel.callPhoneNumber(phone)
                        } label: {
                            Label(phone, systemImage: "phone.fill")
                        }
                        .buttonStyle(DynamicCardSecondaryButtonStyle())
                    }
                }

                HStack(spacing: IrshadTheme.Layout.spacingStandard) {
                    Button {
                        viewModel.skipVerificationAndCreatePlan()
                    } label: {
                        Label("Skip", systemImage: "arrow.forward")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(DynamicCardSecondaryButtonStyle())

                    Button {
                        viewModel.verifyBeforeFinalPlan()
                    } label: {
                        Label("Verify now", systemImage: "checkmark.shield")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(DynamicCardPrimaryButtonStyle())
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        JourneyOutputStageView(viewModel: AppEnvironment.live.makeJourneyViewModel())
            .padding()
    }
    .background(IrshadTheme.Colors.appBackgroundGradient.ignoresSafeArea())
}
