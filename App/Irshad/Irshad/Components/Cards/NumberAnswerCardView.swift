import SwiftUI

struct NumberAnswerCardView: View {
    let card: DynamicCard
    var viewModel: JourneyViewModel

    private var numberValue: String {
        guard viewModel.cardAnswerDraft.cardID == card.cardId else {
            return ""
        }

        switch viewModel.cardAnswerDraft.value {
        case .numberString(let value), .text(let value):
            return value
        default:
            return ""
        }
    }

    private var selectedOptionID: String? {
        guard viewModel.cardAnswerDraft.cardID == card.cardId,
              case .singleOption(let optionID) = viewModel.cardAnswerDraft.value else {
            return nil
        }

        return optionID
    }

    private var canSubmit: Bool {
        !numberValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedOptionID != nil
    }

    private var numberBinding: Binding<String> {
        Binding(
            get: { numberValue },
            set: { viewModel.updateCardNumber(cardID: card.cardId, value: $0) }
        )
    }

    private var quickRanges: [MetadataDisplayItem] {
        card.metadata.displayItems(for: ["quick_ranges", "quickRanges", "ranges", "suggestions"])
    }

    var body: some View {
        QuestionCardContainer(
            card: card,
            screenTitle: viewModel.questionScreenTitle,
            validationMessage: viewModel.cardValidationMessage,
            isServiceBusy: viewModel.isServiceBusy,
            showsConfirm: true,
            canSubmit: canSubmit,
            confirmTitle: card.confirmLabel,
            onCopy: card.showsCopyControl ? { viewModel.copyText(card.displayTitle) } : nil,
            onConfirm: { viewModel.submitCardAnswer(card.cardId) }
        ) {
            VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
                HStack(spacing: IrshadTheme.Layout.spacingTight) {
                    if let prefix = amountPrefix {
                        Text(prefix)
                            .font(IrshadTheme.Typography.primaryBody)
                            .foregroundStyle(IrshadTheme.Colors.secondaryText)
                    }

                    TextField(card.metadata.string(for: ["placeholder"]) ?? "0", text: numberBinding)
                        .font(IrshadTheme.Typography.primaryBody)
                        .keyboardType(.decimalPad)
                        .textInputAutocapitalization(.never)
                        .disabled(viewModel.isServiceBusy)
                }
                .padding(IrshadTheme.Layout.spacingStandard)
                .frame(minHeight: IrshadTheme.Layout.minimumTapTarget)
                .background(
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                        .fill(IrshadTheme.Colors.surfaceElevated)
                        .overlay {
                            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                                .stroke(IrshadTheme.Colors.separator, lineWidth: 1)
                        }
                )

                if !quickRanges.isEmpty {
                    FlowLayout(spacing: IrshadTheme.Layout.spacingTight) {
                        ForEach(quickRanges) { range in
                            Button(range.title) {
                                viewModel.updateCardNumber(cardID: card.cardId, value: range.value ?? range.title)
                            }
                            .buttonStyle(DynamicCardSecondaryButtonStyle())
                            .disabled(viewModel.isServiceBusy)
                        }
                    }
                }

                if !card.options.isEmpty {
                    VStack(spacing: IrshadTheme.Layout.spacingTight) {
                        ForEach(Array(card.options.enumerated()), id: \.element.id) { index, option in
                            Button {
                                viewModel.selectSingleOption(cardID: card.cardId, optionID: option.id)
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
    }

    private var amountPrefix: String? {
        let currency = card.metadata.string(for: ["currency", "unit", "format"])?.uppercased()
        guard currency == "AED" || currency == "د.إ" else {
            return card.metadata.string(for: ["prefix"])
        }

        return "AED"
    }
}

struct FlowLayout<Content: View>: View {
    var spacing: CGFloat
    @ViewBuilder var content: Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: spacing)], alignment: .leading, spacing: spacing) {
            content
        }
    }
}
