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
    private let requestTimeout: TimeInterval

    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        requestTimeout: TimeInterval = 30
    ) {
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
        self.requestTimeout = requestTimeout
    }

    func url(for path: String) throws -> URL {
        let normalizedPath = "/\(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))"
        guard JourneyEndpoint.allCases.contains(where: { $0.rawValue == normalizedPath }) else {
            throw APIError.invalidURL(path)
        }

        return try AppConfig.baseURL.appendingEndpointPath(normalizedPath)
    }

    func startJourney(_ request: StartJourneyRequest) async throws -> StartJourneyResponse {
        try await post(request, to: .start)
    }

    func nextJourneyStep(_ request: NextJourneyRequest) async throws -> NextJourneyResponse {
        try await post(request, to: .next)
    }

    func analyze(_ request: AnalyzeRequest) async throws -> AnalyzeResponse {
        try await post(request, to: .analyze)
    }

    func verify(_ request: VerifyRequest) async throws -> VerifyResponse {
        try await post(request, to: .verify)
    }

    func license(_ request: SessionOnlyRequest) async throws -> LicenseResponse {
        try await post(request, to: .license)
    }

    func banking(_ request: SessionOnlyRequest) async throws -> BankingResponse {
        try await post(request, to: .banking)
    }

    func finalPlan(_ request: SessionOnlyRequest) async throws -> FinalPlanResponse {
        try await post(request, to: .finalPlan)
    }

    private func post<Request: Encodable, Response: Decodable>(
        _ request: Request,
        to endpoint: JourneyEndpoint
    ) async throws -> Response {
        var urlRequest = URLRequest(url: try url(for: endpoint.rawValue))
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = requestTimeout
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.httpBody = try encoder.encode(request)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch is CancellationError {
            throw APIError.cancelled
        } catch let error as URLError {
            switch error.code {
            case .cancelled:
                throw APIError.cancelled
            case .timedOut:
                throw APIError.timeout
            default:
                throw APIError.transport(error.localizedDescription)
            }
        } catch {
            throw APIError.transport(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.transport("Invalid response")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.badStatus(httpResponse.statusCode, Self.errorBodyText(from: data))
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch is CancellationError {
            throw APIError.cancelled
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }

    private static func errorBodyText(from data: Data) -> String? {
        guard let body = String(data: data, encoding: .utf8) else {
            return nil
        }

        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        return String(trimmed.prefix(4_000))
    }
}
