// Session.swift
// Claude Desktop Mac - Session Model
//
// Represents a conversation session with Claude

import Foundation
import SwiftUI

// MARK: - Session Model

/// Represents a conversation session
public struct Session: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var title: String
    public var projectPath: String?
    public var projectName: String?
    public var model: String
    public var messages: [ChatMessage]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String = "New Chat",
        projectPath: String? = nil,
        projectName: String? = nil,
        model: String = "claude-sonnet-4.6",
        messages: [ChatMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.projectPath = projectPath
        self.projectName = projectName
        self.model = model
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Generate title from first user message
    public mutating func generateTitle() {
        guard let firstUserMessage = messages.first(where: { $0.role == .user }) else {
            return
        }

        // Take first 50 characters of the message
        let content = firstUserMessage.content.trimmingCharacters(in: .whitespacesAndNewlines)
        let newTitle = String(content.prefix(50))

        if !newTitle.isEmpty {
            title = newTitle + (content.count > 50 ? "..." : "")
        }
    }

    /// Update the timestamp
    public mutating func touch() {
        updatedAt = Date()
    }

    /// Add a message to the session
    public mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
        touch()

        // Auto-generate title if this is the first user message
        if messages.filter({ $0.role == .user }).count == 1 && message.role == .user {
            generateTitle()
        }
    }

    /// Clear all messages
    public mutating func clearMessages() {
        messages.removeAll()
        touch()
    }

    /// Hashable conformance
    public static func == (lhs: Session, rhs: Session) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Session Summary

/// Lightweight session info for list display
public struct SessionSummary: Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let projectName: String?
    public let messageCount: Int
    public let lastMessageTime: Date?
    public let preview: String?

    public init(from session: Session) {
        self.id = session.id
        self.title = session.title
        self.projectName = session.projectName ?? session.projectPath?.split(separator: "/").last.map(String.init)
        self.messageCount = session.messages.count
        self.lastMessageTime = session.messages.last?.timestamp
        self.preview = session.messages.last?.content.prefix(100).map(String.init)
    }
}

// MARK: - Relative Time Formatting

extension Session {
    /// Relative time string for display
    public var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }
}

// MARK: - Sample Data

extension Session {
    public static var sample: Session {
        Session(
            id: UUID(),
            title: "API Integration Help",
            projectPath: "/Users/dev/projects/claude-desktop-mac",
            projectName: "claude-desktop-mac",
            model: "claude-sonnet-4.6",
            messages: ChatMessage.samples,
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: Date()
        )
    }

    public static var samples: [Session] {
        [
            Session(
                title: "API Integration",
                projectName: "claude-desktop-mac",
                messages: ChatMessage.samples,
                createdAt: Date().addingTimeInterval(-3600),
                updatedAt: Date()
            ),
            Session(
                title: "Bug Fix Session",
                projectName: "my-project",
                messages: [],
                createdAt: Date().addingTimeInterval(-86400),
                updatedAt: Date().addingTimeInterval(-86400)
            ),
            Session(
                title: "Refactoring Code",
                projectName: "work-project",
                messages: [],
                createdAt: Date().addingTimeInterval(-172800),
                updatedAt: Date().addingTimeInterval(-172800)
            )
        ]
    }
}
