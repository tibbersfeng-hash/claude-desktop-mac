// ShortcutStyles.swift
// Claude Desktop Mac - Shortcut Styles
//
// Local style definitions for the Shortcuts module

import SwiftUI

// MARK: - Local Color Definitions for Shortcuts Module

public enum ShortcutColors {
    public static func bgPrimary(scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "1E1E1E") : Color(hex: "FFFFFF")
    }

    public static func bgSecondary(scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "252526") : Color(hex: "F3F3F3")
    }

    public static func bgTertiary(scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "2D2D30") : Color(hex: "EBEBEB")
    }

    public static func bgHover(scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "404040") : Color(hex: "E8E8E8")
    }

    public static func fgPrimary(scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "CCCCCC") : Color(hex: "333333")
    }

    public static func fgSecondary(scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "9D9D9D") : Color(hex: "666666")
    }

    public static func fgTertiary(scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "6B6B6B") : Color(hex: "999999")
    }

    public static func fgInverse(scheme: ColorScheme) -> Color {
        Color(hex: "FFFFFF")
    }

    public static let accentPrimary = Color(hex: "0A84FF")
}

// MARK: - Local Style Types

public enum ShortcutStyles {
    public enum Spacing: CGFloat {
        case xs = 4
        case sm = 8
        case md = 12
        case lg = 16
    }

    public enum CornerRadius: CGFloat {
        case sm = 4
        case md = 8
        case lg = 12
    }

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

        public static let sm = AppShadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
        public static let md = AppShadow(color: Color.black.opacity(0.15), radius: 8, y: 4)
        public static let lg = AppShadow(color: Color.black.opacity(0.2), radius: 16, y: 8)
    }
}

// MARK: - Button Styles

public enum ShortcutButtonStyles {
    public struct Secondary: ButtonStyle {
        @Environment(\.colorScheme) var colorScheme

        public func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ShortcutColors.fgPrimary(scheme: colorScheme))
                .padding(.horizontal, ShortcutStyles.Spacing.lg.rawValue)
                .padding(.vertical, ShortcutStyles.Spacing.sm.rawValue)
                .background(ShortcutColors.bgTertiary(scheme: colorScheme))
                .cornerRadius(ShortcutStyles.CornerRadius.md.rawValue)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
        }
    }

    public struct Icon: ButtonStyle {
        @Environment(\.colorScheme) var colorScheme
        let size: CGFloat

        public init(size: CGFloat = 28) {
            self.size = size
        }

        public func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .frame(width: size, height: size)
                .background(configuration.isPressed ? ShortcutColors.bgHover(scheme: colorScheme) : Color.clear)
                .cornerRadius(ShortcutStyles.CornerRadius.sm.rawValue)
        }
    }
}

extension ButtonStyle where Self == ShortcutButtonStyles.Secondary {
    public static var secondary: ShortcutButtonStyles.Secondary { ShortcutButtonStyles.Secondary() }
}

extension ButtonStyle where Self == ShortcutButtonStyles.Icon {
    public static var icon: ShortcutButtonStyles.Icon { ShortcutButtonStyles.Icon() }
    public static func icon(size: CGFloat) -> ShortcutButtonStyles.Icon { ShortcutButtonStyles.Icon(size: size) }
}

// MARK: - Color Hex Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extension for Shadow

extension View {
    public func shadow(_ shadow: ShortcutStyles.AppShadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
