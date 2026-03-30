// QuickReplyHandler.swift
// Claude Desktop Mac - Quick Reply Handler
//
// Handles quick replies from notifications

import Foundation
import UserNotifications
import AppKit
import Theme

// MARK: - Quick Reply Handler

/// Handles quick reply functionality from notifications
@MainActor
public final class QuickReplyHandler {

    // MARK: - Singleton

    public static let shared = QuickReplyHandler()

    // MARK: - Properties

    private var pendingReplies: [UUID: PendingReply] = [:]

    // MARK: - Callbacks

    public var onSendReply: ((UUID, String) -> Void)?
    public var onShowConversation: ((UUID) -> Void)?

    // MARK: - Initialization

    private init() {
        setupNotificationObserver()
    }

    // MARK: - Setup

    private func setupNotificationObserver() {
        // Observe reply notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleReplyNotification(_:)),
            name: .sendReplyFromNotification,
            object: nil
        )
    }

    @objc private func handleReplyNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let sessionIdString = userInfo["sessionId"] as? String,
              let sessionId = UUID(uuidString: sessionIdString),
              let text = userInfo["text"] as? String else {
            return
        }

        processReply(sessionId: sessionId, text: text)
    }

    // MARK: - Public Methods

    /// Process a quick reply
    public func processReply(sessionId: UUID, text: String) {
        // Validate text
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        // Store pending reply
        let pending = PendingReply(
            sessionId: sessionId,
            text: trimmedText,
            timestamp: Date()
        )
        pendingReplies[sessionId] = pending

        // Send reply
        onSendReply?(sessionId, trimmedText)

        // Post notification for UI
        NotificationCenter.default.post(
            name: .quickReplySent,
            object: nil,
            userInfo: [
                "sessionId": sessionId.uuidString,
                "text": trimmedText
            ]
        )
    }

    /// Handle reply from notification action
    public func handleNotificationReply(
        sessionId: UUID,
        text: String,
        completionHandler: @escaping () -> Void
    ) {
        processReply(sessionId: sessionId, text: text)
        completionHandler()
    }

    /// Get pending reply for a session
    public func getPendingReply(for sessionId: UUID) -> PendingReply? {
        return pendingReplies[sessionId]
    }

    /// Clear pending reply for a session
    public func clearPendingReply(for sessionId: UUID) {
        pendingReplies.removeValue(forKey: sessionId)
    }

    /// Clear all pending replies
    public func clearAllPendingReplies() {
        pendingReplies.removeAll()
    }
}

// MARK: - Pending Reply

/// Represents a pending quick reply
public struct PendingReply: Codable {
    public let sessionId: UUID
    public let text: String
    public let timestamp: Date

    public init(sessionId: UUID, text: String, timestamp: Date) {
        self.sessionId = sessionId
        self.text = text
        self.timestamp = timestamp
    }
}

// MARK: - Quick Reply Options

/// Predefined quick reply options
public enum QuickReplyOption: String, CaseIterable {
    case yes = "Yes"
    case no = "No"
    case proceed = "Proceed"
    case cancel = "Cancel"
    case apply = "Apply"
    case reject = "Reject"
    case continue_ = "Continue"
    case retry = "Retry"

    public var displayText: String {
        rawValue
    }

    /// Get suggested options based on context
    public static func suggestedOptions(for context: ReplyContext) -> [QuickReplyOption] {
        switch context {
        case .confirmation:
            return [.yes, .no]
        case .codeReview:
            return [.apply, .reject]
        case .error:
            return [.retry, .cancel]
        case .continuation:
            return [.continue_, .cancel]
        case .general:
            return [.proceed, .cancel]
        }
    }
}

// MARK: - Reply Context

/// Context for quick reply suggestions
public enum ReplyContext {
    case confirmation
    case codeReview
    case error
    case continuation
    case general
}

// MARK: - Quick Reply Panel

import SwiftUI

/// Panel for quick reply with suggestions
public struct QuickReplyPanel: View {
    let sessionId: UUID
    let context: ReplyContext
    let onReply: (String) -> Void
    let onExpand: () -> Void

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    @Environment(\.colorScheme) private var colorScheme

    public init(
        sessionId: UUID,
        context: ReplyContext,
        onReply: @escaping (String) -> Void,
        onExpand: @escaping () -> Void
    ) {
        self.sessionId = sessionId
        self.context = context
        self.onReply = onReply
        self.onExpand = onExpand
    }

    public var body: some View {
        VStack(spacing: Spacing.md.rawValue) {
            // Input field
            TextField("Quick reply...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .padding(Spacing.sm.rawValue)
                .background(Color.bgTertiary(scheme: colorScheme))
                .cornerRadius(CornerRadius.md.rawValue)
                .focused($isFocused)
                .onSubmit {
                    if !text.isEmpty {
                        onReply(text)
                    }
                }

            // Suggested options
            HStack(spacing: Spacing.sm.rawValue) {
                ForEach(QuickReplyOption.suggestedOptions(for: context), id: \.self) { option in
                    Button(option.displayText) {
                        onReply(option.displayText)
                    }
                    .buttonStyle(.secondary)
                }

                Spacer()

                // Expand button
                Button(action: onExpand) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                }
                .buttonStyle(.icon)
            }
        }
        .padding()
        .background(Color.bgPrimary(scheme: colorScheme))
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when a quick reply is sent
    public static let quickReplySent = Notification.Name("QuickReplySent")

    /// Posted when a reply should be sent from notification
    public static let sendReplyFromNotification = Notification.Name("SendReplyFromNotification")
}
