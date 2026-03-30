// ScalableTypography.swift
// Claude Desktop Mac - Scalable Typography for Dynamic Type
//
// Dynamic Type support with scalable font styles

import SwiftUI

// MARK: - Scalable Font Styles

public enum ScalableFontStyle: String, CaseIterable {
    case windowTitle
    case sectionHeader
    case cardTitle
    case body
    case secondary
    case code
    case caption
    case timestamp

    /// Base point size for this style
    public var baseSize: CGFloat {
        switch self {
        case .windowTitle: return 22
        case .sectionHeader: return 20
        case .cardTitle: return 17
        case .body: return 15
        case .secondary: return 14
        case .code: return 13
        case .caption: return 12
        case .timestamp: return 11
        }
    }

    /// Font weight for this style
    public var weight: Font.Weight {
        switch self {
        case .windowTitle, .sectionHeader, .cardTitle:
            return .semibold
        case .body, .secondary, .caption, .timestamp:
            return .regular
        case .code:
            return .regular
        }
    }

    /// Font design for this style
    public var design: Font.Design {
        switch self {
        case .code:
            return .monospaced
        default:
            return .default
        }
    }

    /// Maximum scale factor (prevents text from becoming too large)
    public var maxScaleFactor: CGFloat {
        switch self {
        case .windowTitle, .sectionHeader:
            return 1.5 // Limit headings
        case .body, .secondary:
            return 2.0 // Allow body to scale more
        case .caption, .timestamp:
            return 1.8
        case .code:
            return 1.5 // Code should stay readable
        case .cardTitle:
            return 1.5
        }
    }
}

// MARK: - Scalable Font Extension

extension Font {
    /// Creates a scalable font for the given style
    public static func scalable(_ style: ScalableFontStyle) -> Font {
        .system(size: style.baseSize, weight: style.weight, design: style.design)
    }

    // Convenience accessors
    public static var scalableWindowTitle: Font { .scalable(.windowTitle) }
    public static var scalableSectionHeader: Font { .scalable(.sectionHeader) }
    public static var scalableCardTitle: Font { .scalable(.cardTitle) }
    public static var scalableBody: Font { .scalable(.body) }
    public static var scalableSecondary: Font { .scalable(.secondary) }
    public static var scalableCode: Font { .scalable(.code) }
    public static var scalableCaption: Font { .scalable(.caption) }
    public static var scalableTimestamp: Font { .scalable(.timestamp) }
}

// MARK: - View Extension for Dynamic Type

extension View {
    /// Applies dynamic type scaling with constraints
    public func dynamicTypeScaling(
        style: ScalableFontStyle,
        minScale: CGFloat = 0.8,
        maxScale: CGFloat? = nil
    ) -> some View {
        self.modifier(DynamicTypeScalingModifier(
            style: style,
            minScale: minScale,
            maxScale: maxScale ?? style.maxScaleFactor
        ))
    }
}

// MARK: - Dynamic Type Scaling Modifier

public struct DynamicTypeScalingModifier: ViewModifier {
    public let style: ScalableFontStyle
    public let minScale: CGFloat
    public let maxScale: CGFloat

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    public init(style: ScalableFontStyle, minScale: CGFloat, maxScale: CGFloat) {
        self.style = style
        self.minScale = minScale
        self.maxScale = maxScale
    }

    public func body(content: Content) -> some View {
        let scaleFactor = min(maxScale, max(minScale, dynamicTypeSize.scaleFactor(style: style)))

        content
            .font(.system(
                size: style.baseSize * scaleFactor,
                weight: style.weight,
                design: style.design
            ))
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Dynamic Type Size Extension

extension DynamicTypeSize {
    /// Calculate scale factor for a given font style
    public func scaleFactor(style: ScalableFontStyle) -> CGFloat {
        // DynamicTypeSize ranges from .xSmall to .accessibility5
        // Map to scale factors
        let baseScale: CGFloat
        switch self {
        case .xSmall: baseScale = 0.85
        case .small: baseScale = 0.9
        case .medium: baseScale = 1.0
        case .large: baseScale = 1.1
        case .xLarge: baseScale = 1.2
        case .xxLarge: baseScale = 1.3
        case .xxxLarge: baseScale = 1.4
        case .accessibility1: baseScale = 1.6
        case .accessibility2: baseScale = 1.8
        case .accessibility3: baseScale = 2.0
        case .accessibility4: baseScale = 2.2
        case .accessibility5: baseScale = 2.4
        @unknown default: baseScale = 1.0
        }

        return min(baseScale, style.maxScaleFactor)
    }
}

// MARK: - Dynamic Spacing Modifier

public struct DynamicSpacingModifier: ViewModifier {
    public let baseSpacing: Spacing
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    public init(baseSpacing: Spacing) {
        self.baseSpacing = baseSpacing
    }

    public func body(content: Content) -> some View {
        let scaleFactor = dynamicTypeSize.scaleFactor(style: .body)
        let scaledSpacing = baseSpacing.rawValue * max(1.0, scaleFactor - 0.5)

        content
            .padding(.all, scaledSpacing)
    }
}

extension View {
    /// Applies dynamic padding based on Dynamic Type size
    public func dynamicPadding(_ spacing: Spacing) -> some View {
        self.modifier(DynamicSpacingModifier(baseSpacing: spacing))
    }
}

// MARK: - Scaled Dimensions Helper

public struct ScaledDimensions {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    /// Calculate scaled max width for message bubbles
    public func scaledMessageMaxWidth(baseWidth: CGFloat = 600) -> CGFloat {
        let scaleFactor = dynamicTypeSize.scaleFactor(style: .body)
        // Increase max width for larger text
        return baseWidth * max(1.0, scaleFactor - 0.3)
    }

    /// Calculate scaled input height
    public func scaledInputHeight(baseHeight: CGFloat) -> CGFloat {
        let scaleFactor = dynamicTypeSize.scaleFactor(style: .body)
        return baseHeight * max(1.0, scaleFactor - 0.5)
    }
}
