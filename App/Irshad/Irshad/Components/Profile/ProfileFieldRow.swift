import SwiftUI

struct ProfileFieldRow: View {
    let field: ProfileField
    var isUpdating: Bool = false
    var isCorrecting: Bool = false
    var beginCorrection: (String) -> Void
    var submitCorrection: (String) -> Void
    var cancelCorrection: () -> Void
    var copyText: (String) -> Void

    @State private var correctionValue = ""

    private var displayValue: String {
        let trimmed = field.value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            switch field.trustStatus {
            case .missing:
                return "Missing"
            case .unknown:
                return "Unknown"
            default:
                return "Not provided"
            }
        }

        return field.value
    }

    private var canCorrect: Bool {
        field.correctionID != nil
    }

    private var correctionFieldID: String {
        field.correctionID ?? field.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
            HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingStandard) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(field.label)
                        .font(IrshadTheme.Typography.secondaryLabel)
                        .foregroundStyle(IrshadTheme.Colors.secondaryText)

                    Text(displayValue)
                        .font(IrshadTheme.Typography.primaryBody)
                        .foregroundStyle(valueForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: IrshadTheme.Layout.spacingTight) {
                    TrustBadge(status: field.trustStatus)

                    HStack(spacing: IrshadTheme.Layout.spacingTight) {
                        if isUpdating {
                            ProgressView()
                                .controlSize(.mini)
                                .tint(IrshadTheme.Colors.primaryAccent)
                                .accessibilityLabel(Text("Updating field"))
                        }

                        Button {
                            copyText(field.value)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 13, weight: .semibold))
                                .frame(width: IrshadTheme.Layout.minimumTapTarget, height: IrshadTheme.Layout.minimumTapTarget)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(IrshadTheme.Colors.tertiaryText)
                        .accessibilityLabel(Text("Copy \(field.label)"))
                        .disabled(field.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        if canCorrect {
                            Button {
                                correctionValue = field.value
                                beginCorrection(correctionFieldID)
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 13, weight: .semibold))
                                    .frame(width: IrshadTheme.Layout.minimumTapTarget, height: IrshadTheme.Layout.minimumTapTarget)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(IrshadTheme.Colors.primaryAccent)
                            .accessibilityLabel(Text("Correct \(field.label)"))
                        }
                    }
                }
            }

            if isCorrecting {
                correctionEditor
            }
        }
        .padding(IrshadTheme.Layout.spacingStandard)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                .fill(rowBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                        .stroke(rowStroke, lineWidth: 1)
                }
        )
        .accessibilityElement(children: .contain)
        .onChange(of: isCorrecting) { _, newValue in
            if newValue {
                correctionValue = field.value
            }
        }
    }

    private var correctionEditor: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingTight) {
            TextField("Enter corrected value", text: $correctionValue, axis: .vertical)
                .font(IrshadTheme.Typography.primaryBody)
                .textFieldStyle(.plain)
                .lineLimit(2...4)
                .padding(IrshadTheme.Layout.spacingStandard)
                .background(
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                        .fill(IrshadTheme.Colors.surface)
                        .overlay {
                            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                                .stroke(IrshadTheme.Colors.primaryAccent.opacity(0.24), lineWidth: 1)
                        }
                )

            HStack(spacing: IrshadTheme.Layout.spacingTight) {
                Button("Cancel", action: cancelCorrection)
                    .buttonStyle(DynamicCardSecondaryButtonStyle())

                Button {
                    submitCorrection(correctionValue)
                } label: {
                    Text("Save")
                        .font(IrshadTheme.Typography.statusMicrocopy)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: IrshadTheme.Layout.minimumTapTarget)
                }
                .buttonStyle(DynamicCardPrimaryButtonStyle())
                .disabled(correctionValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var valueForeground: Color {
        switch field.trustStatus {
        case .missing:
            .red
        case .unknown:
            IrshadTheme.Colors.secondaryText
        default:
            IrshadTheme.Colors.primaryText
        }
    }

    private var rowBackground: Color {
        switch field.trustStatus {
        case .verified:
            IrshadTheme.Colors.verifiedTint
        case .estimated:
            IrshadTheme.Colors.estimatedTint
        case .unverified:
            IrshadTheme.Colors.unverifiedTint
        case .missing:
            IrshadTheme.Colors.missingTint
        case .unknown:
            IrshadTheme.Colors.unknownTint
        case .guidanceOnly:
            IrshadTheme.Colors.surfaceTint
        }
    }

    private var rowStroke: Color {
        switch field.trustStatus {
        case .verified:
            IrshadTheme.Colors.success.opacity(0.18)
        case .estimated:
            IrshadTheme.Colors.primaryAccent.opacity(0.18)
        case .unverified:
            IrshadTheme.Colors.warning.opacity(0.22)
        case .missing:
            Color.red.opacity(0.16)
        case .unknown:
            IrshadTheme.Colors.secondaryText.opacity(0.14)
        case .guidanceOnly:
            IrshadTheme.Colors.primaryAccent.opacity(0.14)
        }
    }
}
