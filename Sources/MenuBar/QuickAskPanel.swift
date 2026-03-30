// QuickAskPanel.swift
// Claude Desktop Mac - Quick Ask Panel
//
// Floating panel for quick questions from MenuBar

import SwiftUI
import AppKit
import Combine

// MARK: - Quick Ask Panel

/// Floating panel for quick questions
public final class QuickAskPanel: NSPanel {

    // MARK: - Singleton

    public static let shared = QuickAskPanel()

    // MARK: - Properties

    private var hostingView: NSHostingView<QuickAskView>?
    private let viewModel = QuickAskViewModel()

    // MARK: - Initialization

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 350),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )

        setupPanel()
    }

    // MARK: - Setup

    private func setupPanel() {
        title = "Quick Ask"
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isFloatingPanel = true
        hidesOnDeactivate = true
        becomesKeyOnlyIfNeeded = false
        isMovableByWindowBackground = true

        // Set minimum size
        minSize = NSSize(width: 350, height: 200)
        maxSize = NSSize(width: 500, height: 600)

        // Create hosting view
        let view = QuickAskView(viewModel: viewModel)
        hostingView = NSHostingView(rootView: view)
        contentView = hostingView

        // Bind callbacks
        viewModel.onExpand = { [weak self] in
            self?.close()
            MenuBarController.shared.onOpenMainWindow?()
        }

        viewModel.onSend = { [weak self] _ in
            self?.close()
        }
    }

    // MARK: - Public Methods

    /// Show the panel near the MenuBar icon
    public func showNearMenuBar() {
        guard let screen = NSScreen.main,
              let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength),
              let button = statusItem.button else {
            // Fallback: center on screen
            center()
            makeKeyAndOrderFront(nil)
            return
        }

        let buttonFrame = button.window?.convertToScreen(button.frame) ?? .zero
        let screenFrame = screen.visibleFrame

        // Calculate position
        var x = buttonFrame.origin.x + buttonFrame.width / 2 - frame.width / 2
        var y = buttonFrame.origin.y - frame.height - 8

        // Keep on screen
        x = max(screenFrame.origin.x, min(x, screenFrame.origin.x + screenFrame.width - frame.width))
        y = max(screenFrame.origin.y, y)

        setFrameOrigin(NSPoint(x: x, y: y))
        makeKeyAndOrderFront(nil)

        // Focus the input
        viewModel.focusInput()
    }

    /// Hide the panel
    public func hide() {
        close()
    }

    /// Toggle visibility
    public func toggle() {
        if isVisible {
            hide()
        } else {
            showNearMenuBar()
        }
    }

    // MARK: - Override

    public override var canBecomeKey: Bool { true }
    public override var canBecomeMain: Bool { true }

    public override func resignKey() {
        super.resignKey()
        // Optionally close when losing focus
        // close()
    }

    public override func keyDown(with event: NSEvent) {
        // Handle escape key
        if event.keyCode == 53 { // Escape
            close()
            return
        }
        super.keyDown(with: event)
    }
}

// MARK: - Quick Ask View Model

/// View model for Quick Ask
@MainActor
@Observable
public final class QuickAskViewModel {

    // MARK: - Properties

    public var inputText: String = ""
    public var lastResponse: String?
    public var lastResponseSummary: String?
    public var currentProject: String?
    public var model: String = "claude-sonnet-4.6"
    public var isInputFocused: Bool = false
    public var isProcessing: Bool = false

    // MARK: - Callbacks

    public var onSend: ((String) -> Void)?
    public var onExpand: (() -> Void)?
    public var onAttach: (() -> Void)?

    // MARK: - Methods

    /// Send the current message
    public func sendMessage() {
        guard !inputText.isEmpty else { return }

        let message = inputText
        inputText = ""
        isProcessing = true

        onSend?(message)
    }

    /// Update last response
    public func updateResponse(_ response: String) {
        lastResponse = response
        lastResponseSummary = String(response.prefix(200))
        isProcessing = false
    }

    /// Focus the input field
    public func focusInput() {
        isInputFocused = true
    }

    /// Attach file
    public func attachFile() {
        onAttach?()
    }

    /// Expand to main window
    public func expandToMainWindow() {
        onExpand?()
    }

    /// Clear the current message
    public func clearInput() {
        inputText = ""
    }
}

// MARK: - Quick Ask View

/// SwiftUI view for Quick Ask panel
public struct QuickAskView: View {
    @Bindable var viewModel: QuickAskViewModel
    @FocusState private var isInputFocused: Bool

    @Environment(\.colorScheme) private var colorScheme

    public init(viewModel: QuickAskViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Response preview
            if let summary = viewModel.lastResponseSummary {
                responsePreview(summary)
            }

            // Input area
            inputArea

            // Footer
            footerView
        }
        .background(Color.bgPrimary(scheme: colorScheme))
        .onChange(of: viewModel.isInputFocused) { _, focused in
            isInputFocused = focused
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack(spacing: Spacing.md.rawValue) {
            // Logo
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 18))
                .foregroundColor(.accentPurple)

            Text("Quick Ask")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.fgPrimary(scheme: colorScheme))

            Spacer()

            // Expand button
            Button(action: { viewModel.expandToMainWindow() }) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            }
            .buttonStyle(.plain)
            .help("Open in main window")
        }
        .padding(Spacing.md.rawValue)
        .background(Color.bgSecondary(scheme: colorScheme))
    }

    private func responsePreview(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
            Text("Previous Response:")
                .font(.system(size: 11))
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))

            Text(summary)
                .font(.system(size: 13))
                .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                .lineLimit(4)

            Button("View Full Response") {
                viewModel.expandToMainWindow()
            }
            .font(.system(size: 11))
            .foregroundColor(.accentPrimary)
        }
        .padding(Spacing.md.rawValue)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bgTertiary(scheme: colorScheme))

        Divider()
    }

    private var inputArea: some View {
        VStack(spacing: Spacing.sm.rawValue) {
            TextEditor(text: $viewModel.inputText)
                .font(.system(size: 14))
                .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                .frame(minHeight: 60, maxHeight: 200)
                .focused($isInputFocused)
                .padding(Spacing.sm.rawValue)
                .background(Color.bgTertiary(scheme: colorScheme))
                .cornerRadius(CornerRadius.md.rawValue)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md.rawValue)
                        .stroke(isInputFocused ? Color.accentPrimary : Color.clear, lineWidth: 1)
                )
        }
        .padding(.horizontal, Spacing.md.rawValue)
        .padding(.top, Spacing.md.rawValue)
    }

    private var footerView: some View {
        HStack(spacing: Spacing.md.rawValue) {
            // Attach button
            Button(action: { viewModel.attachFile() }) {
                Image(systemName: "paperclip")
                    .font(.system(size: 14))
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            }
            .buttonStyle(.plain)
            .help("Attach file")

            Spacer()

            // Project info
            if let project = viewModel.currentProject {
                Text("Project: \(project)")
                    .font(.system(size: 11))
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
            }

            // Send button
            Button(action: { viewModel.sendMessage() }) {
                Text("Send")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.lg.rawValue)
                    .padding(.vertical, Spacing.xs.rawValue)
                    .background(viewModel.inputText.isEmpty ? Color.fgTertiary(scheme: colorScheme) : Color.accentPrimary)
                    .cornerRadius(CornerRadius.md.rawValue)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.inputText.isEmpty)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(Spacing.md.rawValue)
        .background(Color.bgSecondary(scheme: colorScheme))
    }
}

// MARK: - Quick Ask Window Controller

/// Window controller for Quick Ask panel
public final class QuickAskWindowController: NSWindowController {

    // MARK: - Singleton

    public static let shared = QuickAskWindowController()

    // MARK: - Initialization

    private init() {
        super.init(window: QuickAskPanel.shared)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods

    /// Show the Quick Ask panel
    public func showWindow() {
        (window as? QuickAskPanel)?.showNearMenuBar()
    }

    /// Hide the Quick Ask panel
    public func hideWindow() {
        (window as? QuickAskPanel)?.hide()
    }

    /// Toggle the Quick Ask panel
    public func toggleWindow() {
        (window as? QuickAskPanel)?.toggle()
    }
}
