import SwiftUI

/// Active-progress state shown once the backend wait threshold passes.
/// Any `preservedContent` (e.g. the prior card or answer) stays visible
/// above the indicator so the screen never blanks out while work happens.
struct IrshadLoadingStateView<PreservedContent: View>: View {
    var viewModel: JourneyViewModel

    var symbolName: String = "sparkles"
    var title: String = "Working on it"
    var message: String = "Irshad is preparing your next step. Your answers are safe."
    var showsCancel: Bool = false

    @ViewBuilder var preservedContent: () -> PreservedContent

    init(
        viewModel: JourneyViewModel,
        symbolName: String = "sparkles",
        title: String = "Working on it",
        message: String = "Irshad is preparing your next step. Your answers are safe.",
        showsCancel: Bool = false,
        @ViewBuilder preservedContent: @escaping () -> PreservedContent = { EmptyView() }
    ) {
        self.viewModel = viewModel
        self.symbolName = symbolName
        self.title = title
        self.message = message
        self.showsCancel = showsCancel
        self.preservedContent = preservedContent
    }

    var body: some View {
        VStack(spacing: IrshadTheme.Layout.spacingSection) {
            preservedContent()
                .opacity(0.55)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            VStack(spacing: IrshadTheme.Layout.spacingComfortable) {
                ProcessingOrbView(symbolName: symbolName, title: title, isActive: true)

                VStack(spacing: IrshadTheme.Layout.spacingTight) {
                    Text(title)
                        .font(IrshadTheme.Typography.cardTitle)
                        .foregroundStyle(IrshadTheme.Colors.primaryText)

                    Text(message)
                        .font(IrshadTheme.Typography.secondaryLabel)
                        .foregroundStyle(IrshadTheme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if showsCancel {
                    Button {
                        viewModel.cancelCurrentOperation()
                    } label: {
                        Text("Cancel")
                            .frame(minHeight: IrshadTheme.Layout.minimumTapTarget)
                    }
                    .buttonStyle(DynamicCardSecondaryButtonStyle())
                }
            }
        }
        .padding(IrshadTheme.Layout.outerMarginCompact)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text("In progress"))
    }
}
