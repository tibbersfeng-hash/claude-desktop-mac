// ShortcutRegistry.swift
// Claude Desktop Mac - Shortcut Registry
//
// Central registry for all shortcuts (both app-level and global)

import SwiftUI
import Combine

// MARK: - Shortcut Registry

/// Central registry for all shortcuts
@MainActor
public final class ShortcutRegistry: ObservableObject {

    // MARK: - Singleton

    public static let shared = ShortcutRegistry()

    // MARK: - Published Properties

    @Published public var globalShortcuts: [GlobalShortcut] = []
    @Published public var appShortcuts: [ShortcutDefinition] = []
    @Published public var conflicts: [String: [String]] = [:]

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        loadShortcuts()
        observeChanges()
    }

    // MARK: - Public Methods

    /// Get all shortcuts grouped by category
    public func getAllShortcuts() -> [(String, [Any])] {
        var result: [(String, [Any])] = []

        // Global shortcuts
        if !globalShortcuts.isEmpty {
            result.append(("Global", globalShortcuts.map { $0 }))
        }

        // App shortcuts grouped by category
        let grouped = Dictionary(grouping: appShortcuts) { $0.action.category.displayName }
        for category in ShortcutCategory.allCases {
            if let items = grouped[category.displayName], !items.isEmpty {
                result.append((category.displayName, items))
            }
        }

        return result
    }

    /// Find conflicts between shortcuts
    public func findConflicts() -> [String: [String]] {
        var conflicts: [String: [String]] = [:]

        // Check global shortcut conflicts
        for (i, shortcut1) in globalShortcuts.enumerated() {
            var conflicting: [String] = []

            for (j, shortcut2) in globalShortcuts.enumerated() where i != j {
                if shortcut1.keyCode == shortcut2.keyCode &&
                   shortcut1.modifiers == shortcut2.modifiers {
                    conflicting.append(shortcut2.name)
                }
            }

            if !conflicting.isEmpty {
                conflicts[shortcut1.id] = conflicting
            }
        }

        self.conflicts = conflicts
        return conflicts
    }

    /// Update a global shortcut
    public func updateGlobalShortcut(id: String, keyCode: UInt32, modifiers: NSEvent.ModifierFlags) {
        GlobalShortcutManager.shared.updateShortcut(id, keyCode: keyCode, modifiers: modifiers)
        loadShortcuts()
    }

    /// Update an app shortcut
    public func updateAppShortcut(_ action: ShortcutAction, key: String, modifiers: [ModifierKey]) {
        ShortcutManager.shared.updateShortcut(action, key: key, modifiers: modifiers)
        loadShortcuts()
    }

    /// Reset all shortcuts to defaults
    public func resetAllToDefaults() {
        GlobalShortcutManager.shared.resetToDefaults()
        ShortcutManager.shared.resetAllShortcuts()
        loadShortcuts()
    }

    /// Export shortcuts for backup
    public func exportShortcuts() -> ShortcutExport {
        ShortcutExport(
            globalShortcuts: globalShortcuts,
            appShortcuts: appShortcuts
        )
    }

    /// Import shortcuts from backup
    public func importShortcuts(_ export: ShortcutExport) {
        // Import global shortcuts
        if let data = try? JSONEncoder().encode(export.globalShortcuts) {
            UserDefaults.standard.set(data, forKey: "GlobalShortcuts")
        }

        // Import app shortcuts
        if let data = try? JSONEncoder().encode(
            Dictionary(uniqueKeysWithValues: export.appShortcuts.map { ($0.action.rawValue, $0) })
        ) {
            UserDefaults.standard.set(data, forKey: "KeyboardShortcuts")
        }

        loadShortcuts()
    }

    // MARK: - Private Methods

    private func loadShortcuts() {
        globalShortcuts = GlobalShortcutManager.shared.shortcuts
        appShortcuts = ShortcutDefinition.defaults
    }

    private func observeChanges() {
        GlobalShortcutManager.shared.$shortcuts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadShortcuts()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Shortcut Export

/// Structure for exporting/importing shortcuts
public struct ShortcutExport: Codable {
    public let globalShortcuts: [GlobalShortcut]
    public let appShortcuts: [ShortcutDefinition]
    public let exportedAt: Date

    public init(globalShortcuts: [GlobalShortcut], appShortcuts: [ShortcutDefinition]) {
        self.globalShortcuts = globalShortcuts
        self.appShortcuts = appShortcuts
        self.exportedAt = Date()
    }
}

// MARK: - Shortcut Settings View

/// View for configuring shortcuts
public struct ShortcutSettingsView: View {
    @StateObject private var registry = ShortcutRegistry.shared
    @State private var selectedCategory: ShortcutSettingsCategory = .global
    @State private var editingShortcut: String?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

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
                        ForEach(ShortcutSettingsCategory.allCases) { category in
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
                        shortcutSection
                    }
                    .padding()
                }
            }

            Divider()

            // Footer
            HStack {
                Button("Reset All") {
                    registry.resetAllToDefaults()
                }
                .buttonStyle(.secondary)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.primary)
            }
            .padding()
            .background(Color.bgSecondary(scheme: colorScheme))
        }
        .frame(width: 600, height: 500)
        .background(Color.bgPrimary(scheme: colorScheme))
    }

    @ViewBuilder
    private var shortcutSection: some View {
        switch selectedCategory {
        case .global:
            globalShortcutsSection
        case .session:
            appShortcutsSection(category: .session)
        case .navigation:
            appShortcutsSection(category: .navigation)
        case .message:
            appShortcutsSection(category: .message)
        case .general:
            appShortcutsSection(category: .general)
        }
    }

    private var globalShortcutsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
            Text("Global Shortcuts")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))

            ForEach(registry.globalShortcuts) { shortcut in
                globalShortcutRow(shortcut)
            }
        }
    }

    private func appShortcutsSection(category: ShortcutCategory) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
            Text(category.displayName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))

            ForEach(category.shortcuts) { action in
                appShortcutRow(action)
            }
        }
    }

    private func globalShortcutRow(_ shortcut: GlobalShortcut) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(shortcut.name)
                    .font(.callout)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                Text(shortcut.description)
                    .font(.caption)
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            }

            Spacer()

            Text(shortcut.displayString)
                .font(.caption)
                .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                .padding(.horizontal, Spacing.sm.rawValue)
                .padding(.vertical, 4)
                .background(Color.bgTertiary(scheme: colorScheme))
                .cornerRadius(CornerRadius.sm.rawValue)
        }
        .padding(.vertical, Spacing.xs.rawValue)
    }

    private func appShortcutRow(_ action: ShortcutAction) -> some View {
        let definition = ShortcutManager.shared.shortcut(for: action)

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(action.displayName)
                    .font(.callout)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                Text(action.description)
                    .font(.caption)
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            }

            Spacer()

            HStack(spacing: 4) {
                ForEach(definition.modifiers, id: \.self) { modifier in
                    Text(modifier.symbol)
                        .font(.caption)
                        .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                        .padding(.horizontal, Spacing.xs.rawValue)
                        .padding(.vertical, 2)
                        .background(Color.bgTertiary(scheme: colorScheme))
                        .cornerRadius(CornerRadius.sm.rawValue)
                }

                Text(definition.key.uppercased())
                    .font(.caption)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                    .padding(.horizontal, Spacing.xs.rawValue)
                    .padding(.vertical, 2)
                    .background(Color.bgTertiary(scheme: colorScheme))
                    .cornerRadius(CornerRadius.sm.rawValue)
            }
        }
        .padding(.vertical, Spacing.xs.rawValue)
    }
}

// MARK: - Shortcut Settings Category

public enum ShortcutSettingsCategory: String, CaseIterable, Identifiable {
    case global = "Global"
    case session = "Session"
    case navigation = "Navigation"
    case message = "Message"
    case general = "General"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .global: return "globe"
        case .session: return "bubble.left.and.bubble.right"
        case .navigation: return "arrow.up.arrow.down"
        case .message: return "message"
        case .general: return "gearshape"
        }
    }

    public var displayName: String { rawValue }
}

// MARK: - Category Button ( reused from ShortcutManager )

private struct CategoryButton: View {
    let category: ShortcutSettingsCategory
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
