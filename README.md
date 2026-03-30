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

### Performance

- **Memory Optimization** - Intelligent memory management with cache control
- **Fast Launch** - Optimized startup with lazy loading
- **Responsive UI** - 60 FPS animations and smooth scrolling
- **Low Resource Usage** - Minimal CPU and memory footprint

## Screenshots

```
[Main Window - Chat Interface]
[MenuBar Dropdown - Quick Access]
[Quick Ask Panel - Floating Window]
[Tool Call Card - Visual Feedback]
[Diff View - File Changes]
```

## Requirements

- **macOS 14.0 (Sonoma)** or later
- **Claude Code CLI** installed and configured
- **Apple Silicon (M1/M2/M3)** or Intel-based Mac

## Installation

### Download

Download the latest version from [Releases](https://github.com/anthropics/claude-desktop-mac/releases).

1. Download `ClaudeDesktop-{version}.dmg`
2. Open the DMG file
3. Drag Claude Desktop to Applications folder
4. Launch Claude Desktop from Applications

### From Source

```bash
# Clone the repository
git clone https://github.com/anthropics/claude-desktop-mac.git
cd claude-desktop-mac

# Build the project
./Scripts/build.sh

# The built app will be in build/export/
```

### Prerequisites for CLI

Claude Desktop requires the Claude Code CLI to be installed:

```bash
# Install Claude Code CLI
npm install -g @anthropic/claude-code-cli

# Configure your API key
claude-code config set api-key YOUR_API_KEY
```

## Usage

### Quick Start

1. **Launch Claude Desktop**
   - Open Claude Desktop from Applications
   - The app will automatically detect Claude Code CLI

2. **Start a Session**
   - Click "New Session" or press `Cmd+N`
   - Type your message in the input area
   - Press `Cmd+Enter` to send

3. **Work with Claude**
   - Watch Claude's responses stream in real-time
   - View tool operations as visual cards
   - Review file changes in the diff view

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
| `Cmd+W` | Close window |
| `Cmd+Q` | Quit application |

### MenuBar Quick Ask

1. Click the Claude icon in the menu bar
2. Type your question in the Quick Ask panel
3. Get instant responses without opening the main window

### Global Shortcuts

- `Cmd+Shift+A` - Open Quick Ask from anywhere
- `Cmd+Shift+P` - Open command palette
- Custom shortcuts can be configured in Settings

### Project Management

1. Switch projects using the project selector in the sidebar
2. Each project has its own sessions and context
3. Edit project's CLAUDE.md file for custom instructions

## Development

### Prerequisites

- **Xcode 15.0+** with Swift 5.9+
- **macOS 14.0+ SDK**
- **Claude Code CLI** for testing

### Building

```bash
# Debug build
./Scripts/build.sh -c Debug

# Release build
./Scripts/build.sh -c Release

# Clean build
./Scripts/build.sh --clean
```

### Testing

```bash
# Run tests
swift test

# Run with verbose output
swift test --verbose
```

### Project Structure

```
ClaudeDesktop/
├── Sources/
│   ├── CLIDetector/       # CLI detection and launch
│   ├── CLIManager/        # CLI process management
│   ├── Communication/     # Communication pipeline
│   ├── Protocol/          # Message protocol
│   ├── Streaming/         # SSE response handling
│   ├── State/             # Connection state
│   ├── ErrorHandling/     # Error handling and recovery
│   ├── Theme/             # Colors, typography, styles
│   ├── Models/            # Data models
│   ├── ViewModels/        # View models (MVVM)
│   ├── Views/             # SwiftUI views
│   ├── Highlighting/      # Code highlighting
│   ├── Upload/            # File upload handling
│   ├── Shortcuts/         # Keyboard shortcuts
│   ├── History/           # Session history
│   ├── Project/           # Project management
│   ├── MenuBar/           # MenuBar integration
│   ├── GlobalShortcuts/   # Global shortcuts
│   ├── Spotlight/         # Spotlight integration
│   ├── Notifications/     # Push notifications
│   ├── Performance/       # Performance monitoring
│   └── App/               # App lifecycle
├── Tests/                 # Unit tests
├── Resources/             # App resources
│   ├── Info.plist        # App configuration
│   └── Entitlements.entitlements
├── Scripts/              # Build and release scripts
│   ├── build.sh          # Build script
│   ├── sign.sh           # Code signing
│   ├── notarize.sh       # Apple notarization
│   └── create-dmg.sh     # DMG creation
├── docs/                 # Documentation
├── Package.swift         # Swift Package manifest
└── README.md             # This file
```

### Architecture

The app follows MVVM (Model-View-ViewModel) architecture with clear separation of concerns:

- **CLI Connection Layer** - Handles detection, communication, and streaming
- **UI Layer** - SwiftUI views with theme support
- **Enhanced Features** - Highlighting, upload, shortcuts, history
- **System Integration** - MenuBar, global shortcuts, Spotlight, notifications
- **Performance Layer** - Memory management, caching, optimization

### Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow Swift API Design Guidelines
- Use meaningful variable and function names
- Write documentation comments for public APIs
- Maintain test coverage above 80%

## Release Process

### Building for Release

```bash
# Build release version
./Scripts/build.sh -c Release -v 1.0.0

# Sign the app
./Scripts/sign.sh build/export/Claude\ Desktop.app

# Create DMG
./Scripts/create-dmg.sh build/export/Claude\ Desktop.app --sign

# Notarize with Apple
./Scripts/notarize.sh build/export/Claude\ Desktop.app
```

### Version Numbering

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR** - Breaking changes
- **MINOR** - New features, backward compatible
- **PATCH** - Bug fixes

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Powered by [Claude](https://claude.ai) by Anthropic
- Inspired by [Claude Code CLI](https://claude.ai/claude-code)

## Support

- **Documentation**: [docs/](docs/)
- **Issues**: [GitHub Issues](https://github.com/anthropics/claude-desktop-mac/issues)
- **Discussions**: [GitHub Discussions](https://github.com/anthropics/claude-desktop-mac/discussions)

---

<p align="center">
  Made with care for the Claude community
</p>
