// SpotlightHandler.swift
// Claude Desktop Mac - Spotlight Handler
//
// Handles Spotlight search results and user selection

import Foundation
import CoreSpotlight
import AppKit

// MARK: - Spotlight Handler

/// Handles Spotlight search events and results
@MainActor
public final class SpotlightHandler {

    // MARK: - Singleton

    public static let shared = SpotlightHandler()

    // MARK: - Properties

    private var isIndexed: Bool = false

    // MARK: - Initialization

    private init() {
        setupNotifications()
    }

    // MARK: - Setup

    private func setupNotifications() {
        // Listen for app launch from Spotlight
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppLaunch),
            name: NSApplication.didFinishLaunchingNotification,
            object: nil
        )
    }

    @objc private func handleAppLaunch(_ notification: Notification) {
        // Check if launched from Spotlight
        checkForSpotlightLaunch()
    }

    private func checkForSpotlightLaunch() {
        // This would be handled by AppDelegate's continueUserActivity
    }

    // MARK: - Public Methods

    /// Handle selection of a Spotlight search result
    public func handleSearchResult(identifier: String, completionHandler: @escaping (Bool) -> Void) {
        // Parse identifier and navigate to content
        let handled = DeepLinkHandler.shared.handleURL(URL(string: identifier) ?? URL(fileURLWithPath: ""))
        completionHandler(handled)
    }

    /// Index all sessions and projects for Spotlight
    public func indexAllContent(sessions: [Session], projects: [Project]) {
        SpotlightIndexer.shared.reindexAll(sessions: sessions, projects: projects)
        isIndexed = true
    }

    /// Update index when session changes
    public func indexSession(_ session: Session) {
        SpotlightIndexer.shared.indexSession(session)
    }

    /// Remove session from index
    public func removeSessionFromIndex(_ sessionId: UUID) {
        SpotlightIndexer.shared.deleteSession(withId: sessionId)
    }

    /// Update index when project changes
    public func indexProject(_ project: Project) {
        SpotlightIndexer.shared.indexProject(project)
    }

    /// Remove project from index
    public func removeProjectFromIndex(_ projectId: UUID) {
        SpotlightIndexer.shared.deleteProject(withId: projectId)
    }
}

// MARK: - Spotlight Search Result

/// Represents a Spotlight search result
public struct SpotlightSearchResult: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let contentDescription: String
    public let type: ResultType
    public let identifier: String

    public enum ResultType: String {
        case session = "Session"
        case project = "Project"
    }
}

// MARK: - Spotlight Query

/// Utility for performing Spotlight queries
public final class SpotlightQuery {

    /// Search for sessions and projects
    public static func search(query: String) async -> [SpotlightSearchResult] {
        guard !query.isEmpty else { return [] }

        var results: [SpotlightSearchResult] = []

        // Create search query
        let searchQuery = CSSearchableQuery(
            queryString: query,
            completionBlock: { queryResults, error in
                if let error = error {
                    print("Spotlight query error: \(error)")
                    return
                }

                guard let queryResults = queryResults else { return }

                for item in queryResults {
                    let result = SpotlightSearchResult(
                        id: item.uniqueIdentifier,
                        title: item.attributeSet.title ?? "Untitled",
                        subtitle: item.attributeSet.contentDescription ?? "",
                        contentDescription: item.attributeSet.contentDescription ?? "",
                        type: item.domainIdentifier.contains("session") ? .session : .project,
                        identifier: item.uniqueIdentifier
                    )
                    results.append(result)
                }
            }
        )

        // Execute query
        searchQuery.start()

        // Wait for completion
        // Note: In real implementation, this should use async/await properly
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        searchQuery.stop()

        return results
    }
}

// MARK: - AppDelegate Integration

extension SpotlightHandler {

    /// Configure Spotlight integration for AppDelegate
    public static func configure(for appDelegate: NSApplicationDelegate) {
        // Request indexing
        CSSearchableIndex.default().indexSearchableItems([]) { _ in }
    }
}
