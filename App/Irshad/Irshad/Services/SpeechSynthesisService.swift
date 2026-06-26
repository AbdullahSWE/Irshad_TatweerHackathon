import AVFoundation
import Foundation

protocol SpeechSynthesisServiceProtocol: AnyObject {
    func speak(_ text: String, language: AppLanguage, voice: VoicePersona?) async
    func stopSpeaking() async
}

final class SpeechSynthesisService: NSObject, SpeechSynthesisServiceProtocol {
    private let synthesizer: AVSpeechSynthesizer

    init(synthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer()) {
        self.synthesizer = synthesizer
        super.init()
    }

    func speak(_ text: String, language: AppLanguage, voice: VoicePersona?) async {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: trimmedText)
        utterance.voice = Self.matchingVoice(language: language, persona: voice)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        synthesizer.speak(utterance)
    }

    func stopSpeaking() async {
        guard synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
    }
}

private extension SpeechSynthesisService {
    static func matchingVoice(language: AppLanguage, persona: VoicePersona?) -> AVSpeechSynthesisVoice? {
        let localeIdentifier = language.speechLocaleIdentifier
        let voices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == localeIdentifier }

        if let persona, let personaMatch = voices.first(where: { $0.matches(persona: persona) }) {
            return personaMatch
        }

        return AVSpeechSynthesisVoice(language: localeIdentifier) ?? voices.first
    }
}

private extension AVSpeechSynthesisVoice {
    func matches(persona: VoicePersona) -> Bool {
        if #available(iOS 13.0, macOS 10.15, *) {
            switch (persona, gender) {
            case (.male, .male), (.female, .female):
                return true
            default:
                return false
            }
        }

        return false
    }
}
