import Foundation

enum JourneyResponseStatus: Codable, Equatable, Sendable {
    case collecting
    case gateOpen
    case ready
    case unknown(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = (try? container.decode(String.self)) ?? ""

        switch value {
        case "collecting":
            self = .collecting
        case "gateOpen", "gate_open":
            self = .gateOpen
        case "ready":
            self = .ready
        default:
            self = .unknown(value)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .collecting:
            try container.encode("collecting")
        case .gateOpen:
            try container.encode("gateOpen")
        case .ready:
            try container.encode("ready")
        case .unknown(let value):
            try container.encode(value)
        }
    }
}

struct StartJourneyResponse: Decodable, Sendable {
    let session: JourneySession?
    let framing: String?
    let activity: String?
    let card: DynamicCard?
    let progress: JourneyProgress?
    let currentStage: String?
    let currentPhase: JourneyPhase?
}

struct NextJourneyResponse: Decodable, Sendable {
    let status: JourneyResponseStatus
    let session: JourneySession?
    let currentStage: String?
    let currentPhase: JourneyPhase?
    let stageJustCompleted: String?
    let progress: JourneyProgress?
    let card: DynamicCard?
}

struct AnalyzeResponse: Decodable, Sendable {
    let analysis: AnalysisSummary
    let nextStage: String?
}

struct VerifyResponse: Decodable, Sendable {
    let verification: VerificationSummary
    let nextStage: String?

    private enum CodingKeys: String, CodingKey {
        case verification
        case nextStage
    }

    init(verification: VerificationSummary, nextStage: String?) {
        self.verification = verification
        self.nextStage = nextStage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let verification = try container.decodeIfPresent(VerificationSummary.self, forKey: .verification) {
            self.verification = verification
        } else {
            verification = try VerificationSummary(from: decoder)
        }
        nextStage = try container.decodeIfPresent(String.self, forKey: .nextStage)
    }
}

struct LicenseResponse: Decodable, Sendable {
    let license: LicenseRecommendation
    let nextStage: String?
}

struct BankingResponse: Decodable, Sendable {
    let banking: BankingRecommendations
    let nextStage: String?
}

struct FinalPlanResponse: Decodable, Sendable {
    let plan: FinalPlan
}
