// MenuBarController.swift
// Claude Desktop Mac - MenuBar Controller
//
// Manages MenuBar icon, status, and menu

import SwiftUI
import AppKit
import Combine
import Models
import Project

// MARK: - MenuBar Controller

/// Controls the MenuBar status item and menu
@MainActor
public final class MenuBarController: ObservableObject {

    // MARK: - Singleton

    public static let shared = MenuBarController()

    // MARK: - Published Properties

    @Published public var status: MenuBarStatus = .disconnected
    @Published public var recentSessions: [SessionSummary] = []
    @Published public var projects: [Project] = []
    @Published public var currentProject: Project?
    @Published public var model: String = "claude-sonnet-4.6"
    @Published public var version: String = "1.0.0"
    @Published public var unreadCount: Int = 0

    // MARK: - Private Properties

    private var statusItem: NSStatusItem?
    private let animation = MenuBarAnimation()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Callbacks

    public var onNewSession: (() -> Void)?
    public var onShowQuickAsk: (() -> Void)?
    public var onOpenSession: ((UUID) -> Void)?
    public var onSwitchProject: ((Project) -> Void)?
    public var onOpenMainWindow: (() -> Void)?
    public var onOpenSettings: (() -> Void)?
    public var onQuit: (() -> Void)?

    // MARK: - Initialization

    private init() {
        setupBindings()
    }

    // MARK: - Public Methods

    /// Setup the MenuBar status item
    public func setupMenuBar() {
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        // Configure button
        if let button = statusItem?.button {
            button.image = MenuBarIcon.image(for: status)
            button.imageScaling = .scaleProportionallyDown
            button.imagePosition = .imageOnly
            button.toolTip = status.statusText
        }

        // Create menu
        updateMenu()

        // Observe status changes
        $status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newStatus in
                self?.updateStatus(newStatus)
            }
            .store(in: &cancellables)
    }

    /// Update the status
    public func updateStatus(_ newStatus: MenuBarStatus) {
        status = newStatus

        // Update icon
        if let button = statusItem?.button {
            button.image = MenuBarIcon.image(for: newStatus)
            button.toolTip = newStatus.statusText
        }

        // Handle animation for processing state
        if newStatus == .processing {
            animation.startAnimation()
        } else {
            animation.stopAnimation()
        }
    }

    /// Update recent sessions list
    public func updateRecentSessions(_ sessions: [SessionSummary]) {
        recentSessions = Array(sessions.prefix(5))
        updateMenu()
    }

    /// Update projects list
    public func updateProjects(_ projects: [Project], current: Project?) {
        self.projects = projects
        self.currentProject = current
        updateMenu()
    }

    /// Set unread count
    public func setUnreadCount(_ count: Int) {
        unreadCount = count
        updateBadge()
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Animate processing icon
        animation.$currentFrame
            .combineLatest(animation.$isAnimating)
            .sink { [weak self] frame, isAnimating in
                guard isAnimating, let self = self else { return }
                self.updateAnimatedIcon(frame: frame)
            }
            .store(in: &cancellables)
    }

    private func updateAnimatedIcon(frame: Int) {
        let frames = MenuBarIcon.animatedFrames(for: .processing)
        if frame < frames.count {
            statusItem?.button?.image = frames[frame]
        }
    }

    private func updateBadge() {
        if unreadCount > 0 {
            statusItem?.button?.imagePosition = .imageLeading
            statusItem?.button?.title = "\(unreadCount)"
        } else {
            statusItem?.button?.imagePosition = .imageOnly
            statusItem?.button?.title = ""
        }
    }

    private func updateMenu() {
        statusItem?.menu = createMenu()
    }

    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = MenuDelegate.shared

        // Status section
        let statusItem = NSMenuItem(
            title: "\(status.statusText) | Claude Desktop v\(version)",
            action: nil,
            keyEquivalent: ""
        )
        statusItem.isEnabled = false
        menu.addItem(statusItem)

        // Model info
        if status == .connected {
            let modelItem = NSMenuItem(title: "Model: \(model)", action: nil, keyEquivalent: "")
            modelItem.isEnabled = false
            menu.addItem(modelItem)
        }

        menu.addItem(NSMenuItem.separator())

        // Quick actions
        menu.addItem(NSMenuItem(
            title: "New Session",
            action: #selector(newSession),
            keyEquivalent: "n"
        ))

        menu.addItem(NSMenuItem(
            title: "Quick Ask...",
            action: #selector(showQuickAsk),
            keyEquivalent: "a"
        ).withModifierFlags(.shift))

        menu.addItem(NSMenuItem.separator())

        // Recent sessions
        if !recentSessions.isEmpty {
            let recentHeader = NSMenuItem(title: "Recent Sessions", action: nil, keyEquivalent: "")
            recentHeader.isEnabled = false
            menu.addItem(recentHeader)

            for session in recentSessions {
                let item = NSMenuItem(
                    title: session.title,
                    action: #selector(openSession(_:)),
                    keyEquivalent: ""
                )
                item.representedObject = session.id
                item.toolTip = "\(session.projectName ?? "No Project") - \(session.preview ?? "")"
                menu.addItem(item)
            }
        }

        // Projects
        if !projects.isEmpty {
            menu.addItem(NSMenuItem.separator())

            let projectsItem = NSMenuItem(title: "Projects", action: nil, keyEquivalent: "")
            projectsItem.submenu = createProjectsMenu()
            menu.addItem(projectsItem)
        }

        menu.addItem(NSMenuItem.separator())

        // App controls
        menu.addItem(NSMenuItem(
            title: "Open Claude Desktop",
            action: #selector(openMainWindow),
            keyEquivalent: "o"
        ))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))

        menu.addItem(NSMenuItem(
            title: "Quit Claude Desktop",
            action: #selector(quitApp),
            keyEquivalent: "q"
        ))

        return menu
    }

    private func createProjectsMenu() -> NSMenu {
        let menu = NSMenu()

        for project in projects {
            let item = NSMenuItem(
                title: project.name,
                action: #selector(switchProject(_:)),
                keyEquivalent: ""
            )
            item.representedObject = project
            item.state = currentProject?.id == project.id ? .on : .off

            // Add indicator for active project
            if currentProject?.id == project.id {
                item.title = "\(project.name) [Active]"
            }

            menu.addItem(item)
        }

        return menu
    }

    // MARK: - Actions

    @objc private func newSession() {
        onNewSession?()
    }

    @objc private func showQuickAsk() {
        onShowQuickAsk?()
    }

    @objc private func openSession(_ sender: NSMenuItem) {
        guard let sessionId = sender.representedObject as? UUID else { return }
        onOpenSession?(sessionId)
    }

    @objc private func switchProject(_ sender: NSMenuItem) {
        guard let project = sender.representedObject as? Project else { return }
        onSwitchProject?(project)
    }

    @objc private func openMainWindow() {
        onOpenMainWindow?()
    }

    @objc private func openSettings() {
        onOpenSettings?()
    }

    @objc private func quitApp() {
        onQuit?()
    }
}

// MARK: - NSMenuItem Extension

extension NSMenuItem {
    /// Create menu item with modifier flags
    func withModifierFlags(_ flags: NSEvent.ModifierFlags) -> NSMenuItem {
        self.keyEquivalentModifierMask = flags
        return self
    }
}

// MARK: - Menu Delegate

private class MenuDelegate: NSObject, NSMenuDelegate {
    static let shared = MenuDelegate()

    func menuNeedsUpdate(_ menu: NSMenu) {
        // Update menu items before showing
    }
}
