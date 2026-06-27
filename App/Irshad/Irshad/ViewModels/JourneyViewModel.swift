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

enum ActiveResultScreen: Equatable, Sendable {
    case none
    case loadingLicense
    case license
    case loadingBanking
    case banking
    case authority
    case finalPlan
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
    @ObservationIgnored private var speechWarmupTask: Task<Void, Never>?
    @ObservationIgnored private var pendingOperation: PendingOperation?

    let appTitle: String
    var currentLanguage: AppLanguage
    var layoutDirection: LayoutDirection {
        currentLanguage == .ar ? .rightToLeft : .leftToRight
    }
    var selectedVoicePersona: VoicePersona
    var hasStartedOnboarding: Bool
    var sessionId: String
    var journeyStatus: JourneyStatus
    var currentPhase: JourneyPhase
    var phases: [JourneyPhase]
    var completedPhases: Set<JourneyPhase>
    var progress: JourneyProgress?
    var isServiceBusy: Bool
    var serviceActionMessage: String?
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
        !isServiceBusy && (
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
    var activeResultScreen: ActiveResultScreen
    var isVerificationDecisionPending: Bool
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
    var debugTrace: String?
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
        currentLanguage = .en
        selectedVoicePersona = .female
        hasStartedOnboarding = false
        sessionId = ""
        journeyStatus = .empty
        currentPhase = .goal
        phases = JourneyPhase.visibleOrder
        completedPhases = []
        progress = nil
        isServiceBusy = false
        serviceActionMessage = nil
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
        activeResultScreen = .none
        isVerificationDecisionPending = false
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
        debugTrace = nil
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
    func selectLanguage(_ language: AppLanguage) {
        currentLanguage = language
        prepareSpeechEngine()
    }

    func selectVoicePersona(_ persona: VoicePersona) {
        selectedVoicePersona = persona
        prepareSpeechEngine()
    }

    func prepareSpeechEngine() {
        speechWarmupTask?.cancel()
        speechWarmupTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.speechSynthesisService.prepare(language: self.currentLanguage, voice: self.selectedVoicePersona)
        }
    }

    var onboardingGreetingMessage: String {
        let name = selectedVoicePersona.displayName(in: currentLanguage)

        switch currentLanguage {
        case .ar:
            return "السلام عليكم، أنا \(name) وسأساعدك في إعداد مشروعك. أخبرني ما نوع المشروع الذي تريد تأسيسه."
        case .en:
            return "Assalamu Alaikum, I'm \(name) and I'm here to help you set up your business. Please share what business you'd like to set up."
        }
    }

    var firstQuestionIntroMessage: String {
        switch currentLanguage {
        case .ar:
            return "نود أن نسألك بعض الأسئلة حتى نقدم لك التوصيات المناسبة."
        case .en:
            return "We would like to ask you a few questions so we can provide the proper recommendations."
        }
    }

    var phaseHeadline: String {
        let emoji = selectedVoicePersona.assistantEmoji
        let title: String
        switch (currentPhase, currentLanguage) {
        case (.goal, .ar):
            title = "ماذا تريد أن تبدأ؟"
        case (.goal, .en):
            title = "What do you want to start?"
        case (.business, .ar):
            title = "أخبرنا عن مشروعك"
        case (.business, .en):
            title = "Tell us about your business"
        case (.founder, .ar):
            title = "أخبرنا عنك"
        case (.founder, .en):
            title = "Tell us about you"
        case (.details, .ar):
            title = "تفاصيل المشروع"
        case (.details, .en):
            title = "Business details"
        case (.budget, .ar):
            title = "الميزانية والحجم"
        case (.budget, .en):
            title = "Budget and scale"
        case (.documents, .ar):
            title = "المستندات والأهلية"
        case (.documents, .en):
            title = "Documents and eligibility"
        case (.analysis, .ar):
            title = "تحليل إرشاد"
        case (.analysis, .en):
            title = "AI analysis"
        case (.license, .ar):
            title = "توصيات الرخصة"
        case (.license, .en):
            title = "License recommendations"
        case (.banking, .ar):
            title = "توصيات الحساب البنكي"
        case (.banking, .en):
            title = "Banking recommendations"
        case (.verify, .ar):
            title = "التحقق من الجهة الرسمية"
        case (.verify, .en):
            title = "Authority verification"
        case (.nextSteps, .ar):
            title = "المواعيد والخطوات التالية"
        case (.nextSteps, .en):
            title = "Appointments and next steps"
        case (.plan, .ar):
            title = "خطة إطلاق المشروع"
        case (.plan, .en):
            title = "Business launch plan"
        case (.unknown, .ar):
            title = "رحلة إرشاد"
        case (.unknown, .en):
            title = "Irshad journey"
        }
        return "\(title) \(emoji)"
    }

    var questionScreenTitle: String {
        switch currentLanguage {
        case .ar:
            return "ساعدنا نفهم أكثر \(selectedVoicePersona.assistantEmoji)"
        case .en:
            return "Help us understand better \(selectedVoicePersona.assistantEmoji)"
        }
    }

    var compactBusinessLabel: String {
        let fallback: String
        switch currentLanguage {
        case .ar:
            fallback = "لم يحدد بعد"
        case .en:
            fallback = "Not decided yet"
        }

        guard let activeSession else {
            return fallback
        }

        let candidates = [
            activeSession.filledSlots["activity"]?.displayString,
            activeSession.goalText
        ]

        return candidates
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? fallback
    }

    var shouldShowVerificationDecision: Bool {
        isVerificationDecisionPending
            && bankingRecommendations != nil
            && verificationSummary == nil
            && finalPlan == nil
    }

    var isAdditionalContextPromptActive: Bool {
        journeyStatus == .gateOpen
            && activeSession != nil
            && currentCard == nil
            && finalPlan == nil
            && !isServiceBusy
    }

    var additionalContextTitle: String {
        switch currentLanguage {
        case .ar:
            return "هل تود إضافة شيء آخر؟"
        case .en:
            return "Would you like to add anything else?"
        }
    }

    var additionalContextMessage: String {
        switch currentLanguage {
        case .ar:
            return "إذا كانت لديك تفاصيل أخيرة من طرفك، قلها الآن. أو يمكنك تخطي هذه الخطوة وسأجهز خطتك."
        case .en:
            return "If there is anything more from your end, say it now. Or skip ahead if it is all good."
        }
    }

    var additionalContextSkipTitle: String {
        switch currentLanguage {
        case .ar:
            return "لا، كل شيء جيد"
        case .en:
            return "No, it's all good"
        }
    }

    var isChoiceQuestionActive: Bool {
        guard let currentCard, currentCard.isChoiceQuestion else {
            return false
        }

        return !currentCard.allowsCustomInput
    }

    var shouldShowInputOverlay: Bool {
        switch activeResultScreen {
        case .loadingLicense, .license, .loadingBanking, .banking, .authority, .finalPlan:
            return false
        case .none:
            return !isChoiceQuestionActive && !isAdditionalContextPromptActive
        }
    }

    func beginOnboarding() {
        guard !hasStartedOnboarding else {
            beginListening()
            return
        }

        hasStartedOnboarding = true
        currentPrompt = onboardingGreetingMessage
        speechTask?.cancel()
        speechTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.speakCurrentPrompt()
            self.beginListening()
        }
    }

    func startJourneyWithVoice() {
        beginOnboarding()
    }

    func startJourneyWithText(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            inputErrorMessage = localizedInputError(.missingBusinessIdea)
            isTextEntryExpanded = true
            return
        }

        stopListening()
        hasStartedOnboarding = true
        let requestSessionID = sessionId.isEmpty ? UUID().uuidString : sessionId
        sessionId = requestSessionID
        DebugLog.api("ViewModel startJourneyWithText session=\(requestSessionID) language=\(currentLanguage.rawValue) input=\"\(DebugLog.preview(trimmedText))\"")
        pendingOperation = .startText(trimmedText)
        launchServiceOperation(status: .preparing) { [weak self] in
            guard let self else { return }
            try await self.performStartJourney(text: trimmedText, sessionID: requestSessionID)
        }
    }

    func submitCurrentAnswer() {
        let acceptedText = editableTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackText = textFallbackValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = acceptedText.isEmpty ? fallbackText : acceptedText

        if isAdditionalContextPromptActive {
            submitAdditionalContext(value)
            return
        }

        guard !value.isEmpty else {
            inputErrorMessage = localizedInputError(.missingAnswer)
            isTextEntryExpanded = true
            return
        }

        if activeSession == nil || currentCard == nil {
            startJourneyWithText(value)
        } else if let card = currentCard {
            do {
                try applyTranscript(value, to: card)
                submitCardAnswer(card.cardId)
            } catch ViewModelError.invalidAnswer(let message) {
                inputErrorMessage = message
                cardValidationMessage = message
                voiceState = .transcriptReady
                transcriptState = .editing
                isTextEntryExpanded = true
            } catch {
                handleRecoverableError(error)
            }
        }
    }

    func submitCardAnswer(_ cardID: String) {
        pendingOperation = .nextCard(cardID: cardID)
        launchServiceOperation(status: .collecting) { [weak self] in
            guard let self else { return }
            try await self.performNextCard(cardID: cardID, appendLocalAnswer: true)
        }
    }

    func submitAdditionalContext(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            inputErrorMessage = localizedInputError(.missingAnswer)
            voiceState = .idle
            transcriptState = .empty
            return
        }

        appendAdditionalContext(trimmed)
        proceedFromAdditionalContext()
    }

    func skipAdditionalContext() {
        resetInputAfterSuccessfulSubmit()
        proceedFromAdditionalContext()
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
            launchServiceOperation(status: .collecting) { [weak self] in
                guard let self else { return }
                try await self.performNextCard(cardID: cardID, appendLocalAnswer: !answerAlreadyAppended)
            }
        case .analyze:
            launchServiceOperation(status: .processing) { [weak self] in
                guard let self else { return }
                try await self.runOutputChain(startingAt: .analyze)
            }
        case .verify:
            launchServiceOperation(status: .processing) { [weak self] in
                guard let self else { return }
                try await self.runOutputChain(startingAt: .verify)
            }
        case .license:
            launchServiceOperation(status: .processing) { [weak self] in
                guard let self else { return }
                try await self.runOutputChain(startingAt: .license)
            }
        case .banking:
            launchServiceOperation(status: .processing) { [weak self] in
                guard let self else { return }
                try await self.runOutputChain(startingAt: .banking)
            }
        case .finalPlan:
            launchServiceOperation(status: .processing) { [weak self] in
                guard let self else { return }
                try await self.runOutputChain(startingAt: .finalPlan)
            }
        case .loadSavedPlan:
            openSavedPlan()
        case .saveFinalPlan:
            launchServiceOperation(status: .processing) { [weak self] in
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
        isServiceBusy = false
        if journeyStatus == .preparing || journeyStatus == .processing {
            journeyStatus = activeSession == nil ? .empty : .collecting
        }
    }

    func beginListening() {
        guard !isServiceBusy else {
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
        voiceState = .processing
        transcriptState = editableTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .empty : .partial
        speechTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.speechRecognitionService.stopListening()
            self.voiceState = self.editableTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .idle : .transcriptReady
            self.transcriptState = self.editableTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .empty : .final
            self.speechTask = nil
        }
    }

    func stopListeningAndSubmit() {
        speechTask?.cancel()
        speechTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.speechRecognitionService.stopListening()
            self.speechTask = nil
            self.submitRecognizedSpeech()
        }
    }

    func retryListening() {
        inputErrorMessage = nil
        beginListening()
    }

    func acceptTranscript() {
        stopListening()
        submitRecognizedSpeech()
    }

    func updateTranscript(_ value: String) {
        editableTranscript = value
        transcriptState = value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .empty : .editing
    }

    func submitRecognizedSpeech() {
        let accepted = editableTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = textFallbackValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !accepted.isEmpty || !fallback.isEmpty else {
            voiceState = .idle
            transcriptState = .empty
            inputErrorMessage = localizedInputError(.emptyTranscript)
            return
        }

        voiceState = .idle
        transcriptState = accepted.isEmpty ? .editing : .accepted
        submitCurrentAnswer()
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
            toast = ToastState(id: UUID().uuidString, message: localizedToast(.correctionSaved))
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
        toast = ToastState(id: "preferred-bank-\(id)", message: localizedToast(.preferredBankSaved))
    }

    func showBankingOptions() {
        guard licenseRecommendation != nil, bankingRecommendations == nil else {
            activeResultScreen = .banking
            currentPhase = .banking
            journeyStatus = .showingResults
            return
        }

        pendingOperation = .banking
        launchServiceOperation(status: .processing) { [weak self] in
            guard let self else { return }
            try await self.runOutputChain(startingAt: .banking)
        }
    }

    func showAuthorityContacts() {
        guard bankingRecommendations != nil else {
            return
        }

        if verificationSummary != nil {
            activeResultScreen = .authority
            currentPhase = .verify
            journeyStatus = .showingResults
            return
        }

        isVerificationDecisionPending = false
        pendingOperation = .verify
        launchServiceOperation(status: .processing) { [weak self] in
            guard let self else { return }
            try await self.runOutputChain(startingAt: .verify)
        }
    }

    func createFinalActionPlan() {
        guard bankingRecommendations != nil, finalPlan == nil else {
            activeResultScreen = .finalPlan
            currentPhase = .plan
            journeyStatus = .complete
            return
        }

        isVerificationDecisionPending = false
        pendingOperation = .finalPlan
        launchServiceOperation(status: .processing) { [weak self] in
            guard let self else { return }
            try await self.runOutputChain(startingAt: .finalPlan)
        }
    }

    func openURL(_ url: URL) {
        guard journeyRouter.canOpenTrustedURL(url), isKnownTrustedURL(url) else {
            recoverableError = RecoverableError(
                id: UUID().uuidString,
                title: localizedRecoverableTitle(.linkUnavailable),
                message: localizedRecoverableMessage(.linkUnavailable),
                retryKey: nil
            )
            return
        }

        journeyRouter.open(url)
    }

    func callPhoneNumber(_ phoneNumber: String) {
        guard isKnownTrustedPhoneNumber(phoneNumber),
              let url = journeyRouter.makeTelephoneURL(from: phoneNumber) else {
            recoverableError = RecoverableError(
                id: UUID().uuidString,
                title: localizedRecoverableTitle(.phoneUnavailable),
                message: localizedRecoverableMessage(.phoneUnavailable),
                retryKey: nil
            )
            return
        }

        journeyRouter.open(url)
    }

    func copyText(_ text: String) {
        clipboardClient.copy(text)
        copiedItemID = text
        toast = ToastState(id: UUID().uuidString, message: localizedToast(.copied))
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
        launchServiceOperation(status: journeyStatus) { [weak self] in
            guard let self else { return }
            try await self.performOpenSavedPlan()
        }
    }

    func shareFinalPlan() {
        pendingOperation = .shareFinalPlan
        launchServiceOperation(status: journeyStatus) { [weak self] in
            guard let self else { return }
            try await self.performShareFinalPlan()
        }
    }

    func verifyBeforeFinalPlan() {
        guard shouldShowVerificationDecision else {
            return
        }

        isVerificationDecisionPending = false
        pendingOperation = .verify
        launchServiceOperation(status: .processing) { [weak self] in
            guard let self else { return }
            try await self.runOutputChain(startingAt: .verify)
        }
    }

    func skipVerificationAndCreatePlan() {
        guard bankingRecommendations != nil, finalPlan == nil else {
            return
        }

        isVerificationDecisionPending = false
        pendingOperation = .finalPlan
        launchServiceOperation(status: .processing) { [weak self] in
            guard let self else { return }
            try await self.runOutputChain(startingAt: .finalPlan)
        }
    }

    func copyFinalPlanSummary() {
        guard let plan = finalPlan ?? savedPlanSummary?.plan else {
            recoverableError = RecoverableError(
                id: UUID().uuidString,
                title: localizedRecoverableTitle(.copyUnavailable),
                message: localizedRecoverableMessage(.copyUnavailable),
                retryKey: nil
            )
            return
        }

        let summary = shareService.makeCopySummary(plan, trustFacts: currentTrustFactBundle())
        clipboardClient.copy(summary)
        copiedItemID = "final-plan-summary"
        toast = ToastState(id: UUID().uuidString, message: localizedToast(.planSummaryCopied))
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
    enum InputErrorCopyKey {
        case missingBusinessIdea
        case missingAnswer
        case emptyTranscript
        case voiceUnavailable
        case voiceRecognitionFailed
    }

    enum RecoverableTitleCopyKey {
        case retryNeeded
        case journeyPaused
        case linkUnavailable
        case phoneUnavailable
        case copyUnavailable
    }

    enum RecoverableMessageCopyKey {
        case timeout
        case transport
        case badStatus
        case decoding
        case noActiveSession
        case cardUnavailable
        case finalPlanUnavailable
        case generic
        case needsAnotherAnswer
        case unexpectedJourneyUpdate
        case linkUnavailable
        case phoneUnavailable
        case copyUnavailable
    }

    enum ToastCopyKey {
        case correctionSaved
        case preferredBankSaved
        case copied
        case planSummaryCopied
    }

    func localizedInputError(_ key: InputErrorCopyKey) -> String {
        switch (key, currentLanguage) {
        case (.missingBusinessIdea, .ar):
            return "اكتب فكرة مشروعك أولاً."
        case (.missingBusinessIdea, .en):
            return "Type your business idea first."
        case (.missingAnswer, .ar):
            return "أضف إجابة قصيرة أولاً."
        case (.missingAnswer, .en):
            return "Add a short answer first."
        case (.emptyTranscript, .ar):
            return "لم نلتقط كلاماً كافياً. يمكنك كتابة الإجابة بدلاً من ذلك."
        case (.emptyTranscript, .en):
            return "We did not catch enough speech. You can type instead."
        case (.voiceUnavailable, .ar):
            return "إذن الصوت غير متاح. يمكنك الكتابة بدلاً من ذلك."
        case (.voiceUnavailable, .en):
            return "Voice permission is unavailable. You can type instead."
        case (.voiceRecognitionFailed, .ar):
            return "توقف التعرف على الصوت. يمكنك المحاولة مرة أخرى أو الكتابة."
        case (.voiceRecognitionFailed, .en):
            return "Speech recognition stopped. You can try again or type."
        }
    }

    func localizedRecoverableTitle(_ key: RecoverableTitleCopyKey) -> String {
        switch (key, currentLanguage) {
        case (.retryNeeded, .ar):
            return "يحتاج إرشاد إلى محاولة أخرى"
        case (.retryNeeded, .en):
            return "Irshad needs another try"
        case (.journeyPaused, .ar):
            return "توقفت الرحلة مؤقتاً"
        case (.journeyPaused, .en):
            return "Journey paused"
        case (.linkUnavailable, .ar):
            return "الرابط غير متاح"
        case (.linkUnavailable, .en):
            return "Link unavailable"
        case (.phoneUnavailable, .ar):
            return "رقم الهاتف غير متاح"
        case (.phoneUnavailable, .en):
            return "Phone number unavailable"
        case (.copyUnavailable, .ar):
            return "النسخ غير متاح"
        case (.copyUnavailable, .en):
            return "Copy unavailable"
        }
    }

    func localizedRecoverableMessage(_ key: RecoverableMessageCopyKey) -> String {
        switch (key, currentLanguage) {
        case (.timeout, .ar):
            return "استغرق الطلب وقتاً طويلاً. رحلتك الحالية محفوظة ويمكنك إعادة المحاولة."
        case (.timeout, .en):
            return "The request took too long. Your current journey is saved, and you can retry."
        case (.transport, .ar):
            return "تعذر على إرشاد الوصول إلى OpenRouter. رحلتك الحالية محفوظة ويمكنك إعادة المحاولة."
        case (.transport, .en):
            return "Irshad could not reach OpenRouter. Your current journey is saved, and you can retry."
        case (.badStatus, .ar):
            return "تعذر على إرشاد إكمال هذه الخطوة. رحلتك الحالية محفوظة ويمكنك إعادة المحاولة."
        case (.badStatus, .en):
            return "Irshad could not complete this step. Your current journey is saved, and you can retry."
        case (.decoding, .ar):
            return "وصلت استجابة لم يتمكن إرشاد من قراءتها بأمان. يمكنك إعادة هذه الخطوة."
        case (.decoding, .en):
            return "Irshad received a response it could not safely read. You can retry this step."
        case (.noActiveSession, .ar):
            return "ابدأ رحلة قبل المتابعة."
        case (.noActiveSession, .en):
            return "Start a journey before continuing."
        case (.cardUnavailable, .ar):
            return "هذا السؤال لم يعد متاحاً. يمكنك إعادة الخطوة الحالية."
        case (.cardUnavailable, .en):
            return "This question is no longer available. You can retry the current step."
        case (.finalPlanUnavailable, .ar):
            return "نحتاج إلى خطة نهائية قبل استخدام هذا الإجراء."
        case (.finalPlanUnavailable, .en):
            return "A final plan is needed before using this action."
        case (.generic, .ar):
            return "حدث ما أوقف هذه الخطوة. رحلتك الحالية محفوظة ويمكنك إعادة المحاولة."
        case (.generic, .en):
            return "Something stopped this step. Your current journey is saved, and you can retry."
        case (.needsAnotherAnswer, .ar):
            return "يحتاج إرشاد إلى إجابة أخرى قبل إعداد الخطة النهائية."
        case (.needsAnotherAnswer, .en):
            return "Irshad needs one more answer before preparing the final plan."
        case (.unexpectedJourneyUpdate, .ar):
            return "وصل تحديث غير متوقع للرحلة. يمكنك إعادة هذه الخطوة."
        case (.unexpectedJourneyUpdate, .en):
            return "An unexpected journey update arrived. You can retry this step."
        case (.linkUnavailable, .ar):
            return "هذا الرابط غير وارد في نتيجة الرحلة الحالية."
        case (.linkUnavailable, .en):
            return "This link is not part of the current journey result."
        case (.phoneUnavailable, .ar):
            return "هذا الرقم غير وارد في نتيجة الرحلة الحالية."
        case (.phoneUnavailable, .en):
            return "This phone number is not part of the current journey result."
        case (.copyUnavailable, .ar):
            return "نحتاج إلى الخطة النهائية قبل نسخ الملخص."
        case (.copyUnavailable, .en):
            return "A final plan is needed before copying the summary."
        }
    }

    func localizedToast(_ key: ToastCopyKey) -> String {
        switch (key, currentLanguage) {
        case (.correctionSaved, .ar):
            return "تم حفظ التصحيح لهذه الجلسة."
        case (.correctionSaved, .en):
            return "Correction saved for this session."
        case (.preferredBankSaved, .ar):
            return "تم حفظ البنك كخيار مفضل."
        case (.preferredBankSaved, .en):
            return "Bank saved as a preferred option."
        case (.copied, .ar):
            return "تم النسخ."
        case (.copied, .en):
            return "Copied."
        case (.planSummaryCopied, .ar):
            return "تم نسخ ملخص الخطة."
        case (.planSummaryCopied, .en):
            return "Plan summary copied."
        }
    }

    func localizedServiceAction(for operation: PendingOperation?, status: JourneyStatus) -> String {
        switch (operation, status, currentLanguage) {
        case (.startText, _, .ar):
            return "أجهز رحلتك"
        case (.startText, _, .en):
            return "I'm setting up your journey"
        case (.nextCard, _, .ar):
            return "أحفظ إجابتك وأجهز السؤال التالي"
        case (.nextCard, _, .en):
            return "I'm saving your answer"
        case (.analyze, _, .ar):
            return "أطابق نشاط مشروعك"
        case (.analyze, _, .en):
            return "I'm matching your business activity"
        case (.license, _, .ar):
            return "أبحث عن الرخص المناسبة"
        case (.license, _, .en):
            return "I'm looking for suitable licenses"
        case (.banking, _, .ar):
            return "أتحقق من ملاءمة البنوك"
        case (.banking, _, .en):
            return "I'm checking bank fit"
        case (.verify, _, .ar):
            return "أجهز التحقق من الجهة الرسمية"
        case (.verify, _, .en):
            return "I'm preparing authority verification"
        case (.finalPlan, _, .ar):
            return "أجهز خطة الإطلاق"
        case (.finalPlan, _, .en):
            return "I'm preparing your launch plan"
        case (.saveFinalPlan, _, .ar):
            return "أحفظ خطتك"
        case (.saveFinalPlan, _, .en):
            return "I'm saving your plan"
        case (.shareFinalPlan, _, .ar):
            return "أجهز المشاركة"
        case (.shareFinalPlan, _, .en):
            return "I'm preparing your share sheet"
        case (.loadSavedPlan, _, .ar):
            return "أفتح خطتك المحفوظة"
        case (.loadSavedPlan, _, .en):
            return "I'm opening your saved plan"
        case (_, .preparing, .ar):
            return "أجهز رحلتك"
        case (_, .preparing, .en):
            return "I'm setting up your journey"
        case (_, .collecting, .ar):
            return "أجهز السؤال التالي"
        case (_, .collecting, .en):
            return "I'm preparing the next question"
        case (_, _, .ar):
            return "أراجع إجاباتك"
        case (_, _, .en):
            return "I'm reviewing your answers"
        }
    }

    func launchServiceOperation(
        status: JourneyStatus,
        operation: @MainActor @escaping () async throws -> Void
    ) {
        guard !isServiceBusy else {
            return
        }

        debugTrace = nil
        activeTask?.cancel()
        isServiceBusy = true
        recoverableError = nil
        banner = nil
        journeyStatus = status
        serviceActionMessage = localizedServiceAction(for: pendingOperation, status: status)
        DebugLog.api("ViewModel operation begin pending=\(debugPendingOperation(pendingOperation)) status=\(status)")

        activeTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try Task.checkCancellation()
                try await operation()
                try Task.checkCancellation()
                DebugLog.api("ViewModel operation success pending=\(self.debugPendingOperation(self.pendingOperation)) status=\(self.journeyStatus)")
                self.isServiceBusy = false
                self.serviceActionMessage = nil
                self.activeTask = nil
                self.lastUpdatedAt = Date()
                await self.track("journey_operation_success")
            } catch is CancellationError {
                self.isServiceBusy = false
                self.serviceActionMessage = nil
                self.activeTask = nil
                DebugLog.api("ViewModel operation cancelled pending=\(self.debugPendingOperation(self.pendingOperation))")
                await self.track("journey_operation_cancelled")
            } catch APIError.cancelled {
                self.isServiceBusy = false
                self.serviceActionMessage = nil
                self.activeTask = nil
                DebugLog.api("ViewModel operation API-cancelled pending=\(self.debugPendingOperation(self.pendingOperation))")
                await self.track("journey_operation_cancelled")
            } catch {
                self.isServiceBusy = false
                self.serviceActionMessage = nil
                self.activeTask = nil
                self.revealResultErrorSurfaceIfNeeded()
                DebugLog.api("ViewModel operation failed pending=\(self.debugPendingOperation(self.pendingOperation)) status=\(self.journeyStatus) error=\(DebugLog.describe(error))")
                self.debugTrace = self.debugTrace(for: error)
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
        DebugLog.api("ViewModel performStartJourney request session=\(sessionID) language=\(currentLanguage.rawValue) goal=\"\(DebugLog.preview(text))\"")
        let response = try await apiService.startJourney(request)
        try Task.checkCancellation()
        DebugLog.api("ViewModel performStartJourney response session=\(response.session?.sessionId ?? sessionID) stage=\(response.currentStage ?? "nil") phase=\(String(describing: response.currentPhase)) cardId=\(response.card?.cardId ?? "nil")")

        sessionId = response.session?.sessionId ?? sessionID
        let phase = response.currentPhase
            ?? response.card?.phase
            ?? JourneyPhase(serviceValue: response.currentStage)
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
        currentPrompt = firstQuestionPrompt(
            cardTitle: response.card?.title,
            fallback: response.activity ?? response.framing
        )
        currentCard = response.card
        renderableCards = response.card.map { [$0] } ?? []
        unsupportedCard = unsupportedCardIfNeeded(response.card)
        progress = response.progress
        currentPhase = normalizedPhase(phase, fallback: response.card?.phase ?? .goal)
        completedPhases = completedPhases(for: currentPhase)
        journeyStatus = .collecting
        analysisSummary = nil
        licenseRecommendation = nil
        bankingRecommendations = nil
        verificationSummary = nil
        activeResultScreen = .none
        isVerificationDecisionPending = false
        nextStepChecklist = []
        finalPlan = nil
        cardAnswerDraft = .empty
        cardValidationMessage = nil
        inputErrorMessage = nil
        resetInputAfterSuccessfulSubmit()
        pendingOperation = nil
        refreshDerivedState()
        await speakCurrentPrompt()
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
            ?? JourneyPhase(serviceValue: response.currentStage)
        activeSession = session
        progress = response.progress ?? progress

        let phase = response.currentPhase
            ?? response.card?.phase
            ?? JourneyPhase(serviceValue: response.currentStage)
        currentPhase = normalizedPhase(phase, fallback: currentPhase)

        if let completed = response.stageJustCompleted {
            completedPhases.insert(JourneyPhase(serviceValue: completed))
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
            resetInputAfterSuccessfulSubmit()
            refreshDerivedState()
            speakCurrentPromptAfterResponse()
            return false
        case .gateOpen:
            currentCard = nil
            renderableCards = []
            unsupportedCard = nil
            journeyStatus = .gateOpen
            currentPrompt = additionalContextTitle
            currentAssistantMessage = additionalContextMessage
            resetInputAfterSuccessfulSubmit()
            refreshDerivedState()
            pendingOperation = .analyze
            speakCurrentPromptAfterResponse()
            return false
        case .ready:
            if response.card == nil, let progress, progress.filled >= progress.required {
                currentCard = nil
                renderableCards = []
                unsupportedCard = nil
                journeyStatus = .gateOpen
                currentPrompt = additionalContextTitle
                currentAssistantMessage = additionalContextMessage
                resetInputAfterSuccessfulSubmit()
                refreshDerivedState()
                pendingOperation = .analyze
                speakCurrentPromptAfterResponse()
                return false
            } else {
                pendingOperation = .nextCard(cardID: currentCard?.cardId ?? "")
                recoverableError = RecoverableError(
                    id: UUID().uuidString,
                    title: localizedRecoverableTitle(.journeyPaused),
                    message: localizedRecoverableMessage(.needsAnotherAnswer),
                    retryKey: "next"
                )
                journeyStatus = .partial
                return false
            }
        case .unknown:
            recoverableError = RecoverableError(
                id: UUID().uuidString,
                title: localizedRecoverableTitle(.journeyPaused),
                message: localizedRecoverableMessage(.unexpectedJourneyUpdate),
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
            let loadingStart = beginResultLoading(.loadingLicense)
            pendingOperation = .analyze
            serviceActionMessage = localizedServiceAction(for: .analyze, status: .processing)
            currentPhase = .analysis
            let response = try await apiService.analyze(
                AnalyzeRequest(sessionId: session.sessionId, session: session)
            )
            try Task.checkCancellation()
            analysisSummary = response.analysis
            completedPhases.insert(.analysis)
            refreshDerivedState()

            pendingOperation = .license
            serviceActionMessage = localizedServiceAction(for: .license, status: .processing)
            currentPhase = .license
            let licenseResponse = try await apiService.license(SessionOnlyRequest(sessionId: session.sessionId))
            try Task.checkCancellation()
            licenseRecommendation = licenseResponse.license
            completedPhases.insert(.license)
            refreshDerivedState()
            try await finishResultLoading(startedAt: loadingStart)
            activeResultScreen = .license
            currentPhase = .license
            journeyStatus = .showingResults
            pendingOperation = nil
            refreshDerivedState()
            return
        }

        if start == .license {
            let loadingStart = beginResultLoading(.loadingLicense)
            pendingOperation = .license
            serviceActionMessage = localizedServiceAction(for: .license, status: .processing)
            currentPhase = .license
            let response = try await apiService.license(SessionOnlyRequest(sessionId: session.sessionId))
            try Task.checkCancellation()
            licenseRecommendation = response.license
            completedPhases.insert(.license)
            refreshDerivedState()
            try await finishResultLoading(startedAt: loadingStart)
            activeResultScreen = .license
            journeyStatus = .showingResults
            pendingOperation = nil
            refreshDerivedState()
            return
        }

        if start == .banking {
            let loadingStart = beginResultLoading(.loadingBanking)
            pendingOperation = .banking
            serviceActionMessage = localizedServiceAction(for: .banking, status: .processing)
            currentPhase = .banking
            let response = try await apiService.banking(SessionOnlyRequest(sessionId: session.sessionId))
            try Task.checkCancellation()
            bankingRecommendations = response.banking
            completedPhases.insert(.banking)
            refreshDerivedState()
            try await finishResultLoading(startedAt: loadingStart)
            activeResultScreen = .banking
            journeyStatus = .showingResults
            pendingOperation = nil
            refreshDerivedState()
            return
        }

        if start == .verify {
            pendingOperation = .verify
            serviceActionMessage = localizedServiceAction(for: .verify, status: .processing)
            currentPhase = .verify
            let response = try await apiService.verify(
                VerifyRequest(sessionId: session.sessionId, verifyTarget: verifyTarget())
            )
            try Task.checkCancellation()
            verificationSummary = response.verification
            completedPhases.insert(.verify)
            activeResultScreen = .authority
            journeyStatus = .showingResults
            pendingOperation = nil
            refreshDerivedState()
            return
        }

        guard start == .finalPlan else {
            return
        }

        pendingOperation = .finalPlan
        serviceActionMessage = localizedServiceAction(for: .finalPlan, status: .processing)
        currentPhase = .nextSteps
        let response = try await apiService.finalPlan(SessionOnlyRequest(sessionId: session.sessionId))
        try Task.checkCancellation()
        finalPlan = response.plan
        nextStepChecklist = makeChecklist(from: response.plan)
        completedPhases.insert(.nextSteps)
        currentPhase = .plan
        completedPhases.insert(.plan)
        activeResultScreen = .finalPlan
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
            toast = ToastState(id: UUID().uuidString, message: "لم يتم العثور على خطة محفوظة.")
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
        activeResultScreen = .finalPlan
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
            let message = localizedInputError(.voiceUnavailable)
            voiceState = .failed(message)
            transcriptState = .empty
            inputErrorMessage = message
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
            let message = localizedInputError(.voiceUnavailable)
            voiceState = .failed(message)
            inputErrorMessage = message
            isTextEntryExpanded = true
        } catch {
            let message = localizedInputError(.voiceRecognitionFailed)
            voiceState = .failed(message)
            inputErrorMessage = message
            isTextEntryExpanded = true
        }

        speechTask = nil
    }

    func speakCurrentPrompt() async {
        let text = [
            currentPrompt,
            currentAssistantMessage,
            framingMessage
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .first { !$0.isEmpty }

        guard let text else { return }
        await speechSynthesisService.speak(text, language: currentLanguage, voice: selectedVoicePersona)
    }

    func speakCurrentPromptAfterResponse() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.speakCurrentPrompt()
        }
    }

    func beginResultLoading(_ screen: ActiveResultScreen) -> Date {
        activeResultScreen = screen
        journeyStatus = .processing
        let startedAt = Date()
        speakResultLoadingIntro(for: screen)
        return startedAt
    }

    func finishResultLoading(startedAt: Date) async throws {
        let elapsed = Date().timeIntervalSince(startedAt)
        let remaining = max(0, 8.0 - elapsed)
        guard remaining > 0 else { return }
        try await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
    }

    func speakResultLoadingIntro(for screen: ActiveResultScreen) {
        let business = compactBusinessLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasBusiness = !business.isEmpty && business != "Not decided yet" && business != "لم يحدد بعد"

        let text: String
        switch (screen, currentLanguage) {
        case (.loadingLicense, .ar):
            text = hasBusiness
                ? "نبحث عن أفضل رخصة مناسبة لمشروع \(business)."
                : "نبحث عن أفضل رخصة مناسبة لمشروعك."
        case (.loadingLicense, .en):
            text = hasBusiness
                ? "We're finding the best license for your \(business)."
                : "We're finding the best license for your business."
        case (.loadingBanking, .ar):
            text = hasBusiness
                ? "نبحث عن أفضل الخيارات البنكية المناسبة لمشروع \(business)."
                : "نبحث عن أفضل الخيارات البنكية المناسبة لمشروعك."
        case (.loadingBanking, .en):
            text = hasBusiness
                ? "We're finding the best banking options for your \(business)."
                : "We're finding the best banking options for your business."
        default:
            return
        }

        speechTask?.cancel()
        speechTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.speechSynthesisService.speak(text, language: self.currentLanguage, voice: self.selectedVoicePersona)
        }
    }

    func revealResultErrorSurfaceIfNeeded() {
        switch activeResultScreen {
        case .loadingLicense:
            activeResultScreen = .license
        case .loadingBanking:
            activeResultScreen = .banking
        default:
            break
        }
    }
}

private extension JourneyViewModel {
    enum ViewModelError: Error {
        case noActiveSession
        case cardUnavailable
        case invalidAnswer(String)
        case finalPlanUnavailable
    }

    func resetInputAfterSuccessfulSubmit() {
        liveTranscript = ""
        editableTranscript = ""
        transcriptConfidence = nil
        transcriptState = .empty
        textFallbackValue = ""
        inputErrorMessage = nil
        if voiceState == .transcriptReady {
            voiceState = .idle
        }
    }

    func appendAdditionalContext(_ value: String) {
        guard var session = activeSession else {
            return
        }

        let answer = JSONValue.string(value)
        session.filledSlots["additional_context"] = answer
        session.history.append(
            JourneyHistoryItem(
                cardId: "additional-context-\(UUID().uuidString)",
                question: additionalContextTitle,
                answer: answer,
                slot: "additional_context",
                stage: "final_context",
                timestamp: Date()
            )
        )
        activeSession = session
        refreshDerivedState()
        resetInputAfterSuccessfulSubmit()
    }

    func proceedFromAdditionalContext() {
        guard activeSession != nil else {
            handleRecoverableError(ViewModelError.noActiveSession)
            return
        }

        pendingOperation = .analyze
        launchServiceOperation(status: .processing) { [weak self] in
            guard let self else { return }
            try await self.runOutputChain(startingAt: .analyze)
        }
    }

    func applyTranscript(_ value: String, to card: DynamicCard) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ViewModelError.invalidAnswer(localizedInputError(.missingAnswer))
        }

        switch card.type {
        case .text:
            updateCardText(cardID: card.cardId, value: trimmed)
        case .number:
            updateCardNumber(cardID: card.cardId, value: trimmed)
        case .singleSelect:
            if let option = safelyMatchedOption(in: card, transcript: trimmed) {
                selectSingleOption(cardID: card.cardId, optionID: option.id)
            } else if card.allowsCustomInput {
                updateCardText(cardID: card.cardId, value: trimmed)
            } else {
                throw ViewModelError.invalidAnswer(reviewSpeechSelectionMessage())
            }
        case .toggle:
            if let option = safelyMatchedOption(in: card, transcript: trimmed) {
                setToggleAnswer(cardID: card.cardId, value: toggleValue(for: option))
            } else if let bool = boolFromSpeech(trimmed) {
                setToggleAnswer(cardID: card.cardId, value: bool)
            } else if card.allowsCustomInput {
                updateCardText(cardID: card.cardId, value: trimmed)
            } else {
                throw ViewModelError.invalidAnswer(reviewSpeechSelectionMessage())
            }
        case .multiSelect:
            let options = safelyMatchedOptions(in: card, transcript: trimmed)
            if !options.isEmpty {
                cardAnswerDraft = CardAnswerDraft(
                    cardID: card.cardId,
                    value: .multiOptions(selectedIDsRespectingNone(options)),
                    updatedAt: Date()
                )
            } else if card.allowsCustomInput {
                updateCardText(cardID: card.cardId, value: trimmed)
            } else {
                throw ViewModelError.invalidAnswer(reviewSpeechSelectionMessage())
            }
        case .checklist:
            let options = safelyMatchedOptions(in: card, transcript: trimmed)
            if !options.isEmpty {
                cardAnswerDraft = CardAnswerDraft(
                    cardID: card.cardId,
                    value: .checklist(selectedIDsRespectingNone(options)),
                    updatedAt: Date()
                )
            } else if card.allowsCustomInput {
                updateCardText(cardID: card.cardId, value: trimmed)
            } else {
                throw ViewModelError.invalidAnswer(reviewSpeechSelectionMessage())
            }
        case .info, .summary, .recommendation, .roadmap, .none, .unsupported:
            if allowsEmptyAnswer(card) {
                cardAnswerDraft = CardAnswerDraft(cardID: card.cardId, value: .toggle(true), updatedAt: Date())
            } else {
                throw ViewModelError.invalidAnswer(reviewSpeechSelectionMessage())
            }
        }
    }

    func safelyMatchedOption(in card: DynamicCard, transcript: String) -> DynamicCardOption? {
        let matches = safelyMatchedOptions(in: card, transcript: transcript)
        return matches.count == 1 ? matches[0] : nil
    }

    func safelyMatchedOptions(in card: DynamicCard, transcript: String) -> [DynamicCardOption] {
        let normalizedTranscript = normalizedSpeech(transcript)
        guard !normalizedTranscript.isEmpty else {
            return []
        }

        return card.options.filter { option in
            optionCandidates(option).contains { candidate in
                let normalizedCandidate = normalizedSpeech(candidate)
                guard !normalizedCandidate.isEmpty else {
                    return false
                }
                if normalizedCandidate == normalizedTranscript {
                    return true
                }
                if normalizedCandidate.count >= 3, normalizedTranscript.contains(normalizedCandidate) {
                    return true
                }
                return false
            }
        }
    }

    func selectedIDsRespectingNone(_ options: [DynamicCardOption]) -> Set<String> {
        if let noneOption = options.first(where: isNoneOption) {
            return [noneOption.id]
        }
        return Set(options.map(\.id))
    }

    func optionCandidates(_ option: DynamicCardOption) -> [String] {
        [option.label, option.value, option.id].compactMap { $0 }
    }

    func normalizedSpeech(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    func boolFromSpeech(_ value: String) -> Bool? {
        let normalized = normalizedSpeech(value)
        if isAffirmative(normalized) {
            return true
        }
        if isNegative(normalized) {
            return false
        }
        return nil
    }

    func isAffirmative(_ normalized: String) -> Bool {
        ["yes", "y", "true", "ok", "okay", "sure", "نعم", "اي", "أجل"].contains(normalized)
    }

    func isNegative(_ normalized: String) -> Bool {
        ["no", "n", "false", "none", "not", "لا", "كلا", "بدون"].contains(normalized)
            || containsNegativeCue(normalized)
    }

    func containsNegativeCue(_ normalized: String) -> Bool {
        let tokens = Set(normalized.split(separator: " ").map(String.init))
        return !tokens.intersection(["no", "not", "none", "without", "false", "لا", "كلا", "بدون"]).isEmpty
    }

    func isNoneOption(_ option: DynamicCardOption) -> Bool {
        optionCandidates(option).map(normalizedSpeech).contains {
            ["none", "no", "not applicable", "na", "n a", "لا", "بدون"].contains($0)
        }
    }

    func toggleValue(for option: DynamicCardOption) -> Bool {
        let normalizedCandidates = optionCandidates(option).map(normalizedSpeech)
        if normalizedCandidates.contains(where: isAffirmative) {
            return true
        }
        if normalizedCandidates.contains(where: containsNegativeCue) {
            return false
        }
        return true
    }

    func reviewSpeechSelectionMessage() -> String {
        switch currentLanguage {
        case .ar:
            return "راجع النص أو اختر إجابة من الخيارات قبل الإرسال."
        case .en:
            return "Review the transcript or choose one of the options before sending."
        }
    }

    func answerJSON(for card: DynamicCard) throws -> JSONValue {
        guard cardAnswerDraft.cardID == card.cardId else {
            if allowsEmptyAnswer(card) {
                return .bool(true)
            }
            throw ViewModelError.invalidAnswer("اختر أو اكتب إجابة قبل المتابعة.")
        }

        switch cardAnswerDraft.value {
        case .empty:
            if allowsEmptyAnswer(card) {
                return .bool(true)
            }
            throw ViewModelError.invalidAnswer("اختر أو اكتب إجابة قبل المتابعة.")
        case .singleOption(let optionID):
            guard let option = card.options.first(where: { $0.id == optionID }) else {
                throw ViewModelError.invalidAnswer("اختر خياراً متاحاً.")
            }
            return .string(option.value ?? option.label)
        case .multiOptions(let optionIDs):
            let values = card.options
                .filter { optionIDs.contains($0.id) }
                .map { JSONValue.string($0.value ?? $0.label) }
            guard !values.isEmpty else {
                throw ViewModelError.invalidAnswer("اختر خياراً واحداً على الأقل.")
            }
            return .array(values)
        case .text(let value):
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw ViewModelError.invalidAnswer("اكتب إجابة قبل المتابعة.")
            }
            return .string(trimmed)
        case .numberString(let value):
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw ViewModelError.invalidAnswer("أضف رقماً قبل المتابعة.")
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
                throw ViewModelError.invalidAnswer("اختر عنصراً واحداً على الأقل.")
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
        DebugLog.api("ViewModel recoverableError from \(DebugLog.describe(error)) pending=\(debugPendingOperation(pendingOperation))")
        debugTrace = debugTrace(for: error)

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
            title: localizedRecoverableTitle(.retryNeeded),
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

    func debugTrace(for error: Error) -> String? {
        if let debugError = error as? DebuggableAPIError {
            return debugError.debugTrace
        }

        return nil
    }

    func debugPendingOperation(_ operation: PendingOperation?) -> String {
        switch operation {
        case .startText(let text):
            return "startText(\"\(DebugLog.preview(text, limit: 300))\")"
        case .nextCard(let cardID):
            return "nextCard(cardID: \(cardID))"
        case .analyze:
            return "analyze"
        case .verify:
            return "verify"
        case .license:
            return "license"
        case .banking:
            return "banking"
        case .finalPlan:
            return "finalPlan"
        case .loadSavedPlan:
            return "loadSavedPlan"
        case .saveFinalPlan:
            return "saveFinalPlan"
        case .shareFinalPlan:
            return "shareFinalPlan"
        case .none:
            return "nil"
        }
    }

    func userSafeMessage(for error: Error) -> String {
        if let debugError = error as? DebuggableAPIError {
            return userSafeMessage(for: debugError.underlying)
        }

        switch error {
        case APIError.timeout:
            return localizedRecoverableMessage(.timeout)
        case APIError.transport:
            return localizedRecoverableMessage(.transport)
        case APIError.badStatus:
            return localizedRecoverableMessage(.badStatus)
        case APIError.decoding:
            return localizedRecoverableMessage(.decoding)
        case ViewModelError.noActiveSession:
            return localizedRecoverableMessage(.noActiveSession)
        case ViewModelError.cardUnavailable:
            return localizedRecoverableMessage(.cardUnavailable)
        case ViewModelError.finalPlanUnavailable:
            return localizedRecoverableMessage(.finalPlanUnavailable)
        default:
            return localizedRecoverableMessage(.generic)
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
            let label = object["label"]?.displayString.nonEmptyValue
                .map(DisplayLabelFormatter.humanizeIfMachineLabel) ?? labelize(id)
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
    func isKnownTrustedURL(_ url: URL) -> Bool {
        knownTrustedURLs().contains(normalizedURLString(url))
    }

    func isKnownTrustedPhoneNumber(_ phoneNumber: String) -> Bool {
        let normalized = normalizedPhone(phoneNumber)
        guard !normalized.isEmpty else {
            return false
        }

        return knownTrustedPhoneNumbers().contains(normalized)
    }

    func knownTrustedURLs() -> Set<String> {
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
        licenseRecommendation?.best.map { collectURLs(from: $0.metadata, into: &urls) }
        licenseRecommendation?.alternatives.compactMap { $0.source }.compactMap(URL.init(string:)).forEach {
            urls.insert(normalizedURLString($0))
        }
        licenseRecommendation?.alternatives.forEach { collectURLs(from: $0.metadata, into: &urls) }
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

    func knownTrustedPhoneNumbers() -> Set<String> {
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
            if let url = URL(string: string), journeyRouter.canOpenTrustedURL(url) {
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
        DisplayLabelFormatter.humanizeKey(key)
    }

    func firstQuestionPrompt(cardTitle: String?, fallback: String?) -> String? {
        if let title = cardTitle?.nonEmptyValue {
            return "\(firstQuestionIntroMessage) \(title)"
        }

        return fallback?.nonEmptyValue
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
