// DeepLinkHandler.swift
// Claude Desktop Mac - Deep Link Handler
//
// Handles URL scheme deep links for opening specific content

import Foundation
import AppKit
import CoreSpotlight
import UniformTypeIdentifiers

// MARK: - Deep Link Manager

/// Manages deep link handling for the application
@MainActor
public final class DeepLinkHandler {

    // MARK: - Singleton

    public static let shared = DeepLinkHandler()

    // MARK: - URL Scheme

    public static let scheme = "claude"

    // MARK: - Path Types

    public enum DeepLinkPath: String {
        case session = "session"
        case project = "project"
        case quickAsk = "quickask"
        case settings = "settings"
        case newSession = "new"
    }

    // MARK: - Callbacks

    public var onOpenSession: ((UUID) -> Void)?
    public var onOpenProject: ((UUID) -> Void)?
    public var onShowQuickAsk: (() -> Void)?
    public var onOpenSettings: (() -> Void)?
    public var onNewSession: (() -> Void)?

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Handle an incoming URL
    public func handleURL(_ url: URL) -> Bool {
        guard url.scheme == Self.scheme else {
            print("Invalid URL scheme: \(url.scheme ?? "nil")")
            return false
        }

        let host = url.host
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch host {
        case DeepLinkPath.session.rawValue:
            return handleSessionURL(pathComponents: pathComponents, queryItems: url.queryItems)

        case DeepLinkPath.project.rawValue:
            return handleProjectURL(pathComponents: pathComponents, queryItems: url.queryItems)

        case DeepLinkPath.quickAsk.rawValue:
            return handleQuickAskURL()

        case DeepLinkPath.settings.rawValue:
            return handleSettingsURL(queryItems: url.queryItems)

        case DeepLinkPath.newSession.rawValue:
            return handleNewSessionURL(queryItems: url.queryItems)

        default:
            print("Unknown deep link path: \(host ?? "nil")")
            return false
        }
    }

    /// Create a deep link URL for a session
    public func sessionURL(_ sessionId: UUID) -> URL {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = DeepLinkPath.session.rawValue
        components.path = "/\(sessionId.uuidString)"
        return components.url!
    }

    /// Create a deep link URL for a project
    public func projectURL(_ projectId: UUID) -> URL {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = DeepLinkPath.project.rawValue
        components.path = "/\(projectId.uuidString)"
        return components.url!
    }

    /// Create a deep link URL for Quick Ask
    public func quickAskURL() -> URL {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = DeepLinkPath.quickAsk.rawValue
        return components.url!
    }

    /// Create a deep link URL for new session
    public func newSessionURL(projectId: UUID? = nil) -> URL {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = DeepLinkPath.newSession.rawValue

        if let projectId = projectId {
            components.queryItems = [URLQueryItem(name: "project", value: projectId.uuidString)]
        }

        return components.url!
    }

    // MARK: - Private Handlers

    private func handleSessionURL(pathComponents: [String], queryItems: [URLQueryItem]?) -> Bool {
        guard let sessionIdString = pathComponents.first,
              let sessionId = UUID(uuidString: sessionIdString) else {
            print("Invalid session ID in deep link")
            return false
        }

        onOpenSession?(sessionId)
        return true
    }

    private func handleProjectURL(pathComponents: [String], queryItems: [URLQueryItem]?) -> Bool {
        guard let projectIdString = pathComponents.first,
              let projectId = UUID(uuidString: projectIdString) else {
            print("Invalid project ID in deep link")
            return false
        }

        onOpenProject?(projectId)
        return true
    }

    private func handleQuickAskURL() -> Bool {
        onShowQuickAsk?()
        return true
    }

    private func handleSettingsURL(queryItems: [URLQueryItem]?) -> Bool {
        onOpenSettings?()
        return true
    }

    private func handleNewSessionURL(queryItems: [URLQueryItem]?) -> Bool {
        // Check for project parameter
        if let projectItem = queryItems?.first(where: { $0.name == "project" }),
           let projectIdString = projectItem.value,
           let projectId = UUID(uuidString: projectIdString) {
            onOpenProject?(projectId)
        }

        onNewSession?()
        return true
    }
}

// MARK: - URL Extension

extension URL {
    /// Query items from URL
    var queryItems: [URLQueryItem]? {
        URLComponents(url: self, resolvingAgainstBaseURL: true)?.queryItems
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when a deep link opens a session
    public static let deepLinkOpenSession = Notification.Name("DeepLinkOpenSession")

    /// Posted when a deep link opens a project
    public static let deepLinkOpenProject = Notification.Name("DeepLinkOpenProject")

    /// Posted when a deep link requests Quick Ask
    public static let deepLinkShowQuickAsk = Notification.Name("DeepLinkShowQuickAsk")

    /// Posted when a deep link requests settings
    public static let deepLinkOpenSettings = Notification.Name("DeepLinkOpenSettings")

    /// Posted when a deep link requests a new session
    public static let deepLinkNewSession = Notification.Name("DeepLinkNewSession")
}

// MARK: - NSUserActivity Handler

extension DeepLinkHandler {

    /// Handle NSUserActivity from Spotlight or Handoff
    public func handleUserActivity(_ userActivity: NSUserActivity) -> Bool {
        // Handle Spotlight search result
        if userActivity.activityType == CSSearchableItemActionType {
            if let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
                return handleSpotlightIdentifier(identifier)
            }
        }

        // Handle continuation activity
        if userActivity.activityType == "\(Bundle.main.bundleIdentifier ?? "com.claude.desktop").session" {
            if let sessionIdString = userActivity.userInfo?["sessionId"] as? String,
               let sessionId = UUID(uuidString: sessionIdString) {
                onOpenSession?(sessionId)
                return true
            }
        }

        return false
    }

    private func handleSpotlightIdentifier(_ identifier: String) -> Bool {
        // Parse the identifier to determine content type
        if identifier.hasPrefix("claude://session/") {
            let uuidString = identifier.replacingOccurrences(of: "claude://session/", with: "")
            if let sessionId = UUID(uuidString: uuidString) {
                onOpenSession?(sessionId)
                return true
            }
        } else if identifier.hasPrefix("claude://project/") {
            let uuidString = identifier.replacingOccurrences(of: "claude://project/", with: "")
            if let projectId = UUID(uuidString: uuidString) {
                onOpenProject?(projectId)
                return true
            }
        } else {
            // Try to parse as UUID
            if let uuid = UUID(uuidString: identifier) {
                // Assume it's a session
                onOpenSession?(uuid)
                return true
            }
        }

        return false
    }

    /// Create NSUserActivity for Handoff
    public func createUserActivity(for session: Session) -> NSUserActivity {
        let activity = NSUserActivity(activityType: "\(Bundle.main.bundleIdentifier ?? "com.claude.desktop").session")

        activity.title = "Chat: \(session.title)"
        activity.userInfo = ["sessionId": session.id.uuidString]

        // Add to Spotlight
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: UTType.item.identifier)
        attributeSet.title = session.title
        attributeSet.contentDescription = "Claude Desktop conversation"

        activity.contentAttributeSet = attributeSet
        activity.isEligibleForSearch = true
        activity.isEligibleForHandoff = true

        return activity
    }
}
