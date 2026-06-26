import SwiftUI

struct ConfidenceMeterView: View {
    let confidence: Double?

    private var normalizedConfidence: Double {
        guard let confidence else {
            return 0
        }

        return min(max(confidence, 0), 1)
    }

    private var label: String {
        guard confidence != nil else {
            return "Confidence pending"
        }

        switch normalizedConfidence {
        case 0.8...:
            return "High confidence"
        case 0.5..<0.8:
            return "Moderate confidence"
        default:
            return "Low confidence"
        }
    }

    private var detail: String {
        guard confidence != nil else {
            return "Irshad will show confidence once enough details are available."
        }

        return "\(Int((normalizedConfidence * 100).rounded()))% based on captured details"
    }

    private var tint: Color {
        guard confidence != nil else {
            return IrshadTheme.Colors.secondaryText
        }

        switch normalizedConfidence {
        case 0.8...:
            return IrshadTheme.Colors.success
        case 0.5..<0.8:
            return IrshadTheme.Colors.primaryAccent
        default:
            return IrshadTheme.Colors.warning
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
            HStack(alignment: .center, spacing: IrshadTheme.Layout.spacingStandard) {
                Image(systemName: "gauge.with.dots.needle.67percent")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 28, height: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(IrshadTheme.Typography.cardTitle)
                        .foregroundStyle(IrshadTheme.Colors.primaryText)

                    Text(detail)
                        .font(IrshadTheme.Typography.secondaryLabel)
                        .foregroundStyle(IrshadTheme.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(IrshadTheme.Colors.progressTrack)

                    Capsule(style: .continuous)
                        .fill(tint)
                        .frame(width: proxy.size.width * normalizedConfidence)
                }
            }
            .frame(height: 8)
            .accessibilityHidden(true)
        }
        .padding(.horizontal, IrshadTheme.Layout.cardHorizontalPadding)
        .padding(.vertical, IrshadTheme.Layout.cardVerticalPadding)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                        .stroke(tint.opacity(0.16), lineWidth: 1)
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Backend confidence"))
        .accessibilityValue(Text("\(label), \(detail)"))
        .animation(IrshadTheme.Animations.progressTransition, value: normalizedConfidence)
    }
}
