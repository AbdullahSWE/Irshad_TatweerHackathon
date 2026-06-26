import Foundation

enum JourneyEndpoint: String, CaseIterable, Sendable {
    case start = "/api/journey/start"
    case next = "/api/journey/next"
    case analyze = "/api/analyze"
    case verify = "/api/verify"
    case license = "/api/license"
    case banking = "/api/banking"
    case finalPlan = "/api/plan/final"
}

protocol JourneyAPIServiceProtocol: Sendable {
    func startJourney(_ request: StartJourneyRequest) async throws -> StartJourneyResponse
    func nextJourneyStep(_ request: NextJourneyRequest) async throws -> NextJourneyResponse
    func analyze(_ request: AnalyzeRequest) async throws -> AnalyzeResponse
    func verify(_ request: VerifyRequest) async throws -> VerifyResponse
    func license(_ request: SessionOnlyRequest) async throws -> LicenseResponse
    func banking(_ request: SessionOnlyRequest) async throws -> BankingResponse
    func finalPlan(_ request: SessionOnlyRequest) async throws -> FinalPlanResponse
}

final class JourneyAPIService: JourneyAPIServiceProtocol, @unchecked Sendable {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder(), encoder: JSONEncoder = JSONEncoder()) {
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
    }

    func url(for path: String) throws -> URL {
        fatalError("TODO")
    }

    func startJourney(_ request: StartJourneyRequest) async throws -> StartJourneyResponse {
        fatalError("TODO")
    }

    func nextJourneyStep(_ request: NextJourneyRequest) async throws -> NextJourneyResponse {
        fatalError("TODO")
    }

    func analyze(_ request: AnalyzeRequest) async throws -> AnalyzeResponse {
        fatalError("TODO")
    }

    func verify(_ request: VerifyRequest) async throws -> VerifyResponse {
        fatalError("TODO")
    }

    func license(_ request: SessionOnlyRequest) async throws -> LicenseResponse {
        fatalError("TODO")
    }

    func banking(_ request: SessionOnlyRequest) async throws -> BankingResponse {
        fatalError("TODO")
    }

    func finalPlan(_ request: SessionOnlyRequest) async throws -> FinalPlanResponse {
        fatalError("TODO")
    }
}
