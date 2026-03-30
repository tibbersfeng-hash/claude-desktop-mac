// ShortcutManager.swift
// Claude Desktop Mac - Shortcut Manager
//
// Manages keyboard shortcuts and their execution

import SwiftUI
import Combine

// MARK: - Shortcut Manager

/// Manages keyboard shortcuts for the application
@MainActor
@Observable
public final class ShortcutManager {

    // MARK: - Singleton

    public static let shared = ShortcutManager()

    // MARK: - Properties

    /// Current shortcut definitions
    public var shortcuts: [ShortcutAction: ShortcutDefinition] = [:]

    /// Whether shortcuts are enabled
    public var isEnabled: Bool = true

    /// Last triggered shortcut
    public var lastTriggered: ShortcutAction?

    /// Callback for shortcut execution
    public var onShortcutTriggered: ((ShortcutAction) -> Void)?

    // MARK: - UserDefaults Keys

    private let shortcutsKey = "KeyboardShortcuts"

    // MARK: - Initialization

    private init() {
        loadShortcuts()
    }

    // MARK: - Public Methods

    /// Get the current shortcut for an action
    public func shortcut(for action: ShortcutAction) -> ShortcutDefinition {
        shortcuts[action] ?? ShortcutDefinition.definition(for: action)
    }

    /// Update a shortcut
    public func updateShortcut(_ action: ShortcutAction, key: String, modifiers: [ModifierKey]) {
        var definition = shortcut(for: action)
        definition = ShortcutDefinition(
            action: action,
            key: key,
            modifiers: modifiers,
            isEditable: definition.isEditable
        )
        shortcuts[action] = definition
        saveShortcuts()
    }

    /// Reset a shortcut to its default
    public func resetShortcut(_ action: ShortcutAction) {
        let defaultDefinition = ShortcutDefinition.definition(for: action)
        shortcuts[action] = defaultDefinition
        saveShortcuts()
    }

    /// Reset all shortcuts to defaults
    public func resetAllShortcuts() {
        shortcuts = [:]
        loadShortcuts()  // This will load defaults
        saveShortcuts()
    }

    /// Check for shortcut conflicts
    public func findConflicts() -> [ShortcutAction: [ShortcutAction]] {
        var conflicts: [ShortcutAction: [ShortcutAction]] = [:]

        for (action1, def1) in shortcuts {
            var conflictingActions: [ShortcutAction] = []

            for (action2, def2) in shortcuts where action1 != action2 {
                if def1.key == def2.key && def1.modifiers == def2.modifiers {
                    conflictingActions.append(action2)
                }
            }

            if !conflictingActions.isEmpty {
                conflicts[action1] = conflictingActions
            }
        }

        return conflicts
    }

    /// Trigger a shortcut programmatically
    public func trigger(_ action: ShortcutAction) {
        guard isEnabled else { return }

        lastTriggered = action
        onShortcutTriggered?(action)

        // Post notification
        NotificationCenter.default.post(
            name: .shortcutTriggered,
            object: nil,
            userInfo: ["action": action.rawValue]
        )
    }

    // MARK: - Loading & Saving

    private func loadShortcuts() {
        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: shortcutsKey),
           let saved = try? JSONDecoder().decode([String: ShortcutDefinition].self, from: data) {
            for (actionRaw, definition) in saved {
                if let action = ShortcutAction(rawValue: actionRaw) {
                    shortcuts[action] = definition
                }
            }
        } else {
            // Use defaults
            for definition in ShortcutDefinition.defaults {
                shortcuts[definition.action] = definition
            }
        }
    }

    private func saveShortcuts() {
        let dict = Dictionary(uniqueKeysWithValues: shortcuts.map { ($0.key.rawValue, $0.value) })

        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: shortcutsKey)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let shortcutTriggered = Notification.Name("ShortcutTriggered")
}

// MARK: - SwiftUI View Extension

extension View {
    /// Add keyboard shortcut handling to a view
    public func shortcutHandler(_ manager: ShortcutManager = .shared) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .shortcutTriggered)) { notification in
            if let actionRaw = notification.userInfo?["action"] as? String,
               let action = ShortcutAction(rawValue: actionRaw) {
                manager.onShortcutTriggered?(action)
            }
        }
    }

    /// Add a keyboard shortcut for an action
    public func keyboardShortcut(
        _ action: ShortcutAction,
        manager: ShortcutManager = .shared,
        perform handler: @escaping () -> Void
    ) -> some View {
        let definition = manager.shortcut(for: action)

        return self.onKeyDown(key: definition.key, modifiers: definition.modifiers) {
            if manager.isEnabled {
                manager.lastTriggered = action
                handler()
            }
        }
    }

    /// Handle key down events
    private func onKeyDown(key: String, modifiers: [ModifierKey], perform handler: @escaping () -> Void) -> some View {
        self.onKeyPress(KeyEquivalent(Character(key))) {
            // Check modifiers
            let currentModifiers = NSEvent.modifierFlags
            let requiredModifiers = modifiers.map { $0.NSEventModifierFlags }.reduce(NSEvent.ModifierFlags(), { $0.union($1) })

            if currentModifiers == requiredModifiers {
                handler()
                return .handled
            }
            return .ignored
        }
    }
}

// MARK: - NSEvent Extension

extension NSEvent {
    /// Current modifier flags
    static var modifierFlags: ModifierFlags {
        NSApp.currentEvent?.modifierFlags ?? []
    }
}

// MARK: - Keyboard Shortcuts View

/// A view displaying all keyboard shortcuts
public struct KeyboardShortcutsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: ShortcutCategory = .session
    @State private var editingShortcut: ShortcutAction?

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Keyboard Shortcuts")
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

            HStack(spacing: 0) {
                // Category sidebar
                ScrollView {
                    VStack(spacing: Spacing.xs.rawValue) {
                        ForEach(ShortcutCategory.allCases) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category,
                                colorScheme: colorScheme,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(Spacing.sm.rawValue)
                }
                .frame(width: 150)
                .background(Color.bgSecondary(scheme: colorScheme))

                Divider()

                // Shortcuts list
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
                        ForEach(selectedCategory.shortcuts) { action in
                            ShortcutRow(
                                action: action,
                                colorScheme: colorScheme,
                                onEdit: { editingShortcut = action }
                            )
                        }
                    }
                    .padding()
                }
            }

            Divider()

            // Footer
            HStack {
                Button("Reset All") {
                    ShortcutManager.shared.resetAllShortcuts()
                }
                .buttonStyle(.secondary)

                Spacer()

                Button("Edit Shortcuts...") {
                    // Open shortcut editor
                }
                .buttonStyle(.secondary)
            }
            .padding()
            .background(Color.bgSecondary(scheme: colorScheme))
        }
        .frame(width: 600, height: 500)
        .background(Color.bgPrimary(scheme: colorScheme))
    }
}

// MARK: - Category Button

private struct CategoryButton: View {
    let category: ShortcutCategory
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: category.icon)
                    .frame(width: 20)

                Text(category.displayName)
                    .font(.callout)

                Spacer()
            }
            .foregroundColor(isSelected ? .fgInverse(scheme: colorScheme) : Color.fgPrimary(scheme: colorScheme))
            .padding(.horizontal, Spacing.sm.rawValue)
            .padding(.vertical, Spacing.xs.rawValue)
            .background(isSelected ? Color.accentPrimary : Color.clear)
            .cornerRadius(CornerRadius.sm.rawValue)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shortcut Row

private struct ShortcutRow: View {
    let action: ShortcutAction
    let colorScheme: ColorScheme
    let onEdit: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(action.displayName)
                    .font(.callout)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                Text(action.description)
                    .font(.caption)
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            }

            Spacer()

            // Shortcut keys
            HStack(spacing: 4) {
                ForEach(shortcutKeys, id: \.self) { key in
                    Text(key)
                        .font(.caption)
                        .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                        .padding(.horizontal, Spacing.xs.rawValue)
                        .padding(.vertical, 2)
                        .background(Color.bgTertiary(scheme: colorScheme))
                        .cornerRadius(CornerRadius.sm.rawValue)
                }
            }

            if isHovered {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                }
                .buttonStyle(.icon(size: 20))
            }
        }
        .padding(.vertical, Spacing.xs.rawValue)
        .onHover { isHovered = $0 }
    }

    private var shortcutKeys: [String] {
        let definition = ShortcutManager.shared.shortcut(for: action)
        var keys: [String] = definition.modifiers.map { $0.symbol }
        keys.append(definition.key.uppercased())
        return keys
    }
}
