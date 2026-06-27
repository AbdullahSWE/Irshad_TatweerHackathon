import SwiftUI

struct TextAnswerCardView: View {
    let card: DynamicCard
    var viewModel: JourneyViewModel

    private var textValue: String {
        guard viewModel.cardAnswerDraft.cardID == card.cardId,
              case .text(let value) = viewModel.cardAnswerDraft.value else {
            return ""
        }

        return value
    }

    private var textBinding: Binding<String> {
        Binding(
            get: { textValue },
            set: { viewModel.updateCardText(cardID: card.cardId, value: $0) }
        )
    }

    var body: some View {
        QuestionCardContainer(
            card: card,
            screenTitle: viewModel.questionScreenTitle,
            validationMessage: viewModel.cardValidationMessage,
            isServiceBusy: viewModel.isServiceBusy,
            showsConfirm: true,
            canSubmit: !textValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            confirmTitle: card.confirmLabel,
            onCopy: card.showsCopyControl ? { viewModel.copyText(card.displayTitle) } : nil,
            onConfirm: { viewModel.submitCardAnswer(card.cardId) }
        ) {
            TextEditor(text: textBinding)
                .font(IrshadTheme.Typography.primaryBody)
                .foregroundStyle(IrshadTheme.Colors.primaryText)
                .scrollContentBackground(.hidden)
                .frame(minHeight: CGFloat(card.metadata.number(for: ["min_height", "minHeight"]) ?? 112))
                .padding(IrshadTheme.Layout.spacingStandard)
                .background(
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                        .fill(IrshadTheme.Colors.surfaceElevated)
                        .overlay {
                            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                                .stroke(IrshadTheme.Colors.separator, lineWidth: 1)
                        }
                )
                .accessibilityLabel(Text(card.displayTitle))
        }
    }
}
