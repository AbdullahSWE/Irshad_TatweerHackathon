import Foundation

struct JourneySession: Identifiable, Codable, Equatable, Sendable {
    var id: String { sessionId }
    let sessionId: String
    var goalText: String
    var currentStage: String?
    var currentPhase: JourneyPhase
    var filledSlots: [String: JSONValue]
    var history: [JourneyHistoryItem]

    private enum CodingKeys: String, CodingKey {
        case sessionId
        case goalText
        case currentStage
        case currentPhase
        case filledSlots
        case history
    }

    init(
        sessionId: String,
        goalText: String,
        currentStage: String?,
        currentPhase: JourneyPhase,
        filledSlots: [String: JSONValue],
        history: [JourneyHistoryItem]
    ) {
        self.sessionId = sessionId
        self.goalText = goalText
        self.currentStage = currentStage
        self.currentPhase = currentPhase
        self.filledSlots = filledSlots
        self.history = history
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let currentStage = try container.decodeIfPresent(String.self, forKey: .currentStage)
        let phaseValue = try container.decodeIfPresent(String.self, forKey: .currentPhase)

        sessionId = try container.decode(String.self, forKey: .sessionId)
        goalText = try container.decodeIfPresent(String.self, forKey: .goalText) ?? ""
        self.currentStage = currentStage
        currentPhase = JourneyPhase(backendValue: currentStage ?? phaseValue)
        filledSlots = try container.decodeIfPresent([String: JSONValue].self, forKey: .filledSlots) ?? [:]
        history = try container.decodeIfPresent([JourneyHistoryItem].self, forKey: .history) ?? []
    }
}

struct JourneyHistoryItem: Identifiable, Codable, Equatable, Sendable {
    var id: String { cardId }
    let cardId: String
    let question: String
    let answer: JSONValue
    let slot: String?
    let stage: String?
    let timestamp: Date
}
