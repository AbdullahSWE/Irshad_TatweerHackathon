import Foundation
import AVFoundation
import Speech

protocol SpeechRecognitionServiceProtocol: AnyObject {
    func requestAuthorization() async -> SpeechAuthorizationStatus
    func beginListening(language: AppLanguage) async throws -> AsyncThrowingStream<SpeechTranscriptEvent, Error>
    func stopListening() async
    func cancelListening() async
}

final class SpeechRecognitionService: NSObject, SpeechRecognitionServiceProtocol {
    private let audioEngine = AVAudioEngine()
    private let audioSession: AVAudioSession
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var streamContinuation: AsyncThrowingStream<SpeechTranscriptEvent, Error>.Continuation?
    private var didInstallAudioTap = false

    init(audioSession: AVAudioSession = .sharedInstance()) {
        self.audioSession = audioSession
        super.init()
    }

    func requestAuthorization() async -> SpeechAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: SpeechAuthorizationStatus(status))
            }
        }
    }

    func beginListening(language: AppLanguage) async throws -> AsyncThrowingStream<SpeechTranscriptEvent, Error> {
        await cancelListening()

        let authorizationStatus = await requestAuthorization()
        guard authorizationStatus == .authorized else {
            throw SpeechError.permissionDenied
        }

        guard await requestMicrophoneAccess() else {
            throw SpeechError.permissionDenied
        }

        let locale = Locale(identifier: language.speechLocaleIdentifier)
        guard let speechRecognizer = SFSpeechRecognizer(locale: locale), speechRecognizer.isAvailable else {
            throw SpeechError.recognitionFailed("Speech recognition is unavailable for \(language.speechLocaleIdentifier).")
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if #available(iOS 13.0, macOS 10.15, *) {
            request.requiresOnDeviceRecognition = false
        }

        let stream = AsyncThrowingStream<SpeechTranscriptEvent, Error> { continuation in
            continuation.onTermination = { [weak self] _ in
                Task {
                    await self?.cancelListening()
                }
            }
            self.streamContinuation = continuation
        }

        do {
            try configureAudioSessionForRecording()
            try startAudioEngine(with: request)
        } catch {
            finishListening(throwing: SpeechError.microphoneUnavailable, cancelTask: true)
            throw SpeechError.microphoneUnavailable
        }

        recognitionRequest = request
        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                self.streamContinuation?.yield(SpeechTranscriptEvent(result: result))
            }

            if let error {
                self.finishListening(throwing: SpeechError.recognitionFailed(error.localizedDescription), cancelTask: false)
            } else if result?.isFinal == true {
                self.finishListening(throwing: nil, cancelTask: false)
            }
        }

        return stream
    }

    func stopListening() async {
        finishListening(throwing: nil, cancelTask: false)
    }

    func cancelListening() async {
        finishListening(throwing: nil, cancelTask: true)
    }
}

private extension SpeechRecognitionService {
    func requestMicrophoneAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            return await requestCurrentMicrophoneAccess()
        }

        return await requestLegacyMicrophoneAccess()
    }

    @available(iOS 17.0, *)
    func requestCurrentMicrophoneAccess() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }

    @available(iOS, introduced: 7.0, deprecated: 17.0)
    func requestLegacyMicrophoneAccess() async -> Bool {
        switch audioSession.recordPermission {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                audioSession.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }

    func configureAudioSessionForRecording() throws {
        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    func startAudioEngine(with request: SFSpeechAudioBufferRecognitionRequest) throws {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        didInstallAudioTap = true

        audioEngine.prepare()
        try audioEngine.start()
    }

    func finishListening(throwing error: Error?, cancelTask: Bool) {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        if didInstallAudioTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            didInstallAudioTap = false
        }

        if cancelTask {
            recognitionTask?.cancel()
        } else {
            recognitionRequest?.endAudio()
        }

        recognitionTask = nil
        recognitionRequest = nil

        if let error {
            streamContinuation?.finish(throwing: error)
        } else {
            streamContinuation?.finish()
        }
        streamContinuation = nil

        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }
}

private extension SpeechAuthorizationStatus {
    init(_ status: SFSpeechRecognizerAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .authorized:
            self = .authorized
        case .denied:
            self = .denied
        case .restricted:
            self = .restricted
        @unknown default:
            self = .unavailable
        }
    }
}

private extension SpeechTranscriptEvent {
    init(result: SFSpeechRecognitionResult) {
        let transcription = result.bestTranscription
        let confidences = transcription.segments
            .map(\.confidence)
            .filter { $0 >= 0 }
        let averageConfidence = confidences.isEmpty
            ? nil
            : Double(confidences.reduce(0, +)) / Double(confidences.count)

        self.init(
            text: transcription.formattedString,
            isFinal: result.isFinal,
            confidence: averageConfidence
        )
    }
}

extension AppLanguage {
    var speechLocaleIdentifier: String {
        switch self {
        case .ar:
            return "ar-AE"
        case .en:
            return "en-US"
        }
    }
}
