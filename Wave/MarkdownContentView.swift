import SwiftUI

struct MarkdownContentView: View {
    let text: String

    var body: some View {
        let segments = MarkdownParser.parse(text)

        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                switch segment {
                case .text(let content):
                    Text(markdownAttributedString(content))
                        .font(.waveSystem(size: 14))
                        .foregroundStyle(Color.waveTextPrimary)
                        .textSelection(.enabled)

                case .codeBlock(let language, let code):
                    CodeBlockView(language: language, code: code)
                }
            }
        }
    }

    private func markdownAttributedString(_ text: String) -> AttributedString {
        // Parse inline markdown (bold, italic, code, links) while preserving whitespace
        (try? AttributedString(markdown: text, options: .init(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        ))) ?? AttributedString(text)
    }
}
