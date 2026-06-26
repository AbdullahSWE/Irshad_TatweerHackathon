import Foundation

enum DynamicCardKind: Codable, Equatable, Sendable {
    case question
    case confirmation
    case info
    case unsupported(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = (try? container.decode(String.self)) ?? ""

        switch value.lowercased() {
        case "question":
            self = .question
        case "confirmation":
            self = .confirmation
        case "info":
            self = .info
        default:
            self = .unsupported(value)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .question:
            try container.encode("question")
        case .confirmation:
            try container.encode("confirmation")
        case .info:
            try container.encode("info")
        case .unsupported(let value):
            try container.encode(value)
        }
    }
}

enum DynamicCardType: Codable, Equatable, Sendable {
    case singleSelect
    case multiSelect
    case text
    case number
    case toggle
    case checklist
    case info
    case summary
    case recommendation
    case roadmap
    case none
    case unsupported(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = (try? container.decode(String.self)) ?? "none"

        switch value.lowercased() {
        case "single_select", "singleselect":
            self = .singleSelect
        case "multi_select", "multiselect":
            self = .multiSelect
        case "text":
            self = .text
        case "number":
            self = .number
        case "toggle":
            self = .toggle
        case "checklist":
            self = .checklist
        case "info":
            self = .info
        case "summary":
            self = .summary
        case "recommendation":
            self = .recommendation
        case "roadmap":
            self = .roadmap
        case "none":
            self = .none
        default:
            self = .unsupported(value)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .singleSelect:
            try container.encode("single_select")
        case .multiSelect:
            try container.encode("multi_select")
        case .text:
            try container.encode("text")
        case .number:
            try container.encode("number")
        case .toggle:
            try container.encode("toggle")
        case .checklist:
            try container.encode("checklist")
        case .info:
            try container.encode("info")
        case .summary:
            try container.encode("summary")
        case .recommendation:
            try container.encode("recommendation")
        case .roadmap:
            try container.encode("roadmap")
        case .none:
            try container.encode("none")
        case .unsupported(let value):
            try container.encode(value)
        }
    }
}

struct DynamicCard: Identifiable, Codable, Equatable, Sendable {
    var id: String { cardId }
    let cardId: String
    let kind: DynamicCardKind
    let type: DynamicCardType
    let title: String
    let subtitle: String?
    let options: [DynamicCardOption]
    let slot: String?
    let stage: String?
    let phase: JourneyPhase
    let metadata: [String: JSONValue]

    private enum CodingKeys: String, CodingKey {
        case cardId
        case kind
        case type
        case title
        case subtitle
        case options
        case slot
        case stage
        case phase
        case currentPhase
        case metadata
    }

    init(
        cardId: String,
        kind: DynamicCardKind,
        type: DynamicCardType,
        title: String,
        subtitle: String?,
        options: [DynamicCardOption],
        slot: String?,
        stage: String?,
        phase: JourneyPhase,
        metadata: [String: JSONValue]
    ) {
        self.cardId = cardId
        self.kind = kind
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.options = options
        self.slot = slot
        self.stage = stage
        self.phase = phase
        self.metadata = metadata
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let explicitPhase = try container.decodeIfPresent(String.self, forKey: .phase)
            ?? container.decodeIfPresent(String.self, forKey: .currentPhase)
        let stage = try container.decodeIfPresent(String.self, forKey: .stage)

        cardId = try container.decodeIfPresent(String.self, forKey: .cardId) ?? UUID().uuidString
        kind = try container.decodeIfPresent(DynamicCardKind.self, forKey: .kind) ?? .unsupported("")
        type = try container.decodeIfPresent(DynamicCardType.self, forKey: .type) ?? .none
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        options = try container.decodeIfPresent([DynamicCardOption].self, forKey: .options) ?? []
        slot = try container.decodeIfPresent(String.self, forKey: .slot)
        self.stage = stage
        phase = JourneyPhase(serviceValue: explicitPhase ?? stage)
        metadata = try container.decodeIfPresent([String: JSONValue].self, forKey: .metadata) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(cardId, forKey: .cardId)
        try container.encode(kind, forKey: .kind)
        try container.encode(type, forKey: .type)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(subtitle, forKey: .subtitle)
        try container.encode(options, forKey: .options)
        try container.encodeIfPresent(slot, forKey: .slot)
        try container.encodeIfPresent(stage, forKey: .stage)
        try container.encode(phase, forKey: .phase)
        try container.encode(metadata, forKey: .metadata)
    }
}

struct DynamicCardOption: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let label: String
    let value: String?
    let metadata: [String: JSONValue]

    private enum CodingKeys: String, CodingKey {
        case id
        case label
        case value
        case metadata
    }

    init(id: String, label: String, value: String?, metadata: [String: JSONValue]) {
        self.id = id
        self.label = label
        self.value = value
        self.metadata = metadata
    }

    init(from decoder: Decoder) throws {
        if let stringContainer = try? decoder.singleValueContainer(),
           let rawValue = try? stringContainer.decode(String.self) {
            id = DynamicCardOption.normalizedID(from: rawValue)
            label = rawValue
            value = rawValue
            metadata = [:]
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        value = try container.decodeIfPresent(String.self, forKey: .value)
        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? value
            ?? DynamicCardOption.normalizedID(from: label)
        metadata = try container.decodeIfPresent([String: JSONValue].self, forKey: .metadata) ?? [:]
    }

    private static func normalizedID(from label: String) -> String {
        let normalized = label
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")

        return normalized.isEmpty ? UUID().uuidString : normalized
    }
}
