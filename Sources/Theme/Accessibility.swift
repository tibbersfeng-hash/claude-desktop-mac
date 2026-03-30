// Accessibility.swift
// Claude Desktop Mac - Accessibility Helpers
//
// VoiceOver labels, hints, traits, and accessibility modifiers

import SwiftUI

// MARK: - Tool Status Accessibility

extension ToolCallDisplayStatus {
    /// Accessibility description for VoiceOver
    public var accessibilityDescription: String {
        switch self {
        case .pending:
            return "pending"
        case .running:
            return "currently running"
        case .success:
            return "completed successfully"
        case .error:
            return "failed with error"
        }
    }
}

// MARK: - Diff Line Type Accessibility

extension DiffLineType {
    /// Accessibility description for VoiceOver
    public var accessibilityDescription: String {
        switch self {
        case .addition:
            return "Added line"
        case .deletion:
            return "Deleted line"
        case .context:
            return "Context line"
        }
    }

    /// Accessibility hint for VoiceOver
    public var accessibilityHint: String {
        switch self {
        case .addition:
            return "This line was added"
        case .deletion:
            return "This line was removed"
        case .context:
            return "Unchanged line"
        }
    }
}

// MARK: - Accessibility Trait Helpers

extension View {
    /// Applies accessibility traits based on selection state
    public func accessibilitySelectable(isSelected: Bool) -> some View {
        self.accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Applies accessibility label with hint combination
    public func accessibilityLabeled(label: String, hint: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint)
    }

    /// Makes the view a combined accessibility element with label and hint
    public func accessibilityElementCombined(label: String, hint: String? = nil) -> some View {
        var result = self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)

        if let hint = hint {
            result = result.accessibilityHint(hint)
        }

        return result
    }
}

// MARK: - Reduce Motion Support

/// Environment key for reduce motion preference
public struct ReduceMotionKey: EnvironmentKey {
    public static let defaultValue: Bool = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
}

extension EnvironmentValues {
    public var reduceMotion: Bool {
        get { self[ReduceMotionKey.self] }
        set { self[ReduceMotionKey.self] = newValue }
    }
}

// MARK: - High Contrast Support

/// Environment key for high contrast preference
public struct HighContrastKey: EnvironmentKey {
    public static let defaultValue: Bool = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
}

extension EnvironmentValues {
    public var highContrast: Bool {
        get { self[HighContrastKey.self] }
        set { self[HighContrastKey.self] = newValue }
    }
}

// MARK: - Accessible Animation Modifier

/// Animation modifier that respects reduce motion preference
public struct AccessibleAnimationModifier: ViewModifier {
    let animation: Animation?
    @Environment(\.reduceMotion) var reduceMotion

    public func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.animation(animation)
        }
    }
}

extension View {
    /// Applies animation that respects reduce motion preference
    public func accessibleAnimation(_ animation: Animation?) -> some View {
        self.modifier(AccessibleAnimationModifier(animation: animation))
    }
}

// MARK: - Accessible withAnimation Helper

/// Performs animation respecting reduce motion preference
public func withAccessibleAnimation<Result>(
    _ animation: Animation? = .default,
    _ body: () throws -> Result
) rethrows -> Result {
    if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
        return try body()
    } else {
        return try withAnimation(animation, body)
    }
}

// MARK: - Alternative Transition Effects

extension AnyTransition {
    /// Fade-only transition for reduce motion users
    public static var accessibleFade: AnyTransition {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            return .opacity
        } else {
            return .opacity.combined(with: .scale(scale: 0.95))
        }
    }

    /// Accessible slide transition
    public static func accessibleSlide(edge: Edge) -> AnyTransition {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            return .opacity
        } else {
            return .slide(edge: edge).combined(with: .opacity)
        }
    }

    /// Accessible move transition
    public static func accessibleMove(edge: Edge) -> AnyTransition {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            return .opacity
        } else {
            return .move(edge: edge)
        }
    }
}

// MARK: - Accessible Button Style

/// Button style with accessibility enhancements
public struct AccessibleButtonStyle: ButtonStyle {
    @Environment(\.reduceMotion) var reduceMotion

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .accessibleAnimation(reduceMotion ? nil : .easeInOut(duration: AnimationDuration.fast.rawValue))
    }
}

extension ButtonStyle where Self == AccessibleButtonStyle {
    public static var accessible: AccessibleButtonStyle { AccessibleButtonStyle() }
}

// MARK: - Accessibility Preview Helpers

#if DEBUG
/// Preview wrapper that simulates accessibility settings
public struct AccessibilityPreview<Content: View>: View {
    let reduceMotion: Bool
    let highContrast: Bool
    let content: Content

    public init(
        reduceMotion: Bool = false,
        highContrast: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.reduceMotion = reduceMotion
        self.highContrast = highContrast
        self.content = content()
    }

    public var body: some View {
        content
            .environment(\.reduceMotion, reduceMotion)
            .environment(\.highContrast, highContrast)
    }
}
#endif
