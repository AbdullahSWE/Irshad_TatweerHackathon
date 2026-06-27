import SwiftUI

struct ChecklistCardView: View {
    let card: DynamicCard
    var viewModel: JourneyViewModel

    private var checkedItemIDs: Set<String> {
        guard viewModel.cardAnswerDraft.cardID == card.cardId,
              case .checklist(let itemIDs) = viewModel.cardAnswerDraft.value else {
            return []
        }

        return itemIDs
    }

    private var showsConfirm: Bool {
        card.kind == .question || card.requiresExplicitConfirmation || card.requiresAction
    }

    var body: some View {
        QuestionCardContainer(
            card: card,
            screenTitle: card.kind == .question ? viewModel.questionScreenTitle : nil,
            validationMessage: viewModel.cardValidationMessage,
            isServiceBusy: viewModel.isServiceBusy,
            showsConfirm: showsConfirm,
            canSubmit: !showsConfirm || !checkedItemIDs.isEmpty || card.metadata.bool(for: ["allow_empty", "allowEmpty"]) == true,
            confirmTitle: card.confirmLabel,
            onCopy: card.showsCopyControl ? { viewModel.copyText(card.displayTitle) } : nil,
            onConfirm: { viewModel.submitCardAnswer(card.cardId) }
        ) {
            VStack(spacing: IrshadTheme.Layout.spacingTight) {
                ForEach(Array(card.options.enumerated()), id: \.element.id) { index, item in
                    Button {
                        if item.isLocallyMarkable {
                            viewModel.toggleChecklistItem(cardID: card.cardId, itemID: item.id)
                        }
                    } label: {
                        DynamicCardOptionRow(
                            title: item.label,
                            subtitle: item.displaySubtitle,
                            leadingSystemImage: iconName(for: item),
                            trailingText: item.trailingLabel ?? item.status,
                            isSelected: checkedItemIDs.contains(item.id) || item.status?.lowercased() == "completed" || item.status?.lowercased() == "complete",
                            isEnabled: item.isLocallyMarkable || !viewModel.isServiceBusy
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isServiceBusy || !item.isLocallyMarkable)
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

    private func iconName(for item: DynamicCardOption) -> String {
        if let systemImage = item.systemImage {
            return systemImage
        }

        if checkedItemIDs.contains(item.id) {
            return "checkmark.circle.fill"
        }

        switch item.status?.lowercased() {
        case "available", "ready":
            return "checkmark.seal.fill"
        case "missing", "required":
            return "exclamationmark.circle.fill"
        case "unknown", "not_sure", "not-sure":
            return "questionmark.circle.fill"
        case "completed", "complete", "done":
            return "checkmark.circle.fill"
        default:
            return item.isLocallyMarkable ? "circle" : "info.circle"
        }
    }
}
