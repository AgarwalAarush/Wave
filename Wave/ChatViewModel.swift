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
    @Published var messages: [ChatMessage] = []
    @Published var streamingResponse: String = ""
    @Published var isStreaming: Bool = false
    @Published var errorMessage: String?
    var hasContent: Bool { !messages.isEmpty || isStreaming }

    @Published var selectedModel: AIModel {
        didSet { dependencies.writeSetting(selectedModel.rawValue, "ai_model") }
    }

    @Published var pendingScreenshot: Data?
    @Published var pendingScreenshotSourceName: String?
    @Published var hasManualScreenshot: Bool = false

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
        streamingResponse = ""
        queryText = ""

        let model = selectedModel.rawValue
        let screenshotEnabled = dependencies.readSettingObject("screenshot_enabled") as? Bool ?? true
        let manualScreenshot = pendingScreenshot
        let manualScreenshotSourceName = pendingScreenshotSourceName

        pendingScreenshot = nil
        pendingScreenshotSourceName = nil
        hasManualScreenshot = false

        streamTask = Task {
            var screenshotData: Data?
            var screenshotSourceName: String?
            if let manual = manualScreenshot {
                screenshotData = manual
                screenshotSourceName = manualScreenshotSourceName
            } else if screenshotEnabled {
                screenshotData = await dependencies.captureScreen()
                screenshotSourceName = "Screen"
            }

            // Add user message to history
            let userMessage = ChatMessage(role: .user, content: query, screenshot: screenshotData, screenshotSourceName: screenshotSourceName)
            await MainActor.run {
                self.messages.append(userMessage)
            }

            // Build full conversation history for API
            var apiMessages: [GPTMessage] = [
                GPTMessage(role: .system, content: [
                    .text("You are a helpful assistant. The user may share screenshots of their screen for context. Answer concisely and use markdown formatting where appropriate.")
                ])
            ]

            for msg in self.messages {
                var contentParts: [GPTMessage.ContentPart] = []
                if let screenshot = msg.screenshot {
                    contentParts.append(.imageData(screenshot, mimeType: "image/png"))
                }
                contentParts.append(.text(msg.content))

                let role: GPTMessage.Role = msg.role == .user ? .user : .assistant
                apiMessages.append(GPTMessage(role: role, content: contentParts))
            }

            do {
                let stream = dependencies.stream(apiMessages, model, apiKey, selectedModel.provider)
                for try await chunk in stream {
                    self.streamingResponse += chunk
                }

                // Add assistant response to history
                let assistantMessage = ChatMessage(role: .assistant, content: self.streamingResponse)
                self.messages.append(assistantMessage)
                self.streamingResponse = ""
            } catch is CancellationError {
                // Stopped by user - still save partial response if any
                if !self.streamingResponse.isEmpty {
                    let assistantMessage = ChatMessage(role: .assistant, content: self.streamingResponse)
                    self.messages.append(assistantMessage)
                    self.streamingResponse = ""
                }
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
        messages = []
        streamingResponse = ""
        errorMessage = nil
        pendingScreenshot = nil
        pendingScreenshotSourceName = nil
        hasManualScreenshot = false
    }

    func attachScreenshot(_ data: Data, sourceName: String? = nil) {
        pendingScreenshot = data
        pendingScreenshotSourceName = sourceName
        hasManualScreenshot = true
    }

    func removeScreenshot() {
        pendingScreenshot = nil
        pendingScreenshotSourceName = nil
        hasManualScreenshot = false
    }
}
