# Phase 2: 核心 UI - 功能设计文档

> 版本：1.0
> 日期：2026-03-30
> 作者：Product Manager Agent

---

## 一、功能概述

### 1.1 背景

Phase 1 已完成 CLI 连接层的技术基础设施，包括：
- CLI 环境检测与启动管理
- 通信管道建立（stdio/Unix Socket）
- 消息协议层（`MessageProtocol`、`MessageSerializer`）
- 流式响应处理（`StreamingResponseHandler`）
- 连接状态管理（`ConnectionState`、`ConnectionManager`）
- 错误处理与重连机制

Phase 2 将基于这些基础设施，构建用户可见的核心 UI 界面，实现完整的对话交互体验。

### 1.2 目标

构建一个直观、高效的图形化对话界面，实现：
- 多会话管理与切换
- 消息发送与流式响应实时展示
- 基础对话 UI（消息气泡、Markdown 渲染）
- 工具调用可视化展示
- 文件差异对比视图

### 1.3 范围

**包含：**
- 会话管理界面（新建、切换、删除、重命名）
- 消息输入与发送组件
- 流式响应展示组件
- 消息列表与气泡组件
- Markdown 与代码高亮渲染
- 工具调用卡片组件
- Diff View 文件对比组件
- 状态栏与连接状态展示

**不包含：**
- 高级功能（多文件编辑、项目管理）- Phase 3
- 系统集成（文件拖放、快捷键全局化）- Phase 4
- 性能优化与打磨 - Phase 5

---

## 二、用户故事

### US-1: 创建新会话

**作为** Claude Desktop 用户
**我希望** 能快速创建新的对话会话
**以便于** 针对不同任务组织独立的对话

**验收标准：**
- 支持快捷键 Cmd+N 创建新会话
- 支持侧边栏 "+" 按钮创建
- 自动生成会话标题（基于首条消息）
- 新会话自动获得焦点

### US-2: 会话切换

**作为** Claude Desktop 用户
**我希望** 能在不同会话间快速切换
**以便于** 在多个任务间切换工作上下文

**验收标准：**
- 点击侧边栏会话项即可切换
- 支持快捷键 Cmd+Shift+]/[ 前后切换
- 切换时保持各会话的滚动位置
- 切换时保持各会话的输入框内容

### US-3: 发送消息

**作为** Claude Desktop 用户
**我希望** 能在输入框中输入并发送消息给 Claude
**以便于** 与 AI 进行对话交互

**验收标准：**
- 支持 Cmd+Enter 发送消息
- 支持点击发送按钮发送
- 发送后自动清空输入框
- 发送后自动滚动到底部
- 支持多行输入（Shift+Enter 换行）

### US-4: 实时流式响应

**作为** Claude Desktop 用户
**我希望** 能看到 Claude 的回复逐字/逐块显示
**以便于** 不需要等待完整响应就能开始阅读

**验收标准：**
- 响应内容实时增量显示
- 流式过程中显示打字指示器
- 自动滚动跟随新内容
- 用户可手动暂停滚动跟随

### US-5: 查看工具调用

**作为** Claude Desktop 用户
**我希望** 能看到 Claude 调用了哪些工具、参数和结果
**以便于** 了解 AI 的操作过程

**验收标准：**
- 工具调用以卡片形式展示
- 显示工具名称、参数、执行状态
- 支持展开/折叠查看详细结果
- 错误工具调用高亮显示

### US-6: 查看文件修改

**作为** Claude Desktop 用户
**我希望** 能看到 Claude 对文件的具体修改内容
**以便于** 理解和确认代码变更

**验收标准：**
- 支持统一视图（Unified）和并排视图（Side by Side）
- 添加行显示绿色，删除行显示红色
- 显示行号和上下文
- 支持 Accept/Reject 操作

### US-7: 管理会话历史

**作为** Claude Desktop 用户
**我希望** 能查看和管理历史会话
**以便于** 回顾和继续之前的工作

**验收标准：**
- 侧边栏显示会话列表及时间
- 支持删除会话
- 支持重命名会话
- 支持搜索会话内容（P1）

---

## 三、界面布局说明

### 3.1 主窗口结构

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

### 3.2 窗口尺寸规范

| 属性 | 值 |
|------|-----|
| 最小宽度 | 800px |
| 最小高度 | 600px |
| 默认宽度 | 1200px |
| 默认高度 | 800px |
| 侧边栏宽度 | 220px（可折叠至 48px） |

### 3.3 响应式布局

| 窗口宽度 | 侧边栏行为 |
|----------|------------|
| > 1000px | 完整侧边栏（220px） |
| 800-1000px | 折叠侧边栏（48px 图标模式） |
| < 800px | 隐藏侧边栏（需切换显示浮层） |

---

## 四、功能点详细设计

### 4.1 会话管理界面

#### 4.1.1 功能点列表

| ID | 功能点 | 描述 | 优先级 |
|----|--------|------|--------|
| F2.1.1 | 会话列表 | 侧边栏显示所有会话 | P0 |
| F2.1.2 | 新建会话 | 创建新的对话会话 | P0 |
| F2.1.3 | 切换会话 | 点击切换到指定会话 | P0 |
| F2.1.4 | 删除会话 | 删除指定会话 | P0 |
| F2.1.5 | 重命名会话 | 修改会话标题 | P1 |
| F2.1.6 | 会话搜索 | 搜索会话内容 | P2 |
| F2.1.7 | 会话持久化 | 会话数据本地存储 | P1 |

#### 4.1.2 会话数据模型

```swift
/// 会话模型
struct Session: Identifiable, Codable, Sendable {
    let id: UUID
    var title: String
    var projectPath: String?
    var model: String
    var messages: [Message]
    var createdAt: Date
    var updatedAt: Date

    /// 自动生成标题（基于首条用户消息）
    mutating func generateTitle()
}

/// 消息模型
struct Message: Identifiable, Codable, Sendable {
    let id: UUID
    let role: MessageRole
    var content: String
    var toolCalls: [ToolCall]?
    var timestamp: Date
    var status: MessageStatus
}

enum MessageRole: String, Codable, Sendable {
    case user
    case assistant
    case system
}

enum MessageStatus: String, Codable, Sendable {
    case pending
    case streaming
    case completed
    case error
}
```

#### 4.1.3 会话列表项布局

```
+------------------------------------------+
|  [Icon]  Session Title                   |
|          Project Name         [Time]     |
+------------------------------------------+
```

- 高度：48px
- 图标尺寸：24x24px
- 左边距：12px
- 激活状态：`bg-selected` 背景
- 悬停状态：`bg-hover` 背景

#### 4.1.4 会话管理 ViewModel

```swift
@MainActor
@Observable
final class SessionViewModel {
    var sessions: [Session] = []
    var currentSession: Session?
    var isLoading: Bool = false

    func createSession() async
    func selectSession(_ id: UUID) async
    func deleteSession(_ id: UUID) async
    func renameSession(_ id: UUID, to title: String) async
    func loadSessions() async
    func saveSessions() async
}
```

---

### 4.2 消息发送与流式接收

#### 4.2.1 功能点列表

| ID | 功能点 | 描述 | 优先级 |
|----|--------|------|--------|
| F2.2.1 | 输入框 | 多行文本输入区域 | P0 |
| F2.2.2 | 发送按钮 | 点击发送消息 | P0 |
| F2.2.3 | 快捷键发送 | Cmd+Enter 发送 | P0 |
| F2.2.4 | 流式显示 | 增量显示响应内容 | P0 |
| F2.2.5 | 打字指示器 | 显示 AI 正在输入状态 | P1 |
| F2.2.6 | 中断响应 | 停止当前响应生成 | P1 |
| F2.2.7 | 消息重试 | 重新发送失败消息 | P2 |

#### 4.2.2 输入区域布局

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

#### 4.2.3 输入组件规范

| 属性 | 值 |
|------|-----|
| 最小高度 | 80px |
| 最大高度 | 300px（超出自动滚动） |
| 内边距 | 12px |
| 圆角 | 12px |
| 背景 | `bg-tertiary` |
| 边框 | 1px `fg-tertiary`（聚焦时 `accent-primary`） |

#### 4.2.4 流式响应处理流程

```
用户发送消息
      │
      ▼
┌─────────────────┐
│ OutgoingMessage │ ────▶ CLI Connector (Phase 1)
│   .text()       │
└─────────────────┘
      │
      ▼
┌─────────────────────────────┐
│ StreamingResponseHandler    │ ◀─── SSE/JSON 数据流
│ (Phase 1)                   │
└─────────────────────────────┘
      │
      │ Publisher: deltaPublisher
      ▼
┌─────────────────────────────┐
│ MessageViewModel            │
│ - appendDelta()             │
│ - updateContent()           │
└─────────────────────────────┘
      │
      │ @Published content
      ▼
┌─────────────────────────────┐
│ MessageView                 │
│ - 实时渲染增量内容           │
│ - 自动滚动                  │
└─────────────────────────────┘
```

#### 4.2.5 消息发送 ViewModel

```swift
@MainActor
@Observable
final class MessageInputViewModel {
    var text: String = ""
    var isSending: Bool = false
    var isStreaming: Bool = false

    private let cliConnector: CLIConnector
    private var streamingCancellable: AnyCancellable?

    func sendMessage() async throws
    func interruptStream() async
    func canSend() -> Bool
}
```

---

### 4.3 基础对话 UI 实现

#### 4.3.1 功能点列表

| ID | 功能点 | 描述 | 优先级 |
|----|--------|------|--------|
| F2.3.1 | 消息列表 | 滚动列表展示所有消息 | P0 |
| F2.3.2 | 用户消息气泡 | 用户消息样式 | P0 |
| F2.3.3 | AI 消息气泡 | AI 消息样式 | P0 |
| F2.3.4 | Markdown 渲染 | 支持基本 Markdown | P0 |
| F2.3.5 | 代码高亮 | 代码块语法高亮 | P0 |
| F2.3.6 | 消息时间戳 | 显示消息发送时间 | P1 |
| F2.3.7 | 消息操作 | 复制、编辑、删除 | P2 |
| F2.3.8 | 滚动控制 | 自动滚动/手动暂停 | P1 |

#### 4.3.2 用户消息气泡

```
+--------------------------------------------------+
|                                                  |
|  User's message text goes here...                |
|                                                  |
|                              14:32    [Edit]     |
+--------------------------------------------------+
```

- 背景：`bg-tertiary`
- 圆角：12px
- 内边距：12px 16px
- 最大宽度：容器的 80%
- 对齐：右侧

#### 4.3.3 AI 消息气泡

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

- 背景：`bg-secondary` 或透明
- 圆角：12px
- 内边距：12px 16px
- 宽度：100%
- 对齐：左侧

#### 4.3.4 Markdown 渲染规范

| 元素 | 样式 |
|------|------|
| 标题 (h1-h6) | 对应 `title`/`headline` 字体 |
| 粗体 | Semibold 字重 |
| 斜体 | Italic 样式 |
| 代码块 | SF Mono 字体，`code-bg` 背景 |
| 行内代码 | SF Mono 字体，浅色背景 |
| 链接 | `accent-primary` 颜色，悬停下划线 |
| 列表 | 标准缩进 + 项目符号 |
| 引用 | 左侧边框 + 缩进 |

#### 4.3.5 代码块样式

```
+--------------------------------------------------+
|  swift                          [Copy] [Expand] |
+--------------------------------------------------+
|  1 | import Foundation                           |
|  2 |                                              |
|  3 | struct APIClient {                          |
|  4 |     let baseURL: URL                        |
|  ...| ...                                         |
+--------------------------------------------------+
```

- 语言标签：左上角
- 复制按钮：右上角
- 行号：`fg-tertiary` 颜色，右对齐
- 语法高亮：使用定义的代码颜色

---

### 4.4 工具调用可视化展示

#### 4.4.1 功能点列表

| ID | 功能点 | 描述 | 优先级 |
|----|--------|------|--------|
| F2.4.1 | 工具卡片 | 工具调用的基础展示容器 | P0 |
| F2.4.2 | 工具图标 | 不同工具类型的图标 | P0 |
| F2.4.3 | 参数展示 | 显示工具调用参数 | P0 |
| F2.4.4 | 结果展示 | 显示工具执行结果 | P0 |
| F2.4.5 | 状态指示 | 运行/成功/失败状态 | P0 |
| F2.4.6 | 展开/折叠 | 控制详细信息显示 | P1 |
| F2.4.7 | 结果复制 | 复制工具输出 | P2 |
| F2.4.8 | 执行时间 | 显示工具执行耗时 | P2 |

#### 4.4.2 工具类型与图标

| 工具 | 图标 | 颜色 |
|------|------|------|
| Read | doc.text | Blue |
| Write | square.and.pencil | Green |
| Edit | pencil.tip | Orange |
| Bash | terminal | Gray |
| Glob | magnifyingglass | Purple |
| Grep | text.magnifyingglass | Teal |

#### 4.4.3 工具调用状态

| 状态 | 视觉表现 |
|------|----------|
| Running | 动画 spinner，黄色边框 |
| Success | 绿色对勾，默认折叠 |
| Error | 红色指示，默认展开 |
| Pending | 灰色，禁用外观 |

#### 4.4.4 工具卡片布局（折叠状态）

```
+----------------------------------------------------------+
| [Tool Icon] Read File (3)                         [>]    |
+----------------------------------------------------------+
```

#### 4.4.5 工具卡片布局（展开状态）

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

#### 4.4.6 工具调用数据模型

```swift
/// UI 层工具调用展示模型
struct ToolCallDisplay: Identifiable, Sendable {
    let id: String
    let name: String
    let arguments: [String: JSONValue]?
    let result: String?
    let error: String?
    let status: ToolCallStatus
    let duration: TimeInterval?
    var isExpanded: Bool

    /// 工具图标名称
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

    /// 工具图标颜色
    var iconColor: Color {
        switch name {
        case "Read": return .blue
        case "Write": return .green
        case "Edit": return .orange
        case "Bash": return .gray
        case "Glob": return .purple
        case "Grep": return .teal
        default: return .gray
        }
    }
}
```

---

### 4.5 文件差异对比 (Diff View)

#### 4.5.1 功能点列表

| ID | 功能点 | 描述 | 优先级 |
|----|--------|------|--------|
| F2.5.1 | 统一视图 | 行内显示增删改 | P0 |
| F2.5.2 | 并排视图 | 左右对比显示 | P1 |
| F2.5.3 | 行号显示 | 显示原始和修改后行号 | P0 |
| F2.5.4 | 语法高亮 | 代码语法着色 | P1 |
| F2.5.5 | Accept/Reject | 接受或拒绝修改 | P1 |
| F2.5.6 | 上下文折叠 | 折叠未修改区域 | P2 |

#### 4.5.2 Diff 颜色定义

| 类型 | 背景色 | 文字色 |
|------|--------|--------|
| 删除 | `#3D1F1E` | `#FF6B6B` |
| 添加 | `#1E3D26` | `#6BCB77` |
| 修改 | `#3D3A1E` | `#FFD93D` |
| 未修改 | 透明 | `fg-primary` |

#### 4.5.3 统一视图布局 (Unified View)

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

#### 4.5.4 并排视图布局 (Side by Side View)

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

#### 4.5.5 Diff 数据模型

```swift
/// 单个文件的 Diff 信息
struct FileDiff: Identifiable, Sendable {
    let id: UUID
    let filePath: String
    let hunks: [DiffHunk]
    var isAccepted: Bool?

    var additions: Int {
        hunks.reduce(0) { $0 + $1.additions }
    }

    var deletions: Int {
        hunks.reduce(0) { $0 + $1.deletions }
    }
}

/// Diff 块（连续的修改区域）
struct DiffHunk: Sendable {
    let oldStart: Int
    let oldCount: Int
    let newStart: Int
    let newCount: Int
    let lines: [DiffLine]

    var additions: Int {
        lines.filter { $0.type == .addition }.count
    }

    var deletions: Int {
        lines.filter { $0.type == .deletion }.count
    }
}

/// Diff 行
struct DiffLine: Sendable {
    let oldLineNumber: Int?
    let newLineNumber: Int?
    let content: String
    let type: DiffLineType
}

enum DiffLineType: Sendable {
    case context    // 未修改
    case addition   // 新增
    case deletion   // 删除
}
```

---

## 五、与 Phase 1 CLI 连接层的集成

### 5.1 依赖关系图

```
Phase 2 UI 层
      │
      ├──────────────────┬──────────────────┐
      │                  │                  │
      ▼                  ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ConnectionState│  │MessageProtocol│  │StreamingResp │
│              │  │              │  │onseHandler   │
└──────────────┘  └──────────────┘  └──────────────┘
      │                  │                  │
      └──────────────────┴──────────────────┘
                         │
                         ▼
              ┌──────────────────┐
              │  CLIConnector    │
              │  (统一入口)       │
              └──────────────────┘
                         │
                         ▼
              ┌──────────────────┐
              │ Claude Code CLI  │
              └──────────────────┘
```

### 5.2 集成点说明

#### 5.2.1 连接状态展示

UI 层通过订阅 `ConnectionManager` 的状态变化来更新界面：

```swift
// UI 层
struct ConnectionStatusView: View {
    @State private var connectionState: ConnectionState = .idle

    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(connectionState.description)
        }
        .onReceive(connectionManager.$state) { state in
            connectionState = state
        }
    }
}
```

#### 5.2.2 消息发送流程

```swift
// UI 层 -> CLI 层
func sendMessage(_ text: String) async throws {
    // 1. 创建消息模型
    let message = OutgoingMessage.text(text, sessionId: currentSession.id)

    // 2. 通过 CLIConnector 发送
    try await cliConnector.send(message)

    // 3. 开始流式响应处理
    streamingHandler.start()
}
```

#### 5.2.3 流式响应订阅

```swift
// CLI 层 -> UI 层
func subscribeToStream() {
    // 订阅增量更新
    streamingHandler.deltaPublisher
        .receive(on: DispatchQueue.main)
        .sink { [weak self] delta in
            self?.appendDelta(delta)
        }
        .store(in: &cancellables)

    // 订阅完整响应
    streamingHandler.responsePublisher
        .receive(on: DispatchQueue.main)
        .sink { [weak self] response in
            self?.handleResponse(response)
        }
        .store(in: &cancellables)
}
```

#### 5.2.4 工具调用处理

```swift
// 处理来自 StreamingResponseHandler 的工具调用
func handleToolCall(_ toolCall: ToolCall) {
    let display = ToolCallDisplay(
        id: toolCall.id,
        name: toolCall.name,
        arguments: toolCall.arguments,
        result: nil,
        error: nil,
        status: toolCall.status,
        duration: nil,
        isExpanded: toolCall.status == .failed
    )

    currentMessage?.toolCalls?.append(display)
}
```

### 5.3 数据流总览

```
┌─────────────────────────────────────────────────────────────┐
│                        UI 层 (Phase 2)                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │ SessionView  │    │ MessageView  │    │ ToolCallView │  │
│  │    Model     │    │    Model     │    │    Model     │  │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘  │
│         │                   │                   │          │
│         └───────────────────┼───────────────────┘          │
│                             │                              │
├─────────────────────────────┼──────────────────────────────┤
│                             │                              │
│                      ┌──────▼───────┐                      │
│                      │ CLIConnector │                      │
│                      │   (统一入口)  │                      │
│                      └──────┬───────┘                      │
│                             │                              │
├─────────────────────────────┼──────────────────────────────┤
│                             │                              │
│                        Phase 1                             │
│                             │                              │
│  ┌──────────────┐    ┌──────▼───────┐    ┌──────────────┐ │
│  │Connection    │    │ Communication│    │  Streaming   │ │
│  │  Manager     │    │   Pipeline   │    │   Handler    │ │
│  └──────────────┘    └──────────────┘    └──────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │ Claude Code CLI  │
                    └──────────────────┘
```

---

## 六、验收标准

### 6.1 功能验收标准

| 场景 | 预期结果 | 优先级 |
|------|----------|--------|
| 创建新会话 | 侧边栏出现新会话项，自动获得焦点 | P0 |
| 切换会话 | 消息列表更新，输入框保留各会话内容 | P0 |
| 发送消息 | 消息显示在列表中，AI 开始响应 | P0 |
| 流式响应 | 内容逐字显示，自动滚动 | P0 |
| 工具调用 | 显示工具卡片，可展开查看详情 | P0 |
| 文件 Diff | 显示增删行，颜色区分 | P0 |
| 删除会话 | 会话从列表移除，数据清除 | P0 |
| Markdown | 正确渲染标题、列表、代码块 | P0 |
| 代码高亮 | 代码块有语法着色 | P1 |
| 会话重命名 | 标题更新，持久保存 | P1 |

### 6.2 性能验收标准

| 指标 | 目标值 |
|------|--------|
| 会话列表加载 | < 100ms |
| 消息列表渲染（100条） | < 200ms |
| 流式响应首字节显示 | < 100ms |
| 工具卡片渲染 | < 50ms |
| Diff 视图渲染 | < 300ms |
| 内存占用（空闲） | < 150MB |
| 内存占用（活跃） | < 300MB |

### 6.3 UI/UX 验收标准

| 指标 | 目标值 |
|------|--------|
| 动画帧率 | 60 FPS |
| 滚动流畅度 | 无卡顿 |
| 响应延迟 | < 16ms |
| 快捷键响应 | 即时 |
| 错误提示清晰度 | 用户可理解 |

---

## 七、优先级排序

### P0 - 核心功能（必须完成）

```
┌─────────────────────────────────────────────────────────────┐
│                    P0 核心功能                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  会话管理                                                    │
│  ├── F2.1.1 会话列表                                        │
│  ├── F2.1.2 新建会话                                        │
│  ├── F2.1.3 切换会话                                        │
│  └── F2.1.4 删除会话                                        │
│                                                             │
│  消息交互                                                    │
│  ├── F2.2.1 输入框                                          │
│  ├── F2.2.2 发送按钮                                        │
│  ├── F2.2.3 快捷键发送                                      │
│  └── F2.2.4 流式显示                                        │
│                                                             │
│  对话 UI                                                     │
│  ├── F2.3.1 消息列表                                        │
│  ├── F2.3.2 用户消息气泡                                    │
│  ├── F2.3.3 AI 消息气泡                                     │
│  ├── F2.3.4 Markdown 渲染                                   │
│  └── F2.3.5 代码高亮                                        │
│                                                             │
│  工具可视化                                                  │
│  ├── F2.4.1 工具卡片                                        │
│  ├── F2.4.2 工具图标                                        │
│  ├── F2.4.3 参数展示                                        │
│  ├── F2.4.4 结果展示                                        │
│  └── F2.4.5 状态指示                                        │
│                                                             │
│  Diff 视图                                                   │
│  ├── F2.5.1 统一视图                                        │
│  └── F2.5.3 行号显示                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### P1 - 重要功能（应该完成）

| 模块 | 功能点 |
|------|--------|
| 会话管理 | F2.1.5 重命名、F2.1.7 持久化 |
| 消息交互 | F2.2.5 打字指示器、F2.2.6 中断响应 |
| 对话 UI | F2.3.6 时间戳、F2.3.8 滚动控制 |
| 工具可视化 | F2.4.6 展开/折叠 |
| Diff 视图 | F2.5.2 并排视图、F2.5.4 语法高亮、F2.5.5 Accept/Reject |

### P2 - 增强功能（可以完成）

| 模块 | 功能点 |
|------|--------|
| 会话管理 | F2.1.6 搜索 |
| 消息交互 | F2.2.7 消息重试 |
| 对话 UI | F2.3.7 消息操作 |
| 工具可视化 | F2.4.7 结果复制、F2.4.8 执行时间 |
| Diff 视图 | F2.5.6 上下文折叠 |

---

## 八、里程碑

| 里程碑 | 功能点 | 预计周期 |
|--------|--------|----------|
| M1: 基础 UI 框架 | 窗口结构、侧边栏、会话管理 | 第 1 周 |
| M2: 消息交互 | 输入框、发送、流式显示 | 第 2 周 |
| M3: 对话展示 | 消息气泡、Markdown、代码高亮 | 第 3 周 |
| M4: 工具可视化 | 工具卡片、状态展示 | 第 4 周 |
| M5: Diff 视图 | 统一视图、并排视图 | 第 5 周 |

---

## 九、风险与应对

| 风险 | 概率 | 影响 | 应对措施 |
|------|------|------|----------|
| SwiftUI 性能问题 | 中 | 高 | 使用 LazyVStack、优化渲染 |
| Markdown 渲染复杂 | 中 | 中 | 使用成熟库如 MarkdownUI |
| 流式 UI 卡顿 | 低 | 高 | 异步渲染、节流更新 |
| Diff 算法复杂 | 中 | 中 | 使用 diff-match-patch 库 |

---

## 十、参考资源

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [MarkdownUI Library](https://github.com/gonzalezreal/swift-markdown-ui)
- [Highlightr for Syntax Highlighting](https://github.com/raspu/Highlightr)
- Phase 1 设计文档: `docs/phase1-cli-connector-design.md`
- UI 设计指南: `docs/ui-design-guide.md`

---

## 更新日志

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-03-30 | 1.0 | 初始版本，完成 Phase 2 核心 UI 功能设计 |
