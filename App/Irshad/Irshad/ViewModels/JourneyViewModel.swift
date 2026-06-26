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
    @ObservationIgnored private let journeyRouter: JourneyRouter
    @ObservationIgnored private let clipboardClient: ClipboardClient
    @ObservationIgnored private var activeTask: Task<Void, Never>?
    @ObservationIgnored private var speechTask: Task<Void, Never>?
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
        analyticsService: AnalyticsServiceProtocol,
        journeyRouter: JourneyRouter = JourneyRouter(),
        clipboardClient: ClipboardClient? = nil
    ) {
        self.apiService = apiService
        self.speechRecognitionService = speechRecognitionService
        self.speechSynthesisService = speechSynthesisService
        self.localPlanStore = localPlanStore
        self.shareService = shareService
        self.analyticsService = analyticsService
        self.journeyRouter = journeyRouter
        self.clipboardClient = clipboardClient ?? ClipboardClient()

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
        beginListening()
    }

    func startJourneyWithText(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            inputErrorMessage = "Tell Irshad what you want to set up first."
            isTextEntryExpanded = true
            return
        }

        stopListening()
        currentLanguage = inferredLanguage(for: trimmedText)
        let requestSessionID = sessionId.isEmpty ? UUID().uuidString : sessionId
        sessionId = requestSessionID
        pendingOperation = .startText(trimmedText)
        launchBackendOperation(status: .preparing) { [weak self] in
            guard let self else { return }
            try await self.performStartJourney(text: trimmedText, sessionID: requestSessionID)
        }
    }

    func submitCurrentAnswer() {
        let acceptedText = editableTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackText = textFallbackValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = acceptedText.isEmpty ? fallbackText : acceptedText

        guard !value.isEmpty else {
            inputErrorMessage = "Add a short answer first."
            isTextEntryExpanded = true
            return
        }

        if activeSession == nil || currentCard == nil {
            startJourneyWithText(value)
        } else if let cardID = currentCard?.cardId {
            updateCardText(cardID: cardID, value: value)
            submitCardAnswer(cardID)
        }
    }

    func submitCardAnswer(_ cardID: String) {
        pendingOperation = .nextCard(cardID: cardID)
        launchBackendOperation(status: .collecting) { [weak self] in
            guard let self else { return }
            try await self.performNextCard(cardID: cardID, appendLocalAnswer: true)
        }
    }

    func retryCurrentStep() {
        guard let pendingOperation else {
            return
        }

        recoverableError = nil
        cardValidationMessage = nil

        switch pendingOperation {
        case .startText(let text):
            startJourneyWithText(text)
        case .nextCard(let cardID):
            let answerAlreadyAppended = activeSession?.history.contains { $0.cardId == cardID } == true
            launchBackendOperation(status: .collecting) { [weak self] in
                guard let self else { return }
                try await self.performNextCard(cardID: cardID, appendLocalAnswer: !answerAlreadyAppended)
            }
        case .analyze:
            launchBackendOperation(status: .processing) { [weak self] in
                guard let self else { return }
                try await self.runOutputChain(startingAt: .analyze)
            }
        case .verify:
            launchBackendOperation(status: .processing) { [weak self] in
                guard let self else { return }
                try await self.runOutputChain(startingAt: .verify)
            }
        case .license:
            launchBackendOperation(status: .processing) { [weak self] in
                guard let self else { return }
                try await self.runOutputChain(startingAt: .license)
            }
        case .banking:
            launchBackendOperation(status: .processing) { [weak self] in
                guard let self else { return }
                try await self.runOutputChain(startingAt: .banking)
            }
        case .finalPlan:
            launchBackendOperation(status: .processing) { [weak self] in
                guard let self else { return }
                try await self.runOutputChain(startingAt: .finalPlan)
            }
        case .loadSavedPlan:
            openSavedPlan()
        case .saveFinalPlan:
            launchBackendOperation(status: .processing) { [weak self] in
                guard let self else { return }
                try await self.saveCurrentPlan()
            }
        case .shareFinalPlan:
            shareFinalPlan()
        }
    }

    func cancelCurrentOperation() {
        activeTask?.cancel()
        activeTask = nil
        isBackendBusy = false
        if journeyStatus == .preparing || journeyStatus == .processing {
            journeyStatus = activeSession == nil ? .empty : .collecting
        }
    }

    func beginListening() {
        guard !isBackendBusy else {
            return
        }

        speechTask?.cancel()
        inputErrorMessage = nil
        voiceState = .processing
        transcriptState = .empty
        liveTranscript = ""
        editableTranscript = ""
        transcriptConfidence = nil

        speechTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.performListening()
        }
    }

    func stopListening() {
        speechTask?.cancel()
        speechTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.speechRecognitionService.stopListening()
        }
        voiceState = editableTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .idle : .transcriptReady
        transcriptState = editableTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .empty : .final
    }

    func retryListening() {
        inputErrorMessage = nil
        beginListening()
    }

    func acceptTranscript() {
        stopListening()
        let accepted = editableTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !accepted.isEmpty else {
            inputErrorMessage = "We did not catch enough speech. You can type your answer instead."
            return
        }

        transcriptState = .accepted
        startJourneyWithText(accepted)
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
        let field = (profileSections.flatMap(\.fields) + missingFields + unknownFields)
            .first { $0.id == fieldID }
        correctionTarget = CorrectionTarget(
            fieldID: fieldID,
            label: field?.label ?? fieldID,
            currentValue: field?.value
        )
    }

    func submitCorrection(_ value: String) {
        guard let correctionTarget else {
            return
        }

        guard let currentCard else {
            self.correctionTarget = nil
            return
        }

        updateCardText(cardID: currentCard.cardId, value: value)
        if let slot = currentCard.slot, slot == correctionTarget.fieldID {
            submitCardAnswer(currentCard.cardId)
        } else {
            toast = ToastState(id: UUID().uuidString, message: "Correction saved locally for this session.")
        }
        self.correctionTarget = nil
    }

    func cancelCorrection() {
        correctionTarget = nil
    }

    func expandRecommendation(_ id: String) {
        expandedRecommendationIDs.insert(id)
    }

    func savePreferredBank(_ id: String) {
        expandedRecommendationIDs.insert(id)
        toast = ToastState(id: "preferred-bank-\(id)", message: "Bank marked as preferred.")
    }

    func openURL(_ url: URL) {
        guard journeyRouter.canOpenBackendProvidedURL(url), isKnownBackendURL(url) else {
            recoverableError = RecoverableError(
                id: UUID().uuidString,
                title: "Link unavailable",
                message: "This link was not provided by the current journey response.",
                retryKey: nil
            )
            return
        }

        journeyRouter.open(url)
    }

    func callPhoneNumber(_ phoneNumber: String) {
        guard isKnownBackendPhoneNumber(phoneNumber),
              let url = journeyRouter.makeTelephoneURL(from: phoneNumber) else {
            recoverableError = RecoverableError(
                id: UUID().uuidString,
                title: "Phone unavailable",
                message: "This phone number was not provided by the current journey response.",
                retryKey: nil
            )
            return
        }

        journeyRouter.open(url)
    }

    func copyText(_ text: String) {
        clipboardClient.copy(text)
        copiedItemID = text
        toast = ToastState(id: UUID().uuidString, message: "Copied.")
    }

    func markNextStepDone(_ id: String) {
        guard let index = nextStepChecklist.firstIndex(where: { $0.id == id }) else {
            return
        }

        nextStepChecklist[index].isDone.toggle()
        nextStepChecklist[index].status = nextStepChecklist[index].isDone ? .done : .pending
    }

    func openSavedPlan() {
        pendingOperation = .loadSavedPlan
        showSavedPlan = true
        launchBackendOperation(status: journeyStatus) { [weak self] in
            guard let self else { return }
            try await self.performOpenSavedPlan()
        }
    }

    func shareFinalPlan() {
        pendingOperation = .shareFinalPlan
        launchBackendOperation(status: journeyStatus) { [weak self] in
            guard let self else { return }
            try await self.performShareFinalPlan()
        }
    }

    func copyFinalPlanSummary() {
        guard let plan = finalPlan ?? savedPlanSummary?.plan else {
            recoverableError = RecoverableError(
                id: UUID().uuidString,
                title: "Copy unavailable",
                message: "A final plan is needed before copying a summary.",
                retryKey: nil
            )
            return
        }

        let summary = shareService.makeCopySummary(plan, trustFacts: currentTrustFactBundle())
        clipboardClient.copy(summary)
        copiedItemID = "final-plan-summary"
        toast = ToastState(id: UUID().uuidString, message: "Plan summary copied.")
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

private extension JourneyViewModel {
    func launchBackendOperation(
        status: JourneyStatus,
        operation: @MainActor @escaping () async throws -> Void
    ) {
        guard !isBackendBusy else {
            return
        }

        activeTask?.cancel()
        isBackendBusy = true
        recoverableError = nil
        banner = nil
        journeyStatus = status

        activeTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try Task.checkCancellation()
                try await operation()
                try Task.checkCancellation()
                self.isBackendBusy = false
                self.activeTask = nil
                self.lastUpdatedAt = Date()
                await self.track("journey_operation_success")
            } catch is CancellationError {
                self.isBackendBusy = false
                self.activeTask = nil
                await self.track("journey_operation_cancelled")
            } catch APIError.cancelled {
                self.isBackendBusy = false
                self.activeTask = nil
                await self.track("journey_operation_cancelled")
            } catch {
                self.isBackendBusy = false
                self.activeTask = nil
                self.handleRecoverableError(error)
                await self.track("journey_operation_failed")
            }
        }
    }

    func performStartJourney(text: String, sessionID: String) async throws {
        let request = StartJourneyRequest(
            sessionId: sessionID,
            goalText: text,
            language: currentLanguage
        )
        let response = try await apiService.startJourney(request)
        try Task.checkCancellation()

        sessionId = response.session?.sessionId ?? sessionID
        let phase = response.currentPhase
            ?? response.card?.phase
            ?? JourneyPhase(backendValue: response.currentStage)
        activeSession = response.session ?? JourneySession(
            sessionId: sessionId,
            goalText: text,
            currentStage: response.currentStage,
            currentPhase: phase == .unknown ? .goal : phase,
            filledSlots: [:],
            history: []
        )

        if response.session == nil {
            activeSession?.currentStage = response.currentStage
            activeSession?.currentPhase = phase == .unknown ? .goal : phase
        }

        framingMessage = response.framing
        currentAssistantMessage = response.activity ?? response.framing
        currentPrompt = response.card?.title ?? response.activity ?? response.framing
        currentCard = response.card
        renderableCards = response.card.map { [$0] } ?? []
        unsupportedCard = unsupportedCardIfNeeded(response.card)
        progress = response.progress
        currentPhase = normalizedPhase(phase, fallback: response.card?.phase ?? .goal)
        completedPhases = completedPhases(for: currentPhase)
        journeyStatus = .collecting
        cardAnswerDraft = .empty
        cardValidationMessage = nil
        inputErrorMessage = nil
        textFallbackValue = ""
        pendingOperation = nil
        refreshDerivedState()
    }

    func performNextCard(cardID: String, appendLocalAnswer: Bool) async throws {
        guard var session = activeSession else {
            throw ViewModelError.noActiveSession
        }
        guard let card = currentCard, card.cardId == cardID else {
            throw ViewModelError.cardUnavailable
        }

        if appendLocalAnswer {
            let answer = try answerJSON(for: card)
            let historyItem = JourneyHistoryItem(
                cardId: card.cardId,
                question: card.title,
                answer: answer,
                slot: card.slot,
                stage: card.stage,
                timestamp: Date()
            )
            session.history.append(historyItem)
            if let slot = card.slot?.trimmingCharacters(in: .whitespacesAndNewlines), !slot.isEmpty {
                session.filledSlots[slot] = answer
            }
            activeSession = session
            refreshDerivedState()
        }

        let response = try await apiService.nextJourneyStep(
            NextJourneyRequest(sessionId: session.sessionId, session: session)
        )
        try Task.checkCancellation()
        let shouldRunOutputChain = applyNextResponse(response, fallbackSession: session)
        if shouldRunOutputChain {
            try await runOutputChain(startingAt: .analyze)
        }
    }

    func applyNextResponse(_ response: NextJourneyResponse, fallbackSession: JourneySession) -> Bool {
        var session = response.session ?? fallbackSession
        session.currentStage = response.currentStage ?? session.currentStage
        session.currentPhase = response.currentPhase
            ?? JourneyPhase(backendValue: response.currentStage)
        activeSession = session
        progress = response.progress ?? progress

        let phase = response.currentPhase
            ?? response.card?.phase
            ?? JourneyPhase(backendValue: response.currentStage)
        currentPhase = normalizedPhase(phase, fallback: currentPhase)

        if let completed = response.stageJustCompleted {
            completedPhases.insert(JourneyPhase(backendValue: completed))
        }

        switch response.status {
        case .collecting:
            if let card = response.card {
                currentCard = card
                renderableCards = [card]
                unsupportedCard = unsupportedCardIfNeeded(card)
            }
            currentPrompt = response.card?.title ?? currentPrompt
            currentAssistantMessage = response.card?.subtitle ?? currentAssistantMessage
            journeyStatus = .collecting
            pendingOperation = nil
            cardAnswerDraft = .empty
            cardValidationMessage = nil
            refreshDerivedState()
            return false
        case .gateOpen:
            currentCard = response.card
            renderableCards = response.card.map { [$0] } ?? []
            unsupportedCard = unsupportedCardIfNeeded(response.card)
            journeyStatus = .gateOpen
            refreshDerivedState()
            pendingOperation = .analyze
            return true
        case .ready:
            if response.card == nil, let progress, progress.filled >= progress.required {
                currentCard = nil
                renderableCards = []
                unsupportedCard = nil
                journeyStatus = .gateOpen
                refreshDerivedState()
                pendingOperation = .analyze
                return true
            } else {
                pendingOperation = .nextCard(cardID: currentCard?.cardId ?? "")
                recoverableError = RecoverableError(
                    id: UUID().uuidString,
                    title: "Journey paused",
                    message: "Irshad needs one more response before preparing the final plan.",
                    retryKey: "next"
                )
                journeyStatus = .partial
                return false
            }
        case .unknown:
            recoverableError = RecoverableError(
                id: UUID().uuidString,
                title: "Journey paused",
                message: "Irshad received an unexpected journey update. You can retry this step.",
                retryKey: "next"
            )
            journeyStatus = .partial
            return false
        }
    }

    enum OutputChainStart {
        case analyze
        case verify
        case license
        case banking
        case finalPlan
    }

    func runOutputChain(startingAt start: OutputChainStart) async throws {
        guard let session = activeSession else {
            throw ViewModelError.noActiveSession
        }

        journeyStatus = .processing

        if start == .analyze {
            pendingOperation = .analyze
            currentPhase = .analysis
            let response = try await apiService.analyze(
                AnalyzeRequest(sessionId: session.sessionId, session: session)
            )
            try Task.checkCancellation()
            analysisSummary = response.analysis
            completedPhases.insert(.analysis)
            refreshDerivedState()
        }

        if start == .analyze || start == .verify {
            pendingOperation = .verify
            currentPhase = .verify
            let response = try await apiService.verify(
                VerifyRequest(sessionId: session.sessionId, verifyTarget: verifyTarget())
            )
            try Task.checkCancellation()
            verificationSummary = response.verification
            completedPhases.insert(.verify)
            refreshDerivedState()
        }

        if start == .analyze || start == .verify || start == .license {
            pendingOperation = .license
            currentPhase = .license
            let response = try await apiService.license(SessionOnlyRequest(sessionId: session.sessionId))
            try Task.checkCancellation()
            licenseRecommendation = response.license
            completedPhases.insert(.license)
            refreshDerivedState()
        }

        if start == .analyze || start == .verify || start == .license || start == .banking {
            pendingOperation = .banking
            currentPhase = .banking
            let response = try await apiService.banking(SessionOnlyRequest(sessionId: session.sessionId))
            try Task.checkCancellation()
            bankingRecommendations = response.banking
            completedPhases.insert(.banking)
            refreshDerivedState()
        }

        pendingOperation = .finalPlan
        currentPhase = .plan
        let response = try await apiService.finalPlan(SessionOnlyRequest(sessionId: session.sessionId))
        try Task.checkCancellation()
        finalPlan = response.plan
        nextStepChecklist = makeChecklist(from: response.plan)
        completedPhases.insert(.plan)
        journeyStatus = .complete
        refreshDerivedState()
        try await saveCurrentPlan()
        pendingOperation = nil
    }

    func saveCurrentPlan() async throws {
        guard let finalPlan, let activeSession else {
            throw ViewModelError.finalPlanUnavailable
        }

        pendingOperation = .saveFinalPlan
        savedPlanSummary = try await localPlanStore.save(
            plan: finalPlan,
            session: activeSession,
            checklist: nextStepChecklist
        )
        pendingOperation = nil
    }

    func performOpenSavedPlan() async throws {
        guard let summary = try await localPlanStore.loadSavedPlan() else {
            toast = ToastState(id: UUID().uuidString, message: "No saved plan found.")
            pendingOperation = nil
            return
        }

        savedPlanSummary = summary
        finalPlan = summary.plan
        activeSession = summary.session
        sessionId = summary.sessionId
        nextStepChecklist = summary.checklist
        currentPhase = .plan
        completedPhases.insert(.plan)
        journeyStatus = .complete
        showSavedPlan = true
        pendingOperation = nil
        refreshDerivedState()
    }

    func performShareFinalPlan() async throws {
        guard let plan = finalPlan ?? savedPlanSummary?.plan else {
            throw ViewModelError.finalPlanUnavailable
        }

        sharePayload = try await shareService.makeFinalPlanSharePayload(
            plan,
            trustFacts: currentTrustFactBundle()
        )
        showShareSheet = true
        pendingOperation = nil
    }

    func performListening() async {
        let authorization = await speechRecognitionService.requestAuthorization()
        guard authorization == .authorized else {
            voiceState = .failed("Speech permission is not available. You can type instead.")
            transcriptState = .empty
            inputErrorMessage = "Speech permission is not available. You can type instead."
            isTextEntryExpanded = true
            speechTask = nil
            return
        }

        do {
            let stream = try await speechRecognitionService.beginListening(language: currentLanguage)
            voiceState = .listening
            transcriptState = .partial
            for try await event in stream {
                liveTranscript = event.text
                editableTranscript = event.text
                transcriptConfidence = event.confidence
                transcriptState = event.isFinal ? .final : .partial
                if event.isFinal {
                    voiceState = .transcriptReady
                }
            }
            if !editableTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                voiceState = .transcriptReady
                transcriptState = .final
            } else {
                voiceState = .idle
                transcriptState = .empty
            }
        } catch is CancellationError {
            await speechRecognitionService.cancelListening()
        } catch SpeechError.permissionDenied {
            voiceState = .failed("Speech permission is not available. You can type instead.")
            inputErrorMessage = "Speech permission is not available. You can type instead."
            isTextEntryExpanded = true
        } catch {
            voiceState = .failed("Speech recognition stopped. You can try again or type instead.")
            inputErrorMessage = "Speech recognition stopped. You can try again or type instead."
            isTextEntryExpanded = true
        }

        speechTask = nil
    }
}

private extension JourneyViewModel {
    enum ViewModelError: Error {
        case noActiveSession
        case cardUnavailable
        case invalidAnswer(String)
        case finalPlanUnavailable
    }

    func answerJSON(for card: DynamicCard) throws -> JSONValue {
        guard cardAnswerDraft.cardID == card.cardId else {
            if allowsEmptyAnswer(card) {
                return .bool(true)
            }
            throw ViewModelError.invalidAnswer("Choose or type an answer before continuing.")
        }

        switch cardAnswerDraft.value {
        case .empty:
            if allowsEmptyAnswer(card) {
                return .bool(true)
            }
            throw ViewModelError.invalidAnswer("Choose or type an answer before continuing.")
        case .singleOption(let optionID):
            guard let option = card.options.first(where: { $0.id == optionID }) else {
                throw ViewModelError.invalidAnswer("Choose an available option.")
            }
            return .string(option.value ?? option.label)
        case .multiOptions(let optionIDs):
            let values = card.options
                .filter { optionIDs.contains($0.id) }
                .map { JSONValue.string($0.value ?? $0.label) }
            guard !values.isEmpty else {
                throw ViewModelError.invalidAnswer("Choose at least one option.")
            }
            return .array(values)
        case .text(let value):
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw ViewModelError.invalidAnswer("Type an answer before continuing.")
            }
            return .string(trimmed)
        case .numberString(let value):
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw ViewModelError.invalidAnswer("Add a number before continuing.")
            }
            if let number = Double(trimmed) {
                return .number(number)
            }
            return .string(trimmed)
        case .toggle(let value):
            return .bool(value)
        case .checklist(let itemIDs):
            let values = card.options
                .filter { itemIDs.contains($0.id) }
                .map { JSONValue.string($0.value ?? $0.label) }
            guard !values.isEmpty || allowsEmptyAnswer(card) else {
                throw ViewModelError.invalidAnswer("Choose at least one item.")
            }
            return .array(values)
        }
    }

    func allowsEmptyAnswer(_ card: DynamicCard) -> Bool {
        switch card.type {
        case .info, .summary, .recommendation, .roadmap, .none:
            return true
        case .unsupported:
            return metadataBool(card.metadata, keys: ["requires_action", "requiresAction", "needs_action", "needsAction"]) ?? false
        default:
            return false
        }
    }

    func metadataBool(_ metadata: [String: JSONValue], keys: [String]) -> Bool? {
        for key in keys {
            guard let value = metadata[key] else {
                continue
            }

            switch value {
            case .bool(let bool):
                return bool
            case .string(let string):
                switch string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
                case "true", "yes", "1":
                    return true
                case "false", "no", "0":
                    return false
                default:
                    continue
                }
            case .number(let number):
                return number != 0
            default:
                continue
            }
        }

        return nil
    }

    func unsupportedCardIfNeeded(_ card: DynamicCard?) -> DynamicCard? {
        guard let card else {
            return nil
        }

        if case .unsupported = card.type {
            return card
        }
        if case .unsupported = card.kind {
            return card
        }
        return nil
    }

    func normalizedPhase(_ phase: JourneyPhase, fallback: JourneyPhase) -> JourneyPhase {
        phase == .unknown ? fallback : phase
    }

    func completedPhases(for phase: JourneyPhase) -> Set<JourneyPhase> {
        guard let index = phases.firstIndex(of: phase), index > 0 else {
            return []
        }

        return Set(phases.prefix(index))
    }

    func verifyTarget() -> String {
        let candidate = analysisSummary?.candidateLicenses.first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let base = candidate?.isEmpty == false ? candidate! : "best candidate license"
        return "\(base) fee + requirements 2026"
    }

    func makeChecklist(from plan: FinalPlan) -> [NextStepChecklistItem] {
        var items = plan.roadmap.enumerated().map { index, step in
            NextStepChecklistItem(
                id: "roadmap-\(index + 1)",
                title: step,
                detail: nil,
                status: .pending,
                actionMetadata: [:],
                isDone: false
            )
        }

        if let nextAction = plan.nextAction?.trimmingCharacters(in: .whitespacesAndNewlines),
           !nextAction.isEmpty,
           !items.contains(where: { $0.title == nextAction }) {
            items.insert(
                NextStepChecklistItem(
                    id: "next-action",
                    title: nextAction,
                    detail: "Recommended next action",
                    status: .pending,
                    actionMetadata: [:],
                    isDone: false
                ),
                at: 0
            )
        }

        return items
    }

    func handleRecoverableError(_ error: Error) {
        if case ViewModelError.invalidAnswer(let message) = error {
            cardValidationMessage = message
            recoverableError = nil
            return
        }

        let retryKey: String?
        switch pendingOperation {
        case .startText:
            retryKey = "start"
        case .nextCard:
            retryKey = "next"
        case .analyze:
            retryKey = "analyze"
        case .verify:
            retryKey = "verify"
        case .license:
            retryKey = "license"
        case .banking:
            retryKey = "banking"
        case .finalPlan:
            retryKey = "final_plan"
        case .loadSavedPlan:
            retryKey = "saved_plan"
        case .saveFinalPlan:
            retryKey = "save_plan"
        case .shareFinalPlan:
            retryKey = "share_plan"
        case .none:
            retryKey = nil
        }

        recoverableError = RecoverableError(
            id: UUID().uuidString,
            title: "Irshad needs another try",
            message: userSafeMessage(for: error),
            retryKey: retryKey
        )

        if activeSession == nil, currentCard == nil {
            journeyStatus = .failed
        } else if finalPlan != nil {
            journeyStatus = .partial
        } else if journeyStatus == .processing || journeyStatus == .gateOpen {
            journeyStatus = .partial
        }
    }

    func userSafeMessage(for error: Error) -> String {
        switch error {
        case APIError.timeout:
            return "The request took too long. Your current journey is still here, and you can retry."
        case APIError.transport:
            return "Irshad could not reach the service. Your current journey is still here, and you can retry."
        case APIError.badStatus:
            return "Irshad could not complete this step. Your current journey is still here, and you can retry."
        case APIError.decoding:
            return "Irshad received a response it could not read safely. You can retry this step."
        case ViewModelError.noActiveSession:
            return "Start a journey before continuing."
        case ViewModelError.cardUnavailable:
            return "This question is no longer available. You can retry the current step."
        case ViewModelError.finalPlanUnavailable:
            return "A final plan is needed before using this action."
        default:
            return "Something interrupted this step. Your current journey is still here, and you can retry."
        }
    }

    func inferredLanguage(for text: String) -> AppLanguage {
        text.unicodeScalars.contains { scalar in
            (0x0600...0x06FF).contains(Int(scalar.value))
                || (0x0750...0x077F).contains(Int(scalar.value))
                || (0x08A0...0x08FF).contains(Int(scalar.value))
        } ? .ar : .en
    }

    func track(_ name: String) async {
        await analyticsService.track(
            AnalyticsEvent(
                name: name,
                properties: [
                    "session_id": .string(sessionId),
                    "status": .string(journeyStatus.rawValue)
                ],
                timestamp: Date()
            )
        )
    }
}

private extension JourneyViewModel {
    func refreshDerivedState() {
        let trustBundle = deriveTrustFacts()
        verifiedFacts = trustBundle.verified
        estimatedFacts = trustBundle.estimated
        unverifiedFacts = trustBundle.unverified
        guidanceDisclaimer = "This plan is guidance only. Confirm unverified, missing, unknown, and estimated items with the relevant authority or provider before acting."
        deriveProfileSections()
    }

    func deriveProfileSections() {
        guard let activeSession else {
            profileSections = []
            missingFields = []
            unknownFields = []
            return
        }

        let fields = activeSession.filledSlots
            .sorted { $0.key < $1.key }
            .map { key, value in
                profileField(id: key, value: value)
            }

        missingFields = fields.filter { $0.trustStatus == .missing }
        unknownFields = fields.filter { $0.trustStatus == .unknown }
        profileSections = [
            ProfileSection(
                id: "captured-profile",
                title: "Captured profile",
                fields: fields.filter { $0.trustStatus != .missing && $0.trustStatus != .unknown }
            )
        ].filter { !$0.fields.isEmpty }
    }

    func profileField(id: String, value: JSONValue) -> ProfileField {
        if case .object(let object) = value {
            let label = object["label"]?.displayString.nonEmptyValue ?? labelize(id)
            let displayValue = object["value"]?.displayString.nonEmptyValue
                ?? object["answer"]?.displayString.nonEmptyValue
                ?? value.displayString
            let status = TrustStatus(rawValue: object["trustStatus"]?.displayString ?? "")
                ?? TrustStatus(rawValue: object["trust_status"]?.displayString ?? "")
                ?? TrustStatus(rawValue: object["status"]?.displayString ?? "")
                ?? .guidanceOnly
            return ProfileField(
                id: id,
                label: label,
                value: displayValue,
                trustStatus: status,
                correctionID: id
            )
        }

        let displayValue = value.displayString
        let status: TrustStatus
        switch displayValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "missing":
            status = .missing
        case "unknown":
            status = .unknown
        default:
            status = .guidanceOnly
        }

        return ProfileField(
            id: id,
            label: labelize(id),
            value: displayValue,
            trustStatus: status,
            correctionID: id
        )
    }

    func deriveTrustFacts() -> TrustFactBundle {
        var verified: [TrustFact] = []
        var estimated: [TrustFact] = []
        var unverified: [TrustFact] = []
        var missing: [TrustFact] = []
        var unknown: [TrustFact] = []

        if let analysisSummary {
            appendOptionalFact(
                label: "Estimated setup cost",
                value: analysisSummary.estSetupCostRange,
                status: .estimated,
                source: nil,
                to: &estimated
            )
            for activity in analysisSummary.matchedActivities {
                estimated.append(
                    TrustFact(
                        id: "activity-\(activity.id)",
                        label: "Matched activity",
                        value: activity.label,
                        status: .estimated,
                        source: nil
                    )
                )
            }
            for license in analysisSummary.candidateLicenses {
                appendOptionalFact(
                    label: "Candidate license",
                    value: license,
                    status: .estimated,
                    source: nil,
                    to: &estimated
                )
            }
            for (index, item) in analysisSummary.unverified.enumerated() {
                unverified.append(
                    TrustFact(
                        id: "analysis-unverified-\(index)",
                        label: "Needs confirmation",
                        value: item,
                        status: .unverified,
                        source: nil
                    )
                )
            }
        }

        if let verificationSummary {
            for (key, value) in verificationSummary.verifiedFacts.sorted(by: { $0.key < $1.key }) {
                verified.append(
                    TrustFact(
                        id: "verified-\(key)",
                        label: labelize(key),
                        value: value.displayString,
                        status: .verified,
                        source: verificationSummary.authority ?? verificationSummary.sources.first
                    )
                )
            }

            if verificationSummary.status == .notFound {
                appendOptionalFact(
                    label: "Verification result",
                    value: verificationSummary.whatToConfirm ?? verificationSummary.message ?? verificationSummary.info,
                    status: .unverified,
                    source: verificationSummary.authority ?? verificationSummary.sources.first,
                    to: &unverified
                )
            }
        }

        if let best = licenseRecommendation?.best {
            appendOptionalFact(
                label: "Recommended license",
                value: best.type,
                status: .guidanceOnly,
                source: best.source,
                to: &estimated
            )
            appendOptionalFact(
                label: "License estimated cost",
                value: best.estCost,
                status: best.costStatus,
                source: best.source,
                verified: &verified,
                estimated: &estimated,
                unverified: &unverified,
                missing: &missing,
                unknown: &unknown
            )
        }

        if let bankingRecommendations {
            for bank in bankingRecommendations.banks {
                appendOptionalFact(
                    label: "Bank recommendation",
                    value: bank.name,
                    status: .guidanceOnly,
                    source: bank.source,
                    to: &estimated
                )
                appendOptionalFact(
                    label: "\(bank.name) minimum balance",
                    value: bank.minBalance,
                    status: .estimated,
                    source: bank.source,
                    to: &estimated
                )
            }
        }

        if let finalPlan {
            appendOptionalFact(
                label: "Estimated total cost",
                value: finalPlan.totalEstCost,
                status: .estimated,
                source: nil,
                to: &estimated
            )
            appendOptionalFact(
                label: "Estimated timeline",
                value: finalPlan.totalTimeline,
                status: .estimated,
                source: nil,
                to: &estimated
            )
            for (index, item) in finalPlan.unverified.enumerated() {
                unverified.append(
                    TrustFact(
                        id: "plan-unverified-\(index)",
                        label: "Needs confirmation",
                        value: item,
                        status: .unverified,
                        source: nil
                    )
                )
            }
        }

        return TrustFactBundle(
            verified: dedupedFacts(verified),
            estimated: dedupedFacts(estimated),
            unverified: dedupedFacts(unverified),
            missing: dedupedFacts(missing),
            unknown: dedupedFacts(unknown)
        )
    }

    func currentTrustFactBundle() -> TrustFactBundle {
        let derived = deriveTrustFacts()
        return TrustFactBundle(
            verified: verifiedFacts.isEmpty ? derived.verified : verifiedFacts,
            estimated: estimatedFacts.isEmpty ? derived.estimated : estimatedFacts,
            unverified: unverifiedFacts.isEmpty ? derived.unverified : unverifiedFacts,
            missing: missingFields.map {
                TrustFact(id: "missing-\($0.id)", label: $0.label, value: $0.value, status: .missing, source: nil)
            },
            unknown: unknownFields.map {
                TrustFact(id: "unknown-\($0.id)", label: $0.label, value: $0.value, status: .unknown, source: nil)
            }
        )
    }

    func appendOptionalFact(
        label: String,
        value: String?,
        status: TrustStatus,
        source: String?,
        to facts: inout [TrustFact]
    ) {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return
        }

        facts.append(
            TrustFact(
                id: "\(label)-\(value)".stableIdentifier,
                label: label,
                value: value,
                status: status,
                source: source?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmptyValue
            )
        )
    }

    func appendOptionalFact(
        label: String,
        value: String?,
        status: TrustStatus,
        source: String?,
        verified: inout [TrustFact],
        estimated: inout [TrustFact],
        unverified: inout [TrustFact],
        missing: inout [TrustFact],
        unknown: inout [TrustFact]
    ) {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return
        }

        let fact = TrustFact(
            id: "\(label)-\(value)".stableIdentifier,
            label: label,
            value: value,
            status: status,
            source: source?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmptyValue
        )

        switch status {
        case .verified:
            verified.append(fact)
        case .estimated, .guidanceOnly:
            estimated.append(fact)
        case .unverified:
            unverified.append(fact)
        case .missing:
            missing.append(fact)
        case .unknown:
            unknown.append(fact)
        }
    }

    func dedupedFacts(_ facts: [TrustFact]) -> [TrustFact] {
        var seen: Set<String> = []
        return facts.filter { fact in
            let key = "\(fact.label)|\(fact.value)|\(fact.status.rawValue)"
            guard !seen.contains(key) else {
                return false
            }
            seen.insert(key)
            return true
        }
    }
}

private extension JourneyViewModel {
    func isKnownBackendURL(_ url: URL) -> Bool {
        knownBackendURLs().contains(normalizedURLString(url))
    }

    func isKnownBackendPhoneNumber(_ phoneNumber: String) -> Bool {
        let normalized = normalizedPhone(phoneNumber)
        guard !normalized.isEmpty else {
            return false
        }

        return knownBackendPhoneNumbers().contains(normalized)
    }

    func knownBackendURLs() -> Set<String> {
        var urls: Set<String> = []

        if let contactURL = verificationSummary?.contactURL {
            urls.insert(normalizedURLString(contactURL))
        }
        verificationSummary?.sources.compactMap(URL.init(string:)).forEach {
            urls.insert(normalizedURLString($0))
        }
        if let url = licenseRecommendation?.best?.source.flatMap(URL.init(string:)) {
            urls.insert(normalizedURLString(url))
        }
        licenseRecommendation?.alternatives.compactMap { $0.source }.compactMap(URL.init(string:)).forEach {
            urls.insert(normalizedURLString($0))
        }
        bankingRecommendations?.banks.forEach { bank in
            if let url = bank.source.flatMap(URL.init(string:)) {
                urls.insert(normalizedURLString(url))
            }
            collectURLs(from: bank.metadata, into: &urls)
        }

        [currentCard].compactMap { $0 }.forEach { collectURLs(from: $0, into: &urls) }
        renderableCards.forEach { collectURLs(from: $0, into: &urls) }

        return urls
    }

    func knownBackendPhoneNumbers() -> Set<String> {
        var phones: Set<String> = []

        if let phone = verificationSummary?.phone {
            phones.insert(normalizedPhone(phone))
        }
        [currentCard].compactMap { $0 }.forEach { collectPhones(from: $0.metadata, into: &phones) }
        renderableCards.forEach { collectPhones(from: $0.metadata, into: &phones) }
        bankingRecommendations?.banks.forEach { collectPhones(from: $0.metadata, into: &phones) }
        licenseRecommendation?.best.map { collectPhones(from: $0.metadata, into: &phones) }
        licenseRecommendation?.alternatives.forEach { collectPhones(from: $0.metadata, into: &phones) }

        return phones.filter { !$0.isEmpty }
    }

    func collectURLs(from card: DynamicCard, into urls: inout Set<String>) {
        collectURLs(from: card.metadata, into: &urls)
        card.options.forEach { collectURLs(from: $0.metadata, into: &urls) }
    }

    func collectURLs(from metadata: [String: JSONValue], into urls: inout Set<String>) {
        for value in metadata.values {
            collectURLs(from: value, into: &urls)
        }
    }

    func collectURLs(from value: JSONValue, into urls: inout Set<String>) {
        switch value {
        case .string(let string):
            if let url = URL(string: string), journeyRouter.canOpenBackendProvidedURL(url) {
                urls.insert(normalizedURLString(url))
            }
        case .object(let object):
            collectURLs(from: object, into: &urls)
        case .array(let values):
            values.forEach { collectURLs(from: $0, into: &urls) }
        default:
            break
        }
    }

    func collectPhones(from metadata: [String: JSONValue], into phones: inout Set<String>) {
        for (key, value) in metadata {
            let lowercasedKey = key.lowercased()
            if lowercasedKey.contains("phone") || lowercasedKey.contains("tel") {
                let normalized = normalizedPhone(value.displayString)
                if !normalized.isEmpty {
                    phones.insert(normalized)
                }
            }

            switch value {
            case .object(let object):
                collectPhones(from: object, into: &phones)
            case .array(let values):
                values.forEach {
                    if case .object(let object) = $0 {
                        collectPhones(from: object, into: &phones)
                    }
                }
            default:
                break
            }
        }
    }

    func normalizedURLString(_ url: URL) -> String {
        url.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func normalizedPhone(_ phoneNumber: String) -> String {
        phoneNumber.filter { $0 == "+" || $0.isNumber }
    }

    func labelize(_ key: String) -> String {
        key
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { word in
                word.prefix(1).uppercased() + word.dropFirst()
            }
            .joined(separator: " ")
    }
}

private extension String {
    var nonEmptyValue: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var stableIdentifier: String {
        let normalized = lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        return normalized.isEmpty ? UUID().uuidString : normalized
    }
}
