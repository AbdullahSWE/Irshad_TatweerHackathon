import SwiftUI

struct QuestionCardContainer<Content: View>: View {
    let card: DynamicCard
    var screenTitle: String?
    var validationMessage: String?
    var isServiceBusy: Bool
    var showsConfirm: Bool
    var canSubmit: Bool
    var confirmTitle: String?
    var onCopy: (() -> Void)?
    var onConfirm: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        DynamicCardSurface(card: card, screenTitle: screenTitle, onCopy: onCopy) {
            content

            if let validationMessage = normalized(validationMessage) {
                InfoBannerView(
                    message: validationMessage,
                    systemImage: "exclamationmark.circle.fill",
                    tone: .warning
                )
            }

            if showsConfirm {
                Button(action: onConfirm) {
                    HStack(spacing: IrshadTheme.Layout.spacingTight) {
                        if isServiceBusy {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                                .accessibilityHidden(true)
                        }

                        Text(confirmTitle ?? card.confirmLabel)
                            .font(IrshadTheme.Typography.statusMicrocopy)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: IrshadTheme.Layout.minimumTapTarget)
                }
                .buttonStyle(DynamicCardPrimaryButtonStyle())
                .disabled(!canSubmit || isServiceBusy)
                .accessibilityHint(Text("Submits this answer."))
            }
        }
    }

    private func normalized(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct DynamicCardSurface<Content: View>: View {
    let card: DynamicCard
    var screenTitle: String? = nil
    var onCopy: (() -> Void)? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingComfortable) {
            DynamicCardHeader(card: card, screenTitle: screenTitle, onCopy: onCopy)

            content
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
        .animation(IrshadTheme.Animations.cardReveal, value: card.cardId)
    }
}

private struct DynamicCardHeader: View {
    let card: DynamicCard
    var screenTitle: String?
    var onCopy: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
            HStack(alignment: .top, spacing: IrshadTheme.Layout.spacingTight) {
                VStack(alignment: .leading, spacing: 6) {
                    if let eyebrow = card.eyebrowLabel, !usesQuestionScreenTitle {
                        Text(eyebrow)
                            .font(IrshadTheme.Typography.statusMicrocopy)
                            .foregroundStyle(IrshadTheme.Colors.primaryAccent)
                    }

                    Text(headerTitle)
                        .font(IrshadTheme.Typography.cardTitle)
                        .foregroundStyle(IrshadTheme.Colors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if card.showsCopyControl, let onCopy {
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: IrshadTheme.Layout.minimumTapTarget, height: IrshadTheme.Layout.minimumTapTarget)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(IrshadTheme.Colors.tertiaryText)
                    .accessibilityLabel(Text("Copy card text"))
                }
            }

            if let subtitle = headerSubtitle {
                Text(subtitle)
                    .font(IrshadTheme.Typography.secondaryLabel)
                    .foregroundStyle(IrshadTheme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: IrshadTheme.Layout.spacingTight) {
                StatusPill(card.phaseLabel, systemImage: "flag.fill", tone: .active)

                if let slotLabel = card.slotLabel {
                    StatusPill(slotLabel, systemImage: "tag.fill", tone: .secondary)
                }

                if let statusLabel = card.statusLabel {
                    StatusPill(statusLabel, systemImage: card.statusSystemImage, tone: card.statusTone)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var usesQuestionScreenTitle: Bool {
        card.kind == .question && normalized(screenTitle) != nil
    }

    private var headerTitle: String {
        if usesQuestionScreenTitle, let screenTitle = normalized(screenTitle) {
            return screenTitle
        }

        return card.displayTitle
    }

    private var headerSubtitle: String? {
        if usesQuestionScreenTitle {
            return [card.displayTitle, card.displaySubtitle]
                .compactMap { normalized($0) }
                .joined(separator: "\n")
        }

        return card.displaySubtitle
    }

    private func normalized(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct DynamicCardPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.horizontal, IrshadTheme.Layout.spacingComfortable)
            .background(
                RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                    .fill(configuration.isPressed ? IrshadTheme.Colors.supportingAccent : IrshadTheme.Colors.primaryAccent)
            )
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(IrshadTheme.Animations.buttonFeedback, value: configuration.isPressed)
    }
}

struct DynamicCardSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(IrshadTheme.Typography.statusMicrocopy)
            .foregroundStyle(IrshadTheme.Colors.primaryAccent)
            .padding(.horizontal, IrshadTheme.Layout.spacingStandard)
            .frame(minHeight: IrshadTheme.Layout.minimumTapTarget)
            .background(
                RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                    .fill(configuration.isPressed ? IrshadTheme.Colors.surfaceTint.opacity(0.7) : IrshadTheme.Colors.surfaceTint)
                    .overlay {
                        RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                            .stroke(IrshadTheme.Colors.primaryAccent.opacity(0.18), lineWidth: 1)
                    }
            )
            .animation(IrshadTheme.Animations.buttonFeedback, value: configuration.isPressed)
    }
}

struct DynamicCardOptionRow: View {
    let title: String
    var subtitle: String?
    var leadingSystemImage: String?
    var trailingText: String?
    var isSelected: Bool
    var isEnabled: Bool = true

    var body: some View {
        HStack(alignment: .center, spacing: IrshadTheme.Layout.spacingStandard) {
            Image(systemName: leadingSystemImage ?? (isSelected ? "checkmark.circle.fill" : "circle"))
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(isSelected ? IrshadTheme.Colors.primaryAccent : IrshadTheme.Colors.tertiaryText)
                .frame(width: 26)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(IrshadTheme.Typography.primaryBody)
                    .foregroundStyle(IrshadTheme.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle {
                    Text(subtitle)
                        .font(IrshadTheme.Typography.secondaryLabel)
                        .foregroundStyle(IrshadTheme.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let trailingText {
                Text(trailingText)
                    .font(IrshadTheme.Typography.statusMicrocopy)
                    .foregroundStyle(IrshadTheme.Colors.secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(IrshadTheme.Layout.spacingStandard)
        .frame(maxWidth: .infinity, minHeight: IrshadTheme.Layout.minimumTapTarget, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                .fill(isSelected ? IrshadTheme.Colors.surfaceTint : IrshadTheme.Colors.surfaceElevated)
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                        .stroke(isSelected ? IrshadTheme.Colors.primaryAccent.opacity(0.38) : IrshadTheme.Colors.separator, lineWidth: 1)
                }
        )
        .opacity(isEnabled ? 1 : 0.62)
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(isSelected ? "Selected" : "Not selected"))
    }
}

struct MetadataDisplayItem: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String?
    let value: String?
    let status: String?
    let systemImage: String?

    init(id: String, title: String, subtitle: String? = nil, value: String? = nil, status: String? = nil, systemImage: String? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.status = status
        self.systemImage = systemImage
    }
}

extension DynamicCard {
    var displayTitle: String {
        normalized(title) ?? metadata.string(for: ["title", "label", "prompt"]) ?? "Card"
    }

    var displaySubtitle: String? {
        normalized(subtitle) ?? metadata.string(for: ["subtitle", "description", "helper_text", "helperText"])
    }

    var eyebrowLabel: String? {
        metadata.string(for: ["eyebrow", "section", "category"])
    }

    var phaseLabel: String {
        metadata.string(for: ["phase_label", "phaseLabel"]) ?? phase.displayTitle
    }

    var slotLabel: String? {
        metadata.string(for: ["slot_label", "slotLabel"]) ?? normalized(slot)
    }

    var statusLabel: String? {
        metadata.string(for: ["status_label", "statusLabel", "status"])
    }

    var statusSystemImage: String {
        metadata.string(for: ["status_icon", "statusIcon"]) ?? "info.circle.fill"
    }

    var statusTone: StatusPill.Tone {
        switch (metadata.string(for: ["status_tone", "statusTone", "tone"]) ?? "").lowercased() {
        case "success", "verified", "complete", "completed":
            return .success
        case "warning", "unverified", "pending":
            return .warning
        case "error", "missing":
            return .error
        case "secondary", "guidance":
            return .secondary
        case "active", "estimated":
            return .active
        default:
            return .neutral
        }
    }

    var confirmLabel: String {
        metadata.string(for: ["confirm_label", "confirmLabel", "submit_label", "submitLabel", "action_label", "actionLabel"]) ?? "Continue"
    }

    var requiresExplicitConfirmation: Bool {
        metadata.bool(for: ["requires_confirmation", "requiresConfirmation", "show_confirm", "showConfirm"]) ?? false
    }

    var autoSubmits: Bool {
        metadata.bool(for: ["auto_submit", "autoSubmit"]) ?? false
    }

    var isChoiceQuestion: Bool {
        kind == .question && (type == .singleSelect || type == .multiSelect)
    }

    var allowsCustomInput: Bool {
        if type == .text {
            return true
        }

        return metadata.bool(
            for: [
                "allows_custom_input",
                "allowsCustomInput",
                "allow_custom_input",
                "allowCustomInput",
                "custom_input",
                "customInput"
            ]
        ) ?? false
    }

    var requiresAction: Bool {
        metadata.bool(for: ["requires_action", "requiresAction", "needs_action", "needsAction"]) ?? false
    }

    var bodyText: String? {
        metadata.string(for: ["body", "text", "summary", "message", "details"])
    }

    var showsCopyControl: Bool {
        metadata.bool(for: ["copyable", "can_copy", "canCopy"]) ?? false
    }
}

extension DynamicCardOption {
    var displaySubtitle: String? {
        metadata.string(for: ["subtitle", "description", "detail", "helper_text", "helperText"])
    }

    var trailingLabel: String? {
        metadata.string(for: ["trailing_label", "trailingLabel", "value_label", "valueLabel", "badge"])
    }

    var systemImage: String? {
        metadata.string(for: ["icon", "system_image", "systemImage"])
    }

    var status: String? {
        metadata.string(for: ["status", "state"])
    }

    var isLocallyMarkable: Bool {
        metadata.bool(for: ["locally_markable", "locallyMarkable", "markable", "interactive"]) ?? false
    }
}

extension JourneyPhase {
    var displayTitle: String {
        switch self {
        case .nextSteps:
            return "Next steps"
        case .unknown:
            return "Journey"
        default:
            return rawValue.prefix(1).uppercased() + rawValue.dropFirst()
        }
    }
}

extension Dictionary where Key == String, Value == JSONValue {
    func string(for keys: [String]) -> String? {
        for key in keys {
            guard let value = self[key] else {
                continue
            }

            let string = value.displayString.trimmingCharacters(in: .whitespacesAndNewlines)
            if !string.isEmpty {
                return string
            }
        }

        return nil
    }

    func bool(for keys: [String]) -> Bool? {
        for key in keys {
            guard let value = self[key] else {
                continue
            }

            switch value {
            case .bool(let bool):
                return bool
            case .string(let string):
                switch string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
                case "true", "yes", "1":
                    return true
                case "false", "no", "0":
                    return false
                default:
                    continue
                }
            case .number(let number):
                return number != 0
            default:
                continue
            }
        }

        return nil
    }

    func number(for keys: [String]) -> Double? {
        for key in keys {
            guard let value = self[key] else {
                continue
            }

            switch value {
            case .number(let number):
                return number
            case .string(let string):
                if let number = Double(string.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    return number
                }
            default:
                continue
            }
        }

        return nil
    }

    func stringArray(for keys: [String]) -> [String] {
        for key in keys {
            guard let value = self[key] else {
                continue
            }

            switch value {
            case .array(let values):
                let strings = values.compactMap { item -> String? in
                    let text = item.displayString.trimmingCharacters(in: .whitespacesAndNewlines)
                    return text.isEmpty ? nil : text
                }
                if !strings.isEmpty {
                    return strings
                }
            case .string(let string):
                let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return [trimmed]
                }
            default:
                continue
            }
        }

        return []
    }

    func displayItems(for keys: [String]) -> [MetadataDisplayItem] {
        for key in keys {
            guard let value = self[key] else {
                continue
            }

            let items = value.displayItems
            if !items.isEmpty {
                return items
            }
        }

        return []
    }
}

extension JSONValue {
    var displayItems: [MetadataDisplayItem] {
        switch self {
        case .array(let values):
            return values.enumerated().compactMap { index, value in
                value.displayItem(index: index)
            }
        default:
            if let item = displayItem(index: 0) {
                return [item]
            }

            return []
        }
    }

    private func displayItem(index: Int) -> MetadataDisplayItem? {
        switch self {
        case .string(let string):
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                return nil
            }

            return MetadataDisplayItem(id: "\(index)-\(trimmed)", title: trimmed)
        case .number, .bool:
            let text = displayString
            return MetadataDisplayItem(id: "\(index)-\(text)", title: text)
        case .object(let object):
            let title = object.string(for: ["title", "label", "name", "text", "summary"]) ?? JSONValue.object(object).displayString
            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty else {
                return nil
            }

            return MetadataDisplayItem(
                id: object.string(for: ["id", "key"]) ?? "\(index)-\(trimmedTitle)",
                title: trimmedTitle,
                subtitle: object.string(for: ["subtitle", "description", "detail", "body"]),
                value: object.string(for: ["value", "amount", "label_value", "labelValue"]),
                status: object.string(for: ["status", "state", "tone"]),
                systemImage: object.string(for: ["icon", "system_image", "systemImage"])
            )
        case .array, .null:
            return nil
        }
    }
}

private func normalized(_ value: String?) -> String? {
    let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return trimmed.isEmpty ? nil : trimmed
}
