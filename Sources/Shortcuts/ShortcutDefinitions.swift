// ShortcutDefinitions.swift
// Claude Desktop Mac - Shortcut Definitions
//
// Defines all keyboard shortcuts for the application

import SwiftUI
import KeyboardShortcuts

// MARK: - Shortcut Action

/// Represents a keyboard shortcut action
public enum ShortcutAction: String, Codable, CaseIterable, Identifiable, Sendable {
    // Session Management
    case newSession = "newSession"
    case closeSession = "closeSession"
    case nextSession = "nextSession"
    case previousSession = "previousSession"
    case renameSession = "renameSession"

    // Navigation
    case toggleSidebar = "toggleSidebar"
    case focusInput = "focusInput"
    case scrollToTop = "scrollToTop"
    case scrollToBottom = "scrollToBottom"

    // Project
    case quickProjectSwitch = "quickProjectSwitch"
    case openClaudeMd = "openClaudeMd"

    // Search
    case searchHistory = "searchHistory"
    case searchInConversation = "searchInConversation"

    // Message
    case sendMessage = "sendMessage"
    case insertCodeBlock = "insertCodeBlock"
    case attachImage = "attachImage"
    case attachFile = "attachFile"
    case editLastMessage = "editLastMessage"
    case regenerate = "regenerate"

    // View
    case toggleToolCalls = "toggleToolCalls"
    case expandAllToolCalls = "expandAllToolCalls"
    case collapseAllToolCalls = "collapseAllToolCalls"

    // General
    case settings = "settings"
    case keyboardShortcuts = "keyboardShortcuts"
    case zoomIn = "zoomIn"
    case zoomOut = "zoomOut"
    case resetZoom = "resetZoom"

    public var id: String { rawValue }

    /// Display name for the shortcut
    public var displayName: String {
        switch self {
        // Session
        case .newSession: return "New Session"
        case .closeSession: return "Close Session"
        case .nextSession: return "Next Session"
        case .previousSession: return "Previous Session"
        case .renameSession: return "Rename Session"

        // Navigation
        case .toggleSidebar: return "Toggle Sidebar"
        case .focusInput: return "Focus Input"
        case .scrollToTop: return "Scroll to Top"
        case .scrollToBottom: return "Scroll to Bottom"

        // Project
        case .quickProjectSwitch: return "Quick Project Switch"
        case .openClaudeMd: return "Open CLAUDE.md"

        // Search
        case .searchHistory: return "Search History"
        case .searchInConversation: return "Search in Conversation"

        // Message
        case .sendMessage: return "Send Message"
        case .insertCodeBlock: return "Insert Code Block"
        case .attachImage: return "Attach Image"
        case .attachFile: return "Attach File"
        case .editLastMessage: return "Edit Last Message"
        case .regenerate: return "Regenerate Response"

        // View
        case .toggleToolCalls: return "Toggle Tool Calls"
        case .expandAllToolCalls: return "Expand All Tool Calls"
        case .collapseAllToolCalls: return "Collapse All Tool Calls"

        // General
        case .settings: return "Settings"
        case .keyboardShortcuts: return "Keyboard Shortcuts"
        case .zoomIn: return "Zoom In"
        case .zoomOut: return "Zoom Out"
        case .resetZoom: return "Reset Zoom"
        }

        /// Category for the shortcut
        public var category: ShortcutCategory {
            switch self {
            case .newSession, .closeSession, .nextSession, .previousSession, .renameSession:
                return .session
            case .toggleSidebar, .focusInput, .scrollToTop, .scrollToBottom:
                return .navigation
            case .quickProjectSwitch, .openClaudeMd:
                return .project
            case .searchHistory, .searchInConversation:
                return .search
            case .sendMessage, .insertCodeBlock, .attachImage, .attachFile, .editLastMessage, .regenerate:
                return .message
            case .toggleToolCalls, .expandAllToolCalls, .collapseAllToolCalls:
                return .view
            case .settings, .keyboardShortcuts, .zoomIn, .zoomOut, .resetZoom:
                return .general
            }
        }

        /// Description of what the shortcut does
        public var description: String {
            switch self {
            case .newSession: return "Create a new chat session"
            case .closeSession: return "Close the current session"
            case .nextSession: return "Switch to the next session"
            case .previousSession: return "Switch to the previous session"
            case .renameSession: return "Rename the current session"
            case .toggleSidebar: return "Show or hide the sidebar"
            case .focusInput: return "Focus the message input field"
            case .scrollToTop: return "Scroll to the beginning of the conversation"
            case .scrollToBottom: return "Scroll to the end of the conversation"
            case .quickProjectSwitch: return "Open the project switcher"
            case .openClaudeMd: return "Open the CLAUDE.md editor"
            case .searchHistory: return "Search through conversation history"
            case .searchInConversation: return "Search within the current conversation"
            case .sendMessage: return "Send the current message"
            case .insertCodeBlock: return "Insert a code block template"
            case .attachImage: return "Open the image picker"
            case .attachFile: return "Open the file picker"
            case .editLastMessage: return "Edit your last message"
            case .regenerate: return "Regenerate the last response"
            case .toggleToolCalls: return "Toggle tool call visibility"
            case .expandAllToolCalls: return "Expand all tool call details"
            case .collapseAllToolCalls: return "Collapse all tool call details"
            case .settings: return "Open the settings window"
            case .keyboardShortcuts: return "Show keyboard shortcuts"
            case .zoomIn: return "Increase text size"
            case .zoomOut: return "Decrease text size"
            case .resetZoom: return "Reset to default text size"
            }
        }
    }

// MARK: - Shortcut Category

/// Categories for organizing shortcuts
public enum ShortcutCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case session = "Session"
    case navigation = "Navigation"
    case project = "Project"
    case search = "Search"
    case message = "Message"
    case view = "View"
    case general = "General"

    public var id: String { rawValue }

    /// Display name
    public var displayName: String { rawValue }

    /// Icon for the category
    public var icon: String {
        switch self {
        case .session: return "bubble.left.and.bubble.right"
        case .navigation: return "arrow.up.arrow.down"
        case .project: return "folder"
        case .search: return "magnifyingglass"
        case .message: return "message"
        case .view: return "eye"
        case .general: return "gearshape"
        }
    }

    /// Shortcuts in this category
    public var shortcuts: [ShortcutAction] {
        ShortcutAction.allCases.filter { $0.category == self }
    }
}

// MARK: - Shortcut Definition

/// A keyboard shortcut definition
public struct ShortcutDefinition: Codable, Identifiable, Sendable {
    public let id: String
    public let action: ShortcutAction
    public var key: String
    public var modifiers: [ModifierKey]
    public let isEditable: Bool

    public init(action: ShortcutAction, key: String, modifiers: [ModifierKey], isEditable: Bool = true) {
        self.id = action.rawValue
        self.action = action
        self.key = key
        self.modifiers = modifiers
        self.isEditable = isEditable
    }

    /// Display string for the shortcut
    public var displayString: String {
        let modifierSymbols = modifiers.map { $0.symbol }.joined()
        return "\(modifierSymbols)\(key.uppercased())"
    }
}

// MARK: - Modifier Key

/// Keyboard modifier keys
public enum ModifierKey: String, Codable, CaseIterable, Sendable {
    case command = "cmd"
    case option = "opt"
    case control = "ctrl"
    case shift = "shift"

    public var symbol: String {
        switch self {
        case .command: return "\u{2318}"  // Command symbol
        case .option: return "\u{2325}"   // Option symbol
        case .control: return "\u{2303}"  // Control symbol
        case .shift: return "\u{21E7}"    // Shift symbol
        }
    }

    public var displayName: String {
        switch self {
        case .command: return "Command"
        case .option: return "Option"
        case .control: return "Control"
        case .shift: return "Shift"
        }
    }

    public var NSEventModifierFlags: NSEvent.ModifierFlags {
        switch self {
        case .command: return .command
        case .option: return .option
        case .control: return .control
        case .shift: return .shift
        }
    }
}

// MARK: - Default Shortcuts

extension ShortcutDefinition {
    /// Default keyboard shortcuts
    public static let defaults: [ShortcutDefinition] = [
        // Session
        ShortcutDefinition(action: .newSession, key: "n", modifiers: [.command]),
        ShortcutDefinition(action: .closeSession, key: "w", modifiers: [.command]),
        ShortcutDefinition(action: .nextSession, key: "]", modifiers: [.command, .shift]),
        ShortcutDefinition(action: .previousSession, key: "[", modifiers: [.command, .shift]),
        ShortcutDefinition(action: .renameSession, key: "r", modifiers: [.command, .shift]),

        // Navigation
        ShortcutDefinition(action: .toggleSidebar, key: "/", modifiers: [.command]),
        ShortcutDefinition(action: .focusInput, key: "l", modifiers: [.command]),
        ShortcutDefinition(action: .scrollToTop, key: "up", modifiers: [.command]),
        ShortcutDefinition(action: .scrollToBottom, key: "down", modifiers: [.command]),

        // Project
        ShortcutDefinition(action: .quickProjectSwitch, key: "p", modifiers: [.command]),
        ShortcutDefinition(action: .openClaudeMd, key: "m", modifiers: [.command, .shift]),

        // Search
        ShortcutDefinition(action: .searchHistory, key: "f", modifiers: [.command]),
        ShortcutDefinition(action: .searchInConversation, key: "f", modifiers: [.command, .shift]),

        // Message
        ShortcutDefinition(action: .sendMessage, key: "return", modifiers: [.command]),
        ShortcutDefinition(action: .insertCodeBlock, key: "c", modifiers: [.command, .shift]),
        ShortcutDefinition(action: .attachImage, key: "i", modifiers: [.command, .shift]),
        ShortcutDefinition(action: .attachFile, key: "a", modifiers: [.command, .shift]),
        ShortcutDefinition(action: .editLastMessage, key: "up", modifiers: []),
        ShortcutDefinition(action: .regenerate, key: "r", modifiers: [.command]),

        // View
        ShortcutDefinition(action: .toggleToolCalls, key: "t", modifiers: [.command]),
        ShortcutDefinition(action: .expandAllToolCalls, key: "e", modifiers: [.command, .shift]),
        ShortcutDefinition(action: .collapseAllToolCalls, key: "c", modifiers: [.command, .option]),

        // General
        ShortcutDefinition(action: .settings, key: ",", modifiers: [.command]),
        ShortcutDefinition(action: .keyboardShortcuts, key: "?", modifiers: [.command]),
        ShortcutDefinition(action: .zoomIn, key: "=", modifiers: [.command]),
        ShortcutDefinition(action: .zoomOut, key: "-", modifiers: [.command]),
        ShortcutDefinition(action: .resetZoom, key: "0", modifiers: [.command]),
    ]

    /// Get definition for an action
    public static func definition(for action: ShortcutAction) -> ShortcutDefinition {
        defaults.first { $0.action == action } ?? ShortcutDefinition(action: action, key: "", modifiers: [])
    }
}
