import SwiftUI

/// Banking recommendations stage: a simple at-a-glance comparison first, then a
/// detailed card per bank. Preferred selection is highlighted locally for
/// feedback only; authoritative state stays in the ViewModel/backend.
struct BankRecommendationListView: View {
    var viewModel: JourneyViewModel

    /// Local optimistic highlight only — not authoritative backend state.
    @State private var preferredBankID: String?

    private var banks: [BankRecommendation] {
        viewModel.bankingRecommendations?.banks ?? []
    }

    private var state: OutputStageState {
        if viewModel.recoverableError != nil && banks.isEmpty {
            return .error
        }
        guard !banks.isEmpty else {
            return viewModel.isBackendBusy ? .loading : .empty
        }
        return .success
    }

    var body: some View {
        OutputStageContainerView(
            title: "Banking options",
            subtitle: "Accounts that suit your business setup",
            systemImage: "building.columns",
            state: state,
            hasContent: !banks.isEmpty,
            loadingLabel: "Matching banks…",
            emptyLabel: "Bank options appear after your licence path is chosen.",
            recoverableError: viewModel.recoverableError,
            onRetry: { viewModel.retryCurrentStep() }
        ) {
            VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingComfortable) {
                comparison

                VStack(spacing: IrshadTheme.Layout.spacingStandard) {
                    ForEach(banks) { bank in
                        BankRecommendationCardView(
                            bank: bank,
                            isPreferred: preferredBankID == bank.id,
                            viewModel: viewModel
                        )
                    }
                }
            }
        }
    }

    private var comparison: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingTight) {
            Text("Quick comparison")
                .font(IrshadTheme.Typography.statusMicrocopy)
                .foregroundStyle(IrshadTheme.Colors.secondaryText)

            VStack(spacing: 0) {
                ForEach(Array(banks.enumerated()), id: \.element.id) { index, bank in
                    Button {
                        preferredBankID = bank.id
                        viewModel.savePreferredBank(bank.id)
                    } label: {
                        comparisonRow(for: bank)
                    }
                    .buttonStyle(.plain)

                    if index < banks.count - 1 {
                        Divider().overlay(IrshadTheme.Colors.separator)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                    .fill(IrshadTheme.Colors.surfaceTint)
            )
        }
    }

    private func comparisonRow(for bank: BankRecommendation) -> some View {
        HStack(spacing: IrshadTheme.Layout.spacingStandard) {
            Image(systemName: suitabilityImage(bank))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(suitabilityTint(bank))
                .frame(width: 22)
                .accessibilityHidden(true)

            Text(bank.name)
                .font(IrshadTheme.Typography.secondaryLabel)
                .foregroundStyle(IrshadTheme.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(bank.minBalance ?? "—")
                .font(IrshadTheme.Typography.statusMicrocopy)
                .foregroundStyle(IrshadTheme.Colors.secondaryText)

            if preferredBankID == bank.id {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(IrshadTheme.Colors.primaryAccent)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, IrshadTheme.Layout.spacingStandard)
        .frame(minHeight: IrshadTheme.Layout.minimumTapTarget)
        .contentShape(Rectangle())
    }

    private func suitabilityImage(_ bank: BankRecommendation) -> String {
        switch bank.likelyToApprove {
        case .some(true): return "checkmark.circle.fill"
        case .some(false): return "exclamationmark.circle.fill"
        case .none: return "questionmark.circle.fill"
        }
    }

    private func suitabilityTint(_ bank: BankRecommendation) -> Color {
        switch bank.likelyToApprove {
        case .some(true): return IrshadTheme.Colors.success
        case .some(false): return IrshadTheme.Colors.warning
        case .none: return IrshadTheme.Colors.secondaryText
        }
    }
}
