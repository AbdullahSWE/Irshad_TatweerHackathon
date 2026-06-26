import Foundation

struct StartJourneyRequest: Encodable, Sendable {
    let sessionId: String
    let goalText: String
    let language: AppLanguage
}

struct NextJourneyRequest: Encodable, Sendable {
    let sessionId: String
    let session: JourneySession
}

struct AnalyzeRequest: Encodable, Sendable {
    let sessionId: String
    let session: JourneySession
}

struct VerifyRequest: Encodable, Sendable {
    let sessionId: String
    let verifyTarget: String
}

struct SessionOnlyRequest: Encodable, Sendable {
    let sessionId: String
}
