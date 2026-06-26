import Foundation
import Observation
import SwiftUI

enum PendingOperation: Equatable, Sendable {
    case startText(String)
    case nextCard(cardID: String)
    case analyze
    case verify
    case license
    case banking
    case finalPlan
    case loadSavedPlan
    case saveFinalPlan
    case shareFinalPlan
}

@MainActor
@Observable
final class JourneyViewModel {
    @ObservationIgnored private let apiService: JourneyAPIServiceProtocol
    @ObservationIgnored private let speechRecognitionService: SpeechRecognitionServiceProtocol
    @ObservationIgnored private let speechSynthesisService: SpeechSynthesisServiceProtocol
    @ObservationIgnored private let localPlanStore: LocalPlanStoreProtocol
    @ObservationIgnored private let shareService: ShareServiceProtocol
    @ObservationIgnored private let analyticsService: AnalyticsServiceProtocol
    @ObservationIgnored private var activeTask: Task<Void, Never>?
    @ObservationIgnored private var pendingOperation: PendingOperation?

    let appTitle: String
    var currentLanguage: AppLanguage
    var layoutDirection: LayoutDirection {
        currentLanguage == .ar ? .rightToLeft : .leftToRight
    }
    var sessionId: String
    var journeyStatus: JourneyStatus
    var currentPhase: JourneyPhase
    var phases: [JourneyPhase]
    var completedPhases: Set<JourneyPhase>
    var progress: JourneyProgress?
    var isBackendBusy: Bool
    var lastUpdatedAt: Date?

    var currentPrompt: String?
    var framingMessage: String?
    var currentAssistantMessage: String?
    var currentCard: DynamicCard?
    var cardAnswerDraft: CardAnswerDraft
    var cardValidationMessage: String?

    var voiceState: VoiceState
    var transcriptState: TranscriptState
    var liveTranscript: String
    var editableTranscript: String
    var transcriptConfidence: Double?
    var textFallbackValue: String
    var canSubmitCurrentInput: Bool {
        !isBackendBusy && (
            !editableTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !textFallbackValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        )
    }
    var inputErrorMessage: String?

    var activeSession: JourneySession?
    var renderableCards: [DynamicCard]
    var profileSections: [ProfileSection]
    var missingFields: [ProfileField]
    var unknownFields: [ProfileField]
    var correctionTarget: CorrectionTarget?

    var analysisSummary: AnalysisSummary?
    var licenseRecommendation: LicenseRecommendation?
    var bankingRecommendations: BankingRecommendations?
    var verificationSummary: VerificationSummary?
    var nextStepChecklist: [NextStepChecklistItem]
    var finalPlan: FinalPlan?
    var savedPlanSummary: SavedPlanSummary?

    var confidence: Double? {
        finalPlan?.confidence ?? analysisSummary?.confidence
    }
    var verifiedFacts: [TrustFact]
    var estimatedFacts: [TrustFact]
    var unverifiedFacts: [TrustFact]
    var guidanceDisclaimer: String
    var toast: ToastState?
    var banner: BannerState?
    var recoverableError: RecoverableError?
    var unsupportedCard: DynamicCard?

    var isTextEntryExpanded: Bool
    var isProfileExpanded: Bool
    var expandedRecommendationIDs: Set<String>
    var showSavedPlan: Bool
    var showShareSheet: Bool
    var sharePayload: SharePayload?
    var copiedItemID: String?
    var reduceMotionPreferred: Bool

    init(
        apiService: JourneyAPIServiceProtocol,
        speechRecognitionService: SpeechRecognitionServiceProtocol,
        speechSynthesisService: SpeechSynthesisServiceProtocol,
        localPlanStore: LocalPlanStoreProtocol,
        shareService: ShareServiceProtocol,
        analyticsService: AnalyticsServiceProtocol
    ) {
        self.apiService = apiService
        self.speechRecognitionService = speechRecognitionService
        self.speechSynthesisService = speechSynthesisService
        self.localPlanStore = localPlanStore
        self.shareService = shareService
        self.analyticsService = analyticsService

        appTitle = "Irshad"
        currentLanguage = .ar
        sessionId = ""
        journeyStatus = .empty
        currentPhase = .goal
        phases = JourneyPhase.visibleOrder
        completedPhases = []
        progress = nil
        isBackendBusy = false
        lastUpdatedAt = nil

        currentPrompt = nil
        framingMessage = nil
        currentAssistantMessage = nil
        currentCard = nil
        cardAnswerDraft = .empty
        cardValidationMessage = nil

        voiceState = .idle
        transcriptState = .empty
        liveTranscript = ""
        editableTranscript = ""
        transcriptConfidence = nil
        textFallbackValue = ""
        inputErrorMessage = nil

        activeSession = nil
        renderableCards = []
        profileSections = []
        missingFields = []
        unknownFields = []
        correctionTarget = nil

        analysisSummary = nil
        licenseRecommendation = nil
        bankingRecommendations = nil
        verificationSummary = nil
        nextStepChecklist = []
        finalPlan = nil
        savedPlanSummary = nil

        verifiedFacts = []
        estimatedFacts = []
        unverifiedFacts = []
        guidanceDisclaimer = ""
        toast = nil
        banner = nil
        recoverableError = nil
        unsupportedCard = nil

        isTextEntryExpanded = false
        isProfileExpanded = false
        expandedRecommendationIDs = []
        showSavedPlan = false
        showShareSheet = false
        sharePayload = nil
        copiedItemID = nil
        reduceMotionPreferred = false
    }
}

extension JourneyViewModel {
    func startJourneyWithVoice() {
        // TODO: Implement voice journey startup orchestration.
    }

    func startJourneyWithText(_ text: String) {
        pendingOperation = .startText(text)
    }

    func submitCurrentAnswer() {
        // TODO: Submit the accepted text or transcript value.
    }

    func submitCardAnswer(_ cardID: String) {
        pendingOperation = .nextCard(cardID: cardID)
    }

    func retryCurrentStep() {
        // TODO: Re-run the current pending/recoverable operation.
    }

    func cancelCurrentOperation() {
        activeTask?.cancel()
        activeTask = nil
        pendingOperation = nil
        isBackendBusy = false
    }

    func beginListening() {
        voiceState = .listening
    }

    func stopListening() {
        voiceState = .idle
    }

    func retryListening() {
        voiceState = .listening
    }

    func acceptTranscript() {
        transcriptState = .accepted
    }

    func updateTranscript(_ value: String) {
        editableTranscript = value
        transcriptState = value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .empty : .editing
    }

    func updateTextFallback(_ value: String) {
        textFallbackValue = value
    }

    func selectSingleOption(cardID: String, optionID: String) {
        cardAnswerDraft = CardAnswerDraft(cardID: cardID, value: .singleOption(optionID), updatedAt: Date())
    }

    func toggleMultiOption(cardID: String, optionID: String) {
        var selectedOptions: Set<String>
        if case .multiOptions(let currentOptions) = cardAnswerDraft.value, cardAnswerDraft.cardID == cardID {
            selectedOptions = currentOptions
        } else {
            selectedOptions = []
        }

        if selectedOptions.contains(optionID) {
            selectedOptions.remove(optionID)
        } else {
            selectedOptions.insert(optionID)
        }

        cardAnswerDraft = CardAnswerDraft(cardID: cardID, value: .multiOptions(selectedOptions), updatedAt: Date())
    }

    func updateCardText(cardID: String, value: String) {
        cardAnswerDraft = CardAnswerDraft(cardID: cardID, value: .text(value), updatedAt: Date())
    }

    func updateCardNumber(cardID: String, value: String) {
        cardAnswerDraft = CardAnswerDraft(cardID: cardID, value: .numberString(value), updatedAt: Date())
    }

    func setToggleAnswer(cardID: String, value: Bool) {
        cardAnswerDraft = CardAnswerDraft(cardID: cardID, value: .toggle(value), updatedAt: Date())
    }

    func toggleChecklistItem(cardID: String, itemID: String) {
        var checkedItems: Set<String>
        if case .checklist(let currentItems) = cardAnswerDraft.value, cardAnswerDraft.cardID == cardID {
            checkedItems = currentItems
        } else {
            checkedItems = []
        }

        if checkedItems.contains(itemID) {
            checkedItems.remove(itemID)
        } else {
            checkedItems.insert(itemID)
        }

        cardAnswerDraft = CardAnswerDraft(cardID: cardID, value: .checklist(checkedItems), updatedAt: Date())
    }

    func expandCard(_ cardID: String) {
        expandedRecommendationIDs.insert(cardID)
    }

    func collapseCard(_ cardID: String) {
        expandedRecommendationIDs.remove(cardID)
    }

    func beginCorrection(fieldID: String) {
        correctionTarget = CorrectionTarget(fieldID: fieldID, label: "", currentValue: nil)
    }

    func submitCorrection(_ value: String) {
        // TODO: Submit correction value during journey orchestration.
    }

    func cancelCorrection() {
        correctionTarget = nil
    }

    func expandRecommendation(_ id: String) {
        expandedRecommendationIDs.insert(id)
    }

    func savePreferredBank(_ id: String) {
        // TODO: Persist preferred bank selection in a later prompt.
    }

    func openURL(_ url: URL) {
        // TODO: Open URLs from trusted recommendation actions.
    }

    func callPhoneNumber(_ phoneNumber: String) {
        // TODO: Start phone call from trusted recommendation actions.
    }

    func copyText(_ text: String) {
        copiedItemID = text
    }

    func markNextStepDone(_ id: String) {
        guard let index = nextStepChecklist.firstIndex(where: { $0.id == id }) else {
            return
        }

        nextStepChecklist[index].isDone.toggle()
        nextStepChecklist[index].status = nextStepChecklist[index].isDone ? .done : .pending
    }

    func openSavedPlan() {
        showSavedPlan = true
    }

    func shareFinalPlan() {
        pendingOperation = .shareFinalPlan
    }

    func copyFinalPlanSummary() {
        copiedItemID = finalPlan?.nextAction
    }

    func continueWithAssistant() {
        showSavedPlan = false
    }

    func dismissToast() {
        toast = nil
    }

    func dismissBanner() {
        banner = nil
    }
}
