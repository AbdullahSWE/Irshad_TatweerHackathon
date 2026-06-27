import Combine
import SwiftUI

/// Presents one mature-journey result at a time so recommendations arrive as a
/// guided flow instead of one stacked information dump.
struct JourneyOutputStageView: View {
    var viewModel: JourneyViewModel

    private var showsStage: Bool {
        viewModel.activeResultScreen != .none || viewModel.savedPlanSummary != nil
    }

    var body: some View {
        if showsStage {
            VStack(spacing: IrshadTheme.Layout.spacingComfortable) {
                switch viewModel.activeResultScreen {
                case .none:
                    EmptyView()
                case .loadingLicense:
                    ResultLoadingProgressView(
                        title: "Finding your license",
                        systemImage: "doc.badge.gearshape",
                        messages: [
                            "Checking license fit",
                            "Comparing official requirements",
                            "Matching your business activity",
                            "Preparing the best option"
                        ],
                        reduceMotion: viewModel.reduceMotionPreferred
                    )
                case .license:
                    LicenseRecommendationCardView(viewModel: viewModel)
                    ContinueResultButton(
                        title: "View banking options",
                        systemImage: "building.columns",
                        isDisabled: viewModel.licenseRecommendation == nil || viewModel.isServiceBusy,
                        action: { viewModel.showBankingOptions() }
                    )
                case .loadingBanking:
                    ResultLoadingProgressView(
                        title: "Finding banking options",
                        systemImage: "building.columns",
                        messages: [
                            "Checking bank account fit",
                            "Comparing bank requirements",
                            "Matching your license profile",
                            "Preparing the best banking options"
                        ],
                        reduceMotion: viewModel.reduceMotionPreferred
                    )
                case .banking:
                    BankRecommendationListView(viewModel: viewModel)
                    ContinueResultButton(
                        title: "Contact government office",
                        systemImage: "phone.connection",
                        isDisabled: viewModel.bankingRecommendations == nil || viewModel.isServiceBusy,
                        action: { viewModel.showAuthorityContacts() }
                    )
                case .authority:
                    VerificationCardView(viewModel: viewModel)
                    ContinueResultButton(
                        title: "Create action plan",
                        systemImage: "map",
                        isDisabled: viewModel.bankingRecommendations == nil || viewModel.isServiceBusy,
                        action: { viewModel.createFinalActionPlan() }
                    )
                case .finalPlan:
                    NextStepChecklistView(viewModel: viewModel)
                    FinalRoadmapView(viewModel: viewModel)
                }

                if viewModel.savedPlanSummary != nil {
                    savedPlanAccess
                }
            }
            .transition(IrshadTheme.Animations.cardRevealTransition)
            .animation(IrshadTheme.Animations.cardReveal, value: viewModel.activeResultScreen)
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

private struct ContinueResultButton: View {
    let title: String
    let systemImage: String
    var isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity, minHeight: IrshadTheme.Layout.minimumTapTarget)
        }
        .buttonStyle(DynamicCardPrimaryButtonStyle())
        .disabled(isDisabled)
    }
}

#Preview {
    ScrollView {
        JourneyOutputStageView(viewModel: AppEnvironment.live.makeJourneyViewModel())
            .padding()
    }
    .background(IrshadTheme.Colors.appBackgroundGradient.ignoresSafeArea())
}
