# 现有 Claude 桌面客户端调研报告

> 调研日期：2026-03-30
> 排除：官方 Claude Desktop、纯 Web 方案

---

## 一、主流开源项目概览

| 项目 | Stars | 技术栈 | 平台 | Claude 支持 | 开源协议 |
|------|-------|--------|------|-------------|----------|
| [NextChat](https://github.com/ChatGPTNextWeb/NextChat) | 87.6K | TypeScript/Electron | 全平台 | ✅ | MIT |
| [Chatbox](https://github.com/Bin-Huang/chatbox) | 20K+ | TypeScript/Electron | 全平台 | ✅ | GPLv3 |
| [TUUI](https://github.com/AI-QL/tuui) | 1.1K | TypeScript/Electron/Vue3 | 全平台 | ✅ | Apache-2.0 |
| [Kelivo](https://github.com/Chevey339/kelivo) | 1.9K | Dart/Flutter | 全平台+移动端 | ✅ | - |
| [TinyChat](https://github.com/pymike00/tinychat) | 56 | Python/Tkinter | Win/Linux | ✅ | - |
| [OpenLoaf](https://github.com/OpenLoaf/OpenLoaf) | 30 | TypeScript | 全平台 | ✅ | - |

---

## 二、重点项目详细分析

### 1. Chatbox ⭐ 推荐

**基本信息**
- 仓库：https://github.com/Bin-Huang/chatbox
- Stars：20,000+
- 技术栈：**Electron + TypeScript + React**
- 平台：Windows / macOS / Linux / iOS / Android
- 协议：GPLv3（社区版）

**核心特性**
- ✅ 支持 Claude、ChatGPT、Gemini 等多模型
- ✅ 流式输出
- ✅ Markdown 渲染 + 代码高亮
- ✅ 图片/文件上传
- ✅ 本地数据存储（隐私友好）
- ✅ MCP 支持（Model Context Protocol）
- ✅ RAG 知识库

**技术依赖（从 package.json 分析）**
```
核心框架:
- electron (桌面框架)
- @modelcontextprotocol/sdk (MCP 支持)
- @ai-sdk/anthropic (Claude API)
- @lobehub/icons (图标库)

数据存储:
- @libsql/client (本地数据库)
- electron-store (配置存储)

文档解析:
- officeparser (Office 文档)
- epub (电子书)
- @mozilla/readability (网页提取)
```

**优点**
- 成熟稳定，社区活跃
- 功能完整，多模型支持
- 有移动端版本
- 开源版本持续更新

**缺点**
- Electron 体积大
- GPLv3 协议限制商业使用

---

### 2. NextChat

**基本信息**
- 仓库：https://github.com/ChatGPTNextWeb/NextChat
- Stars：87,607
- 技术栈：**TypeScript + Next.js + PWA**
- 平台：Web / iOS / macOS / Android / Windows / Linux

**核心特性**
- ✅ 多模型支持（Claude、GPT、Gemini 等）
- ✅ 流式输出
- ✅ 插件系统
- ✅ 多语言支持
- ✅ PWA 离线使用

**特点**
- 本质是 Web 应用，通过 PWA 提供类桌面体验
- 社区最活跃
- 更新频繁

**缺点**
- 不是原生桌面应用
- 需要部署或使用官方服务

---

### 3. TUUI (Local AI Playground with MCP)

**基本信息**
- 仓库：https://github.com/AI-QL/tuui
- Stars：1,137
- 技术栈：**Electron + Vue3 + Vuetify + TypeScript**
- 平台：Windows / Linux / macOS

**核心特性**
- ✅ **MCP 客户端**（完整支持 Tools/Prompts/Resources/Sampling）
- ✅ 跨厂商 LLM API 编排
- ✅ 多语言支持
- ✅ MCP Registry 发现服务
- ✅ MCPB 扩展支持

**技术依赖**
```
- @modelcontextprotocol/sdk (MCP 核心)
- Vue3 + Vuetify (UI 框架)
- Pinia (状态管理)
- md-editor-v3 (Markdown 编辑器)
- mermaid (图表支持)
- highlight.js (代码高亮)
```

**优点**
- MCP 功能最完整
- 轻量级设计
- 支持 MCPB 扩展

**缺点**
- 相对较新，社区较小
- UI 相对简陋

---

### 4. Kelivo (Flutter)

**基本信息**
- 仓库：https://github.com/Chevey339/kelivo
- Stars：1,952
- 技术栈：**Dart + Flutter**
- 平台：iOS / Android / Desktop / HarmonyOS

**核心特性**
- ✅ 多平台支持（含鸿蒙）
- ✅ 多 LLM 支持
- ✅ 移动端优先设计

**优点**
- Flutter 跨平台，一套代码多端运行
- 原生性能优于 Electron
- 移动端体验好

**缺点**
- Flutter 桌面体验不如原生
- 需要 Dart/Flutter 开发经验

---

### 5. TinyChat

**基本信息**
- 仓库：https://github.com/pymike00/tinychat
- Stars：56
- 技术栈：**Python + CustomTkinter**
- 平台：Windows / Linux（不支持 macOS）

**核心特性**
- ✅ 轻量级（仅依赖 requests、sseclient、CustomTkinter）
- ✅ 支持 Claude、GPT、Gemini、Mistral、Cohere
- ✅ 代码简洁，易于理解和定制

**优点**
- 代码量小，适合学习
- 依赖少，启动快
- 无官方 SDK，纯 HTTP 请求

**缺点**
- 不支持 macOS
- UI 较简陋
- 功能有限

---

## 三、技术栈对比

| 技术方案 | 代表项目 | 体积 | 性能 | 开发难度 | 跨平台 |
|----------|----------|------|------|----------|--------|
| **Electron + React** | Chatbox | 大 (100MB+) | 中等 | 低 | ✅ 全平台 |
| **Electron + Vue3** | TUUI | 大 (100MB+) | 中等 | 低 | ✅ 全平台 |
| **Flutter** | Kelivo | 中 (30-50MB) | 较好 | 中 | ✅ 含移动端 |
| **Python + Tkinter** | TinyChat | 小 (<20MB) | 好 | 低 | ❌ 无 macOS |
| **SwiftUI** | - | 小 (<10MB) | 最好 | 高 | ❌ 仅 macOS |
| **Tauri + React** | - | 小 (<10MB) | 好 | 中 | ✅ 全平台 |

---

## 四、关键功能对比

| 功能 | Chatbox | NextChat | TUUI | Kelivo | TinyChat |
|------|---------|----------|------|--------|----------|
| Claude API | ✅ | ✅ | ✅ | ✅ | ✅ |
| 流式输出 | ✅ | ✅ | ✅ | ✅ | ✅ |
| Markdown | ✅ | ✅ | ✅ | ✅ | ❌ |
| 代码高亮 | ✅ | ✅ | ✅ | - | ❌ |
| 图片上传 | ✅ | ✅ | - | - | ❌ |
| 文件上传 | ✅ | ✅ | - | - | ❌ |
| MCP 支持 | ✅ | ❌ | ✅ | ❌ | ❌ |
| 本地存储 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 多会话 | ✅ | ✅ | ✅ | ✅ | ✅ |
| macOS 原生体验 | ❌ | ❌ | ❌ | ❌ | ❌ |

---

## 五、结论与建议

### 现有方案的不足

1. **无原生 macOS 应用** - 所有项目都是跨平台方案，没有利用 macOS 原生特性
2. **Electron 体积大** - 内存占用高，启动较慢
3. **UI 非原生风格** - 与 macOS 系统风格不统一
4. **缺少系统集成** - 没有利用 macOS 的 Shortcuts、Widgets 等特性

### 可行的差异化方向

| 方向 | 说明 |
|------|------|
| **原生 SwiftUI** | 体积小、性能好、系统风格统一 |
| **系统集成** | Shortcuts、Widgets、MenuBar |
| **隐私优先** | 完全本地化，无云同步 |
| **快捷键优化** | 全局快捷键、键盘导航 |

### 推荐参考

1. **Chatbox** - 功能最完整，MCP 支持好
2. **TUUI** - MCP 实现参考
3. **TinyChat** - 简洁实现参考

---

## 六、待研究

- [ ] Codex 应用设计分析
- [ ] SwiftUI 桌面应用开发最佳实践
- [ ] MCP 协议深度研究

---

## 参考资料

- [Chatbox GitHub](https://github.com/Bin-Huang/chatbox)
- [NextChat GitHub](https://github.com/ChatGPTNextWeb/NextChat)
- [TUUI GitHub](https://github.com/AI-QL/tuui)
- [Kelivo GitHub](https://github.com/Chevey339/kelivo)
- [TinyChat GitHub](https://github.com/pymike00/tinychat)
- [Every ChatGPT GUI](https://github.com/billmei/every-chatgpt-gui) - GUI 客户端汇总
