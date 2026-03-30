// NotificationManager.swift
// Claude Desktop Mac - Notification Manager
//
// Manages user notifications for the application

import Foundation
import UserNotifications
import AppKit

// MARK: - Notification Manager

/// Manages user notifications
@MainActor
public final class NotificationManager: NSObject, ObservableObject {

    // MARK: - Singleton

    public static let shared = NotificationManager()

    // MARK: - Published Properties

    @Published public var isAuthorized: Bool = false
    @Published public var notificationSettings: UNNotificationSettings?

    // MARK: - Properties

    private let center = UNUserNotificationCenter.current()

    // MARK: - Notification Categories

    public enum Category: String, CaseIterable {
        case response = "RESPONSE_CATEGORY"
        case inputNeeded = "INPUT_CATEGORY"
        case code = "CODE_CATEGORY"
        case taskComplete = "TASK_CATEGORY"
        case error = "ERROR_CATEGORY"
    }

    // MARK: - Notification Actions

    public enum Action: String, CaseIterable {
        case view = "VIEW_ACTION"
        case dismiss = "DISMISS_ACTION"
        case reply = "REPLY_ACTION"
        case copyCode = "COPY_CODE_ACTION"
        case apply = "APPLY_ACTION"
        case accept = "ACCEPT_ACTION"
        case reject = "REJECT_ACTION"
    }

    // MARK: - Callbacks

    public var onViewSession: ((UUID) -> Void)?
    public var onReply: ((UUID, String) -> Void)?
    public var onCopyCode: ((String) -> Void)?
    public var onApplyCode: ((UUID, String) -> Void)?

    // MARK: - Initialization

    private override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Authorization

    /// Request notification authorization
    public func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if granted {
                    self?.setupCategories()
                }
                if let error = error {
                    print("Notification authorization error: \(error)")
                }
            }
        }
    }

    /// Check current authorization status
    public func checkAuthorizationStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
                self?.notificationSettings = settings
            }
        }
    }

    // MARK: - Setup

    /// Setup notification categories and actions
    public func setupCategories() {
        var categories: Set<UNNotificationCategory> = []

        // Response category - basic notification with view button
        let viewAction = UNNotificationAction(
            identifier: Action.view.rawValue,
            title: "View",
            options: [.foreground]
        )

        let dismissAction = UNNotificationAction(
            identifier: Action.dismiss.rawValue,
            title: "Dismiss",
            options: []
        )

        let responseCategory = UNNotificationCategory(
            identifier: Category.response.rawValue,
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        categories.insert(responseCategory)

        // Input needed category - with text reply
        let replyAction = UNTextInputNotificationAction(
            identifier: Action.reply.rawValue,
            title: "Reply",
            options: [],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type your response..."
        )

        let inputCategory = UNNotificationCategory(
            identifier: Category.inputNeeded.rawValue,
            actions: [replyAction, viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        categories.insert(inputCategory)

        // Code category - with copy and apply actions
        let copyCodeAction = UNNotificationAction(
            identifier: Action.copyCode.rawValue,
            title: "Copy Code",
            options: []
        )

        let applyAction = UNNotificationAction(
            identifier: Action.apply.rawValue,
            title: "Apply to File",
            options: [.foreground]
        )

        let codeCategory = UNNotificationCategory(
            identifier: Category.code.rawValue,
            actions: [copyCodeAction, applyAction, viewAction],
            intentIdentifiers: [],
            options: []
        )
        categories.insert(codeCategory)

        // Task complete category
        let taskCategory = UNNotificationCategory(
            identifier: Category.taskComplete.rawValue,
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        categories.insert(taskCategory)

        // Error category
        let errorCategory = UNNotificationCategory(
            identifier: Category.error.rawValue,
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        categories.insert(errorCategory)

        center.setNotificationCategories(categories)
    }

    // MARK: - Send Notifications

    /// Send a response notification
    public func sendResponseNotification(
        sessionId: UUID,
        title: String,
        message: String,
        projectName: String? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.categoryIdentifier = Category.response.rawValue
        content.userInfo = [
            "sessionId": sessionId.uuidString,
            "type": "response",
            "projectName": projectName ?? ""
        ]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }

    /// Send an input needed notification
    public func sendInputNeededNotification(
        sessionId: UUID,
        message: String,
        projectName: String? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Claude needs your input"
        content.body = message
        content.sound = .default
        content.categoryIdentifier = Category.inputNeeded.rawValue
        content.userInfo = [
            "sessionId": sessionId.uuidString,
            "type": "input_needed",
            "projectName": projectName ?? ""
        ]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }

    /// Send a code notification
    public func sendCodeNotification(
        sessionId: UUID,
        code: String,
        fileName: String,
        projectName: String? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Code suggestion for \(fileName)"
        content.body = String(code.prefix(100)) + (code.count > 100 ? "..." : "")
        content.sound = .default
        content.categoryIdentifier = Category.code.rawValue
        content.userInfo = [
            "sessionId": sessionId.uuidString,
            "code": code,
            "fileName": fileName,
            "type": "code",
            "projectName": projectName ?? ""
        ]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }

    /// Send a task completion notification
    public func sendTaskCompleteNotification(
        sessionId: UUID,
        taskName: String,
        projectName: String? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Task completed"
        content.body = "\(taskName) has been completed"
        content.sound = .default
        content.categoryIdentifier = Category.taskComplete.rawValue
        content.userInfo = [
            "sessionId": sessionId.uuidString,
            "taskName": taskName,
            "type": "task_complete",
            "projectName": projectName ?? ""
        ]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }

    /// Send an error notification
    public func sendErrorNotification(
        title: String,
        message: String,
        sessionId: UUID? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .defaultCritical
        content.categoryIdentifier = Category.error.rawValue

        var userInfo: [String: Any] = ["type": "error"]
        if let sessionId = sessionId {
            userInfo["sessionId"] = sessionId.uuidString
        }
        content.userInfo = userInfo

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }

    // MARK: - Management

    /// Remove all delivered notifications
    public func clearAllNotifications() {
        center.removeAllDeliveredNotifications()
    }

    /// Remove all pending notifications
    public func cancelAllPendingNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    /// Update the app badge
    public func updateBadge(count: Int) {
        center.setBadgeCount(count) { error in
            if let error = error {
                print("Failed to update badge: \(error)")
            }
        }
    }

    /// Clear the app badge
    public func clearBadge() {
        updateBadge(count: 0)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Extract session ID
        let sessionIdString = userInfo["sessionId"] as? String
        let sessionId = sessionIdString.flatMap { UUID(uuidString: $0) }

        // Handle actions
        switch response.actionIdentifier {
        case Action.view.rawValue:
            if let sessionId = sessionId {
                onViewSession?(sessionId)
            }

        case Action.reply.rawValue:
            if let textResponse = response as? UNTextInputNotificationResponse,
               let sessionId = sessionId {
                let replyText = textResponse.userText
                onReply?(sessionId, replyText)
            }

        case Action.copyCode.rawValue:
            if let code = userInfo["code"] as? String {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(code, forType: .string)
                onCopyCode?(code)
            }

        case Action.apply.rawValue:
            if let sessionId = sessionId,
               let fileName = userInfo["fileName"] as? String,
               let code = userInfo["code"] as? String {
                onApplyCode?(sessionId, fileName)
            }

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself
            if let sessionId = sessionId {
                onViewSession?(sessionId)
            }

        case Action.dismiss.rawValue:
            // Just dismiss
            break

        default:
            break
        }

        completionHandler()
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        if NSApp.isActive {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.banner, .sound, .badge])
        }
    }
}
