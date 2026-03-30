// SessionListViewModel.swift
// Claude Desktop Mac - Session List ViewModel
//
// Manages session list state and operations

import Foundation
import SwiftUI
import Combine

// MARK: - Session List ViewModel

@MainActor
@Observable
public final class SessionListViewModel {

    // MARK: - Properties

    /// All sessions
    public var sessions: [Session] = []

    /// Currently selected session ID
    public var selectedSessionId: UUID?

    /// Loading state
    public var isLoading: Bool = false

    /// Error message
    public var errorMessage: String?

    /// Search query
    public var searchQuery: String = ""

    /// Whether to show the new session dialog
    public var showNewSessionDialog: Bool = false

    /// Session being renamed
    public var renamingSessionId: UUID?

    /// New title for rename
    public var newTitle: String = ""

    // MARK: - Computed Properties

    /// Filtered sessions based on search
    public var filteredSessions: [Session] {
        if searchQuery.isEmpty {
            return sessions
        }
        return sessions.filter { session in
            session.title.localizedCaseInsensitiveContains(searchQuery) ||
            session.projectName?.localizedCaseInsensitiveContains(searchQuery) ?? false
        }
    }

    /// Currently selected session
    public var selectedSession: Session? {
        guard let id = selectedSessionId else { return nil }
        return sessions.first { $0.id == id }
    }

    /// Whether there are any sessions
    public var hasSessions: Bool {
        !sessions.isEmpty
    }

    // MARK: - Private Properties

    private let storageKey = "claude-desktop-sessions"
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init() {
        loadSessions()
    }

    // MARK: - Session Operations

    /// Create a new session
    @discardableResult
    public func createSession(projectPath: String? = nil, projectName: String? = nil) -> Session {
        let session = Session(
            title: "New Chat",
            projectPath: projectPath,
            projectName: projectName
        )
        sessions.insert(session, at: 0)
        selectedSessionId = session.id
        saveSessions()
        return session
    }

    /// Select a session
    public func selectSession(_ id: UUID) {
        selectedSessionId = id
    }

    /// Delete a session
    public func deleteSession(_ id: UUID) {
        sessions.removeAll { $0.id == id }

        // If deleted session was selected, select another
        if selectedSessionId == id {
            selectedSessionId = sessions.first?.id
        }

        saveSessions()
    }

    /// Start renaming a session
    public func startRenaming(_ id: UUID) {
        renamingSessionId = id
        if let session = sessions.first(where: { $0.id == id }) {
            newTitle = session.title
        }
    }

    /// Complete renaming
    public func completeRenaming() {
        guard let id = renamingSessionId,
              let index = sessions.firstIndex(where: { $0.id == id }),
              !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            cancelRenaming()
            return
        }

        sessions[index].title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        saveSessions()
        cancelRenaming()
    }

    /// Cancel renaming
    public func cancelRenaming() {
        renamingSessionId = nil
        newTitle = ""
    }

    /// Duplicate a session
    public func duplicateSession(_ id: UUID) {
        guard let session = sessions.first(where: { $0.id == id }) else { return }

        var newSession = session
        newSession = Session(
            title: "\(session.title) (Copy)",
            projectPath: session.projectPath,
            projectName: session.projectName,
            model: session.model,
            messages: session.messages,
            createdAt: Date(),
            updatedAt: Date()
        )

        sessions.insert(newSession, at: 0)
        selectedSessionId = newSession.id
        saveSessions()
    }

    /// Clear all sessions
    public func clearAllSessions() {
        sessions.removeAll()
        selectedSessionId = nil
        saveSessions()
    }

    // MARK: - Navigation

    /// Select next session
    public func selectNextSession() {
        guard let currentId = selectedSessionId,
              let currentIndex = filteredSessions.firstIndex(where: { $0.id == currentId }) else {
            selectedSessionId = filteredSessions.first?.id
            return
        }

        let nextIndex = currentIndex + 1
        if nextIndex < filteredSessions.count {
            selectedSessionId = filteredSessions[nextIndex].id
        }
    }

    /// Select previous session
    public func selectPreviousSession() {
        guard let currentId = selectedSessionId,
              let currentIndex = filteredSessions.firstIndex(where: { $0.id == currentId }) else {
            selectedSessionId = filteredSessions.first?.id
            return
        }

        let previousIndex = currentIndex - 1
        if previousIndex >= 0 {
            selectedSessionId = filteredSessions[previousIndex].id
        }
    }

    // MARK: - Persistence

    /// Load sessions from storage
    public func loadSessions() {
        isLoading = true

        Task {
            do {
                if let data = UserDefaults.standard.data(forKey: storageKey) {
                    sessions = try JSONDecoder().decode([Session].self, from: data)
                    // Sort by updated date, newest first
                    sessions.sort { $0.updatedAt > $1.updatedAt }
                    selectedSessionId = sessions.first?.id
                }
            } catch {
                errorMessage = "Failed to load sessions: \(error.localizedDescription)"
            }

            isLoading = false
        }
    }

    /// Save sessions to storage
    public func saveSessions() {
        Task {
            do {
                let data = try JSONEncoder().encode(sessions)
                UserDefaults.standard.set(data, forKey: storageKey)
            } catch {
                errorMessage = "Failed to save sessions: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Session Update

    /// Update a session
    public func updateSession(_ session: Session) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[index] = session
        saveSessions()
    }

    /// Add a message to the current session
    public func addMessageToCurrentSession(_ message: ChatMessage) {
        guard let sessionId = selectedSessionId,
              let index = sessions.firstIndex(where: { $0.id == sessionId }) else { return }

        sessions[index].addMessage(message)
        saveSessions()
    }

    /// Update message content in current session
    public func updateMessageContent(_ messageId: UUID, content: String) {
        guard let sessionId = selectedSessionId,
              let sessionIndex = sessions.firstIndex(where: { $0.id == sessionId }),
              let messageIndex = sessions[sessionIndex].messages.firstIndex(where: { $0.id == messageId }) else { return }

        sessions[sessionIndex].messages[messageIndex].content = content
        sessions[sessionIndex].touch()
        saveSessions()
    }

    /// Update message status in current session
    public func updateMessageStatus(_ messageId: UUID, status: MessageStatus) {
        guard let sessionId = selectedSessionId,
              let sessionIndex = sessions.firstIndex(where: { $0.id == sessionId }),
              let messageIndex = sessions[sessionIndex].messages.firstIndex(where: { $0.id == messageId }) else { return }

        sessions[sessionIndex].messages[messageIndex].status = status
        saveSessions()
    }
}
