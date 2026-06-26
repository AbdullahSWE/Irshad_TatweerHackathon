import SwiftUI

/// Lifecycle state for a mature-journey output stage (analysis, license,
/// banking, verification, plan). Drives the consistent surface chrome.
enum OutputStageState: Equatable {
    /// Stage locked or pending: required service state does not exist yet.
    case empty
    /// Stage is generating; previous content (if any) stays visible.
    case loading
    /// Stage produced complete output.
    case success
    /// Output exists but carries missing or unverified items; labels stay visible.
    case partial
    /// Output generation failed; session context remains with retry.
    case error
}

/// Shared surface for every output stage. Renders the header, a stage status
/// pill, locked/loading placeholders, and an inline retry banner. Cards supply
/// only their own content; the container never decides verification or license
/// logic.
struct OutputStageContainerView<Content: View>: View {
    let title: String
    var subtitle: String?
    var systemImage: String
    var state: OutputStageState
    /// Whether prior content exists, so loading preserves it instead of showing
    /// a first-load skeleton.
    var hasContent: Bool
    var loadingLabel: String
    var emptyLabel: String
    var partialNote: String?
    var recoverableError: RecoverableError?
    var onRetry: (() -> Void)?
    @ViewBuilder var content: () -> Content

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String = "doc.text.magnifyingglass",
        state: OutputStageState,
        hasContent: Bool = true,
        loadingLabel: String = "Working…",
        emptyLabel: String = "This step unlocks once the earlier details are ready.",
        partialNote: String? = nil,
        recoverableError: RecoverableError? = nil,
        onRetry: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.state = state
        self.hasContent = hasContent
        self.loadingLabel = loadingLabel
        self.emptyLabel = emptyLabel
        self.partialNote = partialNote
        self.recoverableError = recoverableError
        self.onRetry = onRetry
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingComfortable) {
            header

            switch state {
            case .empty:
                lockedPlaceholder
            case .loading:
                if hasContent {
                    updatingIndicator
                    content()
                } else {
                    OutputStageSkeletonView()
                }
            case .success:
                content()
            case .partial:
                content()
                if let partialNote, !partialNote.isEmpty {
                    InfoBannerView(
                        message: partialNote,
                        systemImage: "exclamationmark.triangle.fill",
                        tone: .warning
                    )
                }
            case .error:
                content()
                errorBanner
            }
        }
        .padding(.horizontal, IrshadTheme.Layout.cardHorizontalPadding)
        .padding(.vertical, IrshadTheme.Layout.cardVerticalPadding)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                        .stroke(IrshadTheme.Colors.separator, lineWidth: 1)
                }
        )
        .irshadShadow(IrshadTheme.Shadows.cardShadow)
        .transition(IrshadTheme.Animations.cardRevealTransition)
        .animation(IrshadTheme.Animations.cardReveal, value: state)
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingStandard) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(IrshadTheme.Colors.primaryAccent)
                .frame(width: 30, height: 30)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(IrshadTheme.Typography.cardTitle)
                    .foregroundStyle(IrshadTheme.Colors.primaryText)

                if let subtitle {
                    Text(subtitle)
                        .font(IrshadTheme.Typography.secondaryLabel)
                        .foregroundStyle(IrshadTheme.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            stageStatusPill
        }
    }

    @ViewBuilder
    private var stageStatusPill: some View {
        switch state {
        case .empty:
            StatusPill("Locked", systemImage: "lock.fill", tone: .neutral)
        case .loading:
            StatusPill(loadingLabel, tone: .active, showsSpinner: true)
        case .success:
            StatusPill("Ready", systemImage: "checkmark.circle.fill", tone: .success)
        case .partial:
            StatusPill("Review", systemImage: "exclamationmark.triangle.fill", tone: .warning)
        case .error:
            StatusPill("Retry needed", systemImage: "arrow.triangle.2.circlepath", tone: .error)
        }
    }

    private var lockedPlaceholder: some View {
        HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingStandard) {
            Image(systemName: "lock.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(IrshadTheme.Colors.tertiaryText)
                .accessibilityHidden(true)

            Text(emptyLabel)
                .font(IrshadTheme.Typography.secondaryLabel)
                .foregroundStyle(IrshadTheme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(IrshadTheme.Layout.spacingStandard)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surfaceElevated)
        )
    }

    private var updatingIndicator: some View {
        StatusPill(loadingLabel, systemImage: "arrow.triangle.2.circlepath", tone: .active, showsSpinner: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let recoverableError {
            InfoBannerView(
                message: recoverableError.message,
                systemImage: "exclamationmark.triangle.fill",
                tone: .error,
                actionTitle: onRetry == nil ? nil : "Retry",
                onAction: onRetry
            )
            .accessibilityLabel(Text(recoverableError.title))
        } else {
            InfoBannerView(
                message: "This step could not be generated. Your earlier answers are safe.",
                systemImage: "exclamationmark.triangle.fill",
                tone: .error,
                actionTitle: onRetry == nil ? nil : "Retry",
                onAction: onRetry
            )
        }
    }
}

/// First-load skeleton placeholder for a stage that has no prior content.
struct OutputStageSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(IrshadTheme.Colors.surfaceElevated)
                .frame(height: 22)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(IrshadTheme.Colors.surfaceElevated)
                .frame(height: 54)
        }
        .redacted(reason: .placeholder)
        .accessibilityLabel(Text("Generating this step"))
    }
}

/// Inline confidence summary without its own card surface, for embedding inside
/// an `OutputStageContainerView`.
struct OutputConfidenceView: View {
    let confidence: Double?
    var caption: String = "AI confidence"

    private var normalized: Double {
        guard let confidence else { return 0 }
        return min(max(confidence, 0), 1)
    }

    private var label: String {
        guard confidence != nil else { return "Confidence pending" }
        switch normalized {
        case 0.8...: return "High confidence"
        case 0.5..<0.8: return "Moderate confidence"
        default: return "Low confidence"
        }
    }

    private var tint: Color {
        guard confidence != nil else { return IrshadTheme.Colors.secondaryText }
        switch normalized {
        case 0.8...: return IrshadTheme.Colors.success
        case 0.5..<0.8: return IrshadTheme.Colors.primaryAccent
        default: return IrshadTheme.Colors.warning
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingTight) {
            HStack(spacing: IrshadTheme.Layout.spacingTight) {
                Image(systemName: "gauge.with.dots.needle.67percent")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)

                Text(label)
                    .font(IrshadTheme.Typography.statusMicrocopy)
                    .foregroundStyle(IrshadTheme.Colors.primaryText)

                Spacer(minLength: 0)

                if confidence != nil {
                    Text("\(Int((normalized * 100).rounded()))%")
                        .font(IrshadTheme.Typography.statusMicrocopy)
                        .foregroundStyle(tint)
                }
            }

            if confidence != nil {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(IrshadTheme.Colors.progressTrack)
                        Capsule(style: .continuous)
                            .fill(tint)
                            .frame(width: proxy.size.width * normalized)
                    }
                }
                .frame(height: 6)
                .accessibilityHidden(true)
            }
        }
        .padding(IrshadTheme.Layout.spacingStandard)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surfaceTint)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(caption))
        .accessibilityValue(Text(label))
        .animation(IrshadTheme.Animations.progressTransition, value: normalized)
    }
}

/// Compact list of trust facts with their status badge. Labels always stay
/// visible — they are never hidden in collapsed states.
struct OutputFactList: View {
    let title: String
    let facts: [TrustFact]

    var body: some View {
        if !facts.isEmpty {
            VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingTight) {
                Text(title)
                    .font(IrshadTheme.Typography.statusMicrocopy)
                    .foregroundStyle(IrshadTheme.Colors.secondaryText)

                ForEach(facts) { fact in
                    HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingTight) {
                        TrustBadge(status: fact.status)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(fact.label)
                                .font(IrshadTheme.Typography.secondaryLabel)
                                .foregroundStyle(IrshadTheme.Colors.primaryText)
                            Text(fact.value)
                                .font(IrshadTheme.Typography.statusMicrocopy)
                                .foregroundStyle(IrshadTheme.Colors.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(IrshadTheme.Layout.spacingTight)
                    .background(
                        RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                            .fill(IrshadTheme.Colors.surfaceTint)
                    )
                }
            }
        }
    }
}

/// Single label/value detail row used across the roadmap and verification cards.
struct OutputDetailRow: View {
    let label: String
    let value: String
    var systemImage: String?
    var accessory: AnyView?

    init(label: String, value: String, systemImage: String? = nil, accessory: AnyView? = nil) {
        self.label = label
        self.value = value
        self.systemImage = systemImage
        self.accessory = accessory
    }

    var body: some View {
        HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingStandard) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(IrshadTheme.Colors.primaryAccent)
                    .frame(width: 22)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(IrshadTheme.Typography.statusMicrocopy)
                    .foregroundStyle(IrshadTheme.Colors.secondaryText)
                Text(value)
                    .font(IrshadTheme.Typography.secondaryLabel)
                    .foregroundStyle(IrshadTheme.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let accessory {
                accessory
            }
        }
        .accessibilityElement(children: .combine)
    }
}
