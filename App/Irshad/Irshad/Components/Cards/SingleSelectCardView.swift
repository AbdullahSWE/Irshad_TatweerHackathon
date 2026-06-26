import SwiftUI

struct SingleSelectCardView: View {
    let card: DynamicCard
    var viewModel: JourneyViewModel

    private var selectedOptionID: String? {
        guard viewModel.cardAnswerDraft.cardID == card.cardId,
              case .singleOption(let optionID) = viewModel.cardAnswerDraft.value else {
            return nil
        }

        return optionID
    }

    private var shouldAutoSubmit: Bool {
        card.autoSubmits && !card.requiresExplicitConfirmation
    }

    var body: some View {
        QuestionCardContainer(
            card: card,
            validationMessage: viewModel.cardValidationMessage,
            isServiceBusy: viewModel.isServiceBusy,
            showsConfirm: !shouldAutoSubmit,
            canSubmit: selectedOptionID != nil,
            confirmTitle: card.confirmLabel,
            onCopy: card.showsCopyControl ? { viewModel.copyText(card.displayTitle) } : nil,
            onConfirm: { viewModel.submitCardAnswer(card.cardId) }
        ) {
            VStack(spacing: IrshadTheme.Layout.spacingTight) {
                ForEach(card.options) { option in
                    Button {
                        viewModel.selectSingleOption(cardID: card.cardId, optionID: option.id)

                        if shouldAutoSubmit {
                            viewModel.submitCardAnswer(card.cardId)
                        }
                    } label: {
                        DynamicCardOptionRow(
                            title: option.label,
                            subtitle: option.displaySubtitle,
                            leadingSystemImage: option.systemImage,
                            trailingText: option.trailingLabel,
                            isSelected: selectedOptionID == option.id
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isServiceBusy)
                }
            }
        }
    }
}
