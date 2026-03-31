// DiffViewModel.swift
// Claude Desktop Mac - Diff View Model
//
// Manages diff operations including accept/reject changes

import SwiftUI
import Combine
import Theme
import Models

// MARK: - Diff Operation Result

public enum DiffOperationResult {
    case success
    case failure(String)
    case partial([String])
}

// MARK: - Diff View Model

@MainActor
@Observable
public final class DiffViewModel {

    // MARK: - Properties

    /// The file diff being displayed
    public var fileDiff: FileDiff?

    /// Whether changes have been accepted
    public var isAccepted: Bool = false

    /// Whether changes have been rejected
    public var isRejected: Bool = false

    /// Whether an operation is in progress
    public var isProcessing: Bool = false

    /// Error message if operation failed
    public var errorMessage: String?

    /// Success message after operation
    public var successMessage: String?

    /// Selected hunks for partial accept/reject
    public var selectedHunkIds: Set<UUID> = []

    // MARK: - Computed Properties

    /// Whether there are pending changes
    public var hasPendingChanges: Bool {
        !isAccepted && !isRejected
    }

    /// Whether any hunks are selected
    public var hasSelectedHunks: Bool {
        !selectedHunkIds.isEmpty
    }

    // MARK: - Initialization

    public init(fileDiff: FileDiff? = nil) {
        self.fileDiff = fileDiff
    }

    // MARK: - Public Methods

    /// Set the file diff
    public func setFileDiff(_ diff: FileDiff) {
        self.fileDiff = diff
        self.isAccepted = false
        self.isRejected = false
        self.selectedHunkIds = []
        clearMessages()
    }

    /// Accept all changes in the diff
    public func acceptAll() async -> DiffOperationResult {
        guard let diff = fileDiff else {
            return .failure("No diff to accept")
        }

        isProcessing = true
        clearMessages()

        defer {
            isProcessing = false
        }

        do {
            // Apply the changes to the file
            try await applyChanges(diff)

            isAccepted = true
            successMessage = "Changes accepted successfully"

            return .success
        } catch {
            errorMessage = "Failed to accept changes: \(error.localizedDescription)"
            return .failure(errorMessage!)
        }
    }

    /// Reject all changes in the diff
    public func rejectAll() async -> DiffOperationResult {
        guard let _ = fileDiff else {
            return .failure("No diff to reject")
        }

        isProcessing = true
        clearMessages()

        defer {
            isProcessing = false
        }

        // Rejecting means discarding the changes - no file operation needed
        isRejected = true
        successMessage = "Changes rejected"

        return .success
    }

    /// Accept only selected hunks
    public func acceptSelected() async -> DiffOperationResult {
        guard let diff = fileDiff else {
            return .failure("No diff to accept")
        }

        if selectedHunkIds.isEmpty {
            return .failure("No hunks selected")
        }

        isProcessing = true
        clearMessages()

        defer {
            isProcessing = false
        }

        do {
            // Apply only selected hunks
            let selectedHunks = diff.hunks.filter { selectedHunkIds.contains($0.id) }
            try await applyPartialChanges(diff, hunks: selectedHunks)

            isAccepted = true
            successMessage = "Selected changes accepted"

            return .success
        } catch {
            errorMessage = "Failed to accept selected changes: \(error.localizedDescription)"
            return .failure(errorMessage!)
        }
    }

    /// Reject only selected hunks
    public func rejectSelected() async -> DiffOperationResult {
        guard let diff = fileDiff else {
            return .failure("No diff to reject")
        }

        if selectedHunkIds.isEmpty {
            return .failure("No hunks selected")
        }

        isProcessing = true
        clearMessages()

        defer {
            isProcessing = false
        }

        // Apply all hunks except the rejected ones
        do {
            let acceptedHunks = diff.hunks.filter { !selectedHunkIds.contains($0.id) }
            try await applyPartialChanges(diff, hunks: acceptedHunks)

            isAccepted = true
            successMessage = "Selected changes rejected"

            return .success
        } catch {
            errorMessage = "Failed to reject selected changes: \(error.localizedDescription)"
            return .failure(errorMessage!)
        }
    }

    /// Toggle hunk selection
    public func toggleHunkSelection(_ hunkId: UUID) {
        if selectedHunkIds.contains(hunkId) {
            selectedHunkIds.remove(hunkId)
        } else {
            selectedHunkIds.insert(hunkId)
        }
    }

    /// Select all hunks
    public func selectAllHunks() {
        guard let diff = fileDiff else { return }
        selectedHunkIds = Set(diff.hunks.map { $0.id })
    }

    /// Clear hunk selection
    public func clearHunkSelection() {
        selectedHunkIds = []
    }

    /// Reset the view model state
    public func reset() {
        fileDiff = nil
        isAccepted = false
        isRejected = false
        selectedHunkIds = []
        clearMessages()
    }

    // MARK: - Private Methods

    private func applyChanges(_ diff: FileDiff) async throws {
        // Read the original file
        let fileURL = URL(fileURLWithPath: diff.filePath)
        let originalContent = try String(contentsOf: fileURL, encoding: .utf8)

        // Apply all hunks to get new content
        let newContent = try applyHunks(diff.hunks, to: originalContent)

        // Write back to file
        try newContent.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func applyPartialChanges(_ diff: FileDiff, hunks: [DiffHunk]) async throws {
        // Read the original file
        let fileURL = URL(fileURLWithPath: diff.filePath)
        let originalContent = try String(contentsOf: fileURL, encoding: .utf8)

        // Apply only selected hunks
        let newContent = try applyHunks(hunks, to: originalContent)

        // Write back to file
        try newContent.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func applyHunks(_ hunks: [DiffHunk], to content: String) throws -> String {
        var lines = content.components(separatedBy: "\n")

        // Sort hunks by their old start position in reverse order
        // This allows us to apply changes from bottom to top without affecting line numbers
        let sortedHunks = hunks.sorted { $0.oldStart > $1.oldStart }

        for hunk in sortedHunks {
            let startIndex = max(0, hunk.oldStart - 1)
            let endIndex = min(lines.count, startIndex + hunk.oldCount)

            // Remove old lines
            lines.removeSubrange(startIndex..<endIndex)

            // Insert new lines (additions)
            let newLines = hunk.lines
                .filter { $0.type == .addition || $0.type == .context }
                .map { $0.content }

            lines.insert(contentsOf: newLines, at: startIndex)
        }

        return lines.joined(separator: "\n")
    }

    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

// MARK: - Diff Hunk Extension

extension DiffHunk {
    /// Check if this hunk contains additions
    public var hasAdditions: Bool {
        lines.contains { $0.type == .addition }
    }

    /// Check if this hunk contains deletions
    public var hasDeletions: Bool {
        lines.contains { $0.type == .deletion }
    }

    /// Get a preview of the changes
    public var changePreview: String {
        let additions = lines.filter { $0.type == .addition }.count
        let deletions = lines.filter { $0.type == .deletion }.count

        var preview = ""
        if additions > 0 {
            preview += "+\(additions)"
        }
        if deletions > 0 {
            if !preview.isEmpty { preview += " " }
            preview += "-\(deletions)"
        }
        return preview
    }
}

// MARK: - File Diff Extension

extension FileDiff {
    /// Create a sample diff for previews
    public static var sample: FileDiff {
        FileDiff(
            filePath: "/src/api/client.swift",
            hunks: [
                DiffHunk(
                    oldStart: 1,
                    oldCount: 5,
                    newStart: 1,
                    newCount: 7,
                    lines: [
                        DiffLine(oldLineNumber: 1, newLineNumber: 1, type: .context, content: "import Foundation"),
                        DiffLine(oldLineNumber: 2, newLineNumber: 2, type: .deletion, content: "class APIClient {"),
                        DiffLine(oldLineNumber: nil, newLineNumber: 3, type: .addition, content: "public class APIClient {"),
                        DiffLine(oldLineNumber: nil, newLineNumber: 4, type: .addition, content: "    private let session: URLSession"),
                        DiffLine(oldLineNumber: 3, newLineNumber: 5, type: .context, content: "    private var baseURL: URL"),
                        DiffLine(oldLineNumber: 4, newLineNumber: 6, type: .deletion, content: "    "),
                        DiffLine(oldLineNumber: 5, newLineNumber: 7, type: .context, content: "    init(baseURL: URL) {")
                    ]
                )
            ]
        )
    }
}

// MARK: - Diff Line Extension

extension DiffLine {
    public init(oldLineNumber: Int?, newLineNumber: Int?, type: DiffLineType, content: String) {
        self.id = UUID()
        self.oldLineNumber = oldLineNumber
        self.newLineNumber = newLineNumber
        self.type = type
        self.content = content
    }
}

// MARK: - Diff Hunk Model

public struct DiffHunk: Identifiable, Sendable {
    public let id: UUID
    public let oldStart: Int
    public let oldCount: Int
    public let newStart: Int
    public let newCount: Int
    public let lines: [DiffLine]

    public init(
        id: UUID = UUID(),
        oldStart: Int,
        oldCount: Int,
        newStart: Int,
        newCount: Int,
        lines: [DiffLine]
    ) {
        self.id = id
        self.oldStart = oldStart
        self.oldCount = oldCount
        self.newStart = newStart
        self.newCount = newCount
        self.lines = lines
    }
}

// MARK: - Diff Line Model

public struct DiffLine: Identifiable, Sendable {
    public let id: UUID
    public let oldLineNumber: Int?
    public let newLineNumber: Int?
    public let type: DiffLineType
    public let content: String

    public init(
        id: UUID = UUID(),
        oldLineNumber: Int?,
        newLineNumber: Int?,
        type: DiffLineType,
        content: String
    ) {
        self.id = id
        self.oldLineNumber = oldLineNumber
        self.newLineNumber = newLineNumber
        self.type = type
        self.content = content
    }
}

// MARK: - Diff Line Type

public enum DiffLineType: String, Sendable {
    case addition
    case deletion
    case context

    public var accessibilityDescription: String {
        switch self {
        case .addition: return "Added line"
        case .deletion: return "Deleted line"
        case .context: return "Context line"
        }
    }

    public var accessibilityHint: String {
        switch self {
        case .addition: return "This line was added"
        case .deletion: return "This line was removed"
        case .context: return "This line is unchanged"
        }
    }
}

// MARK: - File Diff Model

public struct FileDiff: Identifiable, Sendable {
    public let id: UUID
    public let filePath: String
    public let hunks: [DiffHunk]

    public init(id: UUID = UUID(), filePath: String, hunks: [DiffHunk]) {
        self.id = id
        self.filePath = filePath
        self.hunks = hunks
    }

    public var fileName: String {
        (filePath as NSString).lastPathComponent
    }

    public var additions: Int {
        hunks.reduce(0) { $0 + $1.lines.filter { $0.type == .addition }.count }
    }

    public var deletions: Int {
        hunks.reduce(0) { $0 + $1.lines.filter { $0.type == .deletion }.count }
    }
}

// MARK: - Preview

#Preview("Diff View Model") {
    let viewModel = DiffViewModel(fileDiff: .sample)

    return VStack {
        Text("Additions: \(viewModel.fileDiff?.additions ?? 0)")
        Text("Deletions: \(viewModel.fileDiff?.deletions ?? 0)")

        Button("Accept All") {
            Task {
                _ = await viewModel.acceptAll()
            }
        }
    }
    .padding()
}
