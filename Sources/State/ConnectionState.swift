// ConnectionState.swift
// Claude Desktop Mac - Connection State Module
//
// Defines connection states and state machine for CLI connection

import Foundation

// MARK: - Connection State

/// Overall connection state for CLI
public enum ConnectionState: String, Sendable, Codable, Equatable {
    case idle           // Not connected
    case detecting      // Detecting CLI installation
    case connecting     // Establishing connection
    case connected      // Connected and ready
    case disconnecting  // Disconnecting
    case disconnected   // Disconnected
    case reconnecting   // Attempting to reconnect
    case error          // Error state

    /// Whether the connection is active
    public var isActive: Bool {
        switch self {
        case .connected, .connecting, .reconnecting:
            return true
        default:
            return false
        }
    }

    /// Whether an action can be initiated
    public var canStartAction: Bool {
        switch self {
        case .idle, .disconnected, .error:
            return true
        default:
            return false
        }
    }

    /// Human-readable description
    public var description: String {
        switch self {
        case .idle:
            return "Not Connected"
        case .detecting:
            return "Detecting CLI..."
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .disconnecting:
            return "Disconnecting..."
        case .disconnected:
            return "Disconnected"
        case .reconnecting:
            return "Reconnecting..."
        case .error:
            return "Connection Error"
        }
    }
}

// MARK: - Connection Error

/// Errors related to connection
public enum ConnectionError: Error, Sendable, LocalizedError {
    case cliNotFound
    case cliNotRunning
    case connectionFailed(String)
    case authenticationFailed
    case timeout
    case networkError(String)
    case protocolError(String)
    case unexpectedDisconnect
    case maxRetriesExceeded

    public var errorDescription: String? {
        switch self {
        case .cliNotFound:
            return "Claude Code CLI not found."
        case .cliNotRunning:
            return "Claude Code CLI is not running."
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .authenticationFailed:
            return "Authentication failed. Please check your API key."
        case .timeout:
            return "Connection timed out."
        case .networkError(let reason):
            return "Network error: \(reason)"
        case .protocolError(let reason):
            return "Protocol error: \(reason)"
        case .unexpectedDisconnect:
            return "Unexpected disconnection."
        case .maxRetriesExceeded:
            return "Maximum reconnection attempts exceeded."
        }
    }

    /// Suggested solution
    public var suggestedSolution: String {
        switch self {
        case .cliNotFound:
            return "Install Claude Code CLI using: npm install -g @anthropic-ai/claude-code"
        case .cliNotRunning:
            return "Start the CLI process first."
        case .connectionFailed:
            return "Check CLI installation and try again."
        case .authenticationFailed:
            return "Run 'claude auth' to configure your API key."
        case .timeout:
            return "Check your network connection and try again."
        case .networkError:
            return "Verify network connectivity."
        case .protocolError:
            return "Restart the application."
        case .unexpectedDisconnect:
            return "The connection will automatically attempt to reconnect."
        case .maxRetriesExceeded:
            return "Please manually reconnect."
        }
    }

    /// Whether reconnection should be attempted
    public var shouldRetry: Bool {
        switch self {
        case .cliNotFound, .authenticationFailed:
            return false
        default:
            return true
        }
    }
}
