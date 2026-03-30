// ClaudeDesktopUI.swift
// Claude Desktop Mac - UI Module Entry Point
//
// Main entry point for the Claude Desktop UI layer

import SwiftUI

// Re-export all UI components
@_exported import Theme
@_exported import Models
@_exported import ViewModels
@_exported import Views
@_exported import CLIConnector

// MARK: - Claude Desktop App

/// Main application view for Claude Desktop
public struct ClaudeDesktopApp: View {
    @State private var sessionViewModel: SessionListViewModel
    @State private var chatViewModel: ChatViewModel

    public init() {
        self._sessionViewModel = State(initialValue: SessionListViewModel())
        self._chatViewModel = State(initialValue: ChatViewModel())
    }

    public var body: some View {
        ContentView(
            sessionViewModel: sessionViewModel,
            chatViewModel: chatViewModel
        )
        .frame(minWidth: WindowDimensions.minWidth, minHeight: WindowDimensions.minHeight)
        .preferredColorScheme(.dark)
    }
}

// MARK: - App Configuration

public struct ClaudeDesktopConfiguration {
    public var defaultModel: String
    public var defaultProjectPath: String?
    public var theme: ColorScheme
    public var autoConnect: Bool

    public init(
        defaultModel: String = "claude-sonnet-4.6",
        defaultProjectPath: String? = nil,
        theme: ColorScheme = .dark,
        autoConnect: Bool = true
    ) {
        self.defaultModel = defaultModel
        self.defaultProjectPath = defaultProjectPath
        self.theme = theme
        self.autoConnect = autoConnect
    }
}

// MARK: - Preview

#if DEBUG
@available(macOS 14.0, *)
struct ClaudeDesktopUI_Previews: PreviewProvider {
    static var previews: some View {
        ClaudeDesktopApp()
            .frame(width: WindowDimensions.defaultWidth, height: WindowDimensions.defaultHeight)
    }
}
#endif
