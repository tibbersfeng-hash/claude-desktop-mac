// Spotlight.swift
// Claude Desktop Mac - Spotlight Module
//
// Public exports for Spotlight module

import Foundation
import Models
import Project

// Spotlight Module
@MainActor
public enum Spotlight {
    /// Initialize Spotlight integration
    public static func initialize() {
        _ = SpotlightHandler.shared
    }

    /// Index a session for Spotlight
    public static func indexSession(_ session: Session) {
        SpotlightIndexer.shared.indexSession(session)
    }

    /// Index multiple sessions
    public static func indexSessions(_ sessions: [Session]) {
        SpotlightIndexer.shared.indexSessions(sessions)
    }

    /// Index a project for Spotlight
    public static func indexProject(_ project: Project) {
        SpotlightIndexer.shared.indexProject(project)
    }

    /// Index multiple projects
    public static func indexProjects(_ projects: [Project]) {
        SpotlightIndexer.shared.indexProjects(projects)
    }

    /// Reindex all content
    public static func reindexAll(sessions: [Session], projects: [Project]) {
        SpotlightIndexer.shared.reindexAll(sessions: sessions, projects: projects)
    }

    /// Remove a session from index
    public static func removeSession(_ sessionId: UUID) {
        SpotlightIndexer.shared.deleteSession(withId: sessionId)
    }

    /// Remove a project from index
    public static func removeProject(_ projectId: UUID) {
        SpotlightIndexer.shared.deleteProject(withId: projectId)
    }

    /// Handle a deep link URL
    public static func handleURL(_ url: URL) -> Bool {
        DeepLinkHandler.shared.handleURL(url)
    }

    /// Create a session deep link
    public static func sessionURL(_ sessionId: UUID) -> URL {
        DeepLinkHandler.shared.sessionURL(sessionId)
    }

    /// Create a project deep link
    public static func projectURL(_ projectId: UUID) -> URL {
        DeepLinkHandler.shared.projectURL(projectId)
    }

    /// Set deep link handlers
    public static func setHandlers(
        onOpenSession: ((UUID) -> Void)? = nil,
        onOpenProject: ((UUID) -> Void)? = nil,
        onShowQuickAsk: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil,
        onNewSession: (() -> Void)? = nil
    ) {
        let handler = DeepLinkHandler.shared
        handler.onOpenSession = onOpenSession
        handler.onOpenProject = onOpenProject
        handler.onShowQuickAsk = onShowQuickAsk
        handler.onOpenSettings = onOpenSettings
        handler.onNewSession = onNewSession
    }
}
