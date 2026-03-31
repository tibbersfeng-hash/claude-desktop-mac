import XCTest
@testable import Models

final class MCPConfigTests: XCTestCase {

    // MARK: - MCPServerType Tests

    func testMCPServerTypeRawValues() {
        XCTAssertEqual(MCPServerType.stdio.rawValue, "stdio")
        XCTAssertEqual(MCPServerType.sse.rawValue, "sse")
    }

    func testMCPServerTypeDisplayName() {
        XCTAssertEqual(MCPServerType.stdio.displayName, "Local Process (stdio)")
        XCTAssertEqual(MCPServerType.sse.displayName, "HTTP Server (SSE)")
    }

    func testMCPServerTypeIconName() {
        XCTAssertEqual(MCPServerType.stdio.iconName, "terminal")
        XCTAssertEqual(MCPServerType.sse.iconName, "network")
    }

    func testMCPServerTypeCaseIterable() {
        XCTAssertEqual(MCPServerType.allCases.count, 2)
        XCTAssertTrue(MCPServerType.allCases.contains(.stdio))
        XCTAssertTrue(MCPServerType.allCases.contains(.sse))
    }

    // MARK: - MCPServer Initialization Tests

    func testMCPServerInitialization() {
        let server = MCPServer(name: "test-server")

        XCTAssertNotNil(server.id)
        XCTAssertEqual(server.name, "test-server")
        XCTAssertEqual(server.serverType, .stdio)
        XCTAssertTrue(server.isEnabled)
        XCTAssertNil(server.command)
        XCTAssertNil(server.args)
        XCTAssertNil(server.env)
        XCTAssertNil(server.url)
        XCTAssertNil(server.headers)
        XCTAssertNil(server.lastError)
    }

    func testMCPServerStdioInitialization() {
        let server = MCPServer(
            name: "memory",
            serverType: .stdio,
            isEnabled: true,
            command: "node",
            args: ["server.js"],
            env: ["NODE_ENV": "production"]
        )

        XCTAssertEqual(server.name, "memory")
        XCTAssertEqual(server.serverType, .stdio)
        XCTAssertEqual(server.command, "node")
        XCTAssertEqual(server.args, ["server.js"])
        XCTAssertEqual(server.env?["NODE_ENV"], "production")
    }

    func testMCPServerSSEInitialization() {
        let server = MCPServer(
            name: "remote-api",
            serverType: .sse,
            isEnabled: true,
            url: "https://api.example.com/sse",
            headers: ["Authorization": "Bearer token"]
        )

        XCTAssertEqual(server.name, "remote-api")
        XCTAssertEqual(server.serverType, .sse)
        XCTAssertEqual(server.url, "https://api.example.com/sse")
        XCTAssertEqual(server.headers?["Authorization"], "Bearer token")
    }

    // MARK: - MCPServer Coding Tests

    func testMCPServerEncodingDecoding() throws {
        let original = MCPServer(
            name: "test",
            serverType: .stdio,
            isEnabled: true,
            command: "node",
            args: ["index.js"],
            env: ["KEY": "VALUE"]
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MCPServer.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.serverType, original.serverType)
        XCTAssertEqual(decoded.isEnabled, original.isEnabled)
        XCTAssertEqual(decoded.command, original.command)
        XCTAssertEqual(decoded.args, original.args)
        XCTAssertEqual(decoded.env, original.env)
    }

    func testMCPServerEncodingDecodingSSE() throws {
        let original = MCPServer(
            name: "remote",
            serverType: .sse,
            url: "https://example.com/sse",
            headers: ["Auth": "Token"]
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MCPServer.self, from: data)

        XCTAssertEqual(decoded.serverType, .sse)
        XCTAssertEqual(decoded.url, original.url)
        XCTAssertEqual(decoded.headers, original.headers)
    }

    // MARK: - MCPServer Hashable Tests

    func testMCPServerHashable() {
        let id = UUID()
        let server1 = MCPServer(id: id, name: "server1")
        let server2 = MCPServer(id: id, name: "server2")

        XCTAssertEqual(server1, server2, "Servers with same ID should be equal")

        let set = Set([server1, server2])
        XCTAssertEqual(set.count, 1, "Set should contain only one server with same ID")
    }

    func testMCPServerHashableDifferentIds() {
        let server1 = MCPServer(name: "server1")
        let server2 = MCPServer(name: "server2")

        XCTAssertNotEqual(server1, server2)

        let set = Set([server1, server2])
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - MCPConfig JSON Format Tests

    func testMCPConfigEmptyInitialization() {
        let config = MCPConfig()

        XCTAssertTrue(config.mcpServers.isEmpty)
    }

    func testMCPConfigToJsonString() throws {
        let serverConfig = MCPConfig.MCPServerConfig(
            command: "node",
            args: ["server.js"],
            env: ["KEY": "VALUE"]
        )
        let config = MCPConfig(mcpServers: ["test": serverConfig])

        let jsonString = try config.toJsonString()

        XCTAssertTrue(jsonString.contains("\"mcpServers\""))
        XCTAssertTrue(jsonString.contains("\"test\""))
        XCTAssertTrue(jsonString.contains("\"command\""))
        XCTAssertTrue(jsonString.contains("\"node\""))
    }

    func testMCPConfigFromJsonString() throws {
        let jsonString = """
        {
            "mcpServers": {
                "memory": {
                    "command": "node",
                    "args": ["index.js"]
                }
            }
        }
        """

        let config = try MCPConfig.from(jsonString: jsonString)

        XCTAssertEqual(config.mcpServers.count, 1)
        XCTAssertEqual(config.mcpServers["memory"]?.command, "node")
        XCTAssertEqual(config.mcpServers["memory"]?.args, ["index.js"])
    }

    func testMCPConfigOfficialFormatCompatibility() throws {
        // Test format that matches Claude Desktop's official config format
        let officialFormat = """
        {
            "mcpServers": {
                "filesystem": {
                    "command": "npx",
                    "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/dir"]
                },
                "github": {
                    "command": "npx",
                    "args": ["-y", "@modelcontextprotocol/server-github"],
                    "env": {
                        "GITHUB_TOKEN": "ghp_xxxx"
                    }
                }
            }
        }
        """

        let config = try MCPConfig.from(jsonString: officialFormat)

        XCTAssertEqual(config.mcpServers.count, 2)
        XCTAssertEqual(config.mcpServers["filesystem"]?.command, "npx")
        XCTAssertEqual(config.mcpServers["github"]?.env?["GITHUB_TOKEN"], "ghp_xxxx")
    }

    func testMCPConfigRoundTrip() throws {
        let serverConfig = MCPConfig.MCPServerConfig(
            command: "node",
            args: ["server.js"],
            env: ["API_KEY": "secret"]
        )
        let original = MCPConfig(mcpServers: ["server": serverConfig])

        let jsonString = try original.toJsonString()
        let decoded = try MCPConfig.from(jsonString: jsonString)

        XCTAssertEqual(decoded.mcpServers.count, original.mcpServers.count)
        XCTAssertEqual(decoded.mcpServers["server"]?.command, "node")
        XCTAssertEqual(decoded.mcpServers["server"]?.args, ["server.js"])
    }

    // MARK: - MCPServerConfig from MCPServer Tests

    func testMCPServerConfigFromStdioServer() {
        let server = MCPServer(
            name: "test",
            serverType: .stdio,
            command: "node",
            args: ["index.js"],
            env: ["KEY": "VALUE"]
        )

        let config = MCPConfig.MCPServerConfig(from: server)

        XCTAssertEqual(config.command, "node")
        XCTAssertEqual(config.args, ["index.js"])
        XCTAssertEqual(config.env?["KEY"], "VALUE")
        XCTAssertNil(config.url)
        XCTAssertNil(config.headers)
    }

    func testMCPServerConfigFromSSEServer() {
        let server = MCPServer(
            name: "remote",
            serverType: .sse,
            url: "https://example.com/sse",
            headers: ["Auth": "Token"]
        )

        let config = MCPConfig.MCPServerConfig(from: server)

        XCTAssertEqual(config.url, "https://example.com/sse")
        XCTAssertEqual(config.headers?["Auth"], "Token")
        XCTAssertNil(config.command)
        XCTAssertNil(config.args)
        XCTAssertNil(config.env)
    }

    // MARK: - MCPConfigError Tests

    func testMCPConfigErrorDescriptions() {
        XCTAssertEqual(MCPConfigError.invalidJson.errorDescription, "Invalid JSON format")
        XCTAssertEqual(MCPConfigError.fileNotFound.errorDescription, "Configuration file not found")
        XCTAssertEqual(MCPConfigError.writeFailed.errorDescription, "Failed to write configuration file")
        XCTAssertEqual(MCPConfigError.invalidServerName.errorDescription, "Invalid server name")
        XCTAssertEqual(MCPConfigError.duplicateServerName.errorDescription, "Server name already exists")
    }

    func testMCPConfigInvalidJsonError() {
        let invalidJson = "not valid json"

        XCTAssertThrowsError(try MCPConfig.from(jsonString: invalidJson)) { error in
            XCTAssertTrue(error is MCPConfigError)
        }
    }

    // MARK: - MCPServer Touch Tests

    func testMCPServerTouch() {
        var server = MCPServer(name: "test")
        let originalUpdatedAt = server.updatedAt

        // Small delay to ensure time difference
        Thread.sleep(forTimeInterval: 0.01)

        server.touch()

        XCTAssertGreaterThan(server.updatedAt, originalUpdatedAt)
    }

    // MARK: - Sample Data Tests

    func testMCPServerSample() {
        let sample = MCPServer.sample

        XCTAssertEqual(sample.name, "memory")
        XCTAssertEqual(sample.serverType, .stdio)
        XCTAssertTrue(sample.isEnabled)
    }

    func testMCPServerSamples() {
        let samples = MCPServer.samples

        XCTAssertFalse(samples.isEmpty)

        // Check for stdio type sample
        XCTAssertTrue(samples.contains { $0.serverType == .stdio })

        // Check for sse type sample
        XCTAssertTrue(samples.contains { $0.serverType == .sse })
    }
}
