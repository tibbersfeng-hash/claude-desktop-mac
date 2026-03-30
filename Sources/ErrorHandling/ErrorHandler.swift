// ErrorHandler.swift
// Claude Desktop Mac - Error Handler Module
//
// Centralized error handling and recovery

import Foundation
import Combine

// MARK: - Error Category

/// Categories of errors
public enum ErrorCategory: String, Sendable, Codable {
    case cli         // CLI-related errors
    case connection  // Connection errors
    case protocol    // Protocol/communication errors
    case streaming   // Streaming errors
    case process     // Process management errors
    case system      // System errors
    case unknown     // Unknown errors
}

// MARK: - Error Info

/// Detailed error information
public struct ErrorInfo: Sendable {
    public let id: UUID
    public let category: ErrorCategory
    public let code: String
    public let message: String
    public let details: String?
    public let suggestedSolution: String?
    public let timestamp: Date
    public let recoverable: Bool
    public let recoveryAction: String?

    public init(
        category: ErrorCategory,
        code: String,
        message: String,
        details: String? = nil,
        suggestedSolution: String? = nil,
        recoverable: Bool = true,
        recoveryAction: String? = nil
    ) {
        self.id = UUID()
        self.category = category
        self.code = code
        self.message = message
        self.details = details
        self.suggestedSolution = suggestedSolution
        self.timestamp = Date()
        self.recoverable = recoverable
        self.recoveryAction = recoveryAction
    }
}

// MARK: - Error Handler

/// Centralized error handling and logging
public final class ErrorHandler: @unchecked Sendable {

    // MARK: - Properties

    /// Maximum number of errors to keep in history
    public var maxErrorHistory: Int = 100

    /// Error history
    private var errorHistory: [ErrorInfo] = []

    /// Lock for thread safety
    private let lock = NSLock()

    /// Subject for error events
    private let errorSubject = PassthroughSubject<ErrorInfo, Never>()

    /// Subject for recovery suggestions
    private let recoverySubject = PassthroughSubject<ErrorInfo, Never>()

    // MARK: - Singleton

    public static let shared = ErrorHandler()

    private init() {}

    // MARK: - Error Handling

    /// Handle an error and return error info
    @discardableResult
    public func handle(_ error: Error, category: ErrorCategory? = nil) -> ErrorInfo {
        let errorCategory = category ?? categorize(error)
        let info = createErrorInfo(from: error, category: errorCategory)

        // Add to history
        lock.lock()
        errorHistory.append(info)
        if errorHistory.count > maxErrorHistory {
            errorHistory.removeFirst()
        }
        lock.unlock()

        // Emit error
        errorSubject.send(info)

        // Emit recovery suggestion if recoverable
        if info.recoverable {
            recoverySubject.send(info)
        }

        return info
    }

    /// Handle a CLI detection error
    @discardableResult
    public func handle(_ error: CLIDetectionError) -> ErrorInfo {
        let info = ErrorInfo(
            category: .cli,
            code: "CLI_\(error.code)",
            message: error.errorDescription ?? "CLI detection error",
            suggestedSolution: error.suggestedSolution,
            recoverable: error.canRecover
        )
        addError(info)
        return info
    }

    /// Handle a process error
    @discardableResult
    public func handle(_ error: CLIProcessError) -> ErrorInfo {
        let info = ErrorInfo(
            category: .process,
            code: "PROCESS_\(error.code)",
            message: error.errorDescription ?? "Process error",
            suggestedSolution: error.suggestedSolution,
            recoverable: error.canRecover
        )
        addError(info)
        return info
    }

    /// Handle a pipeline error
    @discardableResult
    public func handle(_ error: PipelineError) -> ErrorInfo {
        let info = ErrorInfo(
            category: .connection,
            code: "PIPELINE_\(error.code)",
            message: error.errorDescription ?? "Pipeline error",
            recoverable: error.canRecover
        )
        addError(info)
        return info
    }

    /// Handle a connection error
    @discardableResult
    public func handle(_ error: ConnectionError) -> ErrorInfo {
        let info = ErrorInfo(
            category: .connection,
            code: "CONNECTION_\(error.code)",
            message: error.errorDescription ?? "Connection error",
            suggestedSolution: error.suggestedSolution,
            recoverable: error.shouldRetry
        )
        addError(info)
        return info
    }

    /// Handle a streaming error
    @discardableResult
    public func handle(_ error: StreamingError) -> ErrorInfo {
        let info = ErrorInfo(
            category: .streaming,
            code: "STREAMING_\(error.code)",
            message: error.errorDescription ?? "Streaming error",
            recoverable: error.canRecover
        )
        addError(info)
        return info
    }

    // MARK: - Error History

    /// Get all errors in history
    public func getErrorHistory() -> [ErrorInfo] {
        lock.lock()
        defer { lock.unlock() }
        return errorHistory
    }

    /// Clear error history
    public func clearHistory() {
        lock.lock()
        defer { lock.unlock() }
        errorHistory.removeAll()
    }

    /// Get errors by category
    public func getErrors(by category: ErrorCategory) -> [ErrorInfo] {
        return getErrorHistory().filter { $0.category == category }
    }

    /// Get recent errors
    public func getRecentErrors(count: Int = 10) -> [ErrorInfo] {
        let history = getErrorHistory()
        return Array(history.suffix(count))
    }

    // MARK: - Private Methods

    private func addError(_ info: ErrorInfo) {
        lock.lock()
        defer { lock.unlock() }

        errorHistory.append(info)
        if errorHistory.count > maxErrorHistory {
            errorHistory.removeFirst()
        }

        errorSubject.send(info)

        if info.recoverable {
            recoverySubject.send(info)
        }
    }

    private func categorize(_ error: Error) -> ErrorCategory {
        if error is CLIDetectionError {
            return .cli
        } else if error is CLIProcessError {
            return .process
        } else if error is PipelineError {
            return .connection
        } else if error is ConnectionError {
            return .connection
        } else if error is StreamingError {
            return .streaming
        } else if error is SerializationError {
            return .protocol
        }
        return .unknown
    }

    private func createErrorInfo(from error: Error, category: ErrorCategory) -> ErrorInfo {
        let nsError = error as NSError
        let code = "\(nsError.domain)_\(nsError.code)"

        return ErrorInfo(
            category: category,
            code: code,
            message: error.localizedDescription,
            details: nsError.localizedFailureReason,
            recoverable: true
        )
    }
}

// MARK: - Error Code Extensions

extension CLIDetectionError {
    var code: String {
        switch self {
        case .cliNotFound: return "NOT_FOUND"
        case .pathNotAccessible: return "PATH_NOT_ACCESSIBLE"
        case .versionCheckFailed: return "VERSION_CHECK_FAILED"
        case .apiKeyNotConfigured: return "API_KEY_NOT_CONFIGURED"
        case .detectionFailed: return "DETECTION_FAILED"
        case .customPathInvalid: return "CUSTOM_PATH_INVALID"
        }
    }

    var canRecover: Bool {
        switch self {
        case .cliNotFound, .customPathInvalid:
            return true
        case .apiKeyNotConfigured:
            return true
        default:
            return false
        }
    }
}

extension CLIProcessError {
    var code: String {
        switch self {
        case .processAlreadyRunning: return "ALREADY_RUNNING"
        case .processNotRunning: return "NOT_RUNNING"
        case .failedToStart: return "FAILED_TO_START"
        case .failedToTerminate: return "FAILED_TO_TERMINATE"
        case .unexpectedTermination: return "UNEXPECTED_TERMINATION"
        case .timeout: return "TIMEOUT"
        case .zombieProcessDetected: return "ZOMBIE_PROCESS"
        }
    }

    var canRecover: Bool {
        switch self {
        case .processAlreadyRunning, .processNotRunning:
            return true
        case .unexpectedTermination, .zombieProcessDetected:
            return true
        default:
            return false
        }
    }
}

extension PipelineError {
    var code: String {
        switch self {
        case .notConnected: return "NOT_CONNECTED"
        case .writeFailed: return "WRITE_FAILED"
        case .readFailed: return "READ_FAILED"
        case .connectionTimeout: return "TIMEOUT"
        case .invalidData: return "INVALID_DATA"
        case .pipelineClosed: return "PIPELINE_CLOSED"
        }
    }

    var canRecover: Bool {
        switch self {
        case .notConnected, .connectionTimeout:
            return true
        default:
            return false
        }
    }
}

extension ConnectionError {
    var code: String {
        switch self {
        case .cliNotFound: return "CLI_NOT_FOUND"
        case .cliNotRunning: return "CLI_NOT_RUNNING"
        case .connectionFailed: return "CONNECTION_FAILED"
        case .authenticationFailed: return "AUTH_FAILED"
        case .timeout: return "TIMEOUT"
        case .networkError: return "NETWORK_ERROR"
        case .protocolError: return "PROTOCOL_ERROR"
        case .unexpectedDisconnect: return "UNEXPECTED_DISCONNECT"
        case .maxRetriesExceeded: return "MAX_RETRIES_EXCEEDED"
        }
    }
}

extension StreamingError {
    var code: String {
        switch self {
        case .timeout: return "TIMEOUT"
        case .connectionLost: return "CONNECTION_LOST"
        case .parseError: return "PARSE_ERROR"
        case .interrupted: return "INTERRUPTED"
        case .invalidState: return "INVALID_STATE"
        }
    }

    var canRecover: Bool {
        switch self {
        case .connectionLost, .timeout:
            return true
        default:
            return false
        }
    }
}

// MARK: - Combine Support

extension ErrorHandler {

    /// Publisher for error events
    public var errorPublisher: AnyPublisher<ErrorInfo, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    /// Publisher for recovery suggestions
    public var recoveryPublisher: AnyPublisher<ErrorInfo, Never> {
        recoverySubject.eraseToAnyPublisher()
    }
}
