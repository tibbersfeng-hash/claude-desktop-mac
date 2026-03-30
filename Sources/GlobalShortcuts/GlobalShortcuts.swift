// GlobalShortcuts.swift
// Claude Desktop Mac - Global Shortcuts Module
//
// Public exports for GlobalShortcuts module

import Foundation

// GlobalShortcuts Module
@MainActor
public enum GlobalShortcuts {
    /// Initialize global shortcuts
    public static func initialize() {
        GlobalShortcutManager.shared.registerAllShortcuts()
    }

    /// Check accessibility permission
    public static func checkPermission() -> Bool {
        GlobalShortcutManager.shared.checkAccessibilityPermission()
    }

    /// Show command palette
    public static func showCommandPalette() {
        CommandPalettePanel.shared.showCentered()
    }

    /// Toggle command palette
    public static func toggleCommandPalette() {
        CommandPalettePanel.shared.toggle()
    }

    /// Set action handler
    public static func setActionHandler(_ handler: @escaping (GlobalShortcutAction) -> Void) {
        GlobalShortcutManager.shared.onAction = handler
    }
}
