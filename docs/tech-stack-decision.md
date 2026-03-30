# 技术选型决策

> 决策日期：2026-03-30

## 决策结论

**技术栈：SwiftUI (原生 macOS)**

---

## 决策依据

### 为什么选择 SwiftUI

| 因素 | SwiftUI | Electron | Flutter | Tauri |
|------|---------|----------|---------|-------|
| **应用体积** | < 10MB | 100MB+ | 30-50MB | < 10MB |
| **内存占用** | 低 | 高 | 中 | 低 |
| **启动速度** | 快 | 慢 | 中 | 快 |
| **macOS 原生体验** | ✅ 完美 | ❌ | ❌ | ❌ |
| **系统集成** | ✅ 深度 | ❌ | ❌ | ❌ |
| **开发效率** | 中 | 高 | 高 | 中 |
| **差异化价值** | ✅ 高 | ❌ 低 | ❌ 低 | 中 |

### 核心优势

1. **原生体验**
   - 完美遵循 macOS Human Interface Guidelines
   - 系统级动画、过渡效果
   - 原生控件外观

2. **性能优异**
   - 启动速度快（毫秒级）
   - 内存占用低
   - 电量消耗少

3. **系统集成**
   - Shortcuts 快捷指令
   - Widgets 小组件
   - MenuBar 菜单栏
   - Notification Center
   - Spotlight 集成

4. **市场差异化**
   - 目前没有原生 SwiftUI 的 Claude 客户端
   - 可以吸引追求原生体验的 macOS 用户

---

## 技术架构

### 开发语言
- **Swift 5.9+** - 苹果现代编程语言
- **SwiftUI** - 声明式 UI 框架
- **Combine** - 响应式编程（可选）

### 最低系统要求
- **macOS 14.0+ (Sonoma)** - SwiftUI 最新特性支持

### 网络层
- **URLSession** - 原生网络库
- **Async/Await** - Swift 并发模型

### 数据存储
- **SwiftData** - 苹果最新数据持久化框架（macOS 14+）
- 或 **Core Data** - 成熟的数据存储方案
- 或 **SQLite** - 轻量级数据库

### Markdown 渲染
- **MarkdownUI** - SwiftUI 原生 Markdown 渲染库
- 或自定义 AttributedString 解析

---

## 功能规划

### MVP (Phase 1)

| 功能 | 优先级 |
|------|--------|
| API Key 配置 | P0 |
| 单会话对话 | P0 |
| 流式输出 | P0 |
| Markdown 渲染 | P0 |
| 代码高亮 | P1 |
| 多会话管理 | P1 |

### 进阶功能 (Phase 2)

| 功能 | 优先级 |
|------|--------|
| 图片上传 | P1 |
| 多模型切换 | P2 |
| 历史记录搜索 | P2 |
| 导出对话 | P2 |

### 系统集成 (Phase 3)

| 功能 | 优先级 |
|------|--------|
| MenuBar 快捷入口 | P2 |
| 全局快捷键 | P2 |
| Shortcuts 集成 | P3 |
| Widgets | P3 |

---

## 第三方依赖（预估）

| 依赖 | 用途 | 是否必需 |
|------|------|----------|
| MarkdownUI | Markdown 渲染 | 推荐 |
| Highlightr | 代码高亮 | 推荐 |
| KeychainAccess | 安全存储 API Key | 推荐 |

---

## 风险评估

| 风险 | 级别 | 应对措施 |
|------|------|----------|
| Swift 开发经验不足 | 中 | 边学边做，参考开源项目 |
| macOS 版本限制 | 低 | 明确标注系统要求 |
| 后续跨平台需求 | 中 | 抽象业务逻辑层，便于移植 |

---

## 参考资料

- [Swift 官方文档](https://swift.org/documentation/)
- [SwiftUI 教程](https://developer.apple.com/tutorials/swiftui)
- [Anthropic API 文档](https://docs.anthropic.com)
- [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui)

---

## 决策记录

| 日期 | 决策 | 原因 |
|------|------|------|
| 2026-03-30 | 选择 SwiftUI | 原生体验、性能优异、市场差异化 |

---

## 下一步

- [ ] 搭建 Xcode 项目骨架
- [ ] 实现 API 连接与认证
- [ ] 完成基础对话界面
