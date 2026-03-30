// MenuBar.swift
// Claude Desktop Mac - MenuBar Module
//
// Public exports for MenuBar module

import Foundation

// MenuBar Module
public enum MenuBar {
    /// Initialize MenuBar integration
    public static func initialize() {
        MenuBarController.shared.setupMenuBar()
    }

    /// Update MenuBar status
    public static func updateStatus(_ status: MenuBarStatus) {
        MenuBarController.shared.updateStatus(status)
    }

    /// Show Quick Ask panel
    public static func showQuickAsk() {
        QuickAskWindowController.shared.showWindow()
    }

    /// Hide Quick Ask panel
    public static func hideQuickAsk() {
        QuickAskWindowController.shared.hideWindow()
    }

    /// Toggle Quick Ask panel
    public static func toggleQuickAsk() {
        QuickAskWindowController.shared.toggleWindow()
    }
}
