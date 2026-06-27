import SwiftUI

struct MultiSelectCardView: View {
    let card: DynamicCard
    var viewModel: JourneyViewModel

    private var selectedOptionIDs: Set<String> {
        guard viewModel.cardAnswerDraft.cardID == card.cardId,
              case .multiOptions(let optionIDs) = viewModel.cardAnswerDraft.value else {
            return []
        }

        return optionIDs
    }

    var body: some View {
        QuestionCardContainer(
            card: card,
            screenTitle: viewModel.questionScreenTitle,
            validationMessage: viewModel.cardValidationMessage,
            isServiceBusy: viewModel.isServiceBusy,
            showsConfirm: true,
            canSubmit: !selectedOptionIDs.isEmpty,
            confirmTitle: card.confirmLabel,
            onCopy: card.showsCopyControl ? { viewModel.copyText(card.displayTitle) } : nil,
            onConfirm: { viewModel.submitCardAnswer(card.cardId) }
        ) {
            VStack(spacing: IrshadTheme.Layout.spacingTight) {
                ForEach(Array(card.options.enumerated()), id: \.element.id) { index, option in
                    Button {
                        viewModel.toggleMultiOption(cardID: card.cardId, optionID: option.id)
                    } label: {
                        DynamicCardOptionRow(
                            title: option.label,
                            subtitle: option.displaySubtitle,
                            leadingSystemImage: selectedOptionIDs.contains(option.id) ? "checkmark.square.fill" : "square",
                            trailingText: option.trailingLabel,
                            isSelected: selectedOptionIDs.contains(option.id)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isServiceBusy)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .animation(
                        IrshadTheme.Animations.resolved(
                            .easeOut(duration: 0.28).delay(Double(index) * 0.04),
                            reduceMotion: viewModel.reduceMotionPreferred
                        ),
                        value: card.cardId
                    )
                }
            }
        }
    }
}
