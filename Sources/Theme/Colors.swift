// Colors.swift
// Claude Desktop Mac - Theme Colors
//
// Color definitions for light and dark themes

import SwiftUI

// MARK: - Color Extensions

extension Color {
    // MARK: - Dark Theme Background Colors

    /// Main window background - #1E1E1E
    public static let bgPrimaryDark = Color(hex: "1E1E1E")

    /// Sidebar, panels - #252526
    public static let bgSecondaryDark = Color(hex: "252526")

    /// Cards, elevated surfaces - #2D2D30
    public static let bgTertiaryDark = Color(hex: "2D2D30")

    /// Dropdowns, popovers - #3C3C3C
    public static let bgElevatedDark = Color(hex: "3C3C3C")

    /// Hover state overlay - #404040
    public static let bgHoverDark = Color(hex: "404040")

    /// Selection highlight - #094771
    public static let bgSelectedDark = Color(hex: "094771")

    // MARK: - Light Theme Background Colors

    /// Main window background - #FFFFFF
    public static let bgPrimaryLight = Color(hex: "FFFFFF")

    /// Sidebar, panels - #F3F3F3
    public static let bgSecondaryLight = Color(hex: "F3F3F3")

    /// Cards, elevated surfaces - #EBEBEB
    public static let bgTertiaryLight = Color(hex: "EBEBEB")

    /// Dropdowns, popovers - #FAFAFA
    public static let bgElevatedLight = Color(hex: "FAFAFA")

    /// Hover state overlay - #E8E8E8
    public static let bgHoverLight = Color(hex: "E8E8E8")

    /// Selection highlight - #0078D4
    public static let bgSelectedLight = Color(hex: "0078D4")

    // MARK: - Dark Theme Foreground Colors

    /// Primary text - #CCCCCC
    public static let fgPrimaryDark = Color(hex: "CCCCCC")

    /// Secondary text, labels - #9D9D9D
    public static let fgSecondaryDark = Color(hex: "9D9D9D")

    /// Disabled text, hints - #6B6B6B
    public static let fgTertiaryDark = Color(hex: "6B6B6B")

    /// Text on accent color - #FFFFFF
    public static let fgInverseDark = Color(hex: "FFFFFF")

    // MARK: - Light Theme Foreground Colors

    /// Primary text - #333333
    public static let fgPrimaryLight = Color(hex: "333333")

    /// Secondary text, labels - #666666
    public static let fgSecondaryLight = Color(hex: "666666")

    /// Disabled text, hints - #999999
    public static let fgTertiaryLight = Color(hex: "999999")

    /// Text on accent color - #FFFFFF
    public static let fgInverseLight = Color(hex: "FFFFFF")

    // MARK: - Accent Colors (Shared)

    /// Primary actions, links - macOS system blue #0A84FF
    public static let accentPrimary = Color(hex: "0A84FF")

    /// Success states, connected - #30D158
    public static let accentSuccess = Color(hex: "30D158")

    /// Warning states - #FFD60A
    public static let accentWarning = Color(hex: "FFD60A")

    /// Error states, disconnected - #FF453A
    public static let accentError = Color(hex: "FF453A")

    /// AI/Assistant elements - #BF5AF2
    public static let accentPurple = Color(hex: "BF5AF2")

    /// Reconnecting status - #FF9F0A
    public static let accentOrange = Color(hex: "FF9F0A")

    // MARK: - Code Syntax Colors (Dark Theme)

    /// Code block background - #1A1A1A
    public static let codeBgDark = Color(hex: "1A1A1A")

    /// Keywords - #FC5FA3
    public static let codeKeyword = Color(hex: "FC5FA3")

    /// Strings - #FC6A5D
    public static let codeString = Color(hex: "FC6A5D")

    /// Comments - #73C991
    public static let codeComment = Color(hex: "73C991")

    /// Functions - #67B7A4
    public static let codeFunction = Color(hex: "67B7A4")

    /// Variables - #9CDCFE
    public static let codeVariable = Color(hex: "9CDCFE")

    /// Numbers - #B4CECF
    public static let codeNumber = Color(hex: "B4CECF")

    // MARK: - Diff Colors

    /// Deletion background - #3D1F1E
    public static let diffDeletionBg = Color(hex: "3D1F1E")

    /// Deletion text - #FF6B6B
    public static let diffDeletionFg = Color(hex: "FF6B6B")

    /// Addition background - #1E3D26
    public static let diffAdditionBg = Color(hex: "1E3D26")

    /// Addition text - #6BCB77
    public static let diffAdditionFg = Color(hex: "6BCB77")

    /// Modification background - #3D3A1E
    public static let diffModificationBg = Color(hex: "3D3A1E")

    /// Modification text - #FFD93D
    public static let diffModificationFg = Color(hex: "FFD93D")

    // MARK: - Connection Status Colors

    /// Disconnected status - Red
    public static let statusDisconnected = Color(hex: "FF453A")

    /// Connecting status - Yellow
    public static let statusConnecting = Color(hex: "FFD60A")

    /// Connected status - Green
    public static let statusConnected = Color(hex: "30D158")

    /// Reconnecting status - Orange
    public static let statusReconnecting = Color(hex: "FF9F0A")

    /// Error status - Red
    public static let statusError = Color(hex: "FF453A")

    // MARK: - Tool Icon Colors

    /// Read tool - Blue
    public static let toolRead = Color.blue

    /// Write tool - Green
    public static let toolWrite = Color.green

    /// Edit tool - Orange
    public static let toolEdit = Color.orange

    /// Bash tool - Gray
    public static let toolBash = Color.gray

    /// Glob tool - Purple
    public static let toolGlob = Color.purple

    /// Grep tool - Teal
    public static let toolGrep = Color(hex: "00BFA5")

    // MARK: - High Contrast Colors

    /// High contrast background - Pure black
    public static let bgPrimaryHighContrast = Color(hex: "000000")

    /// High contrast secondary background
    public static let bgSecondaryHighContrast = Color(hex: "0A0A0A")

    /// High contrast tertiary background
    public static let bgTertiaryHighContrast = Color(hex: "1A1A1A")

    /// High contrast elevated background
    public static let bgElevatedHighContrast = Color(hex: "2A2A2A")

    /// High contrast primary foreground - Pure white
    public static let fgPrimaryHighContrast = Color(hex: "FFFFFF")

    /// High contrast secondary foreground
    public static let fgSecondaryHighContrast = Color(hex: "E0E0E0")

    /// High contrast tertiary foreground
    public static let fgTertiaryHighContrast = Color(hex: "B0B0B0")

    /// High contrast primary accent - Brighter blue
    public static let accentPrimaryHighContrast = Color(hex: "3D9FFF")

    /// High contrast success - Brighter green
    public static let accentSuccessHighContrast = Color(hex: "50E878")

    /// High contrast warning - Brighter yellow
    public static let accentWarningHighContrast = Color(hex: "FFE03D")

    /// High contrast error - Brighter red
    public static let accentErrorHighContrast = Color(hex: "FF6B6B")

    /// High contrast purple - Brighter purple
    public static let accentPurpleHighContrast = Color(hex: "D07AFF")

    /// High contrast orange - Brighter orange
    public static let accentOrangeHighContrast = Color(hex: "FFB84D")

    /// High contrast diff addition foreground
    public static let diffAdditionFgHighContrast = Color(hex: "50FF80")

    /// High contrast diff addition background
    public static let diffAdditionBgHighContrast = Color(hex: "0A2A10")

    /// High contrast diff deletion foreground
    public static let diffDeletionFgHighContrast = Color(hex: "FF8080")

    /// High contrast diff deletion background
    public static let diffDeletionBgHighContrast = Color(hex: "2A0A0A")
}

// MARK: - Color Hex Initializer

extension Color {
    public init(hex: String) {
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

// MARK: - Semantic Colors

extension Color {
    /// Check if high contrast mode is enabled
    public static var isHighContrast: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
    }

    /// Semantic background color based on color scheme
    public static func bgPrimary(scheme: ColorScheme) -> Color {
        if isHighContrast {
            return scheme == .dark ? .bgPrimaryHighContrast : .bgPrimaryLight
        }
        return scheme == .dark ? .bgPrimaryDark : .bgPrimaryLight
    }

    public static func bgSecondary(scheme: ColorScheme) -> Color {
        if isHighContrast {
            return scheme == .dark ? .bgSecondaryHighContrast : .bgSecondaryLight
        }
        return scheme == .dark ? .bgSecondaryDark : .bgSecondaryLight
    }

    public static func bgTertiary(scheme: ColorScheme) -> Color {
        if isHighContrast {
            return scheme == .dark ? .bgTertiaryHighContrast : .bgTertiaryLight
        }
        return scheme == .dark ? .bgTertiaryDark : .bgTertiaryLight
    }

    public static func bgElevated(scheme: ColorScheme) -> Color {
        if isHighContrast {
            return scheme == .dark ? .bgElevatedHighContrast : .bgElevatedLight
        }
        return scheme == .dark ? .bgElevatedDark : .bgElevatedLight
    }

    public static func bgHover(scheme: ColorScheme) -> Color {
        if isHighContrast {
            return scheme == .dark ? .bgElevatedHighContrast : .bgHoverLight
        }
        return scheme == .dark ? .bgHoverDark : .bgHoverLight
    }

    public static func bgSelected(scheme: ColorScheme) -> Color {
        if isHighContrast {
            return scheme == .dark ? .accentPrimaryHighContrast.opacity(0.3) : .bgSelectedLight
        }
        return scheme == .dark ? .bgSelectedDark : .bgSelectedLight
    }

    /// Semantic foreground color based on color scheme
    public static func fgPrimary(scheme: ColorScheme) -> Color {
        if isHighContrast {
            return scheme == .dark ? .fgPrimaryHighContrast : .fgPrimaryLight
        }
        return scheme == .dark ? .fgPrimaryDark : .fgPrimaryLight
    }

    public static func fgSecondary(scheme: ColorScheme) -> Color {
        if isHighContrast {
            return scheme == .dark ? .fgSecondaryHighContrast : .fgSecondaryLight
        }
        return scheme == .dark ? .fgSecondaryDark : .fgSecondaryLight
    }

    public static func fgTertiary(scheme: ColorScheme) -> Color {
        if isHighContrast {
            return scheme == .dark ? .fgTertiaryHighContrast : .fgTertiaryLight
        }
        return scheme == .dark ? .fgTertiaryDark : .fgTertiaryLight
    }

    public static func fgInverse(scheme: ColorScheme) -> Color {
        scheme == .dark ? .fgInverseDark : .fgInverseLight
    }

    /// Code background based on color scheme
    public static func codeBg(scheme: ColorScheme) -> Color {
        if isHighContrast {
            return scheme == .dark ? .bgPrimaryHighContrast : .bgTertiaryLight
        }
        return scheme == .dark ? .codeBgDark : .bgTertiaryLight
    }

    /// Diff addition foreground with high contrast support
    public static func diffAdditionFgAccessible() -> Color {
        isHighContrast ? .diffAdditionFgHighContrast : .diffAdditionFg
    }

    /// Diff addition background with high contrast support
    public static func diffAdditionBgAccessible() -> Color {
        isHighContrast ? .diffAdditionBgHighContrast : .diffAdditionBg
    }

    /// Diff deletion foreground with high contrast support
    public static func diffDeletionFgAccessible() -> Color {
        isHighContrast ? .diffDeletionFgHighContrast : .diffDeletionFg
    }

    /// Diff deletion background with high contrast support
    public static func diffDeletionBgAccessible() -> Color {
        isHighContrast ? .diffDeletionBgHighContrast : .diffDeletionBg
    }

    /// Accent primary with high contrast support
    public static func accentPrimaryAccessible() -> Color {
        isHighContrast ? .accentPrimaryHighContrast : .accentPrimary
    }

    /// Accent success with high contrast support
    public static func accentSuccessAccessible() -> Color {
        isHighContrast ? .accentSuccessHighContrast : .accentSuccess
    }

    /// Accent warning with high contrast support
    public static func accentWarningAccessible() -> Color {
        isHighContrast ? .accentWarningHighContrast : .accentWarning
    }

    /// Accent error with high contrast support
    public static func accentErrorAccessible() -> Color {
        isHighContrast ? .accentErrorHighContrast : .accentError
    }
}

// MARK: - Theme Manager

@MainActor
@Observable
public final class ThemeManager {
    public static let shared = ThemeManager()

    public var colorScheme: ColorScheme = .dark

    private init() {}

    public func updateColorScheme(_ scheme: ColorScheme) {
        colorScheme = scheme
    }
}
