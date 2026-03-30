// SpotlightIndexer.swift
// Claude Desktop Mac - Spotlight Indexer
//
// Manages Core Spotlight indexing for sessions and projects

import Foundation
import CoreSpotlight
import UniformTypeIdentifiers
import Models
import Project

// MARK: - Spotlight Index Manager

/// Manages Core Spotlight indexing for searchable content
public final class SpotlightIndexer {

    // MARK: - Singleton

    public static let shared = SpotlightIndexer()

    // MARK: - Properties

    private let index = CSSearchableIndex(name: "com.claude.desktop")
    private let indexingQueue = DispatchQueue(label: "com.claude.desktop.spotlight", qos: .utility)

    // MARK: - Domain Identifiers

    public enum Domain: String {
        case sessions = "com.claude.desktop.sessions"
        case projects = "com.claude.desktop.projects"
    }

    // MARK: - Initialization

    private init() {
        setupIndexDelegate()
    }

    // MARK: - Setup

    private func setupIndexDelegate() {
        index.indexDelegate = SpotlightIndexDelegate.shared
    }

    // MARK: - Session Indexing

    /// Index a single session
    public func indexSession(_ session: Session) {
        indexingQueue.async { [weak self] in
            guard let item = self?.createSessionItem(session) else { return }
            self?.index.indexSearchableItems([item]) { error in
                if let error = error {
                    print("Failed to index session: \(error)")
                }
            }
        }
    }

    /// Index multiple sessions
    public func indexSessions(_ sessions: [Session]) {
        indexingQueue.async { [weak self] in
            let items = sessions.compactMap { self?.createSessionItem($0) }
            self?.index.indexSearchableItems(items) { error in
                if let error = error {
                    print("Failed to index sessions: \(error)")
                }
            }
        }
    }

    /// Update a session in the index
    public func updateSession(_ session: Session) {
        indexSession(session)
    }

    /// Delete a session from the index
    public func deleteSession(withId id: UUID) {
        indexingQueue.async { [weak self] in
            self?.index.deleteSearchableItems(withIdentifiers: [id.uuidString]) { error in
                if let error = error {
                    print("Failed to delete session from index: \(error)")
                }
            }
        }
    }

    /// Delete all sessions from the index
    public func deleteAllSessions() {
        indexingQueue.async { [weak self] in
            self?.index.deleteSearchableItems(withDomainIdentifiers: [Domain.sessions.rawValue]) { error in
                if let error = error {
                    print("Failed to delete all sessions from index: \(error)")
                }
            }
        }
    }

    // MARK: - Project Indexing

    /// Index a single project
    public func indexProject(_ project: Project) {
        indexingQueue.async { [weak self] in
            guard let item = self?.createProjectItem(project) else { return }
            self?.index.indexSearchableItems([item]) { error in
                if let error = error {
                    print("Failed to index project: \(error)")
                }
            }
        }
    }

    /// Index multiple projects
    public func indexProjects(_ projects: [Project]) {
        indexingQueue.async { [weak self] in
            let items = projects.compactMap { self?.createProjectItem($0) }
            self?.index.indexSearchableItems(items) { error in
                if let error = error {
                    print("Failed to index projects: \(error)")
                }
            }
        }
    }

    /// Delete a project from the index
    public func deleteProject(withId id: UUID) {
        indexingQueue.async { [weak self] in
            self?.index.deleteSearchableItems(withIdentifiers: [id.uuidString]) { error in
                if let error = error {
                    print("Failed to delete project from index: \(error)")
                }
            }
        }
    }

    // MARK: - Item Creation

    private func createSessionItem(_ session: Session) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: UTType.item.identifier)

        // Basic info
        attributeSet.title = session.title
        attributeSet.contentDescription = createSessionDescription(session)

        // Keywords for better searchability
        var keywords = ["Claude", "Claude Desktop", "AI", "conversation"]
        if let projectName = session.projectName {
            keywords.append(projectName)
        }
        attributeSet.keywords = keywords

        // Add searchable content from messages
        let messageContent = session.messages
            .map { $0.content }
            .joined(separator: " ")
            .prefix(1000)

        attributeSet.contentDescription? += "\n\(messageContent)"

        // Deep link URL
        let urlString = "claude://session/\(session.id.uuidString)"
        attributeSet.relatedUniqueIdentifier = urlString

        // Timestamp
        attributeSet.lastUsedDate = session.updatedAt

        // Create searchable item
        return CSSearchableItem(
            uniqueIdentifier: session.id.uuidString,
            domainIdentifier: Domain.sessions.rawValue,
            attributeSet: attributeSet
        )
    }

    private func createProjectItem(_ project: Project) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: UTType.folder.identifier)

        // Basic info
        attributeSet.title = project.name
        attributeSet.contentDescription = """
        Claude Desktop Project
        Path: \(project.path.path)
        Sessions: \(project.activeSessionCount)
        """

        // Keywords
        attributeSet.keywords = [
            "Claude",
            "Claude Desktop",
            "Project",
            project.name
        ]

        // Deep link URL
        let urlString = "claude://project/\(project.id.uuidString)"
        attributeSet.relatedUniqueIdentifier = urlString

        // Timestamp
        attributeSet.lastUsedDate = project.lastAccessedAt

        // Create searchable item
        return CSSearchableItem(
            uniqueIdentifier: project.id.uuidString,
            domainIdentifier: Domain.projects.rawValue,
            attributeSet: attributeSet
        )
    }

    private func createSessionDescription(_ session: Session) -> String {
        var parts: [String] = []

        if let projectName = session.projectName {
            parts.append("Project: \(projectName)")
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        parts.append("Date: \(formatter.string(from: session.createdAt))")

        parts.append("Messages: \(session.messages.count)")

        // Add preview of last message
        if let lastMessage = session.messages.last {
            let preview = String(lastMessage.content.prefix(100))
            parts.append("Preview: \(preview)...")
        }

        return parts.joined(separator: "\n")
    }

    // MARK: - Batch Operations

    /// Reindex all content
    public func reindexAll(sessions: [Session], projects: [Project]) {
        indexingQueue.async { [weak self] in
            // Delete existing index
            self?.index.deleteAllSearchableItems { error in
                if let error = error {
                    print("Failed to clear index: \(error)")
                    return
                }

                // Index sessions
                let sessionItems = sessions.compactMap { self?.createSessionItem($0) }
                self?.index.indexSearchableItems(sessionItems) { error in
                    if let error = error {
                        print("Failed to index sessions: \(error)")
                    }
                }

                // Index projects
                let projectItems = projects.compactMap { self?.createProjectItem($0) }
                self?.index.indexSearchableItems(projectItems) { error in
                    if let error = error {
                        print("Failed to index projects: \(error)")
                    }
                }
            }
        }
    }
}

// MARK: - Spotlight Index Delegate

private class SpotlightIndexDelegate: NSObject, CSSearchableIndexDelegate {
    static let shared = SpotlightIndexDelegate()

    func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping () -> Void) {
        // Reindex all content
        Task {
            // This would typically fetch all sessions and projects from storage
            // For now, we'll just acknowledge
            acknowledgementHandler()
        }
    }

    func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexSearchableItemsWithIdentifiers identifiers: [String], acknowledgementHandler: @escaping () -> Void) {
        // Reindex specific items
        Task {
            for identifier in identifiers {
                // Fetch and reindex item with identifier
            }
            acknowledgementHandler()
        }
    }
}

// MARK: - Session Extension for Spotlight

extension Session {
    /// Create a searchable summary
    public var searchableSummary: String {
        let messageSummaries = messages.map { "\($0.role.rawValue): \($0.content.prefix(100))" }
        return messageSummaries.joined(separator: "\n")
    }
}
