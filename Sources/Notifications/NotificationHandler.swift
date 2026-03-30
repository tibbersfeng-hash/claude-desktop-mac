// NotificationHandler.swift
// Claude Desktop Mac - Notification Handler
//
// Handles notification events and triggers

import Foundation
import UserNotifications

// MARK: - Notification Handler

/// Handles notification events and conditions
@MainActor
public final class NotificationHandler {

    // MARK: - Singleton

    public static let shared = NotificationHandler()

    // MARK: - Properties

    private var enabledTypes: Set<NotificationType> = Set(NotificationType.allCases)
    private var quietHours: QuietHours?

    // MARK: - Notification Types

    public enum NotificationType: String, CaseIterable, Codable {
        case responseComplete = "response_complete"
        case inputNeeded = "input_needed"
        case taskComplete = "task_complete"
        case codeSuggestion = "code_suggestion"
        case error = "error"
        case reminder = "reminder"

        public var displayName: String {
            switch self {
            case .responseComplete: return "Response Complete"
            case .inputNeeded: return "Input Needed"
            case .taskComplete: return "Task Complete"
            case .codeSuggestion: return "Code Suggestion"
            case .error: return "Error"
            case .reminder: return "Reminder"
            }
        }

        public var description: String {
            switch self {
            case .responseComplete: return "Notify when Claude finishes responding"
            case .inputNeeded: return "Notify when Claude needs your input"
            case .taskComplete: return "Notify when a long task completes"
            case .codeSuggestion: return "Notify for code suggestions"
            case .error: return "Notify on errors"
            case .reminder: return "Scheduled reminders"
            }
        }
    }

    // MARK: - Initialization

    private init() {
        loadSettings()
    }

    // MARK: - Public Methods

    /// Check if a notification type is enabled
    public func isEnabled(_ type: NotificationType) -> Bool {
        enabledTypes.contains(type) && !isQuietHours()
    }

    /// Enable a notification type
    public func enable(_ type: NotificationType) {
        enabledTypes.insert(type)
        saveSettings()
    }

    /// Disable a notification type
    public func disable(_ type: NotificationType) {
        enabledTypes.remove(type)
        saveSettings()
    }

    /// Toggle a notification type
    public func toggle(_ type: NotificationType) {
        if enabledTypes.contains(type) {
            enabledTypes.remove(type)
        } else {
            enabledTypes.insert(type)
        }
        saveSettings()
    }

    /// Set quiet hours
    public func setQuietHours(start: Date, end: Date, enabled: Bool) {
        quietHours = QuietHours(start: start, end: end, enabled: enabled)
        saveSettings()
    }

    /// Disable quiet hours
    public func disableQuietHours() {
        quietHours?.enabled = false
        saveSettings()
    }

    /// Check if currently in quiet hours
    public func isQuietHours() -> Bool {
        guard let quietHours = quietHours, quietHours.enabled else {
            return false
        }

        let calendar = Calendar.current
        let now = Date()
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let startTime = calendar.dateComponents([.hour, .minute], from: quietHours.start)
        let endTime = calendar.dateComponents([.hour, .minute], from: quietHours.end)

        // Compare time components
        guard let currentMinutes = currentTime.hour! * 60 + currentTime.minute!,
              let startMinutes = startTime.hour! * 60 + startTime.minute!,
              let endMinutes = endTime.hour! * 60 + endTime.minute! else {
            return false
        }

        if startMinutes <= endMinutes {
            // Same day range
            return currentMinutes >= startMinutes && currentMinutes <= endMinutes
        } else {
            // Overnight range
            return currentMinutes >= startMinutes || currentMinutes <= endMinutes
        }
    }

    /// Should show notification for session event
    public func shouldNotify(for event: SessionEvent) -> Bool {
        // Don't notify if app is active and in foreground
        if NSApp.isActive, !event.notifyWhenActive {
            return false
        }

        return isEnabled(event.notificationType)
    }

    /// Handle session event
    public func handleEvent(_ event: SessionEvent) {
        guard shouldNotify(for: event) else { return }

        switch event {
        case .responseComplete(let sessionId, let title, let message, let projectName):
            NotificationManager.shared.sendResponseNotification(
                sessionId: sessionId,
                title: title,
                message: message,
                projectName: projectName
            )

        case .inputNeeded(let sessionId, let message, let projectName):
            NotificationManager.shared.sendInputNeededNotification(
                sessionId: sessionId,
                message: message,
                projectName: projectName
            )

        case .taskComplete(let sessionId, let taskName, let projectName):
            NotificationManager.shared.sendTaskCompleteNotification(
                sessionId: sessionId,
                taskName: taskName,
                projectName: projectName
            )

        case .codeSuggestion(let sessionId, let code, let fileName, let projectName):
            NotificationManager.shared.sendCodeNotification(
                sessionId: sessionId,
                code: code,
                fileName: fileName,
                projectName: projectName
            )

        case .error(let title, let message, let sessionId):
            NotificationManager.shared.sendErrorNotification(
                title: title,
                message: message,
                sessionId: sessionId
            )
        }
    }

    // MARK: - Persistence

    private func loadSettings() {
        // Load enabled types
        if let data = UserDefaults.standard.data(forKey: "NotificationTypes"),
           let types = try? JSONDecoder().decode(Set<NotificationType>.self, from: data) {
            enabledTypes = types
        }

        // Load quiet hours
        if let data = UserDefaults.standard.data(forKey: "QuietHours"),
           let hours = try? JSONDecoder().decode(QuietHours.self, from: data) {
            quietHours = hours
        }
    }

    private func saveSettings() {
        // Save enabled types
        if let data = try? JSONEncoder().encode(enabledTypes) {
            UserDefaults.standard.set(data, forKey: "NotificationTypes")
        }

        // Save quiet hours
        if let hours = quietHours,
           let data = try? JSONEncoder().encode(hours) {
            UserDefaults.standard.set(data, forKey: "QuietHours")
        }
    }
}

// MARK: - Session Event

/// Events that can trigger notifications
public enum SessionEvent {
    case responseComplete(sessionId: UUID, title: String, message: String, projectName: String?)
    case inputNeeded(sessionId: UUID, message: String, projectName: String?)
    case taskComplete(sessionId: UUID, taskName: String, projectName: String?)
    case codeSuggestion(sessionId: UUID, code: String, fileName: String, projectName: String?)
    case error(title: String, message: String, sessionId: UUID?)

    var notificationType: NotificationHandler.NotificationType {
        switch self {
        case .responseComplete: return .responseComplete
        case .inputNeeded: return .inputNeeded
        case .taskComplete: return .taskComplete
        case .codeSuggestion: return .codeSuggestion
        case .error: return .error
        }
    }

    var notifyWhenActive: Bool {
        switch self {
        case .inputNeeded, .error:
            return true
        default:
            return false
        }
    }
}

// MARK: - Quiet Hours

/// Represents quiet hours settings
struct QuietHours: Codable {
    var start: Date
    var end: Date
    var enabled: Bool
}

// MARK: - Notification Settings View

import SwiftUI

/// Settings view for notifications
public struct NotificationSettingsView: View {
    @StateObject private var handler = NotificationHandler.shared
    @StateObject private var manager = NotificationManager.shared

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Notifications")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.bgSecondary(scheme: colorScheme))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg.rawValue) {
                    // Authorization status
                    authorizationSection

                    Divider()

                    // Notification types
                    notificationTypesSection

                    Divider()

                    // Quiet hours
                    quietHoursSection

                    Divider()

                    // System settings link
                    systemSettingsSection
                }
                .padding()
            }
        }
        .frame(width: 450, height: 500)
        .background(Color.bgPrimary(scheme: colorScheme))
        .onAppear {
            manager.checkAuthorizationStatus()
        }
    }

    private var authorizationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
            Text("Authorization")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))

            HStack {
                Image(systemName: manager.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(manager.isAuthorized ? .accentSuccess : .accentError)

                Text(manager.isAuthorized ? "Notifications Enabled" : "Notifications Disabled")
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                Spacer()

                if !manager.isAuthorized {
                    Button("Enable") {
                        manager.requestAuthorization()
                    }
                    .buttonStyle(.primary)
                }
            }
        }
    }

    private var notificationTypesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
            Text("Notification Types")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))

            ForEach(NotificationHandler.NotificationType.allCases, id: \.self) { type in
                Toggle(isOn: Binding(
                    get: { handler.isEnabled(type) },
                    set: { _ in handler.toggle(type) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(type.displayName)
                            .font(.callout)
                            .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                        Text(type.description)
                            .font(.caption)
                            .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                    }
                }
                .toggleStyle(.switch)
            }
        }
    }

    @State private var quietHoursEnabled = false

    private var quietHoursSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
            Toggle("Quiet Hours", isOn: $quietHoursEnabled)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))

            if quietHoursEnabled {
                Text("Notifications will be silenced during the specified hours.")
                    .font(.caption)
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
            }
        }
    }

    private var systemSettingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
            Text("System Settings")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))

            Button("Open System Notification Settings...") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.secondary)
        }
    }
}
