import SwiftUI

struct ToggleAnswerCardView: View {
    let card: DynamicCard
    var viewModel: JourneyViewModel

    private var selectedValue: Bool? {
        guard viewModel.cardAnswerDraft.cardID == card.cardId,
              case .toggle(let value) = viewModel.cardAnswerDraft.value else {
            return nil
        }

        return value
    }

    private var choices: [(label: String, value: Bool, option: DynamicCardOption?)] {
        if card.options.count >= 2 {
            return Array(card.options.prefix(2)).enumerated().map { index, option in
                let explicitValue = option.metadata.bool(for: ["bool", "value_bool", "valueBool", "selected"])
                return (option.label, explicitValue ?? (index == 0), option)
            }
        }

        return [
            (card.metadata.string(for: ["true_label", "trueLabel", "yes_label", "yesLabel"]) ?? "Yes", true, nil),
            (card.metadata.string(for: ["false_label", "falseLabel", "no_label", "noLabel"]) ?? "No", false, nil)
        ]
    }

    var body: some View {
        QuestionCardContainer(
            card: card,
            screenTitle: viewModel.questionScreenTitle,
            validationMessage: viewModel.cardValidationMessage,
            isServiceBusy: viewModel.isServiceBusy,
            showsConfirm: true,
            canSubmit: selectedValue != nil,
            confirmTitle: card.confirmLabel,
            onCopy: card.showsCopyControl ? { viewModel.copyText(card.displayTitle) } : nil,
            onConfirm: { viewModel.submitCardAnswer(card.cardId) }
        ) {
            HStack(spacing: IrshadTheme.Layout.spacingTight) {
                ForEach(Array(choices.enumerated()), id: \.element.value) { index, choice in
                    Button {
                        viewModel.setToggleAnswer(cardID: card.cardId, value: choice.value)
                    } label: {
                        VStack(spacing: IrshadTheme.Layout.spacingTight) {
                            Image(systemName: selectedValue == choice.value ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22, weight: .semibold))

                            Text(choice.label)
                                .font(IrshadTheme.Typography.primaryBody)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.84)
                        }
                        .foregroundStyle(selectedValue == choice.value ? IrshadTheme.Colors.primaryAccent : IrshadTheme.Colors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 88)
                        .padding(IrshadTheme.Layout.spacingStandard)
                        .background(
                            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                                .fill(selectedValue == choice.value ? IrshadTheme.Colors.surfaceTint : IrshadTheme.Colors.surfaceElevated)
                                .overlay {
                                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                                        .stroke(selectedValue == choice.value ? IrshadTheme.Colors.primaryAccent.opacity(0.38) : IrshadTheme.Colors.separator, lineWidth: 1)
                                }
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isServiceBusy)
                    .accessibilityValue(Text(selectedValue == choice.value ? "Selected" : "Not selected"))
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
