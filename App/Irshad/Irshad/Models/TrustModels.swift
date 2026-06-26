import Foundation

enum TrustStatus: String, Codable, CaseIterable, Sendable {
    case verified
    case estimated
    case unverified
    case missing
    case unknown
    case guidanceOnly = "guidance_only"
}

struct TrustFact: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let label: String
    let value: String
    let status: TrustStatus
    let source: String?
}

struct TrustFactBundle: Codable, Equatable, Sendable {
    var verified: [TrustFact]
    var estimated: [TrustFact]
    var unverified: [TrustFact]
    var missing: [TrustFact]
    var unknown: [TrustFact]
}
