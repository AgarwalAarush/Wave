import SwiftUI

struct SyntaxHighlighter {

    // MARK: - Token Types

    enum TokenType {
        case plain
        case keyword
        case string
        case comment
        case number
        case type
        case function
        case preprocessor
    }

    struct Token {
        let text: String
        let type: TokenType
    }

    // MARK: - Language Keywords

    private static let swiftKeywords: Set<String> = [
        "import", "class", "struct", "enum", "protocol", "extension", "func", "var", "let",
        "if", "else", "guard", "switch", "case", "default", "for", "while", "repeat",
        "return", "throw", "throws", "try", "catch", "do", "break", "continue", "fallthrough",
        "where", "in", "as", "is", "nil", "true", "false", "self", "Self", "super",
        "init", "deinit", "get", "set", "willSet", "didSet", "subscript", "static",
        "override", "final", "private", "fileprivate", "internal", "public", "open",
        "mutating", "nonmutating", "lazy", "weak", "unowned", "inout", "some", "any",
        "async", "await", "actor", "nonisolated", "isolated", "@Published", "@State",
        "@Binding", "@ObservedObject", "@StateObject", "@Environment", "@MainActor"
    ]

    private static let swiftTypes: Set<String> = [
        "Int", "String", "Bool", "Double", "Float", "Array", "Dictionary", "Set",
        "Optional", "Result", "Error", "Void", "Any", "AnyObject", "Never",
        "CGFloat", "CGPoint", "CGSize", "CGRect", "Color", "View", "Text", "Image",
        "Button", "VStack", "HStack", "ZStack", "List", "ScrollView", "NavigationView"
    ]

    private static let pythonKeywords: Set<String> = [
        "and", "as", "assert", "async", "await", "break", "class", "continue", "def",
        "del", "elif", "else", "except", "finally", "for", "from", "global", "if",
        "import", "in", "is", "lambda", "nonlocal", "not", "or", "pass", "raise",
        "return", "try", "while", "with", "yield", "True", "False", "None", "self"
    ]

    private static let jsKeywords: Set<String> = [
        "break", "case", "catch", "class", "const", "continue", "debugger", "default",
        "delete", "do", "else", "export", "extends", "finally", "for", "function",
        "if", "import", "in", "instanceof", "let", "new", "return", "super", "switch",
        "this", "throw", "try", "typeof", "var", "void", "while", "with", "yield",
        "async", "await", "static", "get", "set", "true", "false", "null", "undefined"
    ]

    private static let cppKeywords: Set<String> = [
        "alignas", "alignof", "and", "and_eq", "asm", "auto", "bitand", "bitor",
        "bool", "break", "case", "catch", "char", "char8_t", "char16_t", "char32_t",
        "class", "compl", "concept", "const", "consteval", "constexpr", "constinit",
        "const_cast", "continue", "co_await", "co_return", "co_yield", "decltype",
        "default", "delete", "do", "double", "dynamic_cast", "else", "enum", "explicit",
        "export", "extern", "false", "float", "for", "friend", "goto", "if", "inline",
        "int", "long", "mutable", "namespace", "new", "noexcept", "not", "not_eq",
        "nullptr", "operator", "or", "or_eq", "private", "protected", "public",
        "register", "reinterpret_cast", "requires", "return", "short", "signed",
        "sizeof", "static", "static_assert", "static_cast", "struct", "switch",
        "template", "this", "thread_local", "throw", "true", "try", "typedef",
        "typeid", "typename", "union", "unsigned", "using", "virtual", "void",
        "volatile", "wchar_t", "while", "xor", "xor_eq", "override", "final",
        "#include", "#define", "#ifdef", "#ifndef", "#endif", "#pragma", "#if", "#else"
    ]

    private static let cppTypes: Set<String> = [
        "vector", "string", "map", "set", "unordered_map", "unordered_set", "list",
        "deque", "queue", "stack", "pair", "tuple", "array", "bitset", "optional",
        "variant", "any", "span", "string_view", "unique_ptr", "shared_ptr", "weak_ptr",
        "size_t", "ptrdiff_t", "int8_t", "int16_t", "int32_t", "int64_t",
        "uint8_t", "uint16_t", "uint32_t", "uint64_t"
    ]

    private static let goKeywords: Set<String> = [
        "break", "case", "chan", "const", "continue", "default", "defer", "else",
        "fallthrough", "for", "func", "go", "goto", "if", "import", "interface",
        "map", "package", "range", "return", "select", "struct", "switch", "type",
        "var", "true", "false", "nil", "iota", "append", "cap", "close", "complex",
        "copy", "delete", "imag", "len", "make", "new", "panic", "print", "println",
        "real", "recover"
    ]

    private static let rustKeywords: Set<String> = [
        "as", "async", "await", "break", "const", "continue", "crate", "dyn", "else",
        "enum", "extern", "false", "fn", "for", "if", "impl", "in", "let", "loop",
        "match", "mod", "move", "mut", "pub", "ref", "return", "self", "Self", "static",
        "struct", "super", "trait", "true", "type", "unsafe", "use", "where", "while",
        "Box", "Option", "Result", "Some", "None", "Ok", "Err", "Vec", "String"
    ]

    // MARK: - Highlighting

    static func highlight(code: String, language: String?) -> AttributedString {
        let lang = language?.lowercased() ?? ""
        let tokens = tokenize(code: code, language: lang)
        return buildAttributedString(from: tokens)
    }

    private static func tokenize(code: String, language: String) -> [Token] {
        var tokens: [Token] = []
        var currentIndex = code.startIndex

        let keywords = getKeywords(for: language)
        let types = getTypes(for: language)
        let commentStyle = getCommentStyle(for: language)

        while currentIndex < code.endIndex {
            let remaining = String(code[currentIndex...])

            // Check for single-line comment
            if let commentPrefix = commentStyle.single, remaining.hasPrefix(commentPrefix) {
                let endIndex = remaining.firstIndex(of: "\n") ?? remaining.endIndex
                let comment = String(remaining[..<endIndex])
                tokens.append(Token(text: comment, type: .comment))
                currentIndex = code.index(currentIndex, offsetBy: comment.count)
                continue
            }

            // Check for multi-line comment
            if let (start, end) = commentStyle.multi, remaining.hasPrefix(start) {
                if let endRange = remaining.range(of: end, range: remaining.index(after: remaining.startIndex)..<remaining.endIndex) {
                    let comment = String(remaining[..<endRange.upperBound])
                    tokens.append(Token(text: comment, type: .comment))
                    currentIndex = code.index(currentIndex, offsetBy: comment.count)
                } else {
                    // Unclosed comment, treat rest as comment
                    tokens.append(Token(text: remaining, type: .comment))
                    break
                }
                continue
            }

            // Check for preprocessor directives (C/C++)
            if (language == "c" || language == "cpp" || language == "c++") && remaining.hasPrefix("#") {
                let endIndex = remaining.firstIndex(of: "\n") ?? remaining.endIndex
                let directive = String(remaining[..<endIndex])
                tokens.append(Token(text: directive, type: .preprocessor))
                currentIndex = code.index(currentIndex, offsetBy: directive.count)
                continue
            }

            // Check for strings (double quotes)
            if remaining.hasPrefix("\"") {
                if let stringEnd = findStringEnd(in: remaining, quote: "\"") {
                    let str = String(remaining[..<stringEnd])
                    tokens.append(Token(text: str, type: .string))
                    currentIndex = code.index(currentIndex, offsetBy: str.count)
                    continue
                }
            }

            // Check for strings (single quotes)
            if remaining.hasPrefix("'") {
                if let stringEnd = findStringEnd(in: remaining, quote: "'") {
                    let str = String(remaining[..<stringEnd])
                    tokens.append(Token(text: str, type: .string))
                    currentIndex = code.index(currentIndex, offsetBy: str.count)
                    continue
                }
            }

            // Check for template strings (JS/TS)
            if (language == "javascript" || language == "js" || language == "typescript" || language == "ts") && remaining.hasPrefix("`") {
                if let stringEnd = findStringEnd(in: remaining, quote: "`") {
                    let str = String(remaining[..<stringEnd])
                    tokens.append(Token(text: str, type: .string))
                    currentIndex = code.index(currentIndex, offsetBy: str.count)
                    continue
                }
            }

            // Check for numbers
            if let firstChar = remaining.first, firstChar.isNumber || (firstChar == "." && remaining.dropFirst().first?.isNumber == true) {
                let number = extractNumber(from: remaining)
                tokens.append(Token(text: number, type: .number))
                currentIndex = code.index(currentIndex, offsetBy: number.count)
                continue
            }

            // Check for identifiers (keywords, types, functions)
            if let firstChar = remaining.first, firstChar.isLetter || firstChar == "_" || firstChar == "@" {
                let identifier = extractIdentifier(from: remaining)
                let tokenType: TokenType
                if keywords.contains(identifier) {
                    tokenType = .keyword
                } else if types.contains(identifier) {
                    tokenType = .type
                } else if remaining.dropFirst(identifier.count).first == "(" {
                    tokenType = .function
                } else {
                    tokenType = .plain
                }
                tokens.append(Token(text: identifier, type: tokenType))
                currentIndex = code.index(currentIndex, offsetBy: identifier.count)
                continue
            }

            // Default: plain character
            tokens.append(Token(text: String(remaining.first!), type: .plain))
            currentIndex = code.index(after: currentIndex)
        }

        return tokens
    }

    private static func getKeywords(for language: String) -> Set<String> {
        switch language {
        case "swift": return swiftKeywords
        case "python", "py": return pythonKeywords
        case "javascript", "js", "typescript", "ts": return jsKeywords
        case "c", "cpp", "c++", "objc", "objective-c": return cppKeywords
        case "go", "golang": return goKeywords
        case "rust", "rs": return rustKeywords
        default: return swiftKeywords.union(pythonKeywords).union(jsKeywords).union(cppKeywords)
        }
    }

    private static func getTypes(for language: String) -> Set<String> {
        switch language {
        case "swift": return swiftTypes
        case "c", "cpp", "c++": return cppTypes
        default: return swiftTypes.union(cppTypes)
        }
    }

    private static func getCommentStyle(for language: String) -> (single: String?, multi: (String, String)?) {
        switch language {
        case "python", "py", "bash", "sh", "zsh", "shell":
            return ("#", nil)
        case "html", "xml":
            return (nil, ("<!--", "-->"))
        default:
            return ("//", ("/*", "*/"))
        }
    }

    private static func findStringEnd(in text: String, quote: String) -> String.Index? {
        var index = text.index(after: text.startIndex)
        var escaped = false

        while index < text.endIndex {
            let char = text[index]
            if escaped {
                escaped = false
            } else if char == "\\" {
                escaped = true
            } else if String(char) == quote {
                return text.index(after: index)
            }
            index = text.index(after: index)
        }

        return nil
    }

    private static func extractNumber(from text: String) -> String {
        var result = ""
        var hasDecimal = false
        var hasExponent = false

        for (i, char) in text.enumerated() {
            if char.isNumber {
                result.append(char)
            } else if char == "." && !hasDecimal && !hasExponent {
                hasDecimal = true
                result.append(char)
            } else if (char == "e" || char == "E") && !hasExponent && i > 0 {
                hasExponent = true
                result.append(char)
            } else if (char == "+" || char == "-") && hasExponent && result.last?.lowercased() == "e" {
                result.append(char)
            } else if char == "x" || char == "X" || char == "b" || char == "B" || char == "o" || char == "O" {
                // Hex, binary, octal prefixes
                if result == "0" {
                    result.append(char)
                } else {
                    break
                }
            } else if char.isHexDigit && (result.contains("x") || result.contains("X")) {
                result.append(char)
            } else if char == "_" {
                // Number separator (Swift, Rust, etc.)
                result.append(char)
            } else {
                break
            }
        }

        return result.isEmpty ? String(text.first!) : result
    }

    private static func extractIdentifier(from text: String) -> String {
        var result = ""
        for char in text {
            if char.isLetter || char.isNumber || char == "_" || char == "@" {
                result.append(char)
            } else {
                break
            }
        }
        return result
    }

    private static func buildAttributedString(from tokens: [Token]) -> AttributedString {
        var result = AttributedString()

        for token in tokens {
            var attributed = AttributedString(token.text)
            attributed.foregroundColor = color(for: token.type)
            result.append(attributed)
        }

        return result
    }

    private static func color(for tokenType: TokenType) -> Color {
        switch tokenType {
        case .plain:
            return Color.waveCodeText
        case .keyword:
            return Color.waveCodeKeyword
        case .string:
            return Color.waveCodeString
        case .comment:
            return Color.waveCodeComment
        case .number:
            return Color.waveCodeNumber
        case .type:
            return Color.waveCodeType
        case .function:
            return Color.waveCodeFunction
        case .preprocessor:
            return Color.waveCodePreprocessor
        }
    }
}

// MARK: - Character Extension

private extension Character {
    var isHexDigit: Bool {
        return isNumber || ("a"..."f").contains(lowercased().first ?? "g") || ("A"..."F").contains(self)
    }
}
