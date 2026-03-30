# Phase 5: 打磨与发布 - 功能设计文档

> 版本：1.0
> 日期：2026-03-30
> 作者：Product Manager Agent

---

## 一、功能概述

### 1.1 背景

Phase 0-4 已完成 Claude Desktop Mac 的完整功能构建：

| Phase | 内容 | 状态 |
|-------|------|------|
| Phase 0 | 项目初始化、基础设施 | 完成 |
| Phase 1 | CLI 连接层（检测、通信、协议、流式响应） | 完成 |
| Phase 2 | 核心 UI（会话管理、消息界面、工具可视化、Diff 视图） | 完成 |
| Phase 3 | 增强功能（代码高亮、上传、快捷键、历史、项目管理） | 完成 |
| Phase 4 | 系统集成（MenuBar、全局快捷键、Spotlight、通知） | 完成 |

**当前代码规模：** 71 个 Swift 文件，涵盖完整功能模块。

Phase 5 作为最终阶段，专注于：
- UI 打磨与优化
- 性能优化与内存管理
- 打包、签名与公证
- 文档编写与发布准备

### 1.2 目标

将 Claude Desktop Mac 打磨成一款高质量、可正式发布的 macOS 原生应用：

- **精致体验** - 流畅动画、响应迅速、视觉一致
- **高效性能** - 低内存占用、快速启动、稳定运行
- **专业分发** - 代码签名、公证、符合 Apple 规范
- **完善文档** - README、用户手册、开发指南齐备

### 1.3 范围

**包含：**
- UI 动画优化
- 响应速度优化
- 视觉一致性检查
- 无障碍访问增强
- 内存管理与泄漏检测
- 启动速度优化
- 资源使用优化
- App Bundle 构建
- 代码签名
- Apple 公证
- 分发准备
- README 文档
- CHANGELOG 编写
- 开发指南
- 用户手册

**不包含：**
- 新功能开发
- 架构重构
- API 变更

---

## 二、UI 优化清单

### 2.1 动画优化

#### 2.1.1 动画性能目标

| 动画类型 | 目标帧率 | 目标时长 | 优化策略 |
|----------|----------|----------|----------|
| 窗口过渡 | 60 FPS | 200-300ms | 使用 NSAnimationContext |
| 消息出现 | 60 FPS | 100-150ms | 淡入 + 轻微上移 |
| 工具调用展开/折叠 | 60 FPS | 150-200ms | height 约束动画 |
| 侧边栏切换 | 60 FPS | 200ms | width 约束动画 |
| 连接状态脉冲 | 60 FPS | 1500ms 循环 | CABasicAnimation |
| 打字指示器 | 60 FPS | 1400ms 循环 | CAKeyframeAnimation |
| MenuBar 下拉 | 60 FPS | 150ms | 系统默认 |

#### 2.1.2 动画实现规范

```swift
// 标准动画配置
extension Animation {
    static let fast = Animation.easeOut(duration: 0.1)
    static let normal = Animation.easeOut(duration: 0.2)
    static let slow = Animation.easeInOut(duration: 0.3)

    // 弹性动画 - 用于交互反馈
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
}

// 消息出现动画
struct MessageAppearAnimation: ViewModifier {
    @State private var opacity: Double = 0
    @State private var offset: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .offset(y: offset)
            .onAppear {
                withAnimation(.normal) {
                    opacity = 1
                    offset = 0
                }
            }
    }
}

// 工具调用展开动画
struct ExpandableCard: View {
    @State private var isExpanded: Bool = false
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        VStack {
            // Header
            headerView

            // Content with height animation
            if isExpanded {
                contentView
                    .background(
                        GeometryReader { geo in
                            Color.clear.onAppear {
                                contentHeight = geo.size.height
                            }
                        }
                    )
            }
        }
        .animation(.normal, value: isExpanded)
    }
}
```

#### 2.1.3 动画优化清单

| ID | 优化项 | 描述 | 优先级 |
|----|--------|------|--------|
| A1 | 消息气泡动画 | 淡入 + 轻微上移效果 | P0 |
| A2 | 工具调用卡片展开 | 平滑高度变化 | P0 |
| A3 | 侧边栏折叠/展开 | 宽度动画 + 内容渐变 | P0 |
| A4 | 连接状态指示器 | 脉冲呼吸效果 | P1 |
| A5 | 打字指示器 | 三点跳动动画 | P1 |
| A6 | 快捷命令面板 | 滑入效果 | P1 |
| A7 | Quick Ask 窗口 | 从 MenuBar 展开效果 | P1 |
| A8 | Diff 视图切换 | 平滑过渡动画 | P2 |
| A9 | 通知弹出 | 滑入 + 淡入组合 | P2 |
| A10 | 会话切换 | 内容淡入淡出 | P2 |

### 2.2 响应速度优化

#### 2.2.1 响应时间目标

| 操作 | 目标时间 | 当前基准 | 优化策略 |
|------|----------|----------|----------|
| 发送消息 | < 50ms | - | 异步处理 |
| 切换会话 | < 100ms | - | 预加载 |
| 搜索历史 | < 200ms | - | 索引优化 |
| 打开设置 | < 100ms | - | 懒加载 |
| 展开工具调用 | < 50ms | - | 预渲染 |
| 切换主题 | < 100ms | - | 缓存样式 |
| MenuBar 点击响应 | < 50ms | - | 系统原生 |
| 全局快捷键响应 | < 100ms | - | 系统级监听 |

#### 2.2.2 响应优化实现

```swift
// 会话预加载管理器
class SessionPreloader: ObservableObject {
    private var preloadedSessions: [String: PreloadedSession] = [:]
    private let preloadQueue = DispatchQueue(label: "com.claude.desktop.preload")

    func preloadAdjacentSessions(currentSessionId: String, sessions: [Session]) {
        guard let currentIndex = sessions.firstIndex(where: { $0.id == currentSessionId }) else { return }

        preloadQueue.async { [weak self] in
            // 预加载相邻会话
            let indices = [currentIndex - 1, currentIndex + 1].filter {
                $0 >= 0 && $0 < sessions.count
            }

            for index in indices {
                let session = sessions[index]
                self?.preloadSession(session)
            }
        }
    }

    private func preloadSession(_ session: Session) {
        let preloaded = PreloadedSession(
            id: session.id,
            messages: loadMessages(for: session.id),
            context: loadContext(for: session.id)
        )
        DispatchQueue.main.async {
            self.preloadedSessions[session.id] = preloaded
        }
    }
}

// 懒加载视图组件
struct LazySettingsView: View {
    @State private var loadedView: AnyView?

    var body: some View {
        Group {
            if let view = loadedView {
                view
            } else {
                ProgressView()
                    .onAppear {
                        DispatchQueue.main.async {
                            loadedView = AnyView(SettingsContentView())
                        }
                    }
            }
        }
    }
}

// 异步消息发送
extension ChatViewModel {
    func sendMessage(_ text: String) async {
        // 立即更新 UI（乐观更新）
        let tempMessage = Message.placeholder(text: text)
        await MainActor.run {
            messages.append(tempMessage)
        }

        // 异步发送
        do {
            let response = try await connectionManager.sendMessage(text)
            await MainActor.run {
                // 替换临时消息
                if let index = messages.firstIndex(where: { $0.id == tempMessage.id }) {
                    messages[index] = response
                }
            }
        } catch {
            await MainActor.run {
                // 错误处理
                errorMessage = error.localizedDescription
            }
        }
    }
}
```

#### 2.2.3 响应优化清单

| ID | 优化项 | 描述 | 优先级 |
|----|--------|------|--------|
| R1 | 消息发送即时反馈 | 发送后立即显示用户消息 | P0 |
| R2 | 会话切换预加载 | 预加载相邻会话数据 | P0 |
| R3 | 设置页面懒加载 | 分页面按需加载 | P1 |
| R4 | 历史搜索索引 | 建立内存索引加速搜索 | P1 |
| R5 | 工具调用结果缓存 | 缓存已展开的工具调用结果 | P2 |
| R6 | 代码高亮缓存 | 缓存已渲染的代码块 | P2 |
| R7 | 图片缩略图缓存 | 缓存上传图片的缩略图 | P2 |
| R8 | Markdown 渲染优化 | 增量渲染长文档 | P2 |

### 2.3 视觉一致性检查

#### 2.3.1 设计规范检查清单

| ID | 检查项 | 规范 | 验证方法 |
|----|--------|------|----------|
| V1 | 颜色使用 | 使用 Theme 模块定义的颜色 | 代码审查 |
| V2 | 字体大小 | 使用 Typography 模块定义的字体 | 代码审查 |
| V3 | 间距规范 | 使用设计指南定义的间距 | 视觉检查 |
| V4 | 圆角规范 | 使用 Styles 模块定义的圆角 | 视觉检查 |
| V5 | 图标一致性 | 使用 SF Symbols 或自定义图标库 | 视觉检查 |
| V6 | 阴影使用 | 符合设计指南定义的阴影样式 | 视觉检查 |
| V7 | 深浅模式 | 所有界面支持深浅模式切换 | 自动化测试 |
| V8 | 高对比度模式 | 支持 macOS 高对比度模式 | 辅助功能测试 |

#### 2.3.2 视觉一致性实现

```swift
// 统一使用 Theme 模块的颜色
// 正确示例：
struct MessageBubble: View {
    let isUser: Bool

    var body: some View {
        Text("Message content")
            .padding()
            .background(isUser ? Color.bgTertiary : Color.bgSecondary)
            .foregroundColor(.fgPrimary)
            .cornerRadius(.lg)
    }
}

// 错误示例（避免硬编码颜色）：
// .background(Color(hex: "1E1E1E"))  // 不推荐

// 统一使用 Typography 模块的字体
extension Text {
    func messageStyle() -> some View {
        self.font(.body)
            .foregroundColor(.fgPrimary)
            .lineSpacing(4)
    }

    func codeStyle() -> some View {
        self.font(.system(.body, design: .monospaced))
            .foregroundColor(.fgPrimary)
            .padding(.md)
            .background(Color.codeBg)
            .cornerRadius(.sm)
    }
}

// 统一使用 Styles 模块的间距和圆角
extension CGFloat {
    // Spacing
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32

    // Border Radius
    static let radiusSm: CGFloat = 4
    static let radiusMd: CGFloat = 8
    static let radiusLg: CGFloat = 12
    static let radiusXl: CGFloat = 16
}

extension View {
    func padding(_ size: CGFloat) -> some View {
        self.padding(size)
    }

    func cornerRadius(_ size: CGFloat) -> some View {
        self.cornerRadius(size)
    }
}
```

#### 2.3.3 视觉检查清单

| ID | 检查项 | 检查内容 | 状态 |
|----|--------|----------|------|
| VC1 | 窗口标题栏 | 标题字体、按钮位置、工具栏一致性 | 待检查 |
| VC2 | 侧边栏 | 图标大小、间距、选中状态、hover 效果 | 待检查 |
| VC3 | 消息区域 | 气泡样式、间距、时间戳位置、操作按钮 | 待检查 |
| VC4 | 输入区域 | 输入框样式、工具栏、按钮样式 | 待检查 |
| VC5 | 工具调用卡片 | 图标、标题、参数、结果展示一致性 | 待检查 |
| VC6 | Diff 视图 | 颜色、字体、行号、按钮样式 | 待检查 |
| VC7 | MenuBar 菜单 | 菜单项样式、图标、分隔线 | 待检查 |
| VC8 | Quick Ask 窗口 | 窗口样式、输入框、回复区域 | 待检查 |
| VC9 | 命令面板 | 搜索框、结果列表、键盘导航样式 | 待检查 |
| VC10 | 通知样式 | 图标、标题、内容、按钮样式 | 待检查 |
| VC11 | 设置页面 | 分组样式、输入框、开关、按钮 | 待检查 |
| VC12 | 空状态 | 图标、文字、按钮位置和样式 | 待检查 |
| VC13 | 错误状态 | 图标、错误文字、重试按钮样式 | 待检查 |
| VC14 | 加载状态 | 进度指示器、加载文字样式 | 待检查 |

### 2.4 无障碍访问增强

#### 2.4.1 VoiceOver 支持

| 元素 | Accessibility Label | Accessibility Hint | Accessibility Trait |
|------|---------------------|-------------------|---------------------|
| 会话项 | "Session: [title], Project: [name], [timestamp]" | "Double tap to open session" | .button |
| 消息气泡 | "[User/Assistant]: [content preview]" | "Swipe to read full message" | .staticText |
| 工具调用卡片 | "[Tool name] tool call, [status]" | "Double tap to expand" | .button |
| 发送按钮 | "Send message" | "Sends current message" | .button |
| 连接状态 | "Connection status: [state]" | - | .staticText |
| Diff 行 | "Line [number], [added/removed/unchanged]" | - | .staticText |
| 菜单项 | "[Menu item name]" | "[Menu item description]" | .button |

#### 2.4.2 无障碍实现

```swift
// VoiceOver 标签设置
struct SessionItemView: View {
    let session: Session

    var body: some View {
        HStack {
            Image(systemName: "message.fill")
            VStack(alignment: .leading) {
                Text(session.title)
                Text(session.projectName)
                    .font(.caption)
                Text(session.timestamp.relativeString)
                    .font(.caption)
                    .foregroundColor(.fgSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Session: \(session.title), Project: \(session.projectName), \(session.timestamp.relativeString)")
        .accessibilityHint("Double tap to open session")
        .accessibilityAddTraits(.isButton)
    }
}

// 工具调用卡片无障碍
struct ToolCallCardView: View {
    let toolCall: ToolCall
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack {
            // Header
            HStack {
                Image(systemName: toolCall.icon)
                Text(toolCall.name)
                Spacer()
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(toolCall.name) tool call, \(toolCall.status.description)")
            .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand")")
            .accessibilityAddTraits(.isButton)
            .onTapGesture {
                withAnimation(.normal) {
                    isExpanded.toggle()
                }
            }

            // Content
            if isExpanded {
                toolCallContentView
            }
        }
    }
}

// 动态字体支持
struct ScalableText: View {
    let text: String
    let style: Font.TextStyle

    var body: some View {
        Text(text)
            .font(.system(style))
            .minimumScaleFactor(0.75)
            .lineLimit(nil)
    }
}

// 高对比度模式支持
extension Color {
    static var accessiblePrimary: Color {
        Color(primary: "fgPrimary", bundle: nil)
    }

    static var accessibleAccent: Color {
        Color(primary: "accentPrimary", bundle: nil)
    }
}

// 自适应颜色
struct AdaptiveColors {
    @Environment(\.colorScheme) var colorScheme

    var primaryText: Color {
        colorScheme == .dark ? .fgPrimary : Color(hex: "333333")
    }

    var secondaryText: Color {
        colorScheme == .dark ? .fgSecondary : Color(hex: "666666")
    }
}
```

#### 2.4.3 无障碍检查清单

| ID | 检查项 | 描述 | 优先级 |
|----|--------|------|--------|
| AC1 | VoiceOver 导航 | 完整的 VoiceOver 导航支持 | P0 |
| AC2 | 动态字体 | 支持系统字体大小设置 | P0 |
| AC3 | 高对比度 | 高对比度模式下的可读性 | P0 |
| AC4 | 键盘导航 | 完整的键盘导航支持 | P1 |
| AC5 | 焦点指示器 | 清晰的焦点状态显示 | P1 |
| AC6 | 减少动画 | 支持系统"减少动态效果"设置 | P1 |
| AC7 | 颜色对比度 | WCAG AA 标准对比度 | P1 |
| AC8 | 触控板手势 | 支持触控板手势操作 | P2 |
| AC9 | Switch Control | 支持 Switch Control 辅助功能 | P2 |

---

## 三、性能优化目标与方法

### 3.1 内存管理

#### 3.1.1 内存使用目标

| 场景 | 目标内存 | 峰值上限 | 测试方法 |
|------|----------|----------|----------|
| 空闲状态（无会话） | < 50 MB | 80 MB | Instruments Allocations |
| 单会话（50 条消息） | < 100 MB | 150 MB | Instruments Allocations |
| 多会话（10 个会话） | < 200 MB | 300 MB | Instruments Allocations |
| 长对话（500 条消息） | < 150 MB | 200 MB | Instruments Allocations |
| 大文件处理（10MB 文件） | < 150 MB | 250 MB | Instruments Allocations |

#### 3.1.2 内存优化策略

```swift
// 消息分页加载
class MessageStore: ObservableObject {
    @Published var messages: [Message] = []
    private var allMessages: [Message] = []
    private let pageSize = 50
    private var currentPage = 0

    func loadMoreMessages() {
        let start = currentPage * pageSize
        let end = min(start + pageSize, allMessages.count)

        guard start < allMessages.count else { return }

        let newMessages = Array(allMessages[start..<end])
        messages.insert(contentsOf: newMessages, at: 0)
        currentPage += 1
    }

    func resetAndLoadFirstPage() {
        messages = []
        currentPage = 0
        loadMoreMessages()
    }
}

// 图片内存缓存策略
class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, NSImage>()

    init() {
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
        cache.countLimit = 100
    }

    func image(for key: String) -> NSImage? {
        return cache.object(forKey: key as NSString)
    }

    func setImage(_ image: NSImage, for key: String) {
        let cost = image.size.width * image.size.height * 4 // Approximate memory cost
        cache.setObject(image, forKey: key as NSString, cost: Int(cost))
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}

// 会话数据管理
class SessionDataManager {
    private var loadedSessions: [String: SessionData] = [:]
    private let maxLoadedSessions = 5

    func getSession(_ id: String) -> SessionData? {
        if let data = loadedSessions[id] {
            return data
        }

        // Load from disk
        guard let data = loadFromDisk(id) else { return nil }

        // Manage memory
        if loadedSessions.count >= maxLoadedSessions {
            evictLeastRecentlyUsed()
        }

        loadedSessions[id] = data
        return data
    }

    private func evictLeastRecentlyUsed() {
        // Find and remove LRU session
        guard let lruKey = loadedSessions.keys.first else { return }
        loadedSessions.removeValue(forKey: lruKey)
    }
}

// 使用 weak reference 避免循环引用
class ChatViewModel: ObservableObject {
    weak var delegate: ChatViewModelDelegate?
    private var cancellables = Set<AnyCancellable>()

    // 使用 unowned 避免循环引用（当确定对象生命周期时）
    func performAction() {
        Task { [weak self] in
            guard let self = self else { return }
            // ...
        }
    }
}

// 使用 Lazy 属性延迟加载
struct LazyContentView: View {
    @Lazy var expensiveView = ExpensiveView()

    var body: some View {
        VStack {
            if shouldShowExpensive {
                expensiveView
            }
        }
    }
}
```

#### 3.1.3 内存泄漏检测

| ID | 检测项 | 工具 | 方法 |
|----|--------|------|------|
| M1 | 循环引用 | Instruments Leaks | 长时间运行测试 |
| M2 | 未释放资源 | Instruments Allocations | 场景切换测试 |
| M3 | 缓存未清理 | Instruments Allocations | 内存压力测试 |
| M4 | 定时器泄漏 | Instruments Time Profiler | 后台运行测试 |
| M5 | 观察者未移除 | Instruments Leaks | 对象生命周期测试 |
| M6 | 闭包捕获 | Instruments Leaks | 功能测试 |

#### 3.1.4 内存优化清单

| ID | 优化项 | 描述 | 优先级 |
|----|--------|------|--------|
| MO1 | 消息分页加载 | 长对话分页加载，避免一次性加载 | P0 |
| MO2 | 图片缓存限制 | 限制图片缓存大小和数量 | P0 |
| MO3 | 会话数据管理 | 限制同时加载的会话数量 | P1 |
| MO4 | 代码高亮缓存清理 | 定期清理不常用的代码高亮缓存 | P1 |
| MO5 | Markdown 渲染缓存 | 缓存渲染结果，按需清理 | P1 |
| MO6 | 工具调用结果缓存 | 缓存展开的工具调用结果 | P2 |
| MO7 | 历史记录索引 | 内存索引定期清理 | P2 |
| MO8 | Spotlight 索引 | 后台任务完成后释放资源 | P2 |

### 3.2 启动速度优化

#### 3.2.1 启动时间目标

| 阶段 | 目标时间 | 说明 |
|------|----------|------|
| 冷启动到首屏 | < 1.5s | 应用完全退出后启动 |
| 热启动到首屏 | < 0.5s | 应用后台恢复 |
| CLI 连接建立 | < 2s | 从启动到连接就绪 |
| MenuBar 初始化 | < 0.3s | MenuBar 图标显示 |

#### 3.2.2 启动优化策略

```swift
// AppDelegate 启动优化
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. 立即显示主窗口
        showMainWindow()

        // 2. 异步初始化非关键组件
        Task {
            await initializeSecondaryComponents()
        }
    }

    private func showMainWindow() {
        // 最小化主线程工作
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.contentView = NSHostingView(rootView: ContentView())
        window.makeKeyAndOrderFront(nil)
    }

    private func initializeSecondaryComponents() async {
        // 异步初始化
        await GlobalShortcutManager.shared.registerGlobalShortcuts()
        await SpotlightIndexer.shared.startIndexing()
        await NotificationManager.shared.requestAuthorization()
    }
}

// 延迟加载重型组件
struct ContentView: View {
    @State private var isLoaded = false

    var body: some View {
        Group {
            if isLoaded {
                MainContentView()
            } else {
                LoadingView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isLoaded = true
                        }
                    }
            }
        }
    }
}

// 预编译资源
class ResourcePreloader {
    static func preloadCommonResources() {
        // 预加载常用资源
        _ = NSImage(named: "ClaudeIcon")
        _ = NSImage(named: "MenuBarIcon")

        // 预加载字体
        _ = NSFont.systemFont(ofSize: 13)
        _ = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    }
}

// 首屏最小化
struct MinimalFirstScreen: View {
    var body: some View {
        VStack {
            Image("ClaudeIcon")
                .resizable()
                .frame(width: 64, height: 64)

            Text("Claude Desktop")
                .font(.title2)

            ProgressView()
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

#### 3.2.3 启动优化清单

| ID | 优化项 | 描述 | 优先级 |
|----|--------|------|--------|
| S1 | 延迟初始化 | 非关键组件异步初始化 | P0 |
| S2 | 首屏最小化 | 只渲染必要的首屏内容 | P0 |
| S3 | 资源预加载 | 预加载常用图标和字体 | P1 |
| S4 | CLI 连接异步 | 不阻塞 UI 进行 CLI 连接 | P0 |
| S5 | MenuBar 优先 | 先显示 MenuBar 图标 | P1 |
| S6 | 缓存会话列表 | 缓存会话列表避免磁盘读取 | P2 |

### 3.3 响应时间优化

#### 3.3.1 关键操作响应目标

| 操作 | 目标响应时间 | 最大容忍时间 |
|------|--------------|--------------|
| 输入文字 | < 16ms (60 FPS) | 33ms |
| 发送消息 | < 50ms | 100ms |
| 切换会话 | < 100ms | 200ms |
| 展开工具调用 | < 50ms | 100ms |
| 搜索历史 | < 200ms | 500ms |
| 切换主题 | < 100ms | 200ms |
| 滚动消息列表 | < 16ms (60 FPS) | 33ms |

#### 3.3.2 响应优化实现

```swift
// 主线程保护
extension View {
    func onMainThread(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .init("MainThreadAction"))) { _ in
            if Thread.isMainThread {
                action()
            } else {
                DispatchQueue.main.async {
                    action()
                }
            }
        }
    }
}

// 后台处理重型任务
class HeavyTaskProcessor {
    static let shared = HeavyTaskProcessor()
    private let processingQueue = DispatchQueue(label: "com.claude.desktop.heavy", qos: .userInitiated)

    func processCodeHighlight(_ code: String, language: String) async -> AttributedString {
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                let result = CodeHighlighter.highlight(code, language: language)
                continuation.resume(returning: result)
            }
        }
    }

    func processMarkdown(_ markdown: String) async -> AttributedString {
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                let result = MarkdownRenderer.render(markdown)
                continuation.resume(returning: result)
            }
        }
    }
}

// 虚拟化长列表
struct VirtualizedMessageList: View {
    let messages: [Message]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(messages) { message in
                    MessageView(message: message)
                        .id(message.id)
                }
            }
        }
    }
}

// 防抖与节流
class Debouncer {
    private var workItem: DispatchWorkItem?
    private let delay: TimeInterval

    init(delay: TimeInterval = 0.3) {
        self.delay = delay
    }

    func debounce(action: @escaping () -> Void) {
        workItem?.cancel()
        workItem = DispatchWorkItem(block: action)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem!)
    }
}

class Throttler {
    private var lastExecution: Date?
    private let interval: TimeInterval

    init(interval: TimeInterval = 0.1) {
        self.interval = interval
    }

    func throttle(action: @escaping () -> Void) {
        let now = Date()
        if let last = lastExecution, now.timeIntervalSince(last) < interval {
            return
        }
        lastExecution = now
        action()
    }
}

// 输入防抖示例
struct SearchView: View {
    @State private var searchText: String = ""
    private let debouncer = Debouncer(delay: 0.3)

    var body: some View {
        TextField("Search...", text: $searchText)
            .onChange(of: searchText) { _, newValue in
                debouncer.debounce {
                    performSearch(newValue)
                }
            }
    }

    private func performSearch(_ query: String) {
        // 执行搜索
    }
}
```

### 3.4 资源使用优化

#### 3.4.1 CPU 使用目标

| 场景 | 目标 CPU 使用 | 峰值上限 |
|------|---------------|----------|
| 空闲状态 | < 1% | 5% |
| 流式响应处理 | < 10% | 20% |
| 代码高亮 | < 15% | 30% |
| Markdown 渲染 | < 10% | 20% |
| 后台索引 | < 5% | 10% |

#### 3.4.2 磁盘使用目标

| 数据类型 | 存储位置 | 大小限制 |
|----------|----------|----------|
| 会话数据 | ~/Library/Application Support/ClaudeDesktop/ | 无限制（用户可清理） |
| 缓存数据 | ~/Library/Caches/com.claude.desktop/ | 200 MB |
| 日志文件 | ~/Library/Logs/ClaudeDesktop/ | 50 MB |
| 索引数据 | ~/Library/Caches/com.claude.desktop/Index/ | 100 MB |

#### 3.4.3 能耗优化

```swift
// 后台任务优化
class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    func performIndexing() {
        // 低优先级后台队列
        DispatchQueue.global(qos: .utility).async {
            // 执行索引任务
            SpotlightIndexer.shared.updateIndex()
        }
    }

    func pauseHeavyTasks() {
        // 应用进入后台时暂停重型任务
        HeavyTaskProcessor.shared.pause()
    }

    func resumeTasks() {
        // 应用回到前台时恢复
        HeavyTaskProcessor.shared.resume()
    }
}

// 定时器优化
class OptimizedTimer {
    private var timer: Timer?

    func startRepeatingTask(interval: TimeInterval, task: @escaping () -> Void) {
        // 使用 tolerance 允许系统优化
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            task()
        }
        timer?.tolerance = interval * 0.1 // 10% tolerance
    }

    func pauseWhenInBackground() {
        // 后台时暂停定时器
        timer?.invalidate()
        timer = nil
    }
}

// 动画节能模式
extension Animation {
    static var adaptive: Animation {
        // 根据系统设置调整动画
        let reduceMotion = UserDefaults.standard.bool(forKey: "NSMotionReduceMotion")
        return reduceMotion ? .linear(duration: 0) : .normal
    }
}

// 网络请求优化
class NetworkOptimizer {
    static let shared = NetworkOptimizer()

    func batchRequests(_ requests: [URLRequest]) async -> [Data] {
        // 批量处理请求，减少连接开销
        await withTaskGroup(of: Data.self) { group in
            for request in requests {
                group.addTask {
                    try? await URLSession.shared.data(for: request).0 ?? Data()
                }
            }

            var results: [Data] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }
}
```

#### 3.4.4 资源优化清单

| ID | 优化项 | 描述 | 优先级 |
|----|--------|------|--------|
| C1 | 后台任务低优先级 | 后台任务使用 utility QoS | P1 |
| C2 | 定时器 tolerance | 允许系统优化定时器 | P2 |
| C3 | 减少动画支持 | 支持系统减少动画设置 | P1 |
| C4 | 批量网络请求 | 合并网络请求减少开销 | P2 |
| C5 | 后台暂停重型任务 | 进入后台暂停非必要任务 | P1 |
| C6 | 缓存清理策略 | 定期清理过期缓存 | P2 |
| C7 | 日志轮转 | 日志文件自动轮转 | P2 |

---

## 四、打包与签名

### 4.1 App Bundle 结构

#### 4.1.1 标准目录结构

```
ClaudeDesktop.app/
├── Contents/
│   ├── MacOS/
│   │   └── ClaudeDesktop          # 主可执行文件
│   ├── Resources/
│   │   ├── AppIcon.icns           # 应用图标
│   │   ├── Assets.car             # Asset Catalog 编译产物
│   │   ├── MainMenu.nib           # 菜单定义
│   │   ├── en.lproj/              # 英语本地化
│   │   │   ├── Localizable.strings
│   │   │   └── InfoPlist.strings
│   │   └── zh-Hans.lproj/         # 简体中文本地化
│   │       ├── Localizable.strings
│   │       └── InfoPlist.strings
│   ├── Frameworks/                 # 嵌入的框架（如有）
│   ├── PlugIns/                    # 插件（如有）
│   ├── SharedSupport/              # 共享资源
│   │   └── License.txt
│   ├── CodeSignature/              # 代码签名
│   │   └── CodeResources
│   └── Info.plist                  # 应用信息
```

#### 4.1.2 Info.plist 配置

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- 基本信息 -->
    <key>CFBundleName</key>
    <string>Claude Desktop</string>

    <key>CFBundleDisplayName</key>
    <string>Claude Desktop</string>

    <key>CFBundleIdentifier</key>
    <string>com.claude.desktop</string>

    <key>CFBundleVersion</key>
    <string>100</string>

    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>

    <key>CFBundlePackageType</key>
    <string>APPL</string>

    <key>CFBundleExecutable</key>
    <string>ClaudeDesktop</string>

    <key>CFBundleIconFile</key>
    <string>AppIcon</string>

    <!-- 系统要求 -->
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>

    <!-- 支持的架构 -->
    <key>LSArchitecturePriority</key>
    <array>
        <string>arm64</string>
        <string>x86_64</string>
    </array>

    <!-- 应用分类 -->
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>

    <!-- 高分辨率支持 -->
    <key>NSHighResolutionCapable</key>
    <true/>

    <!-- 支持的文档类型 -->
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Source Code</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.source-code</string>
            </array>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
        </dict>
    </array>

    <!-- URL Schemes -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>com.claude.desktop</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>claudedesktop</string>
            </array>
        </dict>
    </array>

    <!-- 权限说明 -->
    <key>NSAppleEventsUsageDescription</key>
    <string>Claude Desktop needs to send Apple Events to interact with other applications.</string>

    <key>NSCalendarsUsageDescription</key>
    <string>Claude Desktop may access calendars for scheduling tasks.</string>

    <key>NSCameraUsageDescription</key>
    <string>Claude Desktop may use the camera for video calls.</string>

    <key>NSMicrophoneUsageDescription</key>
    <string>Claude Desktop may use the microphone for voice input.</string>

    <!-- 后台模式 -->
    <key>UIBackgroundModes</key>
    <array>
        <string>remote-notification</string>
    </array>

    <!-- App Transport Security -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
    </dict>

    <!-- Help Book -->
    <key>CFBundleHelpBookFolder</key>
    <string>ClaudeDesktop.help</string>

    <key>CFBundleHelpBookName</key>
    <string>com.claude.desktop.help</string>
</dict>
</plist>
```

### 4.2 构建配置

#### 4.2.1 Xcode 构建设置

| 设置项 | Debug | Release |
|--------|-------|---------|
| Optimization Level | -Onone | -O |
| Debug Information | DWARF with dSYM | DWARF with dSYM |
| Strip Debug Symbols | No | Yes |
| Strip Swift Symbols | No | Yes |
| Dead Code Stripping | No | Yes |
| Enable Bitcode | No | No (macOS 不需要) |
| Code Signing Identity | - | Developer ID Application |
| Provisioning Profile | - | Automatic |
| Hardened Runtime | No | Yes |
| Library Validation | No | Yes |

#### 4.2.2 构建脚本

```bash
#!/bin/bash
# build.sh - Claude Desktop 构建脚本

set -e

# 配置
APP_NAME="ClaudeDesktop"
BUNDLE_ID="com.claude.desktop"
VERSION="1.0.0"
BUILD_NUMBER="100"

# 目录
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"

echo "=== Building $APP_NAME v$VERSION ($BUILD_NUMBER) ==="

# 清理
echo "Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 解析参数
CONFIGURATION="Release"
SCHEME="ClaudeDesktop"

# 归档
echo "Archiving..."
xcodebuild archive \
    -scheme "$SCHEME" \
    -archivePath "$ARCHIVE_PATH" \
    -configuration "$CONFIGURATION" \
    -destination "platform=macOS" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    MARKETING_VERSION="$VERSION" \
    ONLY_ACTIVE_ARCH=NO

# 导出
echo "Exporting..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$PROJECT_DIR/ExportOptions.plist"

echo "=== Build completed successfully ==="
echo "App bundle: $EXPORT_PATH/$APP_NAME.app"
```

#### 4.2.3 ExportOptions.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>

    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>

    <key>signingStyle</key>
    <string>automatic</string>

    <key>destination</key>
    <string>export</string>

    <key>compileBitcode</key>
    <false/>

    <key>stripSwiftSymbols</key>
    <true/>

    <key>thinning</key>
    <string>none</string>
</dict>
</plist>
```

### 4.3 代码签名

#### 4.3.1 签名要求

| 项目 | 要求 |
|------|------|
| 签名证书 | Developer ID Application |
| 签名方式 | Hardened Runtime |
| 权限配置 | entitlements.plist |
| 时间戳 | 必须 |
| 公证 | 必须 |

#### 4.3.2 Entitlements.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- 允许 JIT 编译（如果需要） -->
    <key>com.apple.security.cs.allow-jit</key>
    <false/>

    <!-- 允许无签名的可执行内存 -->
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <false/>

    <!-- 禁用库验证 -->
    <key>com.apple.security.cs.disable-library-validation</key>
    <false/>

    <!-- 网络访问 -->
    <key>com.apple.security.network.client</key>
    <true/>

    <!-- 网络服务 -->
    <key>com.apple.security.network.server</key>
    <true/>

    <!-- 文件读写 -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>

    <!-- Apple Events -->
    <key>com.apple.security.automation.apple-events</key>
    <true/>

    <!-- 摄像头 -->
    <key>com.apple.security.device.camera</key>
    <true/>

    <!-- 麦克风 -->
    <key>com.apple.security.device.audio-input</key>
    <true/>

    <!-- 辅助功能 -->
    <key>com.apple.security.automation.accessibility</key>
    <true/>
</dict>
</plist>
```

#### 4.3.3 签名命令

```bash
#!/bin/bash
# sign.sh - 代码签名脚本

APP_PATH="$1"
ENTITLEMENTS="entitlements.plist"
SIGNING_IDENTITY="Developer ID Application: Your Name (TEAM_ID)"

echo "=== Signing $APP_PATH ==="

# 检查应用是否存在
if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

# 签名应用
echo "Signing application..."
codesign --sign "$SIGNING_IDENTITY" \
    --entitlements "$ENTITLEMENTS" \
    --options runtime \
    --timestamp \
    --verbose=4 \
    --force \
    "$APP_PATH"

# 验证签名
echo "Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

# 显示签名信息
echo "Signature info:"
codesign --display --verbose=4 "$APP_PATH"

echo "=== Signing completed successfully ==="
```

### 4.4 Apple 公证

#### 4.4.1 公证流程

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   构建 App     │ ──► │   代码签名     │ ──► │   打包 DMG     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   分发 App     │ ◄── │   Staple 公证   │ ◄── │   等待公证     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
                                                ┌─────────────────┐
                                                │   提交公证     │
                                                └─────────────────┘
```

#### 4.4.2 公证脚本

```bash
#!/bin/bash
# notarize.sh - Apple 公证脚本

APP_PATH="$1"
BUNDLE_ID="com.claude.desktop"
APPLE_ID="$2"
TEAM_ID="$3"
APP_PASSWORD="$4"  # App-specific password

echo "=== Notarizing $APP_PATH ==="

# 检查应用是否存在
if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

# 打包为 zip
echo "Creating zip archive..."
ZIP_PATH="${APP_PATH%.app}.zip"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

# 提交公证
echo "Submitting for notarization..."
SUBMIT_OUTPUT=$(xcrun notarytool submit "$ZIP_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_PASSWORD" \
    --wait \
    2>&1)

echo "$SUBMIT_OUTPUT"

# 检查公证结果
if echo "$SUBMIT_OUTPUT" | grep -q "status: Accepted"; then
    echo "Notarization successful!"

    # Staple 公证结果
    echo "Stapling notarization..."
    xcrun stapler staple "$APP_PATH"

    # 验证 Staple
    echo "Verifying staple..."
    xcrun stapler validate "$APP_PATH"

    echo "=== Notarization completed successfully ==="
else
    echo "Notarization failed!"
    echo "Getting log..."
    REQUEST_ID=$(echo "$SUBMIT_OUTPUT" | grep "id:" | awk '{print $2}')
    if [ -n "$REQUEST_ID" ]; then
        xcrun notarytool log "$REQUEST_ID" \
            --apple-id "$APPLE_ID" \
            --team-id "$TEAM_ID" \
            --password "$APP_PASSWORD"
    fi
    exit 1
fi

# 清理 zip
rm -f "$ZIP_PATH"
```

### 4.5 分发准备

#### 4.5.1 DMG 打包

```bash
#!/bin/bash
# create-dmg.sh - 创建 DMG 安装包

APP_NAME="Claude Desktop"
APP_PATH="build/export/Claude Desktop.app"
DMG_NAME="ClaudeDesktop-1.0.0.dmg"
VOLUME_NAME="Claude Desktop"

echo "=== Creating DMG ==="

# 创建临时目录
TMP_DIR=$(mktemp -d)
DMG_TMP="$TMP_DIR/dmg.tmp"

# 创建 DMG 目录结构
mkdir -p "$DMG_TMP"
cp -R "$APP_PATH" "$DMG_TMP/"

# 创建 Applications 链接
ln -s /Applications "$DMG_TMP/Applications"

# 创建 DMG
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$DMG_TMP" \
    -ov -format UDZO \
    "$DMG_NAME"

# 签名 DMG
echo "Signing DMG..."
codesign --sign "Developer ID Application: Your Name (TEAM_ID)" \
    --timestamp \
    "$DMG_NAME"

# 验证
echo "Verifying DMG..."
codesign --verify --verbose=2 "$DMG_NAME"

# 清理
rm -rf "$TMP_DIR"

echo "=== DMG created: $DMG_NAME ==="
```

#### 4.5.2 Sparkle 更新框架配置

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>Claude Desktop Changelog</title>
        <link>https://claude.ai/desktop/appcast.xml</link>
        <description>Most recent changes with links to updates.</description>
        <language>en</language>

        <item>
            <title>Version 1.0.0</title>
            <pubDate>Mon, 30 Mar 2026 00:00:00 +0000</pubDate>
            <sparkle:version>100</sparkle:version>
            <sparkle:shortVersionString>1.0.0</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
            <description><![CDATA[
                <h2>New Features</h2>
                <ul>
                    <li>Initial release</li>
                    <li>CLI connection and message streaming</li>
                    <li>Session management</li>
                    <li>Tool call visualization</li>
                    <li>Diff view for file changes</li>
                    <li>MenuBar integration</li>
                    <li>Global shortcuts</li>
                    <li>Spotlight search</li>
                    <li>Desktop notifications</li>
                </ul>
            ]]></description>
            <enclosure
                url="https://claude.ai/desktop/ClaudeDesktop-1.0.0.dmg"
                sparkle:edSignature="..." length="..." type="application/octet-stream"/>
        </item>
    </channel>
</rss>
```

---

## 五、文档规划

### 5.1 README.md

#### 5.1.1 README 结构

```markdown
# Claude Desktop Mac

<p align="center">
  <img src="docs/images/logo.png" width="128" height="128" alt="Claude Desktop Logo">
</p>

<p align="center">
  <strong>A native macOS desktop client for Claude Code CLI</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#requirements">Requirements</a> •
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a> •
  <a href="#development">Development</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#license">License</a>
</p>

---

## Features

- **Native macOS Experience** - Built with SwiftUI, follows macOS design guidelines
- **CLI Integration** - Seamless connection to Claude Code CLI
- **Session Management** - Multiple sessions with history and search
- **Tool Visualization** - Real-time display of Claude's tool operations
- **Diff View** - Visual comparison for file changes
- **MenuBar Integration** - Quick access from menu bar
- **Global Shortcuts** - System-wide keyboard shortcuts
- **Spotlight Search** - Find sessions from Spotlight
- **Notifications** - Desktop notifications with quick actions

## Screenshots

[Main Window]
[MenuBar]
[Quick Ask]
[Tool Call View]
[Diff View]

## Requirements

- macOS 14.0 (Sonoma) or later
- Claude Code CLI installed

## Installation

### Download

Download the latest version from [Releases](https://github.com/anthropics/claude-desktop-mac/releases).

### From Source

\`\`\`bash
git clone https://github.com/anthropics/claude-desktop-mac.git
cd claude-desktop-mac
open ClaudeDesktop.xcodeproj
\`\`\`

## Usage

### Quick Start

1. Launch Claude Desktop
2. The app will automatically detect Claude Code CLI
3. Click "Connect" to start a session
4. Type your message and press Cmd+Enter to send

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Cmd+N | New session |
| Cmd+Enter | Send message |
| Cmd+/ | Toggle sidebar |
| Cmd+Shift+A | Quick Ask |
| Cmd+Shift+P | Command Palette |

[More documentation...]

## Development

### Prerequisites

- Xcode 15.0+
- Swift 5.9+
- macOS 14.0+ SDK

### Building

\`\`\`bash
xcodebuild -scheme ClaudeDesktop -configuration Debug
\`\`\`

### Testing

\`\`\`bash
xcodebuild test -scheme ClaudeDesktop -destination 'platform=macOS'
\`\`\`

## Project Structure

\`\`\`
ClaudeDesktop/
├── Sources/
│   ├── CLIDetector/       # CLI detection and launch
│   ├── CLIManager/        # CLI process management
│   ├── Communication/     # Communication pipeline
│   ├── Protocol/          # Message protocol
│   ├── Streaming/         # SSE response handling
│   ├── State/             # Connection state
│   ├── ErrorHandling/     # Error handling
│   ├── Theme/             # Colors, typography, styles
│   ├── Models/            # Data models
│   ├── ViewModels/        # View models
│   ├── Views/             # SwiftUI views
│   ├── Highlighting/      # Code highlighting
│   ├── Upload/            # File upload
│   ├── Shortcuts/         # Keyboard shortcuts
│   ├── History/           # Session history
│   ├── Project/           # Project management
│   ├── MenuBar/           # MenuBar integration
│   ├── GlobalShortcuts/   # Global shortcuts
│   ├── Spotlight/         # Spotlight integration
│   ├── Notifications/     # Notifications
│   └── App/               # App lifecycle
├── Tests/                 # Unit tests
├── docs/                  # Documentation
└── Package.swift          # Swift Package
\`\`\`

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Inspired by [Claude Code CLI](https://claude.ai/claude-code)
```

### 5.2 CHANGELOG.md

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-30

### Added

#### CLI Connection (Phase 1)
- Automatic CLI detection and launch
- Bidirectional communication pipeline
- Message protocol with serialization
- SSE streaming response handling
- Connection state management
- Automatic reconnection on disconnect
- Error handling with user-friendly messages

#### Core UI (Phase 2)
- Session management (create, switch, delete, rename)
- Message bubbles with markdown rendering
- Real-time streaming response display
- Tool call visualization cards
- Diff view for file changes
- Connection status bar
- Dark and light theme support

#### Enhanced Features (Phase 3)
- Syntax highlighting for 20+ languages
- Markdown advanced rendering (tables, diagrams)
- Image upload with drag and drop
- File upload with preview
- Global keyboard shortcuts
- Application shortcut system
- Session history search
- Session restore
- CLAUDE.md visual editor
- Multi-project switching

#### System Integration (Phase 4)
- MenuBar icon with status indicator
- MenuBar quick action menu
- Quick Ask floating window
- Global shortcut activation
- Command palette with fuzzy search
- Spotlight search integration
- Session indexing
- Desktop notifications
- Quick reply from notifications
- Notification action buttons

#### Polish & Release (Phase 5)
- Smooth animations throughout
- Optimized memory usage
- Fast startup time
- Code signing and notarization
- Auto-update support (Sparkle)

### Security
- Hardened runtime enabled
- App Sandbox compatible
- Secure credential storage

### Performance
- Startup time < 1.5 seconds
- Memory usage < 100 MB (typical)
- 60 FPS animations
```

### 5.3 开发指南

#### 5.3.1 开发指南目录

```
docs/
├── development/
│   ├── getting-started.md      # 开发环境配置
│   ├── architecture.md          # 架构设计
│   ├── coding-standards.md      # 编码规范
│   ├── testing.md               # 测试指南
│   ├── debugging.md             # 调试技巧
│   ├── contributing.md          # 贡献指南
│   └── release-process.md       # 发布流程
```

#### 5.3.2 getting-started.md 概要

```markdown
# Getting Started

## Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- Swift 5.9 or later
- Claude Code CLI

## Setup

1. Clone the repository
2. Open `ClaudeDesktop.xcodeproj`
3. Select the debug scheme
4. Build and run

## Project Structure

[Detailed explanation of each module]

## Development Workflow

1. Create a feature branch
2. Write tests first (TDD)
3. Implement the feature
4. Run tests
5. Submit a pull request

## Debugging Tips

- Use LLDB for debugging
- Check Console.app for logs
- Use Instruments for performance analysis
```

### 5.4 用户手册

#### 5.4.1 用户手册目录

```
docs/
├── user-guide/
│   ├── installation.md          # 安装指南
│   ├── quick-start.md           # 快速开始
│   ├── sessions.md              # 会话管理
│   ├── messaging.md             # 消息发送
│   ├── tool-calls.md            # 工具调用
│   ├── diff-view.md             # 差异对比
│   ├── shortcuts.md             # 快捷键
│   ├── menubar.md               # MenuBar 功能
│   ├── notifications.md         # 通知设置
│   ├── settings.md              # 设置说明
│   └── troubleshooting.md       # 故障排除
```

#### 5.4.2 用户手册概要

```markdown
# Claude Desktop User Guide

## Installation

1. Download ClaudeDesktop.dmg
2. Open the DMG file
3. Drag Claude Desktop to Applications
4. Launch Claude Desktop

## Quick Start

### Step 1: Install Claude Code CLI

\`\`\`bash
# Install Claude Code CLI
curl -fsSL https://claude.ai/install | sh
\`\`\`

### Step 2: Connect

1. Launch Claude Desktop
2. The app will detect Claude Code CLI automatically
3. Click "Connect" button
4. Start chatting!

## Features Overview

### Session Management
- Create new sessions with Cmd+N
- Switch sessions from sidebar
- Search history with Cmd+Shift+H

### Messaging
- Type your message
- Press Cmd+Enter to send
- See real-time streaming response

### Tool Calls
- View Claude's operations in real-time
- Expand/collapse tool call cards
- See file changes in Diff view

### MenuBar
- Quick access from menu bar
- Quick Ask for instant questions
- Recent sessions list

### Keyboard Shortcuts

[Complete shortcut list]

## Settings

[Settings explanation]

## Troubleshooting

### CLI Not Found
- Verify Claude Code CLI is installed
- Check PATH environment variable
- Use "Browse" to locate manually

### Connection Issues
- Check network connectivity
- Verify API key is valid
- Try restarting the app

[More troubleshooting...]
```

---

## 六、验收标准

### 6.1 UI 优化验收标准

| ID | 验收项 | 验收标准 | 验证方法 |
|----|--------|----------|----------|
| UI-1 | 动画流畅度 | 所有动画达到 60 FPS | Xcode FPS 计数器 |
| UI-2 | 响应速度 | 关键操作响应时间达标 | Instruments Time Profiler |
| UI-3 | 视觉一致性 | 通过视觉检查清单 | 人工检查 + 自动化测试 |
| UI-4 | VoiceOver 支持 | 完整导航支持 | VoiceOver 测试 |
| UI-5 | 动态字体 | 支持系统字体设置 | 系统设置测试 |
| UI-6 | 高对比度 | 高对比度模式可读 | 系统设置测试 |
| UI-7 | 深浅模式 | 两种模式正常显示 | 系统设置测试 |
| UI-8 | 减少动画 | 尊重系统设置 | 系统设置测试 |

### 6.2 性能优化验收标准

| ID | 验收项 | 验收标准 | 验证方法 |
|----|--------|----------|----------|
| P-1 | 内存使用 | 空闲 < 50MB，单会话 < 100MB | Instruments Allocations |
| P-2 | 启动时间 | 冷启动 < 1.5s | 计时测试 |
| P-3 | CPU 使用 | 空闲 < 1%，处理中 < 10% | Instruments CPU Profiler |
| P-4 | 磁盘使用 | 缓存 < 200MB，日志 < 50MB | Finder 检查 |
| P-5 | 无内存泄漏 | 长时间运行无泄漏 | Instruments Leaks |
| P-6 | 无 ANR | 无主线程阻塞 | Instruments Time Profiler |

### 6.3 打包签名验收标准

| ID | 验收项 | 验收标准 | 验证方法 |
|----|--------|----------|----------|
| S-1 | 代码签名 | 签名验证通过 | codesign --verify |
| S-2 | 公证 | 公证状态 Accepted | notarytool info |
| S-3 | Staple | Staple 验证通过 | stapler validate |
| S-4 | DMG 创建 | DMG 可正常挂载安装 | 手动测试 |
| S-5 | Gatekeeper | 首次启动无警告 | 全新系统测试 |

### 6.4 文档验收标准

| ID | 验收项 | 验收标准 | 验证方法 |
|----|--------|----------|----------|
| D-1 | README | 完整、准确、易懂 | 评审 |
| D-2 | CHANGELOG | 符合 Keep a Changelog 格式 | 自动化检查 |
| D-3 | 开发指南 | 新开发者可按指南开发 | 试运行 |
| D-4 | 用户手册 | 用户可按手册使用 | 用户测试 |

### 6.5 综合验收清单

| 阶段 | 验收项 | 状态 |
|------|--------|------|
| **UI 优化** | | |
| | 动画优化完成 | 待验收 |
| | 响应速度达标 | 待验收 |
| | 视觉一致性检查通过 | 待验收 |
| | 无障碍访问测试通过 | 待验收 |
| **性能优化** | | |
| | 内存使用达标 | 待验收 |
| | 启动时间达标 | 待验收 |
| | CPU 使用达标 | 待验收 |
| | 无内存泄漏 | 待验收 |
| **打包签名** | | |
| | App Bundle 构建成功 | 待验收 |
| | 代码签名验证通过 | 待验收 |
| | Apple 公证通过 | 待验收 |
| | DMG 创建成功 | 待验收 |
| **文档编写** | | |
| | README 完成 | 待验收 |
| | CHANGELOG 完成 | 待验收 |
| | 开发指南完成 | 待验收 |
| | 用户手册完成 | 待验收 |
| **发布准备** | | |
| | 版本号确认 | 待验收 |
| | 更新日志确认 | 待验收 |
| | 发布资源准备 | 待验收 |

---

## 七、时间规划

### 7.1 Phase 5 任务分解

| 周次 | 任务 | 预计工时 |
|------|------|----------|
| Week 1 | UI 动画优化 | 16h |
| Week 1 | 响应速度优化 | 12h |
| Week 2 | 视觉一致性检查与修复 | 12h |
| Week 2 | 无障碍访问增强 | 12h |
| Week 3 | 内存优化 | 16h |
| Week 3 | 启动速度优化 | 8h |
| Week 4 | 资源使用优化 | 8h |
| Week 4 | 性能测试与调优 | 12h |
| Week 5 | App Bundle 构建 | 8h |
| Week 5 | 代码签名与公证 | 8h |
| Week 6 | DMG 打包 | 4h |
| Week 6 | 文档编写 | 16h |
| Week 6 | 最终验收与发布 | 8h |

**总计：约 140 小时（6 周）**

---

## 附录

### A. 参考文档

- [macOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [Notarizing macOS Software Before Distribution](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [SwiftUI Animations](https://developer.apple.com/documentation/swiftui/animations)
- [Instruments Help](https://help.apple.com/instruments/mac/current/)

### B. 工具清单

| 工具 | 用途 |
|------|------|
| Xcode 15+ | 开发、构建、调试 |
| Instruments | 性能分析 |
| Console.app | 日志查看 |
| Accessibility Inspector | 无障碍测试 |
| codesign | 代码签名 |
| notarytool | 公证提交 |
| stapler | 公证 Staple |
| create-dmg | DMG 创建 |

### C. 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0 | 2026-03-30 | 初始版本 |
