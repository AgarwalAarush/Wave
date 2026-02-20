import SwiftUI
import AppKit

struct CodeBlockView: View {
    let language: String?
    let code: String

    @State private var showCopied = false
    private let cornerRadius: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header bar with language label and copy button
            HStack {
                Text(displayLanguage)
                    .font(.waveSystem(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.waveCodeText.opacity(0.6))

                Spacer()

                Button {
                    copyToClipboard()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showCopied ? "checkmark" : "square.on.square")
                            .font(.waveSystem(size: 10, weight: .medium))
                        if showCopied {
                            Text("Copied!")
                                .font(.waveSystem(size: 10, weight: .medium))
                        }
                    }
                    .foregroundStyle(showCopied ? Color.waveAccent : Color.waveCodeText.opacity(0.6))
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: showCopied)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.waveCodeBackground)

            Rectangle()
                .fill(Color.waveBorder)
                .frame(height: 0.5)

            // Code content
            ScrollView(.horizontal, showsIndicators: false) {
                Text(SyntaxHighlighter.highlight(code: code, language: language))
                    .font(.waveSystem(size: 12, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.waveCodeBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.waveBorder, lineWidth: 0.5)
        )
    }

    private var displayLanguage: String {
        guard let lang = language?.lowercased(), !lang.isEmpty else {
            return "code"
        }

        // Normalize common language names
        switch lang {
        case "js": return "JavaScript"
        case "ts": return "TypeScript"
        case "py": return "Python"
        case "rb": return "Ruby"
        case "rs": return "Rust"
        case "go", "golang": return "Go"
        case "cpp", "c++": return "C++"
        case "cs", "csharp": return "C#"
        case "objc", "objective-c": return "Objective-C"
        case "sh", "bash", "zsh": return "Shell"
        case "yml": return "YAML"
        case "md": return "Markdown"
        default: return lang.prefix(1).uppercased() + lang.dropFirst()
        }
    }

    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(code, forType: .string)

        showCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showCopied = false
        }
    }
}
