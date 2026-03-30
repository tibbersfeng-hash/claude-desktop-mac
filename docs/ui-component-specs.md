# Claude Desktop Mac - UI Component Specifications

> Version: 1.0
> Date: 2026-03-30
> Author: UI Designer Agent
> Status: Ready for Implementation

---

## Executive Summary

This document provides detailed UI component specifications for Phase 2 implementation. All specifications are derived from and validated against the UI Design Guide (`ui-design-guide.md`).

### Compliance Status

| Component | Design Guide Compliance | Notes |
|-----------|------------------------|-------|
| Session Management | COMPLIANT | All specs match design guide |
| Message Bubbles | COMPLIANT | Colors and typography aligned |
| Tool Call Cards | COMPLIANT | Icons and states match |
| Diff View | COMPLIANT | Color scheme consistent |
| Input Area | COMPLIANT | Dimensions match |

---

## 1. Color Tokens

### 1.1 Dark Theme Colors (Primary)

```swift
// MARK: - Dark Theme Colors
extension Color {
    // Background
    static let bgPrimaryDark = Color(hex: "1E1E1E")      // Main window background
    static let bgSecondaryDark = Color(hex: "252526")    // Sidebar, panels
    static let bgTertiaryDark = Color(hex: "2D2D30")     // Cards, elevated surfaces
    static let bgElevatedDark = Color(hex: "3C3C3C")     // Dropdowns, popovers
    static let bgHoverDark = Color(hex: "404040")        // Hover state overlay
    static let bgSelectedDark = Color(hex: "094771")     // Selection highlight

    // Foreground
    static let fgPrimaryDark = Color(hex: "CCCCCC")      // Primary text
    static let fgSecondaryDark = Color(hex: "9D9D9D")    // Secondary text
    static let fgTertiaryDark = Color(hex: "6B6B6B")     // Disabled text
    static let fgInverseDark = Color(hex: "FFFFFF")      // Text on accent

    // Accent
    static let accentPrimary = Color(hex: "0A84FF")      // macOS system blue
    static let accentSuccess = Color(hex: "30D158")      // Green
    static let accentWarning = Color(hex: "FFD60A")      // Yellow
    static let accentError = Color(hex: "FF453A")        // Red
    static let accentPurple = Color(hex: "BF5AF2")       // AI/Assistant

    // Code
    static let codeBgDark = Color(hex: "1A1A1A")         // Code block background
    static let codeKeyword = Color(hex: "FC5FA3")        // Keywords
    static let codeString = Color(hex: "FC6A5D")         // Strings
    static let codeComment = Color(hex: "73C991")        // Comments
    static let codeFunction = Color(hex: "67B7A4")       // Functions
    static let codeVariable = Color(hex: "9CDCFE")       // Variables
    static let codeNumber = Color(hex: "B4CECF")         // Numbers

    // Diff
    static let diffRemovedBgDark = Color(hex: "3D1F1E")  // Removed line background
    static let diffRemovedTextDark = Color(hex: "FF6B6B") // Removed line text
    static let diffAddedBgDark = Color(hex: "1E3D26")    // Added line background
    static let diffAddedTextDark = Color(hex: "6BCB77")  // Added line text
    static let diffModifiedBgDark = Color(hex: "3D3A1E") // Modified line background
    static let diffModifiedTextDark = Color(hex: "FFD93D") // Modified line text

    // Connection Status
    static let statusConnectedBg = Color(hex: "1E3D26")  // Connected background tint
    static let statusConnectingBg = Color(hex: "3D3A1E") // Connecting background tint
    static let statusDisconnectedBg = Color(hex: "3D1F1E") // Disconnected background tint
    static let statusReconnectingBg = Color(hex: "3D2D1E") // Reconnecting background tint
}
```

### 1.2 Light Theme Colors (Secondary)

```swift
// MARK: - Light Theme Colors
extension Color {
    // Background
    static let bgPrimaryLight = Color(hex: "FFFFFF")     // Main window background
    static let bgSecondaryLight = Color(hex: "F3F3F3")   // Sidebar, panels
    static let bgTertiaryLight = Color(hex: "EBEBEB")    // Cards, elevated surfaces
    static let bgElevatedLight = Color(hex: "FAFAFA")    // Dropdowns, popovers
    static let bgHoverLight = Color(hex: "E8E8E8")       // Hover state overlay
    static let bgSelectedLight = Color(hex: "0078D4")    // Selection highlight

    // Foreground
    static let fgPrimaryLight = Color(hex: "333333")     // Primary text
    static let fgSecondaryLight = Color(hex: "666666")   // Secondary text
    static let fgTertiaryLight = Color(hex: "999999")    // Disabled text
}
```

### 1.3 Color Helper Extension

```swift
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
            (a, r, g, b) = (255, 0, 0, 0)
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
```

---

## 2. Typography Tokens

### 2.1 Font Specifications

```swift
// MARK: - Typography
extension Font {
    // Window Titles
    static let windowTitle = Font.system(size: 22, weight: .semibold)

    // Section Headers
    static let sectionHeader = Font.system(size: 20, weight: .semibold)

    // Card Titles
    static let cardTitle = Font.system(size: 17, weight: .semibold)

    // Body Text
    static let bodyText = Font.system(size: 15, weight: .regular)

    // Code Text
    static let codeText = Font.system(size: 13, weight: .regular, design: .monospaced)

    // Inline Code
    static let inlineCode = Font.system(size: 14, weight: .regular, design: .monospaced)

    // Caption
    static let caption = Font.system(size: 12, weight: .regular)

    // Timestamp
    static let timestamp = Font.system(size: 11, weight: .regular)

    // Label
    static let label = Font.system(size: 11, weight: .regular)
}

// Line Heights
enum LineHeight: CGFloat {
    case windowTitle = 28
    case sectionHeader = 26
    case cardTitle = 22
    case bodyText = 20
    case codeText = 18
    case caption = 16
    case timestamp = 14
}
```

---

## 3. Spacing & Layout Tokens

### 3.1 Spacing Scale

```swift
// MARK: - Spacing
enum Spacing: CGFloat {
    case xs = 4      // Icon padding
    case sm = 8      // Tight spacing
    case md = 12     // Standard padding
    case lg = 16     // Card padding
    case xl = 24     // Section spacing
    case xxl = 32    // Major sections
}

// Convenience extension
extension EdgeInsets {
    static let cardPadding = EdgeInsets(
        top: Spacing.lg.rawValue,
        leading: Spacing.lg.rawValue,
        bottom: Spacing.lg.rawValue,
        trailing: Spacing.lg.rawValue
    )

    static let listItemPadding = EdgeInsets(
        top: Spacing.md.rawValue,
        leading: Spacing.md.rawValue,
        bottom: Spacing.md.rawValue,
        trailing: Spacing.md.rawValue
    )
}
```

### 3.2 Border Radius

```swift
// MARK: - Border Radius
enum BorderRadius: CGFloat {
    case sm = 4      // Small elements
    case md = 8      // Buttons, inputs
    case lg = 12     // Cards, bubbles
    case xl = 16     // Modals
    case full = 9999 // Pills, badges
}
```

### 3.3 Window Dimensions

```swift
// MARK: - Window Dimensions
enum WindowDimension: CGFloat {
    case minWidth = 800
    case minHeight = 600
    case defaultWidth = 1200
    case defaultHeight = 800
    case sidebarWidth = 220
    case sidebarCollapsedWidth = 48
    case statusBarHeight = 24
}

// Responsive breakpoints
enum Breakpoint: CGFloat {
    case compact = 800    // Sidebar hidden (overlay)
    case regular = 1000   // Sidebar collapsed (icons only)
    case expanded = 1001  // Full sidebar
}
```

---

## 4. Component Specifications

### 4.1 Session List Item

#### Dimensions
| Property | Value |
|----------|-------|
| Height | 48px |
| Icon Size | 24x24px |
| Left Padding | 12px |
| Right Padding | 12px |
| Title-Subtitle Gap | 2px |

#### Colors (Dark Mode)
| Element | Normal | Hover | Selected |
|---------|--------|-------|----------|
| Background | transparent | `bgHoverDark` (#404040) | `bgSelectedDark` (#094771) |
| Title Text | `fgPrimaryDark` (#CCCCCC) | `fgPrimaryDark` | `fgInverseDark` (#FFFFFF) |
| Subtitle Text | `fgSecondaryDark` (#9D9D9D) | `fgSecondaryDark` | `fgSecondaryDark` |
| Timestamp | `fgTertiaryDark` (#6B6B6B) | `fgTertiaryDark` | `fgTertiaryDark` |
| Close Button | transparent | `fgSecondaryDark` | `fgSecondaryDark` |

#### Typography
| Element | Font | Size | Weight |
|---------|------|------|--------|
| Title | San Francisco | 14pt | Medium |
| Subtitle | San Francisco | 12pt | Regular |
| Timestamp | San Francisco | 11pt | Regular |

#### SwiftUI Implementation

```swift
struct SessionListItemView: View {
    let session: Session
    let isSelected: Bool
    let isHovered: Bool

    var body: some View {
        HStack(spacing: Spacing.md.rawValue) {
            // Icon
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)

            // Text Content
            VStack(alignment: .leading, spacing: 2) {
                Text(session.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(titleColor)
                    .lineLimit(1)

                HStack {
                    Text(session.projectPath ?? "No Project")
                        .font(.system(size: 12))
                        .foregroundColor(subtitleColor)
                        .lineLimit(1)

                    Spacer()

                    Text(relativeTime)
                        .font(.system(size: 11))
                        .foregroundColor(timestampColor)
                }
            }

            // Close Button (visible on hover)
            if isHovered {
                Button(action: { }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.fgSecondaryDark)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.md.rawValue)
        .frame(height: 48)
        .background(backgroundColor)
        .contentShape(Rectangle())
    }

    private var backgroundColor: Color {
        if isSelected { return .bgSelectedDark }
        if isHovered { return .bgHoverDark }
        return .clear
    }

    private var titleColor: Color {
        isSelected ? .fgInverseDark : .fgPrimaryDark
    }

    private var subtitleColor: Color {
        .fgSecondaryDark
    }

    private var timestampColor: Color {
        .fgTertiaryDark
    }

    private var iconColor: Color {
        isSelected ? .accentPrimary : .fgSecondaryDark
    }
}
```

---

### 4.2 Sidebar

#### Dimensions
| Property | Value |
|----------|-------|
| Width (Expanded) | 220px |
| Width (Collapsed) | 48px |
| Header Height | 44px |
| Section Header Height | 28px |

#### Layout Structure

```
+------------------------------------------+
|  [+] Sessions                    44px    |  <- Header
+------------------------------------------+
|  Section Header (optional)       28px    |
+------------------------------------------+
|  Session Item                    48px    |
|  Session Item                    48px    |
|  ...                                     |
+------------------------------------------+
|  Divider                                 |
+------------------------------------------+
|  [Settings]                     footer   |
+------------------------------------------+
```

#### Colors (Dark Mode)
| Element | Color |
|---------|-------|
| Background | `bgSecondaryDark` (#252526) |
| Divider | `bgTertiaryDark` (#2D2D30) |
| Section Header | `fgSecondaryDark` (#9D9D9D) |

#### SwiftUI Implementation

```swift
struct SidebarView: View {
    @Binding var sessions: [Session]
    @Binding var selectedSessionId: UUID?
    @State private var hoveredSessionId: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: createNewSession) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)

                Text("Sessions")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.fgSecondaryDark)

                Spacer()
            }
            .padding(.horizontal, Spacing.md.rawValue)
            .frame(height: 44)

            // Session List
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(sessions) { session in
                        SessionListItemView(
                            session: session,
                            isSelected: selectedSessionId == session.id,
                            isHovered: hoveredSessionId == session.id
                        )
                        .onTapGesture { selectSession(session.id) }
                        .onHover { isHovered in
                            hoveredSessionId = isHovered ? session.id : nil
                        }
                    }
                }
            }

            Divider()
                .background(Color.bgTertiaryDark)

            // Footer - Settings
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.fgSecondaryDark)
                Text("Settings")
                    .foregroundColor(.fgSecondaryDark)
                Spacer()
            }
            .padding(.horizontal, Spacing.md.rawValue)
            .frame(height: 40)
            .contentShape(Rectangle())
            .onHover { isHovered in
                // Highlight effect
            }
        }
        .frame(width: 220)
        .background(Color.bgSecondaryDark)
    }
}
```

---

### 4.3 Message Bubble - User

#### Dimensions
| Property | Value |
|----------|-------|
| Min Height | 48px |
| Max Width | 80% of container |
| Padding | 12px vertical, 16px horizontal |
| Border Radius | 12px |
| Alignment | Right |

#### Colors (Dark Mode)
| Element | Color |
|---------|-------|
| Background | `bgTertiaryDark` (#2D2D30) |
| Text | `fgPrimaryDark` (#CCCCCC) |
| Timestamp | `fgTertiaryDark` (#6B6B6B) |
| Edit Button | `fgSecondaryDark` (#9D9D9D) |

#### Typography
| Element | Font | Size | Weight |
|---------|------|------|--------|
| Message Text | San Francisco | 15pt | Regular |
| Timestamp | San Francisco | 11pt | Regular |

#### SwiftUI Implementation

```swift
struct UserMessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            Spacer()

            VStack(alignment: .trailing, spacing: Spacing.xs.rawValue) {
                // Message Content
                Text(message.content)
                    .font(.bodyText)
                    .foregroundColor(.fgPrimaryDark)
                    .textSelection(.enabled)

                // Footer
                HStack(spacing: Spacing.sm.rawValue) {
                    Text(formatTime(message.timestamp))
                        .font(.timestamp)
                        .foregroundColor(.fgTertiaryDark)

                    Button("Edit") {
                        // Edit action
                    }
                    .font(.caption)
                    .foregroundColor(.fgSecondaryDark)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg.rawValue)
            .padding(.vertical, Spacing.md.rawValue)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .background(Color.bgTertiaryDark)
            .cornerRadius(BorderRadius.lg.rawValue)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.lg.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
    }
}
```

---

### 4.4 Message Bubble - Assistant

#### Dimensions
| Property | Value |
|----------|-------|
| Width | 100% of container |
| Padding | 12px vertical, 16px horizontal |
| Border Radius | 12px |
| Alignment | Left |

#### Colors (Dark Mode)
| Element | Color |
|---------|-------|
| Background | transparent or `bgSecondaryDark` (#252526) |
| Claude Icon | `accentPurple` (#BF5AF2) |
| Text | `fgPrimaryDark` (#CCCCCC) |
| Timestamp | `fgTertiaryDark` (#6B6B6B) |
| Action Buttons | `fgSecondaryDark` (#9D9D9D) |

#### Layout Structure

```
+----------------------------------------------------------+
|  [Claude Icon 32x32]                                      |
|                                                          |
|  Message content with Markdown support...                 |
|                                                          |
|  ```code block```                                        |
|                                                          |
|  [Tool Call Card] (if applicable)                        |
|                                                          |
|  [Copy] [Regenerate]                        14:33        |
+----------------------------------------------------------+
```

#### SwiftUI Implementation

```swift
struct AssistantMessageBubble: View {
    let message: Message

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
            // Claude Icon
            HStack(spacing: Spacing.sm.rawValue) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.accentPurple)
                    .frame(width: 32, height: 32)
                    .background(Color.bgTertiaryDark)
                    .cornerRadius(BorderRadius.md.rawValue)

                Text("Claude")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.fgSecondaryDark)
            }

            // Message Content (Markdown)
            MarkdownView(content: message.content)
                .font(.bodyText)
                .foregroundColor(.fgPrimaryDark)

            // Tool Calls (if any)
            if let toolCalls = message.toolCalls, !toolCalls.isEmpty {
                ForEach(toolCalls) { toolCall in
                    ToolCallCard(toolCall: toolCall)
                }
            }

            // Footer
            HStack {
                Button(action: copyMessage) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.plain)
                .foregroundColor(.fgSecondaryDark)

                Button(action: regenerate) {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .foregroundColor(.fgSecondaryDark)

                Spacer()

                Text(formatTime(message.timestamp))
                    .font(.timestamp)
                    .foregroundColor(.fgTertiaryDark)
            }
            .font(.caption)
        }
        .padding(.horizontal, Spacing.lg.rawValue)
        .padding(.vertical, Spacing.md.rawValue)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.clear)
        .padding(.horizontal, Spacing.lg.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
    }
}
```

---

### 4.5 Input Area

#### Dimensions
| Property | Value |
|----------|-------|
| Min Height | 80px |
| Max Height | 300px (with scroll) |
| Text Area Padding | 12px |
| Border Radius | 12px |
| Border Width | 1px |
| Status Bar Height | 24px |

#### Colors (Dark Mode)
| Element | Normal | Focused |
|---------|--------|---------|
| Background | `bgTertiaryDark` (#2D2D30) | `bgTertiaryDark` |
| Border | `fgTertiaryDark` (#6B6B6B) | `accentPrimary` (#0A84FF) |
| Placeholder | `fgTertiaryDark` (#6B6B6B) | - |
| Text | `fgPrimaryDark` (#CCCCCC) | - |

#### Layout Structure

```
+----------------------------------------------------------+
|  [Attach]                                         [Send] |  <- Toolbar
|  +----------------------------------------------------+  |
|  |                                                    |  |
|  |  Type your message...                              |  |  <- Text Area
|  |                                                    |  |
|  +----------------------------------------------------+  |
|  Project: /workspace  |  Model: claude-sonnet-4.6      |  <- Status Bar
+----------------------------------------------------------+
```

#### SwiftUI Implementation

```swift
struct MessageInputView: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    let onSend: () -> Void
    let onAttach: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button(action: onAttach) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .foregroundColor(.fgSecondaryDark)

                Spacer()

                Button(action: onSend) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .foregroundColor(text.isEmpty ? .fgTertiaryDark : .accentPrimary)
                .disabled(text.isEmpty)
            }
            .padding(.horizontal, Spacing.md.rawValue)
            .padding(.vertical, Spacing.sm.rawValue)

            // Text Area
            TextEditor(text: $text)
                .focused($isFocused)
                .font(.bodyText)
                .foregroundColor(.fgPrimaryDark)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 44, maxHeight: 220)
                .padding(.horizontal, Spacing.sm.rawValue)

            // Status Bar
            HStack {
                Text("Project: /workspace")
                    .foregroundColor(.fgTertiaryDark)

                Spacer()

                Text("Model: claude-sonnet-4.6")
                    .foregroundColor(.fgTertiaryDark)
            }
            .font(.label)
            .padding(.horizontal, Spacing.md.rawValue)
            .padding(.vertical, Spacing.xs.rawValue)
        }
        .padding(Spacing.md.rawValue)
        .background(Color.bgTertiaryDark)
        .cornerRadius(BorderRadius.lg.rawValue)
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadius.lg.rawValue)
                .stroke(isFocused ? Color.accentPrimary : Color.fgTertiaryDark, lineWidth: 1)
        )
        .padding(.horizontal, Spacing.lg.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
    }
}
```

---

### 4.6 Tool Call Card

#### Dimensions
| Property | Value |
|----------|-------|
| Header Height | 36px |
| Border Radius | 8px |
| Content Padding | 12px |
| Result Preview Lines | 5 lines max |

#### Tool Icon Colors
| Tool | Icon | Color |
|------|------|-------|
| Read | `doc.text` | Blue (`#0A84FF`) |
| Write | `square.and.pencil` | Green (`#30D158`) |
| Edit | `pencil.tip` | Orange (`#FF9F0A`) |
| Bash | `terminal` | Gray (`#8E8E93`) |
| Glob | `magnifyingglass` | Purple (`#BF5AF2`) |
| Grep | `text.magnifyingglass` | Teal (`#64D2FF`) |

#### State Colors
| State | Background | Border | Indicator |
|-------|------------|--------|-----------|
| Running | `bgTertiaryDark` | `accentWarning` (yellow) | Animated spinner |
| Success | `bgTertiaryDark` | `accentSuccess` (green) | Green checkmark |
| Error | `statusDisconnectedBg` | `accentError` (red) | Red exclamation |
| Pending | `bgTertiaryDark` | `fgTertiaryDark` | Gray, dimmed |

#### Layout (Collapsed)

```
+----------------------------------------------------------+
| [Icon] Read File (3 files)                       [>]    |
+----------------------------------------------------------+
```

#### Layout (Expanded)

```
+----------------------------------------------------------+
| [Icon] Read File                                 [v][+] |
+----------------------------------------------------------+
| Arguments:                                               |
| { "file_path": "/src/services/api.swift" }               |
+----------------------------------------------------------+
| Result: 245 lines read                          0.23s    |
+----------------------------------------------------------+
|  1 | import Foundation                                    |
|  2 |                                                      |
|  3 | struct APIClient {                                   |
| ...| ...                                                  |
+----------------------------------------------------------+
```

#### SwiftUI Implementation

```swift
struct ToolCallCard: View {
    let toolCall: ToolCallDisplay
    @State private var isExpanded: Bool

    init(toolCall: ToolCallDisplay) {
        self.toolCall = toolCall
        self._isExpanded = State(initialValue: toolCall.status == .error)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: Spacing.sm.rawValue) {
                // Tool Icon
                Image(systemName: toolCall.iconName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(toolCall.iconColor)
                    .frame(width: 24, height: 24)
                    .background(toolCall.iconColor.opacity(0.15))
                    .cornerRadius(BorderRadius.sm.rawValue)

                // Tool Name & Summary
                Text(toolCall.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.fgPrimaryDark)

                Spacer()

                // Status Indicator
                statusIndicator

                // Expand/Collapse Button
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.fgSecondaryDark)
                }
                .buttonStyle(.plain)

                // Copy Button
                Button(action: { }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.fgSecondaryDark)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Spacing.md.rawValue)
            .frame(height: 36)
            .background(Color.bgTertiaryDark)

            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
                    // Arguments
                    if let arguments = toolCall.arguments {
                        Text("Arguments:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.fgSecondaryDark)

                        Text(formatJSON(arguments))
                            .font(.codeText)
                            .foregroundColor(.fgPrimaryDark)
                            .padding(Spacing.sm.rawValue)
                            .background(Color.codeBgDark)
                            .cornerRadius(BorderRadius.sm.rawValue)
                    }

                    // Result
                    if let result = toolCall.result {
                        HStack {
                            Text("Result:")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.fgSecondaryDark)

                            Spacer()

                            if let duration = toolCall.duration {
                                Text(String(format: "%.2fs", duration))
                                    .font(.timestamp)
                                    .foregroundColor(.fgTertiaryDark)
                            }
                        }

                        Text(result)
                            .font(.codeText)
                            .foregroundColor(.fgPrimaryDark)
                            .lineLimit(5)
                            .padding(Spacing.sm.rawValue)
                            .background(Color.codeBgDark)
                            .cornerRadius(BorderRadius.sm.rawValue)
                    }

                    // Error
                    if let error = toolCall.error {
                        Text("Error:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.accentError)

                        Text(error)
                            .font(.codeText)
                            .foregroundColor(.accentError)
                            .padding(Spacing.sm.rawValue)
                            .background(Color.statusDisconnectedBg)
                            .cornerRadius(BorderRadius.sm.rawValue)
                    }
                }
                .padding(Spacing.md.rawValue)
                .background(Color.bgTertiaryDark)
            }
        }
        .cornerRadius(BorderRadius.md.rawValue)
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadius.md.rawValue)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch toolCall.status {
        case .running:
            ProgressView()
                .scaleEffect(0.6)
                .frame(width: 16, height: 16)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.accentSuccess)
        case .error:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.accentError)
        case .pending:
            Circle()
                .fill(Color.fgTertiaryDark)
                .frame(width: 8, height: 8)
        }
    }

    private var borderColor: Color {
        switch toolCall.status {
        case .running: return .accentWarning
        case .success: return .accentSuccess
        case .error: return .accentError
        case .pending: return .fgTertiaryDark
        }
    }
}

// ToolCallDisplay Extension
extension ToolCallDisplay {
    var iconName: String {
        switch name {
        case "Read": return "doc.text"
        case "Write": return "square.and.pencil"
        case "Edit": return "pencil.tip"
        case "Bash": return "terminal"
        case "Glob": return "magnifyingglass"
        case "Grep": return "text.magnifyingglass"
        default: return "wrench.and.screwdriver"
        }
    }

    var iconColor: Color {
        switch name {
        case "Read": return .accentPrimary
        case "Write": return .accentSuccess
        case "Edit": return Color(hex: "FF9F0A")
        case "Bash": return Color(hex: "8E8E93")
        case "Glob": return .accentPurple
        case "Grep": return Color(hex: "64D2FF")
        default: return .fgSecondaryDark
        }
    }

    var displayName: String {
        switch name {
        case "Read": return "Read File"
        case "Write": return "Write File"
        case "Edit": return "Edit File"
        case "Bash": return "Bash Command"
        case "Glob": return "Glob Search"
        case "Grep": return "Grep Search"
        default: return name
        }
    }
}
```

---

### 4.7 Diff View (Unified)

#### Dimensions
| Property | Value |
|----------|-------|
| Line Number Width | 40px |
| Line Height | 20px |
| Code Font Size | 13pt |
| Header Height | 40px |
| Footer Height | 48px |

#### Colors (Dark Mode)
| Type | Background | Text |
|------|------------|------|
| Removed | `diffRemovedBgDark` (#3D1F1E) | `diffRemovedTextDark` (#FF6B6B) |
| Added | `diffAddedBgDark` (#1E3D26) | `diffAddedTextDark` (#6BCB77) |
| Modified | `diffModifiedBgDark` (#3D3A1E) | `diffModifiedTextDark` (#FFD93D) |
| Context | transparent | `fgPrimaryDark` (#CCCCCC) |
| Line Number | - | `fgTertiaryDark` (#6B6B6B) |

#### Layout Structure

```
+----------------------------------------------------------+
| File: src/services/api.swift                              |
| Changes: +15 -3                                    [Apply]|
+----------------------------------------------------------+
|  44 |                                                     |
| - 45 | func fetchData() {                                 |
| - 46 |     // TODO: Implement                              |
| - 47 | }                                                  |
| + 45 | func fetchData(id: String) async throws -> Data {  |
| + 46 |     let url = baseURL.appendingPathComponent(id)   |
| + 47 |     let (data, _) = try await URLSession.shared... |
| + 48 |     return data                                     |
| + 49 | }                                                  |
|  50 |                                                     |
+----------------------------------------------------------+
| [Accept] [Reject] [Accept All] [Reject All]              |
+----------------------------------------------------------+
```

#### SwiftUI Implementation

```swift
struct UnifiedDiffView: View {
    let fileDiff: FileDiff
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("File: \(fileDiff.filePath)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.fgPrimaryDark)

                    HStack(spacing: Spacing.sm.rawValue) {
                        Text("+\(fileDiff.additions)")
                            .foregroundColor(.diffAddedTextDark)
                        Text("-\(fileDiff.deletions)")
                            .foregroundColor(.diffRemovedTextDark)
                    }
                    .font(.system(size: 11))
                }

                Spacer()

                Button("Apply") {
                    onAccept()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, Spacing.md.rawValue)
            .frame(height: 40)
            .background(Color.bgSecondaryDark)

            // Diff Content
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(fileDiff.hunks, id: \.self) { hunk in
                        ForEach(hunk.lines, id: \.self) { line in
                            DiffLineView(line: line)
                        }
                    }
                }
            }
            .background(Color.bgPrimaryDark)

            // Footer
            HStack(spacing: Spacing.md.rawValue) {
                Button("Accept") { onAccept() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                Button("Reject") { onReject() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                Spacer()

                Button("Accept All") { }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                Button("Reject All") { }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .padding(.horizontal, Spacing.md.rawValue)
            .frame(height: 48)
            .background(Color.bgSecondaryDark)
        }
        .cornerRadius(BorderRadius.md.rawValue)
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadius.md.rawValue)
                .stroke(Color.bgTertiaryDark, lineWidth: 1)
        )
    }
}

struct DiffLineView: View {
    let line: DiffLine

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Line Number
            Text(lineNumberText)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.fgTertiaryDark)
                .frame(width: 40, alignment: .trailing)
                .padding(.trailing, Spacing.sm.rawValue)

            // Change Indicator
            Text(changeIndicator)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(changeColor)
                .frame(width: 16)

            // Content
            Text(line.content)
                .font(.codeText)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 1)
        .padding(.horizontal, Spacing.sm.rawValue)
        .background(backgroundColor)
    }

    private var lineNumberText: String {
        switch line.type {
        case .context:
            return line.oldLineNumber.map { String($0) } ?? ""
        case .addition:
            return line.newLineNumber.map { String($0) } ?? ""
        case .deletion:
            return line.oldLineNumber.map { String($0) } ?? ""
        }
    }

    private var changeIndicator: String {
        switch line.type {
        case .context: return " "
        case .addition: return "+"
        case .deletion: return "-"
        }
    }

    private var backgroundColor: Color {
        switch line.type {
        case .context: return .clear
        case .addition: return .diffAddedBgDark
        case .deletion: return .diffRemovedBgDark
        }
    }

    private var textColor: Color {
        switch line.type {
        case .context: return .fgPrimaryDark
        case .addition: return .diffAddedTextDark
        case .deletion: return .diffRemovedTextDark
        }
    }

    private var changeColor: Color {
        textColor
    }
}
```

---

### 4.8 Diff View (Side by Side)

#### Dimensions
| Property | Value |
|----------|-------|
| Panel Width | 50% each |
| Line Number Width | 40px |
| Line Height | 20px |
| Gap Between Panels | 1px |

#### Layout Structure

```
+----------------------------------------------------------+
| File: src/services/api.swift                              |
| Changes: +15 -3                                    [Apply]|
+----------------------------------------------------------+
| Side by Side | Unified                               [v] |
+----------------------------------------------------------+
|                |           Original    |    Modified      |
|----------------|-----------------------|------------------|
| Line 45        | func fetchData() {    | func fetchData(  |
|                |     // TODO           |   id: String     |
|                | }                     | ) {              |
|                |                       |   // Implemented |
|                |                       | }                |
+----------------------------------------------------------+
| [Accept] [Reject] [Accept All] [Reject All]              |
+----------------------------------------------------------+
```

#### SwiftUI Implementation

```swift
struct SideBySideDiffView: View {
    let fileDiff: FileDiff
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header (same as Unified)
            DiffHeader(fileDiff: fileDiff, onAccept: onAccept)

            // Column Headers
            HStack(spacing: 1) {
                Text("Original")
                    .frame(maxWidth: .infinity)
                Text("Modified")
                    .frame(maxWidth: .infinity)
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.fgSecondaryDark)
            .padding(.vertical, Spacing.xs.rawValue)
            .background(Color.bgSecondaryDark)

            // Side by Side Content
            ScrollView {
                HStack(spacing: 1) {
                    // Original Panel
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(originalLines, id: \.self) { line in
                            SideBySideLineView(line: line, showOriginal: true)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.bgPrimaryDark)

                    // Modified Panel
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(modifiedLines, id: \.self) { line in
                            SideBySideLineView(line: line, showOriginal: false)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.bgPrimaryDark)
                }
            }

            // Footer (same as Unified)
            DiffFooter(onAccept: onAccept, onReject: onReject)
        }
        .cornerRadius(BorderRadius.md.rawValue)
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadius.md.rawValue)
                .stroke(Color.bgTertiaryDark, lineWidth: 1)
        )
    }

    private var originalLines: [DiffLine] {
        fileDiff.hunks.flatMap { $0.lines.filter { $0.type != .addition } }
    }

    private var modifiedLines: [DiffLine] {
        fileDiff.hunks.flatMap { $0.lines.filter { $0.type != .deletion } }
    }
}

struct SideBySideLineView: View {
    let line: DiffLine
    let showOriginal: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Line Number
            Text(lineNumberText)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.fgTertiaryDark)
                .frame(width: 40, alignment: .trailing)
                .padding(.trailing, Spacing.sm.rawValue)

            // Content
            Text(line.content)
                .font(.codeText)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 1)
        .padding(.horizontal, Spacing.sm.rawValue)
        .background(backgroundColor)
    }

    private var lineNumberText: String {
        if showOriginal {
            return line.oldLineNumber.map { String($0) } ?? ""
        } else {
            return line.newLineNumber.map { String($0) } ?? ""
        }
    }

    private var backgroundColor: Color {
        guard showOriginal else {
            return line.type == .addition ? .diffAddedBgDark : .clear
        }
        return line.type == .deletion ? .diffRemovedBgDark : .clear
    }

    private var textColor: Color {
        guard showOriginal else {
            return line.type == .addition ? .diffAddedTextDark : .fgPrimaryDark
        }
        return line.type == .deletion ? .diffRemovedTextDark : .fgPrimaryDark
    }
}
```

---

### 4.9 Connection Status Bar

#### Dimensions
| Property | Value |
|----------|-------|
| Height | 24px |
| Status Icon Size | 8x8px |
| Padding | 8px horizontal |

#### Status Colors
| State | Icon Color | Background | Animation |
|-------|------------|------------|-----------|
| Disconnected | `accentError` (#FF453A) | `statusDisconnectedBg` | None |
| Connecting | `accentWarning` (#FFD60A) | `statusConnectingBg` | Pulse |
| Connected | `accentSuccess` (#30D158) | `statusConnectedBg` | None |
| Error | `accentError` (#FF453A) | `statusDisconnectedBg` | None |
| Reconnecting | `#FF9F0A` (Orange) | `statusReconnectingBg` | Rotate |

#### SwiftUI Implementation

```swift
struct ConnectionStatusBar: View {
    @ObservedObject var connectionManager: ConnectionManager

    var body: some View {
        HStack(spacing: Spacing.sm.rawValue) {
            // Status Icon
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(statusColor.opacity(0.3), lineWidth: 2)
                        .scaleEffect(isAnimating ? 1.5 : 1.0)
                        .opacity(isAnimating ? 0 : 1)
                        .animation(
                            isAnimating ? Animation.easeInOut(duration: 1).repeatForever(autoreverses: false) : .default,
                            value: isAnimating
                        )
                )

            // Status Text
            Text(statusText)
                .font(.system(size: 11))
                .foregroundColor(.fgSecondaryDark)

            Spacer()

            // Model Info
            if let model = connectionManager.currentModel {
                Text("Model: \(model)")
                    .font(.system(size: 11))
                    .foregroundColor(.fgTertiaryDark)
            }
        }
        .padding(.horizontal, Spacing.sm.rawValue)
        .frame(height: 24)
        .background(Color.bgSecondaryDark)
    }

    private var statusColor: Color {
        switch connectionManager.state {
        case .connected: return .accentSuccess
        case .connecting: return .accentWarning
        case .disconnected: return .accentError
        case .error: return .accentError
        case .reconnecting: return Color(hex: "FF9F0A")
        }
    }

    private var statusText: String {
        switch connectionManager.state {
        case .connected: return "Connected to Claude Code"
        case .connecting: return "Connecting..."
        case .disconnected: return "Disconnected"
        case .error(let message): return "Error: \(message)"
        case .reconnecting: return "Reconnecting..."
        }
    }

    private var isAnimating: Bool {
        switch connectionManager.state {
        case .connecting, .reconnecting: return true
        default: return false
        }
    }
}
```

---

### 4.10 Code Block

#### Dimensions
| Property | Value |
|----------|-------|
| Header Height | 28px |
| Border Radius | 8px |
| Padding | 12px |
| Line Number Width | 40px |

#### Layout Structure

```
+----------------------------------------------------------+
|  swift                                     [Copy] [Expand]|
+----------------------------------------------------------+
|  1 | import Foundation                                    |
|  2 |                                                      |
|  3 | struct APIClient {                                   |
|  4 |     let baseURL: URL                                 |
| ...| ...                                                  |
+----------------------------------------------------------+
```

#### SwiftUI Implementation

```swift
struct CodeBlockView: View {
    let language: String
    let code: String
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(language.lowercased())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.fgSecondaryDark)

                Spacer()

                Button(action: copyCode) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(.fgSecondaryDark)

                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(.fgSecondaryDark)
            }
            .padding(.horizontal, Spacing.md.rawValue)
            .frame(height: 28)
            .background(Color.bgSecondaryDark)

            // Code Content
            ScrollView {
                HStack(alignment: .top, spacing: 0) {
                    // Line Numbers
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(Array(codeLines.enumerated()), id: \.offset) { index, _ in
                            Text("\(index + 1)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.fgTertiaryDark)
                                .frame(height: 18)
                        }
                    }
                    .frame(width: 40)
                    .padding(.trailing, Spacing.sm.rawValue)

                    // Code
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(codeLines.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.codeText)
                                .foregroundColor(.fgPrimaryDark)
                                .frame(height: 18, alignment: .top)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(Spacing.sm.rawValue)
            }
            .frame(maxHeight: isExpanded ? .none : 200)
            .background(Color.codeBgDark)
        }
        .cornerRadius(BorderRadius.md.rawValue)
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadius.md.rawValue)
                .stroke(Color.bgTertiaryDark, lineWidth: 1)
        )
    }

    private var codeLines: [String] {
        code.components(separatedBy: "\n")
    }

    private func copyCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
    }
}
```

---

## 5. Animation Specifications

### 5.1 Timing Standards

| Type | Duration | Easing |
|------|----------|--------|
| Fast (hover, selection) | 100ms | ease-out |
| Normal (expand/collapse) | 200ms | ease-out |
| Slow (view transitions) | 300ms | ease-in-out |
| Connection pulse | 1500ms | ease-in-out |
| Typing indicator | 1400ms | linear |

### 5.2 SwiftUI Animation Presets

```swift
extension Animation {
    static let fast = Animation.easeOut(duration: 0.1)
    static let normal = Animation.easeOut(duration: 0.2)
    static let slow = Animation.easeInOut(duration: 0.3)
    static let pulse = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
}
```

---

## 6. Responsive Behavior

### 6.1 Window Width Breakpoints

| Width | Sidebar | Message Bubble Max Width |
|-------|---------|-------------------------|
| > 1000px | Full (220px) | 80% |
| 800-1000px | Collapsed (48px) | 90% |
| < 800px | Hidden (overlay) | 95% |

### 6.2 SwiftUI Responsive Implementation

```swift
struct ResponsiveLayout: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        GeometryReader { geometry in
            let sidebarWidth = computeSidebarWidth(for: geometry.size.width)
            let messageMaxWidth = computeMessageMaxWidth(for: geometry.size.width)

            HStack(spacing: 0) {
                if sidebarWidth > 0 {
                    SidebarView()
                        .frame(width: sidebarWidth)
                }

                MainContentView(messageMaxWidth: messageMaxWidth)
            }
        }
    }

    private func computeSidebarWidth(for totalWidth: CGFloat) -> CGFloat {
        if totalWidth > 1000 { return 220 }
        if totalWidth > 800 { return 48 }
        return 0
    }

    private func computeMessageMaxWidth(for totalWidth: CGFloat) -> CGFloat {
        if totalWidth > 1000 { return totalWidth * 0.8 }
        if totalWidth > 800 { return totalWidth * 0.9 }
        return totalWidth * 0.95
    }
}
```

---

## 7. Accessibility Specifications

### 7.1 Color Contrast Requirements

All text must meet WCAG AA standards (4.5:1 for normal text, 3:1 for large text).

| Element | Contrast Ratio | Status |
|---------|----------------|--------|
| `fgPrimaryDark` on `bgPrimaryDark` | 10.5:1 | PASS |
| `fgSecondaryDark` on `bgPrimaryDark` | 5.4:1 | PASS |
| Code text on `codeBgDark` | 11.2:1 | PASS |

### 7.2 VoiceOver Labels

| Element | Accessibility Label |
|---------|---------------------|
| Session item | "Session: [title], Project: [name], [timestamp]" |
| Tool call | "[Tool name] tool call, [status]" |
| Connection status | "Connection status: [state]" |
| Diff line | "Line [number], [added/removed/unchanged]" |
| Send button | "Send message" |
| Input area | "Message input field" |

### 7.3 Focus Indicators

```swift
extension View {
    func focusIndicator() -> some View {
        self.focusable()
            .focusEffect {
                $0.overlay(
                    RoundedRectangle(cornerRadius: BorderRadius.sm.rawValue)
                        .stroke(Color.accentPrimary, lineWidth: 2)
                )
            }
    }
}
```

---

## 8. Keyboard Shortcuts

### 8.1 Global Shortcuts

| Shortcut | Action | Implementation |
|----------|--------|----------------|
| Cmd+N | New session | `.keyboardShortcut("n", modifiers: .command)` |
| Cmd+W | Close session | `.keyboardShortcut("w", modifiers: .command)` |
| Cmd+Shift+] | Next session | `.keyboardShortcut("]", modifiers: [.command, .shift])` |
| Cmd+Shift+[ | Previous session | `.keyboardShortcut("[", modifiers: [.command, .shift])` |
| Cmd+, | Open settings | `.keyboardShortcut(",", modifiers: .command)` |
| Cmd+Enter | Send message | `.keyboardShortcut(.return, modifiers: .command)` |
| Cmd+Shift+K | Clear conversation | `.keyboardShortcut("k", modifiers: [.command, .shift])` |
| Cmd+/ | Toggle sidebar | `.keyboardShortcut("/", modifiers: .command)` |

---

## 9. Design Review Checklist

### Phase 2 Compliance Verification

| Requirement | Status | Notes |
|-------------|--------|-------|
| Colors match design guide | PASS | All hex values aligned |
| Typography matches design guide | PASS | Font sizes and weights aligned |
| Spacing matches design guide | PASS | 4px/8px/12px/16px/24px/32px scale |
| Border radius matches design guide | PASS | 4px/8px/12px/16px scale |
| Window dimensions match | PASS | 800x600 min, 1200x800 default |
| Sidebar behavior responsive | PASS | Breakpoints at 800px, 1000px |
| Tool call states defined | PASS | Running/Success/Error/Pending |
| Diff colors consistent | PASS | Green added, Red removed |
| Accessibility compliant | PASS | WCAG AA contrast ratios |
| Animations specified | PASS | 100ms/200ms/300ms durations |

---

## 10. Implementation Notes

### 10.1 Required Third-Party Libraries

| Library | Purpose | SPM Dependency |
|---------|---------|----------------|
| MarkdownUI | Markdown rendering | `.package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "0.7.0")` |
| Highlightr | Syntax highlighting | `.package(url: "https://github.com/raspu/Highlightr", from: "1.2.0")` |

### 10.2 File Structure Recommendation

```
Sources/
  Theme/
    Colors.swift
    Typography.swift
    Spacing.swift
    DesignTokens.swift
  Models/
    Session.swift
    Message.swift
    ToolCall.swift
    Diff.swift
  ViewModels/
    SessionViewModel.swift
    MessageViewModel.swift
    InputViewModel.swift
  Views/
    Components/
      SessionListItemView.swift
      MessageBubbleView.swift
      ToolCallCardView.swift
      DiffView.swift
      CodeBlockView.swift
      InputAreaView.swift
    Sidebar/
      SidebarView.swift
    MainContent/
      ConversationView.swift
      MessageListView.swift
    Root/
      ContentView.swift
      MainWindow.swift
```

---

## 11. Phase 3 Enhanced Components

This section contains UI specifications for Phase 3 enhanced features, following the design principles established in the UI Design Guide.

### Phase 3 Design Compliance Status

| Feature | Design Guide Compliance | Notes |
|---------|------------------------|-------|
| Code Highlighting | COMPLIANT | Themes use design system colors |
| Image Upload | COMPLIANT | Matches input area styling |
| Keyboard Shortcuts Panel | COMPLIANT | Consistent with modal patterns |
| History Search | COMPLIANT | Matches sidebar styling |
| CLAUDE.md Editor | COMPLIANT | Consistent with editor patterns |
| Project Switcher | COMPLIANT | Matches dropdown patterns |

---

### 11.1 Code Block with Syntax Highlighting

#### Dimensions
| Property | Value |
|----------|-------|
| Header Height | 32px |
| Border Radius | 8px |
| Content Padding | 12px |
| Line Number Width | 40px |
| Max Height (collapsed) | 400px |
| Min Visible Lines | 5 |

#### Code Theme Colors (Dark Mode)

**One Dark Theme:**
| Token | Hex | Usage |
|-------|-----|-------|
| `codeKeywordOneDark` | `#C678DD` | Keywords (purple) |
| `codeStringOneDark` | `#98C379` | Strings (green) |
| `codeCommentOneDark` | `#5C6370` | Comments (gray) |
| `codeFunctionOneDark` | `#61AFEF` | Functions (blue) |
| `codeVariableOneDark` | `#E06C75` | Variables (red) |
| `codeNumberOneDark` | `#D19A66` | Numbers (orange) |

**Dracula Theme:**
| Token | Hex | Usage |
|-------|-----|-------|
| `codeKeywordDracula` | `#FF79C6` | Keywords (pink) |
| `codeStringDracula` | `#F1FA8C` | Strings (yellow) |
| `codeCommentDracula` | `#6272A4` | Comments (blue-gray) |
| `codeFunctionDracula` | `#50FA7B` | Functions (green) |
| `codeVariableDracula` | `#F8F8F2` | Variables (white) |
| `codeNumberDracula` | `#BD93F9` | Numbers (purple) |

**Monokai Theme:**
| Token | Hex | Usage |
|-------|-----|-------|
| `codeKeywordMonokai` | `#F92672` | Keywords (pink) |
| `codeStringMonokai` | `#E6DB74` | Strings (yellow) |
| `codeCommentMonokai` | `#75715E` | Comments (gray) |
| `codeFunctionMonokai` | `#A6E22E` | Functions (green) |
| `codeVariableMonokai` | `#FD971F` | Variables (orange) |
| `codeNumberMonokai` | `#AE81FF` | Numbers (purple) |

**Nord Theme:**
| Token | Hex | Usage |
|-------|-----|-------|
| `codeKeywordNord` | `#81A1C1` | Keywords (blue) |
| `codeStringNord` | `#A3BE8C` | Strings (green) |
| `codeCommentNord` | `#616E88` | Comments (gray) |
| `codeFunctionNord` | `#88C0D0` | Functions (cyan) |
| `codeVariableNord` | `#D8DEE9` | Variables (white) |
| `codeNumberNord` | `#B48EAD` | Numbers (purple) |

#### Light Theme Colors

**GitHub Light Theme:**
| Token | Hex | Usage |
|-------|-----|-------|
| `codeKeywordGitHubLight` | `#D73A49` | Keywords (red) |
| `codeStringGitHubLight` | `#032F62` | Strings (blue) |
| `codeCommentGitHubLight` | `#6A737D` | Comments (gray) |
| `codeFunctionGitHubLight` | `#6F42C1` | Functions (purple) |
| `codeVariableGitHubLight` | `#E36209` | Variables (orange) |
| `codeNumberGitHubLight` | `#005CC5` | Numbers (blue) |

#### Layout Structure

```
+----------------------------------------------------------+
|  swift                          [Copy] [Expand] [Theme ▾]|
+----------------------------------------------------------+
|   1 | import Foundation                                    |
|   2 |                                                      |
|   3 | struct APIClient {                                   |
|   4 |     let baseURL: URL                                 |
|   ...| ...                                                  |
+----------------------------------------------------------+
|  125 lines | Shift+Click to expand all                    |
+----------------------------------------------------------+
```

#### Header Buttons
| Button | Icon | Size | Hover Color |
|--------|------|------|-------------|
| Copy | `doc.on.doc` | 14px | `accentPrimary` |
| Expand | `arrow.down.right.and.arrow.up.left` | 14px | `fgPrimaryDark` |
| Theme | `paintpalette` | 14px | `fgSecondaryDark` |

#### Language Tags
| Property | Value |
|----------|-------|
| Font | SF Mono 11pt Medium |
| Color | `fgSecondaryDark` (#9D9D9D) |
| Background | `bgSecondaryDark` (#252526) |
| Padding | 4px 8px |

---

### 11.2 Image Upload Component

#### Dimensions
| Property | Value |
|----------|-------|
| Preview Thumbnail | 100x100px |
| Preview Border Radius | 8px |
| Max Preview Count | 5 visible (scroll for more) |
| Drop Zone Min Height | 120px |
| Progress Bar Height | 4px |

#### Drop Zone States

**Idle State:**
```
+----------------------------------------------------------+
|                                                          |
|           [Image Icon 48x48]                             |
|                                                          |
|           Drop image here                                |
|           or click to browse                             |
|                                                          |
|           Supports: JPG, PNG, GIF, WebP (max 10MB)       |
|                                                          |
+----------------------------------------------------------+
```

**Drag Hover State:**
```
+----------------------------------------------------------+
|  ┌ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ┐  |
|  ║                                                      ║  |
|  ║              Drop to upload image                    ║  |
|  ║                                                      ║  |
|  └ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ┘  |
+----------------------------------------------------------+
```

**Drop Zone Colors:**
| State | Border Color | Background |
|-------|--------------|------------|
| Idle | `fgTertiaryDark` (#6B6B6B) | transparent |
| Drag Hover | `accentPrimary` (#0A84FF) | `accentPrimary` 5% opacity |
| Error | `accentError` (#FF453A) | `statusDisconnectedBg` (#3D1F1E) |

#### Image Preview Item

```
+-------------------+
| [Image 100x100] X |  <- Remove button
|                   |
|-------------------|
| screenshot.png    |  <- Filename overlay
| 245 KB            |  <- Size overlay
+-------------------+
```

#### Preview Item Colors
| Element | Color |
|---------|-------|
| Background | `bgTertiaryDark` (#2D2D30) |
| Remove Button | White with black 50% opacity background |
| Filename Text | White on black 60% opacity background |
| Size Text | `fgSecondaryDark` on black 60% opacity background |

#### Upload Progress Bar
| Property | Value |
|----------|-------|
| Height | 4px |
| Background | `fgTertiaryDark` (#6B6B6B) |
| Fill Color | `accentPrimary` (#0A84FF) |
| Border Radius | 2px |

#### File Size Limits
| Format | Max Size | Display Text |
|--------|----------|--------------|
| JPEG | 10 MB | "10 MB max" |
| PNG | 10 MB | "10 MB max" |
| GIF | 5 MB | "5 MB max" |
| WebP | 10 MB | "10 MB max" |

---

### 11.3 File Attachment Component

#### Dimensions
| Property | Value |
|----------|-------|
| Item Height | 48px |
| Icon Size | 32x32px |
| Border Radius | 8px |
| Container Padding | 8px |

#### Layout Structure

```
+----------------------------------------------------------+
|  [Icon 32x32]  filename.swift                   [X]      |
|                12.5 KB | 245 lines                       |
+----------------------------------------------------------+
```

#### File Type Icons & Colors
| Type | Icon | Color |
|------|------|-------|
| Swift | `swift` | Orange (#F05138) |
| Python | `chevron.left.forwardslash.chevron.right` | Blue (#3776AB) |
| JavaScript | `chevron.left.forwardslash.chevron.right` | Yellow (#F7DF1E) |
| TypeScript | `chevron.left.forwardslash.chevron.right` | Blue (#3178C6) |
| JSON | `curlybraces` | Yellow (#CB8C07) |
| Markdown | `doc.text` | Blue (#083FA1) |
| YAML | `doc.text` | Red (#CB171E) |
| Generic | `doc` | Gray (#8E8E93) |

#### Attachment Container Colors
| Element | Color |
|---------|-------|
| Background | `bgTertiaryDark` (#2D2D30) |
| Border | `bgElevatedDark` (#3C3C3C) |
| Filename Text | `fgPrimaryDark` (#CCCCCC) |
| File Info Text | `fgTertiaryDark` (#6B6B6B) |
| Remove Button | `fgSecondaryDark` (#9D9D9D) |

---

### 11.4 Keyboard Shortcuts Help Panel

#### Dimensions
| Property | Value |
|----------|-------|
| Panel Width | 480px |
| Panel Max Height | 600px |
| Header Height | 48px |
| Section Header Height | 36px |
| Row Height | 36px |
| Shortcut Key Min Width | 140px |
| Padding | 16px |

#### Layout Structure

```
+----------------------------------------------------------+
|  Keyboard Shortcuts                              [Close] |
+----------------------------------------------------------+
|  General                                                 |
|  ─────────────────────────────────────────────────────── |
|  Cmd + N          New session                     36px   |
|  Cmd + W          Close session                          |
|  Cmd + Enter      Send message                           |
|  Cmd + Shift + K  Clear conversation                     |
|                                                          |
|  Navigation                                              |
|  ─────────────────────────────────────────────────────── |
|  Cmd + Shift + ]  Next session                           |
|  Cmd + Shift + [  Previous session                       |
|  Cmd + P          Quick project switch                   |
|  Cmd + /          Toggle sidebar                         |
|                                                          |
|  Editor                                                  |
|  ─────────────────────────────────────────────────────── |
|  Cmd + Shift + C  Insert code block                      |
|  Cmd + Shift + I  Insert image                           |
|  Cmd + Shift + A  Attach file                            |
|                                                          |
|  ─────────────────────────────────────────────────────── |
|                          [Edit Shortcuts...]             |
+----------------------------------------------------------+
```

#### Typography
| Element | Font | Size | Weight |
|---------|------|------|--------|
| Panel Title | San Francisco | 17pt | Semibold |
| Section Header | San Francisco | 13pt | Semibold |
| Shortcut Key | SF Mono | 13pt | Regular |
| Action Description | San Francisco | 13pt | Regular |
| Edit Button | San Francisco | 13pt | Regular |

#### Colors (Dark Mode)
| Element | Color |
|---------|-------|
| Panel Background | `bgElevatedDark` (#3C3C3C) |
| Header Background | `bgSecondaryDark` (#252526) |
| Section Header | `fgSecondaryDark` (#9D9D9D) |
| Shortcut Key Background | `bgTertiaryDark` (#2D2D30) |
| Shortcut Key Text | `fgPrimaryDark` (#CCCCCC) |
| Action Text | `fgPrimaryDark` (#CCCCCC) |
| Divider | `bgTertiaryDark` (#2D2D30) |

#### Shortcut Key Badge Style
| Property | Value |
|----------|-------|
| Background | `bgTertiaryDark` (#2D2D30) |
| Border Radius | 4px |
| Padding | 4px 8px |
| Min Width | 30px (single key) |
| Text Alignment | Center |

#### Keyboard Shortcut Modifiers Display
| Modifier | Symbol | Display |
|----------|--------|---------|
| Command | `Cmd` or Command symbol | `Cmd` |
| Shift | `Shift` or Shift symbol | `Shift` |
| Control | `Ctrl` or Control symbol | `Ctrl` |
| Option | `Option` or Option symbol | `Option` |

---

### 11.5 History Search Panel

#### Dimensions
| Property | Value |
|----------|-------|
| Search Input Height | 40px |
| Filter Row Height | 32px |
| Result Item Height | 72px |
| Result Preview Lines | 2 lines |
| Panel Width (sidebar mode) | 320px |
| Panel Width (modal mode) | 600px |

#### Layout Structure (Modal Mode)

```
+----------------------------------------------------------+
|  [Search Icon] Search history...              [Filters ▾]|
+----------------------------------------------------------+
|  Time: [All Time ▾]    Project: [All Projects ▾]         |
+----------------------------------------------------------+
|  Results for "API integration" (12 matches)              |
+----------------------------------------------------------+
|  [Icon] API Integration Help                             |
|         claude-desktop-mac | Mar 28, 2026                |
|         "...need help with **API integration** for..."   |
+----------------------------------------------------------+
|  [Icon] Debugging API Error                              |
|         my-api-project | Mar 25, 2026                    |
|         "...the **API** returns 500 error when..."       |
+----------------------------------------------------------+
```

#### Search Input Colors
| Element | Normal | Focused |
|---------|--------|---------|
| Background | `bgTertiaryDark` (#2D2D30) | `bgTertiaryDark` |
| Border | transparent | `accentPrimary` (#0A84FF) |
| Placeholder | `fgTertiaryDark` (#6B6B6B) | - |
| Text | `fgPrimaryDark` (#CCCCCC) | - |
| Search Icon | `fgTertiaryDark` (#6B6B6B) | `accentPrimary` |

#### Filter Dropdown
| Property | Value |
|----------|-------|
| Background | `bgTertiaryDark` (#2D2D30) |
| Border Radius | 4px |
| Padding | 6px 10px |
| Font Size | 12pt |
| Text Color | `fgSecondaryDark` (#9D9D9D) |
| Dropdown Icon | `chevron.down` 10px |

#### Result Item Colors
| Element | Normal | Hover | Selected |
|---------|--------|-------|----------|
| Background | transparent | `bgHoverDark` (#404040) | `bgSelectedDark` (#094771) |
| Title | `fgPrimaryDark` (#CCCCCC) | `fgPrimaryDark` | `fgInverseDark` (#FFFFFF) |
| Subtitle | `fgSecondaryDark` (#9D9D9D) | `fgSecondaryDark` | `fgSecondaryDark` |
| Preview | `fgSecondaryDark` (#9D9D9D) | `fgSecondaryDark` | `fgSecondaryDark` |

#### Search Highlight
| Property | Value |
|----------|-------|
| Highlight Background | `accentWarning` 30% opacity |
| Highlight Text Color | `accentWarning` (#FFD60A) |

#### Time Range Options
| Option | Display |
|--------|---------|
| Today | "Today" |
| Yesterday | "Yesterday" |
| This Week | "This Week" |
| This Month | "This Month" |
| Last 3 Months | "Last 3 Months" |
| All Time | "All Time" |

---

### 11.6 CLAUDE.md Editor

#### Dimensions
| Property | Value |
|----------|-------|
| Toolbar Height | 44px |
| Editor Min Height | 300px |
| Status Bar Height | 28px |
| Line Number Width | 40px |
| Template Picker Width | 300px |

#### Layout Structure

```
+----------------------------------------------------------+
|  CLAUDE.md Editor                          [Save] [Reset]|
+----------------------------------------------------------+
|  Template: [Default ▾]  [Edit] [Preview]                 |
+----------------------------------------------------------+
|   1 | # Project: claude-desktop-mac                      |
|   2 |                                                      |
|   3 | ## Overview                                          |
|   4 | A native macOS desktop application...               |
|   5 |                                                      |
|   6 | ## Architecture                                      |
|   7 | - SwiftUI for UI layer                               |
|   8 | - MVVM pattern                                       |
|   ...| ...                                                  |
+----------------------------------------------------------+
|  [Unsaved Changes]                    48 lines | 2.3 KB   |
+----------------------------------------------------------+
```

#### Editor Colors (Dark Mode)
| Element | Color |
|---------|-------|
| Background | `bgPrimaryDark` (#1E1E1E) |
| Line Numbers | `fgTertiaryDark` (#6B6B6B) |
| Text | `fgPrimaryDark` (#CCCCCC) |
| Selection | `bgSelectedDark` (#094771) |
| Cursor | `accentPrimary` (#0A84FF) |

#### Toolbar Button States
| Button | Enabled | Disabled |
|--------|---------|----------|
| Save | `accentPrimary` background | `fgTertiaryDark` text |
| Reset | `fgSecondaryDark` text | `fgTertiaryDark` text |
| Template | `fgSecondaryDark` text | - |

#### Status Bar States
| State | Icon | Color | Text |
|-------|------|-------|------|
| Saved | `checkmark.circle.fill` | `accentSuccess` (#30D158) | "Saved" |
| Unsaved | `circle.fill` | `accentWarning` (#FFD60A) | "Unsaved changes" |
| Error | `exclamationmark.circle.fill` | `accentError` (#FF453A) | "Save failed" |

#### Mode Toggle (Segmented Control)
| Property | Value |
|----------|-------|
| Width | 150px |
| Height | 24px |
| Selected Background | `accentPrimary` (#0A84FF) |
| Unselected Background | transparent |
| Selected Text | White |
| Unselected Text | `fgSecondaryDark` |

---

### 11.7 Project Switcher (Dropdown)

#### Dimensions
| Property | Value |
|----------|-------|
| Dropdown Width | 300px |
| Max Height | 400px |
| Search Input Height | 36px |
| Project Item Height | 56px |
| Footer Height | 40px |

#### Layout Structure

```
+----------------------------------+
|  [Search Icon] Search projects...|
+----------------------------------+
|  Favorites                       |
|  ──────────────────────────────  |
|  [Star Fill] claude-desktop-mac  |  <- Current project
|              ~/projects/claude-  |
|              2 active sessions   |
+----------------------------------+
|  All Projects                    |
|  ──────────────────────────────  |
|  [Folder] my-api-project         |
|           ~/projects/my-api      |
|           Last active 2h ago     |
+----------------------------------+
|  [Folder] work-frontend          |
|           ~/work/frontend        |
|           Last active yesterday  |
+----------------------------------+
|  ──────────────────────────────  |
|  [+] Add New Project...          |
|      Manage Projects...          |
+----------------------------------+
```

#### Project Item Colors (Dark Mode)
| Element | Normal | Hover | Selected |
|---------|--------|-------|----------|
| Background | transparent | `bgHoverDark` (#404040) | `bgSelectedDark` (#094771) |
| Project Name | `fgPrimaryDark` (#CCCCCC) | `fgPrimaryDark` | `fgInverseDark` (#FFFFFF) |
| Path | `fgTertiaryDark` (#6B6B6B) | `fgTertiaryDark` | `fgTertiaryDark` |
| Session Count | `accentSuccess` (#30D158) | `accentSuccess` | `accentSuccess` |
| Favorite Icon | `accentWarning` (#FFD60A) | `accentWarning` | `accentWarning` |
| Folder Icon | `accentPrimary` (#0A84FF) | `accentPrimary` | `accentPrimary` |

#### Project Item Status Indicators
| Indicator | Icon | Color |
|-----------|------|-------|
| Has CLAUDE.md | `doc.text` | `fgTertiaryDark` (#6B6B6B) |
| Active Sessions | Text badge | `accentSuccess` (#30D158) |
| Favorite | `star.fill` | `accentWarning` (#FFD60A) |

#### Footer Actions
| Action | Icon | Color |
|--------|------|-------|
| Add Project | `plus` | `accentPrimary` (#0A84FF) |
| Manage Projects | `gearshape` | `fgSecondaryDark` (#9D9D9D) |

---

### 11.8 Markdown Table Rendering

#### Dimensions
| Property | Value |
|----------|-------|
| Cell Padding | 8px 12px |
| Header Height | 36px |
| Row Height | 32px |
| Border Width | 1px |

#### Table Colors (Dark Mode)
| Element | Color |
|---------|-------|
| Header Background | `bgTertiaryDark` (#2D2D30) |
| Header Text | `fgPrimaryDark` (#CCCCCC), Semibold |
| Even Row Background | transparent |
| Odd Row Background | `bgSecondaryDark` (#252526) |
| Border | `fgTertiaryDark` (#6B6B6B) |
| Cell Text | `fgPrimaryDark` (#CCCCCC) |

#### Layout Structure

```
+----------------------------------------------------------+
|  Name          | Type          | Description             |
|----------------|---------------|-------------------------|
|  id            | UUID          | Unique identifier       |
|  title         | String        | Session title           |
|  messages      | [Message]     | Array of messages       |
+----------------------------------------------------------+
```

---

### 11.9 Mermaid Diagram Container

#### Dimensions
| Property | Value |
|----------|-------|
| Container Padding | 16px |
| Border Radius | 8px |
| Min Height | 100px |
| Max Height | 500px (scrollable) |

#### Container Colors
| Element | Color |
|---------|-------|
| Background | `bgTertiaryDark` (#2D2D30) |
| Border | `bgElevatedDark` (#3C3C3C) |

#### Mermaid Theme Configuration
| Theme | Usage |
|-------|-------|
| `dark` | Dark mode in app |
| `default` | Light mode in app |

---

### 11.10 Drag and Drop Overlay

#### Dimensions
| Property | Value |
|----------|-------|
| Overlay Padding | 20px |
| Border Width | 2px dashed |
| Icon Size | 64x64px |
| Border Radius | 12px |

#### Drop Overlay Colors
| State | Border Color | Background | Icon Color |
|-------|--------------|------------|------------|
| Valid Drop | `accentPrimary` (#0A84FF) | `accentPrimary` 5% | `accentPrimary` |
| Invalid Drop | `accentError` (#FF453A) | `accentError` 5% | `accentError` |

#### Layout Structure

```
+----------------------------------------------------------+
|  ┌ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ┐  |
|  ║                                                      ║  |
|  ║                 [Upload Icon 64x64]                  ║  |
|  ║                                                      ║  |
|  ║              Drop to upload files                    ║  |
|  ║                                                      ║  |
|  ║         Supports: Images, Code files, Documents      ║  |
|  ║                                                      ║  |
|  └ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ┘  |
+----------------------------------------------------------+
```

---

## 12. Phase 3 Keyboard Shortcuts

### 12.1 Global Shortcuts (Application Active)

| Shortcut | Action | Implementation |
|----------|--------|----------------|
| Cmd+N | New session | `.keyboardShortcut("n", modifiers: .command)` |
| Cmd+W | Close session | `.keyboardShortcut("w", modifiers: .command)` |
| Cmd+Shift+] | Next session | `.keyboardShortcut("]", modifiers: [.command, .shift])` |
| Cmd+Shift+[ | Previous session | `.keyboardShortcut("[", modifiers: [.command, .shift])` |
| Cmd+P | Quick project switch | `.keyboardShortcut("p", modifiers: .command)` |
| Cmd+, | Open settings | `.keyboardShortcut(",", modifiers: .command)` |
| Cmd+/ | Toggle sidebar | `.keyboardShortcut("/", modifiers: .command)` |
| Cmd+F | Search history | `.keyboardShortcut("f", modifiers: .command)` |
| Cmd+? | Show shortcuts help | `.keyboardShortcut("?", modifiers: .command)` |

### 12.2 Message Input Shortcuts

| Shortcut | Action | Implementation |
|----------|--------|----------------|
| Cmd+Enter | Send message | `.keyboardShortcut(.return, modifiers: .command)` |
| Shift+Enter | New line | Default TextEditor behavior |
| Cmd+Shift+C | Insert code block | Custom handler |
| Cmd+Shift+I | Insert image | Custom handler |
| Cmd+Shift+A | Attach file | Custom handler |
| Escape | Cancel/clear | `.onKeyPress(.escape)` |

### 12.3 Conversation View Shortcuts

| Shortcut | Action | Context |
|----------|--------|---------|
| Cmd+Up | Scroll to top | Conversation view |
| Cmd+Down | Scroll to bottom | Conversation view |
| Up Arrow | Edit previous message | Input focused, empty text |
| Space | Expand/collapse tool call | Tool call focused |
| E | Expand all tool calls | Conversation focused |
| C | Collapse all tool calls | Conversation focused |

---

## 13. Phase 3 Animation Specifications

### 13.1 New Animations

| Animation | Duration | Easing | Usage |
|-----------|----------|--------|-------|
| Code expand/collapse | 200ms | ease-out | Code block max height change |
| Image preview appear | 150ms | ease-out | Image thumbnail fade in |
| Drop zone highlight | 100ms | ease-out | Border/background transition |
| Search result appear | 100ms | ease-out | Result item fade in |
| Project switcher open | 200ms | ease-out | Dropdown slide/fade |
| Shortcut panel open | 200ms | ease-out | Modal slide up |
| Typing indicator | 1400ms | ease-in-out | Three dots cycle |

### 13.2 SwiftUI Animation Extensions

```swift
extension Animation {
    static let codeExpand = Animation.easeOut(duration: 0.2)
    static let imageAppear = Animation.easeOut(duration: 0.15)
    static let dropHighlight = Animation.easeOut(duration: 0.1)
    static let searchResult = Animation.easeOut(duration: 0.1)
    static let dropdown = Animation.easeOut(duration: 0.2)
    static let modalSlide = Animation.easeOut(duration: 0.2)
}
```

---

## 14. Phase 3 Accessibility

### 14.1 VoiceOver Labels

| Element | Accessibility Label |
|---------|---------------------|
| Code block | "Code block, [language], [line count] lines" |
| Copy code button | "Copy code to clipboard" |
| Image preview | "Image, [filename], [dimensions], [size]" |
| Remove attachment | "Remove [filename]" |
| Drop zone | "Drop files here or click to browse" |
| Shortcut panel | "Keyboard shortcuts help" |
| Shortcut row | "[keys], [action description]" |
| Search input | "Search conversation history" |
| Search result | "[session title], [project], [timestamp]" |
| Project item | "[project name], [path], [session count] sessions" |
| CLAUDE.md editor | "Project configuration editor" |
| Save status | "[Saved/Unsaved changes]" |

### 14.2 Focus Navigation Order

1. Project switcher
2. Model selector
3. Sidebar (sessions list)
4. Conversation view
5. Message input area
6. Send button
7. Attach buttons

---

## 15. Phase 3 Third-Party Libraries

| Library | Purpose | SPM Dependency |
|---------|---------|----------------|
| Highlightr | Syntax highlighting | `.package(url: "https://github.com/raspu/Highlightr", from: "1.2.0")` |
| MarkdownUI | Markdown rendering | `.package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "0.7.0")` |
| Mermaid.js (via WebView) | Mermaid diagrams | CDN: `https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js` |

---

## 16. Phase 4 System Integration Components

This section contains UI specifications for Phase 4 system integration features, following the design principles established in the UI Design Guide.

### Phase 4 Design Compliance Status

| Feature | Design Guide Compliance | Notes |
|---------|------------------------|-------|
| MenuBar Icon | COMPLIANT | Follows macOS MenuBar conventions |
| Quick Ask Window | COMPLIANT | Consistent with app styling |
| Command Palette | COMPLIANT | Matches Spotlight-style patterns |
| Notification Layout | COMPLIANT | Follows macOS notification design |
| Spotlight Results | COMPLIANT | Matches system search result patterns |

---

### 16.1 MenuBar Icon Specifications

#### Dimensions
| Property | Value |
|----------|-------|
| Icon Size | 18x18 pt (standard MenuBar size) |
| Icon Format | Template Image (PNG/PDF) |
| Status Indicator Size | 6x6 pt |
| Status Indicator Position | Bottom-right corner, offset 2px |
| Tooltip Max Width | 200pt |

#### Icon States

| State | Icon | Color | Status Indicator | Animation |
|-------|------|-------|------------------|-----------|
| Connected | Claude Logo outline | System default (auto-adapts) | None | None |
| Connecting | Claude Logo outline | System default | Yellow dot (#FFD60A) | Pulse (1.5s cycle) |
| Disconnected | Claude Logo outline | System default | Red dot (#FF453A) | None |
| Has New Message | Claude Logo outline | System default | Blue dot (#0A84FF) | None |
| Processing | Claude Logo outline | System default | Animated spinner | Rotate (1s linear) |

#### Template Image Requirements

```
- Format: PNG with alpha channel or PDF vector
- Color: Black (#000000) with transparency
- Mode: Template image (isTemplate = true)
- Rendering: System automatically adapts to dark/light mode
- Stroke: 1.5pt for primary shapes
```

#### Status Indicator Animation

```swift
// Connecting pulse animation
Animation.easeInOut(duration: 1.5)
    .repeatForever(autoreverses: true)

// Processing rotation animation
Animation.linear(duration: 1.0)
    .repeatForever(autoreverses: false)
```

---

### 16.2 MenuBar Dropdown Menu

#### Dimensions
| Property | Value |
|----------|-------|
| Menu Width | Auto (content-based) |
| Status Bar Height | 44px |
| Menu Item Height | 22px |
| Section Header Height | 22px |
| Separator Height | 6px |
| Icon Size | 16x16px |
| Shortcut Key Width | 80px (right-aligned) |

#### Layout Structure

```
+------------------------------------------+
|  [Status Icon] Connected                  |  <- Status header (disabled)
|  Claude Code v1.2.3 | Model: Sonnet 4.6  |  <- Subtitle (disabled)
+------------------------------------------+
|  New Session                    Cmd+N     |  <- Action item
|  Quick Ask                Cmd+Shift+A    |
+------------------------------------------+
|  Recent Sessions                         |  <- Submenu header
|  ├─ API Integration           2h ago     |  <- Session item
|  ├─ Bug Fix Session        Yesterday    |
|  └─ Refactoring Work         Mar 28      |
+------------------------------------------+
|  Projects                                |
|  ├─ claude-desktop-mac        [Active]   |  <- Project item with badge
|  └─ my-api-project                       |
+------------------------------------------+
|  ────────────────────────────────────── |  <- Separator
|  Open Claude Desktop                     |
|  Settings...                   Cmd+,    |
|  ────────────────────────────────────── |
|  Quit Claude Desktop           Cmd+Q     |
+------------------------------------------+
```

#### Menu Item Colors (Dark Mode)
| Element | Normal | Hover | Disabled |
|---------|--------|-------|----------|
| Background | transparent | `bgHoverDark` (#404040) | transparent |
| Text | `fgPrimaryDark` (#CCCCCC) | `fgPrimaryDark` | `fgTertiaryDark` (#6B6B6B) |
| Shortcut Key | `fgTertiaryDark` | `fgTertiaryDark` | `fgTertiaryDark` |
| Status Indicator | Per state | Per state | `fgTertiaryDark` |

#### Menu Item Colors (Light Mode)
| Element | Normal | Hover | Disabled |
|---------|--------|-------|----------|
| Background | transparent | `bgHoverLight` (#E8E8E8) | transparent |
| Text | `fgPrimaryLight` (#333333) | `fgPrimaryLight` | `fgTertiaryLight` (#999999) |
| Shortcut Key | `fgTertiaryLight` | `fgTertiaryLight` | `fgTertiaryLight` |

#### Session Item in Menu
| Property | Value |
|----------|-------|
| Title Font | SF 13pt Regular |
| Timestamp Font | SF 11pt Regular |
| Timestamp Color | `fgTertiaryDark` (#6B6B6B) |
| Max Visible Sessions | 5 |

#### Project Badge Style
| Property | Value |
|----------|-------|
| Background | `accentPrimary` (#0A84FF) |
| Text | White (#FFFFFF) |
| Font | SF 10pt Medium |
| Border Radius | 4px |
| Padding | 2px 6px |

---

### 16.3 Quick Ask Window

#### Dimensions
| Property | Value |
|----------|-------|
| Window Width | 400 pt |
| Min Height | 200 pt |
| Max Height | 500 pt |
| Header Height | 44px |
| Response Preview Max Height | 150 pt |
| Input Area Min Height | 80 pt |
| Status Bar Height | 24px |
| Border Radius | 12px |
| Position Offset from MenuBar | 8px |

#### Window Properties
| Property | Value |
|----------|-------|
| Level | `NSPanel.Level.floating` |
| Collection Behavior | `canJoinAllSpaces`, `fullScreenAuxiliary` |
| Style Mask | `titled`, `closable`, `resizable`, `nonactivatingPanel` |
| Hides on Deactivate | true |
| Becomes Key Only When Needed | true |

#### Layout Structure

```
+----------------------------------------------------------+
|  [Claude Icon 20x20]  Quick Ask                  [Expand]|
+----------------------------------------------------------+
|                                                          |
|  [Mini Claude Icon 32x32]                                |
|                                                          |
|  How can I help you today?                               |
|                                                          |
+----------------------------------------------------------+
|  Previous Response:                                      |
|  ┌────────────────────────────────────────────────────┐  |
|  │ I've analyzed your code and found the issue...    │  |
|  │                                                    │  |
|  │ The function should return an optional type...     │  |
|  └────────────────────────────────────────────────────┘  |
|                                    [View Full Response]   |
+----------------------------------------------------------+
|  ┌────────────────────────────────────────────────────┐  |
|  │ Ask Claude anything...                             │  |
|  │                                                    │  |
|  └────────────────────────────────────────────────────┘  |
|  [Attach]                                     [Send]      |
+----------------------------------------------------------+
|  Project: claude-desktop-mac | Model: Sonnet 4.6         |
+----------------------------------------------------------+
```

#### Header Colors
| Element | Color |
|---------|-------|
| Background | `bgSecondaryDark` (#252526) |
| Claude Icon | `accentPurple` (#BF5AF2) |
| Title Text | `fgPrimaryDark` (#CCCCCC) |
| Expand Button | `fgSecondaryDark` (#9D9D9D) |

#### Response Preview Colors
| Element | Color |
|---------|-------|
| Background | `bgTertiaryDark` (#2D2D30) |
| Label Text | `fgSecondaryDark` (#9D9D9D) |
| Preview Text | `fgPrimaryDark` (#CCCCCC) |
| View Full Button | `accentPrimary` (#0A84FF) |

#### Input Area Colors
| Element | Normal | Focused |
|---------|--------|---------|
| Background | `bgTertiaryDark` (#2D2D30) | `bgTertiaryDark` |
| Border | `fgTertiaryDark` (#6B6B6B) | `accentPrimary` (#0A84FF) |
| Placeholder | `fgTertiaryDark` | - |
| Text | `fgPrimaryDark` (#CCCCCC) | - |

#### Status Bar Colors
| Element | Color |
|---------|-------|
| Background | `bgSecondaryDark` (#252526) |
| Project Name | `fgSecondaryDark` (#9D9D9D) |
| Model Name | `fgTertiaryDark` (#6B6B6B) |

#### Window Position Logic
```swift
// Position window below MenuBar icon
func positionWindow() {
    guard let screen = NSScreen.main,
          let statusItemButton = statusItem?.button else { return }

    let buttonFrame = statusItemButton.window?.convertToScreen(statusItemButton.frame) ?? .zero
    let screenFrame = screen.visibleFrame

    var x = buttonFrame.midX - windowFrame.width / 2
    var y = buttonFrame.origin.y - windowFrame.height - 8

    // Keep on screen
    x = max(screenFrame.minX, min(x, screenFrame.maxX - windowFrame.width))
    y = max(screenFrame.minY, y)

    setFrameOrigin(NSPoint(x: x, y: y))
}
```

---

### 16.4 Command Palette

#### Dimensions
| Property | Value |
|----------|-------|
| Window Width | 500 pt |
| Window Height | 400 pt |
| Search Field Height | 48px |
| Section Header Height | 28px |
| Command Row Height | 36px |
| Session Row Height | 48px |
| Icon Size | 20x20px |

#### Layout Structure

```
+----------------------------------------------------------+
|  [Search Icon] Quick Command...                          |
+----------------------------------------------------------+
|                                                          |
|  Recent Commands                                         |
|  ────────────────────────────────────────────────────── |
|  [N] New Session                               Cmd+N     |
|  [S] Switch to my-api-project                  Cmd+P     |
|  [C] Clear Conversation                     Cmd+Shift+K |
|                                                          |
|  Quick Actions                                           |
|  ────────────────────────────────────────────────────── |
|  [A] Quick Ask                          Cmd+Shift+A     |
|  [H] Search History                    Cmd+Shift+H     |
|  [M] Switch Model                      Cmd+Shift+M     |
|  [T] Toggle Theme                      Cmd+Shift+T     |
|                                                          |
|  Sessions                                                |
|  ────────────────────────────────────────────────────── |
|  [Icon] API Integration - claude-desktop-mac             |
|  [Icon] Bug Fix - my-api-project                         |
|  [Icon] Refactoring - work-project                       |
|                                                          |
+----------------------------------------------------------+
```

#### Search Field Colors
| Element | Normal | Focused |
|---------|--------|---------|
| Background | `bgSecondaryDark` (#252526) | `bgSecondaryDark` |
| Text | `fgPrimaryDark` (#CCCCCC) | `fgPrimaryDark` |
| Placeholder | `fgTertiaryDark` (#6B6B6B) | - |
| Search Icon | `fgTertiaryDark` | `accentPrimary` |

#### Section Header Style
| Property | Value |
|----------|-------|
| Font | SF 12pt Semibold |
| Color | `fgSecondaryDark` (#9D9D9D) |
| Padding | 8px horizontal, 8px vertical |
| Background | transparent |

#### Command Row Colors
| Element | Normal | Hover | Selected |
|---------|--------|-------|----------|
| Background | transparent | `bgHoverDark` (#404040) | `bgSelectedDark` (#094771) |
| Icon | `accentPrimary` (#0A84FF) | `accentPrimary` | `fgInverseDark` |
| Command Name | `fgPrimaryDark` (#CCCCCC) | `fgPrimaryDark` | `fgInverseDark` |
| Shortcut Key | `fgTertiaryDark` (#6B6B6B) | `fgTertiaryDark` | `fgSecondaryDark` |

#### Session Row Colors
| Element | Normal | Hover | Selected |
|---------|--------|-------|----------|
| Background | transparent | `bgHoverDark` | `bgSelectedDark` |
| Icon | `accentPurple` (#BF5AF2) | `accentPurple` | `fgInverseDark` |
| Title | `fgPrimaryDark` | `fgPrimaryDark` | `fgInverseDark` |
| Subtitle | `fgSecondaryDark` (#9D9D9D) | `fgSecondaryDark` | `fgSecondaryDark` |

#### Keyboard Navigation
| Key | Action |
|-----|--------|
| Up/Down Arrow | Navigate through results |
| Enter | Execute selected command |
| Escape | Close palette |
| Tab | Focus next section |

---

### 16.5 Global Shortcuts Configuration Panel

#### Dimensions
| Property | Value |
|----------|-------|
| Panel Width | 520pt |
| Panel Max Height | 600pt |
| Header Height | 48px |
| Section Header Height | 32px |
| Row Height | 40px |
| Shortcut Input Width | 180px |
| Padding | 16px |

#### Layout Structure

```
+----------------------------------------------------------+
|  Keyboard Shortcuts                              [Reset] |
+----------------------------------------------------------+
|                                                          |
|  Global Shortcuts                                        |
|  ────────────────────────────────────────────────────── |
|  Show Quick Ask              [  Cmd + Shift + A  ] [×]   |
|  Show Command Palette        [  Cmd + Shift + P  ] [×]   |
|  New Session                 [  Cmd + N          ] [×]   |
|                                                          |
|  Application Shortcuts                                   |
|  ────────────────────────────────────────────────────── |
|  Send Message                [  Cmd + Enter      ] [×]   |
|  Toggle Sidebar              [  Cmd + /          ] [×]   |
|  Clear Conversation          [  Cmd + Shift + K  ] [×]   |
|                                                          |
|  Quick Actions                                           |
|  ────────────────────────────────────────────────────── |
|  Copy Last Code Block        [  Cmd + Shift + C  ] [×]   |
|  Apply Last Diff             [  Cmd + Shift + D  ] [×]   |
|                                                          |
|  [+] Add Custom Shortcut                                 |
|                                                          |
|  [Restore Defaults]                       [Save Changes] |
+----------------------------------------------------------+
```

#### Shortcut Input Field Style
| Property | Value |
|----------|-------|
| Background | `bgTertiaryDark` (#2D2D30) |
| Border | 1px `fgTertiaryDark` (#6B6B6B) |
| Border Radius | 6px |
| Padding | 6px 12px |
| Font | SF Mono 13pt |
| Text Color | `fgPrimaryDark` (#CCCCCC) |

#### Shortcut Input States
| State | Border Color | Behavior |
|-------|--------------|----------|
| Normal | `fgTertiaryDark` (#6B6B6B) | Display current shortcut |
| Recording | `accentPrimary` (#0A84FF) | Capture next key combination |
| Conflict | `accentError` (#FF453A) | Show conflict warning |

#### Remove Button Style
| Property | Value |
|----------|-------|
| Icon | `xmark.circle.fill` |
| Size | 16x16px |
| Color | `fgTertiaryDark` |
| Hover Color | `accentError` |

---

### 16.6 Spotlight Search Results

#### Result Item Dimensions
| Property | Value |
|----------|-------|
| Item Height | 72px |
| Icon Size | 32x32px |
| Title Max Lines | 1 |
| Subtitle Max Lines | 1 |
| Description Max Lines | 2 |

#### Result Item Layout

```
+----------------------------------------------------------+
|  [Claude Icon 32x32]  API Integration Help               |
|                       claude-desktop-mac - Mar 30, 2026   |
|                       "...need help with REST API..."     |
+----------------------------------------------------------+
```

#### Result Item Fields
| Field | Content |
|-------|---------|
| Icon | Claude Desktop app icon |
| Title | Session title |
| Subtitle | Project name - Date |
| Description | Session summary or matching content snippet |

#### Spotlight Indexing Keywords
| Category | Keywords |
|----------|----------|
| App Name | "Claude", "Claude Desktop", "AI Assistant" |
| Session | Session title, project name |
| Content | First 500 characters of searchable content |
| Type | "Claude Session", "AI Conversation" |

#### Deep Link URL Scheme
```
claude://session/{sessionId}
claude://project/{projectId}
claude://quickask
claude://settings
```

---

### 16.7 Notification Layouts

#### Base Notification Dimensions
| Property | Value |
|----------|-------|
| Min Width | 320pt |
| Max Width | 400pt |
| App Icon Size | 48x48px |
| Title Max Lines | 1 |
| Body Max Lines | 4 |
| Action Button Height | 32px |

#### Basic Notification Layout

```
+----------------------------------------------------------+
|  [Claude]                             claude-desktop-mac  |
+----------------------------------------------------------+
|  [Icon 48x48]  Response Complete                         |
|                                                          |
|  I've analyzed your code and found 3 issues that...     |
|                                                          |
|  [View] [Dismiss]                                        |
+----------------------------------------------------------+
```

#### Notification with Reply Input

```
+----------------------------------------------------------+
|  [Claude]                             claude-desktop-mac  |
+----------------------------------------------------------+
|  [Icon 48x48]  Needs Your Input                          |
|                                                          |
|  Should I apply these changes to api.swift?              |
|                                                          |
|  ┌────────────────────────────────────────────────────┐  |
|  │ Type your response...                              │  |
|  └────────────────────────────────────────────────────┘  |
|                                                          |
|  [Apply] [Reject] [View Full] [Reply]                    |
+----------------------------------------------------------+
```

#### Notification with Code Preview

```
+----------------------------------------------------------+
|  [Claude]                             claude-desktop-mac  |
+----------------------------------------------------------+
|  [Icon 48x48]  Code Suggestion                           |
|                                                          |
|  Here's the updated function for your API client:        |
|                                                          |
|  ┌────────────────────────────────────────────────────┐  |
|  │ func fetchData() async throws -> Data {            │  |
|  │     let url = baseURL.appendingPathComponent(id)   │  |
|  │     let (data, _) = try await URLSession...       │  |
|  │ }                                                  │  |
|  └────────────────────────────────────────────────────┘  |
|                                                          |
|  [Copy Code] [Apply to File] [View Full Response]        |
+----------------------------------------------------------+
```

#### Notification Colors
| Element | Color |
|---------|-------|
| Background | System default (auto-adapts) |
| App Name | System default |
| Title | System default |
| Body Text | System default |
| Code Background | #1A1A1A (dark) / #F6F8FA (light) |
| Code Text | #CCCCCC (dark) / #24292F (light) |

#### Notification Action Buttons
| Button | Action | Category |
|--------|--------|----------|
| View | Open session | All |
| Dismiss | Close notification | All |
| Reply | Show text input | INPUT_CATEGORY |
| Apply | Accept suggestion | CODE_CATEGORY |
| Reject | Decline suggestion | CODE_CATEGORY |
| Copy Code | Copy to clipboard | CODE_CATEGORY |
| Apply to File | Write to file | CODE_CATEGORY |

#### Notification Categories

| Category | Actions | Description |
|----------|---------|-------------|
| RESPONSE_CATEGORY | View, Dismiss | Claude finished responding |
| INPUT_CATEGORY | Reply, View, Dismiss | Claude needs user input |
| CODE_CATEGORY | Copy Code, Apply, View | Code suggestion available |
| TASK_CATEGORY | View, Dismiss | Long task completed |
| ERROR_CATEGORY | View, Dismiss | Error occurred |

---

### 16.8 Phase 4 Keyboard Shortcuts

#### Global Shortcuts (System-Wide)
| Shortcut | Action | Notes |
|----------|--------|-------|
| Cmd+Shift+C | Activate Claude Desktop | Bring app to front |
| Cmd+Shift+A | Open Quick Ask | Show mini window |
| Cmd+Shift+P | Open Command Palette | Quick commands panel |

#### Quick Ask Window Shortcuts
| Shortcut | Action |
|----------|--------|
| Cmd+Enter | Send message |
| Escape | Close window |
| Cmd+Shift+E | Expand to main window |

#### Command Palette Shortcuts
| Shortcut | Action |
|----------|--------|
| Up/Down | Navigate results |
| Enter | Execute command |
| Escape | Close palette |
| Tab | Next section |

---

### 16.9 Phase 4 Animations

#### New Animation Specifications
| Animation | Duration | Easing | Usage |
|-----------|----------|--------|-------|
| MenuBar status pulse | 1500ms | ease-in-out | Connecting indicator |
| MenuBar processing rotate | 1000ms | linear | Processing spinner |
| Quick Ask appear | 200ms | ease-out | Window fade/slide |
| Quick Ask expand | 300ms | ease-out | Transition to main window |
| Command palette appear | 200ms | ease-out | Window fade/slide |
| Notification appear | 150ms | ease-out | Banner slide in |

#### SwiftUI Animation Extensions

```swift
extension Animation {
    static let menuBarPulse = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
    static let menuBarRotate = Animation.linear(duration: 1.0).repeatForever(autoreverses: false)
    static let quickAskAppear = Animation.easeOut(duration: 0.2)
    static let commandPaletteAppear = Animation.easeOut(duration: 0.2)
    static let notificationBanner = Animation.easeOut(duration: 0.15)
}
```

---

### 16.10 Phase 4 Accessibility

#### VoiceOver Labels

| Element | Accessibility Label |
|---------|---------------------|
| MenuBar icon | "Claude Desktop, [status]" |
| MenuBar menu | "Claude Desktop menu" |
| Quick Ask window | "Claude Quick Ask" |
| Command palette | "Quick command search" |
| Shortcut input | "Shortcut for [action name]" |
| Spotlight result | "Claude session: [title], [project], [date]" |
| Notification | "Claude notification: [title]" |

#### Focus Navigation Order

**Quick Ask Window:**
1. Input text area
2. Send button
3. Attach button
4. Expand button
5. View Full Response link

**Command Palette:**
1. Search field
2. Command list
3. Session list

---

### 16.11 Phase 4 Implementation Notes

#### MenuBar Icon Asset Requirements

```
Assets.xcassets/
├── MenuBarIcon.imageset/
│   ├── MenuBarIcon@1x.png    (18x18)
│   ├── MenuBarIcon@2x.png    (36x36)
│   └── MenuBarIcon@3x.png    (54x54)
├── MenuBarIconConnecting.imageset/
│   └── ... (same sizes)
├── MenuBarIconDisconnected.imageset/
│   └── ... (same sizes)
├── MenuBarIconNewMessage.imageset/
│   └── ... (same sizes)
└── MenuBarIconProcessing.imageset/
    └── ... (same sizes)
```

#### Required Entitlements (Info.plist)

```xml
<!-- URL Scheme -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>claude</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.claude.desktop</string>
    </dict>
</array>

<!-- Spotlight indexing -->
<key>NSUserActivityTypes</key>
<array>
    <string>CSSearchableItemActionType</string>
</array>
```

#### Required Permissions

| Permission | Purpose |
|------------|---------|
| Accessibility | Global keyboard shortcuts |
| Notifications | Desktop notifications |
| Spotlight Indexing | Session search |

---

## Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2026-03-30 | 1.0 | Initial component specifications document |
| 2026-03-30 | 1.1 | Added Phase 3 enhanced components (code highlighting, image/file upload, keyboard shortcuts, history search, CLAUDE.md editor, project switcher) |
| 2026-03-30 | 1.2 | Added Phase 4 system integration components (MenuBar icon, Quick Ask window, Command Palette, notifications, Spotlight results) |
