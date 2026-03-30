// ToolCall.swift
// Claude Desktop Mac - Tool Call Display Model
//
// UI model for displaying tool calls

import Foundation
import SwiftUI
import Protocol

// MARK: - Tool Call Display

/// UI model for displaying a tool call
public struct ToolCallDisplay: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let arguments: String?
    public let result: String?
    public let error: String?
    public let status: ToolCallDisplayStatus
    public let duration: TimeInterval?
    public var isExpanded: Bool

    public init(
        id: String = UUID().uuidString,
        name: String,
        arguments: String? = nil,
        result: String? = nil,
        error: String? = nil,
        status: ToolCallDisplayStatus = .pending,
        duration: TimeInterval? = nil,
        isExpanded: Bool = false
    ) {
        self.id = id
        self.name = name
        self.arguments = arguments
        self.result = result
        self.error = error
        self.status = status
        self.duration = duration
        self.isExpanded = isExpanded
    }

    /// Create from protocol ToolCall
    public init(from toolCall: ToolCall, isExpanded: Bool = false) {
        self.id = toolCall.id
        self.name = toolCall.name
        self.arguments = toolCall.arguments.flatMap { Self.formatArguments($0) }
        self.result = nil
        self.error = nil
        self.status = Self.mapStatus(toolCall.status)
        self.duration = nil
        self.isExpanded = isExpanded
    }

    /// Tool icon name
    public var iconName: String {
        switch name.lowercased() {
        case "read": return "doc.text"
        case "write": return "square.and.pencil"
        case "edit": return "pencil.tip"
        case "bash": return "terminal"
        case "glob": return "magnifyingglass"
        case "grep": return "text.magnifyingglass"
        case "webfetch": return "globe"
        case "websearch": return "magnifyingglass.circle"
        default: return "wrench.and.screwdriver"
        }
    }

    /// Tool icon color
    public var iconColor: Color {
        switch name.lowercased() {
        case "read": return .blue
        case "write": return .green
        case "edit": return .orange
        case "bash": return .gray
        case "glob": return .purple
        case "grep": return .teal
        case "webfetch": return .blue
        case "websearch": return .cyan
        default: return .secondary
        }
    }

    /// Display name for the tool
    public var displayName: String {
        switch name.lowercased() {
        case "read": return "Read File"
        case "write": return "Write File"
        case "edit": return "Edit File"
        case "bash": return "Bash Command"
        case "glob": return "Glob Search"
        case "grep": return "Grep Search"
        case "webfetch": return "Web Fetch"
        case "websearch": return "Web Search"
        default: return name
        }
    }

    /// Short summary for collapsed display
    public var summary: String {
        // Extract key information for display
        if let arguments = arguments {
            // Try to extract file path or command
            if let pathMatch = arguments.range(of: #"file_path["\s:]+([^",}]+)"#, options: .regularExpression) {
                let path = arguments[pathMatch].split(separator: ":").last?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                if let path = path {
                    let fileName = path.split(separator: "/").last.map(String.init) ?? path
                    return fileName
                }
            }
        }
        return displayName
    }

    /// Duration string
    public var durationString: String? {
        guard let duration = duration else { return nil }
        if duration < 1 {
            return String(format: "%.2fs", duration)
        } else {
            return String(format: "%.1fs", duration)
        }
    }

    // MARK: - Private Helpers

    private static func formatArguments(_ args: [String: JSONValue]) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(args)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }

    private static func mapStatus(_ status: ToolCallStatus) -> ToolCallDisplayStatus {
        switch status {
        case .pending: return .pending
        case .running: return .running
        case .completed: return .success
        case .failed: return .error
        }
    }
}

// MARK: - Tool Call Status

/// Status for tool call display
public enum ToolCallDisplayStatus: String, Codable, Sendable {
    case pending
    case running
    case success
    case error

    public var color: Color {
        switch self {
        case .pending: return .secondary
        case .running: return Color(hex: "FFD60A") // accentWarning
        case .success: return Color(hex: "30D158") // accentSuccess
        case .error: return Color(hex: "FF453A")   // accentError
        }
    }

    public var iconName: String {
        switch self {
        case .pending: return "clock"
        case .running: return "arrow.trianglehead.clockwise"
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        }
    }

    public var accessibilityDescription: String {
        switch self {
        case .pending: return "pending"
        case .running: return "running"
        case .success: return "completed successfully"
        case .error: return "failed with error"
        }
    }
}

// MARK: - Diff Models

/// Represents a file diff
public struct FileDiff: Identifiable, Codable, Sendable {
    public let id: UUID
    public let filePath: String
    public let hunks: [DiffHunk]
    public var isAccepted: Bool?

    public init(
        id: UUID = UUID(),
        filePath: String,
        hunks: [DiffHunk],
        isAccepted: Bool? = nil
    ) {
        self.id = id
        self.filePath = filePath
        self.hunks = hunks
        self.isAccepted = isAccepted
    }

    public var additions: Int {
        hunks.reduce(0) { $0 + $1.additions }
    }

    public var deletions: Int {
        hunks.reduce(0) { $0 + $1.deletions }
    }

    public var fileName: String {
        filePath.split(separator: "/").last.map(String.init) ?? filePath
    }
}

/// A diff hunk (continuous change block)
public struct DiffHunk: Codable, Sendable {
    public let oldStart: Int
    public let oldCount: Int
    public let newStart: Int
    public let newCount: Int
    public let lines: [DiffLine]

    public init(oldStart: Int, oldCount: Int, newStart: Int, newCount: Int, lines: [DiffLine]) {
        self.oldStart = oldStart
        self.oldCount = oldCount
        self.newStart = newStart
        self.newCount = newCount
        self.lines = lines
    }

    public var additions: Int {
        lines.filter { $0.type == .addition }.count
    }

    public var deletions: Int {
        lines.filter { $0.type == .deletion }.count
    }
}

/// A single diff line
public struct DiffLine: Identifiable, Codable, Sendable {
    public let id: UUID
    public let oldLineNumber: Int?
    public let newLineNumber: Int?
    public let content: String
    public let type: DiffLineType

    public init(
        id: UUID = UUID(),
        oldLineNumber: Int?,
        newLineNumber: Int?,
        content: String,
        type: DiffLineType
    ) {
        self.id = id
        self.oldLineNumber = oldLineNumber
        self.newLineNumber = newLineNumber
        self.content = content
        self.type = type
    }
}

/// Type of diff line
public enum DiffLineType: String, Codable, Sendable {
    case context    // Unchanged
    case addition   // Added
    case deletion   // Removed

    /// Accessibility description for the line type
    public var accessibilityDescription: String {
        switch self {
        case .context: return "Context line"
        case .addition: return "Added line"
        case .deletion: return "Removed line"
        }
    }

    /// Accessibility hint for the line type
    public var accessibilityHint: String {
        switch self {
        case .context: return "This line was not modified"
        case .addition: return "This line was added"
        case .deletion: return "This line was removed"
        }
    }
}

// MARK: - Sample Data

extension ToolCallDisplay {
    public static var sample: ToolCallDisplay {
        ToolCallDisplay(
            id: "tc-001",
            name: "Read",
            arguments: """
            {
              "file_path": "/src/services/api.swift",
              "limit": 100
            }
            """,
            result: "// File content here...",
            error: nil,
            status: .success,
            duration: 0.23,
            isExpanded: true
        )
    }

    public static var samples: [ToolCallDisplay] {
        [
            ToolCallDisplay(
                name: "Read",
                arguments: "{ \"file_path\": \"/src/api/client.swift\" }",
                result: "245 lines read",
                status: .success,
                duration: 0.15
            ),
            ToolCallDisplay(
                name: "Grep",
                arguments: "{ \"pattern\": \"func.*api\", \"path\": \"/src\" }",
                result: "Found 12 matches",
                status: .success,
                duration: 0.32
            ),
            ToolCallDisplay(
                name: "Edit",
                arguments: "{ \"file_path\": \"/src/api/client.swift\", \"old_string\": \"...\", \"new_string\": \"...\" }",
                error: "Edit failed: could not find exact match",
                status: .error,
                isExpanded: true
            )
        ]
    }
}

extension FileDiff {
    public static var sample: FileDiff {
        FileDiff(
            filePath: "src/services/api.swift",
            hunks: [
                DiffHunk(
                    oldStart: 44,
                    oldCount: 5,
                    newStart: 44,
                    newCount: 7,
                    lines: [
                        DiffLine(oldLineNumber: 44, newLineNumber: 44, content: "", type: .context),
                        DiffLine(oldLineNumber: 45, newLineNumber: nil, content: "func fetchData() {", type: .deletion),
                        DiffLine(oldLineNumber: 46, newLineNumber: nil, content: "    // TODO: Implement", type: .deletion),
                        DiffLine(oldLineNumber: 47, newLineNumber: nil, content: "}", type: .deletion),
                        DiffLine(oldLineNumber: nil, newLineNumber: 45, content: "func fetchData(id: String) async throws -> Data {", type: .addition),
                        DiffLine(oldLineNumber: nil, newLineNumber: 46, content: "    let url = baseURL.appendingPathComponent(id)", type: .addition),
                        DiffLine(oldLineNumber: nil, newLineNumber: 47, content: "    let (data, _) = try await URLSession.shared.data(from: url)", type: .addition),
                        DiffLine(oldLineNumber: nil, newLineNumber: 48, content: "    return data", type: .addition),
                        DiffLine(oldLineNumber: nil, newLineNumber: 49, content: "}", type: .addition),
                        DiffLine(oldLineNumber: 48, newLineNumber: 50, content: "", type: .context)
                    ]
                )
            ]
        )
    }
}

// MARK: - Color Hex Extension (local)

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
