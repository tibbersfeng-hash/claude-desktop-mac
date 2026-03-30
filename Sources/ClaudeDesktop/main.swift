// main.swift
// Claude Desktop Mac - Application Entry Point

import SwiftUI
import ClaudeDesktopUI

@main
struct ClaudeDesktopApplication: App {
    var body: some Scene {
        WindowGroup {
            ClaudeDesktopApp()
                .onAppear {
                    // 确保应用获得焦点
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
