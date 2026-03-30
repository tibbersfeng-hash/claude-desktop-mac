// Colors.swift
// Claude Desktop Mac - Theme Colors
//
// Color definitions for light and dark themes

import SwiftUI

// MARK: - Color Extensions

extension Color {
    // MARK: - Dark Theme Background Colors

    /// Main window background - #1E1E1E
    static let bgPrimaryDark = Color(hex: "1E1E1E")

    /// Sidebar, panels - #252526
    static let bgSecondaryDark = Color(hex: "252526")

    /// Cards, elevated surfaces - #2D2D30
    static let bgTertiaryDark = Color(hex: "2D2D30")

    /// Dropdowns, popovers - #3C3C3C
    static let bgElevatedDark = Color(hex: "3C3C3C")

    /// Hover state overlay - #404040
    static let bgHoverDark = Color(hex: "404040")

    /// Selection highlight - #094771
    static let bgSelectedDark = Color(hex: "094771")

    // MARK: - Light Theme Background Colors

    /// Main window background - #FFFFFF
    static let bgPrimaryLight = Color(hex: "FFFFFF")

    /// Sidebar, panels - #F3F3F3
    static let bgSecondaryLight = Color(hex: "F3F3F3")

    /// Cards, elevated surfaces - #EBEBEB
    static let bgTertiaryLight = Color(hex: "EBEBEB")

    /// Dropdowns, popovers - #FAFAFA
    static let bgElevatedLight = Color(hex: "FAFAFA")

    /// Hover state overlay - #E8E8E8
    static let bgHoverLight = Color(hex: "E8E8E8")

    /// Selection highlight - #0078D4
    static let bgSelectedLight = Color(hex: "0078D4")

    // MARK: - Dark Theme Foreground Colors

    /// Primary text - #CCCCCC
    static let fgPrimaryDark = Color(hex: "CCCCCC")

    /// Secondary text, labels - #9D9D9D
    static let fgSecondaryDark = Color(hex: "9D9D9D")

    /// Disabled text, hints - #6B6B6B
    static let fgTertiaryDark = Color(hex: "6B6B6B")

    /// Text on accent color - #FFFFFF
    static let fgInverseDark = Color(hex: "FFFFFF")

    // MARK: - Light Theme Foreground Colors

    /// Primary text - #333333
    static let fgPrimaryLight = Color(hex: "333333")

    /// Secondary text, labels - #666666
    static let fgSecondaryLight = Color(hex: "666666")

    /// Disabled text, hints - #999999
    static let fgTertiaryLight = Color(hex: "999999")

    /// Text on accent color - #FFFFFF
    static let fgInverseLight = Color(hex: "FFFFFF")

    // MARK: - Accent Colors (Shared)

    /// Primary actions, links - macOS system blue #0A84FF
    static let accentPrimary = Color(hex: "0A84FF")

    /// Success states, connected - #30D158
    static let accentSuccess = Color(hex: "30D158")

    /// Warning states - #FFD60A
    static let accentWarning = Color(hex: "FFD60A")

    /// Error states, disconnected - #FF453A
    static let accentError = Color(hex: "FF453A")

    /// AI/Assistant elements - #BF5AF2
    static let accentPurple = Color(hex: "BF5AF2")

    /// Reconnecting status - #FF9F0A
    static let accentOrange = Color(hex: "FF9F0A")

    // MARK: - Code Syntax Colors (Dark Theme)

    /// Code block background - #1A1A1A
    static let codeBgDark = Color(hex: "1A1A1A")

    /// Keywords - #FC5FA3
    static let codeKeyword = Color(hex: "FC5FA3")

    /// Strings - #FC6A5D
    static let codeString = Color(hex: "FC6A5D")

    /// Comments - #73C991
    static let codeComment = Color(hex: "73C991")

    /// Functions - #67B7A4
    static let codeFunction = Color(hex: "67B7A4")

    /// Variables - #9CDCFE
    static let codeVariable = Color(hex: "9CDCFE")

    /// Numbers - #B4CECF
    static let codeNumber = Color(hex: "B4CECF")

    // MARK: - Diff Colors

    /// Deletion background - #3D1F1E
    static let diffDeletionBg = Color(hex: "3D1F1E")

    /// Deletion text - #FF6B6B
    static let diffDeletionFg = Color(hex: "FF6B6B")

    /// Addition background - #1E3D26
    static let diffAdditionBg = Color(hex: "1E3D26")

    /// Addition text - #6BCB77
    static let diffAdditionFg = Color(hex: "6BCB77")

    /// Modification background - #3D3A1E
    static let diffModificationBg = Color(hex: "3D3A1E")

    /// Modification text - #FFD93D
    static let diffModificationFg = Color(hex: "FFD93D")

    // MARK: - Connection Status Colors

    /// Disconnected status - Red
    static let statusDisconnected = Color(hex: "FF453A")

    /// Connecting status - Yellow
    static let statusConnecting = Color(hex: "FFD60A")

    /// Connected status - Green
    static let statusConnected = Color(hex: "30D158")

    /// Reconnecting status - Orange
    static let statusReconnecting = Color(hex: "FF9F0A")

    /// Error status - Red
    static let statusError = Color(hex: "FF453A")

    // MARK: - Tool Icon Colors

    /// Read tool - Blue
    static let toolRead = Color.blue

    /// Write tool - Green
    static let toolWrite = Color.green

    /// Edit tool - Orange
    static let toolEdit = Color.orange

    /// Bash tool - Gray
    static let toolBash = Color.gray

    /// Glob tool - Purple
    static let toolGlob = Color.purple

    /// Grep tool - Teal
    static let toolGrep = Color(hex: "00BFA5")

    // MARK: - High Contrast Colors

    /// High contrast background - Pure black
    static let bgPrimaryHighContrast = Color(hex: "000000")

    /// High contrast secondary background
    static let bgSecondaryHighContrast = Color(hex: "0A0A0A")

    /// High contrast tertiary background
    static let bgTertiaryHighContrast = Color(hex: "1A1A1A")

    /// High contrast elevated background
    static let bgElevatedHighContrast = Color(hex: "2A2A2A")

    /// High contrast primary foreground - Pure white
    static let fgPrimaryHighContrast = Color(hex: "FFFFFF")

    /// High contrast secondary foreground
    static let fgSecondaryHighContrast = Color(hex: "E0E0E0")

    /// High contrast tertiary foreground
    static let fgTertiaryHighContrast = Color(hex: "B0B0B0")

    /// High contrast primary accent - Brighter blue
    static let accentPrimaryHighContrast = Color(hex: "3D9FFF")

    /// High contrast success - Brighter green
    static let accentSuccessHighContrast = Color(hex: "50E878")

    /// High contrast warning - Brighter yellow
    static let accentWarningHighContrast = Color(hex: "FFE03D")

    /// High contrast error - Brighter red
    static let accentErrorHighContrast = Color(hex: "FF6B6B")

    /// High contrast purple - Brighter purple
    static let accentPurpleHighContrast = Color(hex: "D07AFF")

    /// High contrast orange - Brighter orange
    static let accentOrangeHighContrast = Color(hex: "FFB84D")

    /// High contrast diff addition foreground
    static let diffAdditionFgHighContrast = Color(hex: "50FF80")

    /// High contrast diff addition background
    static let diffAdditionBgHighContrast = Color(hex: "0A2A10")

    /// High contrast diff deletion foreground
    static let diffDeletionFgHighContrast = Color(hex: "FF8080")

    /// High contrast diff deletion background
    static let diffDeletionBgHighContrast = Color(hex: "2A0A0A")
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

// MARK: - Semantic Colors

extension Color {
    /// Check if high contrast mode is enabled
    private static var isHighContrast: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
    }

    /// Semantic background color based on color scheme
    static func bgPrimary(scheme: ColorScheme) -> Color {
        if isHighContrast {
            return scheme == .dark ? .bgPrimaryHighContrast : .bgPrimaryLight
        }
        return scheme == .dark ? .bgPrimaryDark : .bgPrimaryLight
    }

    static func bgSecondary(scheme: ColorScheme) -> Color {
        if isHighContrast {
            return scheme == .dark ? .bgSecondaryHighContrast : .bgSecondaryLight
        }
        return scheme == .dark ? .bgSecondaryDark : .bgSecondaryLight
    }

    static func bgTertiary(scheme: ColorScheme) -> Color {
        if isHighContrast {
            return scheme == .dark ? .bgTertiaryHighContrast : .bgTertiaryLight
        }
        return scheme == .dark ? .bgTertiaryDark : .bgTertiaryLight
    }

    static func bgElevated(scheme: ColorScheme) -> Color {
        if isHighContrast {
            return scheme == .dark ? .bgElevatedHighContrast : .bgElevatedLight
        }
        return scheme == .dark ? .bgElevatedDark : .bgElevatedLight
    }

    static func bgHover(scheme: ColorScheme) -> Color {
        if isHighContrast {
            return scheme == .dark ? .bgElevatedHighContrast : .bgHoverLight
        }
        return scheme == .dark ? .bgHoverDark : .bgHoverLight
    }

    static func bgSelected(scheme: ColorScheme) -> Color {
        if isHighContrast {
            return scheme == .dark ? .accentPrimaryHighContrast.opacity(0.3) : .bgSelectedLight
        }
        return scheme == .dark ? .bgSelectedDark : .bgSelectedLight
    }

    /// Semantic foreground color based on color scheme
    static func fgPrimary(scheme: ColorScheme) -> Color {
        if isHighContrast {
            return scheme == .dark ? .fgPrimaryHighContrast : .fgPrimaryLight
        }
        return scheme == .dark ? .fgPrimaryDark : .fgPrimaryLight
    }

    static func fgSecondary(scheme: ColorScheme) -> Color {
        if isHighContrast {
            return scheme == .dark ? .fgSecondaryHighContrast : .fgSecondaryLight
        }
        return scheme == .dark ? .fgSecondaryDark : .fgSecondaryLight
    }

    static func fgTertiary(scheme: ColorScheme) -> Color {
        if isHighContrast {
            return scheme == .dark ? .fgTertiaryHighContrast : .fgTertiaryLight
        }
        return scheme == .dark ? .fgTertiaryDark : .fgTertiaryLight
    }

    static func fgInverse(scheme: ColorScheme) -> Color {
        scheme == .dark ? .fgInverseDark : .fgInverseLight
    }

    /// Code background based on color scheme
    static func codeBg(scheme: ColorScheme) -> Color {
        if isHighContrast {
            return scheme == .dark ? .bgPrimaryHighContrast : .bgTertiaryLight
        }
        return scheme == .dark ? .codeBgDark : .bgTertiaryLight
    }

    /// Diff addition foreground with high contrast support
    static func diffAdditionFgAccessible() -> Color {
        isHighContrast ? .diffAdditionFgHighContrast : .diffAdditionFg
    }

    /// Diff addition background with high contrast support
    static func diffAdditionBgAccessible() -> Color {
        isHighContrast ? .diffAdditionBgHighContrast : .diffAdditionBg
    }

    /// Diff deletion foreground with high contrast support
    static func diffDeletionFgAccessible() -> Color {
        isHighContrast ? .diffDeletionFgHighContrast : .diffDeletionFg
    }

    /// Diff deletion background with high contrast support
    static func diffDeletionBgAccessible() -> Color {
        isHighContrast ? .diffDeletionBgHighContrast : .diffDeletionBg
    }

    /// Accent primary with high contrast support
    static func accentPrimaryAccessible() -> Color {
        isHighContrast ? .accentPrimaryHighContrast : .accentPrimary
    }

    /// Accent success with high contrast support
    static func accentSuccessAccessible() -> Color {
        isHighContrast ? .accentSuccessHighContrast : .accentSuccess
    }

    /// Accent warning with high contrast support
    static func accentWarningAccessible() -> Color {
        isHighContrast ? .accentWarningHighContrast : .accentWarning
    }

    /// Accent error with high contrast support
    static func accentErrorAccessible() -> Color {
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
