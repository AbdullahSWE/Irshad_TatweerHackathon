import SwiftUI

/// Non-blocking state that makes incompleteness explicit: what Irshad already
/// has versus what is still missing or unknown. Does not invent values for
/// gaps — it only names them.
struct PartialDataStateView: View {
    var viewModel: JourneyViewModel

    var title: String = "Some details still needed"
    var message: String = "Irshad can keep going with what you've shared. These items are still open and won't block your plan."

    private var missing: [ProfileField] { viewModel.missingFields }
    private var unknown: [ProfileField] { viewModel.unknownFields }

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingComfortable) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(IrshadTheme.Typography.cardTitle)
                    .foregroundStyle(IrshadTheme.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(message)
                    .font(IrshadTheme.Typography.secondaryLabel)
                    .foregroundStyle(IrshadTheme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if missing.isEmpty && unknown.isEmpty {
                InfoBannerView(
                    message: "Nothing outstanding right now.",
                    systemImage: "checkmark.seal.fill",
                    tone: .success
                )
            } else {
                if !missing.isEmpty {
                    fieldGroup(
                        heading: "Missing",
                        systemImage: "circle.dashed",
                        tint: IrshadTheme.Colors.missingTint,
                        iconColor: .red,
                        fields: missing
                    )
                }

                if !unknown.isEmpty {
                    fieldGroup(
                        heading: "Unknown",
                        systemImage: "questionmark.circle",
                        tint: IrshadTheme.Colors.unknownTint,
                        iconColor: IrshadTheme.Colors.secondaryText,
                        fields: unknown
                    )
                }
            }
        }
        .padding(IrshadTheme.Layout.outerMarginCompact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                        .stroke(IrshadTheme.Colors.separator, lineWidth: 1)
                }
        )
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func fieldGroup(
        heading: String,
        systemImage: String,
        tint: Color,
        iconColor: Color,
        fields: [ProfileField]
    ) -> some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingTight) {
            Text(heading)
                .font(IrshadTheme.Typography.statusMicrocopy)
                .foregroundStyle(IrshadTheme.Colors.secondaryText)

            ForEach(fields) { field in
                HStack(spacing: IrshadTheme.Layout.spacingStandard) {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(iconColor)
                        .frame(width: 22)
                        .accessibilityHidden(true)

                    Text(field.label)
                        .font(IrshadTheme.Typography.secondaryLabel)
                        .foregroundStyle(IrshadTheme.Colors.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(IrshadTheme.Layout.spacingStandard)
                .frame(minHeight: IrshadTheme.Layout.minimumTapTarget)
                .background(
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                        .fill(tint)
                )
                .accessibilityElement(children: .combine)
                .accessibilityValue(Text(heading))
            }
        }
    }
}
