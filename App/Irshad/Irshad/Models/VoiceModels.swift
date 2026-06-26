import Foundation

enum VoiceState: Codable, Equatable, Sendable {
    case idle
    case listening
    case processing
    case transcriptReady
    case failed(String)
}

enum TranscriptState: Codable, Equatable, Sendable {
    case empty
    case partial
    case final
    case editing
    case accepted
}

struct SpeechTranscriptEvent: Codable, Equatable, Sendable {
    let text: String
    let isFinal: Bool
    let confidence: Double?
}

enum SpeechAuthorizationStatus: Codable, Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
    case unavailable
}
