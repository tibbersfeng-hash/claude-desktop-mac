# 项目管理模块技术决策

## 决策日期：2026-03-31

## 决策 1：项目切换时保存会话状态

### 背景
用户在项目间切换时，需要决定是否保存当前项目的会话状态。

### 决策
**需要保存当前会话状态**

### 理由
1. **用户体验**：用户切换项目后可能需要返回继续工作，不保存会丢失上下文
2. **数据安全**：意外切换不应导致工作丢失
3. **多任务场景**：用户可能在多个项目间来回切换

### 实现方式
- 在 `ProjectManager.switchToProject()` 中触发会话保存
- 会话状态包括：对话历史、当前输入、未保存的更改
- 使用 `activeSessionCount` 跟踪每个项目的活跃会话数
- 状态持久化到 UserDefaults 或文件系统

### 代码位置
`Sources/Project/ProjectManager.swift` - `switchToProject()` 方法

---

## 决策 2：Git 状态刷新策略

### 背景
Git 状态需要异步获取，需要决定何时刷新。

### 决策
**懒加载 + 手动刷新**

### 理由
1. **性能**：启动时不阻塞加载所有项目状态
2. **准确性**：用户需要时手动刷新获取最新状态
3. **资源**：避免频繁执行 Git 命令

### 实现方式
- 视图打开时自动刷新一次（`.task` 修饰符）
- 提供刷新按钮手动触发
- 使用 `TaskGroup` 并行刷新所有项目

### 代码位置
`Sources/Project/ProjectManager.swift` - `refreshAllGitStatus()` 方法

---

## 决策 3：项目排序持久化

### 背景
用户可能偏好特定的排序方式。

### 决策
**持久化排序选项到 UserDefaults**

### 理由
1. **一致性**：用户期望偏好设置被记住
2. **简单**：UserDefaults 足够，无需复杂存储
3. **快速**：同步读写，无延迟

### 代码位置
`Sources/Project/ProjectManager.swift` - `sortOptionKey` / `saveSortOption()`
