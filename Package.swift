// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ClaudeDesktopMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "ClaudeDesktop",
            targets: ["ClaudeDesktop"]),
        .library(
            name: "CLIDetector",
            targets: ["CLIDetector"]),
        .library(
            name: "CLIManager",
            targets: ["CLIManager"]),
        .library(
            name: "Communication",
            targets: ["Communication"]),
        .library(
            name: "Protocol",
            targets: ["Protocol"]),
        .library(
            name: "Streaming",
            targets: ["Streaming"]),
        .library(
            name: "State",
            targets: ["State"]),
        .library(
            name: "ErrorHandling",
            targets: ["ErrorHandling"]),
        .library(
            name: "CLIConnector",
            targets: ["CLIConnector"]),
        // Phase 2: UI Layer
        .library(
            name: "Theme",
            targets: ["Theme"]),
        .library(
            name: "Models",
            targets: ["Models"]),
        .library(
            name: "ViewModels",
            targets: ["ViewModels"]),
        .library(
            name: "Views",
            targets: ["Views"]),
        .library(
            name: "ClaudeDesktopUI",
            targets: ["ClaudeDesktopUI"]),
        // Phase 3: Enhanced Features
        .library(
            name: "Highlighting",
            targets: ["Highlighting"]),
        .library(
            name: "Upload",
            targets: ["Upload"]),
        .library(
            name: "Shortcuts",
            targets: ["Shortcuts"]),
        .library(
            name: "History",
            targets: ["History"]),
        .library(
            name: "Project",
            targets: ["Project"]),
        // Phase 4: System Integration
        .library(
            name: "MenuBar",
            targets: ["MenuBar"]),
        .library(
            name: "GlobalShortcuts",
            targets: ["GlobalShortcuts"]),
        .library(
            name: "Spotlight",
            targets: ["Spotlight"]),
        .library(
            name: "Notifications",
            targets: ["Notifications"]),
        .library(
            name: "App",
            targets: ["App"]),
        // Phase 5: Performance & Release
        .library(
            name: "Performance",
            targets: ["Performance"]),
    ],
    dependencies: [
        // Add dependencies here as needed
    ],
    targets: [
        // Phase 1: CLI Connection Layer
        .target(
            name: "CLIDetector",
            dependencies: [],
            path: "Sources/CLIDetector"),
        .target(
            name: "CLIManager",
            dependencies: [],
            path: "Sources/CLIManager"),
        .target(
            name: "Communication",
            dependencies: [],
            path: "Sources/Communication"),
        .target(
            name: "Protocol",
            dependencies: [],
            path: "Sources/Protocol"),
        .target(
            name: "Streaming",
            dependencies: ["Protocol"],
            path: "Sources/Streaming"),
        .target(
            name: "State",
            dependencies: [
                "CLIDetector",
                "CLIManager",
                "Communication",
                "Streaming",
                "Protocol",
                "ErrorHandling"
            ],
            path: "Sources/State"),
        .target(
            name: "ErrorHandling",
            dependencies: [],
            path: "Sources/ErrorHandling"),
        .target(
            name: "CLIConnector",
            dependencies: [
                "CLIDetector",
                "CLIManager",
                "Communication",
                "Streaming",
                "Protocol",
                "State",
                "ErrorHandling"
            ],
            path: "Sources/CLIConnector"),

        // Phase 2: UI Layer
        .target(
            name: "Theme",
            dependencies: [],
            path: "Sources/Theme"),
        .target(
            name: "Models",
            dependencies: ["Protocol"],
            path: "Sources/Models"),
        .target(
            name: "ViewModels",
            dependencies: [
                "Models",
                "Protocol",
                "Streaming",
                "State",
                "CLIConnector",
                "CLIDetector",
                "ErrorHandling"
            ],
            path: "Sources/ViewModels"),
        .target(
            name: "Views",
            dependencies: [
                "Theme",
                "Models",
                "ViewModels",
                "State"
            ],
            path: "Sources/Views"),
        .target(
            name: "ClaudeDesktopUI",
            dependencies: [
                "Theme",
                "Models",
                "ViewModels",
                "Views",
                "CLIConnector",
                // Phase 3 modules
                "Highlighting",
                "Upload",
                "Shortcuts",
                "History",
                "Project",
                // Phase 4 modules
                "MenuBar",
                "GlobalShortcuts",
                "Spotlight",
                "Notifications",
                "App"
            ],
            path: "Sources/UI"),

        // Phase 3: Enhanced Features
        .target(
            name: "Highlighting",
            dependencies: ["Theme"],
            path: "Sources/Highlighting"),
        .target(
            name: "Upload",
            dependencies: ["Theme"],
            path: "Sources/Upload"),
        .target(
            name: "Shortcuts",
            dependencies: [],
            path: "Sources/Shortcuts"),
        .target(
            name: "History",
            dependencies: ["Models", "Theme"],
            path: "Sources/History"),
        .target(
            name: "Project",
            dependencies: ["Models", "Highlighting", "Theme"],
            path: "Sources/Project"),

        // Phase 4: System Integration
        .target(
            name: "MenuBar",
            dependencies: ["Theme", "Models", "Project"],
            path: "Sources/MenuBar"),
        .target(
            name: "GlobalShortcuts",
            dependencies: ["Theme", "Models", "Shortcuts", "MenuBar", "Project"],
            path: "Sources/GlobalShortcuts"),
        .target(
            name: "Spotlight",
            dependencies: ["Models", "Project", "MenuBar"],
            path: "Sources/Spotlight"),
        .target(
            name: "Notifications",
            dependencies: ["Theme", "Models"],
            path: "Sources/Notifications"),
        .target(
            name: "App",
            dependencies: [
                "Theme",
                "Models",
                "MenuBar",
                "GlobalShortcuts",
                "Spotlight",
                "Notifications",
                "Project",
                "State",
                "Performance"
            ],
            path: "Sources/App"),

        // Phase 5: Performance & Release
        .target(
            name: "Performance",
            dependencies: [],
            path: "Sources/Performance"),

        // Main executable target
        .executableTarget(
            name: "ClaudeDesktop",
            dependencies: [
                "ClaudeDesktopUI",
                "App"
            ],
            path: "Sources/ClaudeDesktop"),

        // Test Targets
        .testTarget(
            name: "ProtocolTests",
            dependencies: ["Protocol"],
            path: "Tests/ProtocolTests"),
        .testTarget(
            name: "StreamingTests",
            dependencies: ["Streaming"],
            path: "Tests/StreamingTests"),
        .testTarget(
            name: "ConnectionTests",
            dependencies: ["State", "CLIConnector"],
            path: "Tests/ConnectionTests"),
    ]
)
