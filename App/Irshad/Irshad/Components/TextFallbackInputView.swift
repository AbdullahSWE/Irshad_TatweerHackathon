import SwiftUI

struct TextFallbackInputView: View {
    var text: Binding<String>
    var isExpanded: Bool
    var isProcessing: Bool
    var submitTitle: String
    var submit: () -> Void

    private var canSubmit: Bool {
        !isProcessing && !text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
            HStack {
                Label("أو اكتب", systemImage: "keyboard")
                    .font(IrshadTheme.Typography.statusMicrocopy)
                    .foregroundStyle(IrshadTheme.Colors.secondaryText)

                Spacer()
            }

            HStack(alignment: .bottom, spacing: IrshadTheme.Layout.spacingStandard) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                        .fill(IrshadTheme.Colors.surface)
                        .overlay {
                            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                                .stroke(IrshadTheme.Colors.separator, lineWidth: 1)
                        }

                    if text.wrappedValue.isEmpty {
                        Text("اكتب فكرتك أو إجابتك")
                            .font(IrshadTheme.Typography.secondaryLabel)
                            .foregroundStyle(IrshadTheme.Colors.secondaryText)
                            .padding(.horizontal, IrshadTheme.Layout.spacingComfortable)
                            .padding(.vertical, IrshadTheme.Layout.spacingStandard)
                    }

                    TextEditor(text: text)
                        .font(IrshadTheme.Typography.secondaryLabel)
                        .foregroundStyle(IrshadTheme.Colors.primaryText)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, IrshadTheme.Layout.spacingTight)
                        .padding(.vertical, 2)
                        .frame(minHeight: isExpanded ? 96 : 58, maxHeight: isExpanded ? 150 : 72)
                        .disabled(isProcessing)
                }
                .frame(minHeight: isExpanded ? 104 : 64)

                Button(action: submit) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: IrshadTheme.Layout.minimumTapTarget, height: IrshadTheme.Layout.minimumTapTarget)
                }
                .buttonStyle(.plain)
                .foregroundStyle(canSubmit ? Color.white : IrshadTheme.Colors.secondaryText)
                .background {
                    Circle()
                        .fill(canSubmit ? IrshadTheme.Colors.primaryAccent : IrshadTheme.Colors.surfaceTint)
                }
                .disabled(!canSubmit)
                .accessibilityLabel(Text(submitTitle))
            }
        }
        .padding(IrshadTheme.Layout.spacingComfortable)
        .background {
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surface.opacity(0.92))
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.cardRadius, style: .continuous)
                        .stroke(IrshadTheme.Colors.separator, lineWidth: 1)
                }
        }
    }
}

