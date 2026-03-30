// MCPConfig.swift
// Claude Desktop Mac - MCP Configuration Model
//
// Represents MCP Server configuration and management

import Foundation
import SwiftUI

// MARK: - Server Type

/// MCP Server connection type
public enum MCPServerType: String, Codable, Sendable, CaseIterable {
    case stdio = "stdio"
    case sse = "sse"

    public var displayName: String {
        switch self {
        case .stdio:
            return "Local Process (stdio)"
        case .sse:
            return "HTTP Server (SSE)"
        }
    }

    public var iconName: String {
        switch self {
        case .stdio:
            return "terminal"
        case .sse:
            return "network"
        }
    }
}

// MARK: - Server Status

/// MCP Server connection status
public enum MCPServerStatus: String, Sendable {
    case idle = "idle"
    case starting = "starting"
    case running = "running"
    case stopping = "stopping"
    case stopped = "stopped"
    case error = "error"

    public var displayName: String {
        switch self {
        case .idle:
            return "Idle"
        case .starting:
            return "Starting..."
        case .running:
            return "Running"
        case .stopping:
            return "Stopping..."
        case .stopped:
            return "Stopped"
        case .error:
            return "Error"
        }
    }

    public var color: Color {
        switch self {
        case .idle:
            return .fgTertiary
        case .starting, .stopping:
            return .accentWarning
        case .running:
            return .accentSuccess
        case .stopped:
            return .fgSecondary
        case .error:
            return .accentError
        }
    }
}

// MARK: - MCP Server Configuration

/// MCP Server configuration
public struct MCPServer: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var name: String
    public var serverType: MCPServerType
    public var isEnabled: Bool

    // stdio type fields
    public var command: String?
    public var args: [String]?
    public var env: [String: String]?

    // sse type fields
    public var url: String?
    public var headers: [String: String]?

    // Metadata
    public var createdAt: Date
    public var updatedAt: Date
    public var lastError: String?

    public init(
        id: UUID = UUID(),
        name: String,
        serverType: MCPServerType = .stdio,
        isEnabled: Bool = true,
        command: String? = nil,
        args: [String]? = nil,
        env: [String: String]? = nil,
        url: String? = nil,
        headers: [String: String]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastError: String? = nil
    ) {
        self.id = id
        self.name = name
        self.serverType = serverType
        self.isEnabled = isEnabled
        self.command = command
        self.args = args
        self.env = env
        self.url = url
        self.headers = headers
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastError = lastError
    }

    /// Update timestamp
    public mutating func touch() {
        updatedAt = Date()
    }

    /// Hashable conformance
    public static func == (lhs: MCPServer, rhs: MCPServer) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - MCP Configuration Root

/// Root configuration for MCP servers
public struct MCPConfig: Codable, Sendable {
    public var mcpServers: [String: MCPServerConfig]

    public init(mcpServers: [String: MCPServerConfig] = [:]) {
        self.mcpServers = mcpServers
    }

    /// Server configuration for JSON format
    public struct MCPServerConfig: Codable, Sendable {
        public var command: String?
        public var args: [String]?
        public var env: [String: String]?
        public var url: String?
        public var headers: [String: String]?

        public init(
            command: String? = nil,
            args: [String]? = nil,
            env: [String: String]? = nil,
            url: String? = nil,
            headers: [String: String]? = nil
        ) {
            self.command = command
            self.args = args
            self.env = env
            self.url = url
            self.headers = headers
        }

        /// Convert from MCPServer
        public init(from server: MCPServer) {
            if server.serverType == .stdio {
                self.command = server.command
                self.args = server.args
                self.env = server.env
            } else {
                self.url = server.url
                self.headers = server.headers
            }
        }
    }

    /// Convert to JSON string
    public func toJsonString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    /// Parse from JSON string
    public static func from(jsonString: String) throws -> MCPConfig {
        guard let data = jsonString.data(using: .utf8) else {
            throw MCPConfigError.invalidJson
        }
        return try JSONDecoder().decode(MCPConfig.self, from: data)
    }
}

// MARK: - Errors

public enum MCPConfigError: Error, LocalizedError {
    case invalidJson
    case fileNotFound
    case writeFailed
    case invalidServerName
    case duplicateServerName

    public var errorDescription: String? {
        switch self {
        case .invalidJson:
            return "Invalid JSON format"
        case .fileNotFound:
            return "Configuration file not found"
        case .writeFailed:
            return "Failed to write configuration file"
        case .invalidServerName:
            return "Invalid server name"
        case .duplicateServerName:
            return "Server name already exists"
        }
    }
}

// MARK: - Sample Data

extension MCPServer {
    public static var sample: MCPServer {
        MCPServer(
            name: "memory",
            serverType: .stdio,
            isEnabled: true,
            command: "node",
            args: ["\${CLAUDE_PLUGIN_ROOT}/servers/memory/index.js"],
            env: nil
        )
    }

    public static var samples: [MCPServer] {
        [
            MCPServer(
                name: "memory",
                serverType: .stdio,
                isEnabled: true,
                command: "node",
                args: ["\${CLAUDE_PLUGIN_ROOT}/servers/memory/index.js"]
            ),
            MCPServer(
                name: "github",
                serverType: .stdio,
                isEnabled: true,
                command: "node",
                args: ["\${CLAUDE_PLUGIN_ROOT}/servers/github/server.js"],
                env: ["GITHUB_TOKEN": "\${GITHUB_TOKEN}"]
            ),
            MCPServer(
                name: "kubernetes",
                serverType: .stdio,
                isEnabled: false,
                command: "node",
                args: ["\${CLAUDE_PLUGIN_ROOT}/servers/kubernetes-mcp/index.js"],
                env: [
                    "KUBECONFIG": "\${KUBECONFIG}",
                    "K8S_NAMESPACE": "\${K8S_NAMESPACE:-default}"
                ]
            ),
            MCPServer(
                name: "remote-api",
                serverType: .sse,
                isEnabled: true,
                url: "https://mcp-server.example.com/sse",
                headers: ["Authorization": "Bearer \${API_TOKEN}"]
            )
        ]
    }
}
