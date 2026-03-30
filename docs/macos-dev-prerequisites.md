# macOS 应用开发前置准备

## 一、开发环境准备

### 1. 硬件要求
- [ ] Mac 电脑 (MacBook/iMac/Mac mini)
- [ ] 推荐配置：M1/M2/M3 芯片，8GB+ 内存，256GB+ 存储

### 2. 软件环境

#### 必需
- [ ] **macOS 操作系统** - 建议 macOS 13 (Ventura) 或更高
- [ ] **Xcode** - 从 App Store 安装，包含：
  - Xcode IDE
  - Swift 编译器
  - SwiftUI 预览
  - iOS/macOS SDK
  - 模拟器
- [ ] **Xcode Command Line Tools**
  ```bash
  xcode-select --install
  ```

#### 推荐
- [ ] **Homebrew** - 包管理器
  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```
- [ ] **Git** - 版本控制（Xcode 已包含）
- [ ] **VS Code** 或其他编辑器（辅助开发）

### 3. 开发者账号

#### 免费账号
- 使用 Apple ID 登录 Xcode
- 可以在本地运行和调试应用
- 无法发布到 App Store
- 应用 7 天后过期（需要重新签名）

#### 付费账号 ($99/年)
- Apple Developer Program 会员
- 可以发布到 App Store
- 可以进行 TestFlight 测试
- 应用签名长期有效
- 可以使用 Push Notifications 等高级功能

---

## 二、技术栈相关准备

### 方案 A: SwiftUI (原生开发)

#### 学习资源
- [ ] Swift 语言基础
- [ ] SwiftUI 框架
- [ ] AppKit (如需系统集成)

#### 项目配置
- [ ] 创建 Xcode 项目
- [ ] 配置 Bundle Identifier
- [ ] 配置 Signing & Capabilities
- [ ] 设置最低部署版本 (macOS 13+)

### 方案 B: Electron

#### 环境准备
- [ ] Node.js (v18+)
  ```bash
  brew install node
  ```
- [ ] npm / pnpm / yarn
- [ ] Electron CLI
  ```bash
  npm install -g electron
  ```

#### 项目配置
- [ ] 初始化项目 `npm init`
- [ ] 安装 Electron `npm install electron`
- [ ] 配置打包工具 (electron-builder / electron-forge)

### 方案 C: Tauri

#### 环境准备
- [ ] Node.js (v18+)
- [ ] Rust 工具链
  ```bash
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  ```
- [ ] Tauri CLI
  ```bash
  npm install -g @tauri-apps/cli
  ```

#### macOS 依赖
- [ ] Xcode Command Line Tools (已包含在上面)

---

## 三、应用签名与公证

### 为什么需要签名？
- macOS Gatekeeper 默认阻止未签名应用
- 用户下载后需要手动信任（体验差）
- App Store 强制要求签名

### 签名流程
1. [ ] 获取 Developer ID Certificate (需要付费账号)
2. [ ] 在 Xcode 中配置签名
3. [ ] 进行公证 (Notarization) - 提交给 Apple 审核
4. [ ] Staple 公证结果到应用包

### 未签名应用的替代方案
- 用户需要执行：
  ```bash
  xattr -cr /path/to/app.app
  ```
- 或在系统偏好设置中允许

---

## 四、网络与 API 准备

### Claude API 相关
- [ ] 注册 Anthropic 账号
- [ ] 获取 API Key
- [ ] 了解 API 定价
- [ ] 测试 API 连通性

### API 调用方式
```bash
# 测试 API
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: YOUR_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d '{"model":"claude-sonnet-4-20250514","max_tokens":100,"messages":[{"role":"user","content":"Hello"}]}'
```

---

## 五、设计参考 (待研究)

### Codex 应用
> 参考 Codex 的产品设计，待后续详细研究

### 其他 Claude 客户端参考
- OpenCat
- Chatbox
- TypingMind
- Claude 官方 Web 版

---

## 六、检查清单汇总

| 类别 | 项目 | 必需 | 状态 |
|------|------|------|------|
| **硬件** | Mac 电脑 | ✅ 必需 | ⏳ |
| **软件** | macOS 13+ | ✅ 必需 | ⏳ |
| **软件** | Xcode | ✅ 必需 | ⏳ |
| **软件** | Xcode CLI Tools | ✅ 必需 | ⏳ |
| **软件** | Homebrew | ⭕ 推荐 | ⏳ |
| **软件** | Node.js (Electron/Tauri) | ⭕ 视方案 | ⏳ |
| **软件** | Rust (Tauri) | ⭕ 视方案 | ⏳ |
| **账号** | Apple ID | ✅ 必需 | ⏳ |
| **账号** | Apple Developer Program | ⭕ 发布需要 | ⏳ |
| **账号** | Anthropic API Key | ✅ 必需 | ⏳ |

---

## 更新日志

### 2026-03-30
- 创建文档，整理 macOS 应用开发前置准备清单
