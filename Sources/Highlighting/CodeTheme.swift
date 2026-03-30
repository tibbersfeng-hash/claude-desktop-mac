// CodeTheme.swift
// Claude Desktop Mac - Code Theme Definitions
//
// Defines code syntax highlighting themes

import SwiftUI

// MARK: - Code Theme

/// Represents a code syntax highlighting theme
public struct CodeTheme: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let isDark: Bool
    public let colors: ThemeColors

    public init(id: String, name: String, isDark: Bool, colors: ThemeColors) {
        self.id = id
        self.name = name
        self.isDark = isDark
        self.colors = colors
    }

    /// Theme color definitions
    public struct ThemeColors: Codable, Hashable, Sendable {
        public let background: String
        public let foreground: String
        public let keyword: String
        public let string: String
        public let comment: String
        public let function: String
        public let variable: String
        public let number: String
        public let type: String
        public let operator_: String
        public let punctuation: String

        public init(
            background: String,
            foreground: String,
            keyword: String,
            string: String,
            comment: String,
            function: String,
            variable: String,
            number: String,
            type: String,
            operator_: String,
            punctuation: String
        ) {
            self.background = background
            self.foreground = foreground
            self.keyword = keyword
            self.string = string
            self.comment = comment
            self.function = function
            self.variable = variable
            self.number = number
            self.type = type
            self.operator_ = operator_
            self.punctuation = punctuation
        }

        /// Convert hex string to Color
        public func color(for key: String) -> Color {
            Color(hex: key)
        }
    }
}

// MARK: - Built-in Themes

extension CodeTheme {
    /// One Dark theme (Atom-style dark theme)
    public static let oneDark = CodeTheme(
        id: "one-dark",
        name: "One Dark",
        isDark: true,
        colors: ThemeColors(
            background: "282C34",
            foreground: "ABB2BF",
            keyword: "C678DD",
            string: "98C379",
            comment: "5C6370",
            function: "61AFEF",
            variable: "E06C75",
            number: "D19A66",
            type: "E5C07B",
            operator_: "56B6C2",
            punctuation: "ABB2BF"
        )
    )

    /// Dracula theme
    public static let dracula = CodeTheme(
        id: "dracula",
        name: "Dracula",
        isDark: true,
        colors: ThemeColors(
            background: "282A36",
            foreground: "F8F8F2",
            keyword: "FF79C6",
            string: "F1FA8C",
            comment: "6272A4",
            function: "50FA7B",
            variable: "FF5555",
            number: "BD93F9",
            type: "8BE9FD",
            operator_: "FF79C6",
            punctuation: "F8F8F2"
        )
    )

    /// Monokai theme
    public static let monokai = CodeTheme(
        id: "monokai",
        name: "Monokai",
        isDark: true,
        colors: ThemeColors(
            background: "272822",
            foreground: "F8F8F2",
            keyword: "F92672",
            string: "E6DB74",
            comment: "75715E",
            function: "A6E22E",
            variable: "FD971F",
            number: "AE81FF",
            type: "66D9EF",
            operator_: "F92672",
            punctuation: "F8F8F2"
        )
    )

    /// Nord theme
    public static let nord = CodeTheme(
        id: "nord",
        name: "Nord",
        isDark: true,
        colors: ThemeColors(
            background: "2E3440",
            foreground: "D8DEE9",
            keyword: "81A1C1",
            string: "A3BE8C",
            comment: "616E88",
            function: "88C0D0",
            variable: "D8DEE9",
            number: "B48EAD",
            type: "8FBCBB",
            operator_: "81A1C1",
            punctuation: "ECEFF4"
        )
    )

    /// GitHub Dark theme
    public static let githubDark = CodeTheme(
        id: "github-dark",
        name: "GitHub Dark",
        isDark: true,
        colors: ThemeColors(
            background: "0D1117",
            foreground: "C9D1D9",
            keyword: "FF7B72",
            string: "A5D6FF",
            comment: "8B949E",
            function: "D2A8FF",
            variable: "FFA657",
            number: "79C0FF",
            type: "7EE787",
            operator_: "FF7B72",
            punctuation: "C9D1D9"
        )
    )

    /// GitHub Light theme
    public static let githubLight = CodeTheme(
        id: "github-light",
        name: "GitHub Light",
        isDark: false,
        colors: ThemeColors(
            background: "FFFFFF",
            foreground: "24292F",
            keyword: "CF222E",
            string: "0A3069",
            comment: "6E7781",
            function: "8250DF",
            variable: "953800",
            number: "0550AE",
            type: "116329",
            operator_: "CF222E",
            punctuation: "24292F"
        )
    )

    /// Solarized Light theme
    public static let solarizedLight = CodeTheme(
        id: "solarized-light",
        name: "Solarized Light",
        isDark: false,
        colors: ThemeColors(
            background: "FDF6E3",
            foreground: "657B83",
            keyword: "859900",
            string: "2AA198",
            comment: "93A1A1",
            function: "268BD2",
            variable: "B58900",
            number: "D33682",
            type: "CB4B16",
            operator_: "859900",
            punctuation: "657B83"
        )
    )

    /// One Light theme
    public static let oneLight = CodeTheme(
        id: "one-light",
        name: "One Light",
        isDark: false,
        colors: ThemeColors(
            background: "FAFAFA",
            foreground: "383A42",
            keyword: "A626A4",
            string: "50A14F",
            comment: "A0A1A7",
            function: "4078F2",
            variable: "E45649",
            number: "986801",
            type: "C18401",
            operator_: "0184BC",
            punctuation: "383A42"
        )
    )

    /// All available themes
    public static let allThemes: [CodeTheme] = [
        oneDark, dracula, monokai, nord, githubDark,
        githubLight, solarizedLight, oneLight
    ]

    /// Dark themes
    public static let darkThemes: [CodeTheme] = allThemes.filter { $0.isDark }

    /// Light themes
    public static let lightThemes: [CodeTheme] = allThemes.filter { !$0.isDark }

    /// Default theme
    public static let `default`: CodeTheme = oneDark
}

// MARK: - Theme Manager

@MainActor
@Observable
public final class ThemeSettings {
    public static let shared = ThemeSettings()

    public var currentTheme: CodeTheme = .default {
        didSet {
            saveThemePreference()
        }
    }

    public var autoDetectFromSystem: Bool = true {
        didSet {
            saveThemePreference()
        }
    }

    private init() {
        loadThemePreference()
    }

    private func loadThemePreference() {
        if let savedThemeId = UserDefaults.standard.string(forKey: "CodeThemeId"),
           let theme = CodeTheme.allThemes.first(where: { $0.id == savedThemeId }) {
            currentTheme = theme
        }
        autoDetectFromSystem = UserDefaults.standard.bool(forKey: "AutoDetectTheme")
    }

    private func saveThemePreference() {
        UserDefaults.standard.set(currentTheme.id, forKey: "CodeThemeId")
        UserDefaults.standard.set(autoDetectFromSystem, forKey: "AutoDetectTheme")
    }

    public func selectTheme(_ theme: CodeTheme) {
        currentTheme = theme
    }

    public func updateForColorScheme(_ scheme: ColorScheme) {
        guard autoDetectFromSystem else { return }
        currentTheme = scheme == .dark ? .oneDark : .githubLight
    }
}

// MARK: - Language Support

/// Supported programming languages for syntax highlighting
public enum CodeLanguage: String, Codable, CaseIterable, Sendable {
    case swift
    case python
    case javascript
    case typescript
    case java
    case kotlin
    case rust
    case go
    case c
    case cpp
    case csharp
    case ruby
    case php
    case html
    case css
    case scss
    case json
    case yaml
    case xml
    case toml
    case markdown
    case sql
    case graphql
    case bash
    case shell
    case powershell
    case dockerfile
    case docker
    case makefile
    case cmake
    case regex

    /// Display name for the language
    public var displayName: String {
        switch self {
        case .swift: return "Swift"
        case .python: return "Python"
        case .javascript: return "JavaScript"
        case .typescript: return "TypeScript"
        case .java: return "Java"
        case .kotlin: return "Kotlin"
        case .rust: return "Rust"
        case .go: return "Go"
        case .c: return "C"
        case .cpp: return "C++"
        case .csharp: return "C#"
        case .ruby: return "Ruby"
        case .php: return "PHP"
        case .html: return "HTML"
        case .css: return "CSS"
        case .scss: return "SCSS"
        case .json: return "JSON"
        case .yaml: return "YAML"
        case .xml: return "XML"
        case .toml: return "TOML"
        case .markdown: return "Markdown"
        case .sql: return "SQL"
        case .graphql: return "GraphQL"
        case .bash, .shell: return "Shell"
        case .powershell: return "PowerShell"
        case .dockerfile, .docker: return "Dockerfile"
        case .makefile: return "Makefile"
        case .cmake: return "CMake"
        case .regex: return "Regex"
        }
    }

    /// File extensions associated with this language
    public var fileExtensions: [String] {
        switch self {
        case .swift: return ["swift"]
        case .python: return ["py", "pyw"]
        case .javascript: return ["js", "mjs", "cjs"]
        case .typescript: return ["ts", "tsx"]
        case .java: return ["java"]
        case .kotlin: return ["kt", "kts"]
        case .rust: return ["rs"]
        case .go: return ["go"]
        case .c: return ["c", "h"]
        case .cpp: return ["cpp", "cc", "cxx", "hpp", "hh", "hxx"]
        case .csharp: return ["cs"]
        case .ruby: return ["rb", "rake"]
        case .php: return ["php"]
        case .html: return ["html", "htm"]
        case .css: return ["css"]
        case .scss: return ["scss", "sass"]
        case .json: return ["json"]
        case .yaml: return ["yaml", "yml"]
        case .xml: return ["xml"]
        case .toml: return ["toml"]
        case .markdown: return ["md", "markdown"]
        case .sql: return ["sql"]
        case .graphql: return ["graphql", "gql"]
        case .bash, .shell: return ["sh", "bash", "zsh"]
        case .powershell: return ["ps1", "psm1"]
        case .dockerfile, .docker: return ["dockerfile", "docker"]
        case .makefile: return ["makefile", "mk"]
        case .cmake: return ["cmake"]
        case .regex: return ["regex"]
        }
    }

    /// Detect language from file extension
    public static func detect(from fileExtension: String) -> CodeLanguage? {
        let ext = fileExtension.lowercased()
        for language in CodeLanguage.allCases {
            if language.fileExtensions.contains(ext) {
                return language
            }
        }
        return nil
    }

    /// Detect language from language string (from code fence)
    public static func from(string: String) -> CodeLanguage? {
        let lowercased = string.lowercased()

        // Direct match
        if let lang = CodeLanguage(rawValue: lowercased) {
            return lang
        }

        // Aliases
        switch lowercased {
        case "js": return .javascript
        case "ts": return .typescript
        case "py": return .python
        case "rb": return .ruby
        case "sh", "zsh", "bash": return .bash
        case "docker": return .dockerfile
        case "yml": return .yaml
        default: return nil
        }
    }
}
