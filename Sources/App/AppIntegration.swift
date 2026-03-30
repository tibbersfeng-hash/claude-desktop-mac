// AppIntegration.swift
// Claude Desktop Mac - App Integration
//
// Public exports for App module and integration helpers

import Foundation

// App Integration Module
public enum AppIntegration {
    /// Initialize all Phase 4 integrations
    public static func initialize() {
        // MenuBar
        MenuBar.initialize()

        // Global shortcuts
        GlobalShortcuts.initialize()

        // Notifications
        Notifications.initialize()

        // Spotlight
        Spotlight.initialize()
    }

    /// Update connection status in MenuBar
    public static func updateConnectionStatus(_ state: ConnectionState) {
        let status: MenuBarStatus
        switch state {
        case .connected:
            status = .connected
        case .connecting, .detecting, .reconnecting:
            status = .connecting
        case .disconnected, .idle, .error, .disconnecting:
            status = .disconnected
        }

        MenuBarController.shared.updateStatus(status)
    }

    /// Update recent sessions in MenuBar
    public static func updateRecentSessions(_ sessions: [Session]) {
        let summaries = sessions.map { SessionSummary(from: $0) }
        MenuBarController.shared.updateRecentSessions(summaries)
    }

    /// Update projects in MenuBar
    public static func updateProjects(_ projects: [Project], current: Project?) {
        MenuBarController.shared.updateProjects(projects, current: current)
    }

    /// Show Quick Ask panel
    public static func showQuickAsk() {
        MenuBar.showQuickAsk()
    }

    /// Show command palette
    public static func showCommandPalette() {
        GlobalShortcuts.showCommandPalette()
    }

    /// Index session for Spotlight
    public static func indexSession(_ session: Session) {
        Spotlight.indexSession(session)
    }

    /// Index project for Spotlight
    public static func indexProject(_ project: Project) {
        Spotlight.indexProject(project)
    }

    /// Send notification for response
    public static func notifyResponse(sessionId: UUID, title: String, message: String, projectName: String? = nil) {
        Notifications.notifyResponse(
            sessionId: sessionId,
            title: title,
            message: message,
            projectName: projectName
        )
    }

    /// Send notification for input needed
    public static func notifyInputNeeded(sessionId: UUID, message: String, projectName: String? = nil) {
        Notifications.notifyInputNeeded(
            sessionId: sessionId,
            message: message,
            projectName: projectName
        )
    }

    /// Set processing state in MenuBar
    public static func setProcessing(_ isProcessing: Bool) {
        if isProcessing {
            MenuBarController.shared.updateStatus(.processing)
        } else {
            MenuBarController.shared.updateStatus(.connected)
        }
    }

    /// Set unread count
    public static func setUnreadCount(_ count: Int) {
        MenuBarController.shared.setUnreadCount(count)
    }
}
