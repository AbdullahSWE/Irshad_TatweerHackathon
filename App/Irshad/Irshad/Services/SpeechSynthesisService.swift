import AVFoundation
import Foundation

protocol SpeechSynthesisServiceProtocol: AnyObject {
    func speak(_ text: String, language: AppLanguage, voice: VoicePersona?) async
    func stopSpeaking() async
}

final class SpeechSynthesisService: NSObject, SpeechSynthesisServiceProtocol {
    override init() {
        super.init()
    }

    func speak(_ text: String, language: AppLanguage, voice: VoicePersona?) async {}

    func stopSpeaking() async {}
}
