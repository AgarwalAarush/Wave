import Foundation
import SwiftUI

protocol APIKeyReading {
    func read(key: String) -> String?
}

protocol SettingsStoring {
    func string(forKey defaultName: String) -> String?
    func object(forKey defaultName: String) -> Any?
    func set(_ value: Any?, forKey defaultName: String)
}

protocol GPTStreaming {
    func stream(
        messages: [GPTMessage],
        model: String,
        apiKey: String
    ) -> AsyncThrowingStream<String, Error>
}

protocol ScreenCapturing {
    func captureFullScreen() async -> Data?
}

struct SystemAPIKeyReader: APIKeyReading {
    func read(key: String) -> String? {
        KeychainHelper.read(key: key)
    }
}

extension UserDefaults: SettingsStoring {}
extension GPTService: GPTStreaming {}
extension ScreenCaptureService: ScreenCapturing {}

@Observable
final class ChatViewModel {

    var queryText: String = ""
    var responseText: String = ""
    var isStreaming: Bool = false
    var errorMessage: String?
    var hasResponse: Bool { !responseText.isEmpty || isStreaming }

    var selectedModel: GPTModel {
        didSet { settingsStore.set(selectedModel.rawValue, forKey: "gpt_model") }
    }

    private var streamTask: Task<Void, Never>?
    private let apiKeyReader: APIKeyReading
    private let settingsStore: SettingsStoring
    private let gptStreamer: GPTStreaming
    private let screenCapturer: ScreenCapturing

    init(
        apiKeyReader: APIKeyReading = SystemAPIKeyReader(),
        settingsStore: SettingsStoring = UserDefaults.standard,
        gptStreamer: GPTStreaming = GPTService.shared,
        screenCapturer: ScreenCapturing = ScreenCaptureService.shared
    ) {
        self.apiKeyReader = apiKeyReader
        self.settingsStore = settingsStore
        self.gptStreamer = gptStreamer
        self.screenCapturer = screenCapturer

        let stored = settingsStore.string(forKey: "gpt_model")
        self.selectedModel = GPTModel.from(rawValue: stored)
    }

    // MARK: - Actions

    func submit() {
        let query = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, !isStreaming else { return }

        guard let apiKey = apiKeyReader.read(key: "openai_api_key"), !apiKey.isEmpty else {
            errorMessage = "No API key configured. Open Settings (Cmd+,) to add your OpenAI key."
            return
        }

        errorMessage = nil
        isStreaming = true
        responseText = ""

        let model = selectedModel.rawValue
        let screenshotEnabled = settingsStore.object(forKey: "screenshot_enabled") as? Bool ?? true

        streamTask = Task {
            var screenshotData: Data?
            if screenshotEnabled {
                screenshotData = await screenCapturer.captureFullScreen()
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
                let stream = gptStreamer.stream(messages: messages, model: model, apiKey: apiKey)
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
