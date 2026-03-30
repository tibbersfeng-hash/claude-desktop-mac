// GlobalShortcutManager.swift
// Claude Desktop Mac - Global Shortcut Manager
//
// Manages system-wide keyboard shortcuts using Carbon Event Manager

import SwiftUI
import AppKit
import Carbon

// MARK: - Global Shortcut

/// Represents a global keyboard shortcut
public struct GlobalShortcut: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public var keyCode: UInt32
    public var modifiers: UInt32
    public let action: GlobalShortcutAction

    public init(
        id: String,
        name: String,
        description: String,
        keyCode: UInt32,
        modifiers: NSEvent.ModifierFlags,
        action: GlobalShortcutAction
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.keyCode = keyCode
        self.modifiers = modifiers.carbonFlags
        self.action = action
    }

    /// Display string for the shortcut
    public var displayString: String {
        var parts: [String] = []

        if modifiers & UInt32(cmdKey) != 0 { parts.append("\u{2318}") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("\u{2325}") }
        if modifiers & UInt32(controlKey) != 0 { parts.append("\u{2303}") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("\u{21E7}") }

        parts.append(keyCodeToString(keyCode))

        return parts.joined()
    }

    /// Convert keycode to string
    private func keyCodeToString(_ keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        case kVK_Space: return "Space"
        case kVK_Return: return "Return"
        case kVK_Tab: return "Tab"
        case kVK_Delete: return "Delete"
        case kVK_Escape: return "Escape"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        default: return "?"
        }
    }
}

// MARK: - Global Shortcut Action

/// Actions that can be triggered by global shortcuts
public enum GlobalShortcutAction: String, Codable, CaseIterable, Sendable {
    case activateApp = "activate_app"
    case showQuickAsk = "show_quick_ask"
    case showCommandPalette = "show_command_palette"
    case newSession = "new_session"

    public var displayName: String {
        switch self {
        case .activateApp: return "Activate Claude Desktop"
        case .showQuickAsk: return "Quick Ask"
        case .showCommandPalette: return "Command Palette"
        case .newSession: return "New Session"
        }
    }

    public var description: String {
        switch self {
        case .activateApp: return "Bring Claude Desktop to front"
        case .showQuickAsk: return "Open Quick Ask window"
        case .showCommandPalette: return "Open command palette"
        case .newSession: return "Create a new session"
        }
    }
}

// MARK: - NSEvent.ModifierFlags Extension

extension NSEvent.ModifierFlags {
    /// Convert to Carbon modifier flags
    var carbonFlags: UInt32 {
        var flags: UInt32 = 0

        if contains(.command) { flags |= UInt32(cmdKey) }
        if contains(.option) { flags |= UInt32(optionKey) }
        if contains(.control) { flags |= UInt32(controlKey) }
        if contains(.shift) { flags |= UInt32(shiftKey) }

        return flags
    }
}

// MARK: - Global Shortcut Manager

/// Manages global keyboard shortcuts
@MainActor
public final class GlobalShortcutManager: ObservableObject {

    // MARK: - Singleton

    public static let shared = GlobalShortcutManager()

    // MARK: - Published Properties

    @Published public var shortcuts: [GlobalShortcut] = []
    @Published public var isAccessibilityGranted: Bool = false

    // MARK: - Private Properties

    private var eventHandler: EventHandlerRef?
    private var hotKeys: [EventHotKeyRef?] = []
    private let signature: OSType = 0x434C4445 // "CLDE"

    // MARK: - Callbacks

    public var onAction: ((GlobalShortcutAction) -> Void)?

    // MARK: - Initialization

    private init() {
        loadShortcuts()
    }

    deinit {
        unregisterAllShortcuts()
    }

    // MARK: - Public Methods

    /// Check and request accessibility permissions
    public func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        isAccessibilityGranted = AXIsProcessTrustedWithOptions(options)

        return isAccessibilityGranted
    }

    /// Register all global shortcuts
    public func registerAllShortcuts() {
        guard checkAccessibilityPermission() else {
            print("Accessibility permission not granted")
            return
        }

        unregisterAllShortcuts()
        setupEventHandler()

        for (index, shortcut) in shortcuts.enumerated() {
            registerHotKey(shortcut, id: UInt32(index))
        }
    }

    /// Unregister all shortcuts
    public func unregisterAllShortcuts() {
        for hotKeyRef in hotKeys {
            if let ref = hotKeyRef {
                UnregisterEventHotKey(ref)
            }
        }
        hotKeys.removeAll()

        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    /// Update a shortcut
    public func updateShortcut(_ id: String, keyCode: UInt32, modifiers: NSEvent.ModifierFlags) {
        guard let index = shortcuts.firstIndex(where: { $0.id == id }) else { return }

        shortcuts[index] = GlobalShortcut(
            id: shortcuts[index].id,
            name: shortcuts[index].name,
            description: shortcuts[index].description,
            keyCode: keyCode,
            modifiers: modifiers,
            action: shortcuts[index].action
        )

        saveShortcuts()
        registerAllShortcuts()
    }

    /// Reset to defaults
    public func resetToDefaults() {
        shortcuts = GlobalShortcutDefaults.all
        saveShortcuts()
        registerAllShortcuts()
    }

    // MARK: - Private Methods

    private func setupEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetEventDispatcherTarget(),
            { (_, event, _) -> OSStatus in
                GlobalShortcutManager.shared.handleHotKeyEvent(event)
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )
    }

    private func registerHotKey(_ shortcut: GlobalShortcut, id: UInt32) {
        var hotKeyID = EventHotKeyID()
        hotKeyID.id = id
        hotKeyID.signature = signature

        var hotKeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr {
            hotKeys.append(hotKeyRef)
        } else {
            print("Failed to register hot key: \(shortcut.name)")
            hotKeys.append(nil)
        }
    }

    private func handleHotKeyEvent(_ event: EventRef?) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr else { return status }

        let index = Int(hotKeyID.id)
        guard index < shortcuts.count else { return OSStatus(paramErr) }

        let shortcut = shortcuts[index]
        executeAction(shortcut.action)

        return noErr
    }

    private func executeAction(_ action: GlobalShortcutAction) {
        DispatchQueue.main.async { [weak self] in
            self?.onAction?(action)
        }
    }

    // MARK: - Persistence

    private func loadShortcuts() {
        if let data = UserDefaults.standard.data(forKey: "GlobalShortcuts"),
           let saved = try? JSONDecoder().decode([GlobalShortcut].self, from: data) {
            shortcuts = saved
        } else {
            shortcuts = GlobalShortcutDefaults.all
        }
    }

    private func saveShortcuts() {
        if let data = try? JSONEncoder().encode(shortcuts) {
            UserDefaults.standard.set(data, forKey: "GlobalShortcuts")
        }
    }
}

// MARK: - Default Shortcuts

public enum GlobalShortcutDefaults {
    /// Default global shortcuts
    public static let all: [GlobalShortcut] = [
        GlobalShortcut(
            id: "activate_app",
            name: "Activate App",
            description: "Bring Claude Desktop to front",
            keyCode: UInt32(kVK_ANSI_C),
            modifiers: [.command, .shift],
            action: .activateApp
        ),
        GlobalShortcut(
            id: "quick_ask",
            name: "Quick Ask",
            description: "Open Quick Ask window",
            keyCode: UInt32(kVK_ANSI_A),
            modifiers: [.command, .shift],
            action: .showQuickAsk
        ),
        GlobalShortcut(
            id: "command_palette",
            name: "Command Palette",
            description: "Open command palette",
            keyCode: UInt32(kVK_ANSI_P),
            modifiers: [.command, .shift],
            action: .showCommandPalette
        ),
        GlobalShortcut(
            id: "new_session",
            name: "New Session",
            description: "Create a new session",
            keyCode: UInt32(kVK_ANSI_N),
            modifiers: [.command, .shift],
            action: .newSession
        )
    ]
}
