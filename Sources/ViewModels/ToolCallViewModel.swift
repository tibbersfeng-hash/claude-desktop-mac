// ToolCallViewModel.swift
// Claude Desktop Mac - Tool Call ViewModel
//
// Manages tool call display state

import Foundation
import SwiftUI
import Combine
import Models

// MARK: - Tool Call ViewModel

@MainActor
@Observable
public final class ToolCallViewModel {

    // MARK: - Properties

    /// Tool calls for display
    public var toolCalls: [ToolCallDisplay] = []

    /// Expanded states by ID
    public var expandedStates: [String: Bool] = [:]

    /// Selected tool call ID
    public var selectedToolCallId: String?

    /// Filter by status
    public var statusFilter: ToolCallDisplayStatus?

    /// Search query
    public var searchQuery: String = ""

    // MARK: - Computed Properties

    /// Filtered tool calls
    public var filteredToolCalls: [ToolCallDisplay] {
        var result = toolCalls

        // Apply status filter
        if let status = statusFilter {
            result = result.filter { $0.status == status }
        }

        // Apply search filter
        if !searchQuery.isEmpty {
            result = result.filter { toolCall in
                toolCall.name.localizedCaseInsensitiveContains(searchQuery) ||
                toolCall.arguments?.localizedCaseInsensitiveContains(searchQuery) ?? false
            }
        }

        return result
    }

    /// Count of running tool calls
    public var runningCount: Int {
        toolCalls.filter { $0.status == .running }.count
    }

    /// Count of successful tool calls
    public var successCount: Int {
        toolCalls.filter { $0.status == .success }.count
    }

    /// Count of failed tool calls
    public var errorCount: Int {
        toolCalls.filter { $0.status == .error }.count
    }

    /// Whether any tool calls are running
    public var hasRunning: Bool {
        runningCount > 0
    }

    /// Selected tool call
    public var selectedToolCall: ToolCallDisplay? {
        guard let id = selectedToolCallId else { return nil }
        return toolCalls.first { $0.id == id }
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - Tool Call Management

    /// Add a tool call
    public func addToolCall(_ toolCall: ToolCallDisplay) {
        // Check if already exists
        if let index = toolCalls.firstIndex(where: { $0.id == toolCall.id }) {
            toolCalls[index] = toolCall
        } else {
            toolCalls.append(toolCall)
            // Auto-expand if it's an error
            if toolCall.status == .error {
                expandedStates[toolCall.id] = true
            }
        }
    }

    /// Update a tool call
    public func updateToolCall(_ toolCall: ToolCallDisplay) {
        guard let index = toolCalls.firstIndex(where: { $0.id == toolCall.id }) else {
            addToolCall(toolCall)
            return
        }
        toolCalls[index] = toolCall
    }

    /// Remove a tool call
    public func removeToolCall(_ id: String) {
        toolCalls.removeAll { $0.id == id }
        expandedStates.removeValue(forKey: id)
    }

    /// Clear all tool calls
    public func clearToolCalls() {
        toolCalls.removeAll()
        expandedStates.removeAll()
        selectedToolCallId = nil
    }

    // MARK: - Expansion

    /// Toggle expanded state
    public func toggleExpanded(_ id: String) {
        expandedStates[id] = !(expandedStates[id] ?? false)
    }

    /// Check if expanded
    public func isExpanded(_ id: String) -> Bool {
        expandedStates[id] ?? false
    }

    /// Expand all
    public func expandAll() {
        for toolCall in toolCalls {
            expandedStates[toolCall.id] = true
        }
    }

    /// Collapse all
    public func collapseAll() {
        for toolCall in toolCalls {
            expandedStates[toolCall.id] = false
        }
    }

    /// Expand errors only
    public func expandErrors() {
        for toolCall in toolCalls {
            expandedStates[toolCall.id] = (toolCall.status == .error)
        }
    }

    // MARK: - Selection

    /// Select a tool call
    public func selectToolCall(_ id: String) {
        selectedToolCallId = id
    }

    /// Deselect
    public func deselectToolCall() {
        selectedToolCallId = nil
    }

    // MARK: - Filtering

    /// Set status filter
    public func setStatusFilter(_ status: ToolCallDisplayStatus?) {
        statusFilter = status
    }

    /// Clear filters
    public func clearFilters() {
        statusFilter = nil
        searchQuery = ""
    }

    // MARK: - Copy Operations

    /// Copy tool result to clipboard
    public func copyResult(_ id: String) {
        guard let toolCall = toolCalls.first(where: { $0.id == id }),
              let result = toolCall.result else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(result, forType: .string)
    }

    /// Copy tool arguments to clipboard
    public func copyArguments(_ id: String) {
        guard let toolCall = toolCalls.first(where: { $0.id == id }),
              let arguments = toolCall.arguments else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(arguments, forType: .string)
    }
}

// MARK: - Diff ViewModel

@MainActor
@Observable
public final class DiffViewModel {

    // MARK: - Properties

    /// Current file diff being displayed
    public var fileDiff: FileDiff?

    /// View mode (unified or side-by-side)
    public var viewMode: DiffViewMode = .unified

    /// Show line numbers
    public var showLineNumbers: Bool = true

    /// Wrap long lines
    public var wrapLines: Bool = false

    /// Selected hunk index
    public var selectedHunkIndex: Int?

    /// Current scroll position
    public var scrollPosition: Int = 0

    // MARK: - Computed Properties

    /// Total additions
    public var totalAdditions: Int {
        fileDiff?.additions ?? 0
    }

    /// Total deletions
    public var totalDeletions: Int {
        fileDiff?.deletions ?? 0
    }

    /// File name
    public var fileName: String {
        fileDiff?.fileName ?? ""
    }

    /// File path
    public var filePath: String {
        fileDiff?.filePath ?? ""
    }

    /// All lines for unified view
    public var allLines: [DiffLine] {
        fileDiff?.hunks.flatMap { $0.lines } ?? []
    }

    /// Selected hunk
    public var selectedHunk: DiffHunk? {
        guard let index = selectedHunkIndex, let diff = fileDiff else { return nil }
        return diff.hunks.indices.contains(index) ? diff.hunks[index] : nil
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - File Operations

    /// Load a file diff
    public func loadDiff(_ diff: FileDiff) {
        fileDiff = diff
        selectedHunkIndex = nil
        scrollPosition = 0
    }

    /// Clear the diff
    public func clearDiff() {
        fileDiff = nil
        selectedHunkIndex = nil
        scrollPosition = 0
    }

    // MARK: - View Mode

    /// Toggle view mode
    public func toggleViewMode() {
        viewMode = viewMode == .unified ? .sideBySide : .unified
    }

    /// Set view mode
    public func setViewMode(_ mode: DiffViewMode) {
        viewMode = mode
    }

    // MARK: - Navigation

    /// Select next hunk
    public func selectNextHunk() {
        guard let diff = fileDiff else { return }

        if let current = selectedHunkIndex {
            let next = current + 1
            if next < diff.hunks.count {
                selectedHunkIndex = next
            }
        } else {
            selectedHunkIndex = 0
        }
    }

    /// Select previous hunk
    public func selectPreviousHunk() {
        guard let diff = fileDiff else { return }

        if let current = selectedHunkIndex {
            let prev = current - 1
            if prev >= 0 {
                selectedHunkIndex = prev
            }
        } else {
            selectedHunkIndex = diff.hunks.count - 1
        }
    }

    /// Scroll to first change
    public func scrollToFirstChange() {
        guard let diff = fileDiff,
              let firstHunk = diff.hunks.first else { return }

        // Find the line number of the first change
        for (index, line) in allLines.enumerated() {
            if line.type != .context {
                scrollPosition = max(0, index - 2)
                return
            }
        }
    }

    // MARK: - Accept/Reject

    /// Accept the diff
    public func acceptDiff() {
        fileDiff?.isAccepted = true
    }

    /// Reject the diff
    public func rejectDiff() {
        fileDiff?.isAccepted = false
    }

    /// Accept selected hunk
    public func acceptHunk(_ index: Int) {
        // This would need to be implemented with actual diff manipulation
    }

    /// Reject selected hunk
    public func rejectHunk(_ index: Int) {
        // This would need to be implemented with actual diff manipulation
    }

    // MARK: - Copy

    /// Copy diff to clipboard
    public func copyDiff() {
        guard let diff = fileDiff else { return }

        var text = "--- \(diff.filePath)\n"
        text += "+++ \(diff.filePath)\n"

        for hunk in diff.hunks {
            text += "@@ -\(hunk.oldStart),\(hunk.oldCount) +\(hunk.newStart),\(hunk.newCount) @@\n"
            for line in hunk.lines {
                let prefix: String
                switch line.type {
                case .addition: prefix = "+"
                case .deletion: prefix = "-"
                case .context: prefix = " "
                }
                text += "\(prefix)\(line.content)\n"
            }
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

// MARK: - Diff View Mode

public enum DiffViewMode: String, CaseIterable {
    case unified
    case sideBySide

    public var displayName: String {
        switch self {
        case .unified: return "Unified"
        case .sideBySide: return "Side by Side"
        }
    }
}
