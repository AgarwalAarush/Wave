import XCTest
@testable import Wave

final class MarkdownBlockRendererTests: XCTestCase {
    func testUnorderedListMetadata() {
        let blocks = MarkdownBlockRenderer.renderBlocks(from: "- first\n- second")

        XCTAssertEqual(blocks.count, 2)
        XCTAssertListItem(blocks[0], kind: .unordered, depth: 1, text: "first")
        XCTAssertListItem(blocks[1], kind: .unordered, depth: 1, text: "second")
    }

    func testOrderedListOrdinals() {
        let blocks = MarkdownBlockRenderer.renderBlocks(from: "1. one\n2. two")

        XCTAssertEqual(blocks.count, 2)
        XCTAssertListItem(blocks[0], kind: .ordered(ordinal: 1), depth: 1, text: "one")
        XCTAssertListItem(blocks[1], kind: .ordered(ordinal: 2), depth: 1, text: "two")
    }

    func testNestedListDepth() {
        let blocks = MarkdownBlockRenderer.renderBlocks(
            from: "- parent\n  - child\n    - grandchild"
        )

        XCTAssertEqual(blocks.count, 3)
        XCTAssertListItem(blocks[0], kind: .unordered, depth: 1, text: "parent")
        XCTAssertListItem(blocks[1], kind: .unordered, depth: 2, text: "child")
        XCTAssertListItem(blocks[2], kind: .unordered, depth: 3, text: "grandchild")
    }

    func testInlineFormattingPreservedInListItem() {
        let blocks = MarkdownBlockRenderer.renderBlocks(
            from: "- item with **bold** and `code` and [link](https://example.com)"
        )

        guard case .listItem(_, _, let content) = blocks.first else {
            return XCTFail("Expected first block to be a list item.")
        }

        let plainText = String(content.characters)
        XCTAssertEqual(plainText, "item with bold and code and link")
        XCTAssertTrue(hasInlineIntent(.stronglyEmphasized, for: "bold", in: content))
        XCTAssertTrue(hasInlineIntent(.code, for: "code", in: content))
        XCTAssertTrue(hasLink(for: "link", in: content))
    }

    func testParagraphBlocksForNonListContent() {
        let blocks = MarkdownBlockRenderer.renderBlocks(
            from: "First paragraph.\n\nSecond paragraph with **bold**."
        )

        XCTAssertEqual(blocks.count, 2)

        guard case .paragraph(let first) = blocks[0] else {
            return XCTFail("Expected first block to be a paragraph.")
        }
        guard case .paragraph(let second) = blocks[1] else {
            return XCTFail("Expected second block to be a paragraph.")
        }

        XCTAssertEqual(String(first.characters), "First paragraph.")
        XCTAssertEqual(String(second.characters), "Second paragraph with bold.")
    }

    private func XCTAssertListItem(
        _ block: MarkdownRenderedBlock,
        kind: MarkdownListKind,
        depth: Int,
        text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .listItem(let actualKind, let actualDepth, let content) = block else {
            return XCTFail("Expected list item block.", file: file, line: line)
        }
        XCTAssertEqual(actualKind, kind, file: file, line: line)
        XCTAssertEqual(actualDepth, depth, file: file, line: line)
        XCTAssertEqual(String(content.characters), text, file: file, line: line)
    }

    private func hasInlineIntent(
        _ intent: InlinePresentationIntent,
        for fragment: String,
        in attributed: AttributedString
    ) -> Bool {
        attributed.runs.contains { run in
            guard let inline = run.inlinePresentationIntent else { return false }
            guard inline.contains(intent) else { return false }
            return String(attributed[run.range].characters).contains(fragment)
        }
    }

    private func hasLink(for fragment: String, in attributed: AttributedString) -> Bool {
        attributed.runs.contains { run in
            guard run.link != nil else { return false }
            return String(attributed[run.range].characters).contains(fragment)
        }
    }
}
