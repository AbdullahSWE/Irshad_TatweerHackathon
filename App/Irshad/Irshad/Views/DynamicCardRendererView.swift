import SwiftUI

struct DynamicCardRendererView: View {
    var viewModel: JourneyViewModel

    private var cardsToRender: [DynamicCard] {
        if let unsupportedCard = viewModel.unsupportedCard {
            return [unsupportedCard]
        }

        if let currentCard = viewModel.currentCard {
            return [currentCard]
        }

        return viewModel.renderableCards
    }

    var body: some View {
        VStack(spacing: IrshadTheme.Layout.spacingComfortable) {
            if let unsupportedCard = viewModel.unsupportedCard {
                UnsupportedCardView(card: unsupportedCard, viewModel: viewModel)
            } else if cardsToRender.isEmpty {
                if viewModel.isServiceBusy {
                    DynamicCardLoadingView()
                }
            } else {
                ForEach(cardsToRender) { card in
                    cardView(for: card)
                }
            }

            if let recoverableError = viewModel.recoverableError {
                InfoBannerView(
                    message: recoverableError.message,
                    systemImage: "exclamationmark.triangle.fill",
                    tone: .warning,
                    actionTitle: "Retry",
                    onAction: { viewModel.retryCurrentStep() }
                )
            } else if viewModel.isServiceBusy && !cardsToRender.isEmpty {
                StatusPill("Updating", systemImage: "arrow.triangle.2.circlepath", tone: .active, showsSpinner: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .animation(
            IrshadTheme.Animations.resolved(IrshadTheme.Animations.progressTransition, reduceMotion: viewModel.reduceMotionPreferred),
            value: viewModel.isServiceBusy
        )
    }

    @ViewBuilder
    private func cardView(for card: DynamicCard) -> some View {
        switch card.type {
        case .singleSelect:
            SingleSelectCardView(card: card, viewModel: viewModel)
        case .multiSelect:
            MultiSelectCardView(card: card, viewModel: viewModel)
        case .text:
            TextAnswerCardView(card: card, viewModel: viewModel)
        case .number:
            NumberAnswerCardView(card: card, viewModel: viewModel)
        case .toggle:
            ToggleAnswerCardView(card: card, viewModel: viewModel)
        case .checklist:
            ChecklistCardView(card: card, viewModel: viewModel)
        case .info:
            InfoCardView(card: card, viewModel: viewModel)
        case .summary:
            SummaryCardView(card: card, viewModel: viewModel)
        case .recommendation:
            RecommendationCardView(card: card, viewModel: viewModel)
        case .roadmap:
            RoadmapCardView(card: card, viewModel: viewModel)
        case .none:
            if card.kind == .info || card.kind == .confirmation {
                InfoCardView(card: card, viewModel: viewModel)
            } else {
                UnsupportedCardView(card: card, viewModel: viewModel)
            }
        case .unsupported:
            UnsupportedCardView(card: card, viewModel: viewModel)
        }
    }
}

private struct DynamicCardLoadingView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(IrshadTheme.Colors.separator)
                .frame(width: 132, height: 14)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(IrshadTheme.Colors.surfaceElevated)
                .frame(height: 22)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(IrshadTheme.Colors.surfaceElevated)
                .frame(height: 54)
        }
        .padding(.horizontal, IrshadTheme.Layout.cardHorizontalPadding)
        .padding(.vertical, IrshadTheme.Layout.cardVerticalPadding)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surface.opacity(0.8))
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                        .stroke(IrshadTheme.Colors.separator, lineWidth: 1)
                }
        )
        .redacted(reason: .placeholder)
        .accessibilityLabel(Text("Loading card"))
    }
}
