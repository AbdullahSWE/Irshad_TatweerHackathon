import SwiftUI

struct ProfileSectionCardView: View {
    let section: ProfileSection
    var isInitiallyExpanded: Bool = true
    var isUpdating: Bool = false
    var correctionTarget: CorrectionTarget?
    var beginCorrection: (String) -> Void
    var submitCorrection: (String) -> Void
    var cancelCorrection: () -> Void
    var copyText: (String) -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isExpanded: Bool

    init(
        section: ProfileSection,
        isInitiallyExpanded: Bool = true,
        isUpdating: Bool = false,
        correctionTarget: CorrectionTarget? = nil,
        beginCorrection: @escaping (String) -> Void,
        submitCorrection: @escaping (String) -> Void,
        cancelCorrection: @escaping () -> Void,
        copyText: @escaping (String) -> Void
    ) {
        self.section = section
        self.isInitiallyExpanded = isInitiallyExpanded
        self.isUpdating = isUpdating
        self.correctionTarget = correctionTarget
        self.beginCorrection = beginCorrection
        self.submitCorrection = submitCorrection
        self.cancelCorrection = cancelCorrection
        self.copyText = copyText
        _isExpanded = State(initialValue: isInitiallyExpanded)
    }

    private var fieldCount: Int {
        section.fields.count
    }

    private var completedCount: Int {
        section.fields.filter { field in
            switch field.trustStatus {
            case .verified, .estimated, .unverified, .guidanceOnly:
                return true
            case .missing, .unknown:
                return false
            }
        }.count
    }

    private var completionFraction: Double {
        guard fieldCount > 0 else {
            return 0
        }

        return Double(completedCount) / Double(fieldCount)
    }

    private var shouldShowRows: Bool {
        isExpanded || horizontalSizeClass != .compact
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
            header

            ProgressView(value: completionFraction)
                .tint(progressTint)
                .accessibilityLabel(Text("Profile section completion"))
                .accessibilityValue(Text("\(completedCount) of \(fieldCount) fields filled"))

            if shouldShowRows {
                rows
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
        .animation(IrshadTheme.Animations.progressTransition, value: completionFraction)
        .animation(IrshadTheme.Animations.buttonFeedback, value: isExpanded)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: IrshadTheme.Layout.spacingStandard) {
            VStack(alignment: .leading, spacing: 6) {
                Text(section.title)
                    .font(IrshadTheme.Typography.cardTitle)
                    .foregroundStyle(IrshadTheme.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: IrshadTheme.Layout.spacingTight) {
                    StatusPill("\(completedCount)/\(fieldCount)", systemImage: "checklist", tone: completionTone)

                    if isUpdating {
                        StatusPill("Updating", systemImage: "arrow.triangle.2.circlepath", tone: .active, showsSpinner: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                isExpanded.toggle()
            } label: {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: IrshadTheme.Layout.minimumTapTarget, height: IrshadTheme.Layout.minimumTapTarget)
            }
            .buttonStyle(.plain)
            .foregroundStyle(IrshadTheme.Colors.secondaryText)
            .accessibilityLabel(Text(isExpanded ? "Collapse section" : "Expand section"))
        }
    }

    private var rows: some View {
        VStack(spacing: IrshadTheme.Layout.spacingTight) {
            if section.fields.isEmpty {
                Text("No profile details captured here yet.")
                    .font(IrshadTheme.Typography.secondaryLabel)
                    .foregroundStyle(IrshadTheme.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, IrshadTheme.Layout.spacingTight)
            } else {
                ForEach(section.fields) { field in
                    ProfileFieldRow(
                        field: field,
                        isUpdating: isUpdating,
                        isCorrecting: correctionTarget?.fieldID == field.correctionID || correctionTarget?.fieldID == field.id,
                        beginCorrection: beginCorrection,
                        submitCorrection: submitCorrection,
                        cancelCorrection: cancelCorrection,
                        copyText: copyText
                    )
                }
            }
        }
    }

    private var completionTone: StatusPill.Tone {
        if fieldCount == 0 || completedCount == 0 {
            return .neutral
        }

        return completedCount == fieldCount ? .success : .active
    }

    private var progressTint: Color {
        switch completionTone {
        case .success:
            IrshadTheme.Colors.success
        case .active:
            IrshadTheme.Colors.primaryAccent
        case .warning:
            IrshadTheme.Colors.warning
        case .error:
            .red
        case .neutral, .secondary:
            IrshadTheme.Colors.secondaryText
        }
    }
}
