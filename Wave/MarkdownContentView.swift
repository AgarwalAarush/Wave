import SwiftUI

struct MarkdownContentView: View {
    let text: String

    var body: some View {
        let segments = MarkdownParser.parse(text)

        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                switch segment {
                case .text(let content):
                    renderedTextSegment(content)

                case .codeBlock(let language, let code):
                    CodeBlockView(language: language, code: code)
                }
            }
        }
    }

    @ViewBuilder
    private func renderedTextSegment(_ content: String) -> some View {
        let blocks = MarkdownBlockRenderer.renderBlocks(from: content)

        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                blockView(block)
                    .padding(.top, blockTopSpacing(at: index, in: blocks))
            }
        }
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownRenderedBlock) -> some View {
        switch block {
        case .paragraph(let content):
            Text(content)
                .font(.waveSystem(size: 14))
                .foregroundStyle(Color.waveTextPrimary)
                .textSelection(.enabled)

        case .listItem(let kind, let depth, let content):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(listMarker(for: kind))
                    .font(.waveSystem(size: 14))
                    .foregroundStyle(Color.waveTextPrimary)
                    .frame(width: markerColumnWidth(for: kind), alignment: .trailing)

                Text(content)
                    .font(.waveSystem(size: 14))
                    .foregroundStyle(Color.waveTextPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, CGFloat(max(depth - 1, 0)) * 14)
        }
    }

    private func blockTopSpacing(at index: Int, in blocks: [MarkdownRenderedBlock]) -> CGFloat {
        guard index > 0 else { return 0 }

        if blocks[index - 1].isListItem && blocks[index].isListItem {
            return 4
        }
        return 8
    }

    private func listMarker(for kind: MarkdownListKind) -> String {
        switch kind {
        case .unordered:
            return "\u{2022}"
        case .ordered(let ordinal):
            return "\(ordinal)."
        }
    }

    private func markerColumnWidth(for kind: MarkdownListKind) -> CGFloat {
        switch kind {
        case .unordered:
            return 16
        case .ordered(let ordinal):
            let digits = max(String(ordinal).count, 1)
            return CGFloat(12 + digits * 8)
        }
    }
}

private extension MarkdownRenderedBlock {
    var isListItem: Bool {
        if case .listItem = self {
            return true
        }
        return false
    }
}
