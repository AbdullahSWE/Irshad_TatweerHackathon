import Foundation
import Speech

protocol SpeechRecognitionServiceProtocol: AnyObject {
    func requestAuthorization() async -> SpeechAuthorizationStatus
    func beginListening(language: AppLanguage) async throws -> AsyncThrowingStream<SpeechTranscriptEvent, Error>
    func stopListening() async
    func cancelListening() async
}

final class SpeechRecognitionService: NSObject, SpeechRecognitionServiceProtocol {
    override init() {
        super.init()
    }

    func requestAuthorization() async -> SpeechAuthorizationStatus {
        .unavailable
    }

    func beginListening(language: AppLanguage) async throws -> AsyncThrowingStream<SpeechTranscriptEvent, Error> {
        fatalError("TODO")
    }

    func stopListening() async {}

    func cancelListening() async {}
}
