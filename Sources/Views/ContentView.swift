// ContentView.swift
// Claude Desktop Mac - Main Content View
//
// Root view that orchestrates the main UI layout

import SwiftUI
import Theme
import Models
import ViewModels
import State
import Combine

// MARK: - Content View

@MainActor
public struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var sessionViewModel: SessionListViewModel
    @State private var chatViewModel: ChatViewModel
    @State private var sidebarCollapsed: Bool = false
    @State private var showSettings: Bool = false

    // Window size tracking
    @State private var windowWidth: CGFloat = WindowDimensions.defaultWidth

    public init(
        sessionViewModel: SessionListViewModel,
        chatViewModel: ChatViewModel
    ) {
        self._sessionViewModel = State(initialValue: sessionViewModel)
        self._chatViewModel = State(initialValue: chatViewModel)
    }

    public var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Sidebar
                if !shouldHideSidebar(width: geometry.size.width) {
                    SidebarView(
                        viewModel: sessionViewModel,
                        isCollapsed: sidebarCollapsed || shouldCollapseSidebar(width: geometry.size.width)
                    )
                    .frame(width: sidebarWidth(for: geometry.size.width))
                    .background(Color.bgSecondary(scheme: colorScheme))

                    // Divider
                    Divider()
                        .frame(width: 1)
                        .background(Color.fgTertiary(scheme: colorScheme).opacity(0.3))
                }

                // Main content
                VStack(spacing: 0) {
                    // Main chat area
                    ChatView(
                        session: sessionViewModel.selectedSession,
                        viewModel: chatViewModel
                    )

                    // Status bar
                    StatusBarView(
                        connectionState: chatViewModel.connectionState,
                        cliVersion: chatViewModel.cliVersion,
                        model: chatViewModel.currentModel,
                        projectPath: sessionViewModel.selectedSession?.projectPath
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.bgPrimary(scheme: colorScheme))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: geometry.size.width) { _, newWidth in
                windowWidth = newWidth
            }
            .onChange(of: sessionViewModel.selectedSessionId) { _, newId in
                if let session = sessionViewModel.selectedSession {
                    chatViewModel.loadSession(session)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: toggleSidebar) {
                    Image(systemName: "sidebar.left")
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                }
                .help("Toggle Sidebar (Cmd+/)")
            }

            ToolbarItemGroup(placement: .principal) {
                if let session = sessionViewModel.selectedSession {
                    Text(session.title)
                        .font(.headline)
                        .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                }
            }

            ToolbarItemGroup(placement: .automatic) {
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape")
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                }
                .help("Settings (Cmd+,)")
            }
        }
        .onAppear {
            // Auto-connect on launch
            Task {
                await chatViewModel.connect()
                // Create a default session if none exists
                if sessionViewModel.sessions.isEmpty {
                    sessionViewModel.createSession()
                }
            }
        }
    }

    // MARK: - Sidebar Logic

    private func shouldHideSidebar(width: CGFloat) -> Bool {
        width < 800 && sidebarCollapsed
    }

    private func shouldCollapseSidebar(width: CGFloat) -> Bool {
        width >= 800 && width < 1000
    }

    private func sidebarWidth(for width: CGFloat) -> CGFloat {
        if shouldCollapseSidebar(width: width) {
            return WindowDimensions.collapsedSidebarWidth
        }
        return WindowDimensions.sidebarWidth
    }

    private func toggleSidebar() {
        sidebarCollapsed.toggle()
    }
}

// MARK: - Status Bar View

struct StatusBarView: View {
    @Environment(\.colorScheme) private var colorScheme

    let connectionState: ConnectionState
    let cliVersion: String?
    let model: String
    let projectPath: String?

    var body: some View {
        HStack(spacing: Spacing.lg.rawValue) {
            // Connection status
            HStack(spacing: Spacing.xs.rawValue) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(connectionState.description)
                    .font(.statusText)
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            }

            if let version = cliVersion {
                Text("Claude Code \(version)")
                    .font(.statusText)
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
            }

            Spacer()

            if let project = projectPath {
                HStack(spacing: Spacing.xs.rawValue) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))

                    Text(project.split(separator: "/").last.map(String.init) ?? project)
                        .font(.statusText)
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                }
            }

            Text(model)
                .font(.statusText)
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))
        }
        .padding(.horizontal, Spacing.md.rawValue)
        .frame(height: WindowDimensions.statusBarHeight)
        .background(Color.bgSecondary(scheme: colorScheme))
    }

    private var statusColor: Color {
        switch connectionState {
        case .idle, .disconnected:
            return .statusDisconnected
        case .detecting, .connecting:
            return .statusConnecting
        case .connected:
            return .statusConnected
        case .reconnecting:
            return .statusReconnecting
        case .error, .disconnecting:
            return .statusError
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: SettingsTab = .mcp
    @State private var mcpViewModel: MCPManagerViewModel = MCPManagerViewModel()

    enum SettingsTab: String, CaseIterable {
        case mcp = "MCP Servers"
        case general = "General"
        case about = "About"

        var iconName: String {
            switch self {
            case .mcp: return "server.rack"
            case .general: return "gearshape"
            case .about: return "info.circle"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            HStack(spacing: 0) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        HStack(spacing: Spacing.sm.rawValue) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 14))
                            Text(tab.rawValue)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(selectedTab == tab
                            ? Color.fgPrimary(scheme: colorScheme)
                            : Color.fgSecondary(scheme: colorScheme))
                        .padding(.horizontal, Spacing.lg.rawValue)
                        .padding(.vertical, Spacing.md.rawValue)
                        .background(selectedTab == tab
                            ? Color.bgTertiary(scheme: colorScheme)
                            : Color.clear)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.bgSecondary(scheme: colorScheme))

            Divider()
                .background(Color.fgTertiary(scheme: colorScheme).opacity(0.3))

            // Tab Content
            Group {
                switch selectedTab {
                case .mcp:
                    MCPManagerView(viewModel: mcpViewModel)
                case .general:
                    GeneralSettingsView()
                case .about:
                    AboutSettingsView()
                }
            }
        }
        .frame(width: 600, height: 500)
        .background(Color.bgPrimary(scheme: colorScheme))
    }
}

// MARK: - General Settings View

struct GeneralSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("autoConnect") private var autoConnect: Bool = true
    @AppStorage("showNotifications") private var showNotifications: Bool = true
    @AppStorage("defaultModel") private var defaultModel: String = "claude-sonnet-4.6"

    private let availableModels = [
        "claude-sonnet-4.6",
        "claude-opus-4.6",
        "claude-haiku-4.5"
    ]

    var body: some View {
        Form {
            Section("Connection") {
                Toggle("Auto-connect on launch", isOn: $autoConnect)
            }

            Section("Notifications") {
                Toggle("Show notifications", isOn: $showNotifications)
            }

            Section("Model") {
                Picker("Default Model", selection: $defaultModel) {
                    ForEach(availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .formStyle(.grouped)
        .padding(Spacing.md.rawValue)
    }
}

// MARK: - About Settings View

struct AboutSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: Spacing.xl.rawValue) {
            // App Icon
            Image(systemName: "bubble.left.and.exclamationmark.bubble.right.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentPrimary)

            // App Info
            VStack(spacing: Spacing.sm.rawValue) {
                Text("Claude Desktop Mac")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                Text("Version 1.0.0")
                    .font(.system(size: 14))
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))

                Text("A native macOS client for Claude Code CLI")
                    .font(.system(size: 14))
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                    .multilineTextAlignment(.center)
            }

            Divider()
                .background(Color.fgTertiary(scheme: colorScheme).opacity(0.3))
                .frame(width: 200)

            // Links
            VStack(spacing: Spacing.md.rawValue) {
                Link(destination: URL(string: "https://github.com/anthropics/claude-code")!) {
                    Label("GitHub Repository", systemImage: "link")
                        .foregroundColor(.accentPrimary)
                }

                Link(destination: URL(string: "https://docs.anthropic.com")!) {
                    Label("Documentation", systemImage: "book")
                        .foregroundColor(.accentPrimary)
                }
            }

            Spacer()

            // Footer
            Text("Built with SwiftUI for macOS")
                .font(.system(size: 12))
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))
        }
        .padding(Spacing.xl.rawValue)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            sessionViewModel: {
                let vm = SessionListViewModel()
                vm.sessions = Session.samples
                return vm
            }(),
            chatViewModel: ChatViewModel()
        )
        .frame(width: WindowDimensions.defaultWidth, height: WindowDimensions.defaultHeight)
    }
}
