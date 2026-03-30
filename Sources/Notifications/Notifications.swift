// Notifications.swift
// Claude Desktop Mac - Notifications Module
//
// Public exports for Notifications module

import Foundation

// Notifications Module
public enum Notifications {
    /// Initialize notification system
    public static func initialize() {
        NotificationManager.shared.requestAuthorization()
    }

    /// Check authorization status
    public static func checkAuthorization() {
        NotificationManager.shared.checkAuthorizationStatus()
    }

    /// Send a response notification
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
    public static func clearAll() {
        NotificationManager.shared.clearAllNotifications()
    }

    /// Update badge count
    public static func updateBadge(count: Int) {
        NotificationManager.shared.updateBadge(count: count)
    }

    /// Clear badge
    public static func clearBadge() {
        NotificationManager.shared.clearBadge()
    }

    /// Set notification handlers
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
    public static func handleEvent(_ event: SessionEvent) {
        NotificationHandler.shared.handleEvent(event)
    }
}
