// Styles.swift
// Claude Desktop Mac - Component Styles
//
// Reusable style definitions for UI components

import SwiftUI

// MARK: - Spacing Scale

public enum Spacing: CGFloat {
    case xs = 4
    case sm = 8
    case md = 12
    case lg = 16
    case xl = 24
    case xxl = 32
}

// MARK: - Border Radius

public enum CornerRadius: CGFloat {
    case sm = 4
    case md = 8
    case lg = 12
    case xl = 16
    case full = 9999
}

// MARK: - Shadows

public struct AppShadow {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat

    public init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

extension AppShadow {
    /// Subtle elevation
    public static let sm = AppShadow(
        color: Color.black.opacity(0.1),
        radius: 2,
        y: 1
    )

    /// Cards
    public static let md = AppShadow(
        color: Color.black.opacity(0.15),
        radius: 8,
        y: 4
    )

    /// Modals, popovers
    public static let lg = AppShadow(
        color: Color.black.opacity(0.2),
        radius: 16,
        y: 8
    )
}

// MARK: - Animation Durations

public enum AnimationDuration: Double {
    case fast = 0.1
    case normal = 0.2
    case slow = 0.3
    case verySlow = 0.5
}

// MARK: - View Extensions for Styles

extension View {
    /// Apply card style
    public func cardStyle(scheme: ColorScheme) -> some View {
        self
            .background(Color.bgTertiary(scheme: scheme))
            .cornerRadius(CornerRadius.lg.rawValue)
            .shadow(AppShadow.md)
    }

    /// Apply hover style
    public func hoverStyle(scheme: ColorScheme, isHovered: Bool) -> some View {
        self
            .background(isHovered ? Color.bgHover(scheme: scheme) : Color.clear)
            .animation(.easeInOut(duration: AnimationDuration.fast.rawValue), value: isHovered)
    }

    /// Apply selection style
    public func selectionStyle(scheme: ColorScheme, isSelected: Bool) -> some View {
        self
            .background(isSelected ? Color.bgSelected(scheme: scheme) : Color.clear)
            .animation(.easeInOut(duration: AnimationDuration.fast.rawValue), value: isSelected)
    }

    /// Apply border style
    public func borderStyle(scheme: ColorScheme, isFocused: Bool = false) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md.rawValue)
                    .stroke(
                        isFocused ? Color.accentPrimary : Color.fgTertiary(scheme: scheme),
                        lineWidth: 1
                    )
            )
    }

    /// Apply input field style
    public func inputStyle(scheme: ColorScheme, isFocused: Bool = false) -> some View {
        self
            .padding(Spacing.md.rawValue)
            .background(Color.bgTertiary(scheme: scheme))
            .cornerRadius(CornerRadius.lg.rawValue)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg.rawValue)
                    .stroke(
                        isFocused ? Color.accentPrimary : Color.fgTertiary(scheme: scheme).opacity(0.3),
                        lineWidth: isFocused ? 2 : 1
                    )
            )
    }

    /// Apply message bubble style
    public func messageBubbleStyle(isUser: Bool, scheme: ColorScheme) -> some View {
        self
            .padding(.horizontal, Spacing.lg.rawValue)
            .padding(.vertical, Spacing.md.rawValue)
            .background(isUser ? Color.bgTertiary(scheme: scheme) : Color.clear)
            .cornerRadius(CornerRadius.lg.rawValue)
    }

    /// Apply code block style
    public func codeBlockStyle(scheme: ColorScheme) -> some View {
        self
            .font(.codeBlock)
            .padding(Spacing.md.rawValue)
            .background(Color.codeBg(scheme: scheme))
            .cornerRadius(CornerRadius.md.rawValue)
    }

    /// Apply tool call card style
    public func toolCallCardStyle(scheme: ColorScheme) -> some View {
        self
            .padding(Spacing.md.rawValue)
            .background(Color.bgSecondary(scheme: scheme))
            .cornerRadius(CornerRadius.md.rawValue)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md.rawValue)
                    .stroke(Color.fgTertiary(scheme: scheme).opacity(0.3), lineWidth: 1)
            )
    }

    /// Apply status badge style
    public func statusBadgeStyle(color: Color) -> some View {
        self
            .padding(.horizontal, Spacing.sm.rawValue)
            .padding(.vertical, Spacing.xs.rawValue)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(CornerRadius.full.rawValue)
    }

    /// Apply sidebar item style
    public func sidebarItemStyle(isSelected: Bool, isHovered: Bool, scheme: ColorScheme) -> some View {
        self
            .padding(.horizontal, Spacing.md.rawValue)
            .padding(.vertical, Spacing.sm.rawValue)
            .background(
                Group {
                    if isSelected {
                        Color.bgSelected(scheme: scheme)
                    } else if isHovered {
                        Color.bgHover(scheme: scheme)
                    } else {
                        Color.clear
                    }
                }
            )
            .cornerRadius(CornerRadius.md.rawValue)
    }
}

// MARK: - Button Styles

public struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.lg.rawValue)
            .padding(.vertical, Spacing.sm.rawValue)
            .background(Color.accentPrimary)
            .cornerRadius(CornerRadius.md.rawValue)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: AnimationDuration.fast.rawValue), value: configuration.isPressed)
    }
}

public struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(Color.fgPrimary(scheme: colorScheme))
            .padding(.horizontal, Spacing.lg.rawValue)
            .padding(.vertical, Spacing.sm.rawValue)
            .background(Color.bgTertiary(scheme: colorScheme))
            .cornerRadius(CornerRadius.md.rawValue)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: AnimationDuration.fast.rawValue), value: configuration.isPressed)
    }
}

public struct IconButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    let size: CGFloat

    public init(size: CGFloat = 28) {
        self.size = size
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(configuration.isPressed ? Color.bgHover(scheme: colorScheme) : Color.clear)
            .cornerRadius(CornerRadius.sm.rawValue)
            .animation(.easeInOut(duration: AnimationDuration.fast.rawValue), value: configuration.isPressed)
    }
}

// MARK: - Button Style Extensions

extension ButtonStyle where Self == PrimaryButtonStyle {
    public static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    public static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

extension ButtonStyle where Self == IconButtonStyle {
    public static var icon: IconButtonStyle { IconButtonStyle() }
    public static func icon(size: CGFloat) -> IconButtonStyle { IconButtonStyle(size: size) }
}

// MARK: - View Modifiers

struct PaddingModifier: ViewModifier {
    let padding: Spacing

    func body(content: Content) -> some View {
        content.padding(padding.rawValue)
    }
}

extension View {
    public func appPadding(_ padding: Spacing) -> some View {
        modifier(PaddingModifier(padding: padding))
    }
}

// MARK: - Window Dimensions

public enum WindowDimensions {
    public static let minWidth: CGFloat = 800
    public static let minHeight: CGFloat = 600
    public static let defaultWidth: CGFloat = 1200
    public static let defaultHeight: CGFloat = 800
    public static let sidebarWidth: CGFloat = 220
    public static let collapsedSidebarWidth: CGFloat = 48
    public static let statusBarHeight: CGFloat = 24
    public static let inputMinHeight: CGFloat = 80
    public static let inputMaxHeight: CGFloat = 300
}

// MARK: - Animation Extensions

extension Animation {
    public static var appFast: Animation {
        .easeInOut(duration: AnimationDuration.fast.rawValue)
    }

    public static var appNormal: Animation {
        .easeInOut(duration: AnimationDuration.normal.rawValue)
    }

    public static var appSlow: Animation {
        .easeInOut(duration: AnimationDuration.slow.rawValue)
    }

    // MARK: - Accessible Animation Extensions

    /// Normal app animation that respects reduce motion
    public static var appNormalAccessible: Animation {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            return .none
        }
        return .appNormal
    }

    /// Fast app animation that respects reduce motion
    public static var appFastAccessible: Animation {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            return .none
        }
        return .appFast
    }

    /// Slow app animation that respects reduce motion
    public static var appSlowAccessible: Animation {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            return .none
        }
        return .appSlow
    }

    /// Creates an animation that respects reduce motion preference
    public static func accessible(_ animation: Animation) -> Animation {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            return .none
        }
        return animation
    }
}
