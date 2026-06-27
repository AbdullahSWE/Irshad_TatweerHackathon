import SwiftUI

struct DebugTracePanelView: View {
    let trace: String
    var onCopy: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingTight) {
            HStack(spacing: IrshadTheme.Layout.spacingTight) {
                Label("Debug trace", systemImage: "terminal.fill")
                    .font(IrshadTheme.Typography.statusMicrocopy.weight(.semibold))
                    .foregroundStyle(IrshadTheme.Colors.primaryText)

                Spacer()

                if let onCopy {
                    Button("Copy", action: onCopy)
                        .font(IrshadTheme.Typography.statusMicrocopy)
                        .buttonStyle(.plain)
                        .foregroundStyle(IrshadTheme.Colors.primaryAccent)
                }
            }

            Text(trace)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(IrshadTheme.Colors.secondaryText)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(IrshadTheme.Layout.spacingStandard)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surfaceElevated)
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                        .stroke(IrshadTheme.Colors.separator, lineWidth: 1)
                }
        )
    }
}
