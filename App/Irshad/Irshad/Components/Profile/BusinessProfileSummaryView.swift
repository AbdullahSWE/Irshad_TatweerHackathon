import SwiftUI

struct BusinessProfileSummaryView: View {
    var viewModel: JourneyViewModel

    private var orderedSections: [ProfileSection] {
        viewModel.profileSections.sorted { lhs, rhs in
            let lhsRank = sectionRank(lhs)
            let rhsRank = sectionRank(rhs)

            if lhsRank == rhsRank {
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }

            return lhsRank < rhsRank
        }
    }

    private var hasProfileSurface: Bool {
        !viewModel.profileSections.isEmpty ||
        !viewModel.missingFields.isEmpty ||
        !viewModel.unknownFields.isEmpty ||
        viewModel.confidence != nil ||
        !viewModel.guidanceDisclaimer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        if hasProfileSurface {
            VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingComfortable) {
                header

                if let banner = viewModel.banner {
                    InfoBannerView(
                        message: banner.message,
                        systemImage: "info.circle.fill",
                        tone: .info,
                        onDismiss: viewModel.dismissBanner
                    )
                    .accessibilityLabel(Text(banner.title))
                }

                ConfidenceMeterView(confidence: viewModel.confidence)

                ForEach(Array(orderedSections.enumerated()), id: \.element.id) { index, section in
                    ProfileSectionCardView(
                        section: section,
                        isInitiallyExpanded: viewModel.isProfileExpanded || index == 0,
                        isUpdating: viewModel.isBackendBusy,
                        correctionTarget: viewModel.correctionTarget,
                        beginCorrection: viewModel.beginCorrection(fieldID:),
                        submitCorrection: viewModel.submitCorrection(_:),
                        cancelCorrection: viewModel.cancelCorrection,
                        copyText: viewModel.copyText(_:)
                    )
                }

                MissingInfoCardView(
                    missingFields: viewModel.missingFields,
                    unknownFields: viewModel.unknownFields,
                    isUpdating: viewModel.isBackendBusy,
                    correctionTarget: viewModel.correctionTarget,
                    beginCorrection: viewModel.beginCorrection(fieldID:),
                    submitCorrection: viewModel.submitCorrection(_:),
                    cancelCorrection: viewModel.cancelCorrection,
                    copyText: viewModel.copyText(_:)
                )

                TrustLegendView(
                    verifiedFacts: viewModel.verifiedFacts,
                    estimatedFacts: viewModel.estimatedFacts,
                    unverifiedFacts: viewModel.unverifiedFacts,
                    guidanceDisclaimer: viewModel.guidanceDisclaimer
                )
            }
            .transition(IrshadTheme.Animations.cardRevealTransition)
            .animation(
                IrshadTheme.Animations.resolved(IrshadTheme.Animations.cardReveal, reduceMotion: viewModel.reduceMotionPreferred),
                value: viewModel.profileSections
            )
            .animation(
                IrshadTheme.Animations.resolved(IrshadTheme.Animations.progressTransition, reduceMotion: viewModel.reduceMotionPreferred),
                value: viewModel.isBackendBusy
            )
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingStandard) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Business profile")
                    .font(IrshadTheme.Typography.cardTitleDynamic)
                    .foregroundStyle(IrshadTheme.Colors.primaryText)

                Text("Details Irshad has captured so far")
                    .font(IrshadTheme.Typography.secondaryLabelDynamic)
                    .foregroundStyle(IrshadTheme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                viewModel.copyText(profileSummaryText)
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: IrshadTheme.Layout.minimumTapTarget, height: IrshadTheme.Layout.minimumTapTarget)
            }
            .buttonStyle(.plain)
            .foregroundStyle(IrshadTheme.Colors.tertiaryText)
            .accessibilityLabel(Text("Copy business profile summary"))
            .accessibilityHint(Text(IrshadTheme.Accessibility.Hint.copySummary))
            .help("Copy business profile summary")
            .disabled(profileSummaryText.isEmpty)
        }
    }

    private var profileSummaryText: String {
        orderedSections
            .map { section in
                let fields = section.fields
                    .map { "\($0.label): \($0.value)" }
                    .joined(separator: "\n")

                return fields.isEmpty ? section.title : "\(section.title)\n\(fields)"
            }
            .joined(separator: "\n\n")
    }

    private func sectionRank(_ section: ProfileSection) -> Int {
        let searchable = "\(section.id) \(section.title)".lowercased()

        if searchable.contains("activity") || searchable.contains("idea") {
            return 0
        }

        if searchable.contains("founder") || searchable.contains("owner") {
            return 1
        }

        if searchable.contains("business") || searchable.contains("location") || searchable.contains("channel") {
            return 2
        }

        if searchable.contains("budget") || searchable.contains("finance") || searchable.contains("cost") {
            return 3
        }

        if searchable.contains("document") || searchable.contains("file") {
            return 4
        }

        return 5
    }
}

#Preview {
    BusinessProfileSummaryView(viewModel: AppEnvironment.live.makeJourneyViewModel())
        .padding()
}
