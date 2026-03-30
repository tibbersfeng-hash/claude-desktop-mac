// MenuBarStatus.swift
// Claude Desktop Mac - MenuBar Status
//
// Defines MenuBar status states and related types

import SwiftUI
import AppKit

// MARK: - MenuBar Status

/// Represents the current status of the MenuBar icon
public enum MenuBarStatus: String, Sendable {
    case connected
    case connecting
    case disconnected
    case hasNewMessage
    case processing

    /// Icon name for the status
    public var iconName: String {
        switch self {
        case .connected:
            return "MenuBarIcon"
        case .connecting:
            return "MenuBarIconConnecting"
        case .disconnected:
            return "MenuBarIconDisconnected"
        case .hasNewMessage:
            return "MenuBarIconNewMessage"
        case .processing:
            return "MenuBarIconProcessing"
        }
    }

    /// Status text for display
    public var statusText: String {
        switch self {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        case .hasNewMessage:
            return "New message"
        case .processing:
            return "Processing..."
        }
    }

    /// Status color for indicators
    public var statusColor: Color {
        switch self {
        case .connected:
            return .accentSuccess
        case .connecting:
            return .accentWarning
        case .disconnected:
            return .accentError
        case .hasNewMessage:
            return .accentPrimary
        case .processing:
            return .accentPurple
        }
    }

    /// Whether the status shows activity
    public var isActive: Bool {
        switch self {
        case .connected, .hasNewMessage:
            return true
        case .connecting, .processing:
            return true
        case .disconnected:
            return false
        }
    }
}

// MARK: - MenuBar Icon

/// MenuBar icon management
public struct MenuBarIcon {
    /// Create status item image
    public static func image(for status: MenuBarStatus) -> NSImage? {
        // Try to load from asset catalog
        if let image = NSImage(named: status.iconName) {
            image.isTemplate = true
            return image
        }

        // Fallback to system symbol
        let symbolName: String
        switch status {
        case .connected:
            symbolName = "bubble.left.and.bubble.right.fill"
        case .connecting:
            symbolName = "bubble.left.and.bubble.right"
        case .disconnected:
            symbolName = "bubble.left.and.bubble.right"
        case .hasNewMessage:
            symbolName = "bubble.left.and.bubble.right.fill"
        case .processing:
            symbolName = "bubble.left.and.bubble.right.fill"
        }

        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        return NSImage(systemSymbolName: symbolName, accessibilityDescription: status.statusText)?
            .withSymbolConfiguration(config)
    }

    /// Create animated icon frames for processing state
    public static func animatedFrames(for status: MenuBarStatus) -> [NSImage] {
        guard status == .processing else {
            return [image(for: status)].compactMap { $0 }
        }

        // Create frames for animation
        let frames = ["circle.dashed", "circle.dashed.inset.filled", "circle.dashed"]
        return frames.compactMap { name in
            NSImage(systemSymbolName: name, accessibilityDescription: nil)
        }
    }
}

// MARK: - MenuBar Animation

/// Handles MenuBar icon animations
@MainActor
public final class MenuBarAnimation: ObservableObject {
    @Published public var currentFrame: Int = 0
    @Published public var isAnimating: Bool = false

    private var animationTimer: Timer?
    private let animationInterval: TimeInterval = 0.3

    public init() {}

    /// Start animation for processing state
    public func startAnimation() {
        guard !isAnimating else { return }

        isAnimating = true
        animationTimer = Timer.scheduledTimer(withTimeInterval: animationInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.advanceFrame()
            }
        }
    }

    /// Stop animation
    public func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        isAnimating = false
        currentFrame = 0
    }

    private func advanceFrame() {
        currentFrame = (currentFrame + 1) % 3
    }
}
