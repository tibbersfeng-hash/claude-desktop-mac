# Claude Desktop Mac

<p align="center">
  <strong>A native macOS desktop client for Claude Code CLI</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#requirements">Requirements</a> •
  <a href="#installation">Installation</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#development">Development</a> •
  <a href="#license">License</a>
</p>

---

## Features

### Core Features

- **Native macOS Experience** - Built with SwiftUI, follows macOS Human Interface Guidelines
- **CLI Integration** - Seamless connection to Claude Code CLI with automatic detection
- **Session Management** - Multiple sessions with history, search, and organization
- **Real-time Streaming** - Live response display as Claude generates content
- **Tool Visualization** - Visual cards showing Claude's tool operations
- **Diff View** - Side-by-side comparison for file changes

### System Integration

- **MenuBar Integration** - Quick access from menu bar with Quick Ask feature
- **Global Shortcuts** - System-wide keyboard shortcuts for instant access
- **Spotlight Search** - Find and resume sessions directly from Spotlight
- **Desktop Notifications** - Rich notifications with quick reply support
- **Deep Links** - URL scheme support for automation and integration

### Enhanced Features

- **Syntax Highlighting** - Support for 20+ programming languages
- **Markdown Rendering** - Full markdown support with tables and diagrams
- **Image Upload** - Drag and drop image support with preview
- **File Upload** - Upload files with preview and metadata display
- **Project Management** - Switch between projects with CLAUDE.md support
- **Keyboard Navigation** - Full keyboard navigation support

## Requirements

- **macOS 14.0 (Sonoma)** or later
- **Claude Code CLI** installed and configured
- **Apple Silicon (M1/M2/M3)** or Intel-based Mac

## Installation

### Prerequisites

1. Install Claude Code CLI:
```bash
npm install -g @anthropic-ai/claude-code
```

2. Configure your API key:
```bash
claude auth
```

### Build from Source

```bash
# Clone the repository
git clone https://github.com/anthropics/claude-desktop-mac.git
cd claude-desktop-mac

# Build as .app bundle and run (Recommended)
./build-app.sh
open "Claude Desktop.app"
```

> **重要提示**：请使用 `./build-app.sh` 构建并运行打包好的 `.app` bundle。直接运行 `.build/debug/ClaudeDesktop` 会导致键盘输入无法正常工作，因为 macOS 需要正确识别应用身份来处理键盘事件。

### Development Build (Debug)

```bash
# Debug build only (not for running)
swift build

# Run tests
swift test
```

### Generate Xcode Project (Optional)

```bash
swift package generate-xcodeproj
open ClaudeDesktopMac.xcodeproj
```

## Quick Start

### Running the Application

**推荐方式 (使用 .app bundle):**
```bash
# Build and run as .app bundle
./build-app.sh && open "Claude Desktop.app"
```

**从 Xcode 运行:**
1. Generate Xcode project: `swift package generate-xcodeproj`
2. Open `ClaudeDesktopMac.xcodeproj`
3. Select the `ClaudeDesktop` scheme
4. Press `Cmd+R` to run

### First Use

1. **Launch Claude Desktop** - The app will automatically detect Claude Code CLI
2. **Verify Connection** - Check the status bar shows "Connected"
3. **Start Chatting** - Type a message and press `Cmd+Enter` to send

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+N` | New session |
| `Cmd+Enter` | Send message |
| `Cmd+/` | Toggle sidebar |
| `Cmd+Shift+A` | Quick Ask (global) |
| `Cmd+Shift+P` | Command Palette |
| `Cmd+F` | Search in session |
| `Cmd+Shift+F` | Search all sessions |
| `Cmd+,` | Open settings |

## Development

### Prerequisites

- **Xcode 15.0+** with Swift 5.9+
- **macOS 14.0+ SDK**
- **Claude Code CLI** for testing

### Build Commands

```bash
# Debug build
swift build

# Release build (optimized)
swift build -c release

# Run tests
swift test

# Clean build
swift package clean
```

### Project Structure

```
ClaudeDesktopMac/
├── Sources/
│   ├── ClaudeDesktop/      # Main entry point
│   ├── CLIConnector/       # CLI execution service
│   ├── CLIDetector/        # CLI detection
│   ├── CLIManager/         # Process management
│   ├── Communication/      # Communication pipeline
│   ├── Protocol/           # Message protocol
│   ├── Streaming/          # Response handling
│   ├── State/              # Connection state
│   ├── ErrorHandling/      # Error handling
│   ├── Theme/              # Colors, typography
│   ├── Models/             # Data models
│   ├── ViewModels/         # View models (MVVM)
│   ├── Views/              # SwiftUI views
│   ├── UI/                 # UI module entry
│   ├── App/                # App lifecycle
│   ├── Highlighting/       # Code highlighting
│   ├── Upload/             # File upload
│   ├── Shortcuts/          # Keyboard shortcuts
│   ├── History/            # Session history
│   ├── Project/            # Project management
│   ├── MenuBar/            # MenuBar integration
│   ├── GlobalShortcuts/    # Global shortcuts
│   ├── Spotlight/          # Spotlight integration
│   ├── Notifications/      # Notifications
│   └── Performance/        # Performance monitoring
├── Tests/                  # Unit tests
├── docs/                   # Documentation
└── Package.swift           # Swift Package manifest
```

### Architecture

The app follows MVVM (Model-View-ViewModel) architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Views     │  │ ViewModels  │  │      Theme          │  │
│  │  (SwiftUI)  │──│  (MVVM)     │──│  (Colors/Styles)    │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────┴─────────────────────────────────┐
│                    CLI Connection Layer                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ CLIConnector│  │ CLIDetector │  │  StreamingHandler   │  │
│  │ (Service)   │──│ (Detection) │──│  (Response Parse)   │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────┴─────────────────────────────────┐
│                    Claude Code CLI                           │
│              (External Process via stream-json)              │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

- **CLIExecutionService** - Executes CLI commands with `--output-format stream-json`
- **StreamingResponseHandler** - Parses JSON events from CLI stdout
- **ChatViewModel** - Manages chat state and message operations
- **ConnectionManager** - Handles connection lifecycle

### CLI Protocol

The app communicates with Claude CLI using the stream-json protocol:

```bash
claude --output-format stream-json --verbose -p "your message"
```

Events are parsed in real-time:
- `system/init` - Session initialization
- `assistant` - AI response content
- `result` - Final result with session_id

See [docs/CLI_PROTOCOL_ANALYSIS.md](docs/CLI_PROTOCOL_ANALYSIS.md) for detailed protocol documentation.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/anthropics/claude-desktop-mac/issues)

---

<p align="center">
  Made with care for the Claude community
</p>
