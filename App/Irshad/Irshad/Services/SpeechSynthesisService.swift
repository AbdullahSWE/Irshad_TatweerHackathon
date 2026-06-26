import AVFoundation
import Foundation

protocol SpeechSynthesisServiceProtocol: AnyObject {
    func speak(_ text: String, language: AppLanguage, voice: VoicePersona?) async
    func stopSpeaking() async
}

final class SpeechSynthesisService: NSObject, SpeechSynthesisServiceProtocol {
    private let synthesizer: AVSpeechSynthesizer
    private let audioSession: AVAudioSession
    private var speechContinuation: CheckedContinuation<Void, Never>?
    private weak var activeUtterance: AVSpeechUtterance?

    init(
        synthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer(),
        audioSession: AVAudioSession = .sharedInstance()
    ) {
        self.synthesizer = synthesizer
        self.audioSession = audioSession
        super.init()
        self.synthesizer.delegate = self
    }

    func speak(_ text: String, language: AppLanguage, voice: VoicePersona?) async {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: trimmedText)
        utterance.voice = Self.matchingVoice(language: language, persona: voice)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        configureAudioSessionForSpeech()

        if synthesizer.isSpeaking {
            speechContinuation?.resume()
            speechContinuation = nil
            activeUtterance = nil
            synthesizer.stopSpeaking(at: .immediate)
        }

        await withCheckedContinuation { continuation in
            speechContinuation = continuation
            activeUtterance = utterance
            synthesizer.speak(utterance)
        }
    }

    func stopSpeaking() async {
        guard synthesizer.isSpeaking else { return }
        speechContinuation?.resume()
        speechContinuation = nil
        activeUtterance = nil
        synthesizer.stopSpeaking(at: .immediate)
    }
}

private extension SpeechSynthesisService {
    func configureAudioSessionForSpeech() {
        do {
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            assertionFailure("Unable to configure audio session for speech: \(error.localizedDescription)")
        }
    }
}

extension SpeechSynthesisService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        guard utterance === activeUtterance else { return }
        speechContinuation?.resume()
        speechContinuation = nil
        activeUtterance = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        guard utterance === activeUtterance else { return }
        speechContinuation?.resume()
        speechContinuation = nil
        activeUtterance = nil
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
