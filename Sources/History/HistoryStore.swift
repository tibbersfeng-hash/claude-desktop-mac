// HistoryStore.swift
// Claude Desktop Mac - History Storage
//
// Handles persistence of session history

import Foundation
import Combine

// MARK: - History Store

/// Manages persistent storage of session history
public actor HistoryStore {

    // MARK: - Singleton

    public static let shared = HistoryStore()

    // MARK: - Properties

    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Storage directory URL
    private var storageDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("ClaudeDesktop")

        if !fileManager.fileExists(atPath: appDir.path) {
            try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        }

        return appDir.appendingPathComponent("History")
    }

    /// Sessions file URL
    private var sessionsFileURL: URL {
        storageDirectory.appendingPathComponent("sessions.json")
    }

    /// Index file URL for search
    private var indexFileURL: URL {
        storageDirectory.appendingPathComponent("index.json")
    }

    // MARK: - Initialization

    private init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        // Ensure storage directory exists
        try? fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Session Storage

    /// Save a session to history
    public func saveSession(_ session: Session) async throws {
        var sessions = try await loadAllSessions()

        // Update existing or add new
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.append(session)
        }

        // Sort by update time
        sessions.sort { $0.updatedAt > $1.updatedAt }

        // Keep only last 100 sessions
        if sessions.count > 100 {
            sessions = Array(sessions.prefix(100))
        }

        try await saveSessions(sessions)
    }

    /// Load all sessions from history
    public func loadAllSessions() async throws -> [Session] {
        guard fileManager.fileExists(atPath: sessionsFileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: sessionsFileURL)
        return try decoder.decode([Session].self, from: data)
    }

    /// Load a specific session by ID
    public func loadSession(id: UUID) async throws -> Session? {
        let sessions = try await loadAllSessions()
        return sessions.first { $0.id == id }
    }

    /// Delete a session from history
    public func deleteSession(_ id: UUID) async throws {
        var sessions = try await loadAllSessions()
        sessions.removeAll { $0.id == id }
        try await saveSessions(sessions)
    }

    /// Clear all history
    public func clearAllHistory() async throws {
        try fileManager.removeItem(at: sessionsFileURL)
    }

    // MARK: - Search Index

    /// Build search index
    public func buildSearchIndex() async throws -> SearchIndex {
        let sessions = try await loadAllSessions()
        var index = SearchIndex()

        for session in sessions {
            for message in session.messages {
                let entry = SearchIndex.Entry(
                    sessionId: session.id,
                    messageId: message.id,
                    sessionTitle: session.title,
                    projectName: session.projectName ?? session.projectPath?.split(separator: "/").last.map(String.init) ?? "",
                    content: message.content,
                    timestamp: message.timestamp
                )
                index.entries.append(entry)
            }
        }

        // Sort by timestamp
        index.entries.sort { $0.timestamp > $1.timestamp }

        // Save index
        let data = try encoder.encode(index)
        try data.write(to: indexFileURL)

        return index
    }

    /// Load search index
    public func loadSearchIndex() async throws -> SearchIndex {
        guard fileManager.fileExists(atPath: indexFileURL.path) else {
            return try await buildSearchIndex()
        }

        let data = try Data(contentsOf: indexFileURL)
        return try decoder.decode(SearchIndex.self, from: data)
    }

    // MARK: - Private Methods

    private func saveSessions(_ sessions: [Session]) async throws {
        let data = try encoder.encode(sessions)
        try data.write(to: sessionsFileURL, options: .atomic)
    }
}

// MARK: - Search Index

/// Search index for fast history searches
public struct SearchIndex: Codable, Sendable {
    public var entries: [Entry] = []

    public struct Entry: Codable, Identifiable, Sendable {
        public let id: UUID
        public let sessionId: UUID
        public let messageId: UUID
        public let sessionTitle: String
        public let projectName: String
        public let content: String
        public let timestamp: Date

        public init(
            id: UUID = UUID(),
            sessionId: UUID,
            messageId: UUID,
            sessionTitle: String,
            projectName: String,
            content: String,
            timestamp: Date
        ) {
            self.id = id
            self.sessionId = sessionId
            self.messageId = messageId
            self.sessionTitle = sessionTitle
            self.projectName = projectName
            self.content = content
            self.timestamp = timestamp
        }
    }

    public init() {}

    public init(entries: [Entry]) {
        self.entries = entries
    }
}

// MARK: - History Statistics

/// Statistics about the history
public struct HistoryStatistics: Codable, Sendable {
    public let totalSessions: Int
    public let totalMessages: Int
    public let oldestSession: Date?
    public let newestSession: Date?
    public let projectCounts: [String: Int]
    public let storageSize: Int64

    public init(
        totalSessions: Int,
        totalMessages: Int,
        oldestSession: Date?,
        newestSession: Date?,
        projectCounts: [String: Int],
        storageSize: Int64
    ) {
        self.totalSessions = totalSessions
        self.totalMessages = totalMessages
        self.oldestSession = oldestSession
        self.newestSession = newestSession
        self.projectCounts = projectCounts
        self.storageSize = storageSize
    }

    public var formattedStorageSize: String {
        ByteCountFormatter.string(fromByteCount: storageSize, countStyle: .file)
    }
}

extension HistoryStore {
    /// Get history statistics
    public func getStatistics() async throws -> HistoryStatistics {
        let sessions = try await loadAllSessions()

        let totalMessages = sessions.reduce(0) { $0 + $1.messages.count }
        let dates = sessions.map { $0.updatedAt }
        let oldestSession = dates.min()
        let newestSession = dates.max()

        var projectCounts: [String: Int] = [:]
        for session in sessions {
            let project = session.projectName ?? session.projectPath?.split(separator: "/").last.map(String.init) ?? "Unknown"
            projectCounts[project, default: 0] += 1
        }

        let storageSize: Int64
        if let attributes = try? fileManager.attributesOfItem(atPath: sessionsFileURL.path),
           let size = attributes[.size] as? Int64 {
            storageSize = size
        } else {
            storageSize = 0
        }

        return HistoryStatistics(
            totalSessions: sessions.count,
            totalMessages: totalMessages,
            oldestSession: oldestSession,
            newestSession: newestSession,
            projectCounts: projectCounts,
            storageSize: storageSize
        )
    }
}
