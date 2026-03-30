// MessageView.swift
// Claude Desktop Mac - Message View
//
// Displays individual messages with markdown support

import SwiftUI

// MARK: - Message View

public struct MessageView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.reduceMotion) private var reduceMotion

    let message: ChatMessage

    public init(message: ChatMessage) {
        self.message = message
    }

    public var body: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: Spacing.sm.rawValue) {
            if message.role == .assistant {
                // Assistant header
                AssistantMessageHeader(status: message.status)
            }

            // Message content
            Group {
                if message.role == .user {
                    UserMessageContent(content: message.content, timestamp: message.formattedTime)
                } else {
                    AssistantMessageContent(
                        content: message.content,
                        toolCalls: message.toolCalls,
                        status: message.status,
                        timestamp: message.formattedTime
                    )
                }
            }
            .frame(maxWidth: message.role == .user ? 600 : .infinity, alignment: message.role == .user ? .trailing : .leading)
        }
        .padding(.vertical, Spacing.xs.rawValue)
        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.95)))
    }
}

// MARK: - Assistant Message Header

struct AssistantMessageHeader: View {
    @Environment(\.colorScheme) private var colorScheme
    let status: MessageStatus

    var body: some View {
        HStack(spacing: Spacing.sm.rawValue) {
            Image(systemName: "sparkles")
                .font(.system(size: 14))
                .foregroundColor(.accentPurple)

            Text("Claude")
                .font(.headline)
                .foregroundColor(Color.fgPrimary(scheme: colorScheme))

            if status == .streaming {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 16, height: 16)
            }

            Spacer()
        }
    }
}

// MARK: - User Message Content

struct UserMessageContent: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.highContrast) private var highContrast

    let content: String
    let timestamp: String

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .trailing, spacing: Spacing.sm.rawValue) {
            Text(content)
                .font(.userMessage)
                .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                .textSelection(.enabled)

            HStack(spacing: Spacing.sm.rawValue) {
                Text(timestamp)
                    .font(.messageMetadata)
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))

                if isHovered {
                    Button(action: {}) {
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.icon(size: 20))
                    .accessibilityLabel("Edit message")
                    .accessibilityHint("Double tap to edit this message")
                }
            }
        }
        .padding(.horizontal, Spacing.lg.rawValue)
        .padding(.vertical, Spacing.md.rawValue)
        .background(Color.bgTertiary(scheme: colorScheme))
        .cornerRadius(CornerRadius.lg.rawValue)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg.rawValue)
                .stroke(highContrast ? Color.fgSecondary(scheme: colorScheme) : Color.clear, lineWidth: highContrast ? 1 : 0)
        )
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your message: \(content)")
        .accessibilityHint("Sent at \(timestamp)")
    }
}

// MARK: - Assistant Message Content

struct AssistantMessageContent: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.highContrast) private var highContrast

    let content: String
    let toolCalls: [ToolCallDisplay]?
    let status: MessageStatus
    let timestamp: String

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
            // Tool calls (shown before content)
            if let toolCalls = toolCalls, !toolCalls.isEmpty {
                VStack(spacing: Spacing.sm.rawValue) {
                    ForEach(toolCalls) { toolCall in
                        ToolCallView(toolCall: toolCall)
                    }
                }
                .accessibilityLabel("\(toolCalls.count) tool calls")
            }

            // Content with markdown
            if !content.isEmpty {
                MarkdownView(content: content)
            }

            // Footer
            HStack(spacing: Spacing.md.rawValue) {
                if isHovered {
                    Button(action: {}) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.captionText)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                    .accessibilityLabel("Copy message")
                    .accessibilityHint("Double tap to copy this message to clipboard")

                    Button(action: {}) {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                            .font(.captionText)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                    .accessibilityLabel("Regenerate response")
                    .accessibilityHint("Double tap to regenerate this response")
                }

                Spacer()

                Text(timestamp)
                    .font(.messageMetadata)
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
            }
        }
        .padding(Spacing.md.rawValue)
        .background(Color.bgSecondary(scheme: colorScheme).opacity(0.3))
        .cornerRadius(CornerRadius.lg.rawValue)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg.rawValue)
                .stroke(highContrast ? Color.fgTertiary(scheme: colorScheme).opacity(0.5) : Color.clear, lineWidth: highContrast ? 1 : 0)
        )
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Claude's response: \(content)")
        .accessibilityHint("Sent at \(timestamp)")
    }
}

// MARK: - Markdown View

struct MarkdownView: View {
    @Environment(\.colorScheme) private var colorScheme

    let content: String

    var body: some View {
        // Basic markdown rendering
        // In production, use a library like MarkdownUI
        VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
            ForEach(Array(parseContent().enumerated()), id: \.offset) { _, block in
                switch block {
                case .text(let text):
                    Text(attributedString(from: text))
                        .font(.assistantMessage)
                        .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                        .textSelection(.enabled)

                case .codeBlock(let code, let language):
                    CodeBlockView(code: code, language: language)

                case .heading(let text, let level):
                    Text(text)
                        .font(headingFont(for: level))
                        .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                case .listItem(let text, let isOrdered, let index):
                    HStack(alignment: .top, spacing: Spacing.sm.rawValue) {
                        if isOrdered {
                            Text("\(index).")
                                .font(.assistantMessage)
                                .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                        } else {
                            Text("•")
                                .font(.assistantMessage)
                                .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                        }

                        Text(attributedString(from: text))
                            .font(.assistantMessage)
                            .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                    }

                case .quote(let text):
                    HStack(spacing: Spacing.sm.rawValue) {
                        Rectangle()
                            .fill(Color.accentPrimary)
                            .frame(width: 3)
                            .cornerRadius(1)

                        Text(text)
                            .font(.assistantMessage)
                            .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                            .italic()
                    }
                    .padding(.leading, Spacing.sm.rawValue)
                }
            }
        }
    }

    // MARK: - Content Parsing

    private enum ContentBlock {
        case text(String)
        case codeBlock(code: String, language: String?)
        case heading(text: String, level: Int)
        case listItem(text: String, isOrdered: Bool, index: Int)
        case quote(text: String)
    }

    private func parseContent() -> [ContentBlock] {
        var blocks: [ContentBlock] = []
        let lines = content.components(separatedBy: "\n")
        var i = 0
        var orderedListIndex = 0

        while i < lines.count {
            let line = lines[i]

            // Code block
            if line.hasPrefix("```") {
                let language = line.dropFirst(3).trimmingCharacters(in: .whitespaces)
                var codeLines: [String] = []
                i += 1

                while i < lines.count && !lines[i].hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }

                blocks.append(.codeBlock(code: codeLines.joined(separator: "\n"), language: language.isEmpty ? nil : language))
                i += 1
                continue
            }

            // Heading
            if line.hasPrefix("#") {
                let level = line.prefix(while: { $0 == "#" }).count
                let text = String(line.dropFirst(level)).trimmingCharacters(in: .whitespaces)
                blocks.append(.heading(text: text, level: level))
                i += 1
                continue
            }

            // Unordered list
            if line.hasPrefix("- ") || line.hasPrefix("* ") {
                let text = String(line.dropFirst(2))
                blocks.append(.listItem(text: text, isOrdered: false, index: 0))
                i += 1
                continue
            }

            // Ordered list
            if let match = line.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                orderedListIndex += 1
                let text = String(line[match.upperBound...])
                blocks.append(.listItem(text: text, isOrdered: true, index: orderedListIndex))
                i += 1
                continue
            } else {
                orderedListIndex = 0
            }

            // Quote
            if line.hasPrefix("> ") {
                let text = String(line.dropFirst(2))
                blocks.append(.quote(text: text))
                i += 1
                continue
            }

            // Regular text
            if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                blocks.append(.text(line))
            }

            i += 1
        }

        return blocks
    }

    private func headingFont(for level: Int) -> Font {
        switch level {
        case 1: return .title
        case 2: return .title2
        case 3: return .title3
        default: return .headline
        }
    }

    private func attributedString(from text: String) -> AttributedString {
        // Basic inline formatting
        var result = AttributedString(text)

        // Bold
        if let boldRange = result.range(of: "**") {
            // Handle bold text
        }

        // Inline code
        if let codeRange = result.range(of: "`") {
            // Handle inline code
        }

        return result
    }
}

// MARK: - Code Block View

struct CodeBlockView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.highContrast) private var highContrast

    let code: String
    let language: String?

    @State private var isHovered = false
    @State private var showCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                if let language = language {
                    Text(language)
                        .font(.captionText)
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                }

                Spacer()

                if isHovered {
                    Button(action: copyCode) {
                        if showCopied {
                            Label("Copied!", systemImage: "checkmark")
                        } else {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
                    .font(.captionText)
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                    .buttonStyle(.plain)
                    .accessibilityLabel("Copy code")
                    .accessibilityHint("Double tap to copy this code block to clipboard")
                }
            }
            .padding(.horizontal, Spacing.md.rawValue)
            .padding(.vertical, Spacing.sm.rawValue)
            .background(Color.fgTertiary(scheme: colorScheme).opacity(0.1))

            Divider()
                .background(Color.fgTertiary(scheme: colorScheme).opacity(0.3))

            // Code content with line numbers
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .top, spacing: Spacing.sm.rawValue) {
                    // Line numbers
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(1...lineCount, id: \.self) { lineNum in
                            Text("\(lineNum)")
                                .font(.codeBlock)
                                .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                                .frame(minWidth: 24, alignment: .trailing)
                        }
                    }
                    .padding(.vertical, Spacing.xs.rawValue)
                    .accessibilityHidden(true)

                    // Code
                    Text(code)
                        .font(.codeBlock)
                        .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                        .textSelection(.enabled)
                        .padding(.vertical, Spacing.xs.rawValue)
                }
                .padding(.horizontal, Spacing.md.rawValue)
            }
        }
        .background(Color.codeBg(scheme: colorScheme))
        .cornerRadius(CornerRadius.md.rawValue)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md.rawValue)
                .stroke(highContrast ? Color.fgTertiary(scheme: colorScheme).opacity(0.5) : Color.clear, lineWidth: highContrast ? 1 : 0)
        )
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(codeBlockAccessibilityLabel)
        .accessibilityHint("Code block with \(lineCount) lines")
    }

    private var lineCount: Int {
        code.components(separatedBy: "\n").count
    }

    private var codeBlockAccessibilityLabel: String {
        var label = "Code block"
        if let language = language {
            label += " in \(language)"
        }
        label += ", \(lineCount) lines"
        return label
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

// MARK: - Preview

#Preview {
    VStack {
        MessageView(message: .user("Can you help me implement an API client?"))

        MessageView(message: .assistant(
            "Here's an implementation:\n\n```swift\nlet client = APIClient()\n```",
            toolCalls: [.sample]
        ))
    }
    .padding()
    .frame(width: 600)
    .background(Color.bgPrimaryDark)
}
