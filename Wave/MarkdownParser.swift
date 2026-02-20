import Foundation

enum MarkdownSegment: Equatable {
    case text(String)
    case codeBlock(language: String?, code: String)
}

struct MarkdownParser {
    /// Parses markdown text into segments, separating code blocks from regular text.
    /// Handles fenced code blocks with optional language specifiers: ```language\ncode\n```
    static func parse(_ text: String) -> [MarkdownSegment] {
        var segments: [MarkdownSegment] = []
        var currentIndex = text.startIndex

        // Regex pattern for fenced code blocks: ```language\ncode\n```
        // Captures: (1) optional language, (2) code content
        let pattern = "```([a-zA-Z0-9+#]*)?\\n([\\s\\S]*?)```"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return [.text(text)]
        }

        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            let matchRange = match.range
            let matchStart = text.index(text.startIndex, offsetBy: matchRange.location)

            // Add any text before this code block
            if currentIndex < matchStart {
                let textBefore = String(text[currentIndex..<matchStart])
                if !textBefore.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    segments.append(.text(textBefore))
                }
            }

            // Extract language (group 1)
            var language: String? = nil
            if match.range(at: 1).location != NSNotFound {
                let langRange = match.range(at: 1)
                if langRange.length > 0 {
                    language = nsString.substring(with: langRange)
                }
            }

            // Extract code content (group 2)
            if match.range(at: 2).location != NSNotFound {
                let codeRange = match.range(at: 2)
                var code = nsString.substring(with: codeRange)
                // Remove trailing newline if present
                if code.hasSuffix("\n") {
                    code = String(code.dropLast())
                }
                segments.append(.codeBlock(language: language, code: code))
            }

            // Move current index past this match
            currentIndex = text.index(text.startIndex, offsetBy: matchRange.location + matchRange.length)
        }

        // Add any remaining text after the last code block
        if currentIndex < text.endIndex {
            let remainingText = String(text[currentIndex...])
            if !remainingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                segments.append(.text(remainingText))
            }
        }

        // If no segments were found, treat entire text as regular text
        if segments.isEmpty && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            segments.append(.text(text))
        }

        return segments
    }
}
