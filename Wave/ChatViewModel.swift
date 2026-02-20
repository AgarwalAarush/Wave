import Foundation
import SwiftUI
import Combine

struct ChatViewModelDependencies {
    let readAPIKey: (String) -> String?
    let readSettingString: (String) -> String?
    let readSettingObject: (String) -> Any?
    let writeSetting: (Any?, String) -> Void
    let stream: ([GPTMessage], String, String, AIProvider) -> AsyncThrowingStream<String, Error>
    let captureScreen: () async -> Data?

    nonisolated(unsafe) static let live = ChatViewModelDependencies(
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
        stream: { messages, model, apiKey, provider in
            switch provider {
            case .openai:
                GPTService.shared.stream(messages: messages, model: model, apiKey: apiKey)
            case .anthropic:
                AnthropicService.shared.stream(messages: messages, model: model, apiKey: apiKey)
            }
        },
        captureScreen: {
            await ScreenCaptureService.shared.captureFullScreen()
        }
    )
}

@MainActor
final class ChatViewModel: ObservableObject {

    @Published var queryText: String = ""
    @Published var responseText: String = ""
    @Published var isStreaming: Bool = false
    @Published var errorMessage: String?
    var hasResponse: Bool { !responseText.isEmpty || isStreaming }

    @Published var selectedModel: AIModel {
        didSet { dependencies.writeSetting(selectedModel.rawValue, "ai_model") }
    }

    private var streamTask: Task<Void, Never>?
    private let dependencies: ChatViewModelDependencies

    init(dependencies: ChatViewModelDependencies? = nil) {
        let resolved = dependencies ?? .live
        self.dependencies = resolved

        let stored = resolved.readSettingString("ai_model")
            ?? resolved.readSettingString("gpt_model")
        self.selectedModel = AIModel.fromStored(stored)
    }

    // MARK: - Actions

    func submit() {
        let query = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, !isStreaming else { return }

        let keyName = selectedModel.provider.apiKeyKey
        guard let apiKey = dependencies.readAPIKey(keyName), !apiKey.isEmpty else {
            let providerName = selectedModel.provider.rawValue
            errorMessage = "No API key configured. Open Settings (Cmd+,) to add your \(providerName) key."
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
                let stream = dependencies.stream(messages, model, apiKey, selectedModel.provider)
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
