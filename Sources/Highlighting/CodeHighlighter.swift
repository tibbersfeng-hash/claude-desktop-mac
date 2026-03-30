// CodeHighlighter.swift
// Claude Desktop Mac - Code Syntax Highlighting
//
// Provides syntax highlighting for code blocks

import SwiftUI
import Combine
import Theme

// MARK: - Code Highlighter

/// Provides syntax highlighting for code
public final class CodeHighlighter: Sendable {

    // MARK: - Singleton

    public static let shared = CodeHighlighter()

    // MARK: - Properties

    private let highlightQueue = DispatchQueue(label: "com.claudedesktop.highlighting", qos: .userInitiated)

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Highlight code with the given language and theme
    public func highlight(_ code: String, language: CodeLanguage?, theme: CodeTheme) async -> AttributedString {
        return await withCheckedContinuation { continuation in
            highlightQueue.async {
                let result = self.performHighlight(code: code, language: language, theme: theme)
                continuation.resume(returning: result)
            }
        }
    }

    /// Highlight code synchronously (for small code blocks)
    public func highlightSync(_ code: String, language: CodeLanguage?, theme: CodeTheme) -> AttributedString {
        performHighlight(code: code, language: language, theme: theme)
    }

    // MARK: - Private Methods

    private func performHighlight(code: String, language: CodeLanguage?, theme: CodeTheme) -> AttributedString {
        guard let language = language else {
            // No language specified, return plain text
            return plainAttributedString(code, theme: theme)
        }

        // Apply syntax highlighting based on language
        let highlighted = applySyntaxHighlighting(code: code, language: language, theme: theme)
        return highlighted
    }

    private func plainAttributedString(_ code: String, theme: CodeTheme) -> AttributedString {
        var result = AttributedString(code)
        result.font = .codeBlock
        result.foregroundColor = Color(hex: theme.colors.foreground)
        return result
    }

    private func applySyntaxHighlighting(code: String, language: CodeLanguage, theme: CodeTheme) -> AttributedString {
        var result = AttributedString(code)

        // Get language-specific keywords and patterns
        let patterns = syntaxPatterns(for: language)

        // Apply highlighting patterns
        for pattern in patterns {
            highlightPattern(&result, pattern: pattern, code: code, theme: theme)
        }

        return result
    }

    private func highlightPattern(
        _ result: inout AttributedString,
        pattern: SyntaxPattern,
        code: String,
        theme: CodeTheme
    ) {
        let nsRange = NSRange(code.startIndex..., in: code)

        guard let regex = try? NSRegularExpression(pattern: pattern.regex, options: pattern.options) else {
            return
        }

        let matches = regex.matches(in: code, options: [], range: nsRange)

        for match in matches.reversed() {
            guard let range = Range(match.range, in: code) else { continue }

            let attrRange = AttributedString.Index(range.lowerBound, within: result)!
                ..< AttributedString.Index(range.upperBound, within: result)!

            let color = colorForToken(pattern.tokenType, theme: theme)
            result[attrRange].foregroundColor = color

            if pattern.tokenType == .keyword || pattern.tokenType == .type {
                result[attrRange].font = .system(size: 13, weight: .medium, design: .monospaced)
            }
        }
    }

    private func colorForToken(_ tokenType: TokenType, theme: CodeTheme) -> Color {
        switch tokenType {
        case .keyword:
            return Color(hex: theme.colors.keyword)
        case .string:
            return Color(hex: theme.colors.string)
        case .comment:
            return Color(hex: theme.colors.comment)
        case .function:
            return Color(hex: theme.colors.function)
        case .variable:
            return Color(hex: theme.colors.variable)
        case .number:
            return Color(hex: theme.colors.number)
        case .type:
            return Color(hex: theme.colors.type)
        case .operator_:
            return Color(hex: theme.colors.operator_)
        case .punctuation:
            return Color(hex: theme.colors.punctuation)
        }
    }

    // MARK: - Syntax Patterns

    private struct SyntaxPattern {
        let regex: String
        let tokenType: TokenType
        let options: NSRegularExpression.Options

        init(regex: String, tokenType: TokenType, options: NSRegularExpression.Options = []) {
            self.regex = regex
            self.tokenType = tokenType
            self.options = options
        }
    }

    private enum TokenType {
        case keyword, string, comment, function, variable, number, type, operator_, punctuation
    }

    private func syntaxPatterns(for language: CodeLanguage) -> [SyntaxPattern] {
        switch language {
        case .swift:
            return swiftPatterns
        case .python:
            return pythonPatterns
        case .javascript, .typescript:
            return javascriptPatterns
        case .rust:
            return rustPatterns
        case .go:
            return goPatterns
        case .java:
            return javaPatterns
        case .kotlin:
            return kotlinPatterns
        case .c, .cpp:
            return cppPatterns
        case .csharp:
            return csharpPatterns
        case .ruby:
            return rubyPatterns
        case .json:
            return jsonPatterns
        case .yaml:
            return yamlPatterns
        case .html:
            return htmlPatterns
        case .css, .scss:
            return cssPatterns
        case .sql:
            return sqlPatterns
        case .bash, .shell:
            return bashPatterns
        default:
            return commonPatterns
        }
    }

    // MARK: - Language-Specific Patterns

    private var commonPatterns: [SyntaxPattern] {
        [
            SyntaxPattern(regex: #"//.*$"#, tokenType: .comment, options: .anchorsMatchLines),
            SyntaxPattern(regex: #"/\*[\s\S]*?\*/"#, tokenType: .comment),
            SyntaxPattern(regex: #"(["'])(?:(?!\1)[^\\]|\\.)*?\1"#, tokenType: .string),
            SyntaxPattern(regex: #"\b(\d+\.?\d*)\b"#, tokenType: .number),
        ]
    }

    private var swiftPatterns: [SyntaxPattern] {
        [
            // Comments
            SyntaxPattern(regex: #"//.*$"#, tokenType: .comment, options: .anchorsMatchLines),
            SyntaxPattern(regex: #"/\*[\s\S]*?\*/"#, tokenType: .comment),

            // Strings
            SyntaxPattern(regex: #""[^"]*?""#, tokenType: .string),
            SyntaxPattern(regex: #"\"[^\"]*\""#, tokenType: .string),

            // Keywords
            SyntaxPattern(regex: #"\b(func|let|var|if|else|switch|case|default|for|while|do|repeat|break|continue|return|throw|try|catch|import|class|struct|enum|protocol|extension|init|deinit|subscript|typealias|associatedtype|public|private|fileprivate|internal|open|static|final|override|mutating|nonmutating|lazy|weak|unowned|guard|defer|async|await|actor|some|any|inout|self|Self|true|false|nil|in|as|is)\b"#, tokenType: .keyword),

            // Types
            SyntaxPattern(regex: #"\b([A-Z][a-zA-Z0-9_]*)\b"#, tokenType: .type),

            // Functions
            SyntaxPattern(regex: #"\b([a-z_][a-zA-Z0-9_]*)\s*\("#, tokenType: .function),

            // Numbers
            SyntaxPattern(regex: #"\b(\d+\.?\d*[eE]?[+-]?\d*)\b"#, tokenType: .number),
        ]
    }

    private var pythonPatterns: [SyntaxPattern] {
        [
            // Comments
            SyntaxPattern(regex: #"#.*$"#, tokenType: .comment, options: .anchorsMatchLines),
            SyntaxPattern(regex: #"'''[\s\S]*?'''"#, tokenType: .string),
            SyntaxPattern(regex: #"""[\s\S]*?"""#, tokenType: .string),

            // Strings
            SyntaxPattern(regex: #"(["'])(?:(?!\1)[^\\]|\\.)*?\1"#, tokenType: .string),

            // Keywords
            SyntaxPattern(regex: #"\b(def|class|if|elif|else|for|while|try|except|finally|with|as|import|from|return|yield|raise|break|continue|pass|lambda|and|or|not|in|is|None|True|False|global|nonlocal|assert|del|async|await|match|case)\b"#, tokenType: .keyword),

            // Built-in types
            SyntaxPattern(regex: #"\b(int|float|str|list|dict|set|tuple|bool|bytes|None)\b"#, tokenType: .type),

            // Functions
            SyntaxPattern(regex: #"\b([a-z_][a-zA-Z0-9_]*)\s*\("#, tokenType: .function),

            // Numbers
            SyntaxPattern(regex: #"\b(\d+\.?\d*[eE]?[+-]?\d*)\b"#, tokenType: .number),
        ]
    }

    private var javascriptPatterns: [SyntaxPattern] {
        [
            // Comments
            SyntaxPattern(regex: #"//.*$"#, tokenType: .comment, options: .anchorsMatchLines),
            SyntaxPattern(regex: #"/\*[\s\S]*?\*/"#, tokenType: .comment),

            // Strings
            SyntaxPattern(regex: #"(["'`])(?:(?!\1)[^\\]|\\.)*?\1"#, tokenType: .string),

            // Keywords
            SyntaxPattern(regex: #"\b(function|const|let|var|if|else|switch|case|default|for|while|do|break|continue|return|throw|try|catch|finally|class|extends|new|this|super|import|export|from|async|await|yield|static|get|set|of|in|instanceof|typeof|delete|void|null|undefined|true|false|interface|type|enum|implements|private|protected|public|readonly|abstract|as|namespace|module|declare)\b"#, tokenType: .keyword),

            // Types (for TypeScript)
            SyntaxPattern(regex: #"\b([A-Z][a-zA-Z0-9_]*)\b"#, tokenType: .type),

            // Functions
            SyntaxPattern(regex: #"\b([a-z_][a-zA-Z0-9_]*)\s*\("#, tokenType: .function),

            // Numbers
            SyntaxPattern(regex: #"\b(\d+\.?\d*[eE]?[+-]?\d*)\b"#, tokenType: .number),
        ]
    }

    private var rustPatterns: [SyntaxPattern] {
        [
            // Comments
            SyntaxPattern(regex: #"//.*$"#, tokenType: .comment, options: .anchorsMatchLines),
            SyntaxPattern(regex: #"/\*[\s\S]*?\*/"#, tokenType: .comment),

            // Strings
            SyntaxPattern(regex: #"(["'])(?:(?!\1)[^\\]|\\.)*?\1"#, tokenType: .string),

            // Keywords
            SyntaxPattern(regex: #"\b(fn|let|mut|const|static|if|else|match|for|while|loop|break|continue|return|pub|mod|use|crate|self|Self|super|struct|enum|impl|trait|type|where|as|in|unsafe|extern|ref|move|async|await|dyn|box|ref|true|false|Some|None|Ok|Err)\b"#, tokenType: .keyword),

            // Types
            SyntaxPattern(regex: #"\b([A-Z][a-zA-Z0-9_]*)\b"#, tokenType: .type),

            // Functions
            SyntaxPattern(regex: #"\b([a-z_][a-zA-Z0-9_]*)\s*\("#, tokenType: .function),

            // Numbers
            SyntaxPattern(regex: #"\b(\d+\.?\d*[eE]?[+-]?\d*)\b"#, tokenType: .number),
        ]
    }

    private var goPatterns: [SyntaxPattern] {
        [
            // Comments
            SyntaxPattern(regex: #"//.*$"#, tokenType: .comment, options: .anchorsMatchLines),
            SyntaxPattern(regex: #"/\*[\s\S]*?\*/"#, tokenType: .comment),

            // Strings
            SyntaxPattern(regex: #"(["'`])(?:(?!\1)[^\\]|\\.)*?\1"#, tokenType: .string),

            // Keywords
            SyntaxPattern(regex: #"\b(func|var|const|type|struct|interface|map|chan|if|else|switch|case|default|for|range|break|continue|return|goto|fallthrough|defer|go|select|package|import|true|false|nil|iota)\b"#, tokenType: .keyword),

            // Types
            SyntaxPattern(regex: #"\b([A-Z][a-zA-Z0-9_]*)\b"#, tokenType: .type),

            // Functions
            SyntaxPattern(regex: #"\b([a-z_][a-zA-Z0-9_]*)\s*\("#, tokenType: .function),

            // Numbers
            SyntaxPattern(regex: #"\b(\d+\.?\d*[eE]?[+-]?\d*)\b"#, tokenType: .number),
        ]
    }

    private var javaPatterns: [SyntaxPattern] {
        [
            // Comments
            SyntaxPattern(regex: #"//.*$"#, tokenType: .comment, options: .anchorsMatchLines),
            SyntaxPattern(regex: #"/\*[\s\S]*?\*/"#, tokenType: .comment),

            // Strings
            SyntaxPattern(regex: #"\"[^\"]*\""#, tokenType: .string),

            // Keywords
            SyntaxPattern(regex: #"\b(public|private|protected|static|final|abstract|class|interface|enum|extends|implements|new|this|super|if|else|switch|case|default|for|while|do|break|continue|return|throw|throws|try|catch|finally|import|package|void|int|long|short|byte|float|double|boolean|char|null|true|false|instanceof|synchronized|volatile|transient|native|strictfp|const|goto|record|sealed|permits|var)\b"#, tokenType: .keyword),

            // Types
            SyntaxPattern(regex: #"\b([A-Z][a-zA-Z0-9_]*)\b"#, tokenType: .type),

            // Functions
            SyntaxPattern(regex: #"\b([a-z_][a-zA-Z0-9_]*)\s*\("#, tokenType: .function),

            // Numbers
            SyntaxPattern(regex: #"\b(\d+\.?\d*[eE]?[+-]?\d*[fFdDlL]?)\b"#, tokenType: .number),
        ]
    }

    private var kotlinPatterns: [SyntaxPattern] {
        [
            // Comments
            SyntaxPattern(regex: #"//.*$"#, tokenType: .comment, options: .anchorsMatchLines),
            SyntaxPattern(regex: #"/\*[\s\S]*?\*/"#, tokenType: .comment),

            // Strings
            SyntaxPattern(regex: #"\"[^\"]*\""#, tokenType: .string),

            // Keywords
            SyntaxPattern(regex: #"\b(fun|val|var|class|interface|object|data|sealed|enum|annotation|inner|open|final|abstract|override|public|private|protected|internal|lateinit|companion|companion object|if|else|when|for|while|do|break|continue|return|throw|try|catch|finally|import|package|is|as|in|typeof|null|true|false|suspend|inline|noinline|crossinline|reified|tailrec|operator|infix|external|const|vararg|suspend|init|constructor|by|where|typealias|suspend|context)\b"#, tokenType: .keyword),

            // Types
            SyntaxPattern(regex: #"\b([A-Z][a-zA-Z0-9_]*)\b"#, tokenType: .type),

            // Functions
            SyntaxPattern(regex: #"\b([a-z_][a-zA-Z0-9_]*)\s*\("#, tokenType: .function),

            // Numbers
            SyntaxPattern(regex: #"\b(\d+\.?\d*[eE]?[+-]?\d*[fFdDlL]?)\b"#, tokenType: .number),
        ]
    }

    private var cppPatterns: [SyntaxPattern] {
        [
            // Comments
            SyntaxPattern(regex: #"//.*$"#, tokenType: .comment, options: .anchorsMatchLines),
            SyntaxPattern(regex: #"/\*[\s\S]*?\*/"#, tokenType: .comment),

            // Strings
            SyntaxPattern(regex: #"\"[^\"]*\""#, tokenType: .string),

            // Keywords
            SyntaxPattern(regex: #"\b(auto|break|case|class|const|continue|default|delete|do|else|enum|explicit|extern|for|friend|goto|if|inline|namespace|new|operator|private|protected|public|return|sizeof|static|struct|switch|template|this|throw|try|typedef|typename|union|using|virtual|void|volatile|while|nullptr|constexpr|decltype|noexcept|override|final|nullptr|thread_local|alignas|alignof|static_assert|and|or|not|bitand|bitor|xor|compl|and_eq|or_eq|xor_eq|not_eq|true|false)\b"#, tokenType: .keyword),

            // Types
            SyntaxPattern(regex: #"\b([A-Z][a-zA-Z0-9_]*)\b"#, tokenType: .type),
            SyntaxPattern(regex: #"\b(int|char|float|double|long|short|unsigned|signed|bool|wchar_t|char16_t|char32_t|size_t|int8_t|int16_t|int32_t|int64_t|uint8_t|uint16_t|uint32_t|uint64_t)\b"#, tokenType: .type),

            // Functions
            SyntaxPattern(regex: #"\b([a-z_][a-zA-Z0-9_]*)\s*\("#, tokenType: .function),

            // Numbers
            SyntaxPattern(regex: #"\b(\d+\.?\d*[eE]?[+-]?\d*[fFuUlL]*)\b"#, tokenType: .number),
        ]
    }

    private var csharpPatterns: [SyntaxPattern] {
        [
            // Comments
            SyntaxPattern(regex: #"//.*$"#, tokenType: .comment, options: .anchorsMatchLines),
            SyntaxPattern(regex: #"/\*[\s\S]*?\*/"#, tokenType: .comment),

            // Strings
            SyntaxPattern(regex: #"\"[^\"]*\""#, tokenType: .string),
            SyntaxPattern(regex: #"@\\"[^\"]*\""#, tokenType: .string),

            // Keywords
            SyntaxPattern(regex: #"\b(abstract|as|base|bool|break|byte|case|catch|char|checked|class|const|continue|decimal|default|delegate|do|double|else|enum|event|explicit|extern|false|finally|fixed|float|for|foreach|goto|if|implicit|in|int|interface|internal|is|lock|long|namespace|new|null|object|operator|out|override|params|private|protected|public|readonly|ref|return|sbyte|sealed|short|sizeof|stackalloc|static|string|struct|switch|this|throw|true|try|typeof|uint|ulong|unchecked|unsafe|ushort|using|virtual|void|volatile|while|async|await|dynamic|var|record|init|required|nint|nuint|partial|get|set|value|add|remove|global|alias|select|from|where|join|orderby|group|by|into|let|ascending|descending|equals|on)\b"#, tokenType: .keyword),

            // Types
            SyntaxPattern(regex: #"\b([A-Z][a-zA-Z0-9_]*)\b"#, tokenType: .type),

            // Functions
            SyntaxPattern(regex: #"\b([a-z_][a-zA-Z0-9_]*)\s*\("#, tokenType: .function),

            // Numbers
            SyntaxPattern(regex: #"\b(\d+\.?\d*[eE]?[+-]?\d*[mMfFdDlLuU]?)\b"#, tokenType: .number),
        ]
    }

    private var rubyPatterns: [SyntaxPattern] {
        [
            // Comments
            SyntaxPattern(regex: #"#.*$"#, tokenType: .comment, options: .anchorsMatchLines),

            // Strings
            SyntaxPattern(regex: #"(["'])(?:(?!\1)[^\\]|\\.)*?\1"#, tokenType: .string),

            // Keywords
            SyntaxPattern(regex: #"\b(begin|end|def|class|module|if|else|elsif|unless|case|when|while|until|for|do|break|next|redo|retry|return|yield|throw|catch|raise|rescue|ensure|require|require_relative|include|extend|attr_reader|attr_writer|attr_accessor|private|protected|public|self|nil|true|false|and|or|not|in|then|alias|defined?|super|lambda|proc|END|BEGIN|__END__|__FILE__|__LINE__|__ENCODING__)\b"#, tokenType: .keyword),

            // Types
            SyntaxPattern(regex: #"\b([A-Z][a-zA-Z0-9_]*)\b"#, tokenType: .type),

            // Functions
            SyntaxPattern(regex: #"\b([a-z_][a-zA-Z0-9_!?]*)\b"#, tokenType: .function),

            // Numbers
            SyntaxPattern(regex: #"\b(\d+\.?\d*[eE]?[+-]?\d*)\b"#, tokenType: .number),
        ]
    }

    private var jsonPatterns: [SyntaxPattern] {
        [
            // Strings (keys and values)
            SyntaxPattern(regex: #"\"[^\"]*\""#, tokenType: .string),

            // Numbers
            SyntaxPattern(regex: #"\b(-?\d+\.?\d*[eE]?[+-]?\d*)\b"#, tokenType: .number),

            // Booleans and null
            SyntaxPattern(regex: #"\b(true|false|null)\b"#, tokenType: .keyword),
        ]
    }

    private var yamlPatterns: [SyntaxPattern] {
        [
            // Comments
            SyntaxPattern(regex: #"#.*$"#, tokenType: .comment, options: .anchorsMatchLines),

            // Strings
            SyntaxPattern(regex: #"(["'])(?:(?!\1)[^\\]|\\.)*?\1"#, tokenType: .string),

            // Keys
            SyntaxPattern(regex: #"^[\s]*([a-zA-Z_][a-zA-Z0-9_]*):"#, tokenType: .keyword, options: .anchorsMatchLines),

            // Numbers
            SyntaxPattern(regex: #"\b(-?\d+\.?\d*[eE]?[+-]?\d*)\b"#, tokenType: .number),

            // Booleans and null
            SyntaxPattern(regex: #"\b(true|false|null|yes|no|on|off|~)\b"#, tokenType: .keyword),
        ]
    }

    private var htmlPatterns: [SyntaxPattern] {
        [
            // Comments
            SyntaxPattern(regex: #"<!--[\s\S]*?-->"#, tokenType: .comment),

            // Tags
            SyntaxPattern(regex: #"</?([a-zA-Z][a-zA-Z0-9]*)"#, tokenType: .keyword),

            // Attributes
            SyntaxPattern(regex: #"\b([a-zA-Z_-][a-zA-Z0-9_-]*)\s*="#, tokenType: .variable),

            // Strings
            SyntaxPattern(regex: #"(["'])(?:(?!\1)[^\\]|\\.)*?\1"#, tokenType: .string),
        ]
    }

    private var cssPatterns: [SyntaxPattern] {
        [
            // Comments
            SyntaxPattern(regex: #"/\*[\s\S]*?\*/"#, tokenType: .comment),

            // Selectors
            SyntaxPattern(regex: #"([.#]?[a-zA-Z_-][a-zA-Z0-9_-]*)\s*\{"#, tokenType: .type),

            // Properties
            SyntaxPattern(regex: #"([a-zA-Z_-][a-zA-Z0-9_-]*)\s*:"#, tokenType: .keyword),

            // Values/Strings
            SyntaxPattern(regex: #"(["'])(?:(?!\1)[^\\]|\\.)*?\1"#, tokenType: .string),

            // Numbers with units
            SyntaxPattern(regex: #"\b(-?\d+\.?\d*)(px|em|rem|%|vh|vw|deg|s|ms)?\b"#, tokenType: .number),
        ]
    }

    private var sqlPatterns: [SyntaxPattern] {
        [
            // Comments
            SyntaxPattern(regex: #"--.*$"#, tokenType: .comment, options: .anchorsMatchLines),
            SyntaxPattern(regex: #"/\*[\s\S]*?\*/"#, tokenType: .comment),

            // Keywords
            SyntaxPattern(regex: #"\b(SELECT|FROM|WHERE|JOIN|INNER|LEFT|RIGHT|OUTER|ON|AND|OR|NOT|IN|EXISTS|BETWEEN|LIKE|IS|NULL|AS|ORDER|BY|GROUP|HAVING|LIMIT|OFFSET|INSERT|INTO|VALUES|UPDATE|SET|DELETE|CREATE|TABLE|INDEX|VIEW|DROP|ALTER|ADD|COLUMN|CONSTRAINT|PRIMARY|KEY|FOREIGN|REFERENCES|UNIQUE|CHECK|DEFAULT|AUTO_INCREMENT|IDENTITY|CASCADE|RESTRICT|NULL|NOT|TRUE|FALSE|DISTINCT|ALL|UNION|INTERSECT|EXCEPT|CASE|WHEN|THEN|ELSE|END|CAST|CONVERT|COALESCE|NULLIF|IFNULL|NVL|COUNT|SUM|AVG|MIN|MAX|ROUND|FLOOR|CEILING|CONCAT|SUBSTRING|TRIM|UPPER|LOWER|LENGTH|DATE|TIME|DATETIME|TIMESTAMP|YEAR|MONTH|DAY|HOUR|MINUTE|SECOND|NOW|CURRENT_DATE|CURRENT_TIME|CURRENT_TIMESTAMP|DATABASE|SCHEMA|GRANT|REVOKE|COMMIT|ROLLBACK|TRANSACTION|BEGIN|DECLARE|CURSOR|FETCH|OPEN|CLOSE|EXEC|EXECUTE|PROCEDURE|FUNCTION|TRIGGER)\b"#, tokenType: .keyword),

            // Strings
            SyntaxPattern(regex: #"(["'])(?:(?!\1)[^\\]|\\.)*?\1"#, tokenType: .string),

            // Numbers
            SyntaxPattern(regex: #"\b(-?\d+\.?\d*)\b"#, tokenType: .number),

            // Identifiers
            SyntaxPattern(regex: #"`[^`]+`"#, tokenType: .variable),
        ]
    }

    private var bashPatterns: [SyntaxPattern] {
        [
            // Comments
            SyntaxPattern(regex: #"#.*$"#, tokenType: .comment, options: .anchorsMatchLines),

            // Strings
            SyntaxPattern(regex: #"(["'])(?:(?!\1)[^\\]|\\.)*?\1"#, tokenType: .string),

            // Keywords
            SyntaxPattern(regex: #"\b(if|then|else|elif|fi|for|while|do|done|case|esac|in|function|return|exit|break|continue|local|export|source|alias|unalias|set|unset|shift|read|echo|printf|test|true|false|null|cd|pwd|ls|mkdir|rmdir|rm|cp|mv|cat|grep|sed|awk|find|xargs|sort|uniq|head|tail|wc|chmod|chown|sudo|apt|yum|brew|git|npm|yarn|pip|cargo|go|rustc|python|python3|ruby|node|java|javac|swift|clang|gcc|make|cmake|docker|kubectl|helm|terraform|ansible|ssh|scp|rsync|curl|wget|tar|zip|unzip)\b"#, tokenType: .keyword),

            // Variables
            SyntaxPattern(regex: #"\$[a-zA-Z_][a-zA-Z0-9_]*"#, tokenType: .variable),
            SyntaxPattern(regex: #"\$\{[^}]+\}"#, tokenType: .variable),

            // Numbers
            SyntaxPattern(regex: #"\b(\d+)\b"#, tokenType: .number),
        ]
    }
}

// MARK: - Code Block View

/// A view that displays highlighted code with line numbers
public struct HighlightedCodeBlock: View {
    @Environment(\.colorScheme) private var colorScheme

    let code: String
    let language: CodeLanguage?
    let theme: CodeTheme

    @State private var highlightedCode: AttributedString?
    @State private var isHovered = false
    @State private var showCopied = false
    @State private var isExpanded = true

    public init(code: String, language: CodeLanguage? = nil, theme: CodeTheme? = nil) {
        self.code = code
        self.language = language
        self.theme = theme ?? .default
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerView

            // Code content
            if isExpanded {
                codeContentView
            }
        }
        .background(Color(hex: theme.colors.background))
        .cornerRadius(CornerRadius.md.rawValue)
        .task {
            highlightedCode = await CodeHighlighter.shared.highlight(code, language: language, theme: theme)
        }
        .onHover { isHovered = $0 }
    }

    private var headerView: some View {
        HStack {
            // Language label
            if let language = language {
                Text(language.displayName)
                    .font(.captionText)
                    .foregroundColor(Color(hex: theme.colors.foreground).opacity(0.7))
            }

            Spacer()

            // Line count
            Text("\(lineCount) lines")
                .font(.caption2)
                .foregroundColor(Color(hex: theme.colors.foreground).opacity(0.5))

            // Expand/Collapse button
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 12))
            }
            .buttonStyle(.icon(size: 20))
            .foregroundColor(Color(hex: theme.colors.foreground).opacity(0.7))

            // Copy button
            if isHovered {
                Button(action: copyCode) {
                    if showCopied {
                        Label("Copied!", systemImage: "checkmark")
                    } else {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
                .font(.captionText)
                .foregroundColor(Color(hex: theme.colors.foreground).opacity(0.7))
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.md.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
        .background(Color(hex: theme.colors.background).opacity(0.8))
    }

    private var codeContentView: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: 0) {
                // Line numbers
                lineNumbersView

                // Code
                codeTextView
            }
            .padding(.horizontal, Spacing.md.rawValue)
            .padding(.vertical, Spacing.sm.rawValue)
        }
        .frame(maxHeight: maxHeight)
    }

    private var lineNumbersView: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(1...lineCount, id: \.self) { lineNum in
                Text("\(lineNum)")
                    .font(.codeBlock)
                    .foregroundColor(Color(hex: theme.colors.foreground).opacity(0.4))
                    .frame(minWidth: 24, alignment: .trailing)
            }
        }
        .padding(.trailing, Spacing.md.rawValue)
    }

    private var codeTextView: some View {
        Group {
            if let highlighted = highlightedCode {
                Text(highlighted)
            } else {
                Text(code)
                    .font(.codeBlock)
                    .foregroundColor(Color(hex: theme.colors.foreground))
            }
        }
        .textSelection(.enabled)
    }

    private var lineCount: Int {
        max(code.components(separatedBy: "\n").count, 1)
    }

    private var maxHeight: CGFloat? {
        lineCount > 20 ? 400 : nil
    }

    private func copyCode() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(code, forType: .string)

        showCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopied = false
        }
    }
}
