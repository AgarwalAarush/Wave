import Foundation

struct GPTMessage: Sendable {
    enum Role: String, Sendable { case system, user, assistant }
    let role: Role
    let content: [ContentPart]

    enum ContentPart: Sendable {
        case text(String)
        case imageData(Data, mimeType: String)
    }
}

final class GPTService: @unchecked Sendable {
    static let shared = GPTService()
    private init() {}

    private let baseURL = URL(string: "https://api.openai.com/v1/chat/completions")!

    func stream(
        messages: [GPTMessage],
        model: String,
        apiKey: String
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = try buildRequest(messages: messages, model: model, apiKey: apiKey)
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let http = response as? HTTPURLResponse else {
                        continuation.finish(throwing: GPTError.invalidResponse)
                        return
                    }
                    guard http.statusCode == 200 else {
                        var body = ""
                        for try await line in bytes.lines { body += line }
                        continuation.finish(throwing: GPTError.apiError(http.statusCode, body))
                        return
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                        if payload == "[DONE]" { break }

                        guard let data = payload.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let delta = choices.first?["delta"] as? [String: Any],
                              let content = delta["content"] as? String
                        else { continue }

                        continuation.yield(content)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func buildRequest(messages: [GPTMessage], model: String, apiKey: String) throws -> URLRequest {
        var jsonMessages: [[String: Any]] = []

        for msg in messages {
            var parts: [[String: Any]] = []
            for part in msg.content {
                switch part {
                case .text(let text):
                    parts.append(["type": "text", "text": text])
                case .imageData(let data, let mime):
                    parts.append([
                        "type": "image_url",
                        "image_url": [
                            "url": "data:\(mime);base64,\(data.base64EncodedString())",
                            "detail": "low"
                        ]
                    ])
                }
            }
            jsonMessages.append(["role": msg.role.rawValue, "content": parts])
        }

        let body: [String: Any] = [
            "model": model,
            "messages": jsonMessages,
            "stream": true,
            "max_tokens": 4096
        ]

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
}

enum GPTError: LocalizedError {
    case invalidResponse
    case apiError(Int, String)
    case noAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "Invalid response from OpenAI"
        case .apiError(let code, let body): "OpenAI API error \(code): \(body)"
        case .noAPIKey: "No API key configured. Open Settings to add your OpenAI key."
        }
    }
}
