// CommandPalette.swift
// Claude Desktop Mac - Command Palette
//
// Quick command palette for executing commands

import SwiftUI
import AppKit
import Theme
import Models
import Project

// MARK: - Command Palette Item

/// Represents an item in the command palette
public struct CommandPaletteItem: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let icon: String
    public let shortcut: String?
    public let category: CommandCategory
    public let action: CommandAction

    public init(
        id: String,
        name: String,
        description: String,
        icon: String,
        shortcut: String? = nil,
        category: CommandCategory,
        action: CommandAction
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.shortcut = shortcut
        self.category = category
        self.action = action
    }
}

// MARK: - Command Category

/// Categories for command palette items
public enum CommandCategory: String, CaseIterable, Identifiable, Sendable {
    case session = "Session"
    case project = "Project"
    case search = "Search"
    case view = "View"
    case general = "General"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .session: return "bubble.left.and.bubble.right"
        case .project: return "folder"
        case .search: return "magnifyingglass"
        case .view: return "eye"
        case .general: return "gearshape"
        }
    }

    public var displayName: String { rawValue }
}

// MARK: - Command Action

/// Actions that can be executed from command palette
public enum CommandAction: Sendable {
    case newSession
    case closeSession
    case openSession(UUID)
    case switchProject(UUID)
    case searchHistory
    case searchConversation
    case openSettings
    case toggleSidebar
    case focusInput
    case clearConversation
    case toggleTheme
}

// MARK: - Command Palette View Model

/// View model for command palette
@MainActor
@Observable
public final class CommandPaletteViewModel {

    // MARK: - Properties

    public var searchText: String = ""
    public var selectedItemId: String?
    public var recentCommands: [CommandPaletteItem] = []
    public var sessions: [SessionSummary] = []
    public var projects: [Project] = []

    // MARK: - Callbacks

    public var onExecute: ((CommandAction) -> Void)?
    public var onClose: (() -> Void)?

    // MARK: - Computed Properties

    /// All available commands
    public var allCommands: [CommandPaletteItem] {
        CommandPaletteDefaults.allCommands
    }

    /// Filtered commands based on search
    public var filteredCommands: [CommandPaletteItem] {
        if searchText.isEmpty {
            return allCommands
        }
        return allCommands.filter { item in
            item.name.localizedCaseInsensitiveContains(searchText) ||
            item.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Filtered sessions based on search
    public var filteredSessions: [SessionSummary] {
        if searchText.isEmpty {
            return Array(sessions.prefix(5))
        }
        return sessions.filter { session in
            session.title.localizedCaseInsensitiveContains(searchText) ||
            (session.projectName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    /// Filtered projects based on search
    public var filteredProjects: [Project] {
        if searchText.isEmpty {
            return projects
        }
        return projects.filter { project in
            project.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Grouped items for display
    public var groupedItems: [(String, [Any])] {
        var groups: [(String, [Any])] = []

        if !filteredCommands.isEmpty {
            groups.append(("Commands", filteredCommands.map { $0 }))
        }

        if !filteredSessions.isEmpty {
            groups.append(("Recent Sessions", filteredSessions.map { $0 }))
        }

        if !filteredProjects.isEmpty {
            groups.append(("Projects", filteredProjects.map { $0 }))
        }

        return groups
    }

    // MARK: - Methods

    /// Execute selected command
    public func executeSelected() {
        guard let id = selectedItemId else {
            // Execute first command if nothing selected
            if let first = filteredCommands.first {
                executeCommand(first)
            }
            return
        }

        if let command = filteredCommands.first(where: { $0.id == id }) {
            executeCommand(command)
        } else if let session = filteredSessions.first(where: { $0.id.uuidString == id }) {
            executeAction(.openSession(session.id))
        } else if let project = filteredProjects.first(where: { $0.id.uuidString == id }) {
            executeAction(.switchProject(project.id))
        }
    }

    /// Execute a command
    public func executeCommand(_ command: CommandPaletteItem) {
        addToRecent(command)
        executeAction(command.action)
    }

    /// Execute action
    public func executeAction(_ action: CommandAction) {
        onExecute?(action)
        onClose?()
    }

    /// Select next item
    public func selectNext() {
        let allIds = getAllIds()
        guard !allIds.isEmpty else { return }

        if let currentId = selectedItemId,
           let currentIndex = allIds.firstIndex(of: currentId) {
            selectedItemId = allIds[(currentIndex + 1) % allIds.count]
        } else {
            selectedItemId = allIds.first
        }
    }

    /// Select previous item
    public func selectPrevious() {
        let allIds = getAllIds()
        guard !allIds.isEmpty else { return }

        if let currentId = selectedItemId,
           let currentIndex = allIds.firstIndex(of: currentId) {
            let newIndex = currentIndex == 0 ? allIds.count - 1 : currentIndex - 1
            selectedItemId = allIds[newIndex]
        } else {
            selectedItemId = allIds.last
        }
    }

    /// Close palette
    public func close() {
        onClose?()
    }

    // MARK: - Private Methods

    private func getAllIds() -> [String] {
        var ids: [String] = []
        ids.append(contentsOf: filteredCommands.map { $0.id })
        ids.append(contentsOf: filteredSessions.map { $0.id.uuidString })
        ids.append(contentsOf: filteredProjects.map { $0.id.uuidString })
        return ids
    }

    private func addToRecent(_ command: CommandPaletteItem) {
        recentCommands.removeAll { $0.id == command.id }
        recentCommands.insert(command, at: 0)
        recentCommands = Array(recentCommands.prefix(5))
    }
}

// MARK: - Command Palette Defaults

public enum CommandPaletteDefaults {
    /// All default commands
    public static let allCommands: [CommandPaletteItem] = [
        // Session
        CommandPaletteItem(
            id: "new_session",
            name: "New Session",
            description: "Create a new chat session",
            icon: "plus.circle",
            shortcut: "\u{2318}N",
            category: .session,
            action: .newSession
        ),
        CommandPaletteItem(
            id: "close_session",
            name: "Close Session",
            description: "Close the current session",
            icon: "xmark.circle",
            shortcut: "\u{2318}W",
            category: .session,
            action: .closeSession
        ),
        CommandPaletteItem(
            id: "clear_conversation",
            name: "Clear Conversation",
            description: "Clear all messages in current session",
            icon: "trash",
            shortcut: "\u{21E7}\u{2318}K",
            category: .session,
            action: .clearConversation
        ),

        // Project
        CommandPaletteItem(
            id: "search_history",
            name: "Search History",
            description: "Search through conversation history",
            icon: "clock.arrow.circlepath",
            shortcut: "\u{2318}F",
            category: .search,
            action: .searchHistory
        ),
        CommandPaletteItem(
            id: "search_conversation",
            name: "Search in Conversation",
            description: "Search within the current conversation",
            icon: "doc.text.magnifyingglass",
            shortcut: "\u{21E7}\u{2318}F",
            category: .search,
            action: .searchConversation
        ),

        // View
        CommandPaletteItem(
            id: "toggle_sidebar",
            name: "Toggle Sidebar",
            description: "Show or hide the sidebar",
            icon: "sidebar.left",
            shortcut: "\u{2318}/",
            category: .view,
            action: .toggleSidebar
        ),
        CommandPaletteItem(
            id: "focus_input",
            name: "Focus Input",
            description: "Focus the message input field",
            icon: "keyboard",
            shortcut: "\u{2318}L",
            category: .view,
            action: .focusInput
        ),
        CommandPaletteItem(
            id: "toggle_theme",
            name: "Toggle Theme",
            description: "Switch between light and dark theme",
            icon: "circle.lefthalf.filled",
            shortcut: "\u{21E7}\u{2318}T",
            category: .view,
            action: .toggleTheme
        ),

        // General
        CommandPaletteItem(
            id: "open_settings",
            name: "Open Settings",
            description: "Open the settings window",
            icon: "gearshape",
            shortcut: "\u{2318},",
            category: .general,
            action: .openSettings
        )
    ]
}

// MARK: - Command Palette View

/// SwiftUI view for command palette
public struct CommandPaletteView: View {
    @Bindable var viewModel: CommandPaletteViewModel
    @FocusState private var isSearchFocused: Bool

    @Environment(\.colorScheme) private var colorScheme

    public init(viewModel: CommandPaletteViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search field
            searchField

            Divider()

            // Results
            resultsView
        }
        .frame(width: 500)
        .frame(maxHeight: 400)
        .background(Color.bgPrimary(scheme: colorScheme))
        .cornerRadius(CornerRadius.lg.rawValue)
        .shadow(AppShadow.lg)
        .onAppear {
            isSearchFocused = true
        }
    }

    // MARK: - Subviews

    private var searchField: some View {
        HStack(spacing: Spacing.md.rawValue) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))

            TextField("Quick Command...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .focused($isSearchFocused)
                .onSubmit {
                    viewModel.executeSelected()
                }

            // Keyboard hints
            Text("\u{21E7}\u{2318}P")
                .font(.system(size: 11))
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))
        }
        .padding(Spacing.md.rawValue)
        .background(Color.bgSecondary(scheme: colorScheme))
    }

    private var resultsView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Recent commands (when no search)
                if viewModel.searchText.isEmpty && !viewModel.recentCommands.isEmpty {
                    sectionHeader("Recent Commands")
                    ForEach(viewModel.recentCommands) { command in
                        commandRow(command)
                    }
                }

                // Commands
                if !viewModel.filteredCommands.isEmpty {
                    if !viewModel.searchText.isEmpty || viewModel.recentCommands.isEmpty {
                        sectionHeader("Commands")
                    }
                    ForEach(viewModel.filteredCommands) { command in
                        commandRow(command)
                    }
                }

                // Sessions
                if !viewModel.filteredSessions.isEmpty {
                    sectionHeader("Recent Sessions")
                    ForEach(viewModel.filteredSessions) { session in
                        sessionRow(session)
                    }
                }

                // Projects
                if !viewModel.filteredProjects.isEmpty && !viewModel.searchText.isEmpty {
                    sectionHeader("Projects")
                    ForEach(viewModel.filteredProjects) { project in
                        projectRow(project)
                    }
                }
            }
            .padding(.vertical, Spacing.sm.rawValue)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            .padding(.horizontal, Spacing.md.rawValue)
            .padding(.vertical, Spacing.sm.rawValue)
    }

    private func commandRow(_ command: CommandPaletteItem) -> some View {
        HStack(spacing: Spacing.md.rawValue) {
            Image(systemName: command.icon)
                .font(.system(size: 16))
                .foregroundColor(.accentPrimary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(command.name)
                    .font(.system(size: 14))
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                Text(command.description)
                    .font(.system(size: 12))
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            }

            Spacer()

            if let shortcut = command.shortcut {
                Text(shortcut)
                    .font(.system(size: 11))
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                    .padding(.horizontal, Spacing.xs.rawValue)
                    .padding(.vertical, 2)
                    .background(Color.bgTertiary(scheme: colorScheme))
                    .cornerRadius(CornerRadius.sm.rawValue)
            }
        }
        .padding(.horizontal, Spacing.md.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
        .background(
            viewModel.selectedItemId == command.id
                ? Color.bgSelected(scheme: colorScheme)
                : Color.clear
        )
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.executeCommand(command)
        }
        .onHover { isHovered in
            if isHovered {
                viewModel.selectedItemId = command.id
            }
        }
    }

    private func sessionRow(_ session: SessionSummary) -> some View {
        HStack(spacing: Spacing.md.rawValue) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 16))
                .foregroundColor(.accentPurple)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.title)
                    .font(.system(size: 14))
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                    .lineLimit(1)

                HStack(spacing: Spacing.xs.rawValue) {
                    if let projectName = session.projectName {
                        Text(projectName)
                            .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                    }
                    if let time = session.lastMessageTime {
                        Text("-")
                        Text(time, style: .relative)
                            .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                    }
                }
                .font(.system(size: 12))
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.md.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
        .background(
            viewModel.selectedItemId == session.id.uuidString
                ? Color.bgSelected(scheme: colorScheme)
                : Color.clear
        )
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.executeAction(.openSession(session.id))
        }
        .onHover { isHovered in
            if isHovered {
                viewModel.selectedItemId = session.id.uuidString
            }
        }
    }

    private func projectRow(_ project: Project) -> some View {
        HStack(spacing: Spacing.md.rawValue) {
            Image(systemName: project.isFavorite ? "star.fill" : "folder.fill")
                .font(.system(size: 16))
                .foregroundColor(project.isFavorite ? .yellow : .accentPrimary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.system(size: 14))
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                Text(project.path.path)
                    .font(.system(size: 12))
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.md.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
        .background(
            viewModel.selectedItemId == project.id.uuidString
                ? Color.bgSelected(scheme: colorScheme)
                : Color.clear
        )
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.executeAction(.switchProject(project.id))
        }
        .onHover { isHovered in
            if isHovered {
                viewModel.selectedItemId = project.id.uuidString
            }
        }
    }
}

// MARK: - Command Palette Panel

/// Panel for command palette
public final class CommandPalettePanel: NSPanel {

    // MARK: - Singleton

    public static let shared = CommandPalettePanel()

    // MARK: - Properties

    private var hostingView: NSHostingView<CommandPaletteView>?
    private let viewModel = CommandPaletteViewModel()

    // MARK: - Initialization

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )

        setupPanel()
    }

    private func setupPanel() {
        title = "Command Palette"
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isFloatingPanel = true
        hidesOnDeactivate = true
        becomesKeyOnlyIfNeeded = false
        isMovableByWindowBackground = true

        let view = CommandPaletteView(viewModel: viewModel)
        hostingView = NSHostingView(rootView: view)
        contentView = hostingView

        viewModel.onClose = { [weak self] in
            self?.close()
        }
    }

    // MARK: - Public Methods

    /// Show the panel centered on screen
    public func showCentered() {
        center()
        makeKeyAndOrderFront(nil)
    }

    /// Toggle visibility
    public func toggle() {
        if isVisible {
            close()
        } else {
            showCentered()
        }
    }

    // MARK: - Override

    public override var canBecomeKey: Bool { true }
    public override var canBecomeMain: Bool { true }

    public override func keyDown(with event: NSEvent) {
        // Handle escape key
        if event.keyCode == 53 { // Escape
            close()
            return
        }

        // Handle arrow keys
        if event.keyCode == 125 { // Down
            viewModel.selectNext()
            return
        }
        if event.keyCode == 126 { // Up
            viewModel.selectPrevious()
            return
        }

        super.keyDown(with: event)
    }
}
