// AppDelegate.swift
// Claude Desktop Mac - App Delegate
//
// Main application delegate for the app

import SwiftUI
import AppKit

// MARK: - App Delegate

/// Main application delegate
@main
public class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    private var menuBarController: MenuBarController?
    private var globalShortcutManager: GlobalShortcutManager?
    private var notificationManager: NotificationManager?

    // MARK: - Lifecycle

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize all Phase 4 integrations
        initializeMenuBar()
        initializeGlobalShortcuts()
        initializeNotifications()
        initializeSpotlight()

        // Setup deep link handlers
        setupDeepLinkHandlers()

        // Observe app state
        observeAppState()
    }

    public func applicationWillTerminate(_ notification: Notification) {
        // Cleanup
        GlobalShortcutManager.shared.unregisterAllShortcuts()
        NotificationManager.shared.clearAllNotifications()
    }

    public func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    // MARK: - URL Handling

    public func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            DeepLinkHandler.shared.handleURL(url)
        }
    }

    public func application(_ application: NSApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([NSUserActivityRestoring]) -> Void) -> Bool {
        // Handle Spotlight search result
        if userActivity.activityType == CSSearchableItemActionType {
            return DeepLinkHandler.shared.handleUserActivity(userActivity)
        }

        // Handle Handoff
        return DeepLinkHandler.shared.handleUserActivity(userActivity)
    }
}

// MARK: - Initialization

extension AppDelegate {

    /// Initialize MenuBar integration
    private func initializeMenuBar() {
        menuBarController = MenuBarController.shared
        menuBarController?.setupMenuBar()

        // Set MenuBar callbacks
        menuBarController?.onNewSession = { [weak self] in
            self?.createNewSession()
        }

        menuBarController?.onShowQuickAsk = { [weak self] in
            self?.showQuickAsk()
        }

        menuBarController?.onOpenSession = { [weak self] sessionId in
            self?.openSession(sessionId)
        }

        menuBarController?.onSwitchProject = { [weak self] project in
            self?.switchProject(project)
        }

        menuBarController?.onOpenMainWindow = { [weak self] in
            self?.activateMainWindow()
        }

        menuBarController?.onOpenSettings = { [weak self] in
            self?.openSettings()
        }

        menuBarController?.onQuit = {
            NSApp.terminate(nil)
        }
    }

    /// Initialize global shortcuts
    private func initializeGlobalShortcuts() {
        globalShortcutManager = GlobalShortcutManager.shared
        globalShortcutManager?.registerAllShortcuts()

        // Set shortcut action handler
        globalShortcutManager?.onAction = { [weak self] action in
            self?.handleGlobalShortcut(action)
        }
    }

    /// Initialize notifications
    private func initializeNotifications() {
        notificationManager = NotificationManager.shared
        notificationManager?.requestAuthorization()
        notificationManager?.setupCategories()

        // Set notification handlers
        notificationManager?.onViewSession = { [weak self] sessionId in
            self?.openSession(sessionId)
        }

        notificationManager?.onReply = { [weak self] sessionId, text in
            self?.handleQuickReply(sessionId: sessionId, text: text)
        }

        notificationManager?.onCopyCode = { code in
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(code, forType: .string)
        }

        notificationManager?.onApplyCode = { [weak self] sessionId, fileName in
            self?.applyCode(sessionId: sessionId, fileName: fileName)
        }
    }

    /// Initialize Spotlight integration
    private func initializeSpotlight() {
        Spotlight.initialize()

        // Set Spotlight handlers
        Spotlight.setHandlers(
            onOpenSession: { [weak self] sessionId in
                self?.openSession(sessionId)
            },
            onOpenProject: { [weak self] projectId in
                self?.openProject(projectId)
            },
            onShowQuickAsk: { [weak self] in
                self?.showQuickAsk()
            },
            onOpenSettings: { [weak self] in
                self?.openSettings()
            },
            onNewSession: { [weak self] in
                self?.createNewSession()
            }
        )
    }

    /// Setup deep link handlers
    private func setupDeepLinkHandlers() {
        DeepLinkHandler.shared.onOpenSession = { [weak self] sessionId in
            self?.openSession(sessionId)
        }

        DeepLinkHandler.shared.onOpenProject = { [weak self] projectId in
            self?.openProject(projectId)
        }

        DeepLinkHandler.shared.onShowQuickAsk = { [weak self] in
            self?.showQuickAsk()
        }

        DeepLinkHandler.shared.onOpenSettings = { [weak self] in
            self?.openSettings()
        }

        DeepLinkHandler.shared.onNewSession = { [weak self] in
            self?.createNewSession()
        }
    }
}

// MARK: - Actions

extension AppDelegate {

    /// Handle global shortcut action
    private func handleGlobalShortcut(_ action: GlobalShortcutAction) {
        switch action {
        case .activateApp:
            activateMainWindow()

        case .showQuickAsk:
            showQuickAsk()

        case .showCommandPalette:
            showCommandPalette()

        case .newSession:
            createNewSession()
        }
    }

    /// Create a new session
    private func createNewSession() {
        activateMainWindow()
        NotificationCenter.default.post(name: .createNewSession, object: nil)
    }

    /// Show Quick Ask panel
    private func showQuickAsk() {
        QuickAskWindowController.shared.showWindow()
    }

    /// Show command palette
    private func showCommandPalette() {
        activateMainWindow()
        CommandPalettePanel.shared.showCentered()
    }

    /// Open a specific session
    private func openSession(_ sessionId: UUID) {
        activateMainWindow()
        NotificationCenter.default.post(
            name: .openSession,
            object: nil,
            userInfo: ["sessionId": sessionId]
        )
    }

    /// Open a specific project
    private func openProject(_ projectId: UUID) {
        activateMainWindow()
        NotificationCenter.default.post(
            name: .openProject,
            object: nil,
            userInfo: ["projectId": projectId]
        )
    }

    /// Switch to a project
    private func switchProject(_ project: Project) {
        activateMainWindow()
        ProjectManager.shared.switchToProject(project)
    }

    /// Activate the main window
    private func activateMainWindow() {
        NSApp.activate(ignoringOtherApps: true)

        // Show main window if hidden
        if let window = NSApp.windows.first(where: { $0.isKeyWindow == false && $0.canBecomeKey }) {
            window.makeKeyAndOrderFront(nil)
        }
    }

    /// Open settings
    private func openSettings() {
        activateMainWindow()
        NotificationCenter.default.post(name: .openSettings, object: nil)
    }

    /// Handle quick reply from notification
    private func handleQuickReply(sessionId: UUID, text: String) {
        activateMainWindow()
        QuickReplyHandler.shared.processReply(sessionId: sessionId, text: text)
    }

    /// Apply code from notification
    private func applyCode(sessionId: UUID, fileName: String) {
        activateMainWindow()
        NotificationCenter.default.post(
            name: .applyCodeToFile,
            object: nil,
            userInfo: ["sessionId": sessionId, "fileName": fileName]
        )
    }
}

// MARK: - App State Observation

extension AppDelegate {

    /// Observe app state changes
    private func observeAppState() {
        // Observe connection state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(connectionStateChanged(_:)),
            name: .connectionStateChanged,
            object: nil
        )

        // Observe session updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionsUpdated(_:)),
            name: .sessionsUpdated,
            object: nil
        )

        // Observe message received
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(messageReceived(_:)),
            name: .messageReceived,
            object: nil
        )
    }

    @objc private func connectionStateChanged(_ notification: Notification) {
        if let state = notification.userInfo?["state"] as? ConnectionState {
            updateMenuBarStatus(for: state)
        }
    }

    @objc private func sessionsUpdated(_ notification: Notification) {
        if let sessions = notification.userInfo?["sessions"] as? [Session] {
            let summaries = sessions.map { SessionSummary(from: $0) }
            MenuBarController.shared.updateRecentSessions(summaries)
        }
    }

    @objc private func messageReceived(_ notification: Notification) {
        // Update MenuBar to show new message indicator
        MenuBarController.shared.updateStatus(.hasNewMessage)
    }

    private func updateMenuBarStatus(for state: ConnectionState) {
        let status: MenuBarStatus
        switch state {
        case .connected:
            status = .connected
        case .connecting, .detecting, .reconnecting:
            status = .connecting
        case .disconnected, .idle:
            status = .disconnected
        case .error:
            status = .disconnected
        case .disconnecting:
            status = .disconnected
        }

        MenuBarController.shared.updateStatus(status)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when connection state changes
    public static let connectionStateChanged = Notification.Name("ConnectionStateChanged")

    /// Posted when sessions are updated
    public static let sessionsUpdated = Notification.Name("SessionsUpdated")

    /// Posted when a message is received
    public static let messageReceived = Notification.Name("MessageReceived")

    /// Posted to create a new session
    public static let createNewSession = Notification.Name("CreateNewSession")

    /// Posted to open a session
    public static let openSession = Notification.Name("OpenSession")

    /// Posted to open a project
    public static let openProject = Notification.Name("OpenProject")

    /// Posted to open settings
    public static let openSettings = Notification.Name("OpenSettings")

    /// Posted to apply code to a file
    public static let applyCodeToFile = Notification.Name("ApplyCodeToFile")
}
