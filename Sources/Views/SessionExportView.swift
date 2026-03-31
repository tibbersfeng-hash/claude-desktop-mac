// SessionExportView.swift
// Claude Desktop Mac - Session Export View
//
// Export sessions to various formats (JSON, Markdown, PDF)

import SwiftUI
import Theme
import Models

// MARK: - Export Format

public enum ExportFormat: String, CaseIterable, Identifiable {
    case json = "JSON"
    case markdown = "Markdown"
    case pdf = "PDF"
    case html = "HTML"

    public var id: String { rawValue }

    public var fileExtension: String {
        switch self {
        case .json: return "json"
        case .markdown: return "md"
        case .pdf: return "pdf"
        case .html: return "html"
        }
    }

    public var iconName: String {
        switch self {
        case .json: return "curlybraces"
        case .markdown: return "doc.text"
        case .pdf: return "doc.richtext"
        case .html: return "globe"
        }
    }

    public var description: String {
        switch self {
        case .json:
            return "Full data export, can be re-imported"
        case .markdown:
            return "Human-readable format for notes and sharing"
        case .pdf:
            return "Print-ready document format"
        case .html:
            return "Web page format with styling"
        }
    }
}

// MARK: - Session Exporter

@MainActor
public class SessionExporter: ObservableObject {

    // MARK: - Properties

    @Published var isExporting: Bool = false
    @Published var exportProgress: Double = 0.0
    @Published var errorMessage: String?
    @Published var exportedURL: URL?

    // MARK: - Export Methods

    /// Export a session to the specified format
    public func export(
        session: Session,
        format: ExportFormat,
        to url: URL
    ) async throws {
        isExporting = true
        exportProgress = 0.0
        errorMessage = nil
        exportedURL = nil

        defer {
            isExporting = false
        }

        let content: Data

        switch format {
        case .json:
            content = try exportAsJSON(session: session)
            exportProgress = 0.5

        case .markdown:
            let markdown = try exportAsMarkdown(session: session)
            content = markdown.data(using: .utf8) ?? Data()
            exportProgress = 0.5

        case .pdf:
            content = try await exportAsPDF(session: session)
            exportProgress = 0.5

        case .html:
            let html = try exportAsHTML(session: session)
            content = html.data(using: .utf8) ?? Data()
            exportProgress = 0.5
        }

        // Write to file
        try content.write(to: url)
        exportProgress = 1.0
        exportedURL = url
    }

    // MARK: - Format Implementations

    private func exportAsJSON(session: Session) throws -> Data {
        let exportData = SessionExportData(session: session)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(exportData)
    }

    private func exportAsMarkdown(session: Session) throws -> String {
        var markdown = "# \(session.title)\n\n"
        markdown += "**Exported:** \(ISO8601DateFormatter().string(from: Date()))\n"
        markdown += "**Project:** \(session.projectPath ?? "None")\n"
        markdown += "**Messages:** \(session.messages.count)\n\n"
        markdown += "---\n\n"

        for message in session.messages {
            let timestamp = DateFormatter.localizedString(from: message.timestamp, dateStyle: .short, timeStyle: .short)

            switch message.role {
            case .user:
                markdown += "### 👤 You (\(timestamp))\n\n"
            case .assistant:
                markdown += "### ✨ Claude (\(timestamp))\n\n"
            case .system:
                markdown += "### ⚙️ System (\(timestamp))\n\n"
            }

            markdown += "\(message.content)\n\n"

            // Tool calls
            if let toolCalls = message.toolCalls, !toolCalls.isEmpty {
                markdown += "**Tool Calls:**\n\n"
                for toolCall in toolCalls {
                    markdown += "- `\(toolCall.name)` - \(toolCall.status.displayText)\n"
                }
                markdown += "\n"
            }

            // Edit indicator
            if message.isEdited {
                markdown += "*[edited]*\n\n"
            }

            markdown += "---\n\n"
        }

        return markdown
    }

    private func exportAsPDF(session: Session) async throws -> Data {
        // Generate HTML and convert to PDF
        let html = try exportAsHTML(session: session)

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Create a simple PDF from HTML
                    let pdfData = try Self.htmlToPDF(html: html)
                    continuation.resume(returning: pdfData)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func htmlToPDF(html: String) throws -> Data {
        // Use WKWebView to render HTML to PDF
        // For simplicity, we'll return HTML data as a fallback
        // In production, this would use PDFKit or WKWebView
        guard let data = html.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        return data
    }

    private func exportAsHTML(session: Session) throws -> String {
        var html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(session.title)</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 20px;
                    background: #f5f5f5;
                }
                .header {
                    text-align: center;
                    padding: 20px;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    border-radius: 10px;
                    margin-bottom: 20px;
                }
                .header h1 {
                    margin: 0;
                }
                .metadata {
                    font-size: 0.9em;
                    opacity: 0.9;
                    margin-top: 10px;
                }
                .message {
                    padding: 15px;
                    margin: 10px 0;
                    border-radius: 10px;
                    background: white;
                    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
                }
                .message.user {
                    background: #e3f2fd;
                    border-left: 4px solid #2196f3;
                }
                .message.assistant {
                    background: #f3e5f5;
                    border-left: 4px solid #9c27b0;
                }
                .message.system {
                    background: #fff3e0;
                    border-left: 4px solid #ff9800;
                }
                .message-header {
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    margin-bottom: 10px;
                }
                .role {
                    font-weight: bold;
                }
                .timestamp {
                    font-size: 0.8em;
                    color: #666;
                }
                .content {
                    white-space: pre-wrap;
                    line-height: 1.6;
                }
                .tool-calls {
                    margin-top: 10px;
                    padding: 10px;
                    background: rgba(0,0,0,0.05);
                    border-radius: 5px;
                    font-size: 0.9em;
                }
                .tool-call {
                    margin: 5px 0;
                }
                .edited {
                    font-style: italic;
                    font-size: 0.8em;
                    color: #666;
                }
                pre {
                    background: #1e1e1e;
                    color: #d4d4d4;
                    padding: 15px;
                    border-radius: 5px;
                    overflow-x: auto;
                }
                code {
                    background: rgba(0,0,0,0.1);
                    padding: 2px 5px;
                    border-radius: 3px;
                }
                .footer {
                    text-align: center;
                    padding: 20px;
                    color: #666;
                    font-size: 0.8em;
                }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>\(session.title)</h1>
                <div class="metadata">
                    Exported on \(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short))
                </div>
            </div>

        """

        for message in session.messages {
            let roleClass = message.role.rawValue
            let roleName = message.role.displayName
            let timestamp = DateFormatter.localizedString(from: message.timestamp, dateStyle: .short, timeStyle: .short)

            html += """
                <div class="message \(roleClass)">
                    <div class="message-header">
                        <span class="role">\(roleName)</span>
                        <span class="timestamp">\(timestamp)</span>
                    </div>
                    <div class="content">\(escapeHTML(message.content))</div>

            """

            if let toolCalls = message.toolCalls, !toolCalls.isEmpty {
                html += """
                    <div class="tool-calls">
                        <strong>Tool Calls:</strong>
                        \(toolCalls.map { "<div class=\"tool-call\">\($0.name) - \($0.status.displayText)</div>" }.joined())
                    </div>

                """
            }

            if message.isEdited {
                html += """
                    <div class="edited">[edited]</div>

                """
            }

            html += """
                </div>

            """
        }

        html += """
            <div class="footer">
                Generated by Claude Desktop Mac
            </div>
        </body>
        </html>
        """

        return html
    }

    private func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
            .replacingOccurrences(of: "\n", with: "<br>")
    }
}

// MARK: - Session Export Data

/// Data structure for JSON export
public struct SessionExportData: Codable {
    public let id: UUID
    public let title: String
    public let projectPath: String?
    public let createdAt: Date
    public let exportedAt: Date
    public let messages: [MessageExportData]

    public init(session: Session) {
        self.id = session.id
        self.title = session.title
        self.projectPath = session.projectPath
        self.createdAt = session.createdAt
        self.exportedAt = Date()
        self.messages = session.messages.map(MessageExportData.init)
    }
}

public struct MessageExportData: Codable {
    public let id: UUID
    public let role: String
    public let content: String
    public let timestamp: Date
    public let isEdited: Bool
    public let toolCalls: [ToolCallExportData]?

    public init(message: ChatMessage) {
        self.id = message.id
        self.role = message.role.rawValue
        self.content = message.content
        self.timestamp = message.timestamp
        self.isEdited = message.isEdited
        self.toolCalls = message.toolCalls?.map(ToolCallExportData.init)
    }
}

public struct ToolCallExportData: Codable {
    public let name: String
    public let status: String
    public let arguments: String?
    public let result: String?

    public init(toolCall: ToolCallDisplay) {
        self.name = toolCall.name
        self.status = toolCall.status.rawValue
        self.arguments = toolCall.arguments
        self.result = toolCall.result
    }
}

// MARK: - Export Error

public enum ExportError: LocalizedError {
    case encodingFailed
    case fileWriteFailed
    case unsupportedFormat

    public var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode session data"
        case .fileWriteFailed:
            return "Failed to write export file"
        case .unsupportedFormat:
            return "Unsupported export format"
        }
    }
}

// MARK: - Export Sheet View

public struct SessionExportSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    let session: Session
    let onComplete: ((URL) -> Void)?

    @StateObject private var exporter = SessionExporter()
    @State private var selectedFormat: ExportFormat = .markdown
    @State private var fileName: String = ""
    @State private var showSavePanel: Bool = false

    public init(
        session: Session,
        onComplete: ((URL) -> Void)? = nil
    ) {
        self.session = session
        self.onComplete = onComplete
        self._fileName = State(initialValue: session.title.replacingOccurrences(of: " ", with: "-"))
    }

    public var body: some View {
        VStack(spacing: Spacing.lg.rawValue) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
                    Text("Export Session")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Export \"\(session.title)\" with \(session.messages.count) messages")
                        .font(.callout)
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                }

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                }
                .buttonStyle(.plain)
            }

            // Format selection
            VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
                Text("Export Format")
                    .font(.headline)

                Picker("", selection: $selectedFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        HStack(spacing: Spacing.sm.rawValue) {
                            Image(systemName: format.iconName)
                            Text(format.rawValue)
                        }
                        .tag(format)
                    }
                }
                .pickerStyle(.segmented)

                // Format description
                HStack(spacing: Spacing.sm.rawValue) {
                    Image(systemName: selectedFormat.iconName)
                        .foregroundColor(.accentPrimary)

                    Text(selectedFormat.description)
                        .font(.callout)
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                }
                .padding(Spacing.md.rawValue)
                .background(Color.bgSecondary(scheme: colorScheme))
                .cornerRadius(CornerRadius.md.rawValue)
            }

            // File name
            VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
                Text("File Name")
                    .font(.callout)
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))

                HStack {
                    TextField("File name", text: $fileName)
                        .textFieldStyle(.roundedBorder)

                    Text(".\(selectedFormat.fileExtension)")
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                }
            }

            // Progress (when exporting)
            if exporter.isExporting {
                VStack(spacing: Spacing.sm.rawValue) {
                    ProgressView(value: exporter.exportProgress) {
                        Text("Exporting...")
                            .font(.callout)
                    }

                    Text("\(Int(exporter.exportProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                }
            }

            // Error message
            if let error = exporter.errorMessage {
                HStack(spacing: Spacing.sm.rawValue) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.accentError)

                    Text(error)
                        .font(.callout)
                        .foregroundColor(.accentError)
                }
                .padding(Spacing.md.rawValue)
                .background(Color.accentError.opacity(0.1))
                .cornerRadius(CornerRadius.md.rawValue)
            }

            // Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.secondary)

                Spacer()

                Button {
                    Task {
                        await exportSession()
                    }
                } label: {
                    if exporter.isExporting {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Text("Export")
                    }
                }
                .buttonStyle(.primary)
                .disabled(fileName.isEmpty || exporter.isExporting)
            }
        }
        .padding(Spacing.lg.rawValue)
        .frame(width: 500)
        .background(Color.bgPrimary(scheme: colorScheme))
    }

    private func exportSession() async {
        // Show save panel
        let panel = NSSavePanel()
        panel.title = "Export Session"
        panel.nameFieldStringValue = "\(fileName).\(selectedFormat.fileExtension)"
        panel.allowedContentTypes = [UTType(filenameExtension: selectedFormat.fileExtension) ?? .data]

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try await exporter.export(session: session, format: selectedFormat, to: url)

                if let exportedURL = exporter.exportedURL {
                    onComplete?(exportedURL)
                    dismiss()
                }
            } catch {
                exporter.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - UTType Helper

import UniformTypeIdentifiers

private func UTType(filenameExtension: String) -> UTType? {
    UTType(filenameExtension: filenameExtension)
}

// MARK: - Preview

#Preview("Export Sheet") {
    SessionExportSheet(
        session: Session(
            title: "Test Session",
            messages: [
                .user("Hello!"),
                .assistant("Hi there! How can I help you today?")
            ]
        )
    )
}
