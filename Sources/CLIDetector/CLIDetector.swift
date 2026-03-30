// CLIDetector.swift
// Claude Desktop Mac - CLI Detection Module
//
// Detects Claude Code CLI installation and validates environment

import Foundation

// MARK: - CLI Detection Result

/// Result of CLI detection operation
public struct CLIDetectionResult: Sendable {
    public let isInstalled: Bool
    public let path: String?
    public let version: String?
    public let environmentStatus: EnvironmentStatus
    public let error: CLIDetectionError?

    public init(
        isInstalled: Bool,
        path: String? = nil,
        version: String? = nil,
        environmentStatus: EnvironmentStatus = .unknown,
        error: CLIDetectionError? = nil
    ) {
        self.isInstalled = isInstalled
        self.path = path
        self.version = version
        self.environmentStatus = environmentStatus
        self.error = error
    }

    /// Successful detection with path and version
    public static func success(path: String, version: String, environmentStatus: EnvironmentStatus) -> CLIDetectionResult {
        CLIDetectionResult(
            isInstalled: true,
            path: path,
            version: version,
            environmentStatus: environmentStatus
        )
    }

    /// CLI not found
    public static func notFound(error: CLIDetectionError? = nil) -> CLIDetectionResult {
        CLIDetectionResult(
            isInstalled: false,
            environmentStatus: .cliNotFound,
            error: error ?? .cliNotFound
        )
    }

    /// CLI found but environment issues
    public static func environmentIssue(path: String, version: String?, error: CLIDetectionError) -> CLIDetectionResult {
        CLIDetectionResult(
            isInstalled: true,
            path: path,
            version: version,
            environmentStatus: .error,
            error: error
        )
    }
}

// MARK: - Environment Status

/// Status of the CLI environment
public enum EnvironmentStatus: String, Sendable, Codable {
    case ready           // CLI installed and API key configured
    case missingApiKey   // CLI installed but API key not configured
    case cliNotFound     // CLI not installed
    case outdatedVersion // CLI version too old
    case error           // Other environment errors
    case unknown         // Not yet checked
}

// MARK: - CLI Detection Error

/// Errors that can occur during CLI detection
public enum CLIDetectionError: Error, Sendable, LocalizedError {
    case cliNotFound
    case pathNotAccessible(String)
    case versionCheckFailed(String)
    case apiKeyNotConfigured
    case detectionFailed(String)
    case customPathInvalid(String)

    public var errorDescription: String? {
        switch self {
        case .cliNotFound:
            return "Claude Code CLI not found. Please install it first."
        case .pathNotAccessible(let path):
            return "CLI path '\(path)' is not accessible."
        case .versionCheckFailed(let reason):
            return "Failed to check CLI version: \(reason)"
        case .apiKeyNotConfigured:
            return "API key is not configured. Please run 'claude auth' to configure."
        case .detectionFailed(let reason):
            return "Detection failed: \(reason)"
        case .customPathInvalid(let path):
            return "Custom path '\(path)' is invalid."
        }
    }

    /// Suggested solution for the error
    public var suggestedSolution: String {
        switch self {
        case .cliNotFound:
            return "Install Claude Code CLI using: npm install -g @anthropic-ai/claude-code"
        case .pathNotAccessible:
            return "Check file permissions or reinstall the CLI."
        case .versionCheckFailed:
            return "Try reinstalling Claude Code CLI."
        case .apiKeyNotConfigured:
            return "Run 'claude auth' in terminal to configure your API key."
        case .detectionFailed:
            return "Check your system configuration and try again."
        case .customPathInvalid:
            return "Verify the custom path is correct and the file exists."
        }
    }
}

// MARK: - CLI Detector

/// Detects and validates Claude Code CLI installation
public final class CLIDetector: @unchecked Sendable {

    // MARK: - Properties

    /// Common installation paths for Claude Code CLI
    public static let defaultSearchPaths = [
        "/usr/local/bin/claude",
        "/opt/homebrew/bin/claude",
        "/usr/bin/claude",
        "/opt/local/bin/claude",
        "\(NSHomeDirectory())/.local/bin/claude",
        "\(NSHomeDirectory())/.npm-global/bin/claude",
        "\(NSHomeDirectory())/node_modules/.bin/claude"
    ]

    /// Cached detection result
    private var cachedResult: CLIDetectionResult?
    private let cacheLock = NSLock()

    /// Custom CLI path (user-configured)
    public var customPath: String?

    // MARK: - Singleton

    public static let shared = CLIDetector()

    private init() {}

    // MARK: - Public Methods

    /// Detect CLI installation (with caching)
    public func detect() async -> CLIDetectionResult {
        // Check cache first
        cacheLock.lock()
        defer { cacheLock.unlock() }

        if let cached = cachedResult {
            return cached
        }

        let result = await performDetection()
        cachedResult = result
        return result
    }

    /// Force re-detection (ignores cache)
    public func reDetect() async -> CLIDetectionResult {
        cacheLock.lock()
        cachedResult = nil
        cacheLock.unlock()

        return await detect()
    }

    /// Detect CLI at a specific path
    public func detectAtPath(_ path: String) async -> CLIDetectionResult {
        return await performDetection(customPath: path)
    }

    /// Set custom CLI path
    public func setCustomPath(_ path: String) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        customPath = path
        cachedResult = nil // Invalidate cache
    }

    /// Clear cache
    public func clearCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        cachedResult = nil
    }

    // MARK: - Private Methods

    private func performDetection(customPath: String? = nil) async -> CLIDetectionResult {
        // Determine which path to use
        let pathToCheck = customPath ?? self.customPath

        // If custom path is specified, check it first
        if let customPath = pathToCheck {
            return await checkPath(customPath, isCustom: true)
        }

        // Search default paths
        for path in Self.defaultSearchPaths {
            let result = await checkPath(path, isCustom: false)
            if result.isInstalled {
                return result
            }
        }

        // Try to find in PATH using `which`
        if let whichResult = await findUsingWhich() {
            return whichResult
        }

        return .notFound()
    }

    private func checkPath(_ path: String, isCustom: Bool) async -> CLIDetectionResult {
        let fileManager = FileManager.default

        // Check if file exists
        guard fileManager.fileExists(atPath: path) else {
            if isCustom {
                return .notFound(error: .customPathInvalid(path))
            }
            return .notFound()
        }

        // Check if file is executable
        guard fileManager.isExecutableFile(atPath: path) else {
            return .environmentIssue(
                path: path,
                version: nil,
                error: .pathNotAccessible(path)
            )
        }

        // Get version
        let version = await getVersion(at: path)

        // Check environment (API key)
        let envStatus = await checkEnvironment()

        if case .missingApiKey = envStatus {
            return .environmentIssue(
                path: path,
                version: version,
                error: .apiKeyNotConfigured
            )
        }

        return .success(
            path: path,
            version: version ?? "unknown",
            environmentStatus: envStatus
        )
    }

    private func findUsingWhich() async -> CLIDetectionResult? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["claude"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let path = output.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !path.isEmpty {
                        return await checkPath(path, isCustom: false)
                    }
                }
            }
        } catch {
            // `which` command failed, continue with other methods
        }

        return nil
    }

    private func getVersion(at path: String) async -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["--version"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            // Version check failed
        }

        return nil
    }

    private func checkEnvironment() async -> EnvironmentStatus {
        // Check if ANTHROPIC_API_KEY is set
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", "echo $ANTHROPIC_API_KEY"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let apiKey = output.trimmingCharacters(in: .whitespacesAndNewlines)
                return apiKey.isEmpty ? .missingApiKey : .ready
            }
        } catch {
            // Environment check failed
        }

        return .unknown
    }
}

// MARK: - Publisher Support (Combine)

import Combine

extension CLIDetector {

    /// Publisher for detection result
    public func detectPublisher() -> AnyPublisher<CLIDetectionResult, Never> {
        Future { promise in
            Task {
                let result = await self.detect()
                promise(.success(result))
            }
        }
        .eraseToAnyPublisher()
    }
}
