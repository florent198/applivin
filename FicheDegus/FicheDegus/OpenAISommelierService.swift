import Foundation

enum OpenAISommelierError: LocalizedError {
    case invalidResponse
    case missingResponseBody
    case malformedJSON
    case httpError(code: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Réponse invalide du service IA."
        case .missingResponseBody:
            return "Le service IA n'a pas renvoyé de contenu exploitable."
        case .malformedJSON:
            return "La réponse IA n'est pas au format JSON attendu."
        case .httpError(let code, let message):
            return "Erreur API (\(code)): \(message)"
        }
    }
}

struct OpenAISommelierService {
    static let shared = OpenAISommelierService()

    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    func suggest(for wineContext: String, fallbackWineName: String, apiKey: String) async throws -> SommelierSuggestion {
        let cleanedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        let payload = ChatCompletionsRequest(
            model: "gpt-4o-mini",
            temperature: 0.4,
            messages: [
                .init(
                    role: "system",
                    content: "Tu es un sommelier professionnel. Réponds uniquement en JSON compact avec les clés exactes: wineName (String), explanation (String), foodPairings (Array de 4 à 6 String), serviceTip (String). Pas de markdown, pas de texte hors JSON. Réponds en français."
                ),
                .init(role: "user", content: wineContext)
            ]
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(cleanedKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAISommelierError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Erreur inconnue"
            throw OpenAISommelierError.httpError(code: httpResponse.statusCode, message: message)
        }

        let completion = try JSONDecoder().decode(ChatCompletionsResponse.self, from: data)
        guard let rawContent = completion.firstMessageContent else {
            throw OpenAISommelierError.missingResponseBody
        }

        let jsonText = Self.extractJSON(from: rawContent)
        guard let jsonData = jsonText.data(using: .utf8) else {
            throw OpenAISommelierError.malformedJSON
        }

        let decoded = try JSONDecoder().decode(SommelierSuggestionPayload.self, from: jsonData)
        return decoded.toSuggestion(defaultWineName: fallbackWineName)
    }

    private static func extractJSON(from content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("```") {
            let cleaned = trimmed
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned
        }
        return trimmed
    }
}

private struct ChatCompletionsRequest: Encodable {
    let model: String
    let temperature: Double
    let messages: [ChatMessage]
}

private struct ChatMessage: Codable {
    let role: String
    let content: String
}

private struct ChatCompletionsResponse: Decodable {
    let choices: [Choice]

    var firstMessageContent: String? {
        choices.first?.message.extractText()
    }
}

private struct Choice: Decodable {
    let message: ResponseMessage
}

private struct ResponseMessage: Decodable {
    let content: MessageContent

    func extractText() -> String? {
        switch content {
        case .text(let value):
            return value
        case .parts(let parts):
            return parts
                .compactMap { $0.text }
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

private enum MessageContent: Decodable {
    case text(String)
    case parts([ContentPart])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self = .text(text)
            return
        }
        if let parts = try? container.decode([ContentPart].self) {
            self = .parts(parts)
            return
        }
        throw DecodingError.typeMismatch(
            MessageContent.self,
            .init(codingPath: decoder.codingPath, debugDescription: "Unsupported message content format")
        )
    }
}

private struct ContentPart: Decodable {
    let type: String?
    let text: String?
}
