# Web 版 Code Agent / AI Coding Assistant 研究报告

> 研究日期: 2026-03-30

## 目录

1. [Claude Code](#1-claude-code)
2. [Cursor](#2-cursor)
3. [OpenHands](#3-openhands)
4. [Bolt.new](#4-boltnew)
5. [v0.dev](#5-v0dev)
6. [Replit](#6-replit)
7. [Windsurf](#7-windsurf)
8. [Aider](#8-aider)
9. [Continue.dev](#9-continuedev)
10. [功能模块对比分析](#功能模块对比分析)

---

## 1. Claude Code

### 项目信息

- **开发商**: Anthropic
- **项目 URL**: https://claude.ai/code
- **GitHub**: https://github.com/anthropics/claude-code
- **类型**: 终端 + Web + IDE 集成

### 核心功能

| 功能 | 描述 |
|------|------|
| Agentic 编码 | 理解代码库，执行任务，解释代码，处理 git 工作流 |
| 自然语言命令 | 通过自然语言命令完成日常任务 |
| 多平台支持 | 终端、VS Code、JetBrains、GitHub 集成 |
| Git 工作流 | 自动化提交、PR 创建、代码审查 |
| 文件操作 | 读取、编辑、创建文件 |
| Bash 命令执行 | 运行终端命令、测试、构建 |

### UI 设计特点

```
+----------------------------------------------------------+
|  Claude Code (Terminal/Web)                               |
+----------------------------------------------------------+
|  > 用户输入自然语言命令                                    |
|                                                          |
|  [工具调用可视化]                                         |
|  - Read file: src/main.py                                |
|  - Edit file: src/main.py                                |
|  - Bash: npm test                                        |
|                                                          |
|  [代码差异预览]                                           |
|  - 展示修改前后对比                                       |
|  - 高亮显示变更部分                                       |
+----------------------------------------------------------+
```

### 技术架构

- **语言**: Node.js/TypeScript
- **分发方式**: NPM 包
- **模型**: Claude 4.5/4.6 系列
- **插件系统**: 支持 MCP (Model Context Protocol)

### 用户交互流程

1. 用户在终端/Web 输入自然语言命令
2. Claude Code 分析代码库上下文
3. 执行工具调用 (Read/Edit/Bash)
4. 展示执行结果和代码差异
5. 用户确认或继续迭代

### 特色功能

- **/commit**: 自动生成 Git 提交
- **/feature-dev**: 7 阶段功能开发工作流
- **/hookify**: 创建行为钩子防止不良操作
- **MCP 集成**: 扩展工具能力
- **多代理编排**: 支持子代理协作

---

## 2. Cursor

### 项目信息

- **开发商**: Anysphere
- **项目 URL**: https://cursor.com
- **GitHub**: https://github.com/getcursor
- **类型**: 桌面 IDE + Cloud Agent

### 核心功能

| 功能 | 描述 |
|------|------|
| AI Chat | 代码库级别的智能对话 |
| Code Generation | 自然语言生成代码 |
| Cursor Tab | AI 代码补全 |
| Inline Edit | 行内代码编辑 (Cmd/Ctrl+K) |
| Cloud Agent | 云端代理自动执行任务 |
| User Rules | 全局用户偏好配置 |

### UI 设计特点

```
+----------------------------------------------------------+
|  Cursor IDE                                              |
+-------------------+--------------------------------------+
|  文件浏览器       |  代码编辑器                          |
|  - src/          |  + AI Inline Edit                   |
|    - main.ts     |  |  // 光标位置触发 AI 补全          |
|    - utils.ts    |  |  function example() {            |
|  - tests/        |  |    // AI 生成的代码...            |
|                   |  |  }                                |
+-------------------+--------------------------------------+
|  AI Chat Panel (Cmd/Ctrl+L)                             |
|  用户: 帮我重构这个组件                                  |
|  Cursor: [代码建议] [应用] [丢弃]                        |
+----------------------------------------------------------+
```

### 技术架构

- **基础**: VS Code 分支
- **语言**: TypeScript
- **模型**: 多模型支持 (Claude, GPT-4, Gemini)
- **API**: Cursor Cloud Agent API

### 用户交互流程

1. 打开项目文件
2. 使用 Cmd/Ctrl+L 打开 AI Chat
3. 描述需求或选择代码提问
4. AI 提供代码建议
5. 一键应用或迭代修改

### 特色功能

- **Deeplinks**: URL 深度链接预设提示词
- **Cloud Agent API**: 程序化创建云端代理
- **JetBrains 集成**: 支持 JetBrains IDE 插件
- **Codebase Understanding**: 深度理解代码库

---

## 3. OpenHands

### 项目信息

- **开发商**: All Hands AI
- **项目 URL**: https://docs.openhands.dev
- **GitHub**: https://github.com/OpenDevin/OpenDevin
- **类型**: 开源 Web GUI + CLI

### 核心功能

| 功能 | 描述 |
|------|------|
| Web GUI | 完整的图形化 Web 界面 |
| CLI | 命令行终端界面 |
| Web Interface | 浏览器中的终端 UI |
| 文件管理 | 工作区文件操作 |
| 会话管理 | 多会话支持 |
| Docker 集成 | 容器化运行环境 |

### UI 设计特点

```
+----------------------------------------------------------+
|  OpenHands Web GUI                                       |
+-------------------+--------------------------------------+
|  会话列表         |  主工作区                            |
|  - Session 1     |  + 文件浏览器                        |
|  - Session 2     |  |  - src/                          |
|                   |  |  - tests/                        |
|                   |  + 终端/代码编辑器                   |
+-------------------+--------------------------------------+
|  AI Chat Panel                                           |
|  用户: 帮我添加一个新功能                                 |
|  OpenHands: [执行命令] [编辑文件] [显示结果]              |
+----------------------------------------------------------+
```

### 技术架构

- **语言**: Python
- **框架**: FastAPI
- **容器**: Docker
- **模型**: 多 LLM 支持

### 用户交互流程

1. 启动 Web 服务: `openhands serve`
2. 浏览器访问 http://localhost:12000
3. 创建新会话
4. 与 AI 代理交互
5. 查看文件变更和命令执行

### 特色功能

- **Web vs GUI**: 轻量 Web 终端 vs 完整 GUI
- **API**: RESTful API 集成
- **工作区隔离**: 会话级工作区
- **.gitignore 支持**: 自动忽略规则

---

## 4. Bolt.new

### 项目信息

- **开发商**: StackBlitz
- **项目 URL**: https://bolt.new
- **GitHub**: https://github.com/stackblitz/bolt.new
- **类型**: 浏览器端全栈开发平台

### 核心功能

| 功能 | 描述 |
|------|------|
| 全栈应用生成 | 从自然语言生成完整应用 |
| WebContainers | 浏览器内运行 Node.js |
| 实时预览 | 即时查看应用效果 |
| 一键部署 | 快速部署到云端 |
| GitHub 集成 | 版本控制和协作 |
| Figma 集成 | 设计稿转代码 |

### UI 设计特点

```
+----------------------------------------------------------+
|  Bolt.new                                                |
+-------------------+--------------------------------------+
|  聊天面板         |  代码编辑器 + 预览                   |
|  用户: 创建一个   |  +--------------------------------+|
|  博客应用         |  |  [代码] [预览] [终端]          ||
|                   |  |                                ||
|  Bolt: [生成中...] |  |   Live Preview                 ||
|                   |  |   +--------------------------+ ||
|                   |  |   |  应用实时预览             | ||
|                   |  |   +--------------------------+ ||
+-------------------+--------------------------------------+
```

### 技术架构

- **运行时**: StackBlitz WebContainers
- **语言**: TypeScript
- **框架**: 支持多种前端框架
- **模型**: 多 LLM 支持

### 用户交互流程

1. 访问 bolt.new
2. 输入应用描述
3. AI 生成代码
4. 实时预览和修改
5. 部署或导出

### 特色功能

- **零本地设置**: 完全在浏览器中运行
- **多框架支持**: React, Vue, Svelte 等
- **移动应用**: 通过 Expo 支持
- **支付集成**: Stripe 集成

---

## 5. v0.dev

### 项目信息

- **开发商**: Vercel
- **项目 URL**: https://v0.dev
- **GitHub**: https://github.com/vercel/v0-sdk
- **类型**: AI 驱动的 Web 开发平台

### 核心功能

| 功能 | 描述 |
|------|------|
| UI 组件生成 | 从自然语言生成 React 组件 |
| 全栈应用 | 生成完整 Next.js 应用 |
| 多轮对话 | 迭代优化代码 |
| 框架优化 | 专注于 Next.js/React/Tailwind |
| AI SDK 集成 | 与 Vercel AI SDK 无缝集成 |

### UI 设计特点

```
+----------------------------------------------------------+
|  v0.dev                                                  |
+-------------------+--------------------------------------+
|  聊天界面         |  生成结果                            |
|  用户: 创建一个   |  +--------------------------------+|
|  导航组件         |  |  [预览] [代码] [部署]          ||
|                   |  |                                ||
|  v0: [生成组件...] |  |   Component Preview            ||
|                   |  |   +--------------------------+ ||
|                   |  |   |  实时组件预览             | ||
|                   |  |   +--------------------------+ ||
|                   |  |                                ||
|                   |  |   Code:                       ||
|                   |  |   ```tsx                      ||
|                   |  |   export function Nav() {...}  ||
|                   |  |   ```                         ||
+-------------------+--------------------------------------+
```

### 技术架构

- **语言**: TypeScript
- **框架**: Next.js, React, Tailwind CSS
- **组件库**: shadcn/ui
- **API**: v0 Platform API

### 用户交互流程

1. 访问 v0.dev
2. 描述需要的 UI 组件
3. AI 生成代码
4. 预览和迭代
5. 导出或部署到 Vercel

### 特色功能

- **Model API**: 生成 React 组件和 Next.js 应用
- **Platform API**: 完整开发基础设施
- **v0 SDK**: 程序化访问
- **MCP Server**: Claude Code 集成

---

## 6. Replit

### 项目信息

- **开发商**: Replit
- **项目 URL**: https://replit.com
- **类型**: 浏览器端开发平台

### 核心功能

| 功能 | 描述 |
|------|------|
| Replit Agent | AI 编码代理 |
| Replit Assistant | AI 编码助手 |
| 实时协作 | 多人协作开发 |
| 即时部署 | 一键部署应用 |
| 多语言支持 | 支持多种编程语言 |
| Ghostwriter | AI 代码补全 |

### UI 设计特点

```
+----------------------------------------------------------+
|  Replit                                                  |
+-------------------+--------------------------------------+
|  文件树           |  代码编辑器                          |
|  - main.py       |  +--------------------------------+|
|  - utils.py      |  |  # AI 助手高亮错误              ||
|                   |  |  def hello():                  ||
|                   |  |      print("Hello")            ||
|                   |  |      # [Debug with AI] 按钮    ||
+-------------------+--------------------------------------+
|  AI Assistant Panel                                      |
|  用户: 解释这段代码                                       |
|  AI: [代码解释]                                          |
|  用户: 修改这个函数                                       |
|  AI: [代码建议] [应用修改]                                |
+-------------------+--------------------------------------+
|  终端 | 预览 | 输出                                    |
+----------------------------------------------------------+
```

### 技术架构

- **语言**: 多语言支持
- **运行时**: Replit 容器
- **部署**: Replit Deployments
- **AI**: Replit AI

### 用户交互流程

1. 创建或导入项目
2. 使用 AI Agent 编码
3. 实时预览和测试
4. 部署或分享

### 特色功能

- **代码解释**: 高亮代码获取解释
- **AI 修改**: 高亮代码请求修改
- **错误调试**: AI 辅助调试
- **模板库**: 丰富的项目模板

---

## 7. Windsurf

### 项目信息

- **开发商**: Codeium
- **项目 URL**: https://codeium.com/windsurf
- **类型**: AI IDE

### 核心功能

| 功能 | 描述 |
|------|------|
| Cascade | Agentic AI 助手 |
| Code Mode | 代码修改模式 |
| Chat Mode | 对话模式 |
| 代码补全 | Tab 补全 |
| 语音输入 | 语音命令 |
| Checkpoints | 工作检查点 |

### UI 设计特点

```
+----------------------------------------------------------+
|  Windsurf IDE                                            |
+-------------------+--------------------------------------+
|  文件浏览器       |  代码编辑器                          |
|  - src/          |  +--------------------------------+|
|    - index.ts    |  |  // Cascade 代码建议            ||
|                   |  |  function example() {          ||
|                   |  |    // AI 生成的代码            ||
|                   |  |  }                             ||
+-------------------+--------------------------------------+
|  Cascade Panel (Cmd/Ctrl+L)                              |
|  [Code] [Chat]                                           |
|  用户: 帮我重构这个函数                                   |
|  Cascade: [分析代码] [生成建议] [应用/拒绝]               |
+----------------------------------------------------------+
```

### 技术架构

- **基础**: VS Code 兼容
- **语言**: TypeScript
- **模型**: 多模型支持
- **Neovim 插件**: windsurf.nvim

### 用户交互流程

1. 打开项目
2. Cmd/Ctrl+L 打开 Cascade
3. 选择 Code 或 Chat 模式
4. 描述需求
5. 接受或修改 AI 建议

### 特色功能

- **Flow State**: 保持开发者心流
- **Real-time Awareness**: 实时代码感知
- **Linter Integration**: 代码检查集成
- **VS Code 设置导入**: 无缝迁移

---

## 8. Aider

### 项目信息

- **开发商**: Aider AI
- **项目 URL**: https://aider.chat
- **GitHub**: https://github.com/Aider-AI/aider
- **类型**: 终端工具 + 浏览器 UI

### 核心功能

| 功能 | 描述 |
|------|------|
| 终端 AI 编码 | 命令行 AI 编程 |
| 浏览器 UI | 实验性 Web 界面 |
| Git 集成 | 自动提交变更 |
| 多 LLM 支持 | 支持 GPT-4, Claude 等 |
| Ask/Code 模式 | 询问与编码模式切换 |

### UI 设计特点

```
+----------------------------------------------------------+
|  Aider Browser UI                                        |
+-------------------+--------------------------------------+
|  聊天区域         |  文件预览                            |
|  > /ask 分析这个  |  +--------------------------------+|
|    函数           |  |  main.py                       ||
|                   |  |  def main():                   ||
|  Aider: [解释...]  |  |      print("Hello")            ||
|                   |  |                                ||
|  > 修改为打印     |  |  [变更预览]                    ||
|    Hello World    |  |  - print("Hello")              ||
|                   |  |  + print("Hello World")        ||
+-------------------+--------------------------------------+
```

### 技术架构

- **语言**: Python
- **分发**: PyPI
- **模型**: OpenAI, Anthropic, Google 等

### 用户交互流程

1. 安装: `pip install aider-chat`
2. 启动浏览器 UI: `aider --browser`
3. 输入命令或问题
4. 查看代码变更
5. 确认或继续迭代

### 特色功能

- **URL 抓取**: `/web` 命令抓取网页内容
- **Ask/Code 模式**: 先问后改的工作流
- **图片支持**: 支持图片 URL 分析

---

## 9. Continue.dev

### 项目信息

- **开发商**: Continue
- **项目 URL**: https://continue.dev
- **GitHub**: https://github.com/continuedev/continue
- **类型**: IDE 扩展 (开源)

### 核心功能

| 功能 | 描述 |
|------|------|
| Chat | AI 对话 |
| Autocomplete | Tab 代码补全 |
| Inline Edit | 行内编辑 (Cmd/Ctrl+I) |
| Agent | 代理工作流 |
| 多模型支持 | 本地和云端模型 |
| 规则系统 | 自定义编码规则 |

### UI 设计特点

```
+----------------------------------------------------------+
|  VS Code / JetBrains + Continue                          |
+-------------------+--------------------------------------+
|  项目文件         |  代码编辑器                          |
|                   |  +--------------------------------+|
|                   |  |  // Tab 补全                   ||
|                   |  |  function sort(arr) {          ||
|                   |  |    // AI 自动补全...           ||
|                   |  |  }                             ||
+-------------------+--------------------------------------+
|  Continue Chat (Cmd/Ctrl+L)                              |
|  用户: 解释这个排序算法                                   |
|  Continue: [代码解释] [优化建议]                          |
+----------------------------------------------------------+
```

### 技术架构

- **语言**: TypeScript
- **平台**: VS Code, JetBrains
- **配置**: YAML 配置文件
- **模型**: 多 LLM 支持

### 用户交互流程

1. 安装 IDE 扩展
2. 配置模型和规则
3. Cmd/Ctrl+L 打开 Chat
4. 或使用 Tab 补全
5. Cmd/Ctrl+I 行内编辑

### 特色功能

- **开源**: 完全开源
- **自定义规则**: 项目级编码规范
- **多 IDE**: VS Code 和 JetBrains 支持
- **本地模型**: 支持 Ollama 等本地模型

---

## 功能模块对比分析

### 代码编辑器集成

| 项目 | 集成方式 | 编辑器类型 |
|------|----------|------------|
| Claude Code | 终端/IDE 扩展 | VS Code, JetBrains |
| Cursor | 独立 IDE | VS Code 分支 |
| OpenHands | Web GUI | 浏览器编辑器 |
| Bolt.new | Web | 浏览器编辑器 |
| v0.dev | Web | 浏览器编辑器 |
| Replit | Web | 浏览器编辑器 |
| Windsurf | 独立 IDE | VS Code 兼容 |
| Aider | 终端/浏览器 | 外部编辑器 |
| Continue | IDE 扩展 | VS Code, JetBrains |

### 文件管理

| 项目 | 文件浏览 | 文件编辑 | Git 集成 |
|------|----------|----------|----------|
| Claude Code | Yes | Yes | Yes |
| Cursor | Yes | Yes | Yes |
| OpenHands | Yes | Yes | Yes |
| Bolt.new | Yes | Yes | Yes |
| v0.dev | Yes | Yes | Limited |
| Replit | Yes | Yes | Yes |
| Windsurf | Yes | Yes | Yes |
| Aider | Limited | Yes | Yes |
| Continue | Yes | Yes | Through IDE |

### 会话管理

| 项目 | 多会话 | 历史记录 | 上下文保持 |
|------|--------|----------|------------|
| Claude Code | Yes | Yes | Codebase |
| Cursor | Yes | Yes | Codebase |
| OpenHands | Yes | Yes | Workspace |
| Bolt.new | Yes | Limited | Project |
| v0.dev | Yes | Yes | Chat |
| Replit | Yes | Yes | Project |
| Windsurf | Yes | Yes | Codebase |
| Aider | No | Limited | Files |
| Continue | Yes | Yes | Codebase |

### 代码补全

| 项目 | Tab 补全 | 多行补全 | 上下文感知 |
|------|----------|----------|------------|
| Claude Code | No | No | Yes |
| Cursor | Yes | Yes | Yes |
| OpenHands | No | No | Yes |
| Bolt.new | No | No | Yes |
| v0.dev | No | No | Yes |
| Replit | Yes (Ghostwriter) | Yes | Yes |
| Windsurf | Yes | Yes | Yes |
| Aider | No | No | Yes |
| Continue | Yes | Yes | Yes |

### 代码生成

| 项目 | 自然语言生成 | 组件生成 | 全栈生成 |
|------|--------------|----------|----------|
| Claude Code | Yes | Yes | Yes |
| Cursor | Yes | Yes | Yes |
| OpenHands | Yes | Yes | Yes |
| Bolt.new | Yes | Yes | Yes |
| v0.dev | Yes | Yes | Yes |
| Replit | Yes | Yes | Yes |
| Windsurf | Yes | Yes | Yes |
| Aider | Yes | Limited | Limited |
| Continue | Yes | Yes | Yes |

### 错误处理

| 项目 | 错误检测 | AI 调试 | 自动修复 |
|------|----------|---------|----------|
| Claude Code | Yes | Yes | Yes |
| Cursor | Yes | Yes | Yes |
| OpenHands | Yes | Yes | Yes |
| Bolt.new | Yes | Yes | Yes |
| v0.dev | Yes | Yes | Yes |
| Replit | Yes | Yes | Yes |
| Windsurf | Yes (Linter) | Yes | Yes |
| Aider | Limited | Yes | Yes |
| Continue | Through IDE | Yes | Yes |

### 上下文管理

| 项目 | 代码库索引 | 文件引用 | Token 管理 |
|------|------------|----------|------------|
| Claude Code | Yes | @file | Smart |
| Cursor | Yes | @codebase | Token Limit |
| OpenHands | Workspace | Files | Session |
| Bolt.new | Project | Files | Token Limit |
| v0.dev | Project | Files | Token Limit |
| Replit | Project | Files | Token Limit |
| Windsurf | Yes | Context | Smart |
| Aider | Files in chat | /add | Manual |
| Continue | Codebase | @file | Configurable |

### 工具调用可视化

| 项目 | 工具调用显示 | 执行状态 | 结果预览 |
|------|--------------|----------|----------|
| Claude Code | Yes | Yes | Yes |
| Cursor | Yes | Yes | Yes |
| OpenHands | Yes | Yes | Yes |
| Bolt.new | Limited | Yes | Preview |
| v0.dev | Limited | Yes | Preview |
| Replit | Limited | Yes | Preview |
| Windsurf | Yes | Yes | Yes |
| Aider | Limited | Yes | Diff |
| Continue | Yes | Yes | Yes |

---

## 总结

### Web 版 Code Agent 分类

1. **浏览器端完整 IDE**
   - Replit: 最成熟的浏览器 IDE
   - Bolt.new: 全栈应用快速生成
   - v0.dev: UI 组件快速生成

2. **桌面 IDE + 云端 Agent**
   - Cursor: VS Code 分支，深度 AI 集成
   - Windsurf: Codeium 的 AI IDE

3. **终端工具 + Web 界面**
   - Claude Code: 终端优先，多平台集成
   - Aider: 终端工具，实验性浏览器 UI
   - OpenHands: 开源 AI 开发平台

4. **IDE 扩展**
   - Continue: 开源 IDE 扩展

### 关键趋势

1. **Agentic 编码**: 从代码补全到代理执行
2. **代码库理解**: 深度索引和上下文感知
3. **多模态交互**: 文本、语音、图片
4. **云端协作**: Cloud Agent 和远程执行
5. **零配置**: 浏览器端无需本地设置

### 参考资源

- [Claude Code 文档](https://docs.anthropic.com/claude-code)
- [Cursor 文档](https://cursor.com/docs)
- [OpenHands 文档](https://docs.openhands.dev)
- [Bolt.new 支持](https://support.bolt.new)
- [v0.dev 文档](https://v0.app/docs)
- [Replit 文档](https://docs.replit.com)
- [Windsurf 文档](https://docs.windsurf.com)
- [Aider 文档](https://aider.chat/docs)
- [Continue 文档](https://continue.dev/docs)
