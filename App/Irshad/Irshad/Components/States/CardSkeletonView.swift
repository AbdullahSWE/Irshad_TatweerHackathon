import SwiftUI

/// Placeholder that mirrors a dynamic card's footprint (header, body lines,
/// action row) closely enough to avoid large layout jumps when the real card
/// arrives. Shimmer respects Reduce Motion.
struct CardSkeletonView: View {
    var lineCount: Int = 3
    var showsActionRow: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shimmer = false

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingComfortable) {
            // Header: title + status pill row
            VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
                bar(width: 0.62, height: 20)
                HStack(spacing: IrshadTheme.Layout.spacingTight) {
                    bar(width: 0.22, height: IrshadTheme.Layout.statusPillHeight, corner: IrshadTheme.Layout.statusPillHeight / 2)
                    bar(width: 0.18, height: IrshadTheme.Layout.statusPillHeight, corner: IrshadTheme.Layout.statusPillHeight / 2)
                }
            }

            // Body lines
            VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingTight) {
                ForEach(0..<max(1, lineCount), id: \.self) { index in
                    bar(width: index == lineCount - 1 ? 0.5 : 0.95, height: 14)
                }
            }

            if showsActionRow {
                bar(width: 1.0, height: IrshadTheme.Layout.minimumTapTarget, corner: IrshadTheme.Layout.controlRadius)
            }
        }
        .padding(.horizontal, IrshadTheme.Layout.cardHorizontalPadding)
        .padding(.vertical, IrshadTheme.Layout.cardVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                        .stroke(IrshadTheme.Colors.separator, lineWidth: 1)
                }
        )
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Loading content"))
        .accessibilityValue(Text("Please wait"))
    }

    @ViewBuilder
    private func bar(width: CGFloat, height: CGFloat, corner: CGFloat = 6) -> some View {
        GeometryReader { proxy in
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(IrshadTheme.Colors.surfaceElevated)
                .overlay {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(IrshadTheme.Colors.surfaceTint)
                        .opacity(reduceMotion ? 0.5 : (shimmer ? 0.85 : 0.25))
                }
                .frame(width: proxy.size.width * width)
        }
        .frame(height: height)
    }
}
