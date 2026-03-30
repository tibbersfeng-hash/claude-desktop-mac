# Claude Desktop Mac - UI Design Guide

> Version: 1.0
> Date: 2026-03-30
> Author: UI Designer Agent

---

## 1. Design Principles

### 1.1 Core Philosophy

Claude Desktop Mac is a **developer-focused native macOS application** that replaces the Claude Code CLI. The UI design follows these core principles:

1. **Native First** - Embrace macOS design language, feel like a natural extension of the system
2. **Developer-Centric** - Professional, efficient, no unnecessary visual noise
3. **Dark Mode Optimized** - Primary focus on dark theme, matching terminal/IDE aesthetics
4. **Minimalist & Functional** - Every element serves a purpose, no decorative excess
5. **Keyboard-Driven** - Support power users with keyboard shortcuts and navigation

### 1.2 Design Values

| Value | Description |
|-------|-------------|
| **Clarity** | Clear visual hierarchy, easy to scan and understand |
| **Efficiency** | Minimize clicks, support keyboard navigation, quick actions |
| **Reliability** | Stable appearance, consistent patterns, predictable behavior |
| **Professionalism** | Serious tone suitable for development work |

---

## 2. Color Scheme

### 2.1 Dark Theme (Primary)

Based on macOS system dark mode colors with developer tool conventions.

#### Background Colors

| Name | Hex | Usage |
|------|-----|-------|
| `bg-primary` | `#1E1E1E` | Main window background |
| `bg-secondary` | `#252526` | Sidebar, panels |
| `bg-tertiary` | `#2D2D30` | Cards, elevated surfaces |
| `bg-elevated` | `#3C3C3C` | Dropdowns, popovers |
| `bg-hover` | `#404040` | Hover state overlay |
| `bg-selected` | `#094771` | Selection highlight |

#### Foreground Colors

| Name | Hex | Usage |
|------|-----|-------|
| `fg-primary` | `#CCCCCC` | Primary text |
| `fg-secondary` | `#9D9D9D` | Secondary text, labels |
| `fg-tertiary` | `#6B6B6B` | Disabled text, hints |
| `fg-inverse` | `#FFFFFF` | Text on accent color |

#### Accent Colors

| Name | Hex | Usage |
|------|-----|-------|
| `accent-primary` | `#0A84FF` | Primary actions, links (macOS system blue) |
| `accent-success` | `#30D158` | Success states, connected |
| `accent-warning` | `#FFD60A` | Warning states |
| `accent-error` | `#FF453A` | Error states, disconnected |
| `accent-purple` | `#BF5AF2` | AI/Assistant elements |

#### Code & Syntax Colors

| Name | Hex | Usage |
|------|-----|-------|
| `code-bg` | `#1A1A1A` | Code block background |
| `code-keyword` | `#FC5FA3` | Keywords |
| `code-string` | `#FC6A5D` | Strings |
| `code-comment` | `#73C991` | Comments |
| `code-function` | `#67B7A4` | Functions |
| `code-variable` | `#9CDCFE` | Variables |
| `code-number` | `#B4CECF` | Numbers |

### 2.2 Light Theme (Secondary)

For users who prefer light mode.

#### Background Colors

| Name | Hex | Usage |
|------|-----|-------|
| `bg-primary` | `#FFFFFF` | Main window background |
| `bg-secondary` | `#F3F3F3` | Sidebar, panels |
| `bg-tertiary` | `#EBEBEB` | Cards, elevated surfaces |
| `bg-elevated` | `#FAFAFA` | Dropdowns, popovers |
| `bg-hover` | `#E8E8E8` | Hover state overlay |
| `bg-selected` | `#0078D4` | Selection highlight |

#### Foreground Colors

| Name | Hex | Usage |
|------|-----|-------|
| `fg-primary` | `#333333` | Primary text |
| `fg-secondary` | `#666666` | Secondary text, labels |
| `fg-tertiary` | `#999999` | Disabled text, hints |

### 2.3 Connection Status Colors

Critical for the CLI connection layer visualization.

| Status | Color | Hex | Background |
|--------|-------|-----|------------|
| **Disconnected** | Red | `#FF453A` | Dark red tint `#3D1F1E` |
| **Connecting** | Yellow | `#FFD60A` | Yellow tint `#3D3A1E` |
| **Connected** | Green | `#30D158` | Green tint `#1E3D26` |
| **Error** | Red | `#FF453A` | Dark red tint `#3D1F1E` |
| **Reconnecting** | Orange | `#FF9F0A` | Orange tint `#3D2D1E` |

---

## 3. Typography

### 3.1 Font Stack

**Primary Font:** San Francisco (macOS system font)

```swift
// SwiftUI Font Usage
.title2          // 22pt, Semibold - Window titles
.title3          // 20pt, Semibold - Section headers
.headline        // 17pt, Semibold - Card titles
.body            // 17pt, Regular - Body text
.callout         // 16pt, Regular - Secondary text
.subheadline     // 15pt, Regular - Captions
.footnote        // 13pt, Regular - Hints, timestamps
.caption2        // 11pt, Regular - Labels
```

**Code Font:** SF Mono

```swift
// Code Typography
.system(.body, design: .monospaced)    // Code blocks
.system(.callout, design: .monospaced) // Inline code
.system(.caption, design: .monospaced) // Tool output
```

### 3.2 Font Sizes

| Element | Size | Weight | Line Height |
|---------|------|--------|-------------|
| Window Title | 22pt | Semibold | 28pt |
| Section Header | 20pt | Semibold | 26pt |
| Card Title | 17pt | Semibold | 22pt |
| Body Text | 15pt | Regular | 20pt |
| Code Text | 13pt | Regular | 18pt |
| Caption | 12pt | Regular | 16pt |
| Timestamp | 11pt | Regular | 14pt |

### 3.3 Text Colors by Context

| Context | Color | Notes |
|---------|-------|-------|
| User Message | `fg-primary` | Standard text |
| Assistant Message | `fg-primary` | Slightly lighter in dark mode |
| Code Block | `fg-primary` | On `code-bg` background |
| Inline Code | `fg-primary` | With subtle background |
| System Message | `fg-secondary` | Timestamps, status |
| Error Message | `accent-error` | Red text |
| Link | `accent-primary` | Underlined on hover |

---

## 4. Component Specifications

### 4.1 Window Layout

**Main Window Structure:**

```
+----------------------------------------------------------+
|  [Window Toolbar - Traffic lights + Title + Actions]      |
+----------------------------------------------------------+
|         |                                                 |
| Sidebar |              Main Content Area                  |
|  220px  |                                                 |
|         |                                                 |
| Sessions|          [Context-sensitive content]            |
| History |                                                 |
| Settings|                                                 |
|         |                                                 |
+---------+-------------------------------------------------+
|                    Status Bar (24px)                       |
+----------------------------------------------------------+
```

**Window Dimensions:**

| Property | Value |
|----------|-------|
| Minimum Width | 800px |
| Minimum Height | 600px |
| Default Width | 1200px |
| Default Height | 800px |
| Sidebar Width | 220px (collapsible to 48px) |

### 4.2 Sidebar

**Session List Item:**

```
+------------------------------------------+
|  [Icon]  Session Title                   |
|          Project Name         [Time]     |
+------------------------------------------+
```

- Height: 48px
- Icon Size: 24x24px
- Left Padding: 12px
- Active state: `bg-selected` background
- Hover state: `bg-hover` background

**Sidebar Sections:**

| Section | Content |
|---------|---------|
| Sessions | Active and recent sessions |
| Projects | Project shortcuts |
| Settings | App settings |

### 4.3 Connection Status Bar

**Critical for Phase 1 - CLI Connection Layer.**

**Layout:**

```
+------------------------------------------------------------------+
|  [Status Icon]  Connected to Claude Code v1.x.x   [Disconnect]   |
+------------------------------------------------------------------+
```

**Status Indicators:**

| State | Icon | Color | Animation |
|-------|------|-------|-----------|
| Disconnected | Circle fill | Red | None |
| Connecting | Circle dotted | Yellow | Pulse animation |
| Connected | Circle checkmark | Green | None |
| Error | Exclamation mark | Red | None |
| Reconnecting | Arrow clockwise | Orange | Rotate animation |

### 4.4 Message Bubbles

**User Message:**

```
+--------------------------------------------------+
|                                                  |
|  User's message text goes here...                |
|                                                  |
|                              14:32    [Edit]     |
+--------------------------------------------------+
```

- Background: `bg-tertiary`
- Border radius: 12px
- Padding: 12px 16px
- Max width: 80% of container
- Aligned to right

**Assistant Message:**

```
+--------------------------------------------------+
|  [Claude Icon]                                   |
|                                                  |
|  Assistant's response with markdown support...   |
|                                                  |
|  ```code block```                                |
|                                                  |
|  [Copy] [Regenerate]            14:33            |
+--------------------------------------------------+
```

- Background: `bg-secondary` or transparent
- Border radius: 12px
- Padding: 12px 16px
- Full width
- Aligned to left

### 4.5 Tool Call Visualization

**Critical for showing Claude's tool operations.**

**Tool Call Card:**

```
+------------------------------------------------------+
|  [Tool Icon]  Read File                    [v] [+ ] |
+------------------------------------------------------+
|  Arguments:                                          |
|  { "path": "/src/main.swift" }                       |
+------------------------------------------------------+
|  [Result]  [Expand]                    Duration: 0.3s|
+------------------------------------------------------+
|  Result:                                             |
|  file content preview...                             |
+------------------------------------------------------+
```

**Tool Types & Icons:**

| Tool | Icon | Color |
|------|------|-------|
| Read | doc.text | Blue |
| Write | square.and.pencil | Green |
| Edit | pencil.tip | Orange |
| Bash | terminal | Gray |
| Glob | magnifyingglass | Purple |
| Grep | text.magnifyingglass | Teal |

**Tool Call States:**

| State | Visual Treatment |
|-------|------------------|
| Running | Animated spinner, yellow accent |
| Success | Green checkmark, collapsible |
| Error | Red indicator, expanded by default |
| Pending | Gray, disabled appearance |

### 4.6 Diff Viewer

**For visualizing file changes.**

**Layout:**

```
+----------------------------------------------------------+
|  File: src/main.swift                           [Apply]  |
+----------------------------------------------------------+
|  -  1 | import Foundation                    |  +  1 |   |
|  -  2 |                                       |  +  2 |   |
|  -  3 | func old() {                          |        |   |
|        |                                       |  +  3 |   |
|        |                                       |  +  4 | func new() { |
+----------------------------------------------------------+
```

**Diff Colors:**

| Type | Background | Text |
|------|------------|------|
| Removed | `#3D1F1E` | `#FF6B6B` |
| Added | `#1E3D26` | `#6BCB77` |
| Modified | `#3D3A1E` | `#FFD93D` |
| Unchanged | Transparent | `fg-primary` |

**Line Numbers:**

- Width: 40px
- Color: `fg-tertiary`
- Font: SF Mono, 11pt

### 4.7 Input Area

**Message Input:**

```
+----------------------------------------------------------+
|  [Attach]                                         [Send] |
|  +----------------------------------------------------+  |
|  |                                                    |  |
|  |  Type your message...                              |  |
|  |                                                    |  |
|  +----------------------------------------------------+  |
|  Project: /workspace  |  Model: claude-sonnet-4.6      |
+----------------------------------------------------------+
```

**Specifications:**

| Property | Value |
|----------|-------|
| Min Height | 80px |
| Max Height | 300px (auto-scroll) |
| Padding | 12px |
| Border Radius | 12px |
| Background | `bg-tertiary` |
| Border | 1px `fg-tertiary` (focus: `accent-primary`) |

**Input Toolbar:**

| Action | Icon | Shortcut |
|--------|------|----------|
| Attach File | paperclip | Cmd+Shift+A |
| Attach Image | photo | Cmd+Shift+I |
| Code Block | chevron.left.forwardslash.chevron.right | Cmd+Shift+C |
| Send | paperplane.fill | Cmd+Enter |

---

## 5. Key Interface Layouts

### 5.1 Connection Status Interface (Phase 1)

**Purpose:** Display CLI connection state and controls.

**Layout Description:**

```
+----------------------------------------------------------+
|  Claude Desktop                              [_][□][×]    |
+----------------------------------------------------------+
|                                                          |
|                    [Claude Logo - Large]                 |
|                                                          |
|                                                          |
|              +-----------------------------+              |
|              |  Connection Status Card     |              |
|              |                             |              |
|              |  [Status Icon] Connected    |              |
|              |                             |              |
|              |  Claude Code CLI v1.2.3     |              |
|              |  /usr/local/bin/claude      |              |
|              |                             |              |
|              |  [Connect] [Disconnect]     |              |
|              +-----------------------------+              |
|                                                          |
|              +-----------------------------+              |
|              |  Quick Actions              |              |
|              |                             |              |
|              |  [New Session]  [Settings]  |              |
|              +-----------------------------+              |
|                                                          |
|                                                          |
+----------------------------------------------------------+
|  Status: Connected | Claude Code v1.2.3 | Model: Sonnet   |
+----------------------------------------------------------+
```

**Connection Flow States:**

1. **Initial State:**
   - Large Claude logo centered
   - "Detecting Claude Code CLI..." text with spinner
   - Gray/dimmed appearance

2. **CLI Not Found:**
   - Warning icon
   - "Claude Code CLI not found"
   - Installation instructions card
   - "Install Claude Code" button linking to docs
   - "Browse for CLI" option

3. **CLI Found, Disconnected:**
   - CLI version display
   - Path to CLI
   - Prominent "Connect" button
   - Model selection dropdown

4. **Connecting:**
   - Animated connecting state
   - Progress indicator
   - "Cancel" option

5. **Connected:**
   - Success indicator
   - Session ready message
   - Transition to main chat interface

### 5.2 Session List Interface

**Purpose:** Manage multiple Claude sessions.

**Layout Description:**

```
+----------------------------------------------------------+
|  Claude Desktop                              [_][□][×]    |
+----------------------------------------------------------+
| [+] Sessions                      |                       |
|----------------------------------|                       |
| [Icon] API Integration            |   +-------------+    |
|        claude-desktop-mac         |   |             |    |
|        2h ago            [×]      |   |   Empty     |    |
|----------------------------------|   |   State     |    |
| [Icon] Bug Fix Session            |   |             |    |
|        my-project                 |   |   Select a  |    |
|        Yesterday         [×]      |   |   session   |    |
|----------------------------------|   |             |    |
| [Icon] Refactoring                |   +-------------+    |
|        work-project               |                       |
|        Mar 28            [×]      |                       |
|----------------------------------|                       |
|                                   |                       |
| [Projects]                        |                       |
| [Settings]                        |                       |
+----------------------------------------------------------+
```

**Session Item Details:**

- Icon: Claude logo or project-specific
- Title: User-defined or auto-generated from first message
- Subtitle: Project name
- Timestamp: Relative time (2h ago, Yesterday, Mar 28)
- Hover actions: Close button appears

### 5.3 Main Conversation Interface

**Purpose:** Primary interaction area for Claude conversations.

**Layout Description:**

```
+----------------------------------------------------------+
|  Claude Desktop                    [Project] [Model] [×] |
+----------------------------------------------------------+
| [Sessions]  |                                             |
| [+]         |  +-------------------------------------+   |
|-------------|  | [Claude]                            |   |
| [Icon] API  |  |                                     |   |
|  Integration|  | I'll help you implement the API     |   |
|-------------|  | integration. Let me first check      |   |
| [Icon] Bug  |  | the existing code...                |   |
|  Fix        |  |                                     |   |
|-------------|  | +---------------------------------+ |   |
|             |  | | [Tool] Read File         [v][+] | |   |
|             |  | | path: /src/api/client.swift     | |   |
|             |  | | Result: 245 lines               | |   |
|             |  | +---------------------------------+ |   |
|             |  |                                     |   |
|             |  | Now I can see the structure...     |   |
|             |  +-------------------------------------+   |
|             |                                             |
|             |  +-------------------------------------+   |
|             |  |                                     |   |
|             |  | User message aligned right          |   |
|             |  |                                     |   |
|             |  |                      14:32  [Edit]  |   |
|             |  +-------------------------------------+   |
|             |                                             |
+----------------------------------------------------------+
|  [Attach]                                          [Send] |
|  +----------------------------------------------------+  |
|  | Type your message...                               |  |
|  +----------------------------------------------------+  |
|  Project: claude-desktop-mac | Model: claude-sonnet-4.6 |
+----------------------------------------------------------+
```

### 5.4 Tool Call Visualization Interface

**Purpose:** Show Claude's tool operations in real-time.

**Layout Description:**

**Collapsed State:**

```
+----------------------------------------------------------+
| [Tool Icon] Read File (3)                         [>]    |
+----------------------------------------------------------+
```

**Expanded State:**

```
+----------------------------------------------------------+
| [Tool Icon] Read File                             [v][+] |
+----------------------------------------------------------+
| Arguments:                                               |
| {                                                        |
|   "file_path": "/src/services/api.swift",                |
|   "limit": 100                                           |
| }                                                        |
+----------------------------------------------------------+
| Result: 245 lines read                          0.23s    |
+----------------------------------------------------------+
|  1 | import Foundation                                    |
|  2 |                                                      |
|  3 | struct APIClient {                                   |
|  4 |     let baseURL: URL                                 |
|  ...| ...                                                  |
+----------------------------------------------------------+
```

**Multiple Tool Calls:**

```
+----------------------------------------------------------+
| [Tool] Read File (api.swift)                     [v][+] |
+----------------------------------------------------------+
| [Tool] Grep "func.*api"                          [v][+] |
+----------------------------------------------------------+
| [Tool] Edit file                                 [v][+] |
+----------------------------------------------------------+
```

### 5.5 Diff View Interface

**Purpose:** Visualize file modifications.

**Layout Description:**

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

**Inline Diff Mode:**

```
+----------------------------------------------------------+
| File: src/services/api.swift                              |
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
```

---

## 6. Interaction Specifications

### 6.1 Keyboard Shortcuts

**Global Shortcuts:**

| Shortcut | Action |
|----------|--------|
| Cmd+N | New session |
| Cmd+W | Close current session |
| Cmd+Shift+] | Next session |
| Cmd+Shift+[ | Previous session |
| Cmd+, | Open settings |
| Cmd+Enter | Send message |
| Cmd+Shift+K | Clear conversation |
| Cmd+/ | Toggle sidebar |

**Message Navigation:**

| Shortcut | Action |
|----------|--------|
| Up Arrow | Edit previous message (when input focused) |
| Escape | Cancel current action |
| Cmd+Up | Scroll to top |
| Cmd+Down | Scroll to bottom |

**Tool Call Interactions:**

| Shortcut | Action |
|----------|--------|
| Space | Expand/collapse focused tool call |
| E | Expand all tool calls |
| C | Collapse all tool calls |

### 6.2 Mouse Interactions

**Session List:**

| Action | Behavior |
|--------|----------|
| Click | Select session |
| Double-click | Rename session |
| Right-click | Context menu (Delete, Duplicate, Export) |
| Drag | Reorder sessions |

**Message Area:**

| Action | Behavior |
|--------|----------|
| Click code | Copy code to clipboard |
| Double-click | Select word |
| Triple-click | Select paragraph |
| Right-click | Context menu (Copy, Select All, Search) |

**Tool Call Cards:**

| Action | Behavior |
|--------|----------|
| Click header | Expand/collapse |
| Click [+] | Copy result |
| Click [v] | View full output |

### 6.3 Animations

**Duration Standards:**

| Type | Duration |
|------|----------|
| Fast (hover, selection) | 100ms |
| Normal (expand/collapse) | 200ms |
| Slow (view transitions) | 300ms |

**Animation Types:**

1. **Connection Status Pulse**
   - Yellow connecting indicator
   - 1.5s duration, ease-in-out
   - Repeats until connected

2. **Tool Call Expand/Collapse**
   - Height animation
   - 200ms, ease-out

3. **Message Appear**
   - Fade in + slide up
   - 150ms, ease-out

4. **Typing Indicator**
   - Three dots animation
   - 1.4s cycle

### 6.4 Feedback States

**Loading States:**

```
+----------------------------------+
|  [Spinner]  Connecting to CLI... |
+----------------------------------+
```

**Error States:**

```
+----------------------------------+
|  [!] Connection Failed           |
|                                  |
|  Unable to connect to Claude     |
|  Code CLI. Please verify...      |
|                                  |
|  [Retry] [View Logs]             |
+----------------------------------+
```

**Empty States:**

```
+----------------------------------+
|                                  |
|      [Large Icon]                |
|                                  |
|      No sessions yet             |
|                                  |
|      Start a new conversation    |
|      to begin working with       |
|      Claude.                     |
|                                  |
|      [New Session]               |
+----------------------------------+
```

---

## 7. Responsive Considerations

### 7.1 Window Resizing

| Width | Sidebar Behavior |
|-------|------------------|
| > 1000px | Full sidebar (220px) |
| 800-1000px | Collapsed sidebar (48px icons only) |
| < 800px | Hidden sidebar (toggle to show overlay) |

### 7.2 Content Scaling

- Message bubbles max-width: 80% at 1200px, 90% at 800px
- Tool call cards: Always full width
- Code blocks: Horizontal scroll for long lines

---

## 8. Accessibility

### 8.1 Color Contrast

All text must meet WCAG AA standards:

| Element | Contrast Ratio |
|---------|----------------|
| Primary text on bg-primary | 10.5:1 |
| Secondary text on bg-primary | 5.4:1 |
| Code text on code-bg | 11.2:1 |

### 8.2 VoiceOver Support

| Element | Accessibility Label |
|---------|---------------------|
| Session item | "Session: [title], Project: [name], [timestamp]" |
| Tool call | "[Tool name] tool call, [status]" |
| Connection status | "Connection status: [state]" |
| Diff line | "Line [number], [added/removed/unchanged]" |

### 8.3 Focus Indicators

- Clear 2px outline on focus
- Visible focus ring for keyboard navigation
- Focus trap in modal dialogs

---

## 9. Design Tokens Summary

### 9.1 Spacing Scale

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon padding |
| sm | 8px | Tight spacing |
| md | 12px | Standard padding |
| lg | 16px | Card padding |
| xl | 24px | Section spacing |
| xxl | 32px | Major sections |

### 9.2 Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| sm | 4px | Small elements |
| md | 8px | Buttons, inputs |
| lg | 12px | Cards, bubbles |
| xl | 16px | Modals |
| full | 9999px | Pills, badges |

### 9.3 Shadows

| Token | Value | Usage |
|-------|-------|-------|
| sm | 0 1px 2px rgba(0,0,0,0.1) | Subtle elevation |
| md | 0 4px 8px rgba(0,0,0,0.15) | Cards |
| lg | 0 8px 16px rgba(0,0,0,0.2) | Modals, popovers |

---

## 10. Implementation Notes

### 10.1 SwiftUI Color Extensions

```swift
extension Color {
    // Background
    static let bgPrimary = Color(hex: "1E1E1E")
    static let bgSecondary = Color(hex: "252526")
    static let bgTertiary = Color(hex: "2D2D30")

    // Accent
    static let accentPrimary = Color(hex: "0A84FF")
    static let accentSuccess = Color(hex: "30D158")
    static let accentWarning = Color(hex: "FFD60A")
    static let accentError = Color(hex: "FF453A")
}
```

### 10.2 Semantic Color Usage

```swift
// Use semantic colors for theme support
extension Color {
    static var messageBackground: Color {
        ColorScheme.current == .dark ? .bgTertiary : .white
    }

    static var toolCallBackground: Color {
        ColorScheme.current == .dark ? .bgSecondary : .bgTertiary
    }
}
```

---

## 11. Reference Sources

This design guide draws inspiration from:

1. **macOS Human Interface Guidelines** - Native design patterns
2. **VS Code Dark Theme** - Developer tool color conventions
3. **Cursor AI** - AI coding assistant interface patterns
4. **Chatbox AI** - Multi-model chat UI patterns
5. **Xcode Interface** - macOS developer tool conventions

---

## Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2026-03-30 | 1.0 | Initial design guide |
