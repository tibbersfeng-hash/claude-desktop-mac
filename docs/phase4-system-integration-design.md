# Phase 4: 系统集成 - 功能设计文档

> 版本：1.0
> 日期：2026-03-30
> 作者：Product Manager Agent

---

## 一、功能概述

### 1.1 背景

Phase 3 已完成增强功能的构建，包括：
- 代码高亮与 Markdown 高级渲染
- 图片/文件上传支持
- 全面的快捷键系统
- 历史记录搜索与恢复
- 项目上下文管理（CLAUDE.md 可视化编辑）
- 多项目切换与管理

Phase 4 将深入 macOS 系统集成，实现：
- MenuBar 快捷入口 - 随时快速访问
- 全局快捷键 - 系统级快速唤起
- Spotlight 集成 - 系统搜索快速查找
- 通知中心集成 - 桌面通知与快速回复

### 1.2 目标

将 Claude Desktop 打造成真正融入 macOS 生态的原生应用：
- 无缝系统集成 - 像系统自带功能一样自然
- 即时访问 - 任何时刻都能快速唤起 Claude
- 智能通知 - 重要消息及时推送，支持快速操作
- 统一体验 - 与 macOS 系统功能深度整合

### 1.3 范围

**包含：**
- MenuBar 图标与状态显示
- MenuBar 快速操作菜单
- MenuBar 迷你窗口（Quick Ask）
- 系统级全局快捷键
- 快速命令面板
- Spotlight 搜索集成
- 会话快速查找
- 桌面通知推送
- 通知内快速回复
- 通知操作按钮

**不包含：**
- Siri 快捷指令集成 - Phase 5
- Shortcuts App 集成 - Phase 5
- Widgets 小组件 - Phase 5
- 性能深度优化 - Phase 5

---

## 二、用户故事

### US-1: MenuBar 快速访问

**作为** Claude Desktop 用户
**我希望** 能通过 MenuBar 快速访问常用功能
**以便于** 在不切换应用的情况下快速使用 Claude

**验收标准：**
- MenuBar 显示 Claude 图标
- 点击图标显示快速操作菜单
- 显示当前连接状态
- 提供快速新建会话入口
- 显示最近会话列表

### US-2: MenuBar Quick Ask

**作为** Claude Desktop 用户
**我希望** 能通过 MenuBar 快速提问
**以便于** 不打开完整窗口即可获取帮助

**验收标准：**
- 支持从 MenuBar 打开迷你窗口
- 迷你窗口支持快速输入和发送
- 支持查看最近的回复
- 可选择展开到完整窗口
- 支持快捷键快速唤起

### US-3: 全局快捷键唤起

**作为** Claude Desktop 用户
**我希望** 能使用全局快捷键快速唤起应用
**以便于** 在任何应用中快速切换到 Claude

**验收标准：**
- 支持自定义全局快捷键
- 默认快捷键合理且不冲突
- 应用隐藏时可唤起
- 唤起时自动聚焦输入框
- 支持多显示器环境

### US-4: 快速命令面板

**作为** Claude Desktop 用户
**我希望** 能通过快捷键打开快速命令面板
**以便于** 快速执行常用操作

**验收标准：**
- 支持模糊搜索命令
- 显示最近使用的会话
- 快速切换项目
- 快速切换模型
- 支持键盘导航

### US-5: Spotlight 搜索集成

**作为** Claude Desktop 用户
**我希望** 能通过 Spotlight 搜索我的会话
**以便于** 快速找到历史对话

**验收标准：**
- Spotlight 可搜索会话标题
- 搜索结果显示会话摘要
- 点击结果可打开对应会话
- 显示项目名称和时间
- 支持搜索会话内容

### US-6: 会话快速查找

**作为** Claude Desktop 用户
**我希望** 能在 Spotlight 中快速找到特定会话
**以便于** 快速恢复之前的工作

**验收标准：**
- 会话索引自动更新
- 支持按项目筛选
- 显示会话上下文摘要
- 支持深度链接直接跳转
- 索引创建不影响性能

### US-7: 桌面通知

**作为** Claude Desktop 用户
**我希望** 应用不在前台时能收到通知
**以便于** 知道 Claude 完成了任务或需要我的输入

**验收标准：**
- Claude 回复完成时发送通知
- 长任务完成时发送通知
- 需要用户输入时发送通知
- 通知显示消息摘要
- 点击通知可打开对应会话

### US-8: 通知快速回复

**作为** Claude Desktop 用户
**我希望** 能直接在通知中快速回复
**以便于** 不打开应用即可继续对话

**验收标准：**
- 通知支持文本输入
- 支持发送快速回复
- 支持预设回复选项
- 回复后可展开查看完整对话
- 支持语音输入回复

### US-9: 通知操作按钮

**作为** Claude Desktop 用户
**我希望** 通知中有操作按钮
**以便于** 快速执行常用操作

**验收标准：**
- 支持"复制代码"按钮
- 支持"应用到文件"按钮
- 支持"查看完整回复"按钮
- 支持"忽略"按钮
- 按钮操作符合上下文

---

## 三、界面布局说明

### 3.1 MenuBar 图标与状态

#### 3.1.1 图标状态设计

MenuBar 图标需要清晰传达应用状态。

**图标设计方案：**

| 状态 | 图标 | 颜色 | 说明 |
|------|------|------|------|
| 已连接 | Claude Logo | 系统默认色 | 正常状态 |
| 连接中 | Claude Logo + 动画点 | 黄色 | 连接过程中 |
| 断开连接 | Claude Logo + 红点 | 红色 | 未连接状态 |
| 有新消息 | Claude Logo + 蓝点 | 蓝色 | 有未读消息 |
| 处理中 | Claude Logo + 动画 | 动态 | Claude 正在处理 |

**图标规格：**
- 尺寸：18x18 pt (标准 MenuBar 图标尺寸)
- 格式：Template Image（支持深浅模式自动适配）
- 样式：单色轮廓，符合 macOS 设计规范

#### 3.1.2 MenuBar 下拉菜单

点击 MenuBar 图标显示下拉菜单：

```
+------------------------------------------+
|  [Status: Connected]                      |
|  Claude Code v1.2.3 | Model: Sonnet 4.6  |
+------------------------------------------+
|  New Session                    Cmd+N     |
|  Quick Ask                      Cmd+Shift+A |
+------------------------------------------+
|  Recent Sessions                         |
|  ├─ API Integration           2h ago     |
|  ├─ Bug Fix Session          Yesterday   |
|  └─ Refactoring Work         Mar 28      |
+------------------------------------------+
|  Projects                                |
|  ├─ claude-desktop-mac        [Active]   |
|  └─ my-api-project                       |
+------------------------------------------+
|  Open Claude Desktop                     |
|  ────────────────────────────────────── |
|  Settings...                             |
|  Quit Claude Desktop          Cmd+Q      |
+------------------------------------------+
```

**菜单项说明：**

| 菜单项 | 功能 | 快捷键 |
|--------|------|--------|
| 状态栏 | 显示连接状态、版本、模型 | - |
| New Session | 新建会话 | Cmd+N |
| Quick Ask | 打开快速提问窗口 | Cmd+Shift+A |
| Recent Sessions | 最近会话列表（最多 5 个） | - |
| Projects | 项目快速切换 | - |
| Open Claude Desktop | 打开/激活主窗口 | - |
| Settings | 打开设置 | - |
| Quit | 退出应用 | Cmd+Q |

### 3.2 Quick Ask 迷你窗口

#### 3.2.1 窗口设计

Quick Ask 是一个紧凑的浮动窗口，用于快速提问。

```
+----------------------------------------------------------+
|  [Claude]  Quick Ask                              [×][□]  |
+----------------------------------------------------------+
|                                                          |
|  [Mini Claude Icon]  How can I help you today?           |
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
|  [Expand to Full Window]                                 |
+----------------------------------------------------------+
```

#### 3.2.2 窗口规格

| 属性 | 值 |
|------|-----|
| 宽度 | 400 pt |
| 最小高度 | 200 pt |
| 最大高度 | 500 pt |
| 位置 | MenuBar 图标下方 |
| 层级 | NSPanel (浮动窗口) |
| 行为 | 可拖动、可调整高度 |
| 遮罩 | 点击外部区域关闭 |

#### 3.2.3 窗口行为

| 场景 | 行为 |
|------|------|
| 首次打开 | 显示欢迎提示 |
| 有历史记录 | 显示最近一条回复摘要 |
| 发送消息后 | 显示流式回复 |
| 点击外部 | 最小化到 MenuBar |
| 按 Escape | 关闭窗口 |
| 按 Cmd+Enter | 发送消息 |

### 3.3 全局快捷键面板

#### 3.3.1 快速命令面板

类似 Spotlight 的命令面板，支持模糊搜索。

```
+----------------------------------------------------------+
|  [Search Icon] Quick Command...                          |
+----------------------------------------------------------+
|                                                          |
|  +----------------------------------------------------+  |
|  | >                                                  |  |
|  +----------------------------------------------------+  |
|                                                          |
|  Recent Commands                                         |
|  ├─ [N] New Session                               Cmd+N  |
|  ├─ [S] Switch to my-api-project                  Cmd+P  |
|  └─ [C] Clear Conversation                     Cmd+Shift+K |
|                                                          |
|  Quick Actions                                           |
|  ├─ [A] Quick Ask                          Cmd+Shift+A    |
|  ├─ [H] Search History                    Cmd+Shift+H    |
|  ├─ [M] Switch Model                      Cmd+Shift+M    |
|  └─ [T] Toggle Theme                      Cmd+Shift+T    |
|                                                          |
|  Sessions                                                |
|  ├─ API Integration - claude-desktop-mac               |
|  ├─ Bug Fix - my-api-project                           |
|  └─ Refactoring - work-project                         |
|                                                          |
+----------------------------------------------------------+
```

#### 3.3.2 快捷键配置面板

在设置中提供快捷键自定义界面：

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

### 3.4 Spotlight 集成界面

#### 3.4.1 Spotlight 搜索结果

在 Spotlight 中显示会话搜索结果：

```
+----------------------------------------------------------+
|  [Search Icon] API integration                           |
+----------------------------------------------------------+
|                                                          |
|  Claude Desktop                                          |
|  ├─ API Integration Help                                 |
|  │   claude-desktop-mac - Mar 30, 2026                   |
|  │   "...need help with REST API integration..."         |
|  │                                                       |
|  ├─ Debugging API Error                                  |
|  │   my-api-project - Mar 28, 2026                       |
|  │   "...the API returns 500 error..."                   |
|  │                                                       |
|  └─ API Documentation Generator                          |
|      work-project - Mar 25, 2026                         |
|      "...generate documentation from OpenAPI..."         |
|                                                          |
+----------------------------------------------------------+
```

#### 3.4.2 搜索结果项设计

每个搜索结果包含：

| 字段 | 说明 |
|------|------|
| 图标 | Claude Desktop 应用图标 |
| 标题 | 会话标题 |
| 副标题 | 项目名称 - 时间 |
| 描述 | 会话摘要或匹配内容片段 |
| 类型 | "Claude Session" |

### 3.5 通知设计

#### 3.5.1 通知类型

| 类型 | 触发条件 | 示例 |
|------|----------|------|
| 回复完成 | Claude 完成回复 | "Claude has finished responding" |
| 长任务完成 | 长时间处理完成 | "Code analysis complete" |
| 需要输入 | Claude 需要用户输入 | "Claude needs your input" |
| 错误通知 | 发生错误 | "Connection lost" |
| 提醒通知 | 定时提醒 | "Remember to review changes" |

#### 3.5.2 通知布局

**基础通知：**

```
+----------------------------------------------------------+
|  [Claude]                             claude-desktop-mac  |
+----------------------------------------------------------+
|  [Icon]  Response Complete                               |
|                                                          |
|  I've analyzed your code and found 3 issues that...     |
|                                                          |
|  [View] [Dismiss]                                        |
+----------------------------------------------------------+
```

**带回复输入的通知：**

```
+----------------------------------------------------------+
|  [Claude]                             claude-desktop-mac  |
+----------------------------------------------------------+
|  [Icon]  Needs Your Input                                |
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

**带代码预览的通知：**

```
+----------------------------------------------------------+
|  [Claude]                             claude-desktop-mac  |
+----------------------------------------------------------+
|  [Icon]  Code Suggestion                                 |
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

#### 3.5.3 通知操作按钮

| 按钮 | 功能 | 适用场景 |
|------|------|----------|
| View | 打开会话查看完整内容 | 所有通知 |
| Dismiss | 关闭通知 | 所有通知 |
| Reply | 打开回复输入框 | 需要输入通知 |
| Copy Code | 复制代码到剪贴板 | 代码建议通知 |
| Apply to File | 应用修改到文件 | 代码修改通知 |
| Accept | 接受建议 | 决策类通知 |
| Reject | 拒绝建议 | 决策类通知 |

---

## 四、功能点详细设计

### 4.1 MenuBar 快捷入口

#### 4.1.1 功能点列表

| ID | 功能点 | 描述 | 优先级 |
|----|--------|------|--------|
| F4.1.1 | MenuBar 图标 | 显示应用图标和状态 | P0 |
| F4.1.2 | 状态指示器 | 显示连接/处理状态 | P0 |
| F4.1.3 | 下拉菜单 | 快速操作菜单 | P0 |
| F4.1.4 | 最近会话 | 最近 5 个会话快捷入口 | P1 |
| F4.1.5 | 项目切换 | 快速切换项目 | P1 |
| F4.1.6 | Quick Ask 迷你窗口 | 紧凑型快速提问窗口 | P0 |
| F4.1.7 | 迷你窗口流式回复 | 实时显示回复 | P0 |
| F4.1.8 | 展开到主窗口 | 从迷你窗口展开 | P1 |

#### 4.1.2 MenuBar 状态管理

```swift
enum MenuBarStatus {
    case connected
    case connecting
    case disconnected
    case hasNewMessage
    case processing

    var icon: NSImage {
        switch self {
        case .connected:
            return NSImage(named: "MenuBarIcon")!
        case .connecting:
            return NSImage(named: "MenuBarIconConnecting")!
        case .disconnected:
            return NSImage(named: "MenuBarIconDisconnected")!
        case .hasNewMessage:
            return NSImage(named: "MenuBarIconNewMessage")!
        case .processing:
            return NSImage(named: "MenuBarIconProcessing")!
        }
    }

    var statusText: String {
        switch self {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        case .hasNewMessage:
            return "New message"
        case .processing:
            return "Processing..."
        }
    }
}
```

#### 4.1.3 MenuBar 控制器设计

```swift
class MenuBarController: ObservableObject {
    @Published var status: MenuBarStatus = .disconnected
    @Published var recentSessions: [Session] = []
    @Published var projects: [Project] = []

    private var statusItem: NSStatusItem?

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.image = status.icon
        statusItem?.button?.imagePosition = .imageOnly
        statusItem?.menu = createMenu()
    }

    func updateStatus(_ newStatus: MenuBarStatus) {
        status = newStatus
        statusItem?.button?.image = newStatus.icon
        statusItem?.button?.toolTip = newStatus.statusText
    }

    private func createMenu() -> NSMenu {
        let menu = NSMenu()

        // Status section
        let statusItem = NSMenuItem(title: status.statusText, action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)

        menu.addItem(NSMenuItem.separator())

        // Quick actions
        menu.addItem(NSMenuItem(title: "New Session", action: #selector(newSession), keyEquivalent: "n"))
        menu.addItem(NSMenuItem(title: "Quick Ask", action: #selector(showQuickAsk), keyEquivalent: "a").withModifier(.shift))

        menu.addItem(NSMenuItem.separator())

        // Recent sessions
        let recentItem = NSMenuItem(title: "Recent Sessions", action: nil, keyEquivalent: "")
        recentItem.submenu = createRecentSessionsMenu()
        menu.addItem(recentItem)

        // Projects
        let projectsItem = NSMenuItem(title: "Projects", action: nil, keyEquivalent: "")
        projectsItem.submenu = createProjectsMenu()
        menu.addItem(projectsItem)

        menu.addItem(NSMenuItem.separator())

        // App controls
        menu.addItem(NSMenuItem(title: "Open Claude Desktop", action: #selector(openMainWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Quit Claude Desktop", action: #selector(quitApp), keyEquivalent: "q"))

        return menu
    }
}
```

#### 4.1.4 Quick Ask 窗口设计

```swift
struct QuickAskWindow: NSPanel {
    private let viewModel: QuickAskViewModel

    init(viewModel: QuickAskViewModel) {
        self.viewModel = viewModel

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.title = "Quick Ask"
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isFloatingPanel = true
        self.hidesOnDeactivate = true
        self.contentView = NSHostingView(rootView: QuickAskView(viewModel: viewModel))
    }

    func showNearMenuBar() {
        guard let screen = NSScreen.main,
              let statusItem = MenuBarController.shared.statusItem,
              let button = statusItem.button else { return }

        let buttonFrame = button.window?.convertToScreen(button.frame) ?? .zero
        let screenFrame = screen.visibleFrame

        var x = buttonFrame.origin.x - frame.width / 2
        var y = buttonFrame.origin.y - frame.height - 8

        // Ensure window stays on screen
        x = max(screenFrame.origin.x, min(x, screenFrame.origin.x + screenFrame.width - frame.width))
        y = max(screenFrame.origin.y, y)

        setFrameOrigin(NSPoint(x: x, y: y))
        makeKeyAndOrderFront(nil)
    }
}
```

#### 4.1.5 Quick Ask SwiftUI 视图

```swift
struct QuickAskView: View {
    @ObservedObject var viewModel: QuickAskViewModel
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image("ClaudeIconMini")
                    .resizable()
                    .frame(width: 24, height: 24)
                Text("Quick Ask")
                    .font(.headline)
                Spacer()
                Button(action: { viewModel.expandToMainWindow() }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.bgSecondary)

            Divider()

            // Response preview
            if let lastResponse = viewModel.lastResponse {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Previous Response:")
                            .font(.caption)
                            .foregroundColor(.fgSecondary)

                        Text(lastResponse.summary)
                            .font(.body)
                            .lineLimit(3)

                        Button("View Full Response") {
                            viewModel.expandToMainWindow()
                        }
                        .font(.caption)
                    }
                    .padding()
                }
                .frame(maxHeight: 150)
                .background(Color.bgTertiary)

                Divider()
            }

            // Input area
            VStack(spacing: 8) {
                TextEditor(text: $inputText)
                    .font(.body)
                    .frame(minHeight: 60, maxHeight: 150)
                    .focused($isInputFocused)
                    .padding(8)
                    .background(Color.bgTertiary)
                    .cornerRadius(8)

                HStack {
                    Button(action: { viewModel.attachFile() }) {
                        Image(systemName: "paperclip")
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("Project: \(viewModel.currentProject)")
                        .font(.caption)
                        .foregroundColor(.fgSecondary)

                    Button("Send") {
                        viewModel.sendMessage(inputText)
                        inputText = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(inputText.isEmpty)
                }
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 200, maxHeight: 500)
        .onAppear {
            isInputFocused = true
        }
    }
}
```

---

### 4.2 全局快捷键

#### 4.2.1 功能点列表

| ID | 功能点 | 描述 | 优先级 |
|----|--------|------|--------|
| F4.2.1 | 全局快捷键注册 | 系统级快捷键监听 | P0 |
| F4.2.2 | 快捷键唤起应用 | 全局唤起 Claude Desktop | P0 |
| F4.2.3 | Quick Ask 快捷键 | 快速打开迷你窗口 | P0 |
| F4.2.4 | 命令面板快捷键 | 打开快速命令面板 | P1 |
| F4.2.5 | 快捷键自定义 | 用户自定义快捷键 | P1 |
| F4.2.6 | 快捷键冲突检测 | 检测系统快捷键冲突 | P2 |
| F4.2.7 | 多显示器支持 | 多显示器环境下正确工作 | P1 |

#### 4.2.2 默认快捷键配置

| 功能 | 默认快捷键 | 说明 |
|------|------------|------|
| 唤起应用 | Cmd+Shift+C | 快速激活应用窗口 |
| Quick Ask | Cmd+Shift+A | 打开快速提问窗口 |
| 命令面板 | Cmd+Shift+P | 打开命令面板 |
| 新建会话 | Cmd+N | 新建会话 |
| 发送消息 | Cmd+Enter | 发送当前消息 |

#### 4.2.3 全局快捷键管理器

```swift
class GlobalShortcutManager: ObservableObject {
    static let shared = GlobalShortcutManager()

    @Published var shortcuts: [Shortcut] = []
    private var eventHandler: EventHandlerRef?

    struct Shortcut: Identifiable, Codable {
        let id: String
        let name: String
        let description: String
        var keyCode: UInt32
        var modifiers: NSEvent.ModifierFlags
        let action: String

        static let activateApp = Shortcut(
            id: "activate_app",
            name: "Activate Claude Desktop",
            description: "Bring Claude Desktop to front",
            keyCode: 8,  // C
            modifiers: [.command, .shift],
            action: "activateApp"
        )

        static let quickAsk = Shortcut(
            id: "quick_ask",
            name: "Quick Ask",
            description: "Open Quick Ask window",
            keyCode: 0,  // A
            modifiers: [.command, .shift],
            action: "showQuickAsk"
        )

        static let commandPalette = Shortcut(
            id: "command_palette",
            name: "Command Palette",
            description: "Open command palette",
            keyCode: 35,  // P
            modifiers: [.command, .shift],
            action: "showCommandPalette"
        )
    }

    func registerGlobalShortcuts() {
        // Request Accessibility permissions
        requestAccessibilityPermission()

        // Register keyboard event handler
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

        // Register each shortcut
        for shortcut in shortcuts {
            registerHotKey(shortcut)
        }
    }

    private func registerHotKey(_ shortcut: Shortcut) {
        var hotKeyID = EventHotKeyID()
        hotKeyID.id = UInt32(shortcuts.firstIndex(where: { $0.id == shortcut.id }) ?? 0)
        hotKeyID.signature = OSType(0x434C4445) // "CLDE"

        var hotKeyRef: EventHotKeyRef?

        let keyCode = shortcut.keyCode
        let modifiers = UInt32(shortcut.modifiers.rawValue)

        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
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
        if index < shortcuts.count {
            executeAction(shortcuts[index].action)
        }

        return noErr
    }

    private func executeAction(_ action: String) {
        DispatchQueue.main.async {
            switch action {
            case "activateApp":
                NSApp.activate(ignoringOtherApps: true)
            case "showQuickAsk":
                QuickAskWindowController.shared.showWindow()
            case "showCommandPalette":
                CommandPaletteController.shared.show()
            default:
                break
            }
        }
    }

    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
```

#### 4.2.4 命令面板设计

```swift
struct CommandPaletteView: View {
    @StateObject private var viewModel = CommandPaletteViewModel()
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.fgSecondary)

                TextField("Quick Command...", text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .onSubmit {
                        viewModel.executeSelectedCommand()
                    }
            }
            .padding()
            .background(Color.bgSecondary)

            Divider()

            // Results
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Recent commands
                    if searchText.isEmpty {
                        sectionHeader("Recent Commands")
                        ForEach(viewModel.recentCommands) { command in
                            commandRow(command)
                        }
                    }

                    // Filtered results
                    let results = viewModel.filterCommands(searchText)
                    if !results.isEmpty {
                        if !searchText.isEmpty {
                            sectionHeader("Commands")
                        }
                        ForEach(results) { command in
                            commandRow(command)
                        }
                    }

                    // Sessions
                    if searchText.isEmpty || viewModel.filterSessions(searchText).count > 0 {
                        sectionHeader("Sessions")
                        ForEach(viewModel.filterSessions(searchText)) { session in
                            sessionRow(session)
                        }
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
        .background(Color.bgPrimary)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .foregroundColor(.fgSecondary)
            .padding(.horizontal)
            .padding(.vertical, 8)
    }

    private func commandRow(_ command: Command) -> some View {
        HStack {
            Image(systemName: command.icon)
                .frame(width: 24)
                .foregroundColor(.accentPrimary)

            VStack(alignment: .leading) {
                Text(command.name)
                    .font(.body)
                if !command.shortcut.isEmpty {
                    Text(command.shortcut)
                        .font(.caption)
                        .foregroundColor(.fgSecondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(viewModel.selectedCommand?.id == command.id ? Color.bgSelected : Color.clear)
        .onTapGesture {
            viewModel.executeCommand(command)
        }
    }

    private func sessionRow(_ session: Session) -> some View {
        HStack {
            Image(systemName: "message")
                .frame(width: 24)
                .foregroundColor(.accentPurple)

            VStack(alignment: .leading) {
                Text(session.title)
                    .font(.body)
                Text("\(session.projectName) - \(session.timeAgo)")
                    .font(.caption)
                    .foregroundColor(.fgSecondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .onTapGesture {
            viewModel.openSession(session)
        }
    }
}
```

---

### 4.3 Spotlight 集成

#### 4.3.1 功能点列表

| ID | 功能点 | 描述 | 优先级 |
|----|--------|------|--------|
| F4.3.1 | Core Spotlight 索引 | 创建可搜索索引 | P0 |
| F4.3.2 | 会话索引 | 索引会话标题和内容 | P0 |
| F4.3.3 | 项目索引 | 索引项目信息 | P1 |
| F4.3.4 | 深度链接 | 从 Spotlight 打开特定会话 | P0 |
| F4.3.5 | 增量索引更新 | 实时更新索引 | P0 |
| F4.3.6 | 索引性能优化 | 后台异步索引 | P1 |

#### 4.3.2 Core Spotlight 索引管理

```swift
import CoreSpotlight
import MobileCoreServices

class SpotlightIndexManager {
    static let shared = SpotlightIndexManager()

    private let index = CSSearchableIndex(name: "com.claude.desktop.sessions")
    private var indexingQueue = DispatchQueue(label: "com.claude.desktop.spotlight", qos: .utility)

    // MARK: - Index Session

    func indexSession(_ session: Session) {
        indexingQueue.async { [weak self] in
            let searchableItem = self?.createSearchableItem(for: session) else { return }
            self?.index.indexSearchableItems([searchableItem]) { error in
                if let error = error {
                    print("Failed to index session: \(error)")
                }
            }
        }
    }

    func indexSessions(_ sessions: [Session]) {
        indexingQueue.async { [weak self] in
            let items = sessions.compactMap { self?.createSearchableItem(for: $0) }
            self?.index.indexSearchableItems(items) { error in
                if let error = error {
                    print("Failed to index sessions: \(error)")
                }
            }
        }
    }

    private func createSearchableItem(for session: Session) -> CSSearchableItem {
        // Create attribute set
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)

        // Basic info
        attributeSet.title = session.title
        attributeSet.contentDescription = """
        Project: \(session.projectName)
        \(session.summary)
        """

        // Add keywords for better searchability
        attributeSet.keywords = [
            "Claude",
            "Claude Desktop",
            session.projectName,
            "AI conversation"
        ]

        // Add content for full-text search
        if let content = session.searchableContent {
            attributeSet.contentDescription? += "\n" + content
        }

        // Create deep link URL
        let urlString = "claude://session/\(session.id)"
        attributeSet.relatedUniqueIdentifier = urlString
        attributeSet.identifier = session.id

        // Create searchable item
        let item = CSSearchableItem(
            uniqueIdentifier: session.id,
            domainIdentifier: "com.claude.desktop.sessions",
            attributeSet: attributeSet
        )

        return item
    }

    // MARK: - Update Index

    func updateSession(_ session: Session) {
        indexSession(session)
    }

    func deleteSession(withId id: String) {
        indexingQueue.async { [weak self] in
            self?.index.deleteSearchableItems(withIdentifiers: [id]) { error in
                if let error = error {
                    print("Failed to delete session from index: \(error)")
                }
            }
        }
    }

    func deleteAllSessions() {
        indexingQueue.async { [weak self] in
            self?.index.deleteAllSearchableItems { error in
                if let error = error {
                    print("Failed to delete all sessions from index: \(error)")
                }
            }
        }
    }

    // MARK: - Project Indexing

    func indexProject(_ project: Project) {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeFolder as String)

        attributeSet.title = project.name
        attributeSet.contentDescription = """
        Claude Desktop Project
        Path: \(project.path)
        Sessions: \(project.sessionCount)
        """

        attributeSet.keywords = [
            "Claude",
            "Claude Desktop",
            "Project",
            project.name
        ]

        let urlString = "claude://project/\(project.id)"
        attributeSet.relatedUniqueIdentifier = urlString

        let item = CSSearchableItem(
            uniqueIdentifier: project.id,
            domainIdentifier: "com.claude.desktop.projects",
            attributeSet: attributeSet
        )

        indexingQueue.async { [weak self] in
            self?.index.indexSearchableItems([item]) { error in
                if let error = error {
                    print("Failed to index project: \(error)")
                }
            }
        }
    }
}
```

#### 4.3.3 深度链接处理

```swift
class DeepLinkManager {
    static let shared = DeepLinkManager()

    func handleURL(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return false
        }

        let pathComponents = components.path.split(separator: "/")

        switch url.host {
        case "session":
            if let sessionId = pathComponents.first {
                openSession(String(sessionId))
                return true
            }

        case "project":
            if let projectId = pathComponents.first {
                openProject(String(projectId))
                return true
            }

        case "quickask":
            QuickAskWindowController.shared.showWindow()
            return true

        case "settings":
            openSettings()
            return true

        default:
            return false
        }

        return false
    }

    private func openSession(_ sessionId: String) {
        NotificationCenter.default.post(
            name: .openSession,
            object: nil,
            userInfo: ["sessionId": sessionId]
        )
    }

    private func openProject(_ projectId: String) {
        NotificationCenter.default.post(
            name: .openProject,
            object: nil,
            userInfo: ["projectId": projectId]
        )
    }

    private func openSettings() {
        NotificationCenter.default.post(name: .openSettings, object: nil)
    }
}

// In AppDelegate
func application(_ application: NSApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([NSUserActivityRestoring]) -> Void) -> Bool {
    if userActivity.activityType == CSSearchableItemActionType {
        if let sessionId = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
            DeepLinkManager.shared.openSession(sessionId)
            return true
        }
    }
    return false
}
```

#### 4.3.4 URL Scheme 配置

在 Info.plist 中添加：

```xml
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
```

---

### 4.4 通知中心集成

#### 4.4.1 功能点列表

| ID | 功能点 | 描述 | 优先级 |
|----|--------|------|--------|
| F4.4.1 | 通知授权 | 请求用户通知权限 | P0 |
| F4.4.2 | 基础通知 | 发送桌面通知 | P0 |
| F4.4.3 | 分类通知 | 不同类型通知样式 | P0 |
| F4.4.4 | 通知操作按钮 | 通知内操作按钮 | P1 |
| F4.4.5 | 快速回复 | 通知内文本回复 | P1 |
| F4.4.6 | 通知管理 | 通知设置和静音 | P1 |
| F4.4.7 | 通知分组 | 按会话分组通知 | P2 |

#### 4.4.2 通知管理器

```swift
import UserNotifications

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Authorization

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if granted {
                    self?.setupCategories()
                }
            }
        }
    }

    func checkAuthorizationStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async { [weak self] in
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Categories

    private func setupCategories() {
        // Response notification category
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "View",
            options: [.foreground]
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Dismiss",
            options: []
        )

        let responseCategory = UNNotificationCategory(
            identifier: "RESPONSE_CATEGORY",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        // Input needed notification category
        let replyAction = UNTextInputNotificationAction(
            identifier: "REPLY_ACTION",
            title: "Reply",
            options: [],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type your response..."
        )

        let inputCategory = UNNotificationCategory(
            identifier: "INPUT_CATEGORY",
            actions: [replyAction, viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        // Code suggestion category
        let copyCodeAction = UNNotificationAction(
            identifier: "COPY_CODE_ACTION",
            title: "Copy Code",
            options: [.foreground]
        )

        let applyAction = UNNotificationAction(
            identifier: "APPLY_ACTION",
            title: "Apply to File",
            options: [.foreground]
        )

        let codeCategory = UNNotificationCategory(
            identifier: "CODE_CATEGORY",
            actions: [copyCodeAction, applyAction, viewAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([responseCategory, inputCategory, codeCategory])
    }

    // MARK: - Send Notifications

    func sendResponseNotification(session: Session, message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Claude has responded"
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "RESPONSE_CATEGORY"
        content.userInfo = [
            "sessionId": session.id,
            "type": "response"
        ]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        center.add(request)
    }

    func sendInputNeededNotification(session: Session, message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Claude needs your input"
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "INPUT_CATEGORY"
        content.userInfo = [
            "sessionId": session.id,
            "type": "input_needed"
        ]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        center.add(request)
    }

    func sendCodeNotification(session: Session, code: String, file: String) {
        let content = UNMutableNotificationContent()
        content.title = "Code suggestion for \(file)"
        content.body = code
        content.sound = .default
        content.categoryIdentifier = "CODE_CATEGORY"
        content.userInfo = [
            "sessionId": session.id,
            "code": code,
            "file": file,
            "type": "code"
        ]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        center.add(request)
    }

    func sendTaskCompleteNotification(session: Session, taskName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Task completed"
        content.body = "\(taskName) has been completed"
        content.sound = .default
        content.categoryIdentifier = "RESPONSE_CATEGORY"
        content.userInfo = [
            "sessionId": session.id,
            "type": "task_complete"
        ]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        center.add(request)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        guard let sessionId = userInfo["sessionId"] as? String else {
            completionHandler()
            return
        }

        switch response.actionIdentifier {
        case "VIEW_ACTION":
            DeepLinkManager.shared.openSession(sessionId)

        case "REPLY_ACTION":
            if let textResponse = response as? UNTextInputNotificationResponse {
                let replyText = textResponse.userText
                sendReplyFromNotification(sessionId: sessionId, text: replyText)
            }

        case "COPY_CODE_ACTION":
            if let code = userInfo["code"] as? String {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(code, forType: .string)
            }

        case "APPLY_ACTION":
            if let file = userInfo["file"] as? String {
                NotificationCenter.default.post(
                    name: .applyCodeToFile,
                    object: nil,
                    userInfo: ["sessionId": sessionId, "file": file]
                )
            }

        case UNNotificationDefaultActionIdentifier:
            DeepLinkManager.shared.openSession(sessionId)

        default:
            break
        }

        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        if NSApp.isActive {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.banner, .sound, .badge])
        }
    }

    private func sendReplyFromNotification(sessionId: String, text: String) {
        NotificationCenter.default.post(
            name: .sendReplyFromNotification,
            object: nil,
            userInfo: ["sessionId": sessionId, "text": text]
        )
    }
}
```

#### 4.4.3 通知设置

```swift
struct NotificationSettings: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("notifyOnResponse") private var notifyOnResponse = true
    @AppStorage("notifyOnInputNeeded") private var notifyOnInputNeeded = true
    @AppStorage("notifyOnTaskComplete") private var notifyOnTaskComplete = true
    @AppStorage("notifySound") private var notifySound = true

    var body: some View {
        Form {
            Section("Notification Settings") {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { _, newValue in
                        if newValue {
                            NotificationManager.shared.requestAuthorization()
                        }
                    }

                if notificationsEnabled {
                    Toggle("Response Notifications", isOn: $notifyOnResponse)
                    Toggle("Input Needed Notifications", isOn: $notifyOnInputNeeded)
                    Toggle("Task Complete Notifications", isOn: $notifyOnTaskComplete)
                    Toggle("Notification Sound", isOn: $notifySound)
                }
            }

            Section {
                Button("Open System Notification Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}
```

---

## 五、macOS 系统集成技术方案

### 5.1 MenuBar 集成技术

#### 5.1.1 技术选型

| 技术 | 用途 | 说明 |
|------|------|------|
| NSStatusItem | MenuBar 图标 | AppKit 原生 API |
| NSMenu | 下拉菜单 | 系统标准菜单 |
| NSPanel | 浮动窗口 | Quick Ask 窗口 |

#### 5.1.2 关键实现

```swift
// MenuBar Controller
class MenuBarController {
    private var statusItem: NSStatusItem?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(named: "MenuBarIcon")
            button.image?.isTemplate = true  // Support dark/light mode
            button.imageScaling = .scaleProportionallyDown
        }

        statusItem?.menu = createMenu()
    }

    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        // Add menu items...
        return menu
    }
}
```

### 5.2 全局快捷键技术

#### 5.2.1 技术选型

| 技术 | 用途 | 说明 |
|------|------|------|
| Carbon Event Manager | 全局热键 | 系统级快捷键监听 |
| AXIsProcessTrusted | 辅助功能权限 | 监听全局按键需要权限 |
| NSEvent.addGlobalMonitor | 备选方案 | 应用不活动时监听 |

#### 5.2.2 权限请求

```swift
func checkAndRequestAccessibilityPermission() -> Bool {
    let trusted = AXIsProcessTrusted()

    if !trusted {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    return trusted
}
```

### 5.3 Spotlight 集成技术

#### 5.3.1 技术选型

| 技术 | 用途 | 说明 |
|------|------|------|
| Core Spotlight | 索引内容 | 创建可搜索内容 |
| CSSearchableIndex | 索引管理 | 管理搜索索引 |
| NSUserActivity | 用户活动 | 处理搜索结果点击 |
| URL Scheme | 深度链接 | 打开特定内容 |

#### 5.3.2 索引策略

| 策略 | 说明 |
|------|------|
| 增量索引 | 会话更新时立即索引 |
| 后台索引 | 长内容在后台队列处理 |
| 批量索引 | 应用启动时批量更新 |
| 删除同步 | 会话删除时同步删除索引 |

### 5.4 通知技术

#### 5.4.1 技术选型

| 技术 | 用途 | 说明 |
|------|------|------|
| User Notifications | 通知管理 | 发送和管理通知 |
| UNNotificationCategory | 通知分类 | 定义通知类型 |
| UNNotificationAction | 通知操作 | 定义操作按钮 |
| UNTextInputNotificationAction | 文本输入 | 快速回复功能 |

#### 5.4.2 通知流程

```
1. 检查权限 -> 请求权限
2. 注册通知分类和操作
3. 发送通知（根据类型选择分类）
4. 处理用户操作（delegate 回调）
5. 执行对应业务逻辑
```

---

## 六、技术架构

### 6.1 模块架构

```
+----------------------------------------------------------+
|                    Claude Desktop App                     |
+----------------------------------------------------------+
|                                                           |
|  +-------------+  +-------------+  +-------------+        |
|  |   MenuBar   |  |   Global    |  |  Spotlight  |        |
|  |  Controller |  |  Shortcuts  |  |   Manager   |        |
|  +-------------+  +-------------+  +-------------+        |
|         |                |                  |              |
|         v                v                  v              |
|  +-------------+  +-------------+  +-------------+        |
|  |  Quick Ask  |  |  Command    |  |  Deep Link  |        |
|  |   Window    |  |  Palette    |  |   Manager   |        |
|  +-------------+  +-------------+  +-------------+        |
|         |                |                  |              |
|         v                v                  v              |
|  +------------------------------------------------+       |
|  |              Notification Manager              |       |
|  +------------------------------------------------+       |
|                           |                               |
|                           v                               |
|  +------------------------------------------------+       |
|  |              Core Session Manager              |       |
|  +------------------------------------------------+       |
|                           |                               |
|                           v                               |
|  +------------------------------------------------+       |
|  |              CLI Connection Layer              |       |
|  +------------------------------------------------+       |
|                                                           |
+----------------------------------------------------------+
```

### 6.2 数据流

```
用户操作 -> 全局监听器 -> 动作分发 -> 业务处理 -> UI 更新

MenuBar:
点击图标 -> NSMenu 显示 -> 选择操作 -> 执行对应命令

全局快捷键:
按键事件 -> Carbon Handler -> 执行绑定的 Action

Spotlight:
输入搜索 -> 系统查询索引 -> 显示结果 -> 点击结果 -> Deep Link -> 打开会话

通知:
触发条件 -> 创建通知内容 -> 发送通知 -> 用户操作 -> Delegate 回调 -> 执行业务逻辑
```

### 6.3 文件结构

```
ClaudeDesktop/
├── SystemIntegration/
│   ├── MenuBar/
│   │   ├── MenuBarController.swift
│   │   ├── MenuBarStatus.swift
│   │   └── QuickAskWindowController.swift
│   ├── Shortcuts/
│   │   ├── GlobalShortcutManager.swift
│   │   ├── ShortcutDefinition.swift
│   │   └── CommandPaletteController.swift
│   ├── Spotlight/
│   │   ├── SpotlightIndexManager.swift
│   │   └── SpotlightSearchableItem.swift
│   ├── Notifications/
│   │   ├── NotificationManager.swift
│   │   ├── NotificationCategory.swift
│   │   └── NotificationAction.swift
│   └── DeepLinks/
│       └── DeepLinkManager.swift
├── Views/
│   ├── QuickAsk/
│   │   ├── QuickAskView.swift
│   │   └── QuickAskViewModel.swift
│   ├── CommandPalette/
│   │   ├── CommandPaletteView.swift
│   │   └── CommandPaletteViewModel.swift
│   └── Settings/
│       ├── NotificationSettings.swift
│       └── ShortcutSettings.swift
└── Resources/
    ├── Assets.xcassets/
    │   ├── MenuBarIcon.imageset/
    │   ├── MenuBarIconConnecting.imageset/
    │   └── MenuBarIconProcessing.imageset/
    └── ...
```

---

## 七、验收标准

### 7.1 MenuBar 功能验收

| 验收项 | 预期结果 | 测试方法 |
|--------|----------|----------|
| 图标显示 | MenuBar 显示 Claude 图标 | 启动应用检查 |
| 状态指示 | 不同状态显示正确图标 | 模拟各种状态 |
| 下拉菜单 | 点击显示完整菜单 | 点击测试 |
| 最近会话 | 显示最近 5 个会话 | 创建多个会话后检查 |
| Quick Ask | 打开迷你窗口 | 点击测试 |
| 迷你窗口输入 | 可输入并发送消息 | 功能测试 |
| 流式回复 | 迷你窗口显示流式回复 | 发送消息观察 |
| 展开窗口 | 可展开到完整窗口 | 点击展开按钮 |

### 7.2 全局快捷键验收

| 验收项 | 预期结果 | 测试方法 |
|--------|----------|----------|
| 权限请求 | 首次使用请求辅助功能权限 | 检查权限流程 |
| 唤起应用 | 快捷键正确唤起应用 | 在其他应用中测试 |
| Quick Ask 快捷键 | 快捷键打开迷你窗口 | 在其他应用中测试 |
| 命令面板快捷键 | 快捷键打开命令面板 | 在其他应用中测试 |
| 快捷键自定义 | 可自定义快捷键 | 设置界面测试 |
| 冲突检测 | 检测到冲突时提示 | 设置重复快捷键 |
| 多显示器 | 多显示器下正常工作 | 多显示器环境测试 |

### 7.3 Spotlight 集成验收

| 验收项 | 预期结果 | 测试方法 |
|--------|----------|----------|
| 权限授权 | 请求 Spotlight 索引权限 | 首次启动检查 |
| 会话搜索 | 可搜索到会话标题 | Spotlight 搜索测试 |
| 内容搜索 | 可搜索会话内容 | 搜索会话内关键词 |
| 结果显示 | 显示正确标题、项目、时间 | 检查搜索结果 |
| 点击打开 | 点击结果打开对应会话 | 点击测试 |
| 索引更新 | 新会话立即可搜索 | 创建新会话后搜索 |
| 删除同步 | 删除会话后不再出现 | 删除后搜索测试 |

### 7.4 通知功能验收

| 验收项 | 预期结果 | 测试方法 |
|--------|----------|----------|
| 权限请求 | 请求通知权限 | 首次发送通知时 |
| 回复完成通知 | Claude 回复完成时发送 | 触发回复场景 |
| 需要输入通知 | Claude 需要输入时发送 | 触发需要输入场景 |
| 长任务通知 | 长任务完成时发送 | 执行长任务测试 |
| 查看按钮 | 点击打开对应会话 | 点击通知 |
| 快速回复 | 可在通知中输入回复 | 使用快速回复 |
| 复制代码 | 通知中复制代码按钮有效 | 代码通知测试 |
| 应用文件 | 应用修改到文件 | 代码修改通知测试 |
| 前台显示 | 应用前台时也显示通知 | 应用前台测试 |

### 7.5 性能验收

| 验收项 | 预期结果 | 测试方法 |
|--------|----------|----------|
| MenuBar 内存 | MenuBar 占用内存 < 5MB | 内存分析 |
| 快捷键响应 | 快捷键响应时间 < 100ms | 响应时间测试 |
| 索引延迟 | 会话索引延迟 < 1s | 创建会话后搜索 |
| 通知延迟 | 通知发送延迟 < 500ms | 触发通知测量 |
| CPU 占用 | 空闲时 CPU 占用 < 1% | 活动监视器检查 |

---

## 八、里程碑计划

### Phase 4.1: MenuBar 基础 (Week 1)
- MenuBar 图标和状态显示
- 下拉菜单
- 基础 Quick Ask 窗口

### Phase 4.2: 全局快捷键 (Week 2)
- 全局快捷键注册
- 命令面板
- 快捷键自定义设置

### Phase 4.3: Spotlight 集成 (Week 3)
- Core Spotlight 索引
- 深度链接
- 搜索结果优化

### Phase 4.4: 通知集成 (Week 4)
- 通知授权和发送
- 通知操作按钮
- 快速回复
- 测试和优化

---

## 九、风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 辅助功能权限被拒绝 | 全局快捷键失效 | 提供应用内快捷键作为备选 |
| 通知权限被拒绝 | 无法发送通知 | 提供应用内消息提示 |
| Spotlight 索引性能 | 影响系统性能 | 异步后台索引，限制频率 |
| 快捷键冲突 | 与系统或其他应用冲突 | 提供冲突检测和自定义 |
| 多显示器兼容性 | Quick Ask 位置错误 | 检测鼠标位置，智能定位 |

---

## 十、附录

### 10.1 相关 Apple 文档

- [MenuBar Extras](https://developer.apple.com/design/human-interface-guidelines/macos/extensions/menu-bar-extras/)
- [Hot Keys](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/CarbonEventManager/CarbonEventManager.pdf)
- [Core Spotlight](https://developer.apple.com/documentation/corespotlight)
- [User Notifications](https://developer.apple.com/documentation/usernotifications)

### 10.2 参考资料

- Phase 3 功能设计文档
- UI 设计指南
- macOS Human Interface Guidelines

---

## Changelog

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-03-30 | 1.0 | 初始版本 |
