# Claude Desktop Mac - Accessibility Fix Design Document

> Version: 1.0
> Date: 2026-03-30
> Author: Product Manager Agent
> Status: Design Complete

---

## Executive Summary

This document outlines the design for implementing accessibility features required before release. Based on the UI Final Review Report (score: 93.8/100), the application is missing critical accessibility support that must be addressed for App Store compliance and user inclusivity.

### Scope

| Priority | Feature | Status |
|----------|---------|--------|
| P0 | VoiceOver Labels | NOT IMPLEMENTED |
| P0 | Dynamic Type Support | NOT IMPLEMENTED |
| P0 | High Contrast Mode | NOT IMPLEMENTED |
| P1 | Reduce Motion Support | NOT IMPLEMENTED |

---

## 1. VoiceOver Labels Implementation

### 1.1 Overview

VoiceOver is Apple's screen reader technology. All interactive elements and important content must have proper accessibility labels, hints, and traits for VoiceOver users.

### 1.2 Implementation Details

#### 1.2.1 Session Item (SidebarView.swift)

**Current State:** Session rows have no accessibility labels.

**Fix:**

```swift
// SessionRowView
HStack(spacing: Spacing.sm.rawValue) {
    // ... existing content
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(session.title), \(session.projectName ?? "no project"), \(session.relativeTime)")
.accessibilityHint("Double tap to open session")
.accessibilityAddTraits(.isButton)
.accessibilityAddTraits(isSelected ? .isSelected : [])
```

**Collapsed Session Row:**

```swift
// CollapsedSessionRow
VStack(spacing: Spacing.xs.rawValue) {
    // ... existing content
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(session.title)")
.accessibilityHint("Double tap to open session")
.accessibilityAddTraits(.isButton)
.accessibilityAddTraits(isSelected ? .isSelected : [])
```

#### 1.2.2 Message Bubble (MessageView.swift)

**Current State:** Message content has no accessibility structure.

**Fix:**

```swift
// UserMessageContent
VStack(alignment: .trailing, spacing: Spacing.sm.rawValue) {
    // ... existing content
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Your message: \(content)")
.accessibilityHint("Sent at \(timestamp)")

// AssistantMessageContent
VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
    // ... existing content
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Claude's response: \(content)")
.accessibilityHint("Sent at \(timestamp)")
```

**Tool Calls in Message:**

```swift
// ToolCallView
VStack(alignment: .leading, spacing: 0) {
    // ... existing content
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(toolCall.displayName) tool call, \(toolCall.status.accessibilityDescription)")
.accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand") details")
.accessibilityAddTraits(.isButton)
```

#### 1.2.3 Send Button (InputView.swift)

**Current State:** Send button uses only SF Symbol with `.help()` modifier.

**Fix:**

```swift
// Send button
Button(action: onSend) {
    Image(systemName: "paperplane.fill")
        .font(.system(size: 14))
        .foregroundColor(.white)
}
.buttonStyle(.primary)
.disabled(!inputState.canSend || connectionState != .connected)
.accessibilityLabel("Send message")
.accessibilityHint("Double tap to send your message")
.accessibilityAddTraits(inputState.canSend ? [] : .notEnabled)

// Stop button
Button(action: onInterrupt) {
    Image(systemName: "stop.fill")
        .font(.system(size: 14))
        .foregroundColor(.white)
}
.buttonStyle(.primary)
.accessibilityLabel("Stop response")
.accessibilityHint("Double tap to interrupt Claude's response")
```

#### 1.2.4 Diff Lines (DiffView.swift)

**Current State:** Diff lines have no accessibility information.

**Fix:**

```swift
// UnifiedDiffLineView
HStack(alignment: .top, spacing: 0) {
    // ... existing content
}
.accessibilityElement(children: .combine)
.accessibilityLabel(diffLineAccessibilityLabel)
.accessibilityHint(diffLineAccessibilityHint)

private var diffLineAccessibilityLabel: String {
    let lineDesc: String
    switch line.type {
    case .addition:
        lineDesc = "Added line"
    case .deletion:
        lineDesc = "Deleted line"
    case .context:
        lineDesc = "Context line"
    }

    let lineNum = line.newLineNumber ?? line.oldLineNumber ?? 0
    return "\(lineDesc) \(lineNum): \(line.content)"
}

private var diffLineAccessibilityHint: String {
    switch line.type {
    case .addition:
        return "This line was added"
    case .deletion:
        return "This line was removed"
    case .context:
        return "Unchanged line"
    }
}
```

#### 1.2.5 Additional VoiceOver Elements

**New Session Button:**

```swift
// SidebarHeader - New Session Button
Button(action: onNewSession) {
    Image(systemName: "plus")
        .font(.system(size: 14))
        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
}
.buttonStyle(.icon)
.accessibilityLabel("New session")
.accessibilityHint("Double tap to create a new chat session")
```

**Search Field:**

```swift
// Session search
TextField("Search sessions...", text: $viewModel.searchQuery)
    .textFieldStyle(.plain)
    .font(.captionText)
    .foregroundColor(Color.fgPrimary(scheme: colorScheme))
    .accessibilityLabel("Search sessions")
    .accessibilityHint("Type to filter your session history")
```

**Code Block Copy Button:**

```swift
// CodeBlockView - Copy Button
Button(action: copyCode) {
    if showCopied {
        Label("Copied!", systemImage: "checkmark")
    } else {
        Label("Copy", systemImage: "doc.on.doc")
    }
}
.font(.captionText)
.foregroundColor(Color.fgSecondary(scheme: colorScheme))
.buttonStyle(.plain)
.accessibilityLabel("Copy code")
.accessibilityHint("Double tap to copy this code block to clipboard")
```

### 1.3 Accessibility Extensions

Create a new file `Sources/Theme/Accessibility.swift`:

```swift
// Accessibility.swift
// Claude Desktop Mac - Accessibility Helpers

import SwiftUI

// MARK: - Accessibility Color Contrast

extension Color {
    /// Returns a color that meets WCAG AA contrast requirements
    func accessible(luminanceThreshold: Double = 0.5) -> Color {
        // Implement contrast adjustment logic
        self
    }
}

// MARK: - Tool Status Accessibility

extension ToolCallStatus {
    var accessibilityDescription: String {
        switch self {
        case .running:
            return "currently running"
        case .success:
            return "completed successfully"
        case .error:
            return "failed with error"
        }
    }
}

// MARK: - Message Status Accessibility

extension MessageStatus {
    var accessibilityDescription: String {
        switch self {
        case .streaming:
            return "Claude is responding"
        case .complete:
            return "Response complete"
        case .error:
            return "Response had an error"
        }
    }
}

// MARK: - Accessibility Trait Helpers

extension View {
    /// Applies accessibility traits based on state
    func accessibilitySelectable(isSelected: Bool) -> some View {
        self.accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Applies accessibility label with hint combination
    func accessibilityLabeled(label: String, hint: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint)
    }
}

// MARK: - Animation Accessibility

extension Animation {
    /// Returns appropriate animation based on reduce motion preference
    static func accessible(_ animation: Animation) -> Animation {
        if UIAccessibility.isReduceMotionEnabled {
            return .none
        }
        return animation
    }
}
```

### 1.4 Acceptance Criteria

| Criteria | Verification Method |
|----------|---------------------|
| VoiceOver can navigate all session items | Manual testing with VoiceOver |
| VoiceOver reads message content correctly | Manual testing with VoiceOver |
| VoiceOver announces tool call status | Manual testing with VoiceOver |
| VoiceOver identifies all buttons | Manual testing with VoiceOver |
| VoiceOver reads diff changes | Manual testing with VoiceOver |
| Accessibility Inspector shows no warnings | Xcode Accessibility Inspector |

---

## 2. Dynamic Type Support

### 2.1 Overview

Dynamic Type allows users to scale text according to their preferences. The application must respect system font scaling while maintaining layout integrity.

### 2.2 Implementation Details

#### 2.2.1 Typography System Refactor

**Current State:** Fonts use fixed sizes (e.g., `Font.system(size: 15)`).

**Fix:** Replace fixed font sizes with scalable text styles.

Create `Sources/Theme/ScalableTypography.swift`:

```swift
// ScalableTypography.swift
// Claude Desktop Mac - Scalable Typography for Dynamic Type

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
    var baseSize: CGFloat {
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
    var weight: Font.Weight {
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
    var design: Font.Design {
        switch self {
        case .code:
            return .monospaced
        default:
            return .default
        }
    }

    /// Maximum scale factor (prevents text from becoming too large)
    var maxScaleFactor: CGFloat {
        switch self {
        case .windowTitle, .sectionHeader:
            return 1.5 // Limit headings
        case .body, .secondary:
            return 2.0 // Allow body to scale more
        case .caption, .timestamp:
            return 1.8
        case .code:
            return 1.5 // Code should stay readable
        }
    }
}

// MARK: - Scalable Font Extension

extension Font {
    /// Creates a scalable font for the given style
    static func scalable(_ style: ScalableFontStyle) -> Font {
        .system(size: style.baseSize, weight: style.weight, design: style.design)
    }

    // Convenience accessors
    static var scalableWindowTitle: Font { .scalable(.windowTitle) }
    static var scalableSectionHeader: Font { .scalable(.sectionHeader) }
    static var scalableCardTitle: Font { .scalable(.cardTitle) }
    static var scalableBody: Font { .scalable(.body) }
    static var scalableSecondary: Font { .scalable(.secondary) }
    static var scalableCode: Font { .scalable(.code) }
    static var scalableCaption: Font { .scalable(.caption) }
    static var scalableTimestamp: Font { .scalable(.timestamp) }
}

// MARK: - View Extension for Dynamic Type

extension View {
    /// Applies dynamic type scaling with constraints
    func dynamicTypeScaling(
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

struct DynamicTypeScalingModifier: ViewModifier {
    let style: ScalableFontStyle
    let minScale: CGFloat
    let maxScale: CGFloat

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    func body(content: Content) -> some View {
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
    func scaleFactor(style: ScalableFontStyle) -> CGFloat {
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
```

#### 2.2.2 View Updates

**MessageView.swift Updates:**

```swift
// UserMessageContent
Text(content)
    .dynamicTypeScaling(style: .body)
    .foregroundColor(Color.fgPrimary(scheme: colorScheme))
    .textSelection(.enabled)

// Timestamp
Text(timestamp)
    .dynamicTypeScaling(style: .timestamp)
    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
```

**SidebarView.swift Updates:**

```swift
// SessionRowView - Title
Text(session.title)
    .dynamicTypeScaling(style: .body)
    .foregroundColor(isSelected ? Color.fgPrimary(scheme: colorScheme) : Color.fgSecondary(scheme: colorScheme))
    .lineLimit(1)
    .truncationMode(.tail)

// Session subtitle
if let projectName = session.projectName {
    Text(projectName)
        .dynamicTypeScaling(style: .caption)
        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
        .lineLimit(1)
}
```

**InputView.swift Updates:**

```swift
// TextEditor
TextEditor(text: $text)
    .dynamicTypeScaling(style: .body)
    .foregroundColor(Color.fgPrimary(scheme: colorScheme))
    .focused(isFocused)
    .scrollContentBackground(.hidden)
    .frame(minHeight: 36, maxHeight: WindowDimensions.inputMaxHeight - 48)

// Placeholder
Text(placeholderText)
    .dynamicTypeScaling(style: .body)
    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
```

#### 2.2.3 Layout Adaptations

**Dynamic Spacing:**

```swift
// Add to Styles.swift or create new file
struct DynamicSpacing: ViewModifier {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    let baseSpacing: Spacing

    func body(content: Content) -> some View {
        content
            .padding(.all, scaledSpacing)
    }

    private var scaledSpacing: CGFloat {
        let scaleFactor = dynamicTypeSize.scaleFactor(style: .body)
        return baseSpacing.rawValue * scaleFactor
    }
}

extension View {
    func dynamicPadding(_ spacing: Spacing) -> some View {
        self.modifier(DynamicSpacing(baseSpacing: spacing))
    }
}
```

**Container Sizing:**

```swift
// Update message bubble max-width
VStack(alignment: message.role == .user ? .trailing : .leading, spacing: Spacing.sm.rawValue) {
    // ... content
}
.frame(
    maxWidth: message.role == .user ? scaledMaxWidth : .infinity,
    alignment: message.role == .user ? .trailing : .leading
)

private var scaledMaxWidth: CGFloat {
    let baseWidth: CGFloat = 600
    let scaleFactor = dynamicTypeSize.scaleFactor(style: .body)
    // Increase max width for larger text
    return baseWidth * max(1.0, scaleFactor - 0.5)
}
```

### 2.3 Acceptance Criteria

| Criteria | Verification Method |
|----------|---------------------|
| Text scales with system Dynamic Type setting | Settings > Accessibility > Display & Text Size > Larger Text |
| Layout remains functional at all text sizes | Test at accessibility sizes (up to 2.4x) |
| No text truncation at larger sizes | Visual inspection |
| Code blocks remain readable at larger sizes | Visual inspection |
| Input area expands to accommodate larger text | Visual inspection |
| Minimum scale factor respected (0.8x) | Test with smaller text setting |

---

## 3. High Contrast Mode

### 3.1 Overview

High Contrast Mode increases the visual distinction between UI elements for users with low vision or color sensitivity issues.

### 3.2 Implementation Details

#### 3.2.1 High Contrast Color Definitions

**Update `Sources/Theme/Colors.swift`:**

```swift
// MARK: - High Contrast Colors

extension Color {
    // High contrast background colors
    static let bgPrimaryHighContrast = Color(hex: "000000") // Pure black
    static let bgSecondaryHighContrast = Color(hex: "0A0A0A")
    static let bgTertiaryHighContrast = Color(hex: "1A1A1A")
    static let bgElevatedHighContrast = Color(hex: "2A2A2A")

    // High contrast foreground colors
    static let fgPrimaryHighContrast = Color(hex: "FFFFFF") // Pure white
    static let fgSecondaryHighContrast = Color(hex: "E0E0E0")
    static let fgTertiaryHighContrast = Color(hex: "B0B0B0")

    // High contrast accent colors (brighter versions)
    static let accentPrimaryHighContrast = Color(hex: "3D9FFF") // Brighter blue
    static let accentSuccessHighContrast = Color(hex: "50E878") // Brighter green
    static let accentWarningHighContrast = Color(hex: "FFE03D") // Brighter yellow
    static let accentErrorHighContrast = Color(hex: "FF6B6B") // Brighter red
    static let accentPurpleHighContrast = Color(hex: "D07AFF") // Brighter purple
    static let accentOrangeHighContrast = Color(hex: "FFB84D") // Brighter orange

    // High contrast diff colors
    static let diffAdditionFgHighContrast = Color(hex: "50FF80")
    static let diffAdditionBgHighContrast = Color(hex: "0A2A10")
    static let diffDeletionFgHighContrast = Color(hex: "FF8080")
    static let diffDeletionBgHighContrast = Color(hex: "2A0A0A")
}
```

#### 3.2.2 Color Resolution Helper

**Add to `Sources/Theme/Colors.swift`:**

```swift
// MARK: - High Contrast Detection

extension Color {
    /// Resolves the appropriate color based on color scheme and high contrast setting
    static func resolveColor(
        standard: Color,
        highContrast: Color,
        scheme: ColorScheme
    ) -> Color {
        if UIAccessibility.isDarkerSystemColorsEnabled {
            return highContrast
        }
        return standard
    }
}

// MARK: - Semantic Color Extensions with High Contrast

extension Color {
    static func bgPrimary(scheme: ColorScheme, highContrast: Bool = false) -> Color {
        if highContrast || UIAccessibility.isDarkerSystemColorsEnabled {
            return scheme == .dark ? .bgPrimaryHighContrast : .bgPrimaryLight
        }
        return scheme == .dark ? .bgPrimaryDark : .bgPrimaryLight
    }

    static func fgPrimary(scheme: ColorScheme, highContrast: Bool = false) -> Color {
        if highContrast || UIAccessibility.isDarkerSystemColorsEnabled {
            return scheme == .dark ? .fgPrimaryHighContrast : .fgPrimaryLight
        }
        return scheme == .dark ? .fgPrimaryDark : .fgPrimaryLight
    }

    static func fgSecondary(scheme: ColorScheme, highContrast: Bool = false) -> Color {
        if highContrast || UIAccessibility.isDarkerSystemColorsEnabled {
            return scheme == .dark ? .fgSecondaryHighContrast : .fgSecondaryLight
        }
        return scheme == .dark ? .fgSecondaryDark : .fgSecondaryLight
    }

    static func fgTertiary(scheme: ColorScheme, highContrast: Bool = false) -> Color {
        if highContrast || UIAccessibility.isDarkerSystemColorsEnabled {
            return scheme == .dark ? .fgTertiaryHighContrast : .fgTertiaryLight
        }
        return scheme == .dark ? .fgTertiaryDark : .fgTertiaryLight
    }
}
```

#### 3.2.3 View Modifications

**Session Row Border Enhancement:**

```swift
// SessionRowView
HStack(spacing: Spacing.sm.rawValue) {
    // ... existing content
}
.padding(.horizontal, Spacing.sm.rawValue)
.padding(.vertical, Spacing.sm.rawValue)
.background(
    RoundedRectangle(cornerRadius: CornerRadius.md.rawValue)
        .fill(isSelected ? Color.bgSelected(scheme: colorScheme) :
              isHovered ? Color.bgHover(scheme: colorScheme) : Color.clear)
)
.overlay(
    RoundedRectangle(cornerRadius: CornerRadius.md.rawValue)
        .stroke(
            highContrastBorder,
            lineWidth: highContrastBorderWidth
        )
)
.contentShape(Rectangle())

private var highContrastBorder: Color {
    if UIAccessibility.isDarkerSystemColorsEnabled {
        return isSelected ? Color.accentPrimaryHighContrast : Color.fgTertiaryHighContrast.opacity(0.5)
    }
    return Color.clear
}

private var highContrastBorderWidth: CGFloat {
    UIAccessibility.isDarkerSystemColorsEnabled ? 2 : 0
}
```

**Message Bubble Enhancement:**

```swift
// UserMessageContent
VStack(alignment: .trailing, spacing: Spacing.sm.rawValue) {
    // ... content
}
.padding(.horizontal, Spacing.lg.rawValue)
.padding(.vertical, Spacing.md.rawValue)
.background(Color.bgTertiary(scheme: colorScheme))
.cornerRadius(CornerRadius.lg.rawValue)
.overlay(
    RoundedRectangle(cornerRadius: CornerRadius.lg.rawValue)
        .stroke(
            highContrast ? Color.fgSecondary(scheme: colorScheme, highContrast: true) : Color.clear,
            lineWidth: highContrast ? 1 : 0
        )
)

private var highContrast: Bool {
    UIAccessibility.isDarkerSystemColorsEnabled
}
```

**Tool Call Card Enhancement:**

```swift
// ToolCallView
VStack(alignment: .leading, spacing: 0) {
    // ... content
}
.background(Color.bgSecondary(scheme: colorScheme))
.cornerRadius(CornerRadius.md.rawValue)
.overlay(
    RoundedRectangle(cornerRadius: CornerRadius.md.rawValue)
        .stroke(
            enhancedBorderColor,
            lineWidth: enhancedBorderWidth
        )
)

private var enhancedBorderColor: Color {
    if UIAccessibility.isDarkerSystemColorsEnabled {
        switch toolCall.status {
        case .running:
            return .accentWarningHighContrast
        case .error:
            return .accentErrorHighContrast
        default:
            return .fgSecondaryHighContrast
        }
    }
    return statusBorderColor
}

private var enhancedBorderWidth: CGFloat {
    UIAccessibility.isDarkerSystemColorsEnabled ? 2 : 1
}
```

**Input Field Enhancement:**

```swift
// TextInputArea
TextEditor(text: $text)
    // ... existing modifiers
    .background(Color.bgTertiary(scheme: colorScheme))
    .cornerRadius(CornerRadius.md.rawValue)
    .overlay(
        RoundedRectangle(cornerRadius: CornerRadius.md.rawValue)
            .stroke(
                enhancedInputBorderColor,
                lineWidth: enhancedInputBorderWidth
            )
    )

private var enhancedInputBorderColor: Color {
    if UIAccessibility.isDarkerSystemColorsEnabled {
        return isFocused.wrappedValue ? Color.accentPrimaryHighContrast : Color.fgSecondaryHighContrast
    }
    return isFocused.wrappedValue ? Color.accentPrimary : Color.fgTertiary(scheme: colorScheme).opacity(0.3)
}

private var enhancedInputBorderWidth: CGFloat {
    UIAccessibility.isDarkerSystemColorsEnabled ? 2 : (isFocused.wrappedValue ? 2 : 1)
}
```

### 3.3 Acceptance Criteria

| Criteria | Verification Method |
|----------|---------------------|
| Colors adapt to "Increase Contrast" setting | System Preferences > Accessibility > Display > Increase contrast |
| All text meets WCAG AAA contrast ratio (7:1) | Color contrast analyzer tool |
| Borders are visible on all interactive elements | Visual inspection |
| Selection states clearly visible | Visual inspection |
| Tool call status colors distinguishable | Visual inspection |
| Diff addition/deletion colors distinguishable | Visual inspection |

---

## 4. Reduce Motion Support

### 4.1 Overview

Reduce Motion is an accessibility setting that minimizes animations for users who experience motion sensitivity or vestibular disorders.

### 4.2 Implementation Details

#### 4.2.1 Motion Preference Detection

**Add to `Sources/Theme/Accessibility.swift`:**

```swift
// MARK: - Reduce Motion Support

import SwiftUI

/// Environment key for reduce motion preference
struct ReduceMotionKey: EnvironmentKey {
    static let defaultValue: Bool = UIAccessibility.isReduceMotionEnabled
}

extension EnvironmentValues {
    var reduceMotion: Bool {
        get { self[ReduceMotionKey.self] }
        set { self[ReduceMotionKey.self] = newValue }
    }
}

/// Animation modifier that respects reduce motion preference
struct AccessibleAnimationModifier: ViewModifier {
    let animation: Animation
    @Environment(\.reduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content.animation(.none, value: UUID())
        } else {
            content.animation(animation, value: UUID())
        }
    }
}

extension View {
    /// Applies animation that respects reduce motion preference
    func accessibleAnimation(_ animation: Animation) -> some View {
        self.modifier(AccessibleAnimationModifier(animation: animation))
    }

    /// Conditional animation based on reduce motion
    func animationIfEnabled(_ animation: Animation, condition: Bool = true) -> some View {
        if UIAccessibility.isReduceMotionEnabled || !condition {
            return AnyView(self)
        } else {
            return AnyView(self.animation(animation))
        }
    }
}

// MARK: - Alternative Transition Effects

extension AnyTransition {
    /// Fade-only transition for reduce motion users
    static var accessibleFade: AnyTransition {
        if UIAccessibility.isReduceMotionEnabled {
            return .opacity
        } else {
            return .opacity.combined(with: .scale(scale: 0.95))
        }
    }

    /// Accessible slide transition
    static func accessibleSlide(edge: Edge) -> AnyTransition {
        if UIAccessibility.isReduceMotionEnabled {
            return .opacity
        } else {
            return .slide(edge: edge).combined(with: .opacity)
        }
    }

    /// Accessible move transition
    static func accessibleMove(edge: Edge) -> AnyTransition {
        if UIAccessibility.isReduceMotionEnabled {
            return .opacity
        } else {
            return .move(edge: edge)
        }
    }
}
```

#### 4.2.2 View Updates

**ToolCallView.swift - Expand/Collapse Animation:**

```swift
// Current
.onTapGesture {
    withAnimation(.appNormal) {
        isExpanded.toggle()
    }
}

// Updated
.onTapGesture {
    withAnimation(.accessible(.appNormal)) {
        isExpanded.toggle()
    }
}
```

**MessageView.swift - Appear Animation:**

```swift
// Add appear animation
VStack(alignment: message.role == .user ? .trailing : .leading, spacing: Spacing.sm.rawValue) {
    // ... content
}
.transition(.accessibleFade)
.animationIfEnabled(.easeOut(duration: 0.2))
```

**SidebarView.swift - Session Selection:**

```swift
// SessionRowView
.background(
    RoundedRectangle(cornerRadius: CornerRadius.md.rawValue)
        .fill(isSelected ? Color.bgSelected(scheme: colorScheme) :
              isHovered ? Color.bgHover(scheme: colorScheme) : Color.clear)
)
.animationIfEnabled(.easeInOut(duration: AnimationDuration.fast.rawValue))
```

**DiffView.swift - View Mode Switch:**

```swift
// Diff content container
ScrollView([.horizontal, .vertical]) {
    if viewMode == .unified {
        UnifiedDiffView(hunks: fileDiff.hunks)
            .transition(.accessibleFade)
    } else {
        SideBySideDiffView(hunks: fileDiff.hunks)
            .transition(.accessibleFade)
    }
}
.scrollIndicators(.automatic)
```

#### 4.2.3 Animation Extension Update

**Update `Sources/Theme/Styles.swift`:**

```swift
// MARK: - Accessible Animation Extensions

extension Animation {
    /// Normal app animation that respects reduce motion
    public static var appNormalAccessible: Animation {
        if UIAccessibility.isReduceMotionEnabled {
            return .none
        }
        return .appNormal
    }

    /// Fast app animation that respects reduce motion
    public static var appFastAccessible: Animation {
        if UIAccessibility.isReduceMotionEnabled {
            return .none
        }
        return .appFast
    }

    /// Slow app animation that respects reduce motion
    public static var appSlowAccessible: Animation {
        if UIAccessibility.isReduceMotionEnabled {
            return .none
        }
        return .appSlow
    }

    /// Creates an animation that respects reduce motion preference
    public static func accessible(_ animation: Animation) -> Animation {
        if UIAccessibility.isReduceMotionEnabled {
            return .none
        }
        return animation
    }
}

// MARK: - withAnimation Helper

func withAccessibleAnimation(_ animation: Animation = .default, _ body: () -> Void) {
    if UIAccessibility.isReduceMotionEnabled {
        body()
    } else {
        withAnimation(animation, body)
    }
}
```

### 4.3 Acceptance Criteria

| Criteria | Verification Method |
|----------|---------------------|
| Animations stop when Reduce Motion is enabled | System Preferences > Accessibility > Display > Reduce motion |
| Transitions still occur (instant instead of animated) | Visual testing |
| UI remains fully functional without animations | Functional testing |
| Hover states still work without animation | Visual testing |
| Selection states still indicate properly | Visual testing |
| Tool call expand/collapse works instantly | Functional testing |

---

## 5. Implementation Plan

### 5.1 Phase Order

| Phase | Feature | Estimated Effort | Dependencies |
|-------|---------|------------------|--------------|
| 1 | VoiceOver Labels | 2-3 days | None |
| 2 | Dynamic Type Support | 2-3 days | None |
| 3 | High Contrast Mode | 1-2 days | None |
| 4 | Reduce Motion Support | 1 day | None |

### 5.2 Files to Modify

| File | Changes |
|------|---------|
| `Sources/Views/SidebarView.swift` | VoiceOver labels, Dynamic Type, High Contrast borders |
| `Sources/Views/MessageView.swift` | VoiceOver labels, Dynamic Type, Reduce Motion transitions |
| `Sources/Views/ToolCallView.swift` | VoiceOver labels, Dynamic Type, High Contrast borders, Reduce Motion |
| `Sources/Views/InputView.swift` | VoiceOver labels, Dynamic Type, High Contrast borders |
| `Sources/Views/DiffView.swift` | VoiceOver labels, Dynamic Type, High Contrast, Reduce Motion |
| `Sources/Theme/Colors.swift` | High Contrast color definitions |
| `Sources/Theme/Typography.swift` | Scalable typography system |
| `Sources/Theme/Styles.swift` | Accessible animation helpers |

### 5.3 New Files to Create

| File | Purpose |
|------|---------|
| `Sources/Theme/Accessibility.swift` | Accessibility helpers, extensions, modifiers |
| `Sources/Theme/ScalableTypography.swift` | Dynamic Type scaling system |

---

## 6. Testing Plan

### 6.1 VoiceOver Testing

1. Enable VoiceOver (Cmd+F5)
2. Navigate through all screens using Tab and arrow keys
3. Verify all elements have appropriate labels
4. Verify hints provide useful context
5. Verify traits correctly identify element types

### 6.2 Dynamic Type Testing

1. Open System Preferences > Accessibility > Display & Text Size > Larger Text
2. Test with slider at minimum, medium, and maximum settings
3. Verify all text scales appropriately
4. Verify layouts adapt to larger text
5. Verify no content is clipped or truncated

### 6.3 High Contrast Testing

1. Enable "Increase Contrast" in Accessibility settings
2. Verify all colors adapt to high contrast variants
3. Verify borders are visible on all interactive elements
4. Verify selection states are clearly distinguishable
5. Use color contrast analyzer for WCAG AAA compliance

### 6.4 Reduce Motion Testing

1. Enable "Reduce Motion" in Accessibility settings
2. Verify animations are disabled
3. Verify transitions still work (instant instead of animated)
4. Verify UI remains fully functional
5. Verify no motion-based visual feedback is lost

### 6.5 Accessibility Inspector

1. Open Xcode Accessibility Inspector
2. Run audit on all views
3. Address all warnings and errors
4. Verify contrast ratios
5. Verify element hit targets are adequate (44x44 points minimum)

---

## 7. Verification Checklist

### 7.1 VoiceOver

- [ ] Session items read title, project, and time
- [ ] Message bubbles read content and timestamp
- [ ] Tool call cards read status and action hints
- [ ] Send button labeled correctly
- [ ] All buttons have descriptive labels
- [ ] Text fields have helpful placeholder descriptions

### 7.2 Dynamic Type

- [ ] Text scales with system setting
- [ ] Layouts adapt at all sizes
- [ ] No text truncation
- [ ] Input areas expand
- [ ] Code blocks remain readable
- [ ] Minimum scale factor works

### 7.3 High Contrast

- [ ] Colors adapt to high contrast setting
- [ ] All text meets WCAG AAA contrast
- [ ] Borders visible on interactive elements
- [ ] Selection states clearly visible
- [ ] Diff colors distinguishable

### 7.4 Reduce Motion

- [ ] Animations disabled when setting enabled
- [ ] Transitions still function
- [ ] UI fully functional without animations
- [ ] Hover states work
- [ ] Selection states work

---

## 8. Conclusion

This design document provides a comprehensive plan to implement all required accessibility features for Claude Desktop Mac. The implementation should follow the phased approach to ensure thorough testing at each stage.

Upon completion of all four phases, the application will:
1. Be fully navigable with VoiceOver
2. Support all Dynamic Type sizes
3. Provide high contrast alternatives
4. Respect Reduce Motion preferences

This will ensure compliance with App Store accessibility requirements and provide an inclusive experience for all users.

---

*End of Document*
