# Phase 3: 增强功能 - 功能设计文档

> 版本：1.0
> 日期：2026-03-30
> 作者：Product Manager Agent

---

## 一、功能概述

### 1.1 背景

Phase 2 已完成核心 UI 的构建，包括：
- 会话管理界面（新建、切换、删除、重命名）
- 消息发送与流式响应实时展示
- 基础对话 UI（消息气泡、基础 Markdown 渲染）
- 工具调用可视化展示
- 文件差异对比视图（Diff View）
- 状态栏与连接状态展示

Phase 3 将在这些基础之上，增强用户体验和功能深度，实现：
- 完善的代码高亮与 Markdown 渲染
- 图片/文件上传支持
- 全面的快捷键系统
- 历史记录搜索与恢复
- 项目上下文管理（CLAUDE.md 可视化编辑）
- 多项目切换与管理

### 1.2 目标

构建一个更高效、更智能的 Claude Desktop 应用，实现：
- 代码阅读体验优化（语法高亮、主题支持）
- 丰富的多媒体交互（图片预览、文件拖拽）
- 键盘优先的操作体验
- 会话历史的高效管理
- 项目配置的可视化管理
- 多项目工作流支持

### 1.3 范围

**包含：**
- 代码高亮增强（多语言支持、主题切换）
- Markdown 高级渲染（表格、Mermaid 图表）
- 图片上传与预览
- 文件拖拽上传
- 全局快捷键
- 应用内快捷键系统
- 历史记录搜索
- 会话恢复
- CLAUDE.md 可视化编辑器
- 多项目切换界面

**不包含：**
- MenuBar 快捷入口 - Phase 4
- Spotlight 集成 - Phase 4
- 通知中心集成 - Phase 4
- 性能深度优化 - Phase 5

---

## 二、用户故事

### US-1: 代码高亮体验

**作为** Claude Desktop 用户
**我希望** 能看到高质量的语法高亮代码
**以便于** 快速阅读和理解代码片段

**验收标准：**
- 支持主流编程语言（Swift、Python、JavaScript、Rust 等）
- 支持 5+ 代码主题（暗色/亮色各半）
- 代码块显示语言标签和行号
- 支持一键复制代码
- 支持代码块展开/折叠

### US-2: Markdown 高级渲染

**作为** Claude Desktop 用户
**我希望** Claude 的回复能正确渲染高级 Markdown
**以便于** 获得完整的格式化信息

**验收标准：**
- 支持表格渲染
- 支持 Mermaid 图表渲染
- 支持数学公式（LaTeX）
- 支持 GFM（GitHub Flavored Markdown）
- 支持任务列表（可交互）

### US-3: 图片上传

**作为** Claude Desktop 用户
**我希望** 能上传图片给 Claude 分析
**以便于** 获取基于图片内容的帮助

**验收标准：**
- 支持拖拽上传图片
- 支持点击选择上传图片
- 支持剪贴板粘贴图片
- 上传前显示预览
- 支持 JPG、PNG、GIF、WebP 格式
- 显示上传进度

### US-4: 文件上传

**作为** Claude Desktop 用户
**我希望** 能上传文件给 Claude 分析
**以便于** 获取基于文件内容的帮助

**验收标准：**
- 支持拖拽上传文件
- 支持点击选择上传文件
- 显示文件名和大小
- 支持多文件上传
- 显示上传进度

### US-5: 快捷键操作

**作为** Claude Desktop 用户
**我希望** 能使用快捷键快速操作
**以便于** 提高工作效率

**验收标准：**
- 支持全局快捷键（应用激活时）
- 支持应用内快捷键（特定上下文）
- 快捷键可自定义
- 提供快捷键帮助面板
- 支持 Vim 模式（可选）

### US-6: 历史记录搜索

**作为** Claude Desktop 用户
**我希望** 能搜索历史会话内容
**以便于** 快速找到之前的对话

**验收标准：**
- 支持关键词搜索
- 支持时间范围筛选
- 支持项目筛选
- 搜索结果高亮显示
- 点击搜索结果可跳转到对应消息

### US-7: 会话恢复

**作为** Claude Desktop 用户
**我希望** 能恢复之前中断的会话
**以便于** 继续未完成的工作

**验收标准：**
- 自动保存会话状态
- 支持手动恢复会话
- 显示会话上下文摘要
- 支持从历史记录创建新会话

### US-8: CLAUDE.md 管理

**作为** Claude Desktop 用户
**我希望** 能可视化编辑项目的 CLAUDE.md
**以便于** 管理项目上下文配置

**验收标准：**
- 显示当前项目 CLAUDE.md 内容
- 支持可视化编辑
- 支持模板选择
- 支持语法高亮
- 显示编辑历史

### US-9: 多项目切换

**作为** Claude Desktop 用户
**我希望** 能在不同项目间快速切换
**以便于** 管理多个项目的开发工作

**验收标准：**
- 显示项目列表
- 支持项目搜索
- 显示项目状态（活跃会话数）
- 支持项目收藏
- 快速切换快捷键

---

## 三、界面布局说明

### 3.1 新增界面元素

#### 3.1.1 项目选择器（窗口工具栏）

```
+----------------------------------------------------------+
|  Claude Desktop        [Project ▾] [Model ▾]    [_][□][×] |
+----------------------------------------------------------+
```

点击项目选择器显示下拉菜单：

```
+----------------------------------+
|  Search projects...              |
+----------------------------------+
|  [Star] claude-desktop-mac       | <- 当前项目
|          ~/projects/claude-...   |
|          2 active sessions       |
+----------------------------------+
|  [ ] my-api-project              |
|          ~/projects/my-api       |
|          Last active 2h ago      |
+----------------------------------+
|  [ ] work-frontend               |
|          ~/work/frontend         |
|          Last active yesterday   |
+----------------------------------+
|  ─────────────────────────────── |
|  [+] Add New Project...          |
|  [ ] Manage Projects...          |
+----------------------------------+
```

#### 3.1.2 图片上传区域

**拖拽上传状态：**

```
+----------------------------------------------------------+
|                                                          |
|                    Drop image here                       |
|                    [Image Preview]                       |
|                    file.png (245 KB)                     |
|                                                          |
+----------------------------------------------------------+
```

**上传预览：**

```
+----------------------------------------------------------+
|  [Image Preview  ] [x]                                   |
|  screenshot.png                                          |
|  1280 x 720 | 245 KB                    [Remove] [Send]  |
+----------------------------------------------------------+
```

#### 3.1.3 历史搜索面板

```
+----------------------------------------------------------+
|  [Search Icon] Search history...            [Filters ▾]  |
+----------------------------------------------------------+
|  Time: [All ▾]  Project: [All ▾]                         |
+----------------------------------------------------------+
|  Results for "API integration"                           |
+----------------------------------------------------------+
|  [Session Icon] API Integration Help                     |
|                  claude-desktop-mac                      |
|                  "...need help with API integration..."  |
|                  Mar 28, 2026                            |
+----------------------------------------------------------+
|  [Session Icon] Debugging API Error                      |
|                  my-api-project                          |
|                  "...the API returns 500 error..."       |
|                  Mar 25, 2026                            |
+----------------------------------------------------------+
```

#### 3.1.4 CLAUDE.md 编辑器

```
+----------------------------------------------------------+
|  CLAUDE.md Editor                          [Save] [Reset]|
+----------------------------------------------------------+
|  Template: [Default ▾] [Custom Rules ▾]                  |
+----------------------------------------------------------+
|  # Project: claude-desktop-mac                           |
|                                                          |
|  ## Overview                                             |
|  A native macOS desktop application...                   |
|                                                          |
|  ## Architecture                                         |
|  - SwiftUI for UI layer                                  |
|  - MVVM pattern                                          |
|  ...                                                     |
+----------------------------------------------------------+
|  [Preview] [Edit] [History]                              |
+----------------------------------------------------------+
```

### 3.2 快捷键帮助面板

```
+----------------------------------------------------------+
|  Keyboard Shortcuts                              [Close] |
+----------------------------------------------------------+
|  General                                                 |
|  ─────────────────────────────────────────────────────── |
|  Cmd + N          New session                            |
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
|  [Edit Shortcuts...]                                     |
+----------------------------------------------------------+
```

---

## 四、功能点详细设计

### 4.1 代码高亮增强

#### 4.1.1 功能点列表

| ID | 功能点 | 描述 | 优先级 |
|----|--------|------|--------|
| F3.1.1 | 多语言支持 | 支持 20+ 编程语言语法高亮 | P0 |
| F3.1.2 | 代码主题 | 支持多种代码主题切换 | P0 |
| F3.1.3 | 行号显示 | 显示代码行号 | P0 |
| F3.1.4 | 语言标签 | 显示代码块语言名称 | P0 |
| F3.1.5 | 一键复制 | 复制代码到剪贴板 | P0 |
| F3.1.6 | 展开/折叠 | 长代码块展开折叠 | P1 |
| F3.1.7 | 自动语言检测 | 根据内容自动检测语言 | P2 |
| F3.1.8 | 代码块全屏 | 全屏查看代码块 | P2 |

#### 4.1.2 支持的语言

| 类别 | 语言 |
|------|------|
| 系统/底层 | C, C++, Rust, Go |
| 应用开发 | Swift, Kotlin, Java, C# |
| 脚本语言 | Python, Ruby, JavaScript, TypeScript |
| Web | HTML, CSS, SCSS, Vue, Svelte |
| 数据/配置 | JSON, YAML, TOML, XML |
| Shell | Bash, Zsh, PowerShell |
| 数据库 | SQL, GraphQL |
| 其他 | Markdown, Regex, Dockerfile |

#### 4.1.3 代码主题

**暗色主题：**
| 名称 | 描述 |
|------|------|
| One Dark | Atom 风格，经典暗色 |
| Dracula | 流行的暗色主题 |
| Monokai | Sublime Text 经典 |
| Nord | 北欧风格冷色调 |

**亮色主题：**
| 名称 | 描述 |
|------|------|
| GitHub Light | GitHub 风格 |
| Solarized Light | 护眼经典 |
| One Light | Atom 亮色版本 |

#### 4.1.4 代码块组件设计

```swift
struct CodeBlockView: View {
    let code: String
    let language: String?
    let theme: CodeTheme

    @State private var isExpanded: Bool = true
    @State private var showCopiedFeedback: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(languageDisplayName)
                    .font(.caption)
                    .foregroundColor(.fgSecondaryDark)

                Spacer()

                Button(action: toggleExpand) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                }
                .buttonStyle(.plain)

                Button(action: copyCode) {
                    Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.bgTertiaryDark)

            // Code content
            if isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 0) {
                        // Line numbers
                        VStack(alignment: .trailing) {
                            ForEach(lineNumbers, id: \.self) { num in
                                Text("\(num)")
                                    .font(.codeText)
                                    .foregroundColor(.fgTertiaryDark)
                            }
                        }
                        .padding(.trailing, 8)

                        // Highlighted code
                        Text(highlightedCode)
                            .font(.codeText)
                    }
                    .padding(12)
                }
                .frame(maxHeight: maxHeight)
            }
        }
        .background(Color.codeBgDark)
        .cornerRadius(8)
    }

    private var maxHeight: CGFloat? {
        let lineCount = code.components(separatedBy: "\n").count
        return lineCount > 20 ? 400 : nil
    }
}
```

#### 4.1.5 技术实现方案

**方案选择：Highlightr**

Highlightr 是一个 Swift 语法高亮库，基于 highlight.js，支持 180+ 语言。

```swift
import Highlightr

class CodeHighlighter {
    private let highlightr: Highlightr?

    init() {
        highlightr = Highlightr()
        highlightr?.setTheme(to: "one-dark")
    }

    func highlight(_ code: String, language: String) -> AttributedString? {
        guard let result = highlightr?.highlight(code, as: language) else {
            return nil
        }
        return try? AttributedString(markdown: result)
    }

    func setTheme(_ theme: String) {
        highlightr?.setTheme(to: theme)
    }
}
```

---

### 4.2 Markdown 高级渲染

#### 4.2.1 功能点列表

| ID | 功能点 | 描述 | 优先级 |
|----|--------|------|--------|
| F3.2.1 | 表格渲染 | 支持 Markdown 表格 | P0 |
| F3.2.2 | 任务列表 | 支持可交互任务列表 | P1 |
| F3.2.3 | Mermaid 图表 | 支持 Mermaid 流程图等 | P1 |
| F3.2.4 | 数学公式 | 支持 LaTeX 数学公式 | P1 |
| F3.2.5 | GFM 支持 | GitHub Flavored Markdown | P0 |
| F3.2.6 | 脚注 | 支持脚注语法 | P2 |
| F3.2.7 | 定义列表 | 支持定义列表 | P2 |

#### 4.2.2 表格样式

```
+----------------------------------------------------------+
|  | Name        | Type     | Description             |   |
|  |-------------|----------|-------------------------|   |
|  | id          | UUID     | Unique identifier       |   |
|  | title       | String   | Session title           |   |
|  | messages    | [Message]| Array of messages       |   |
+----------------------------------------------------------+
```

**样式规范：**
- 表头背景：`bg-tertiary`
- 表头文字：`fg-primary`，Semibold
- 行背景：交替 `bg-secondary` / 透明
- 边框：1px `fg-tertiary`
- 单元格内边距：8px 12px

#### 4.2.3 Mermaid 图表

支持以下 Mermaid 图表类型：
- Flowchart（流程图）
- Sequence Diagram（时序图）
- Class Diagram（类图）
- State Diagram（状态图）
- Entity Relationship Diagram（ER 图）
- Gantt Chart（甘特图）

**渲染方案：** 使用 WebView 渲染 Mermaid.js

```swift
struct MermaidView: NSViewRepresentable {
    let mermaidCode: String

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
            <style>
                body { background: transparent; margin: 0; padding: 16px; }
                .mermaid { font-family: sans-serif; }
            </style>
        </head>
        <body>
            <div class="mermaid">\(mermaidCode)</div>
            <script>mermaid.initialize({ startOnLoad: true, theme: 'dark' });</script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}
```

#### 4.2.4 数学公式渲染

使用 MathJax 或 KaTeX 渲染 LaTeX 公式。

**行内公式：** `$E = mc^2$`

**块级公式：**
```
$$
\frac{\partial f}{\partial x} = \lim_{h \to 0} \frac{f(x+h) - f(x)}{h}
$$
```

---

### 4.3 图片上传

#### 4.3.1 功能点列表

| ID | 功能点 | 描述 | 优先级 |
|----|--------|------|--------|
| F3.3.1 | 拖拽上传 | 拖拽图片到输入区上传 | P0 |
| F3.3.2 | 点击上传 | 点击按钮选择上传 | P0 |
| F3.3.3 | 粘贴上传 | 从剪贴板粘贴图片 | P0 |
| F3.3.4 | 图片预览 | 上传前显示预览 | P0 |
| F3.3.5 | 格式限制 | 限制支持格式 | P0 |
| F3.3.6 | 大小限制 | 限制文件大小 | P0 |
| F3.3.7 | 多图上传 | 同时上传多张图片 | P1 |
| F3.3.8 | 图片压缩 | 自动压缩大图 | P2 |

#### 4.3.2 支持的图片格式

| 格式 | 扩展名 | MIME Type | 最大大小 |
|------|--------|-----------|----------|
| JPEG | .jpg, .jpeg | image/jpeg | 10 MB |
| PNG | .png | image/png | 10 MB |
| GIF | .gif | image/gif | 5 MB |
| WebP | .webp | image/webp | 10 MB |

#### 4.3.3 图片上传流程

```
用户操作（拖拽/点击/粘贴）
        │
        ▼
┌─────────────────┐
│ ImageValidator  │ ──▶ 格式检查、大小检查
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ ImagePreview    │ ──▶ 显示预览，等待确认
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ ImageUploader   │ ──▶ 上传到临时位置/Base64 编码
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ MessageBuilder  │ ──▶ 构建包含图片的消息
└─────────────────┘
        │
        ▼
    发送给 Claude
```

#### 4.3.4 图片预览组件

```swift
struct ImagePreviewView: View {
    let images: [ImageAttachment]
    let onRemove: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(images.indices, id: \.self) { index in
                    ImagePreviewItem(
                        image: images[index],
                        onRemove: { onRemove(index) }
                    )
                }
            }
            .padding(8)
        }
        .background(Color.bgTertiaryDark)
    }
}

struct ImagePreviewItem: View {
    let image: ImageAttachment
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Image thumbnail
            Image(nsImage: image.thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .cornerRadius(8)
                .clipped()

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            .buttonStyle(.plain)
            .offset(x: 4, y: -4)

            // File info overlay
            VStack {
                Spacer()
                HStack {
                    Text(image.fileName)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(4)
                .background(Color.black.opacity(0.6))
            }
            .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
        }
    }
}
```

#### 4.3.5 消息中的图片显示

```swift
struct MessageImageView: View {
    let imageUrl: URL
    let width: CGFloat?
    let height: CGFloat?

    @State private var image: NSImage?
    @State private var isExpanded = false

    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: isExpanded ? .infinity : 400)
                    .cornerRadius(8)
                    .onTapGesture {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }
            } else {
                ProgressView()
                    .frame(width: 100, height: 100)
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        // Load image asynchronously
        Task {
            if let data = try? Data(contentsOf: imageUrl),
               let nsImage = NSImage(data: data) {
                await MainActor.run {
                    self.image = nsImage
                }
            }
        }
    }
}
```

---

### 4.4 文件上传

#### 4.4.1 功能点列表

| ID | 功能点 | 描述 | 优先级 |
|----|--------|------|--------|
| F3.4.1 | 拖拽上传 | 拖拽文件到输入区上传 | P0 |
| F3.4.2 | 点击上传 | 点击按钮选择上传 | P0 |
| F3.4.3 | 文件预览 | 显示文件名和大小 | P0 |
| F3.4.4 | 多文件上传 | 同时上传多个文件 | P1 |
| F3.4.5 | 类型限制 | 限制支持的文件类型 | P0 |
| F3.4.6 | 大小限制 | 限制文件大小 | P0 |
| F3.4.7 | 上传进度 | 显示上传进度 | P1 |
| F3.4.8 | 文件预览（代码） | 预览代码文件内容 | P2 |

#### 4.4.2 支持的文件类型

| 类别 | 扩展名 | 说明 |
|------|--------|------|
| 代码文件 | .swift, .py, .js, .ts, .rs, .go, .java, .kt | 源代码 |
| 配置文件 | .json, .yaml, .toml, .xml, .env | 配置 |
| 文档文件 | .md, .txt, .rst | 文档 |
| 数据文件 | .csv, .sql | 数据 |
| 其他 | .sh, .bash, .zsh | 脚本 |

**默认大小限制：** 单文件 5 MB，总计 20 MB

#### 4.4.3 文件上传组件

```swift
struct FileAttachmentView: View {
    let files: [FileAttachment]
    let onRemove: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(files.indices, id: \.self) { index in
                FileAttachmentItem(
                    file: files[index],
                    onRemove: { onRemove(index) }
                )
            }
        }
        .padding(8)
        .background(Color.bgTertiaryDark)
        .cornerRadius(8)
    }
}

struct FileAttachmentItem: View {
    let file: FileAttachment
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // File icon
            Image(systemName: fileIcon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)

            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.callout)
                    .foregroundColor(.fgPrimaryDark)
                    .lineLimit(1)

                Text(file.formattedSize)
                    .font(.caption2)
                    .foregroundColor(.fgTertiaryDark)
            }

            Spacer()

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.fgSecondaryDark)
            }
            .buttonStyle(.plain)
        }
        .padding(4)
    }

    private var fileIcon: String {
        switch file.extension {
        case "swift": return "swift"
        case "py": return "chevron.left.forwardslash.chevron.right"
        case "js", "ts": return "chevron.left.forwardslash.chevron.right"
        case "json": return "curlybraces"
        case "md": return "doc.text"
        default: return "doc"
        }
    }

    private var iconColor: Color {
        switch file.extension {
        case "swift": return .orange
        case "py": return .blue
        case "js": return .yellow
        case "ts": return .blue
        case "json": return .yellow
        default: return .gray
        }
    }
}
```

---

### 4.5 快捷键支持

#### 4.5.1 功能点列表

| ID | 功能点 | 描述 | 优先级 |
|----|--------|------|--------|
| F3.5.1 | 全局快捷键 | 应用激活时的快捷键 | P0 |
| F3.5.2 | 应用内快捷键 | 特定上下文快捷键 | P0 |
| F3.5.3 | 快捷键自定义 | 允许用户自定义快捷键 | P1 |
| F3.5.4 | 快捷键帮助 | 显示快捷键帮助面板 | P0 |
| F3.5.5 | Vim 模式 | 可选的 Vim 风格导航 | P2 |
| F3.5.6 | 快捷键冲突检测 | 检测并提示冲突 | P2 |

#### 4.5.2 默认快捷键映射

**全局快捷键（应用激活时）：**

| 快捷键 | 功能 | 说明 |
|--------|------|------|
| Cmd + N | 新建会话 | 创建新对话 |
| Cmd + W | 关闭会话 | 关闭当前会话 |
| Cmd + Shift + ] | 下一会话 | 切换到下一个会话 |
| Cmd + Shift + [ | 上一会话 | 切换到上一个会话 |
| Cmd + P | 快速项目切换 | 打开项目选择器 |
| Cmd + , | 设置 | 打开设置窗口 |
| Cmd + / | 切换侧边栏 | 显示/隐藏侧边栏 |
| Cmd + F | 搜索历史 | 打开历史搜索面板 |
| Cmd + ? | 快捷键帮助 | 显示快捷键帮助面板 |

**消息输入快捷键：**

| 快捷键 | 功能 | 说明 |
|--------|------|------|
| Cmd + Enter | 发送消息 | 发送当前消息 |
| Shift + Enter | 换行 | 输入框内换行 |
| Cmd + Shift + C | 插入代码块 | 插入代码块语法 |
| Cmd + Shift + I | 插入图片 | 打开图片选择器 |
| Cmd + Shift + A | 添加附件 | 打开文件选择器 |
| Escape | 取消输入 | 清空输入框或取消操作 |

**对话视图快捷键：**

| 快捷键 | 功能 | 说明 |
|--------|------|------|
| Cmd + Up | 滚动到顶部 | 滚动到对话开头 |
| Cmd + Down | 滚动到底部 | 滚动到最新消息 |
| Up Arrow | 编辑上一条 | 编辑上一条用户消息 |
| Space | 展开/折叠 | 展开或折叠工具调用 |
| E | 展开所有 | 展开所有工具调用 |
| C | 折叠所有 | 折叠所有工具调用 |

#### 4.5.3 快捷键管理器

```swift
class KeyboardShortcutManager: ObservableObject {
    @Published var shortcuts: [ShortcutAction: KeyEquivalent] = [:]

    static let shared = KeyboardShortcutManager()

    private init() {
        loadDefaultShortcuts()
    }

    func loadDefaultShortcuts() {
        shortcuts = [
            .newSession: .n,
            .closeSession: .w,
            .nextSession: .rightCurlyBracket,
            .previousSession: .leftCurlyBracket,
            .quickProject: .p,
            .settings: .comma,
            .toggleSidebar: .slash,
            .searchHistory: .f,
            .sendMessage: .return,
        ]
    }

    func registerGlobalShortcuts(for window: NSWindow) {
        // Register keyboard shortcuts with the window
    }

    func updateShortcut(_ action: ShortcutAction, to key: KeyEquivalent) {
        shortcuts[action] = key
        saveShortcuts()
    }
}

enum ShortcutAction: String, CaseIterable {
    case newSession = "newSession"
    case closeSession = "closeSession"
    case nextSession = "nextSession"
    case previousSession = "previousSession"
    case quickProject = "quickProject"
    case settings = "settings"
    case toggleSidebar = "toggleSidebar"
    case searchHistory = "searchHistory"
    case sendMessage = "sendMessage"

    var displayName: String {
        switch self {
        case .newSession: return "New Session"
        case .closeSession: return "Close Session"
        // ...
        }
    }
}
```

#### 4.5.4 SwiftUI 快捷键实现

```swift
struct ContentView: View {
    @FocusState private var focusedField: Field?

    var body: some View {
        VStack {
            // Main content
        }
        .onKeyPress(.escape) {
            handleEscape()
            return .handled
        }
        .keyboardShortcut("n", modifiers: .command) {
            createNewSession()
        }
        .keyboardShortcut("w", modifiers: .command) {
            closeCurrentSession()
        }
        .keyboardShortcut("p", modifiers: .command) {
            showQuickProjectSwitcher()
        }
        .keyboardShortcut("f", modifiers: .command) {
            showHistorySearch()
        }
        .keyboardShortcut("/", modifiers: .command) {
            toggleSidebar()
        }
    }
}
```

---

### 4.6 历史记录

#### 4.6.1 功能点列表

| ID | 功能点 | 描述 | 优先级 |
|----|--------|------|--------|
| F3.6.1 | 全文搜索 | 搜索会话内容 | P0 |
| F3.6.2 | 时间筛选 | 按时间范围筛选 | P0 |
| F3.6.3 | 项目筛选 | 按项目筛选 | P0 |
| F3.6.4 | 搜索高亮 | 高亮显示搜索结果 | P0 |
| F3.6.5 | 快速跳转 | 点击结果跳转到消息 | P0 |
| F3.6.6 | 会话恢复 | 恢复历史会话状态 | P1 |
| F3.6.7 | 搜索历史 | 记录搜索历史 | P2 |
| F3.6.8 | 导出功能 | 导出搜索结果 | P2 |

#### 4.6.2 历史搜索数据模型

```swift
struct SearchQuery: Codable {
    let keywords: String
    let timeRange: TimeRange?
    let projectId: UUID?
    let createdAt: Date
}

struct SearchResult: Identifiable {
    let id: UUID
    let sessionId: UUID
    let messageId: UUID
    let sessionTitle: String
    let projectName: String
    let matchedContent: String
    let highlightRanges: [Range<String.Index>]
    let timestamp: Date
}

enum TimeRange: String, Codable, CaseIterable {
    case today = "Today"
    case yesterday = "Yesterday"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case lastThreeMonths = "Last 3 Months"
    case all = "All Time"
}
```

#### 4.6.3 历史搜索 ViewModel

```swift
@MainActor
@Observable
final class HistorySearchViewModel {
    var searchQuery: String = ""
    var selectedTimeRange: TimeRange = .all
    var selectedProjectId: UUID?
    var searchResults: [SearchResult] = []
    var isSearching: Bool = false
    var recentSearches: [String] = []

    private let historyService: HistoryService

    func search() async {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        defer { isSearching = false }

        let query = SearchQuery(
            keywords: searchQuery,
            timeRange: selectedTimeRange,
            projectId: selectedProjectId,
            createdAt: Date()
        )

        do {
            searchResults = try await historyService.search(query)
        } catch {
            // Handle error
        }
    }

    func selectResult(_ result: SearchResult) async {
        // Navigate to the message in the session
    }

    func resumeSession(_ sessionId: UUID) async {
        // Create a new session continuing from the historical one
    }
}
```

#### 4.6.4 历史搜索服务

```swift
actor HistoryService {
    private let persistenceController: PersistenceController
    private let searchIndex: SearchIndex

    func search(_ query: SearchQuery) async throws -> [SearchResult] {
        var sessions = try await fetchSessions(
            timeRange: query.timeRange,
            projectId: query.projectId
        )

        // Full-text search
        let results = sessions.flatMap { session -> [SearchResult] in
            session.messages.compactMap { message in
                guard let range = message.content.range(of: query.keywords, options: .caseInsensitive) else {
                    return nil
                }

                return SearchResult(
                    id: UUID(),
                    sessionId: session.id,
                    messageId: message.id,
                    sessionTitle: session.title,
                    projectName: session.project?.name ?? "",
                    matchedContent: extractContext(message.content, around: range),
                    highlightRanges: findHighlights(in: message.content, for: query.keywords),
                    timestamp: message.timestamp
                )
            }
        }

        return results.sorted { $0.timestamp > $1.timestamp }
    }

    private func extractContext(_ content: String, around range: Range<String.Index>) -> String {
        let contextLength = 100
        let start = content.index(range.lowerBound, offsetBy: -contextLength, limitedBy: content.startIndex) ?? content.startIndex
        let end = content.index(range.upperBound, offsetBy: contextLength, limitedBy: content.endIndex) ?? content.endIndex
        return String(content[start..<end])
    }
}
```

---

### 4.7 项目上下文管理 (CLAUDE.md)

#### 4.7.1 功能点列表

| ID | 功能点 | 描述 | 优先级 |
|----|--------|------|--------|
| F3.7.1 | CLAUDE.md 显示 | 显示当前项目配置 | P0 |
| F3.7.2 | 可视化编辑 | 图形化编辑 CLAUDE.md | P0 |
| F3.7.3 | 模板选择 | 预设模板快速配置 | P0 |
| F3.7.4 | 语法高亮 | Markdown 语法高亮 | P0 |
| F3.7.5 | 编辑历史 | 查看编辑历史 | P1 |
| F3.7.6 | 预览模式 | 实时预览渲染效果 | P1 |
| F3.7.7 | 规则片段 | 常用规则快速插入 | P2 |
| F3.7.8 | 同步状态 | 显示文件同步状态 | P2 |

#### 4.7.2 CLAUDE.md 模板

**Default 模板：**

```markdown
# Project: [Project Name]

## Overview
[Project description]

## Tech Stack
- Language: [Language]
- Framework: [Framework]

## Architecture
[Architecture description]

## Coding Standards
- [Coding standard 1]
- [Coding standard 2]

## Notes
[Additional notes]
```

**Swift/iOS 模板：**

```markdown
# Project: [Project Name]

## Overview
[Project description]

## Tech Stack
- Language: Swift
- UI Framework: SwiftUI / UIKit
- Architecture: MVVM / Clean Architecture

## Coding Standards
- Use SwiftLint for linting
- Maximum line length: 120 characters
- Use meaningful variable names

## File Organization
- Models: /Models
- Views: /Views
- ViewModels: /ViewModels
- Services: /Services

## Testing
- Unit tests: XCTest
- UI tests: XCUITest
- Minimum coverage: 80%
```

**Web Frontend 模板：**

```markdown
# Project: [Project Name]

## Overview
[Project description]

## Tech Stack
- Language: TypeScript
- Framework: React / Vue / Next.js
- Styling: Tailwind CSS

## Coding Standards
- Use ESLint + Prettier
- Component naming: PascalCase
- File naming: kebab-case

## Directory Structure
- /components - Reusable components
- /pages - Page components
- /hooks - Custom hooks
- /utils - Utility functions

## Testing
- Unit tests: Jest + React Testing Library
- E2E tests: Playwright
```

#### 4.7.3 CLAUDE.md 编辑器组件

```swift
struct ClaudeMdEditorView: View {
    @Binding var content: String
    let projectPath: URL

    @State private var selectedTemplate: CLAUDEMdTemplate?
    @State private var editMode: EditMode = .edit
    @State private var showingTemplatePicker = false
    @State private var hasUnsavedChanges = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Picker("Mode", selection: $editMode) {
                    Text("Edit").tag(EditMode.edit)
                    Text("Preview").tag(EditMode.preview)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)

                Spacer()

                Button("Templates") {
                    showingTemplatePicker = true
                }

                Button("Reset") {
                    resetContent()
                }
                .disabled(!hasUnsavedChanges)

                Button("Save") {
                    saveContent()
                }
                .disabled(!hasUnsavedChanges)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color.bgSecondaryDark)

            Divider()

            // Editor / Preview
            if editMode == .edit {
                TextEditor(text: $content)
                    .font(.codeText)
                    .background(Color.bgPrimaryDark)
                    .onChange(of: content) { _, _ in
                        hasUnsavedChanges = true
                    }
            } else {
                ScrollView {
                    MarkdownView(content: content)
                        .padding()
                }
                .background(Color.bgPrimaryDark)
            }

            // Status bar
            HStack {
                if hasUnsavedChanges {
                    Image(systemName: "circle.fill")
                        .foregroundColor(.orange)
                        .font(.caption2)
                    Text("Unsaved changes")
                        .font(.caption)
                        .foregroundColor(.fgSecondaryDark)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption2)
                    Text("Saved")
                        .font(.caption)
                        .foregroundColor(.fgSecondaryDark)
                }

                Spacer()

                Text("\(content.components(separatedBy: "\n").count) lines")
                    .font(.caption)
                    .foregroundColor(.fgTertiaryDark)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(Color.bgTertiaryDark)
        }
        .sheet(isPresented: $showingTemplatePicker) {
            TemplatePickerView(selectedTemplate: $selectedTemplate)
        }
        .onChange(of: selectedTemplate) { _, newTemplate in
            if let template = newTemplate {
                content = template.content
            }
        }
    }

    private func saveContent() {
        Task {
            let fileURL = projectPath.appendingPathComponent("CLAUDE.md")
            try? content.write(to: fileURL, atomically: true, encoding: .utf8)
            hasUnsavedChanges = false
        }
    }

    private func resetContent() {
        Task {
            let fileURL = projectPath.appendingPathComponent("CLAUDE.md")
            if let savedContent = try? String(contentsOf: fileURL) {
                content = savedContent
                hasUnsavedChanges = false
            }
        }
    }
}

enum EditMode {
    case edit
    case preview
}
```

---

### 4.8 多项目切换

#### 4.8.1 功能点列表

| ID | 功能点 | 描述 | 优先级 |
|----|--------|------|--------|
| F3.8.1 | 项目列表 | 显示所有项目 | P0 |
| F3.8.2 | 快速切换 | 快速切换当前项目 | P0 |
| F3.8.3 | 项目搜索 | 搜索项目名称 | P0 |
| F3.8.4 | 添加项目 | 添加新项目 | P0 |
| F3.8.5 | 项目收藏 | 收藏常用项目 | P1 |
| F3.8.6 | 项目状态 | 显示项目活跃状态 | P1 |
| F3.8.7 | 移除项目 | 从列表中移除项目 | P1 |
| F3.8.8 | 项目图标 | 自定义项目图标 | P2 |

#### 4.8.2 项目数据模型

```swift
struct Project: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var path: URL
    var icon: String?
    var isFavorite: Bool
    var createdAt: Date
    var lastAccessedAt: Date?

    var claudeMdPath: URL {
        path.appendingPathComponent("CLAUDE.md")
    }

    var hasClaudeMd: Bool {
        FileManager.default.fileExists(atPath: claudeMdPath.path)
    }

    var activeSessionCount: Int {
        // Count sessions for this project
        0
    }
}
```

#### 4.8.3 项目选择器组件

```swift
struct ProjectPickerView: View {
    @Binding var selectedProject: Project?
    @Binding var projects: [Project]
    @State private var searchText: String = ""
    @State private var showAddProject: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.fgTertiaryDark)
                TextField("Search projects...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color.bgTertiaryDark)

            Divider()

            // Project list
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Favorites section
                    if !favoriteProjects.isEmpty {
                        Section("Favorites") {
                            ForEach(favoriteProjects) { project in
                                ProjectItemView(
                                    project: project,
                                    isSelected: selectedProject?.id == project.id,
                                    onSelect: { selectedProject = project }
                                )
                            }
                        }
                    }

                    // All projects section
                    Section("All Projects") {
                        ForEach(filteredProjects) { project in
                            ProjectItemView(
                                project: project,
                                isSelected: selectedProject?.id == project.id,
                                onSelect: { selectedProject = project }
                            )
                        }
                    }
                }
            }

            Divider()

            // Footer actions
            HStack {
                Button(action: { showAddProject = true }) {
                    Label("Add Project", systemImage: "plus")
                }

                Spacer()

                Button("Manage...") {
                    // Open project management
                }
            }
            .padding(8)
            .background(Color.bgSecondaryDark)
        }
        .frame(width: 300, maxHeight: 400)
        .sheet(isPresented: $showAddProject) {
            AddProjectView(projects: $projects)
        }
    }

    private var favoriteProjects: [Project] {
        projects.filter { $0.isFavorite && matchesSearch($0) }
    }

    private var filteredProjects: [Project] {
        projects.filter { !$0.isFavorite && matchesSearch($0) }
    }

    private func matchesSearch(_ project: Project) -> Bool {
        searchText.isEmpty || project.name.localizedCaseInsensitiveContains(searchText)
    }
}

struct ProjectItemView: View {
    let project: Project
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Project icon
            Image(systemName: project.isFavorite ? "star.fill" : "folder")
                .foregroundColor(project.isFavorite ? .yellow : .accentPrimary)
                .frame(width: 24)

            // Project info
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.callout)
                    .foregroundColor(isSelected ? .fgInverseDark : .fgPrimaryDark)
                    .lineLimit(1)

                HStack {
                    Text(project.path.path)
                        .font(.caption2)
                        .foregroundColor(.fgTertiaryDark)
                        .lineLimit(1)

                    if project.activeSessionCount > 0 {
                        Text("\(project.activeSessionCount) sessions")
                            .font(.caption2)
                            .foregroundColor(.accentSuccess)
                    }
                }
            }

            Spacer()

            // CLAUDE.md indicator
            if project.hasClaudeMd {
                Image(systemName: "doc.text")
                    .foregroundColor(.fgTertiaryDark)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.bgSelectedDark : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}
```

---

## 五、与已有功能的集成

### 5.1 依赖关系图

```
Phase 3 增强功能层
         │
         ├──────────────────┬──────────────────┬──────────────────┐
         │                  │                  │                  │
         ▼                  ▼                  ▼                  ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│  代码高亮     │   │  图片/文件    │   │  快捷键       │   │  历史记录    │
│  Markdown    │   │  上传         │   │  系统         │   │  项目管理    │
└──────────────┘   └──────────────┘   └──────────────┘   └──────────────┘
         │                  │                  │                  │
         └──────────────────┴──────────────────┴──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │   Phase 2 UI     │
                    │   MessageView    │
                    │   InputView      │
                    │   SessionManager │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │   Phase 1 CLI    │
                    │   CLIConnector   │
                    └──────────────────┘
```

### 5.2 集成点说明

#### 5.2.1 代码高亮与 MessageView 集成

```swift
// MessageView.swift 中集成代码高亮
struct MessageView: View {
    let message: Message

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(message.contentBlocks) { block in
                switch block.type {
                case .code:
                    CodeBlockView(
                        code: block.content,
                        language: block.language,
                        theme: themeSettings.codeTheme
                    )
                case .markdown:
                    MarkdownView(content: block.content)
                case .image:
                    MessageImageView(imageUrl: block.url)
                }
            }
        }
    }
}
```

#### 5.2.2 图片上传与 InputView 集成

```swift
// InputView.swift 中集成图片上传
struct InputView: View {
    @State private var attachments: [Attachment] = []
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            // Attachments preview
            if !attachments.isEmpty {
                AttachmentPreviewView(attachments: $attachments)
            }

            // Input area
            TextEditor(text: $inputText)
                .onDrop(of: [.image, .fileURL], isTargeted: $isDropTargeted) { providers in
                    handleDrop(providers)
                    return true
                }

            // Toolbar
            InputToolbar(
                onAttachImage: { showImagePicker() },
                onAttachFile: { showFilePicker() }
            )
        }
    }
}
```

#### 5.2.3 快捷键与全局集成

```swift
// AppDelegate.swift 中注册全局快捷键
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        KeyboardShortcutManager.shared.registerGlobalShortcuts(for: NSApp.mainWindow!)
    }
}

// ContentView.swift 中处理快捷键
struct ContentView: View {
    var body: some View {
        mainContent
            .onKeyPress(.escape) {
                handleEscape()
                return .handled
            }
            .keyboardShortcut(KeyEquivalent(Character("n")), modifiers: .command) {
                createNewSession()
            }
    }
}
```

#### 5.2.4 历史记录与 SessionManager 集成

```swift
// SessionManager.swift 扩展
extension SessionManager {
    func searchHistory(query: SearchQuery) async throws -> [SearchResult] {
        return try await historyService.search(query)
    }

    func resumeSession(_ sessionId: UUID) async throws -> Session {
        let historicalSession = try await historyService.fetchSession(sessionId)
        // Create new session continuing from historical context
        return try await createSession(from: historicalSession)
    }
}
```

#### 5.2.5 项目管理与 CLI 集成

```swift
// CLIConnector.swift 扩展
extension CLIConnector {
    func switchProject(to projectPath: URL) async throws {
        // Update working directory for CLI
        try await send(.setWorkingDirectory(projectPath.path))
    }

    func loadClaudeMd(for projectPath: URL) async throws -> String {
        let fileURL = projectPath.appendingPathComponent("CLAUDE.md")
        return try String(contentsOf: fileURL)
    }

    func saveClaudeMd(_ content: String, for projectPath: URL) async throws {
        let fileURL = projectPath.appendingPathComponent("CLAUDE.md")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
```

---

## 六、验收标准

### 6.1 功能验收标准

| 场景 | 预期结果 | 优先级 |
|------|----------|--------|
| 代码高亮 | 代码块显示语法高亮，语言标签正确 | P0 |
| 代码主题切换 | 切换主题后所有代码块更新 | P0 |
| 表格渲染 | Markdown 表格正确显示 | P0 |
| 拖拽图片上传 | 图片显示预览，发送后正确传递 | P0 |
| 粘贴图片 | 剪贴板图片可直接粘贴上传 | P0 |
| 文件上传 | 文件信息正确显示，发送后可访问 | P0 |
| 全局快捷键 | 应用激活时快捷键立即响应 | P0 |
| 快捷键帮助 | 按 Cmd+? 显示帮助面板 | P0 |
| 历史搜索 | 关键词搜索返回匹配结果 | P0 |
| 搜索结果跳转 | 点击结果跳转到对应消息 | P0 |
| CLAUDE.md 显示 | 正确显示当前项目配置 | P0 |
| CLAUDE.md 编辑 | 编辑后保存到文件 | P0 |
| 项目切换 | 切换后 CLI 工作目录更新 | P0 |
| 项目搜索 | 输入关键词筛选项目列表 | P0 |

### 6.2 性能验收标准

| 指标 | 目标值 |
|------|--------|
| 代码高亮渲染 | < 100ms |
| 表格渲染 | < 50ms |
| Mermaid 图表渲染 | < 500ms |
| 图片预览加载 | < 200ms |
| 历史搜索响应 | < 300ms |
| 项目切换 | < 200ms |
| 快捷键响应 | < 50ms |

### 6.3 用户体验验收标准

| 指标 | 目标值 |
|------|--------|
| 拖拽响应 | 即时视觉反馈 |
| 上传进度 | 清晰显示 |
| 搜索体验 | 实时结果更新 |
| 快捷键冲突 | 提示并可解决 |
| 错误处理 | 友好提示信息 |

---

## 七、优先级排序

### P0 - 核心功能（必须完成）

```
┌─────────────────────────────────────────────────────────────┐
│                    P0 核心功能                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  代码高亮                                                    │
│  ├── F3.1.1 多语言支持                                      │
│  ├── F3.1.2 代码主题                                        │
│  ├── F3.1.3 行号显示                                        │
│  ├── F3.1.4 语言标签                                        │
│  └── F3.1.5 一键复制                                        │
│                                                             │
│  Markdown 高级渲染                                           │
│  ├── F3.2.1 表格渲染                                        │
│  └── F3.2.5 GFM 支持                                        │
│                                                             │
│  图片上传                                                    │
│  ├── F3.3.1 拖拽上传                                        │
│  ├── F3.3.2 点击上传                                        │
│  ├── F3.3.3 粘贴上传                                        │
│  ├── F3.3.4 图片预览                                        │
│  ├── F3.3.5 格式限制                                        │
│  └── F3.3.6 大小限制                                        │
│                                                             │
│  文件上传                                                    │
│  ├── F3.4.1 拖拽上传                                        │
│  ├── F3.4.2 点击上传                                        │
│  ├── F3.4.3 文件预览                                        │
│  ├── F3.4.5 类型限制                                        │
│  └── F3.4.6 大小限制                                        │
│                                                             │
│  快捷键                                                      │
│  ├── F3.5.1 全局快捷键                                      │
│  ├── F3.5.2 应用内快捷键                                    │
│  └── F3.5.4 快捷键帮助                                      │
│                                                             │
│  历史记录                                                    │
│  ├── F3.6.1 全文搜索                                        │
│  ├── F3.6.2 时间筛选                                        │
│  ├── F3.6.3 项目筛选                                        │
│  ├── F3.6.4 搜索高亮                                        │
│  └── F3.6.5 快速跳转                                        │
│                                                             │
│  CLAUDE.md 管理                                              │
│  ├── F3.7.1 CLAUDE.md 显示                                  │
│  ├── F3.7.2 可视化编辑                                      │
│  ├── F3.7.3 模板选择                                        │
│  └── F3.7.4 语法高亮                                        │
│                                                             │
│  多项目切换                                                  │
│  ├── F3.8.1 项目列表                                        │
│  ├── F3.8.2 快速切换                                        │
│  ├── F3.8.3 项目搜索                                        │
│  └── F3.8.4 添加项目                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### P1 - 重要功能（应该完成）

| 模块 | 功能点 |
|------|--------|
| 代码高亮 | F3.1.6 展开/折叠 |
| Markdown | F3.2.2 任务列表、F3.2.3 Mermaid 图表、F3.2.4 数学公式 |
| 图片上传 | F3.3.7 多图上传 |
| 文件上传 | F3.4.4 多文件上传、F3.4.7 上传进度 |
| 快捷键 | F3.5.3 快捷键自定义 |
| 历史记录 | F3.6.6 会话恢复 |
| CLAUDE.md | F3.7.5 编辑历史、F3.7.6 预览模式 |
| 项目管理 | F3.8.5 项目收藏、F3.8.6 项目状态、F3.8.7 移除项目 |

### P2 - 增强功能（可以完成）

| 模块 | 功能点 |
|------|--------|
| 代码高亮 | F3.1.7 自动语言检测、F3.1.8 代码块全屏 |
| Markdown | F3.2.6 脚注、F3.2.7 定义列表 |
| 图片上传 | F3.3.8 图片压缩 |
| 文件上传 | F3.4.8 文件预览（代码） |
| 快捷键 | F3.5.5 Vim 模式、F3.5.6 快捷键冲突检测 |
| 历史记录 | F3.6.7 搜索历史、F3.6.8 导出功能 |
| CLAUDE.md | F3.7.7 规则片段、F3.7.8 同步状态 |
| 项目管理 | F3.8.8 项目图标 |

---

## 八、里程碑

| 里程碑 | 功能点 | 预计周期 |
|--------|--------|----------|
| M1: 代码与 Markdown | 代码高亮、Markdown 高级渲染 | 第 1 周 |
| M2: 上传功能 | 图片上传、文件上传 | 第 2 周 |
| M3: 快捷键系统 | 全局快捷键、应用内快捷键、帮助面板 | 第 3 周 |
| M4: 历史记录 | 搜索、筛选、跳转、恢复 | 第 4 周 |
| M5: 项目管理 | CLAUDE.md 编辑、多项目切换 | 第 5 周 |
| M6: 集成测试 | 所有功能集成测试与修复 | 第 6 周 |

---

## 九、风险与应对

| 风险 | 概率 | 影响 | 应对措施 |
|------|------|------|----------|
| 代码高亮性能问题 | 中 | 中 | 虚拟化渲染、延迟加载 |
| Mermaid 渲染复杂 | 中 | 中 | 使用 WebView、限制图表类型 |
| 图片上传内存占用 | 低 | 中 | 压缩、流式处理 |
| 快捷键冲突 | 中 | 低 | 冲突检测、可自定义 |
| 历史搜索性能 | 中 | 中 | 建立索引、分页加载 |
| CLAUDE.md 同步 | 低 | 低 | 本地文件监听 |

---

## 十、技术实现要点

### 10.1 第三方库依赖

| 库 | 用途 | 许可证 |
|-----|------|--------|
| Highlightr | 代码语法高亮 | MIT |
| MarkdownUI | Markdown 渲染 | MIT |
| Mermaid.js (via WebView) | 图表渲染 | MIT |

### 10.2 数据存储

| 数据 | 存储方式 | 位置 |
|------|----------|------|
| 会话历史 | SQLite/CoreData | ~/Library/Application Support/Claude Desktop/ |
| 项目列表 | JSON | ~/Library/Application Support/Claude Desktop/projects.json |
| 用户设置 | UserDefaults | 系统标准位置 |
| 快捷键配置 | JSON | ~/Library/Application Support/Claude Desktop/shortcuts.json |

### 10.3 性能优化要点

1. **代码高亮**：使用异步渲染，避免阻塞主线程
2. **图片处理**：压缩后再上传，使用缩略图预览
3. **历史搜索**：建立全文索引，使用 FTS（全文搜索）
4. **项目列表**：延迟加载项目详情

---

## 十一、参考资源

- [Highlightr Documentation](https://github.com/raspu/Highlightr)
- [MarkdownUI Documentation](https://github.com/gonzalezreal/swift-markdown-ui)
- [Mermaid Documentation](https://mermaid.js.org/)
- Phase 1 设计文档: `docs/phase1-cli-connector-design.md`
- Phase 2 设计文档: `docs/phase2-core-ui-design.md`
- UI 设计指南: `docs/ui-design-guide.md`
- UI 组件规格: `docs/ui-component-specs.md`

---

## 更新日志

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-03-30 | 1.0 | 初始版本，完成 Phase 3 增强功能设计 |
