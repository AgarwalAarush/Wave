import Foundation
import SwiftUI

@Observable
final class ChatViewModel {

    var queryText: String = ""
    var responseText: String = ""
    var isStreaming: Bool = false
    var errorMessage: String?
    var hasResponse: Bool { !responseText.isEmpty || isStreaming }

    private var streamTask: Task<Void, Never>?

    // MARK: - Actions

    func submit() {
        let query = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, !isStreaming else { return }

        guard let apiKey = KeychainHelper.read(key: "openai_api_key"), !apiKey.isEmpty else {
            errorMessage = "No API key configured. Open Settings (Cmd+,) to add your OpenAI key."
            return
        }

        errorMessage = nil
        isStreaming = true
        responseText = ""

        let model = UserDefaults.standard.string(forKey: "gpt_model") ?? "gpt-4o"
        let screenshotEnabled = UserDefaults.standard.object(forKey: "screenshot_enabled") as? Bool ?? true

        streamTask = Task {
            var screenshotData: Data?
            if screenshotEnabled {
                screenshotData = await ScreenCaptureService.shared.captureFullScreen()
            }

            var contentParts: [GPTMessage.ContentPart] = []
            if let data = screenshotData {
                contentParts.append(.imageData(data, mimeType: "image/png"))
            }
            contentParts.append(.text(query))

            let messages: [GPTMessage] = [
                GPTMessage(role: .system, content: [
                    .text("You are a helpful assistant. The user has shared a screenshot of their screen for context. Answer concisely and use markdown formatting where appropriate.")
                ]),
                GPTMessage(role: .user, content: contentParts)
            ]

            do {
                let stream = GPTService.shared.stream(messages: messages, model: model, apiKey: apiKey)
                for try await chunk in stream {
                    self.responseText += chunk
                }
            } catch is CancellationError {
                // Stopped by user
            } catch {
                self.errorMessage = error.localizedDescription
            }

            self.isStreaming = false
        }
    }

    func stopStreaming() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
    }

    func newChat() {
        stopStreaming()
        queryText = ""
        responseText = ""
        errorMessage = nil
    }
}
