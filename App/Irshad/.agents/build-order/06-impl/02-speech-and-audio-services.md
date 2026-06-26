# Prompt 06.02: Speech And Audio Services Implementation

## Context

Implement the native speech recognition and optional speech synthesis services for Irshad. The app is voice-first and Arabic-first, but the user must always retain a text fallback. The service layer reports authorization, transcript events, and non-blocking speech playback; the ViewModel decides how the UI responds.

This prompt implements speech/audio services only. Do not implement ViewModel orchestration, UI views, reusable components, theme files, visual styling, animations, gestures, backend calls, persistence, or sharing.

## File Location

Update:

- `Irshad/Services/SpeechRecognitionService.swift`
- `Irshad/Services/SpeechSynthesisService.swift`
- `Irshad/Models/VoiceModels.swift` only if model refinements are required

## Dependencies

- Imports: `Foundation`, `Speech`, `AVFoundation`
- Depends on: `AppLanguage`, `SpeechAuthorizationStatus`, `SpeechTranscriptEvent`, `SpeechError`, `VoicePersona`
- Later consumers: `JourneyViewModel`, speech tests or manual device QA

## Requirements

- Request speech recognition authorization with `SFSpeechRecognizer.requestAuthorization`.
- Check microphone permission through `AVAudioSession` APIs.
- Use Arabic locale by default for `.ar` and English locale for `.en`.
- Return transcript events through `AsyncThrowingStream<SpeechTranscriptEvent, Error>`.
- Emit partial and final transcript events when available.
- Stop and clean up audio engine, recognition request, recognition task, and stream continuation.
- Permission denial must throw `SpeechError.permissionDenied` or return a denied authorization status, not crash.
- Speech synthesis is optional and non-blocking. Failure to speak must not fail a journey.

## Interface

Keep this recognition protocol unchanged:

```swift
protocol SpeechRecognitionServiceProtocol: AnyObject {
    func requestAuthorization() async -> SpeechAuthorizationStatus
    func beginListening(language: AppLanguage) async throws -> AsyncThrowingStream<SpeechTranscriptEvent, Error>
    func stopListening() async
    func cancelListening() async
}
```

Implement these locale mappings:

```swift
extension AppLanguage {
    var speechLocaleIdentifier: String {
        switch self {
        case .ar: return "ar-AE"
        case .en: return "en-US"
        }
    }
}
```

Keep this synthesis protocol unchanged:

```swift
protocol SpeechSynthesisServiceProtocol: AnyObject {
    func speak(_ text: String, language: AppLanguage, voice: VoicePersona?) async
    func stopSpeaking() async
}
```

## Implementation Notes

- `SpeechRecognitionService` may inherit from `NSObject` for Apple delegate compatibility.
- Use `SFSpeechAudioBufferRecognitionRequest` and `AVAudioEngine`.
- Configure the audio session for recording before listening and deactivate/restore as appropriate after stopping.
- Guard against starting a second recognition task while one is active; stop or cancel the previous task first.
- If `SFSpeechRecognizer(locale:)` is unavailable for a requested language, throw `SpeechError.recognitionFailed`.
- Populate transcript confidence when Apple provides segment confidence. If not available, leave confidence nil.
- `stopListening()` should finish gracefully.
- `cancelListening()` should cancel and clear resources.
- `SpeechSynthesisService` can use `AVSpeechSynthesizer`, `AVSpeechUtterance`, and a best-effort voice matching language/persona.
- Do not block the main actor while streaming speech.

## Acceptance Criteria

- [ ] `requestAuthorization()` maps all Apple authorization states to `SpeechAuthorizationStatus`.
- [ ] Permission denied does not crash and can be handled by text fallback.
- [ ] `beginListening(language: .ar)` uses the Arabic locale identifier.
- [ ] `beginListening(language: .en)` uses the English locale identifier.
- [ ] Partial transcript events can be emitted.
- [ ] Final transcript events can be emitted.
- [ ] Stopping listening releases audio engine and recognition resources.
- [ ] Cancelling listening cancels the active task and finishes the stream.
- [ ] Speech synthesis speaks text when possible and silently tolerates unavailable voices.
- [ ] No ViewModel behavior, UI, component, theme, style, animation, gesture, backend, persistence, or sharing logic is added by this prompt.
