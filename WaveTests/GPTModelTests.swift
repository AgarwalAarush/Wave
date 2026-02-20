import XCTest
@testable import Wave

final class GPTModelTests: XCTestCase {
    func testDefaultModelIsMini() {
        XCTAssertEqual(GPTModel.default, .mini)
    }

    func testFromRawValueUsesStoredModel() {
        let model = GPTModel.from(rawValue: GPTModel.full.rawValue)
        XCTAssertEqual(model, .full)
    }

    func testFromRawValueFallsBackToDefaultWhenMissingOrInvalid() {
        XCTAssertEqual(GPTModel.from(rawValue: nil), .default)
        XCTAssertEqual(GPTModel.from(rawValue: "not-a-model"), .default)
    }
}
