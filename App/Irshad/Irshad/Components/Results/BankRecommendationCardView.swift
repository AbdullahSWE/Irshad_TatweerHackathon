import SwiftUI

/// Single bank recommendation: suitability, minimum balance (when known),
/// required documents, next action, and source/status when supplied. Details
/// expand on demand. Never invents minimums, documents, or sources.
struct BankRecommendationCardView: View {
    let bank: BankRecommendation
    var isPreferred: Bool
    var viewModel: JourneyViewModel

    private var isExpanded: Bool {
        viewModel.expandedRecommendationIDs.contains(bank.id)
    }

    private var suitability: (label: String, image: String, tone: StatusPill.Tone) {
        switch bank.likelyToApprove {
        case .some(true):
            return ("Likely to approve", "checkmark.circle.fill", .success)
        case .some(false):
            return ("May not approve", "exclamationmark.circle.fill", .warning)
        case .none:
            return ("Suitability unknown", "questionmark.circle.fill", .neutral)
        }
    }

    private var nextAction: String? {
        bank.metadata.string(for: ["next_action", "nextAction"])
    }

    private var websiteURL: URL? {
        guard let raw = bank.metadata.string(for: ["url", "website", "apply_url", "applyURL", "open_url", "openURL"]) else {
            return nil
        }
        return URL(string: raw)
    }

    private var phone: String? {
        bank.metadata.string(for: ["phone", "business_phone", "corporate_phone"])
    }

    private var email: String? {
        bank.metadata.string(for: ["email", "corporate_email"])
    }

    private var emailURL: URL? {
        bank.metadata.string(for: ["email_url", "emailURL"]).flatMap(URL.init(string:))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
            HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingStandard) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bank.name)
                        .font(IrshadTheme.Typography.cardTitle)
                        .foregroundStyle(IrshadTheme.Colors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    StatusPill(suitability.label, systemImage: suitability.image, tone: suitability.tone)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isPreferred {
                    StatusPill("Preferred", systemImage: "bookmark.fill", tone: .secondary)
                }
            }

            if let minBalance = bank.minBalance, !minBalance.isEmpty {
                OutputDetailRow(label: "Minimum balance", value: minBalance, systemImage: "banknote")
            }

            if let nextAction {
                InfoBannerView(message: nextAction, systemImage: "arrow.forward.circle.fill", tone: .info)
            }

            Button {
                if isExpanded {
                    viewModel.expandedRecommendationIDs.remove(bank.id)
                } else {
                    viewModel.expandRecommendation(bank.id)
                }
            } label: {
                Label(isExpanded ? "Hide requirements" : "Requirements & documents", systemImage: isExpanded ? "chevron.up" : "chevron.down")
            }
            .buttonStyle(DynamicCardSecondaryButtonStyle())

            if isExpanded {
                VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
                    if !bank.requirements.isEmpty {
                        TextListSection(title: "Requirements", icon: "list.bullet", tint: IrshadTheme.Colors.primaryAccent, items: bank.requirements)
                    }
                    if !bank.docsNeeded.isEmpty {
                        TextListSection(title: "Documents needed", icon: "doc.text.fill", tint: IrshadTheme.Colors.primaryAccent, items: bank.docsNeeded)
                    }
                    if let source = bank.source, !source.isEmpty {
                        OutputDetailRow(label: "Source", value: source, systemImage: "link")
                    }
                }
                .padding(IrshadTheme.Layout.spacingStandard)
                .background(
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                        .fill(IrshadTheme.Colors.surfaceTint)
                )
            }

            HStack(spacing: IrshadTheme.Layout.spacingTight) {
                Button {
                    viewModel.savePreferredBank(bank.id)
                } label: {
                    Label(isPreferred ? "Saved" : "Save", systemImage: isPreferred ? "bookmark.fill" : "bookmark")
                }
                .buttonStyle(DynamicCardSecondaryButtonStyle())

                if let websiteURL {
                    Button {
                        viewModel.openURL(websiteURL)
                    } label: {
                        Label("Website", systemImage: "safari")
                    }
                    .buttonStyle(DynamicCardSecondaryButtonStyle())
                }

                if let phone {
                    Button {
                        viewModel.callPhoneNumber(phone)
                    } label: {
                        Label(phone, systemImage: "phone.fill")
                    }
                    .buttonStyle(DynamicCardSecondaryButtonStyle())
                }

                if let emailURL {
                    Button {
                        viewModel.openURL(emailURL)
                    } label: {
                        Label(email ?? "Email", systemImage: "envelope.fill")
                    }
                    .buttonStyle(DynamicCardSecondaryButtonStyle())
                }
            }
        }
        .padding(IrshadTheme.Layout.spacingComfortable)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surfaceElevated)
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                        .stroke(isPreferred ? IrshadTheme.Colors.primaryAccent.opacity(0.3) : IrshadTheme.Colors.separator, lineWidth: 1)
                }
        )
        .accessibilityElement(children: .contain)
    }
}
