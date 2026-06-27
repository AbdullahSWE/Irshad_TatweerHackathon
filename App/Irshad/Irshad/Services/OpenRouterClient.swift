import Foundation

final class OpenRouterClient: @unchecked Sendable {
    private struct Message: Encodable {
        let role: String
        let content: String
    }

    private struct ResponseFormat: Encodable {
        let type: String
    }

    private struct ChatRequest: Encodable {
        let model: String
        let responseFormat: ResponseFormat
        let messages: [Message]

        private enum CodingKeys: String, CodingKey {
            case model
            case responseFormat = "response_format"
            case messages
        }
    }

    private struct ChatResponse: Decodable {
        let choices: [Choice]
    }

    private struct Choice: Decodable {
        let message: AssistantMessage?
        let finishReason: String?
        let error: ChoiceError?

        private enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
            case error
        }
    }

    private struct AssistantMessage: Decodable {
        let content: String?
    }

    private struct ChoiceError: Decodable {
        let code: Int?
        let message: String?
        let metadata: [String: JSONValue]?
    }

    private let apiKey: String
    private let model: String
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let endpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!

    init(
        apiKey: String = AppConfig.openRouterAPIKey,
        model: String = AppConfig.openRouterModel,
        session: URLSession = .shared,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.apiKey = apiKey
        self.model = model
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
    }

    func json<T: Decodable>(
        system: String,
        user: String,
        language: AppLanguage = .en,
        debugLabel: String = "json",
        as type: T.Type = T.self
    ) async throws -> T {
        let requestID = String(UUID().uuidString.prefix(8))
        let startedAt = Date()
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty, !trimmedKey.contains("replace-with") else {
            let trace = """
            OpenRouter[\(requestID)] \(debugLabel)
            endpoint=POST \(endpoint.absoluteString)
            model=\(model)
            target=\(String(describing: T.self))
            failure=missing API key
            """
            DebugLog.api(trace)
            throw DebuggableAPIError(
                underlying: APIError.transport("OpenRouter API key is missing."),
                debugTrace: trace
            )
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("https://irshad.app", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("Irshad", forHTTPHeaderField: "X-OpenRouter-Title")

        let body = ChatRequest(
            model: model,
            responseFormat: ResponseFormat(type: "json_object"),
            messages: [
                Message(role: "system", content: "\(system)\n\n\(Self.languageInstruction(language))"),
                Message(role: "user", content: user)
            ]
        )
        let bodyData = try encoder.encode(body)
        request.httpBody = bodyData
        let requestTrace = Self.requestTrace(
            requestID: requestID,
            debugLabel: debugLabel,
            endpoint: endpoint,
            model: model,
            language: language,
            timeout: request.timeoutInterval,
            target: String(describing: T.self),
            bodyData: bodyData
        )

        DebugLog.api(requestTrace)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            DebugLog.api("OpenRouter[\(requestID)] \(debugLabel) cancelled after \(Self.elapsedMilliseconds(since: startedAt))ms")
            throw APIError.cancelled
        } catch let error as URLError {
            let trace = Self.failureTrace(
                requestTrace: requestTrace,
                startedAt: startedAt,
                detail: "URLSession error: \(DebugLog.describe(error))\nhttpResponse=none\nresponseBody=none"
            )
            DebugLog.api(trace)
            switch error.code {
            case .cancelled:
                throw APIError.cancelled
            case .timedOut:
                throw DebuggableAPIError(underlying: .timeout, debugTrace: trace)
            default:
                throw DebuggableAPIError(
                    underlying: .transport(error.localizedDescription),
                    debugTrace: trace
                )
            }
        } catch {
            let trace = Self.failureTrace(
                requestTrace: requestTrace,
                startedAt: startedAt,
                detail: "Transport error: \(DebugLog.describe(error))\nhttpResponse=none\nresponseBody=none"
            )
            DebugLog.api(trace)
            throw DebuggableAPIError(
                underlying: .transport(error.localizedDescription),
                debugTrace: trace
            )
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            let trace = Self.failureTrace(
                requestTrace: requestTrace,
                startedAt: startedAt,
                detail: "Invalid response type: \(Swift.type(of: response))"
            )
            DebugLog.api(trace)
            throw DebuggableAPIError(
                underlying: .transport("Invalid OpenRouter response."),
                debugTrace: trace
            )
        }

        let responseTrace = Self.responseTrace(
            requestTrace: requestTrace,
            startedAt: startedAt,
            response: httpResponse,
            data: data
        )
        DebugLog.api(responseTrace)

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw DebuggableAPIError(
                underlying: .badStatus(httpResponse.statusCode, Self.errorText(from: data)),
                debugTrace: responseTrace
            )
        }

        let chatResponse: ChatResponse
        do {
            chatResponse = try decoder.decode(ChatResponse.self, from: data)
        } catch {
            let trace = """
            \(responseTrace)
            decodeFailure=chat envelope
            decodeError=\(DebugLog.describe(error))
            """
            DebugLog.api(trace)
            throw DebuggableAPIError(
                underlying: .decoding(error.localizedDescription),
                debugTrace: trace
            )
        }

        if let choice = chatResponse.choices.first,
           choice.finishReason == "error" || choice.error != nil {
            let code = choice.error?.code ?? 502
            let message = choice.error?.message ?? "OpenRouter returned finish_reason=error."
            let trace = """
            \(responseTrace)
            choiceError.finishReason=\(choice.finishReason ?? "nil")
            choiceError.code=\(code)
            choiceError.message=\(message)
            choiceError.metadata=\(choice.error?.metadata ?? [:])
            """
            DebugLog.api(trace)
            throw DebuggableAPIError(
                underlying: .badStatus(code, message),
                debugTrace: trace
            )
        }

        guard let text = chatResponse.choices.first?.message?.content,
              let jsonData = text.data(using: .utf8) else {
            let trace = """
            \(responseTrace)
            decodeFailure=empty assistant message
            choices=\(chatResponse.choices.count)
            """
            DebugLog.api(trace)
            throw DebuggableAPIError(
                underlying: .decoding("OpenRouter returned an empty message."),
                debugTrace: trace
            )
        }

        DebugLog.api("OpenRouter[\(requestID)] \(debugLabel) assistantJSONBytes=\(jsonData.count) assistantPreview=\(DebugLog.preview(text))")

        do {
            let decoded = try decoder.decode(T.self, from: jsonData)
            DebugLog.api("OpenRouter[\(requestID)] \(debugLabel) decoded \(String(describing: T.self)) successfully")
            return decoded
        } catch {
            let trace = """
            \(responseTrace)
            assistantJSONBytes=\(jsonData.count)
            assistantPreview=\(DebugLog.preview(text))
            decodeFailure=target \(String(describing: T.self))
            decodeError=\(DebugLog.describe(error))
            """
            DebugLog.api(trace)
            throw DebuggableAPIError(
                underlying: .decoding(error.localizedDescription),
                debugTrace: trace
            )
        }
    }

    private static func languageInstruction(_ language: AppLanguage) -> String {
        switch language {
        case .ar:
            return "IMPORTANT: All human-readable text values in the JSON must be in Arabic (العربية). JSON field names stay in English. Numbers and codes stay as-is."
        case .en:
            return "Respond in English."
        }
    }

    private static func errorText(from data: Data) -> String? {
        guard let body = String(data: data, encoding: .utf8) else {
            return nil
        }
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : String(trimmed.prefix(4_000))
    }

    private static func elapsedMilliseconds(since startedAt: Date) -> Int {
        Int(Date().timeIntervalSince(startedAt) * 1_000)
    }

    private static func requestTrace(
        requestID: String,
        debugLabel: String,
        endpoint: URL,
        model: String,
        language: AppLanguage,
        timeout: TimeInterval,
        target: String,
        bodyData: Data
    ) -> String {
        """
        OpenRouter[\(requestID)] \(debugLabel)
        endpoint=POST \(endpoint.absoluteString)
        model=\(model)
        language=\(language.rawValue)
        timeout=\(Int(timeout))s
        target=\(target)
        payloadBytes=\(bodyData.count)
        payloadPreview=\(DebugLog.prettyJSONPreview(data: bodyData))
        """
    }

    private static func responseTrace(
        requestTrace: String,
        startedAt: Date,
        response: HTTPURLResponse,
        data: Data
    ) -> String {
        """
        \(requestTrace)
        elapsedMs=\(elapsedMilliseconds(since: startedAt))
        httpStatus=\(response.statusCode)
        responseBytes=\(data.count)
        responseHeaders=\(debugHeaders(from: response))
        responseBodyPreview=\(DebugLog.preview(data: data))
        """
    }

    private static func failureTrace(
        requestTrace: String,
        startedAt: Date,
        detail: String
    ) -> String {
        """
        \(requestTrace)
        elapsedMs=\(elapsedMilliseconds(since: startedAt))
        \(detail)
        """
    }

    private static func debugHeaders(from response: HTTPURLResponse) -> [String: String] {
        var selected: [String: String] = [:]
        let wanted = [
            "content-type",
            "x-request-id",
            "x-openrouter-request-id",
            "openrouter-processing-time",
            "cf-ray"
        ]

        for (key, value) in response.allHeaderFields {
            let normalizedKey = String(describing: key).lowercased()
            guard wanted.contains(normalizedKey) else {
                continue
            }
            selected[normalizedKey] = String(describing: value)
        }

        return selected
    }
}
