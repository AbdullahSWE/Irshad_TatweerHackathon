import SwiftUI

struct MissingInfoCardView: View {
    let missingFields: [ProfileField]
    let unknownFields: [ProfileField]
    var isUpdating: Bool = false
    var correctionTarget: CorrectionTarget?
    var beginCorrection: (String) -> Void
    var submitCorrection: (String) -> Void
    var cancelCorrection: () -> Void
    var copyText: (String) -> Void

    private var hasItems: Bool {
        !missingFields.isEmpty || !unknownFields.isEmpty
    }

    var body: some View {
        if hasItems {
            VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
                HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingStandard) {
                    Image(systemName: "questionmark.bubble.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(IrshadTheme.Colors.warning)
                        .frame(width: 28, height: 28)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Details to clarify")
                            .font(IrshadTheme.Typography.cardTitle)
                            .foregroundStyle(IrshadTheme.Colors.primaryText)

                        Text("Some details are still open. You can answer them when they are relevant.")
                            .font(IrshadTheme.Typography.secondaryLabel)
                            .foregroundStyle(IrshadTheme.Colors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                fieldGroup(title: "Missing", fields: missingFields)
                fieldGroup(title: "Unknown", fields: unknownFields)
            }
            .padding(.horizontal, IrshadTheme.Layout.cardHorizontalPadding)
            .padding(.vertical, IrshadTheme.Layout.cardVerticalPadding)
            .background(
                RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                    .fill(IrshadTheme.Colors.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                            .stroke(IrshadTheme.Colors.warning.opacity(0.18), lineWidth: 1)
                    }
            )
            .irshadShadow(IrshadTheme.Shadows.cardShadow)
            .transition(IrshadTheme.Animations.cardRevealTransition)
        }
    }

    @ViewBuilder
    private func fieldGroup(title: String, fields: [ProfileField]) -> some View {
        if !fields.isEmpty {
            VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingTight) {
                Text(title)
                    .font(IrshadTheme.Typography.statusMicrocopy)
                    .foregroundStyle(IrshadTheme.Colors.secondaryText)

                ForEach(fields) { field in
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
}
