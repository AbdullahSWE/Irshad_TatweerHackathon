import SwiftUI

/// Ordered, practical next-step checklist. Items can be marked done locally
/// through the ViewModel; the view never holds authoritative backend state.
struct NextStepChecklistView: View {
    var viewModel: JourneyViewModel

    private var items: [NextStepChecklistItem] {
        viewModel.nextStepChecklist
    }

    private var state: OutputStageState {
        if viewModel.recoverableError != nil && items.isEmpty {
            return .error
        }
        guard !items.isEmpty else {
            return viewModel.isBackendBusy ? .loading : .empty
        }
        return .success
    }

    private var doneCount: Int {
        items.filter(\.isDone).count
    }

    var body: some View {
        OutputStageContainerView(
            title: "Your next steps",
            subtitle: doneCount > 0 ? "\(doneCount) of \(items.count) done" : "Practical steps to move forward",
            systemImage: "checklist",
            state: state,
            hasContent: !items.isEmpty,
            loadingLabel: "Preparing steps…",
            emptyLabel: "Next steps appear once your plan takes shape.",
            recoverableError: viewModel.recoverableError,
            onRetry: { viewModel.retryCurrentStep() }
        ) {
            VStack(spacing: IrshadTheme.Layout.spacingTight) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    row(index: index, item: item)
                }
            }
        }
    }

    private func row(index: Int, item: NextStepChecklistItem) -> some View {
        Button {
            viewModel.markNextStepDone(item.id)
        } label: {
            HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingStandard) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(item.isDone ? IrshadTheme.Colors.success : IrshadTheme.Colors.tertiaryText)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(index + 1).")
                            .font(IrshadTheme.Typography.secondaryLabel)
                            .foregroundStyle(IrshadTheme.Colors.secondaryText)

                        Text(item.title)
                            .font(IrshadTheme.Typography.primaryBody)
                            .foregroundStyle(IrshadTheme.Colors.primaryText)
                            .strikethrough(item.isDone, color: IrshadTheme.Colors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let detail = item.detail, !detail.isEmpty {
                        Text(detail)
                            .font(IrshadTheme.Typography.secondaryLabel)
                            .foregroundStyle(IrshadTheme.Colors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(IrshadTheme.Layout.spacingStandard)
            .frame(maxWidth: .infinity, minHeight: IrshadTheme.Layout.minimumTapTarget, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                    .fill(item.isDone ? IrshadTheme.Colors.verifiedTint : IrshadTheme.Colors.surfaceElevated)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Step \(index + 1): \(item.title)"))
        .accessibilityValue(Text(item.isDone ? "Done" : "Not done"))
        .accessibilityHint(Text("Double tap to toggle done."))
    }
}
