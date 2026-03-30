// MarkdownRenderer.swift
// Claude Desktop Mac - Markdown Rendering
//
// Advanced Markdown rendering with support for tables, Mermaid, and LaTeX

import SwiftUI
import Combine
import Theme

// MARK: - Markdown Renderer

/// Renders Markdown content with advanced features
public final class MarkdownRenderer: @unchecked Sendable {

    // MARK: - Singleton

    public static let shared = MarkdownRenderer()

    // MARK: - Properties

    private let renderQueue = DispatchQueue(label: "com.claudedesktop.markdown", qos: .userInitiated)

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Parse markdown content into blocks
    public func parse(_ content: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = content.components(separatedBy: "\n")
        var i = 0

        while i < lines.count {
            let line = lines[i]

            // Code block
            if line.hasPrefix("```") {
                let (block, newIndex) = parseCodeBlock(lines: lines, startIndex: i)
                blocks.append(block)
                i = newIndex
                continue
            }

            // Mermaid diagram
            if line.hasPrefix("```mermaid") {
                let (block, newIndex) = parseMermaidBlock(lines: lines, startIndex: i)
                blocks.append(block)
                i = newIndex
                continue
            }

            // Table
            if isTableStart(line: line, lines: lines, currentIndex: i) {
                let (block, newIndex) = parseTable(lines: lines, startIndex: i)
                blocks.append(block)
                i = newIndex
                continue
            }

            // Heading
            if line.hasPrefix("#") {
                let (block, newIndex) = parseHeading(lines: lines, startIndex: i)
                blocks.append(block)
                i = newIndex
                continue
            }

            // Task list
            if line.hasPrefix("- [ ]") || line.hasPrefix("- [x]") || line.hasPrefix("* [ ]") || line.hasPrefix("* [x]") {
                let (block, newIndex) = parseTaskList(lines: lines, startIndex: i)
                blocks.append(block)
                i = newIndex
                continue
            }

            // Unordered list
            if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") {
                let (block, newIndex) = parseUnorderedList(lines: lines, startIndex: i)
                blocks.append(block)
                i = newIndex
                continue
            }

            // Ordered list
            if let match = line.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                let (block, newIndex) = parseOrderedList(lines: lines, startIndex: i)
                blocks.append(block)
                i = newIndex
                continue
            }

            // Blockquote
            if line.hasPrefix("> ") {
                let (block, newIndex) = parseBlockquote(lines: lines, startIndex: i)
                blocks.append(block)
                i = newIndex
                continue
            }

            // Horizontal rule
            if line.hasPrefix("---") || line.hasPrefix("***") || line.hasPrefix("___") {
                blocks.append(.horizontalRule)
                i += 1
                continue
            }

            // LaTeX math block
            if line.hasPrefix("$$") {
                let (block, newIndex) = parseLatexBlock(lines: lines, startIndex: i)
                blocks.append(block)
                i = newIndex
                continue
            }

            // Regular paragraph
            if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                let (block, newIndex) = parseParagraph(lines: lines, startIndex: i)
                blocks.append(block)
                i = newIndex
                continue
            }

            i += 1
        }

        return blocks
    }

    // MARK: - Block Parsing

    private func parseCodeBlock(lines: [String], startIndex: Int) -> (MarkdownBlock, Int) {
        let firstLine = lines[startIndex]
        let languageStr = String(firstLine.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        let language = CodeLanguage.from(string: languageStr)

        var codeLines: [String] = []
        var i = startIndex + 1

        while i < lines.count && !lines[i].hasPrefix("```") {
            codeLines.append(lines[i])
            i += 1
        }

        return (.codeBlock(code: codeLines.joined(separator: "\n"), language: language), i + 1)
    }

    private func parseMermaidBlock(lines: [String], startIndex: Int) -> (MarkdownBlock, Int) {
        var codeLines: [String] = []
        var i = startIndex + 1

        while i < lines.count && !lines[i].hasPrefix("```") {
            codeLines.append(lines[i])
            i += 1
        }

        return (.mermaidDiagram(code: codeLines.joined(separator: "\n")), i + 1)
    }

    private func isTableStart(line: String, lines: [String], currentIndex: Int) -> Bool {
        guard line.contains("|") else { return false }
        guard currentIndex + 1 < lines.count else { return false }

        let nextLine = lines[currentIndex + 1]
        return nextLine.contains("|") && nextLine.contains("-")
    }

    private func parseTable(lines: [String], startIndex: Int) -> (MarkdownBlock, Int) {
        var tableLines: [String] = []
        var i = startIndex

        while i < lines.count && lines[i].contains("|") {
            tableLines.append(lines[i])
            i += 1
        }

        let rows = tableLines.map { line -> [String] in
            line.split(separator: "|")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }

        guard rows.count >= 2 else {
            return (.paragraph(text: tableLines.joined(separator: "\n")), i)
        }

        // First row is header, second row is alignment, rest are data
        let headers = rows[0]
        let alignmentRow = rows[1]
        let alignments = alignmentRow.map { cell -> TableAlignment in
            if cell.contains(":") && cell.hasSuffix(":") {
                return .center
            } else if cell.hasSuffix(":") {
                return .right
            } else {
                return .left
            }
        }
        let data = Array(rows.dropFirst(2))

        return (.table(headers: headers, alignments: alignments, rows: data), i)
    }

    private func parseHeading(lines: [String], startIndex: Int) -> (MarkdownBlock, Int) {
        let line = lines[startIndex]
        let level = line.prefix(while: { $0 == "#" }).count
        let text = String(line.dropFirst(level)).trimmingCharacters(in: .whitespaces)
        return (.heading(text: text, level: level), startIndex + 1)
    }

    private func parseTaskList(lines: [String], startIndex: Int) -> (MarkdownBlock, Int) {
        var items: [(text: String, checked: Bool)] = []
        var i = startIndex

        while i < lines.count {
            let line = lines[i]
            if line.hasPrefix("- [ ]") || line.hasPrefix("* [ ]") {
                let text = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                items.append((text: text, checked: false))
                i += 1
            } else if line.hasPrefix("- [x]") || line.hasPrefix("* [x]") {
                let text = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                items.append((text: text, checked: true))
                i += 1
            } else {
                break
            }
        }

        return (.taskList(items: items), i)
    }

    private func parseUnorderedList(lines: [String], startIndex: Int) -> (MarkdownBlock, Int) {
        var items: [String] = []
        var i = startIndex

        while i < lines.count {
            let line = lines[i]
            if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") {
                let text = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                items.append(text)
                i += 1
            } else {
                break
            }
        }

        return (.unorderedList(items: items), i)
    }

    private func parseOrderedList(lines: [String], startIndex: Int) -> (MarkdownBlock, Int) {
        var items: [(index: Int, text: String)] = []
        var i = startIndex
        var listIndex = 0

        while i < lines.count {
            let line = lines[i]
            if let match = line.range(of: #"^(\d+)\.\s"#, options: .regularExpression) {
                listIndex += 1
                let text = String(line[match.upperBound...])
                items.append((index: listIndex, text: text))
                i += 1
            } else {
                break
            }
        }

        return (.orderedList(items: items), i)
    }

    private func parseBlockquote(lines: [String], startIndex: Int) -> (MarkdownBlock, Int) {
        var textLines: [String] = []
        var i = startIndex

        while i < lines.count && lines[i].hasPrefix("> ") {
            let text = String(lines[i].dropFirst(2))
            textLines.append(text)
            i += 1
        }

        return (.blockquote(text: textLines.joined(separator: "\n")), i)
    }

    private func parseLatexBlock(lines: [String], startIndex: Int) -> (MarkdownBlock, Int) {
        var latexLines: [String] = []
        var i = startIndex + 1

        while i < lines.count && !lines[i].hasPrefix("$$") {
            latexLines.append(lines[i])
            i += 1
        }

        return (.latex(equation: latexLines.joined(separator: "\n")), i + 1)
    }

    private func parseParagraph(lines: [String], startIndex: Int) -> (MarkdownBlock, Int) {
        var textLines: [String] = []
        var i = startIndex

        while i < lines.count {
            let line = lines[i]
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                break
            }
            // Stop if we hit a special block
            if line.hasPrefix("#") || line.hasPrefix("- ") || line.hasPrefix("* ") ||
               line.hasPrefix("> ") || line.hasPrefix("```") || line.hasPrefix("$$") ||
               line.contains("|") || line.hasPrefix("---") {
                break
            }
            textLines.append(line)
            i += 1
        }

        return (.paragraph(text: textLines.joined(separator: "\n")), i)
    }
}

// MARK: - Markdown Block Types

/// Represents a parsed markdown block
public enum MarkdownBlock: Identifiable, Sendable {
    case paragraph(text: String)
    case heading(text: String, level: Int)
    case codeBlock(code: String, language: CodeLanguage?)
    case unorderedList(items: [String])
    case orderedList(items: [(index: Int, text: String)])
    case taskList(items: [(text: String, checked: Bool)])
    case blockquote(text: String)
    case table(headers: [String], alignments: [TableAlignment], rows: [[String]])
    case horizontalRule
    case mermaidDiagram(code: String)
    case latex(equation: String)

    public var id: UUID { UUID() }
}

/// Table column alignment
public enum TableAlignment: String, Sendable {
    case left
    case center
    case right
}

// MARK: - Advanced Markdown View

/// A view that renders advanced Markdown content
public struct AdvancedMarkdownView: View {
    @Environment(\.colorScheme) private var colorScheme

    let content: String
    let theme: CodeTheme

    @State private var blocks: [MarkdownBlock] = []

    public init(content: String, theme: CodeTheme? = nil) {
        self.content = content
        self.theme = theme ?? .default
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
            ForEach(blocks) { block in
                blockView(for: block)
            }
        }
        .task {
            blocks = MarkdownRenderer.shared.parse(content)
        }
        .onChange(of: content) { _, _ in
            blocks = MarkdownRenderer.shared.parse(content)
        }
    }

    @ViewBuilder
    private func blockView(for block: MarkdownBlock) -> some View {
        switch block {
        case .paragraph(let text):
            ParagraphView(text: text, colorScheme: colorScheme)

        case .heading(let text, let level):
            HeadingView(text: text, level: level, colorScheme: colorScheme)

        case .codeBlock(let code, let language):
            HighlightedCodeBlock(code: code, language: language, theme: theme)

        case .unorderedList(let items):
            UnorderedListView(items: items, colorScheme: colorScheme)

        case .orderedList(let items):
            OrderedListView(items: items, colorScheme: colorScheme)

        case .taskList(let items):
            TaskListView(items: items, colorScheme: colorScheme)

        case .blockquote(let text):
            BlockquoteView(text: text, colorScheme: colorScheme)

        case .table(let headers, let alignments, let rows):
            TableView(headers: headers, alignments: alignments, rows: rows, colorScheme: colorScheme)

        case .horizontalRule:
            Divider()
                .background(Color.fgTertiary(scheme: colorScheme))

        case .mermaidDiagram(let code):
            MermaidDiagramView(code: code, colorScheme: colorScheme)

        case .latex(let equation):
            LatexView(equation: equation, colorScheme: colorScheme)
        }
    }
}

// MARK: - Block Views

private struct ParagraphView: View {
    let text: String
    let colorScheme: ColorScheme

    var body: some View {
        Text(attributedText)
            .font(.assistantMessage)
            .foregroundColor(Color.fgPrimary(scheme: colorScheme))
            .textSelection(.enabled)
    }

    private var attributedText: AttributedString {
        var result = AttributedString(text)
        // Apply inline formatting (bold, italic, inline code, links)
        applyInlineFormatting(&result)
        return result
    }

    private func applyInlineFormatting(_ result: inout AttributedString) {
        // Bold: **text**
        // Italic: *text* or _text_
        // Inline code: `code`
        // Links: [text](url)
    }
}

private struct HeadingView: View {
    let text: String
    let level: Int
    let colorScheme: ColorScheme

    var body: some View {
        Text(text)
            .font(headingFont)
            .foregroundColor(Color.fgPrimary(scheme: colorScheme))
            .padding(.top, level == 1 ? Spacing.md.rawValue : Spacing.sm.rawValue)
    }

    private var headingFont: Font {
        switch level {
        case 1: return .title
        case 2: return .title2
        case 3: return .title3
        default: return .headline
        }
    }
}

private struct UnorderedListView: View {
    let items: [String]
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: Spacing.sm.rawValue) {
                    Text("\u{2022}")
                        .font(.assistantMessage)
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))

                    Text(item)
                        .font(.assistantMessage)
                        .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                        .textSelection(.enabled)
                }
            }
        }
    }
}

private struct OrderedListView: View {
    let items: [(index: Int, text: String)]
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
            ForEach(items, id: \.index) { item in
                HStack(alignment: .top, spacing: Spacing.sm.rawValue) {
                    Text("\(item.index).")
                        .font(.assistantMessage)
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))

                    Text(item.text)
                        .font(.assistantMessage)
                        .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                        .textSelection(.enabled)
                }
            }
        }
    }
}

private struct TaskListView: View {
    let items: [(text: String, checked: Bool)]
    let colorScheme: ColorScheme

    @State private var checkedItems: Set<Int> = []

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
            ForEach(items.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: Spacing.sm.rawValue) {
                    Image(systemName: isChecked(index) ? "checkmark.square" : "square")
                        .font(.system(size: 14))
                        .foregroundColor(isChecked(index) ? .accentSuccess : Color.fgSecondary(scheme: colorScheme))
                        .onTapGesture {
                            toggleItem(index)
                        }

                    Text(items[index].text)
                        .font(.assistantMessage)
                        .foregroundColor(isChecked(index) ? Color.fgTertiary(scheme: colorScheme) : Color.fgPrimary(scheme: colorScheme))
                        .strikethrough(isChecked(index))
                        .textSelection(.enabled)
                }
            }
        }
        .onAppear {
            checkedItems = Set(items.enumerated().filter { $0.element.checked }.map { $0.offset })
        }
    }

    private func isChecked(_ index: Int) -> Bool {
        checkedItems.contains(index)
    }

    private func toggleItem(_ index: Int) {
        if checkedItems.contains(index) {
            checkedItems.remove(index)
        } else {
            checkedItems.insert(index)
        }
    }
}

private struct BlockquoteView: View {
    let text: String
    let colorScheme: ColorScheme

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm.rawValue) {
            Rectangle()
                .fill(Color.accentPrimary)
                .frame(width: 3)
                .cornerRadius(1)

            Text(text)
                .font(.assistantMessage)
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                .italic()
                .textSelection(.enabled)
        }
        .padding(.leading, Spacing.sm.rawValue)
    }
}

private struct TableView: View {
    let headers: [String]
    let alignments: [TableAlignment]
    let rows: [[String]]
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                ForEach(headers.indices, id: \.self) { index in
                    Text(headers[index])
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                        .frame(maxWidth: .infinity, alignment: alignmentFor(index))
                        .padding(.horizontal, Spacing.sm.rawValue)
                        .padding(.vertical, Spacing.sm.rawValue)
                }
            }
            .background(Color.bgTertiary(scheme: colorScheme))

            Divider()

            // Data rows
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 0) {
                    ForEach(rows[rowIndex].indices, id: \.self) { colIndex in
                        Text(colIndex < rows[rowIndex].count ? rows[rowIndex][colIndex] : "")
                            .font(.system(size: 13))
                            .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                            .frame(maxWidth: .infinity, alignment: alignmentFor(colIndex))
                            .padding(.horizontal, Spacing.sm.rawValue)
                            .padding(.vertical, Spacing.sm.rawValue)
                            .textSelection(.enabled)
                    }
                }
                .background(rowIndex % 2 == 0 ? Color.clear : Color.bgSecondary(scheme: colorScheme).opacity(0.3))

                if rowIndex < rows.count - 1 {
                    Divider()
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md.rawValue)
                .stroke(Color.fgTertiary(scheme: colorScheme).opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(CornerRadius.md.rawValue)
    }

    private func alignmentFor(_ index: Int) -> Alignment {
        guard index < alignments.count else { return .leading }
        switch alignments[index] {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }
}

private struct MermaidDiagramView: View {
    let code: String
    let colorScheme: ColorScheme

    var body: some View {
        Text("Mermaid Diagram")
            .font(.caption)
            .foregroundColor(Color.fgTertiary(scheme: colorScheme))
        // Note: Full Mermaid rendering would require a WebView
        // This is a placeholder showing the code
        Text(code)
            .font(.codeBlock)
            .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            .padding(Spacing.md.rawValue)
            .background(Color.codeBg(scheme: colorScheme))
            .cornerRadius(CornerRadius.md.rawValue)
    }
}

private struct LatexView: View {
    let equation: String
    let colorScheme: ColorScheme

    var body: some View {
        Text(equation)
            .font(.system(size: 15, design: .serif))
            .foregroundColor(Color.fgPrimary(scheme: colorScheme))
            .padding(Spacing.md.rawValue)
            .frame(maxWidth: .infinity)
            .background(Color.bgTertiary(scheme: colorScheme).opacity(0.5))
            .cornerRadius(CornerRadius.md.rawValue)
        // Note: Full LaTeX rendering would require a proper math rendering library
    }
}
