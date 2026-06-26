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
        let message: AssistantMessage
    }

    private struct AssistantMessage: Decodable {
        let content: String?
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
        as type: T.Type = T.self
    ) async throws -> T {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty, !trimmedKey.contains("replace-with") else {
            throw APIError.transport("OpenRouter API key is missing.")
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
        request.httpBody = try encoder.encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
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
            throw APIError.transport("Invalid OpenRouter response.")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.badStatus(httpResponse.statusCode, Self.errorText(from: data))
        }

        let chatResponse: ChatResponse
        do {
            chatResponse = try decoder.decode(ChatResponse.self, from: data)
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }

        guard let text = chatResponse.choices.first?.message.content,
              let jsonData = text.data(using: .utf8) else {
            throw APIError.decoding("OpenRouter returned an empty message.")
        }

        do {
            return try decoder.decode(T.self, from: jsonData)
        } catch {
            throw APIError.decoding(error.localizedDescription)
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
}
