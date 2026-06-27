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
                            "Checking license fit for your activity",
                            "Comparing official requirements",
                            "Reviewing cost and timing signals",
                            "Preparing the strongest match"
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
                            "Checking account fit",
                            "Comparing bank requirements",
                            "Reviewing documents and balances",
                            "Shortlisting practical options"
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

private struct ResultLoadingProgressView: View {
    let title: String
    let systemImage: String
    let messages: [String]
    var reduceMotion: Bool

    @State private var startedAt = Date()
    @State private var progress = 0.0
    @State private var messageIndex = 0

    private let duration = 8.0
    private let timer = Timer.publish(every: 0.12, on: .main, in: .common).autoconnect()

    private var currentMessage: String {
        guard !messages.isEmpty else { return "Preparing your recommendation" }
        return messages[min(messageIndex, messages.count - 1)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingComfortable) {
            HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingStandard) {
                ProcessingOrbView(symbolName: systemImage, title: title, isActive: true)
                    .frame(width: 58, height: 58)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingTight) {
                    Text(title)
                        .font(IrshadTheme.Typography.cardTitle)
                        .foregroundStyle(IrshadTheme.Colors.primaryText)

                    Text(currentMessage)
                        .font(IrshadTheme.Typography.secondaryLabel)
                        .foregroundStyle(IrshadTheme.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .contentTransition(reduceMotion ? .identity : .opacity)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            progressBar

            StatusPill("Preparing", tone: .active, showsSpinner: true)
        }
        .padding(.horizontal, IrshadTheme.Layout.cardHorizontalPadding)
        .padding(.vertical, IrshadTheme.Layout.cardVerticalPadding)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                        .stroke(IrshadTheme.Colors.separator, lineWidth: 1)
                }
        )
        .irshadShadow(IrshadTheme.Shadows.cardShadow)
        .onAppear {
            startedAt = Date()
            progress = 0
            messageIndex = 0
        }
        .onReceive(timer) { now in
            let elapsed = now.timeIntervalSince(startedAt)
            let normalized = min(max(elapsed / duration, 0), 1)
            progress = normalized

            guard !messages.isEmpty else { return }
            let nextIndex = min(Int(elapsed / (duration / Double(messages.count))), messages.count - 1)
            if nextIndex != messageIndex {
                if reduceMotion {
                    messageIndex = nextIndex
                } else {
                    withAnimation(IrshadTheme.Animations.cardReveal) {
                        messageIndex = nextIndex
                    }
                }
            }
        }
        .animation(reduceMotion ? nil : IrshadTheme.Animations.progressTransition, value: progress)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(currentMessage))
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(IrshadTheme.Colors.progressTrack)
                Capsule(style: .continuous)
                    .fill(IrshadTheme.Colors.primaryAccent)
                    .frame(width: proxy.size.width * progress)
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }
}

#Preview {
    ScrollView {
        JourneyOutputStageView(viewModel: AppEnvironment.live.makeJourneyViewModel())
            .padding()
    }
    .background(IrshadTheme.Colors.appBackgroundGradient.ignoresSafeArea())
}
