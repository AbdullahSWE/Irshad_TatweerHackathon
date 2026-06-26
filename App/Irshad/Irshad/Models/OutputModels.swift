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

    private enum CodingKeys: String, CodingKey {
        case status
        case info
        case verifiedFacts
        case facts
        case sources
        case authority
        case phone
        case contactURL
        case contactUrl
        case url
        case whatToConfirm
        case message
        case metadata
    }

    init(
        status: VerificationStatus,
        info: String?,
        verifiedFacts: [String: JSONValue],
        sources: [String],
        authority: String?,
        phone: String?,
        contactURL: URL?,
        whatToConfirm: String?,
        message: String?,
        metadata: [String: JSONValue]
    ) {
        self.status = status
        self.info = info
        self.verifiedFacts = verifiedFacts
        self.sources = sources
        self.authority = authority
        self.phone = phone
        self.contactURL = contactURL
        self.whatToConfirm = whatToConfirm
        self.message = message
        self.metadata = metadata
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        status = try container.decodeIfPresent(VerificationStatus.self, forKey: .status) ?? .unknown("")
        info = try container.decodeIfPresent(String.self, forKey: .info)
        verifiedFacts = try container.decodeIfPresent([String: JSONValue].self, forKey: .verifiedFacts)
            ?? container.decodeIfPresent([String: JSONValue].self, forKey: .facts)
            ?? [:]
        sources = try container.decodeIfPresent([String].self, forKey: .sources) ?? []
        authority = try container.decodeIfPresent(String.self, forKey: .authority)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        contactURL = try container.decodeIfPresent(URL.self, forKey: .contactURL)
            ?? container.decodeIfPresent(URL.self, forKey: .contactUrl)
            ?? container.decodeIfPresent(URL.self, forKey: .url)
        whatToConfirm = try container.decodeIfPresent(String.self, forKey: .whatToConfirm)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        metadata = try container.decodeIfPresent([String: JSONValue].self, forKey: .metadata) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(info, forKey: .info)
        try container.encode(verifiedFacts, forKey: .verifiedFacts)
        try container.encode(sources, forKey: .sources)
        try container.encodeIfPresent(authority, forKey: .authority)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encodeIfPresent(contactURL, forKey: .contactURL)
        try container.encodeIfPresent(whatToConfirm, forKey: .whatToConfirm)
        try container.encodeIfPresent(message, forKey: .message)
        try container.encode(metadata, forKey: .metadata)
    }
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
