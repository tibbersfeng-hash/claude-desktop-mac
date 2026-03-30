// MenuBarMenu.swift
// Claude Desktop Mac - MenuBar Menu
//
// Custom menu components for MenuBar

import SwiftUI
import AppKit
import Theme
import Models
import Project

// MARK: - Menu Item View

/// Custom view for menu items
public struct MenuItemView: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let shortcut: String?
    let isActive: Bool

    @Environment(\.colorScheme) private var colorScheme

    public init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        shortcut: String? = nil,
        isActive: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.shortcut = shortcut
        self.isActive = isActive
    }

    public var body: some View {
        HStack(spacing: Spacing.md.rawValue) {
            // Icon
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isActive ? .accentPrimary : Color.fgSecondary(scheme: colorScheme))
                    .frame(width: 20)
            }

            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                }
            }

            Spacer()

            // Shortcut
            if let shortcut = shortcut {
                Text(shortcut)
                    .font(.system(size: 12))
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                    .padding(.horizontal, Spacing.xs.rawValue)
                    .padding(.vertical, 2)
                    .background(Color.bgTertiary(scheme: colorScheme))
                    .cornerRadius(CornerRadius.sm.rawValue)
            }

            // Active indicator
            if isActive {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.accentPrimary)
            }
        }
        .padding(.horizontal, Spacing.md.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
    }
}

// MARK: - Status Menu Header

/// Header view for status menu
public struct StatusMenuHeader: View {
    let status: MenuBarStatus
    let version: String
    let model: String

    @Environment(\.colorScheme) private var colorScheme

    public init(status: MenuBarStatus, version: String, model: String) {
        self.status = status
        self.version = version
        self.model = model
    }

    public var body: some View {
        HStack(spacing: Spacing.md.rawValue) {
            // Status indicator
            Circle()
                .fill(status.statusColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(status.statusText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                Text("Claude Desktop v\(version) | \(model)")
                    .font(.system(size: 11))
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.md.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
        .background(Color.bgTertiary(scheme: colorScheme))
    }
}

// MARK: - Recent Session Menu Item

/// Menu item for recent session
public struct RecentSessionMenuItem: View {
    let session: SessionSummary

    @Environment(\.colorScheme) private var colorScheme

    public init(session: SessionSummary) {
        self.session = session
    }

    public var body: some View {
        HStack(spacing: Spacing.md.rawValue) {
            // Session icon
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 14))
                .foregroundColor(.accentPurple)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.title)
                    .font(.system(size: 13))
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                    .lineLimit(1)

                HStack(spacing: Spacing.sm.rawValue) {
                    if let projectName = session.projectName {
                        Text(projectName)
                            .font(.system(size: 11))
                            .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                    }

                    if let time = session.lastMessageTime {
                        Text(time.relativeTime)
                            .font(.system(size: 11))
                            .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.md.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
    }
}

// MARK: - Project Menu Item

/// Menu item for project
public struct ProjectMenuItem: View {
    let project: Project
    let isActive: Bool

    @Environment(\.colorScheme) private var colorScheme

    public init(project: Project, isActive: Bool = false) {
        self.project = project
        self.isActive = isActive
    }

    public var body: some View {
        HStack(spacing: Spacing.md.rawValue) {
            // Project icon
            Image(systemName: project.isFavorite ? "star.fill" : "folder.fill")
                .font(.system(size: 14))
                .foregroundColor(project.isFavorite ? .yellow : (isActive ? .accentPrimary : Color.fgSecondary(scheme: colorScheme)))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.system(size: 13))
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                    .lineLimit(1)

                Text(project.path.path)
                    .font(.system(size: 10))
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                    .lineLimit(1)
            }

            Spacer()

            // Active indicator
            if isActive {
                Text("Active")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.accentPrimary)
                    .padding(.horizontal, Spacing.xs.rawValue)
                    .padding(.vertical, 2)
                    .background(Color.accentPrimary.opacity(0.2))
                    .cornerRadius(CornerRadius.sm.rawValue)
            }
        }
        .padding(.horizontal, Spacing.md.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
    }
}

// MARK: - NSMenu Extensions

extension NSMenu {
    /// Add separator item
    @discardableResult
    func addSeparator() -> NSMenuItem {
        let item = NSMenuItem.separator()
        addItem(item)
        return item
    }

    /// Add menu item with action
    @discardableResult
    func addItem(
        title: String,
        action: Selector?,
        keyEquivalent: String = "",
        keyModifiers: NSEvent.ModifierFlags = .command,
        target: AnyObject? = nil
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = target
        if !keyEquivalent.isEmpty {
            item.keyEquivalentModifierMask = keyModifiers
        }
        addItem(item)
        return item
    }

    /// Add disabled header item
    @discardableResult
    func addHeader(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        addItem(item)
        return item
    }
}

// MARK: - Date Extension

extension Date {
    /// Relative time string
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
