// GlobalShortcut.swift
// Claude Desktop Mac - Global Shortcuts
//
// Handles global keyboard shortcuts when app is active

import SwiftUI
import Combine

// MARK: - Global Shortcut Handler

/// Handles global keyboard shortcuts at the application level
@MainActor
@Observable
public final class GlobalShortcutHandler {

    // MARK: - Singleton

    public static let shared = GlobalShortcutHandler()

    // MARK: - Properties

    /// Whether global shortcuts are enabled
    public var isEnabled: Bool = true

    /// Registered shortcuts
    private var registeredShortcuts: [ShortcutAction: () -> Void] = [:]

    /// Event monitor
    private var eventMonitor: Any?

    /// Shortcut manager reference
    private let shortcutManager = ShortcutManager.shared

    // MARK: - Initialization

    private init() {
        setupDefaultHandlers()
    }

    // MARK: - Public Methods

    /// Register a handler for a shortcut action
    public func register(_ action: ShortcutAction, handler: @escaping () -> Void) {
        registeredShortcuts[action] = handler
    }

    /// Unregister a shortcut handler
    public func unregister(_ action: ShortcutAction) {
        registeredShortcuts.removeValue(forKey: action)
    }

    /// Start monitoring keyboard events
    public func startMonitoring() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.isEnabled else { return event }

            if self.handleKeyEvent(event) {
                return nil  // Event was handled
            }

            return event  // Pass through
        }
    }

    /// Stop monitoring keyboard events
    public func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    // MARK: - Private Methods

    private func setupDefaultHandlers() {
        // Register default handlers that just post notifications
        for action in ShortcutAction.allCases {
            register(action) { [weak self] in
                self?.shortcutManager.trigger(action)
            }
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags

        // Get key character
        guard let characters = event.charactersIgnoringModifiers else { return false }
        guard let character = characters.first else { return false }

        let key = String(character).lowercased()

        // Special key handling
        let specialKey = mapSpecialKey(event.keyCode)

        // Find matching shortcut
        for (action, _) in registeredShortcuts {
            let definition = shortcutManager.shortcut(for: action)

            // Check if key matches
            let keyMatches = definition.key.lowercased() == key ||
                            definition.key.lowercased() == specialKey

            // Check if modifiers match
            let modifierFlags = definition.modifiers.map { $0.NSEventModifierFlags }
            let requiredModifiers = modifierFlags.reduce(NSEvent.ModifierFlags()) { $0.union($1) }

            if keyMatches && modifiers == requiredModifiers {
                if let handler = registeredShortcuts[action] {
                    handler()
                    return true
                }
            }
        }

        return false
    }

    private func mapSpecialKey(_ keyCode: UInt16) -> String {
        switch Int(keyCode) {
        case 36: return "return"      // Return/Enter
        case 48: return "tab"         // Tab
        case 49: return "space"       // Space
        case 51: return "delete"      // Delete
        case 53: return "escape"      // Escape
        case 123: return "left"       // Left arrow
        case 124: return "right"      // Right arrow
        case 125: return "down"       // Down arrow
        case 126: return "up"         // Up arrow
        default: return ""
        }
    }
}

// MARK: - App Extension for Global Shortcuts

extension NSApplicationDelegate {
    /// Set up global shortcuts in application delegate
    public func setupGlobalShortcuts() {
        GlobalShortcutHandler.shared.startMonitoring()
    }

    /// Tear down global shortcuts
    public func teardownGlobalShortcuts() {
        GlobalShortcutHandler.shared.stopMonitoring()
    }
}

// MARK: - Command Table

/// Represents a menu command with keyboard shortcut
public struct MenuCommand: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let action: ShortcutAction
    public let selector: Selector?

    public init(title: String, action: ShortcutAction, selector: Selector? = nil) {
        self.id = action.rawValue
        self.title = title
        self.action = action
        self.selector = selector
    }
}

// MARK: - Command Menu Builder

/// Builds menu commands from shortcuts
public struct CommandMenuBuilder: Sendable {

    public static let shared = CommandMenuBuilder()

    public init() {}

    /// Build File menu commands
    public var fileCommands: [MenuCommand] {
        [
            MenuCommand(title: "New Session", action: .newSession, selector: #selector(NSDocumentController.newDocument(_:))),
            MenuCommand(title: "Close Session", action: .closeSession, selector: #selector(NSWindow.performClose(_:))),
        ]
    }

    /// Build Edit menu commands
    public var editCommands: [MenuCommand] {
        [
            MenuCommand(title: "Search History", action: .searchHistory),
        ]
    }

    /// Build View menu commands
    public var viewCommands: [MenuCommand] {
        [
            MenuCommand(title: "Toggle Sidebar", action: .toggleSidebar),
            MenuCommand(title: "Zoom In", action: .zoomIn),
            MenuCommand(title: "Zoom Out", action: .zoomOut),
            MenuCommand(title: "Reset Zoom", action: .resetZoom),
        ]
    }

    /// Build Window menu commands
    public var windowCommands: [MenuCommand] {
        [
            MenuCommand(title: "Next Session", action: .nextSession),
            MenuCommand(title: "Previous Session", action: .previousSession),
        ]
    }

    /// Build Help menu commands
    public var helpCommands: [MenuCommand] {
        [
            MenuCommand(title: "Keyboard Shortcuts", action: .keyboardShortcuts),
        ]
    }
}

// MARK: - Quick Actions View

/// A floating view for quick actions (Cmd+P style)
public struct QuickActionsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var searchText: String = ""
    @State private var selectedAction: ShortcutAction?

    let onSelect: (ShortcutAction) -> Void

    public init(onSelect: @escaping (ShortcutAction) -> Void) {
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))

                TextField("Search actions...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.bodyText)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color.bgSecondary(scheme: colorScheme))

            Divider()

            // Actions list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredActions) { action in
                        QuickActionRow(
                            action: action,
                            colorScheme: colorScheme,
                            isSelected: selectedAction == action,
                            onSelect: {
                                onSelect(action)
                                dismiss()
                            }
                        )
                        .onTapGesture {
                            selectedAction = action
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .frame(width: 400)
        .background(Color.bgPrimary(scheme: colorScheme))
        .cornerRadius(CornerRadius.lg.rawValue)
        .shadow(AppShadow.lg)
    }

    private var filteredActions: [ShortcutAction] {
        if searchText.isEmpty {
            return ShortcutAction.allCases
        }

        return ShortcutAction.allCases.filter { action in
            action.displayName.localizedCaseInsensitiveContains(searchText) ||
            action.description.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Quick Action Row

private struct QuickActionRow: View {
    let action: ShortcutAction
    let colorScheme: ColorScheme
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(action.displayName)
                    .font(.callout)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                Text(action.description)
                    .font(.caption)
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            }

            Spacer()

            // Shortcut keys
            HStack(spacing: 4) {
                ForEach(shortcutKeys, id: \.self) { key in
                    Text(key)
                        .font(.caption)
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.bgTertiary(scheme: colorScheme))
                        .cornerRadius(CornerRadius.sm.rawValue)
                }
            }
        }
        .padding(.horizontal, Spacing.md.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
        .background(isSelected || isHovered ? Color.bgHover(scheme: colorScheme) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovered = $0 }
    }

    private var shortcutKeys: [String] {
        let definition = ShortcutManager.shared.shortcut(for: action)
        var keys: [String] = definition.modifiers.map { $0.symbol }
        keys.append(definition.key.uppercased())
        return keys
    }
}

// MARK: - Commands Extension

extension Commands {
    /// Create commands from shortcuts
    public static func shortcutCommands() -> some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Session") {
                ShortcutManager.shared.trigger(.newSession)
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("Close Session") {
                ShortcutManager.shared.trigger(.closeSession)
            }
            .keyboardShortcut("w", modifiers: .command)
        }

        CommandGroup(after: .toolbar) {
            Button("Toggle Sidebar") {
                ShortcutManager.shared.trigger(.toggleSidebar)
            }
            .keyboardShortcut("/", modifiers: .command)
        }
    }
}
