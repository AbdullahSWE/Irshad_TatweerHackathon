import Foundation

struct AnalysisSummary: Codable, Equatable, Sendable {
    let matchedActivities: [MatchedActivity]
    let estSetupCostRange: String?
    let candidateLicenses: [String]
    let confidence: Double?
    let unverified: [String]
    let metadata: [String: JSONValue]
}

struct MatchedActivity: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let label: String
    let metadata: [String: JSONValue]
}

enum VerificationStatus: Codable, Equatable, Sendable {
    case verified
    case notFound
    case unknown(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = (try? container.decode(String.self)) ?? ""

        switch value.lowercased() {
        case "verified":
            self = .verified
        case "not_found", "notfound":
            self = .notFound
        default:
            self = .unknown(value)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .verified:
            try container.encode("verified")
        case .notFound:
            try container.encode("not_found")
        case .unknown(let value):
            try container.encode(value)
        }
    }
}

struct VerificationSummary: Codable, Equatable, Sendable {
    let status: VerificationStatus
    let info: String?
    let verifiedFacts: [String: JSONValue]
    let sources: [String]
    let authority: String?
    let phone: String?
    let contactURL: URL?
    let whatToConfirm: String?
    let message: String?
    let metadata: [String: JSONValue]
}

struct LicenseRecommendation: Codable, Equatable, Sendable {
    let best: LicenseOption?
    let alternatives: [LicenseOption]
    let metadata: [String: JSONValue]
}

struct LicenseOption: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let type: String
    let issuer: String?
    let pros: [String]
    let cons: [String]
    let timeline: String?
    let approvals: [String]
    let estCost: String?
    let costStatus: TrustStatus
    let source: String?
    let metadata: [String: JSONValue]
}

struct BankingRecommendations: Codable, Equatable, Sendable {
    let banks: [BankRecommendation]
    let metadata: [String: JSONValue]
}

struct BankRecommendation: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let name: String
    let minBalance: String?
    let requirements: [String]
    let docsNeeded: [String]
    let likelyToApprove: Bool?
    let source: String?
    let metadata: [String: JSONValue]
}

struct FinalPlan: Codable, Equatable, Sendable {
    let roadmap: [String]
    let totalEstCost: String?
    let totalTimeline: String?
    let nextAction: String?
    let confidence: Double?
    let unverified: [String]
    let metadata: [String: JSONValue]
}

enum NextStepStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case done
}

struct NextStepChecklistItem: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let title: String
    let detail: String?
    var status: NextStepStatus
    let actionMetadata: [String: JSONValue]
    var isDone: Bool
}
