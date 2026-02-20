import Foundation
import SwiftUI

struct ChatViewModelDependencies {
    let readAPIKey: (String) -> String?
    let readSettingString: (String) -> String?
    let readSettingObject: (String) -> Any?
    let writeSetting: (Any?, String) -> Void
    let stream: ([GPTMessage], String, String) -> AsyncThrowingStream<String, Error>
    let captureScreen: () async -> Data?

    static let live = ChatViewModelDependencies(
        readAPIKey: { key in
            KeychainHelper.read(key: key)
        },
        readSettingString: { key in
            UserDefaults.standard.string(forKey: key)
        },
        readSettingObject: { key in
            UserDefaults.standard.object(forKey: key)
        },
        writeSetting: { value, key in
            UserDefaults.standard.set(value, forKey: key)
        },
        stream: { messages, model, apiKey in
            GPTService.shared.stream(messages: messages, model: model, apiKey: apiKey)
        },
        captureScreen: {
            await ScreenCaptureService.shared.captureFullScreen()
        }
    )
}

@Observable
final class ChatViewModel {

    var queryText: String = ""
    var responseText: String = ""
    var isStreaming: Bool = false
    var errorMessage: String?
    var hasResponse: Bool { !responseText.isEmpty || isStreaming }

    var selectedModel: GPTModel {
        didSet { dependencies.writeSetting(selectedModel.rawValue, "gpt_model") }
    }

    @ObservationIgnored private var streamTask: Task<Void, Never>?
    @ObservationIgnored private let dependencies: ChatViewModelDependencies

    init(dependencies: ChatViewModelDependencies = .live) {
        self.dependencies = dependencies

        let stored = dependencies.readSettingString("gpt_model")
        self.selectedModel = GPTModel.from(rawValue: stored)
    }

    // MARK: - Actions

    func submit() {
        let query = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, !isStreaming else { return }

        guard let apiKey = dependencies.readAPIKey("openai_api_key"), !apiKey.isEmpty else {
            errorMessage = "No API key configured. Open Settings (Cmd+,) to add your OpenAI key."
            return
        }

        errorMessage = nil
        isStreaming = true
        responseText = ""

        let model = selectedModel.rawValue
        let screenshotEnabled = dependencies.readSettingObject("screenshot_enabled") as? Bool ?? true

        streamTask = Task {
            var screenshotData: Data?
            if screenshotEnabled {
                screenshotData = await dependencies.captureScreen()
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
                let stream = dependencies.stream(messages, model, apiKey)
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
