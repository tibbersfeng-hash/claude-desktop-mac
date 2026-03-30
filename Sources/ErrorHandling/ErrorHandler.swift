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
    case messaging   // Protocol/communication errors (renamed from 'protocol' which is a Swift keyword)
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
        addError(info)

        return info
    }

    /// Handle an error with explicit category and code
    @discardableResult
    public func handle(
        _ error: Error,
        category: ErrorCategory,
        code: String,
        suggestedSolution: String? = nil,
        recoverable: Bool = true
    ) -> ErrorInfo {
        let info = ErrorInfo(
            category: category,
            code: code,
            message: error.localizedDescription,
            suggestedSolution: suggestedSolution,
            recoverable: recoverable
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
        let errorString = String(describing: type(of: error))

        if errorString.contains("CLI") || errorString.contains("Detection") {
            return .cli
        } else if errorString.contains("Connection") || errorString.contains("Pipeline") {
            return .connection
        } else if errorString.contains("Stream") {
            return .streaming
        } else if errorString.contains("Process") {
            return .process
        } else if errorString.contains("Serialization") || errorString.contains("Protocol") {
            return .messaging
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
