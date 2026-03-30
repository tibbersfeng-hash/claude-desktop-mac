// MCPManagerViewModel.swift
// Claude Desktop Mac - MCP Manager ViewModel
//
// Manages MCP Server configuration state and operations

import Foundation
import SwiftUI
import Combine
import Models

// MARK: - MCP Manager ViewModel

@MainActor
@Observable
public final class MCPManagerViewModel {

    // MARK: - Properties

    /// All MCP servers
    public var servers: [MCPServer] = []

    /// Loading state
    public var isLoading: Bool = false

    /// Error message
    public var errorMessage: String?

    /// Success message
    public var successMessage: String?

    /// Selected server ID for editing
    public var selectedServerId: UUID?

    /// Whether showing add/edit sheet
    public var showServerSheet: Bool = false

    /// Whether showing delete confirmation
    public var showDeleteConfirmation: Bool = false

    /// Server to delete
    public var serverToDelete: MCPServer?

    /// Whether showing restart confirmation
    public var showRestartConfirmation: Bool = false

    // MARK: - Form State

    /// Editing server (nil for new)
    public var editingServer: MCPServer?

    /// Form fields
    public var formName: String = ""
    public var formServerType: MCPServerType = .stdio
    public var formIsEnabled: Bool = true
    public var formCommand: String = ""
    public var formArgs: String = ""
    public var formEnv: String = ""
    public var formUrl: String = ""
    public var formHeaders: String = ""

    // MARK: - Computed Properties

    /// Whether form is valid for submission
    public var isFormValid: Bool {
        guard !formName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        if formServerType == .stdio {
            return !formCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            return !formUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    /// Whether editing existing server
    public var isEditing: Bool {
        editingServer != nil
    }

    /// Enabled servers count
    public var enabledCount: Int {
        servers.filter { $0.isEnabled }.count
    }

    // MARK: - Private Properties

    private let configFileName = "claude_desktop_config.json"
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init() {
        loadServers()
    }

    // MARK: - Server Operations

    /// Load servers from configuration file
    public func loadServers() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let configPath = try getConfigPath()

                guard FileManager.default.fileExists(atPath: configPath.path) else {
                    // Config file doesn't exist yet, start with empty list
                    servers = []
                    isLoading = false
                    return
                }

                let data = try Data(contentsOf: configPath)
                let config = try JSONDecoder().decode(MCPConfig.self, from: data)

                // Convert to MCPServer array
                servers = config.mcpServers.map { name, serverConfig in
                    MCPServer(
                        name: name,
                        serverType: serverConfig.url != nil ? .sse : .stdio,
                        isEnabled: true,
                        command: serverConfig.command,
                        args: serverConfig.args,
                        env: serverConfig.env,
                        url: serverConfig.url,
                        headers: serverConfig.headers
                    )
                }

            } catch {
                // If decode fails, start fresh
                if let decodingError = error as? DecodingError {
                    print("Config decode error: \(decodingError)")
                }
                servers = []
            }

            isLoading = false
        }
    }

    /// Save servers to configuration file
    public func saveServers() {
        Task {
            do {
                var mcpServers: [String: MCPConfig.MCPServerConfig] = [:]

                for server in servers where server.isEnabled {
                    mcpServers[server.name] = MCPConfig.MCPServerConfig(from: server)
                }

                let config = MCPConfig(mcpServers: mcpServers)

                let configPath = try getConfigPath()
                let configDir = configPath.deletingLastPathComponent()

                // Ensure directory exists
                if !FileManager.default.fileExists(atPath: configDir.path) {
                    try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
                }

                // Write config
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(config)

                try data.write(to: configPath)
                successMessage = "Configuration saved successfully"

            } catch {
                errorMessage = "Failed to save configuration: \(error.localizedDescription)"
            }
        }
    }

    /// Get Claude Desktop config path
    private func getConfigPath() throws -> URL {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        return homeDir.appendingPathComponent("Library/Application Support/Claude/claude_desktop_config.json")
    }

    // MARK: - CRUD Operations

    /// Add a new server
    public func addServer() {
        guard isFormValid else { return }

        // Check for duplicate name
        if servers.contains(where: { $0.name.lowercased() == formName.lowercased() }) {
            errorMessage = "Server name already exists"
            return
        }

        let server = createServerFromForm()
        servers.append(server)
        saveServers()
        resetForm()
        showServerSheet = false
    }

    /// Update existing server
    public func updateServer() {
        guard let existingServer = editingServer, isFormValid else { return }

        // Check for duplicate name (excluding current server)
        if servers.contains(where: { $0.id != existingServer.id && $0.name.lowercased() == formName.lowercased() }) {
            errorMessage = "Server name already exists"
            return
        }

        if let index = servers.firstIndex(where: { $0.id == existingServer.id }) {
            var updated = createServerFromForm()
            updated.id = existingServer.id
            updated.createdAt = existingServer.createdAt
            servers[index] = updated
            saveServers()
        }

        resetForm()
        showServerSheet = false
    }

    /// Delete a server
    public func deleteServer(_ server: MCPServer) {
        servers.removeAll { $0.id == server.id }
        saveServers()
        serverToDelete = nil
        showDeleteConfirmation = false
    }

    /// Toggle server enabled state
    public func toggleServer(_ server: MCPServer) {
        guard let index = servers.firstIndex(where: { $0.id == server.id }) else { return }
        servers[index].isEnabled.toggle()
        servers[index].touch()
        saveServers()
    }

    /// Duplicate a server
    public func duplicateServer(_ server: MCPServer) {
        var newName = server.name
        var counter = 1

        while servers.contains(where: { $0.name == newName }) {
            newName = "\(server.name) (\(counter))"
            counter += 1
        }

        var newServer = server
        newServer = MCPServer(
            name: newName,
            serverType: server.serverType,
            isEnabled: false,
            command: server.command,
            args: server.args,
            env: server.env,
            url: server.url,
            headers: server.headers
        )

        servers.append(newServer)
        saveServers()
    }

    // MARK: - Form Operations

    /// Prepare form for new server
    public func prepareNewServer() {
        editingServer = nil
        resetForm()
        showServerSheet = true
    }

    /// Prepare form for editing server
    public func prepareEditServer(_ server: MCPServer) {
        editingServer = server
        formName = server.name
        formServerType = server.serverType
        formIsEnabled = server.isEnabled
        formCommand = server.command ?? ""
        formArgs = server.args?.joined(separator: " ") ?? ""
        formEnv = server.env?.map { "\($0.key)=\($0.value)" }.joined(separator: "\n") ?? ""
        formUrl = server.url ?? ""
        formHeaders = server.headers?.map { "\($0.key): \($0.value)" }.joined(separator: "\n") ?? ""
        showServerSheet = true
    }

    /// Reset form to defaults
    public func resetForm() {
        formName = ""
        formServerType = .stdio
        formIsEnabled = true
        formCommand = ""
        formArgs = ""
        formEnv = ""
        formUrl = ""
        formHeaders = ""
        editingServer = nil
        errorMessage = nil
    }

    /// Create server from form data
    private func createServerFromForm() -> MCPServer {
        var server = MCPServer(
            name: formName.trimmingCharacters(in: .whitespacesAndNewlines),
            serverType: formServerType,
            isEnabled: formIsEnabled
        )

        if formServerType == .stdio {
            server.command = formCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : formCommand.trimmingCharacters(in: .whitespacesAndNewlines)

            server.args = parseArgs(formArgs)

            server.env = parseKeyValuePairs(formEnv)
        } else {
            server.url = formUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : formUrl.trimmingCharacters(in: .whitespacesAndNewlines)

            server.headers = parseHeaders(formHeaders)
        }

        return server
    }

    /// Parse command line arguments
    private func parseArgs(_ input: String) -> [String]? {
        let args = input
            .split(separator: " ")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return args.isEmpty ? nil : args
    }

    /// Parse environment variables (KEY=value format)
    private func parseKeyValuePairs(_ input: String) -> [String: String]? {
        var result: [String: String] = [:]

        for line in input.split(separator: "\n") {
            let parts = line.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                if !key.isEmpty {
                    result[key] = value
                }
            }
        }

        return result.isEmpty ? nil : result
    }

    /// Parse HTTP headers (Key: Value format)
    private func parseHeaders(_ input: String) -> [String: String]? {
        var result: [String: String] = [:]

        for line in input.split(separator: "\n") {
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                if !key.isEmpty {
                    result[key] = value
                }
            }
        }

        return result.isEmpty ? nil : result
    }

    // MARK: - Confirmation Dialogs

    /// Show delete confirmation
    public func confirmDelete(_ server: MCPServer) {
        serverToDelete = server
        showDeleteConfirmation = true
    }

    /// Cancel delete
    public func cancelDelete() {
        serverToDelete = nil
        showDeleteConfirmation = false
    }

    // MARK: - Messages

    /// Clear messages
    public func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

// MARK: - Preview Support

extension MCPManagerViewModel {
    public static var preview: MCPManagerViewModel {
        let vm = MCPManagerViewModel()
        vm.servers = MCPServer.samples
        return vm
    }
}
