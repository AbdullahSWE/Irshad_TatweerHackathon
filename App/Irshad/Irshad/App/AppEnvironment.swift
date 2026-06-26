import Foundation

struct AppEnvironment: Sendable {
    let apiService: JourneyAPIServiceProtocol
    let speechRecognitionService: SpeechRecognitionServiceProtocol
    let speechSynthesisService: SpeechSynthesisServiceProtocol
    let localPlanStore: LocalPlanStoreProtocol
    let shareService: ShareServiceProtocol
    let analyticsService: AnalyticsServiceProtocol

    static var live: AppEnvironment {
        AppEnvironment(
            apiService: LocalJourneyAPIService(),
            speechRecognitionService: SpeechRecognitionService(),
            speechSynthesisService: SpeechSynthesisService(),
            localPlanStore: LocalPlanStore(),
            shareService: ShareService(),
            analyticsService: NoopAnalyticsService()
        )
    }

    @MainActor
    func makeJourneyViewModel() -> JourneyViewModel {
        JourneyViewModel(
            apiService: apiService,
            speechRecognitionService: speechRecognitionService,
            speechSynthesisService: speechSynthesisService,
            localPlanStore: localPlanStore,
            shareService: shareService,
            analyticsService: analyticsService
        )
    }
}
