import Foundation

actor LocalJourneyAPIService: JourneyAPIServiceProtocol {
    fileprivate struct StoredSession {
        var archetypeId: String
        var goalText: String
        var language: AppLanguage
        var filledSlots: [String: JSONValue]
        var analysis: AnalysisSummary?
        var verification: VerificationSummary?
        var license: LicenseRecommendation?
        var banking: BankingRecommendations?
    }

    private enum Stage {
        static let path = ["business", "founder", "details", "budget", "documents"]
        static let maxQuestions = 8
        static let coreSlots = ["activity", "residency", "location", "capital"]
    }

    private let kb: LocalKnowledgeBase
    private let llm: OpenRouterClient
    private var sessions: [String: StoredSession] = [:]

    init(
        kb: LocalKnowledgeBase = .shared,
        llm: OpenRouterClient = OpenRouterClient()
    ) {
        self.kb = kb
        self.llm = llm
    }

    func startJourney(_ request: StartJourneyRequest) async throws -> StartJourneyResponse {
        let goalText = request.goalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !goalText.isEmpty else {
            throw APIError.badStatus(400, "goalText is required")
        }

        DebugLog.api("Journey startJourney session=\(request.sessionId) language=\(request.language.rawValue) goal=\"\(DebugLog.preview(goalText))\"")

        let classified: ClassificationDTO
        do {
            classified = try await classifyGoal(goalText: goalText, language: request.language)
            DebugLog.api("Journey startJourney.classifyGoal success session=\(request.sessionId) archetypeId=\(classified.archetypeId) archetypeLabel=\"\(classified.archetypeLabel)\"")
        } catch {
            DebugLog.api("Journey startJourney.classifyGoal failed session=\(request.sessionId): \(DebugLog.describe(error))")
            throw error
        }

        guard kb.archetype(id: classified.archetypeId) != nil else {
            DebugLog.api("Journey startJourney unknown archetype session=\(request.sessionId) archetypeId=\(classified.archetypeId)")
            throw APIError.decoding("OpenRouter returned an unknown archetypeId: \(classified.archetypeId)")
        }

        var filledSlots: [String: JSONValue] = [
            "activity": .string(classified.archetypeLabel),
            "language": .string(request.language.rawValue)
        ]

        let session = JourneySession(
            sessionId: request.sessionId,
            goalText: goalText,
            currentStage: "business",
            currentPhase: .business,
            filledSlots: filledSlots,
            history: []
        )

        let missing = computeMissing(archetypeId: classified.archetypeId, stage: "business", filledSlots: filledSlots)
        let slotToAsk = missing.first ?? "businessStage"
        DebugLog.api("Journey startJourney.generateCard begin session=\(request.sessionId) stage=business slot=\(slotToAsk) missing=\(missing)")
        let card: DynamicCard
        do {
            card = try await generateCard(
                slot: slotToAsk,
                archetypeId: classified.archetypeId,
                archetypeLabel: classified.archetypeLabel,
                stage: "business",
                filledSlots: filledSlots,
                history: [],
                language: request.language
            )
            DebugLog.api("Journey startJourney.generateCard success session=\(request.sessionId) cardId=\(card.cardId) type=\(card.type) title=\"\(DebugLog.preview(card.title, limit: 300))\"")
        } catch {
            DebugLog.api("Journey startJourney.generateCard failed session=\(request.sessionId) stage=business slot=\(slotToAsk): \(DebugLog.describe(error))")
            throw error
        }

        filledSlots = session.filledSlots
        sessions[request.sessionId] = StoredSession(
            archetypeId: classified.archetypeId,
            goalText: goalText,
            language: request.language,
            filledSlots: filledSlots,
            analysis: nil,
            verification: nil,
            license: nil,
            banking: nil
        )

        return StartJourneyResponse(
            session: session,
            framing: classified.framing,
            activity: classified.archetypeLabel,
            card: card,
            progress: computeProgress(session: session, archetypeId: classified.archetypeId),
            currentStage: "business",
            currentPhase: .business
        )
    }

    func nextJourneyStep(_ request: NextJourneyRequest) async throws -> NextJourneyResponse {
        guard var stored = sessions[request.sessionId] else {
            throw APIError.badStatus(404, "Session not found - start a journey first")
        }

        var session = request.session
        syncFilledSlotsFromHistory(&session)
        stored.filledSlots = session.filledSlots
        sessions[request.sessionId] = stored

        if session.history.count >= Stage.maxQuestions {
            return NextJourneyResponse(
                status: .gateOpen,
                session: session,
                currentStage: session.currentStage,
                currentPhase: JourneyPhase(serviceValue: session.currentStage),
                stageJustCompleted: nil,
                progress: computeProgress(session: session, archetypeId: stored.archetypeId),
                card: nil
            )
        }

        var currentStage = normalizedStage(session.currentStage)
        var stageJustCompleted: String?

        while true {
            let missing = computeMissing(archetypeId: stored.archetypeId, stage: currentStage, filledSlots: session.filledSlots)
            if !missing.isEmpty {
                break
            }

            guard let next = advanceStage(currentStage) else {
                session.currentStage = currentStage
                session.currentPhase = JourneyPhase(serviceValue: currentStage)
                return NextJourneyResponse(
                    status: .gateOpen,
                    session: session,
                    currentStage: currentStage,
                    currentPhase: JourneyPhase(serviceValue: currentStage),
                    stageJustCompleted: stageJustCompleted,
                    progress: computeProgress(session: session, archetypeId: stored.archetypeId),
                    card: nil
                )
            }

            stageJustCompleted = currentStage
            currentStage = next
            session.currentStage = next
            session.currentPhase = JourneyPhase(serviceValue: next)
        }

        let stillMissing = computeMissing(archetypeId: stored.archetypeId, stage: currentStage, filledSlots: session.filledSlots)
        let slotToAsk = coreFilled(session.filledSlots)
            ? stillMissing.first
            : stillMissing.first { Stage.coreSlots.contains($0) } ?? stillMissing.first

        guard let slotToAsk else {
            return NextJourneyResponse(
                status: .gateOpen,
                session: session,
                currentStage: currentStage,
                currentPhase: JourneyPhase(serviceValue: currentStage),
                stageJustCompleted: stageJustCompleted,
                progress: computeProgress(session: session, archetypeId: stored.archetypeId),
                card: nil
            )
        }

        guard let archetype = kb.archetype(id: stored.archetypeId) else {
            throw APIError.badStatus(400, "Unknown archetypeId in session")
        }

        let card = try await generateCard(
            slot: slotToAsk,
            archetypeId: stored.archetypeId,
            archetypeLabel: archetype.label,
            stage: currentStage,
            filledSlots: session.filledSlots,
            history: session.history,
            language: stored.language
        )

        return NextJourneyResponse(
            status: .collecting,
            session: session,
            currentStage: currentStage,
            currentPhase: JourneyPhase(serviceValue: currentStage),
            stageJustCompleted: stageJustCompleted,
            progress: computeProgress(session: session, archetypeId: stored.archetypeId),
            card: card
        )
    }

    func analyze(_ request: AnalyzeRequest) async throws -> AnalyzeResponse {
        guard var stored = sessions[request.sessionId] else {
            throw APIError.badStatus(404, "Session not found - start a journey first")
        }

        stored.filledSlots = request.session.filledSlots
        let result = try await runAnalysis(session: request.session, stored: stored)
        stored.analysis = result
        sessions[request.sessionId] = stored
        return AnalyzeResponse(analysis: result, nextStage: "license")
    }

    func verify(_ request: VerifyRequest) async throws -> VerifyResponse {
        guard var stored = sessions[request.sessionId] else {
            throw APIError.badStatus(404, "Session not found - run analysis first")
        }

        let candidateLicenses = stored.analysis?.candidateLicenses ?? []
        let target = request.verifyTarget.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "\(candidateLicenses.first ?? "business license") fee and requirements 2025 Abu Dhabi"
            : request.verifyTarget

        let result = try await runVerify(
            verifyTarget: target,
            archetypeId: stored.archetypeId,
            candidateLicenses: candidateLicenses,
            language: stored.language
        )
        stored.verification = result
        sessions[request.sessionId] = stored
        return VerifyResponse(verification: result, nextStage: "plan")
    }

    func license(_ request: SessionOnlyRequest) async throws -> LicenseResponse {
        guard var stored = sessions[request.sessionId] else {
            throw APIError.badStatus(404, "Session not found - run analysis first")
        }

        let verification = stored.verification ?? verificationFallback(stored: stored)
        let result = try await runLicenseRec(stored: stored, verification: verification)
        stored.license = result
        sessions[request.sessionId] = stored
        return LicenseResponse(license: result, nextStage: "banking")
    }

    func banking(_ request: SessionOnlyRequest) async throws -> BankingResponse {
        guard var stored = sessions[request.sessionId] else {
            throw APIError.badStatus(404, "Session not found - run analysis first")
        }

        let result = try await runBankingRec(stored: stored)
        stored.banking = result
        sessions[request.sessionId] = stored
        return BankingResponse(banking: result, nextStage: "verify")
    }

    func finalPlan(_ request: SessionOnlyRequest) async throws -> FinalPlanResponse {
        guard let stored = sessions[request.sessionId] else {
            throw APIError.badStatus(404, "Session not found - run prior stages first")
        }
        guard let analysis = stored.analysis,
              let license = stored.license,
              let banking = stored.banking else {
            throw APIError.badStatus(400, "Missing prior results - complete analyze, license, and banking first")
        }

        let plan = try await runPlan(
            stored: stored,
            analysis: analysis,
            verification: stored.verification ?? verificationFallback(stored: stored),
            license: license,
            banking: banking
        )
        return FinalPlanResponse(plan: plan)
    }
}

private extension LocalJourneyAPIService {
    struct ClassificationDTO: Decodable {
        let archetypeId: String
        let archetypeLabel: String
        let framing: String
    }

    struct AnalysisDTO: Decodable {
        let matchedActivities: [MatchedActivityDTO]
        let estSetupCostRange: String?
        let candidateLicenses: [String]
        let confidence: Double?
        let unverified: [String]
    }

    struct MatchedActivityDTO: Decodable {
        let id: String
        let label: String
    }

    struct VerifyDTO: Decodable {
        let status: String
        let info: String?
        let verifiedFacts: [String: JSONValue]?
        let sources: [String]?
    }

    struct LicenseDTO: Decodable {
        let best: LicenseOptionDTO?
        let alternatives: [LicenseOptionDTO]?
    }

    struct LicenseOptionDTO: Decodable {
        let type: String
        let issuer: String?
        let pros: [String]?
        let cons: [String]?
        let timeline: String?
        let approvals: [String]?
        let estCost: String?
        let costStatus: String?
        let source: String?
    }

    struct BankingDTO: Decodable {
        let banks: [BankDTO]
    }

    struct BankDTO: Decodable {
        let name: String
        let minBalance: String?
        let requirements: [String]?
        let docsNeeded: [String]?
        let likelyToApprove: Bool?
        let source: String?
    }

    struct PlanDTO: Decodable {
        let roadmap: [String]
        let totalEstCost: String?
        let totalTimeline: String?
        let nextAction: String?
        let confidence: Double?
        let unverified: [String]
    }

    func classifyGoal(goalText: String, language: AppLanguage) async throws -> ClassificationDTO {
        try await llm.json(
            system: "You are a business activity classifier for Abu Dhabi entrepreneurs. Return only valid JSON.",
            user: """
            Classify this founder's goal to the best matching archetype.

            Archetypes:
            \(kb.archetypeList())

            Founder goal: "\(goalText)"

            Return JSON:
            {
              "archetypeId": "<exact id from list>",
              "archetypeLabel": "<exact label from list>",
              "framing": "Got it - a [friendly 1-line description of what they want to build]."
            }
            """,
            language: language,
            debugLabel: "startJourney.classifyGoal",
            as: ClassificationDTO.self
        )
    }

    func generateCard(
        slot: String,
        archetypeId: String,
        archetypeLabel: String,
        stage: String,
        filledSlots: [String: JSONValue],
        history: [JourneyHistoryItem],
        language: AppLanguage
    ) async throws -> DynamicCard {
        let known = profileSummary(filledSlots).isEmpty ? "nothing yet" : profileSummary(filledSlots)
        let asked = history.compactMap(\.slot).joined(separator: ", ")
        return try await llm.json(
            system: "You generate question cards for a business setup journey in Abu Dhabi. Return only valid JSON.",
            user: """
            Activity: \(archetypeLabel)
            Stage: \(stage)
            Slot to fill: \(slot)
            What we know: \(known)
            Already asked: \(asked.isEmpty ? "none" : asked)

            Generate ONE question card for slot "\(slot)", phrased for a "\(archetypeLabel)" business.

            Return JSON:
            {
              "cardId": "q_\(slot)",
              "kind": "question",
              "type": "<single_select|multi_select|text|toggle>",
              "title": "<concise question, max 12 words>",
              "subtitle": "<optional hint>",
              "options": ["<opt1>", "<opt2>"],
              "slot": "\(slot)",
              "stage": "\(stage)"
            }

            Rules:
            - text: free-form (names, descriptions)
            - single_select: one-of-many or yes/no (2-4 options)
            - multi_select: multiple OK (docs, assets) - include "None" as last option
            - toggle: binary on/off
            - Omit options for text type
            - Keep title conversational and specific to \(archetypeLabel)
            """,
            language: language,
            debugLabel: "generateCard.\(stage).\(slot)",
            as: DynamicCard.self
        )
    }

    func runAnalysis(session: JourneySession, stored: StoredSession) async throws -> AnalysisSummary {
        let dto = try await llm.json(
            system: "You are a business setup advisor for Abu Dhabi. Use only provided KB data - do NOT invent fees. Return only valid JSON.",
            user: """
            Analyze this founder's profile.

            Activity: \(stored.archetypeId)
            Goal: \(stored.goalText)

            Profile:
            \(profileSummary(session.filledSlots))

            ## KB licenses for this activity
            \(kb.formatLicensesForLLM(archetypeId: stored.archetypeId))

            Return JSON:
            {
              "matchedActivities": [{ "id": "<archetypeId>", "label": "<friendly label>" }],
              "estSetupCostRange": "AED X - Y",
              "candidateLicenses": ["<license type name>"],
              "confidence": <0.0-1.0>,
              "unverified": ["<uncertain items>"]
            }

            Confidence guide: 0.9 = all slots filled + KB match; 0.6 = partial profile; 0.4 = many gaps.
            """,
            language: stored.language,
            debugLabel: "runAnalysis",
            as: AnalysisDTO.self
        )

        return AnalysisSummary(
            matchedActivities: dto.matchedActivities.map {
                MatchedActivity(id: $0.id, label: $0.label, metadata: [:])
            },
            estSetupCostRange: dto.estSetupCostRange,
            candidateLicenses: dto.candidateLicenses,
            confidence: dto.confidence,
            unverified: dto.unverified,
            metadata: [:]
        )
    }

    func runVerify(
        verifyTarget: String,
        archetypeId: String,
        candidateLicenses: [String],
        language: AppLanguage
    ) async throws -> VerificationSummary {
        let authority = kb.authorityForFirstLicense(archetypeId: archetypeId)

        do {
            let dto = try await llm.json(
                system: "You are verifying Abu Dhabi business license requirements from your training knowledge. Be conservative - only report facts you are highly confident about. Return only valid JSON.",
                user: """
                Verify current requirements for: "\(verifyTarget)"

                Candidate licenses: \(candidateLicenses.joined(separator: ", "))
                Authority: \(authority?.name ?? "ADDED / DCT Abu Dhabi")

                From your knowledge of Abu Dhabi business regulations, report what you know about:
                - License fee in AED
                - Required approvals and documents
                - Processing timeline
                - Issuing authority

                If you are highly confident (>80%) in the information, return:
                {
                  "status": "verified",
                  "info": "<1-2 sentence summary>",
                  "verifiedFacts": {
                    "licenseFee": "AED ...",
                    "approvals": "<list>",
                    "timeline": "..."
                  },
                  "sources": ["knowledge base"]
                }

                If you are not confident or the information may be outdated, return:
                {
                  "status": "not_found",
                  "confidence": <0.0-1.0>
                }
                """,
                language: language,
                debugLabel: "runVerify",
                as: VerifyDTO.self
            )

            if dto.status == "verified" {
                return VerificationSummary(
                    status: .verified,
                    info: dto.info,
                    verifiedFacts: dto.verifiedFacts ?? [:],
                    sources: dto.sources ?? [authority?.contactURL].compactMap { $0 },
                    authority: authority?.name,
                    phone: authority?.phone,
                    contactURL: authority.flatMap { URL(string: $0.contactURL) },
                    whatToConfirm: verifyTarget,
                    message: nil,
                    metadata: [:]
                )
            }
        } catch APIError.cancelled {
            throw APIError.cancelled
        } catch {
            return verificationFallback(authority: authority, target: verifyTarget, language: language)
        }

        return verificationFallback(authority: authority, target: verifyTarget, language: language)
    }

    func runLicenseRec(stored: StoredSession, verification: VerificationSummary) async throws -> LicenseRecommendation {
        let verifiedInfo: String
        switch verification.status {
        case .verified:
            verifiedInfo = """
            Confirmed facts:
            - Fee: \(verification.verifiedFacts["licenseFee"]?.displayString ?? "see KB")
            - Approvals: \(verification.verifiedFacts["approvals"]?.displayString ?? "see KB")
            - Timeline: \(verification.verifiedFacts["timeline"]?.displayString ?? "see KB")
            - Sources: \(verification.sources.joined(separator: ", "))
            """
        default:
            verifiedInfo = "Not confirmed online. Founder must call \(verification.authority ?? "the relevant authority") (\(verification.phone ?? verification.contactURL?.absoluteString ?? "see contact URL")) to verify: \(verification.whatToConfirm ?? "license fee and requirements")"
        }

        let dto = try await llm.json(
            system: "You recommend business licenses for Abu Dhabi founders. Use KB data. Return only valid JSON.",
            user: """
            Activity: \(stored.archetypeId)
            Goal: \(stored.goalText)
            Profile: \(profileSummary(stored.filledSlots))

            ## KB licenses for this activity
            \(kb.formatLicensesForLLM(archetypeId: stored.archetypeId))

            ## Verification result
            \(verifiedInfo)

            Pick the BEST license and 1-2 alternatives.
            Set costStatus to "verified" if cost was web-confirmed, else "not_verified_confirm_by_phone".

            Return JSON:
            {
              "best": {
                "type": "...", "issuer": "...", "pros": ["..."], "cons": ["..."],
                "timeline": "...", "approvals": ["..."], "estCost": "AED ...",
                "costStatus": "verified"|"not_verified_confirm_by_phone", "source": "..."
              },
              "alternatives": [{ same fields }]
            }
            """,
            language: stored.language,
            debugLabel: "runLicenseRec",
            as: LicenseDTO.self
        )

        return LicenseRecommendation(
            best: dto.best.map { makeLicenseOption($0, archetypeId: stored.archetypeId) },
            alternatives: (dto.alternatives ?? []).map { makeLicenseOption($0, archetypeId: stored.archetypeId) },
            metadata: [:]
        )
    }

    func runBankingRec(stored: StoredSession) async throws -> BankingRecommendations {
        let dto = try await llm.json(
            system: "You recommend bank accounts for Abu Dhabi small business founders. Return only valid JSON.",
            user: """
            Profile: \(profileSummary(stored.filledSlots))
            Activity: \(stored.archetypeId)

            ## Available banks
            \(kb.formatBanksForLLM(archetypeId: stored.archetypeId))

            Rank by likelihood of approval. Set likelyToApprove: true if capital meets minimum balance AND profile is straightforward.

            Return JSON:
            {
              "banks": [{
                "name": "...", "minBalance": "...", "requirements": ["..."],
                "docsNeeded": ["..."], "likelyToApprove": true|false, "source": "..."
              }]
            }

            Order: most likely to approve first.
            """,
            language: stored.language,
            debugLabel: "runBankingRec",
            as: BankingDTO.self
        )

        return BankingRecommendations(
            banks: dto.banks.map {
                BankRecommendation(
                    id: Self.normalizedID($0.name),
                    name: $0.name,
                    minBalance: $0.minBalance,
                    requirements: $0.requirements ?? [],
                    docsNeeded: $0.docsNeeded ?? [],
                    likelyToApprove: $0.likelyToApprove,
                    source: $0.source,
                    metadata: [:]
                )
            },
            metadata: [:]
        )
    }

    func runPlan(
        stored: StoredSession,
        analysis: AnalysisSummary,
        verification: VerificationSummary,
        license: LicenseRecommendation,
        banking: BankingRecommendations
    ) async throws -> FinalPlan {
        let bestBank = banking.banks.first { $0.likelyToApprove == true } ?? banking.banks.first
        let dto = try await llm.json(
            system: "You create business launch roadmaps for Abu Dhabi founders. Concrete, ordered steps. Return only valid JSON.",
            user: """
            Goal: \(stored.goalText)
            Activity: \(stored.archetypeId)
            Best license: \(license.best?.type ?? "TBD") - \(license.best?.estCost ?? "TBD"), \(license.best?.timeline ?? "TBD")
            Best bank: \(bestBank?.name ?? "TBD")
            Verify: \(verification.status == .verified ? "facts confirmed" : "not verified - founder to call authority")
            Confidence: \(analysis.confidence ?? 0.0)
            Unverified: \(analysis.unverified.isEmpty ? "none" : analysis.unverified.joined(separator: ", "))

            Create 4-7 step roadmap. Steps must be concrete and ordered. nextAction = first thing they can do today.
            Include licensing, documents, bank appointment/opening, authority confirmation if unverified, and launch preparation.
            Keep recommendations limited to licences, bank accounts, authority contacts, documents, and launch steps.

            Return JSON:
            {
              "roadmap": ["Step 1: ...", "Step 2: ..."],
              "totalEstCost": "AED X - Y",
              "totalTimeline": "X-Y weeks",
              "nextAction": "<one clear action they can take today>",
              "confidence": <from analysis>,
              "unverified": ["..."]
            }
            """,
            language: stored.language,
            debugLabel: "runPlan",
            as: PlanDTO.self
        )

        return FinalPlan(
            roadmap: dto.roadmap,
            totalEstCost: dto.totalEstCost,
            totalTimeline: dto.totalTimeline,
            nextAction: dto.nextAction,
            confidence: dto.confidence,
            unverified: dto.unverified,
            metadata: [:]
        )
    }

    func makeLicenseOption(_ dto: LicenseOptionDTO, archetypeId: String) -> LicenseOption {
        let kbLicense = kb.licenses(for: archetypeId).first {
            Self.normalizedID($0.type) == Self.normalizedID(dto.type)
                || $0.type.localizedCaseInsensitiveContains(dto.type)
                || dto.type.localizedCaseInsensitiveContains($0.type)
        }
        let authority = kbLicense.flatMap { kb.authority(id: $0.authorityId) }
        var metadata: [String: JSONValue] = [:]
        if let authority {
            metadata["authority"] = .string(authority.name)
            if let phone = authority.phone, !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                metadata["phone"] = .string(phone)
            }
            if !authority.contactURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                metadata["url"] = .string(authority.contactURL)
            }
        }

        return LicenseOption(
            id: Self.normalizedID(dto.type),
            type: dto.type,
            issuer: dto.issuer,
            pros: dto.pros ?? [],
            cons: dto.cons ?? [],
            timeline: dto.timeline,
            approvals: dto.approvals ?? [],
            estCost: dto.estCost,
            costStatus: dto.costStatus == "verified" ? .verified : .unverified,
            source: dto.source ?? kbLicense?.source,
            metadata: metadata
        )
    }
}

private extension LocalJourneyAPIService {
    func normalizedStage(_ value: String?) -> String {
        guard let value, Stage.path.contains(value) else {
            return "business"
        }
        return value
    }

    func advanceStage(_ current: String) -> String? {
        guard let index = Stage.path.firstIndex(of: current), index < Stage.path.count - 1 else {
            return nil
        }
        return Stage.path[index + 1]
    }

    func computeMissing(archetypeId: String, stage: String, filledSlots: [String: JSONValue]) -> [String] {
        kb.stageSlots(stage).filter { slot in
            guard let value = filledSlots[slot] else {
                return true
            }
            return !isFilled(value)
        }
    }

    func coreFilled(_ filledSlots: [String: JSONValue]) -> Bool {
        Stage.coreSlots.allSatisfy { slot in
            filledSlots[slot].map(isFilled) ?? false
        }
    }

    func computeProgress(session: JourneySession, archetypeId: String) -> JourneyProgress {
        var required: [String] = []
        var filled: [String] = []

        for stage in Stage.path {
            let slots = kb.stageSlots(stage)
            required.append(contentsOf: slots)
            for slot in slots where session.filledSlots[slot].map(isFilled) ?? false {
                filled.append(slot)
            }
        }

        let currentIndex = Stage.path.firstIndex(of: normalizedStage(session.currentStage)) ?? 0
        let stagesDone = Stage.path.prefix(currentIndex).filter {
            computeMissing(archetypeId: archetypeId, stage: $0, filledSlots: session.filledSlots).isEmpty
        }
        .count

        return JourneyProgress(
            filled: filled.count,
            required: required.count,
            stagesDone: stagesDone,
            stagesTotal: Stage.path.count
        )
    }

    func syncFilledSlotsFromHistory(_ session: inout JourneySession) {
        guard let last = session.history.last,
              let slot = last.slot,
              session.filledSlots[slot] == nil else {
            return
        }
        session.filledSlots[slot] = last.answer
    }

    func isFilled(_ value: JSONValue) -> Bool {
        switch value {
        case .string(let string):
            return !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .array(let array):
            return !array.isEmpty
        case .null:
            return false
        case .number, .bool, .object:
            return true
        }
    }

    func profileSummary(_ filledSlots: [String: JSONValue]) -> String {
        filledSlots
            .filter { isFilled($0.value) }
            .sorted { $0.key < $1.key }
            .map { "\($0.key): \($0.value.displayString)" }
            .joined(separator: "\n")
    }

    func verificationFallback(stored: StoredSession) -> VerificationSummary {
        verificationFallback(
            authority: kb.authorityForFirstLicense(archetypeId: stored.archetypeId),
            target: "license fee and requirements",
            language: stored.language
        )
    }

    func verificationFallback(authority: AuthorityEntry?, target: String, language: AppLanguage) -> VerificationSummary {
        VerificationSummary(
            status: .notFound,
            info: nil,
            verifiedFacts: [:],
            sources: [],
            authority: authority?.name ?? "ADDED",
            phone: authority?.phone,
            contactURL: authority.flatMap { URL(string: $0.contactURL) },
            whatToConfirm: target,
            message: language == .ar
                ? "لم يتم التحقق إلكترونياً. يرجى التواصل مع \(authority?.name ?? "الجهة المختصة") للتأكد من المتطلبات."
                : "Could not verify online. Contact \(authority?.name ?? "the relevant authority") to confirm exact requirements.",
            metadata: [:]
        )
    }

    static func normalizedID(_ value: String) -> String {
        let pieces = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        return pieces.isEmpty ? UUID().uuidString : pieces.joined(separator: "-")
    }
}
