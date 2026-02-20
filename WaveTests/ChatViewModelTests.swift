import XCTest
@testable import Wave

@MainActor
final class ChatViewModelTests: XCTestCase {
    func testInitUsesStoredModel() {
        let settings = MockSettingsStore(values: ["gpt_model": GPTModel.full.rawValue])
        let viewModel = makeViewModel(
            apiKey: "sk-test",
            settings: settings
        )

        XCTAssertEqual(viewModel.selectedModel, .full)
    }

    func testSelectedModelPersistsToSettings() {
        let settings = MockSettingsStore()
        let viewModel = makeViewModel(
            apiKey: "sk-test",
            settings: settings
        )

        viewModel.selectedModel = .codex
        XCTAssertEqual(settings.string(forKey: "gpt_model"), GPTModel.codex.rawValue)
    }

    func testSubmitWithoutAPIKeySetsError() {
        let streamer = MockStreamer()
        let viewModel = makeViewModel(
            apiKey: nil,
            streamer: streamer
        )
        viewModel.queryText = "Hello"

        viewModel.submit()

        XCTAssertFalse(viewModel.isStreaming)
        XCTAssertEqual(
            viewModel.errorMessage,
            "No API key configured. Open Settings (Cmd+,) to add your OpenAI key."
        )
        XCTAssertNil(streamer.capturedMessages)
    }

    func testSubmitStreamsResponseAndStops() async throws {
        let settings = MockSettingsStore(values: ["screenshot_enabled": false])
        let streamer = MockStreamer()
        streamer.streamToReturn = makeStream(chunks: ["Hello", " world"])
        let capturer = MockScreenCapturer(data: Data([0x01]))
        let viewModel = makeViewModel(
            apiKey: "sk-test",
            settings: settings,
            streamer: streamer,
            capturer: capturer
        )
        viewModel.queryText = "What is this?"

        viewModel.submit()
        await waitUntil { !viewModel.isStreaming }

        XCTAssertEqual(viewModel.responseText, "Hello world")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(capturer.callCount, 0)
        XCTAssertEqual(streamer.capturedModel, viewModel.selectedModel.rawValue)
        XCTAssertEqual(streamer.capturedAPIKey, "sk-test")

        let messages = try XCTUnwrap(streamer.capturedMessages)
        XCTAssertEqual(messages.count, 2)
        let userMessage = try XCTUnwrap(messages.last)
        let hasImage = userMessage.content.contains(where: {
            if case .imageData = $0 { return true }
            return false
        })
        XCTAssertFalse(hasImage)
    }

    func testSubmitIncludesScreenshotWhenEnabled() async throws {
        let settings = MockSettingsStore(values: ["screenshot_enabled": true])
        let streamer = MockStreamer()
        streamer.streamToReturn = makeStream(chunks: ["ok"])
        let capturer = MockScreenCapturer(data: Data([0xAA]))
        let viewModel = makeViewModel(
            apiKey: "sk-test",
            settings: settings,
            streamer: streamer,
            capturer: capturer
        )
        viewModel.queryText = "Use screenshot"

        viewModel.submit()
        await waitUntil { !viewModel.isStreaming }

        XCTAssertEqual(capturer.callCount, 1)
        let userMessage = try XCTUnwrap(streamer.capturedMessages?.last)
        let hasImage = userMessage.content.contains(where: {
            if case .imageData = $0 { return true }
            return false
        })
        let hasText = userMessage.content.contains(where: {
            if case .text("Use screenshot") = $0 { return true }
            return false
        })
        XCTAssertTrue(hasImage)
        XCTAssertTrue(hasText)
    }

    func testStopStreamingCancelsAndClearsStreamingState() async {
        let settings = MockSettingsStore(values: ["screenshot_enabled": false])
        let streamer = MockStreamer()
        streamer.streamToReturn = makeCancellableInfiniteStream()
        let viewModel = makeViewModel(
            apiKey: "sk-test",
            settings: settings,
            streamer: streamer
        )
        viewModel.queryText = "Long response"

        viewModel.submit()
        await waitUntil { viewModel.isStreaming }
        viewModel.stopStreaming()

        XCTAssertFalse(viewModel.isStreaming)
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testNewChatResetsState() {
        let viewModel = makeViewModel(apiKey: "sk-test")
        viewModel.queryText = "Question"
        viewModel.responseText = "Answer"
        viewModel.errorMessage = "Error"

        viewModel.newChat()

        XCTAssertEqual(viewModel.queryText, "")
        XCTAssertEqual(viewModel.responseText, "")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isStreaming)
    }

    private func makeViewModel(
        apiKey: String?,
        settings: MockSettingsStore = MockSettingsStore(),
        streamer: MockStreamer = MockStreamer(),
        capturer: MockScreenCapturer = MockScreenCapturer()
    ) -> ChatViewModel {
        let dependencies = ChatViewModelDependencies(
            readAPIKey: { _ in apiKey },
            readSettingString: { key in settings.string(forKey: key) },
            readSettingObject: { key in settings.object(forKey: key) },
            writeSetting: { value, key in settings.set(value, forKey: key) },
            stream: { messages, model, key in
                streamer.capturedMessages = messages
                streamer.capturedModel = model
                streamer.capturedAPIKey = key
                return streamer.streamToReturn
            },
            captureScreen: {
                capturer.callCount += 1
                return capturer.data
            }
        )

        return ChatViewModel(dependencies: dependencies)
    }

    private func waitUntil(
        timeoutNanoseconds: UInt64 = 1_000_000_000,
        condition: @escaping () -> Bool
    ) async {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
        while DispatchTime.now().uptimeNanoseconds < deadline {
            if condition() { return }
            await Task.yield()
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Timed out waiting for condition")
    }

    private func makeStream(chunks: [String]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                for chunk in chunks {
                    continuation.yield(chunk)
                }
                continuation.finish()
            }
        }
    }

    private func makeCancellableInfiniteStream() -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    while true {
                        try Task.checkCancellation()
                        continuation.yield("chunk")
                        try await Task.sleep(nanoseconds: 20_000_000)
                    }
                } catch is CancellationError {
                    continuation.finish(throwing: CancellationError())
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

private final class MockSettingsStore {
    private var values: [String: Any]

    init(values: [String: Any] = [:]) {
        self.values = values
    }

    func string(forKey defaultName: String) -> String? {
        values[defaultName] as? String
    }

    func object(forKey defaultName: String) -> Any? {
        values[defaultName]
    }

    func set(_ value: Any?, forKey defaultName: String) {
        values[defaultName] = value
    }
}

private final class MockStreamer {
    var capturedMessages: [GPTMessage]?
    var capturedModel: String?
    var capturedAPIKey: String?
    var streamToReturn: AsyncThrowingStream<String, Error> = AsyncThrowingStream { continuation in
        continuation.finish()
    }
}

private final class MockScreenCapturer {
    let data: Data?
    var callCount: Int = 0

    init(data: Data? = nil) {
        self.data = data
    }
}
