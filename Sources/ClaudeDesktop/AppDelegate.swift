// AppDelegate.swift
// Claude Desktop Mac - Application Entry Point

import SwiftUI
import ClaudeDesktopUI

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 确保应用显示在所有窗口最前面
        NSApp.activate(ignoringOtherApps: true)

        // 确保应用有菜单栏
        if NSApp.mainMenu == nil {
            let mainMenu = NSMenu()
            NSApp.mainMenu = mainMenu
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// MARK: - SwiftUI App

@main
struct ClaudeDesktopApplication: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ClaudeDesktopApp()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
