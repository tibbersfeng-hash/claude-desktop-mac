# Claude Code CLI 和 Claude Desktop 官方功能研究

> 研究日期: 2026-03-30
> 数据来源: Context7 官方文档、Anthropic GitHub 仓库

---

## 目录

1. [功能对比总览](#功能对比总览)
2. [Claude Code CLI 完整功能](#claude-code-cli-完整功能)
3. [Claude Desktop 官方版本](#claude-desktop-官方版本)
4. [工具系统详解](#工具系统详解)
5. [MCP 协议支持](#mcp-协议支持)
6. [会话与上下文管理](#会话与上下文管理)
7. [权限和安全机制](#权限和安全机制)
8. [配置选项](#配置选项)
9. [快捷键](#快捷键)
10. [输出格式](#输出格式)

---

## 功能对比总览

### 功能矩阵

| 功能类别 | Claude Code CLI | Claude Desktop | 共有 |
|---------|:---------------:|:--------------:|:----:|
| **核心功能** |
| 文本对话 | ✅ | ✅ | ✅ |
| 图像分析 | ✅ | ✅ | ✅ |
| PDF 阅读 | ✅ | ✅ | ✅ |
| 代码生成 | ✅ | ✅ | ✅ |
| **文件操作** |
| 读取本地文件 | ✅ (Read工具) | ❌ | - |
| 写入/编辑文件 | ✅ (Write/Edit工具) | ❌ | - |
| 文件搜索 | ✅ (Glob/Grep工具) | ❌ | - |
| 多文件编辑 | ✅ | ❌ | - |
| **命令执行** |
| Bash 命令执行 | ✅ | ❌ | - |
| Git 工作流 | ✅ | ❌ | - |
| 包管理操作 | ✅ | ❌ | - |
| **集成功能** |
| MCP Server 集成 | ✅ | ✅ | ✅ |
| IDE 集成 (VS Code) | ✅ | ❌ | - |
| Jupyter Notebook | ✅ | ❌ | - |
| **高级功能** |
| Skills/插件系统 | ✅ | ❌ | - |
| Agents/子代理 | ✅ | ❌ | - |
| Hooks 钩子系统 | ✅ | ❌ | - |
| Headless 模式 | ✅ | ❌ | - |
| 计划模式 (Plan Mode) | ✅ | ❌ | - |
| **会话管理** |
| 会话持久化 | ✅ | ✅ | ✅ |
| 上下文压缩 | ✅ | ❓ | - |
| 会话恢复 | ✅ | ✅ | ✅ |
| **配置与定制** |
| CLAUDE.md 项目指令 | ✅ | ❌ | - |
| 自定义快捷键 | ✅ | ❌ | - |
| 权限规则配置 | ✅ | ❌ | - |
| Auto Memory | ✅ | ❌ | - |

---

## Claude Code CLI 完整功能

### 命令行参数

```bash
# 基本用法
claude                           # 启动交互式会话
claude -p "prompt"               # 非交互模式执行
claude --help                    # 显示帮助

# 权限控制
claude --permission-mode plan    # 计划模式 (只读)
claude --enable-auto-mode        # 自动模式
claude --allowedTools "Read,Edit,Bash"  # 预批准工具

# MCP 和插件
claude -p --permission-prompt-tool mcp_auth_tool "query"
claude --plugin-dir ./my-plugins # 加载外部插件

# 其他选项
claude --resume                  # 恢复上次会话
claude --clear-context           # 清除上下文
```

### Slash 命令列表

| 命令 | 描述 | 平台限制 |
|------|------|---------|
| `/help` | 显示帮助信息 | - |
| `/init` | 初始化 CLAUDE.md | - |
| `/context` | 查看上下文使用情况 | - |
| `/compact` | 压缩对话历史 | - |
| `/clear` | 清除当前会话 | - |
| `/model` | 切换模型 | - |
| `/keybindings` | 自定义快捷键 | - |
| `/upgrade` | 升级订阅 | Pro/Max |
| `/privacy-settings` | 隐私设置 | Pro/Max |
| `/desktop` | 集成桌面应用 | macOS/Windows |
| `/plugin` | 插件管理 | - |

### 插件市场命令

```shell
/plugin marketplace list              # 列出所有市场
/plugin marketplace update name       # 更新市场列表
/plugin marketplace remove name       # 移除市场
```

---

## Claude Desktop 官方版本

### 核心功能

Claude Desktop 是 Anthropic 官方提供的桌面应用程序，支持 macOS 和 Windows。

**主要功能:**
- 对话式 AI 交互
- 图像分析 (拖放、粘贴、文件路径)
- PDF 文档阅读
- 多模态输入支持
- MCP Server 集成

**文件支持:**
- 图像: PNG, JPG, GIF, WebP 等
- 文档: PDF
- 代码片段粘贴

**限制:**
- 无法直接访问本地文件系统
- 无法执行命令
- 无 Bash/终端集成
- 依赖 MCP Server 扩展功能

---

## 工具系统详解

### 内置工具

Claude Code CLI 提供以下内置工具:

| 工具名称 | 功能描述 | 是否写入 |
|---------|---------|:-------:|
| **Read** | 读取文件内容 (支持图像、PDF、Jupyter Notebook) | ❌ |
| **Write** | 创建或覆盖文件 | ✅ |
| **Edit** | 编辑现有文件 (字符串替换) | ✅ |
| **Glob** | 文件模式匹配搜索 | ❌ |
| **Grep** | 文件内容正则搜索 | ❌ |
| **Bash** | 执行 Shell 命令 | ✅ |

### 工具权限语法

```text
# 精确匹配
Bash(npm run build)

# 前缀匹配 (空格+星号)
Bash(npm run *)
Bash(git commit *)

# 后缀匹配
Bash(* --version)
Bash(* --help *)

# 域名限制
Bash(domain:example.com)

# 文件路径
Read(~/.zshrc)
Read(./.env)
```

### IDE 集成工具 (VS Code)

| 工具名称 | 功能 | 是否写入 |
|---------|------|:-------:|
| `mcp__ide__getDiagnostics` | 获取语言服务器诊断信息 | ❌ |
| `mcp__ide__executeCode` | 在 Jupyter Notebook 内核中执行代码 | ✅ |

### 多模态支持

**Read 工具支持的文件类型:**
- 文本文件 (所有编码)
- 图像文件 (PNG, JPG, GIF, WebP, BMP)
- PDF 文档 (可指定页码范围)
- Jupyter Notebook (.ipynb)

```python
# PDF 读取示例 (指定页码)
Read(file_path="document.pdf", pages="1-5,10,20-25")
```

---

## MCP 协议支持

### MCP Server 配置

**stdio 类型 (本地进程):**

```json
{
  "serverType": "stdio",
  "command": "node",
  "args": ["${CLAUDE_PLUGIN_ROOT}/server.js"],
  "env": {
    "API_KEY": "${MY_API_KEY}"
  }
}
```

**SSE 类型 (HTTP 服务):**

```json
{
  "serverType": "sse",
  "url": "https://mcp-server.example.com/sse",
  "headers": {
    "Authorization": "Bearer ${API_TOKEN}"
  }
}
```

### 多 MCP Server 配置

```json
{
  "mcpServers": {
    "kubernetes": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/servers/kubernetes-mcp/index.js"],
      "env": {
        "KUBECONFIG": "${KUBECONFIG}",
        "K8S_NAMESPACE": "${K8S_NAMESPACE:-default}"
      }
    },
    "github-actions": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/servers/github-actions-mcp/server.js"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

### MCP 工具命名规则

MCP 工具名称格式: `mcp__<server_name>__<tool_name>`

示例:
- `mcp__memory__write` - memory server 的 write 工具
- `mcp__github__search_repositories` - github server 的搜索工具

---

## 会话与上下文管理

### 上下文窗口组成

```
┌─────────────────────────────────────────────────┐
│                  上下文窗口                       │
├─────────────────────────────────────────────────┤
│  • CLAUDE.md 项目指令                             │
│  • Auto Memory (持久化记忆)                       │
│  • MCP 工具名称                                   │
│  • Skills 描述                                    │
│  • 系统指令                                       │
│  • 对话历史                                       │
│  • 文件内容                                       │
│  • 命令输出                                       │
└─────────────────────────────────────────────────┘
```

### 上下文生命周期

1. **启动阶段**: 加载 CLAUDE.md、auto memory、MCP 工具名、skill 描述
2. **工作阶段**: 自动添加文件读取和路径范围规则
3. **复杂任务**: 子代理在隔离上下文中执行，返回摘要
4. **压缩阶段**: 使用 `/compact` 命令替换历史为结构化摘要

### 上下文监控

```bash
# 查看上下文使用情况
/context

# 手动压缩上下文
/compact
```

### 状态栏显示

支持通过脚本显示上下文使用百分比:

```
[claude-sonnet-4-6] ▓▓▓▓▓░░░░░ 50%
```

---

## 权限和安全机制

### 权限模式

| 模式 | 描述 |
|------|------|
| `accept` | 自动接受所有工具调用 |
| `plan` | 只读模式，无写操作 |
| `auto` | 根据规则自动决策 |

### 权限配置示例

```json
{
  "permissions": {
    "defaultMode": "plan",
    "allow": [
      "Bash(npm run lint)",
      "Bash(npm run test *)",
      "Read(~/.zshrc)"
    ],
    "deny": [
      "Bash(curl *)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)"
    ]
  }
}
```

### 沙箱配置

```json
{
  "sandbox": {
    "bashCommand": "strict",
    "networkAccess": {
      "allowUnixSockets": false,
      "allowedDomains": ["api.anthropic.com"],
      "deniedDomains": ["*"]
    }
  }
}
```

### Hooks 钩子系统

**事件类型:**
- `PreToolUse` - 工具执行前
- `PostToolUse` - 工具执行后
- `PrePrompt` - 提示发送前

**PreToolUse 钩子示例:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "验证文件写入安全性: 系统路径、凭据、路径遍历、敏感内容。返回 'approve' 或 'deny'。"
          }
        ]
      }
    ]
  }
}
```

**MCP 工具监控钩子:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__memory__.*",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Memory operation initiated' >> ~/mcp-operations.log"
          }
        ]
      }
    ]
  }
}
```

---

## 配置选项

### settings.json 结构

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "defaultMode": "plan",
    "allow": ["Bash(npm *)"],
    "deny": ["Read(./secrets/**)"]
  },
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1"
  },
  "claudeMdExcludes": [
    "**/monorepo/CLAUDE.md"
  ],
  "companyAnnouncements": [
    "欢迎使用 Claude Code!"
  ]
}
```

### CLAUDE.md 项目指令

```markdown
# 代码风格
- 使用 ES modules (import/export) 语法
- 尽可能解构导入

# 工作流
- 完成代码修改后务必进行类型检查
- 为性能考虑，优先运行单个测试

# 架构决策
- 使用 JWT 认证，不使用 session
```

### 配置文件位置

| 文件 | 位置 | 作用域 |
|------|------|--------|
| `settings.json` | `~/.claude/` | 用户级 |
| `settings.local.json` | `.claude/` | 项目级 |
| `CLAUDE.md` | 项目根目录或 `.claude/` | 项目级 |
| `keybindings.json` | `~/.claude/` | 用户级 |
| `hooks.json` | `~/.claude/` 或插件内 | 用户/插件级 |

---

## 快捷键

### 配置文件

```json
{
  "$schema": "https://www.schemastore.org/claude-code-keybindings.json",
  "$docs": "https://code.claude.com/docs/en/keybindings",
  "bindings": [
    {
      "context": "Chat",
      "bindings": {
        "ctrl+e": "chat:externalEditor",
        "ctrl+u": null
      }
    },
    {
      "context": "History",
      "bindings": {
        "ctrl+r": "history:search"
      }
    }
  ]
}
```

### 快捷键命令

- `/keybindings` - 打开快捷键配置

---

## 输出格式

### Markdown 渲染

Claude Code 支持 GitHub Flavored Markdown 渲染:
- 标题 (h1-h6)
- 列表 (有序、无序)
- 代码块 (带语法高亮)
- 链接和引用
- 表格
- 任务列表

### 代码块格式

````
```language
// 代码内容
```
````

支持的语言高亮: JavaScript, TypeScript, Python, Go, Rust, Java, Kotlin, Swift, C++, CSS, HTML, JSON, YAML, Markdown 等。

### 文件路径引用

输出中使用格式: `file_path:line_number`

示例:
- `src/index.ts:42` - 引用文件第 42 行
- `lib/utils.py:10-15` - 引用文件第 10-15 行

---

## Skills 和 Agents 系统

### Skills (技能)

Skills 是可复用的提示模板，存储在 `~/.claude/skills/` 目录。

**目录结构:**
```
skills/
├── tdd-guide.md
├── code-reviewer.md
└── security-reviewer.md
```

**Skill 文件格式:**
```markdown
---
name: tdd-guide
description: 测试驱动开发指导
tools: Read, Edit, Bash, Grep, Glob
---

# TDD 工作流程

1. RED: 先写失败的测试
2. GREEN: 实现最小代码通过测试
3. REFACTOR: 重构优化
```

### Agents (代理)

Agents 是具有特定角色和能力的子代理。

**Agent 配置示例:**
```markdown
---
name: debugger
description: 调试专家，用于错误分析和修复
tools: Read, Edit, Bash, Grep, Glob
model: inherit
color: blue
---

你是一个专业的调试专家，专注于根因分析。

**核心职责:**
1. 捕获错误信息和堆栈跟踪
2. 确定复现步骤
3. 隔离故障位置
4. 实现最小修复
5. 验证解决方案

**输出格式:**
- 根因解释
- 诊断证据
- 具体修复代码
- 测试方法
- 预防建议
```

### 代理编排模式

1. **分层代理**: 主代理 -> 子代理 -> 结果汇总
2. **并行代理**: 多个子代理同时执行独立任务
3. **顺序代理**: 代理按依赖关系顺序执行
4. **编排代理**: 协调多步骤复杂工作流

---

## 插件系统

### 插件目录结构

```
plugin/
├── manifest.json        # 插件清单
├── commands/           # 命令定义
├── agents/             # 代理定义
├── skills/             # 技能定义
├── servers/            # MCP 服务器
├── hooks/              # 钩子脚本
├── templates/          # 模板文件
└── lib/
    ├── core/          # 核心逻辑
    ├── integrations/  # 外部集成
    └── utils/         # 工具函数
```

### 插件清单 (manifest.json)

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "示例插件",
  "commands": "./commands",
  "agents": "./agents",
  "skills": "./skills",
  "mcpServers": {
    "my-server": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/servers/index.js"]
    }
  }
}
```

---

## 流式输出处理

### SSE (Server-Sent Events)

Claude Code 支持 SSE 流式输出用于实时监控:

```typescript
const listeners = new Set<(chunk: string) => void>()

function send(text: string) {
  const chunk = text.split('\n').map(l => `data: ${l}\n`).join('') + '\n'
  for (const emit of listeners) emit(chunk)
}

// SSE 端点
Bun.serve({
  port: 8788,
  async fetch(req) {
    if (req.method === 'GET' && url.pathname === '/events') {
      const stream = new ReadableStream({
        start(ctrl) {
          ctrl.enqueue(': connected\n\n')
          const emit = (chunk: string) => ctrl.enqueue(chunk)
          listeners.add(emit)
          req.signal.addEventListener('abort', () => listeners.delete(emit))
        },
      })
      return new Response(stream, {
        headers: { 'Content-Type': 'text/event-stream' }
      })
    }
  }
})
```

---

## 总结

### CLI 独有功能

1. **文件系统操作**: Read, Write, Edit, Glob, Grep
2. **命令执行**: Bash 工具，Git 工作流
3. **Skills/插件系统**: 可扩展的技能和插件架构
4. **Agents 子代理**: 多代理协作和编排
5. **Hooks 钩子系统**: 工具执行前后的拦截和控制
6. **Headless 模式**: 非交互式自动化执行
7. **Plan Mode**: 只读分析和计划模式
8. **CLAUDE.md**: 项目级指令和规则
9. **自定义快捷键**: 完全可定制的键盘绑定
10. **IDE 集成**: VS Code 深度集成

### Desktop 独有功能

1. **图形界面**: 原生桌面应用体验
2. **拖放支持**: 直接拖放文件到聊天
3. **系统托盘**: 后台运行和通知

### 共有功能

1. **对话交互**: 文本对话和代码生成
2. **图像分析**: 多模态图像理解
3. **PDF 支持**: 文档阅读和分析
4. **MCP 集成**: Model Context Protocol 支持
5. **会话管理**: 对话历史和恢复

---

*本文档基于 Claude Code v2.1.39 和 Claude Desktop 官方文档整理*
