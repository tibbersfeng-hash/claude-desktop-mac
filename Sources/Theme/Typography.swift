// Typography.swift
// Claude Desktop Mac - Typography Definitions
//
// Font definitions and text styles for the application

import SwiftUI

// MARK: - Font Extensions

extension Font {
    // MARK: - Standard Typography

    /// Window titles - 22pt, Semibold
    static let windowTitle = Font.system(size: 22, weight: .semibold)

    /// Section headers - 20pt, Semibold
    static let sectionHeader = Font.system(size: 20, weight: .semibold)

    /// Card titles - 17pt, Semibold
    static let cardTitle = Font.system(size: 17, weight: .semibold)

    /// Body text - 15pt, Regular
    static let bodyText = Font.system(size: 15, weight: .regular)

    /// Secondary text - 14pt, Regular
    static let secondaryText = Font.system(size: 14, weight: .regular)

    /// Code blocks - 13pt, Regular, Monospaced
    static let codeBlock = Font.system(size: 13, weight: .regular, design: .monospaced)

    /// Inline code - 14pt, Regular, Monospaced
    static let inlineCode = Font.system(size: 14, weight: .regular, design: .monospaced)

    /// Tool output - 12pt, Regular, Monospaced
    static let toolOutput = Font.system(size: 12, weight: .regular, design: .monospaced)

    /// Caption text - 12pt, Regular
    static let captionText = Font.system(size: 12, weight: .regular)

    /// Timestamp - 11pt, Regular
    static let timestamp = Font.system(size: 11, weight: .regular)

    /// Label text - 11pt, Regular
    static let labelText = Font.system(size: 11, weight: .regular)

    // MARK: - Message Typography

    /// User message text
    static let userMessage = Font.system(size: 15, weight: .regular)

    /// Assistant message text
    static let assistantMessage = Font.system(size: 15, weight: .regular)

    /// Message metadata
    static let messageMetadata = Font.system(size: 11, weight: .regular)

    // MARK: - Session List Typography

    /// Session title
    static let sessionTitle = Font.system(size: 13, weight: .medium)

    /// Session subtitle
    static let sessionSubtitle = Font.system(size: 11, weight: .regular)

    /// Session timestamp
    static let sessionTimestamp = Font.system(size: 10, weight: .regular)

    // MARK: - Input Typography

    /// Input field text
    static let inputText = Font.system(size: 15, weight: .regular)

    /// Placeholder text
    static let placeholderText = Font.system(size: 15, weight: .regular)

    // MARK: - Status Typography

    /// Status bar text
    static let statusText = Font.system(size: 12, weight: .regular)

    /// Connection status
    static let connectionStatus = Font.system(size: 12, weight: .medium)

    // MARK: - Tool Call Typography

    /// Tool name
    static let toolName = Font.system(size: 13, weight: .medium)

    /// Tool arguments
    static let toolArguments = Font.system(size: 12, weight: .regular, design: .monospaced)

    /// Tool result
    static let toolResult = Font.system(size: 12, weight: .regular, design: .monospaced)

    // MARK: - Diff Typography

    /// Diff line number
    static let diffLineNumber = Font.system(size: 11, weight: .regular, design: .monospaced)

    /// Diff code
    static let diffCode = Font.system(size: 12, weight: .regular, design: .monospaced)

    /// Diff header
    static let diffHeader = Font.system(size: 13, weight: .medium)
}

// MARK: - Line Height

public enum LineHeight: CGFloat {
    case tight = 1.2
    case normal = 1.4
    case relaxed = 1.6
}

// MARK: - Text Style

public struct TextStyle {
    public let font: Font
    public let lineHeight: LineHeight
    public let letterSpacing: CGFloat

    public init(font: Font, lineHeight: LineHeight = .normal, letterSpacing: CGFloat = 0) {
        self.font = font
        self.lineHeight = lineHeight
        self.letterSpacing = letterSpacing
    }
}

// MARK: - Predefined Text Styles

extension TextStyle {
    /// Default body style
    public static let body = TextStyle(font: .bodyText, lineHeight: .normal)

    /// Code block style
    public static let code = TextStyle(font: .codeBlock, lineHeight: .tight, letterSpacing: 0.3)

    /// Caption style
    public static let caption = TextStyle(font: .captionText, lineHeight: .normal)

    /// Session title style
    public static let sessionTitle = TextStyle(font: .sessionTitle, lineHeight: .tight)

    /// Tool name style
    public static let toolName = TextStyle(font: .toolName, lineHeight: .tight)
}
