// Notifications.swift
// Claude Desktop Mac - Notifications Module
//
// Public exports for Notifications module

import Foundation

// Notifications Module
public enum Notifications {
    /// Initialize notification system
    @MainActor
    public static func initialize() {
        NotificationManager.shared.requestAuthorization()
    }

    /// Check authorization status
    @MainActor
    public static func checkAuthorization() {
        NotificationManager.shared.checkAuthorizationStatus()
    }

    /// Send a response notification
    @MainActor
    public static func notifyResponse(
        sessionId: UUID,
        title: String,
        message: String,
        projectName: String? = nil
    ) {
        NotificationManager.shared.sendResponseNotification(
            sessionId: sessionId,
            title: title,
            message: message,
            projectName: projectName
        )
    }

    /// Send an input needed notification
    @MainActor
    public static func notifyInputNeeded(
        sessionId: UUID,
        message: String,
        projectName: String? = nil
    ) {
        NotificationManager.shared.sendInputNeededNotification(
            sessionId: sessionId,
            message: message,
            projectName: projectName
        )
    }

    /// Send a code notification
    @MainActor
    public static func notifyCode(
        sessionId: UUID,
        code: String,
        fileName: String,
        projectName: String? = nil
    ) {
        NotificationManager.shared.sendCodeNotification(
            sessionId: sessionId,
            code: code,
            fileName: fileName,
            projectName: projectName
        )
    }

    /// Send a task complete notification
    @MainActor
    public static func notifyTaskComplete(
        sessionId: UUID,
        taskName: String,
        projectName: String? = nil
    ) {
        NotificationManager.shared.sendTaskCompleteNotification(
            sessionId: sessionId,
            taskName: taskName,
            projectName: projectName
        )
    }

    /// Send an error notification
    @MainActor
    public static func notifyError(
        title: String,
        message: String,
        sessionId: UUID? = nil
    ) {
        NotificationManager.shared.sendErrorNotification(
            title: title,
            message: message,
            sessionId: sessionId
        )
    }

    /// Clear all notifications
    @MainActor
    public static func clearAll() {
        NotificationManager.shared.clearAllNotifications()
    }

    /// Update badge count
    @MainActor
    public static func updateBadge(count: Int) {
        NotificationManager.shared.updateBadge(count: count)
    }

    /// Clear badge
    @MainActor
    public static func clearBadge() {
        NotificationManager.shared.clearBadge()
    }

    /// Set notification handlers
    @MainActor
    public static func setHandlers(
        onViewSession: ((UUID) -> Void)? = nil,
        onReply: ((UUID, String) -> Void)? = nil,
        onCopyCode: ((String) -> Void)? = nil,
        onApplyCode: ((UUID, String) -> Void)? = nil
    ) {
        let manager = NotificationManager.shared
        manager.onViewSession = onViewSession
        manager.onReply = onReply
        manager.onCopyCode = onCopyCode
        manager.onApplyCode = onApplyCode
    }

    /// Handle session event for notifications
    @MainActor
    public static func handleEvent(_ event: SessionEvent) {
        NotificationHandler.shared.handleEvent(event)
    }
}
