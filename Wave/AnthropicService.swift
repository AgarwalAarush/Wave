import Foundation

final class AnthropicService: @unchecked Sendable {
    static let shared = AnthropicService()
    private init() {}

    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!

    enum StreamParseResult: Equatable {
        case content(String)
        case done
        case ignore
    }

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

                    var eventType = ""

                    lineLoop: for try await line in bytes.lines {
                        if line.hasPrefix("event:") {
                            eventType = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                        } else if line.hasPrefix("data:") {
                            let payload = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                            if payload == "[DONE]" {
                                break lineLoop
                            }
                            if eventType == "content_block_delta", let text = Self.parseContentBlockDelta(payload) {
                                continuation.yield(text)
                            } else if eventType == "message_stop" {
                                break lineLoop
                            }
                        } else if line.isEmpty {
                            eventType = ""
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private static func parseContentBlockDelta(_ jsonString: String) -> String? {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let delta = json["delta"] as? [String: Any],
              let text = delta["text"] as? String
        else { return nil }
        return text
    }

    func buildRequest(messages: [GPTMessage], model: String, apiKey: String) throws -> URLRequest {
        var systemPrompt: String?
        var apiMessages: [[String: Any]] = []

        for msg in messages {
            if msg.role == .system {
                let textParts = msg.content.compactMap { part -> String? in
                    if case .text(let t) = part { return t }
                    return nil
                }
                systemPrompt = textParts.joined(separator: "\n")
                continue
            }

            var contentBlocks: [[String: Any]] = []
            for part in msg.content {
                switch part {
                case .text(let text):
                    contentBlocks.append(["type": "text", "text": text])
                case .imageData(let data, let mime):
                    contentBlocks.append([
                        "type": "image",
                        "source": [
                            "type": "base64",
                            "media_type": mime,
                            "data": data.base64EncodedString()
                        ]
                    ])
                }
            }
            apiMessages.append([
                "role": msg.role == .user ? "user" : "assistant",
                "content": contentBlocks
            ])
        }

        var body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "messages": apiMessages,
            "stream": true
        ]
        if let system = systemPrompt {
            body["system"] = system
        }

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
}
