import XCTest
@testable import WaveCore

final class GPTServiceTests: XCTestCase {
    func testBuildRequestContainsHeadersAndBody() throws {
        let messages: [GPTMessage] = [
            GPTMessage(role: .system, content: [.text("System prompt")]),
            GPTMessage(role: .user, content: [
                .text("Question"),
                .imageData(Data([0x01, 0x02, 0x03]), mimeType: "image/png"),
            ]),
        ]

        let request = try GPTService.shared.buildRequest(
            messages: messages,
            model: GPTModel.nano.rawValue,
            apiKey: "test-key"
        )

        XCTAssertEqual(request.url?.absoluteString, "https://api.openai.com/v1/chat/completions")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")

        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(json["model"] as? String, GPTModel.nano.rawValue)
        XCTAssertEqual(json["stream"] as? Bool, true)
        XCTAssertEqual(json["max_completion_tokens"] as? Int, 4096)

        let jsonMessages = try XCTUnwrap(json["messages"] as? [[String: Any]])
        XCTAssertEqual(jsonMessages.count, 2)

        let userMessage = try XCTUnwrap(jsonMessages.last)
        XCTAssertEqual(userMessage["role"] as? String, "user")

        let content = try XCTUnwrap(userMessage["content"] as? [[String: Any]])
        XCTAssertEqual(content.count, 2)
        XCTAssertEqual(content[0]["type"] as? String, "text")
        XCTAssertEqual(content[0]["text"] as? String, "Question")

        XCTAssertEqual(content[1]["type"] as? String, "image_url")
        let imageURL = try XCTUnwrap(content[1]["image_url"] as? [String: Any])
        let url = try XCTUnwrap(imageURL["url"] as? String)
        XCTAssertTrue(url.hasPrefix("data:image/png;base64,"))
        XCTAssertEqual(imageURL["detail"] as? String, "low")
    }

    func testParseStreamLineContent() {
        let line = #"data: {"choices":[{"delta":{"content":"Hello"}}]}"#
        XCTAssertEqual(GPTService.parseStreamLine(line), .content("Hello"))
    }

    func testParseStreamLineDone() {
        XCTAssertEqual(GPTService.parseStreamLine("data: [DONE]"), .done)
    }

    func testParseStreamLineIgnoreCases() {
        XCTAssertEqual(GPTService.parseStreamLine("event: ping"), .ignore)
        XCTAssertEqual(GPTService.parseStreamLine("data: {\"choices\":[]}"), .ignore)
        XCTAssertEqual(GPTService.parseStreamLine("data: not-json"), .ignore)
    }
}
