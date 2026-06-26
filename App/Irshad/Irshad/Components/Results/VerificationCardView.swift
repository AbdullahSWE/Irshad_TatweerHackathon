import SwiftUI

/// Authority verification card. Separates confirmed facts from requirements that
/// still need confirmation, and surfaces the official authority, the exact
/// question to ask, and contact actions — but only when the backend supplied
/// them. Contact details are never invented.
struct VerificationCardView: View {
    var viewModel: JourneyViewModel

    private var summary: VerificationSummary? {
        viewModel.verificationSummary
    }

    private var hasContent: Bool {
        summary != nil || !viewModel.verifiedFacts.isEmpty || !viewModel.unverifiedFacts.isEmpty
    }

    private var state: OutputStageState {
        if viewModel.recoverableError != nil && !hasContent {
            return .error
        }
        guard hasContent else {
            return viewModel.isBackendBusy ? .loading : .empty
        }
        return viewModel.unverifiedFacts.isEmpty ? .success : .partial
    }

    private var statusPill: (label: String, image: String, tone: StatusPill.Tone) {
        switch summary?.status {
        case .verified:
            return ("Verified with authority", "checkmark.seal.fill", .success)
        case .notFound:
            return ("Not found on record", "exclamationmark.triangle.fill", .warning)
        case .unknown(let value):
            let label = value.isEmpty ? "Status unknown" : value
            return (label, "circle.dashed", .neutral)
        case .none:
            return ("Pending verification", "hourglass", .neutral)
        }
    }

    var body: some View {
        OutputStageContainerView(
            title: "Authority verification",
            subtitle: "What is confirmed and what to check yourself",
            systemImage: "checkmark.shield",
            state: state,
            hasContent: hasContent,
            loadingLabel: "Verifying…",
            emptyLabel: "Verification appears once there are facts to confirm.",
            partialNote: "Some requirements still need to be confirmed with the authority.",
            recoverableError: viewModel.recoverableError,
            onRetry: { viewModel.retryCurrentStep() }
        ) {
            VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingComfortable) {
                StatusPill(statusPill.label, systemImage: statusPill.image, tone: statusPill.tone)

                if let info = summary?.info ?? summary?.message, !info.isEmpty {
                    Text(info)
                        .font(IrshadTheme.Typography.secondaryLabel)
                        .foregroundStyle(IrshadTheme.Colors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                OutputFactList(title: "Confirmed facts", facts: viewModel.verifiedFacts)

                OutputFactList(title: "Still to confirm", facts: viewModel.unverifiedFacts)

                if let summary {
                    authoritySection(summary)
                }
            }
        }
    }

    @ViewBuilder
    private func authoritySection(_ summary: VerificationSummary) -> some View {
        let hasAuthorityInfo = (summary.authority?.isEmpty == false)
            || (summary.whatToConfirm?.isEmpty == false)
            || summary.contactURL != nil
            || (summary.phone?.isEmpty == false)

        if hasAuthorityInfo {
            VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
                if let authority = summary.authority, !authority.isEmpty {
                    OutputDetailRow(label: "Official authority", value: authority, systemImage: "building.2")
                }

                if let question = summary.whatToConfirm, !question.isEmpty {
                    VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingTight) {
                        Text("Exact question to ask")
                            .font(IrshadTheme.Typography.statusMicrocopy)
                            .foregroundStyle(IrshadTheme.Colors.secondaryText)

                        Text("“\(question)”")
                            .font(IrshadTheme.Typography.secondaryLabel)
                            .foregroundStyle(IrshadTheme.Colors.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(IrshadTheme.Layout.spacingStandard)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                                    .fill(IrshadTheme.Colors.surfaceTint)
                            )

                        Button {
                            viewModel.copyText(question)
                        } label: {
                            Label(viewModel.copiedItemID == question ? "Copied" : "Copy question", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(DynamicCardSecondaryButtonStyle())
                    }
                }

                HStack(spacing: IrshadTheme.Layout.spacingTight) {
                    if let contactURL = summary.contactURL {
                        Button {
                            viewModel.openURL(contactURL)
                        } label: {
                            Label("Official page", systemImage: "safari")
                        }
                        .buttonStyle(DynamicCardSecondaryButtonStyle())
                    }

                    if let phone = summary.phone, !phone.isEmpty {
                        Button {
                            viewModel.callPhoneNumber(phone)
                        } label: {
                            Label(phone, systemImage: "phone.fill")
                        }
                        .buttonStyle(DynamicCardSecondaryButtonStyle())
                    }
                }

                if !summary.sources.isEmpty {
                    TextListSection(title: "Sources", icon: "link", tint: IrshadTheme.Colors.secondaryText, items: summary.sources)
                }
            }
            .padding(IrshadTheme.Layout.spacingComfortable)
            .background(
                RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                    .fill(IrshadTheme.Colors.surfaceElevated)
            )
        }
    }
}
