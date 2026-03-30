// RecoveryManager.swift
// Claude Desktop Mac - Recovery Manager Module
//
// Handles automatic error recovery strategies

import Foundation
import Combine
import CLIDetector
import State
import ErrorHandling

// MARK: - Recovery Strategy

/// Strategy for recovering from errors
public enum RecoveryStrategy: Sendable {
    case reconnect              // Attempt to reconnect
    case restartProcess         // Restart the CLI process
    case clearCache             // Clear cached data
    case resetConnection        // Reset the entire connection
    case notifyUser             // Notify user for manual intervention
    case retry(delay: TimeInterval) // Retry with delay
    case none                   // No automatic recovery
}

// MARK: - Recovery Action

/// A recovery action to be performed
public struct RecoveryAction: Sendable {
    public let id: UUID
    public let error: ErrorInfo
    public let strategy: RecoveryStrategy
    public let timestamp: Date
    public var attemptCount: Int
    public var status: RecoveryStatus

    public init(error: ErrorInfo, strategy: RecoveryStrategy) {
        self.id = UUID()
        self.error = error
        self.strategy = strategy
        self.timestamp = Date()
        self.attemptCount = 0
        self.status = .pending
    }
}

// MARK: - Recovery Status

/// Status of a recovery action
public enum RecoveryStatus: String, Sendable, Codable {
    case pending
    case inProgress
    case succeeded
    case failed
    case cancelled
}

// MARK: - Recovery Manager

/// Manages error recovery strategies and execution
public final class RecoveryManager: @unchecked Sendable {

    // MARK: - Properties

    /// Maximum recovery attempts per error
    public var maxRecoveryAttempts: Int = 3

    /// Base delay for retry strategies
    public var retryBaseDelay: TimeInterval = 1.0

    /// Maximum delay for retry strategies
    public var retryMaxDelay: TimeInterval = 30.0

    /// Reference to connection manager
    private weak var connectionManager: ConnectionManager?

    /// Reference to error handler
    private let errorHandler: ErrorHandler

    /// Active recovery actions
    private var activeRecoveries: [UUID: RecoveryAction] = [:]

    /// Lock for thread safety
    private let lock = NSLock()

    /// Subject for recovery events
    private let recoverySubject = PassthroughSubject<RecoveryAction, Never>()

    /// Recovery queue
    private let recoveryQueue = DispatchQueue(label: "com.claude.desktop.recovery", qos: .utility)

    // MARK: - Initialization

    public init(
        connectionManager: ConnectionManager,
        errorHandler: ErrorHandler = .shared
    ) {
        self.connectionManager = connectionManager
        self.errorHandler = errorHandler

        setupObservers()
    }

    // MARK: - Public Methods

    /// Determine recovery strategy for an error
    public func determineStrategy(for error: ErrorInfo) -> RecoveryStrategy {
        switch error.category {
        case .cli:
            return .notifyUser

        case .connection:
            switch error.code {
            case "CONNECTION_CLI_NOT_FOUND":
                return .notifyUser
            case "CONNECTION_AUTH_FAILED":
                return .notifyUser
            case "CONNECTION_UNEXPECTED_DISCONNECT":
                return .reconnect
            case "CONNECTION_MAX_RETRIES_EXCEEDED":
                return .notifyUser
            default:
                return .reconnect
            }

        case .process:
            switch error.code {
            case "PROCESS_UNEXPECTED_TERMINATION":
                return .restartProcess
            case "PROCESS_ZOMBIE_PROCESS":
                return .resetConnection
            default:
                return .restartProcess
            }

        case .streaming:
            switch error.code {
            case "STREAMING_TIMEOUT":
                return .retry(delay: 5.0)
            case "STREAMING_CONNECTION_LOST":
                return .reconnect
            default:
                return .reconnect
            }

        case .messaging:
            return .resetConnection

        case .system:
            return .notifyUser

        case .unknown:
            return .notifyUser
        }
    }

    /// Execute recovery for an error
    public func recover(from error: ErrorInfo) async -> Bool {
        let strategy = determineStrategy(for: error)
        var action = RecoveryAction(error: error, strategy: strategy)

        lock.lock()
        activeRecoveries[action.id] = action
        lock.unlock()

        recoverySubject.send(action)

        let success = await executeRecovery(&action)

        lock.lock()
        if success {
            action.status = .succeeded
        } else {
            action.status = .failed
        }
        activeRecoveries[action.id] = action
        lock.unlock()

        recoverySubject.send(action)
        return success
    }

    /// Cancel all active recoveries
    public func cancelAllRecoveries() {
        lock.lock()
        defer { lock.unlock() }

        for (id, var action) in activeRecoveries {
            action.status = .cancelled
            activeRecoveries[id] = action
            recoverySubject.send(action)
        }
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // Observe errors from error handler
        errorHandler.recoveryPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorInfo in
                Task {
                    _ = await self?.recover(from: errorInfo)
                }
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    private func executeRecovery(_ action: inout RecoveryAction) async -> Bool {
        action.status = .inProgress
        action.attemptCount += 1

        guard action.attemptCount <= maxRecoveryAttempts else {
            return false
        }

        switch action.strategy {
        case .reconnect:
            return await executeReconnect()

        case .restartProcess:
            return await executeRestartProcess()

        case .clearCache:
            return await executeClearCache()

        case .resetConnection:
            return await executeResetConnection()

        case .notifyUser:
            // User notification is handled by UI layer
            return false

        case .retry(let delay):
            return await executeRetry(delay: delay)

        case .none:
            return false
        }
    }

    private func executeReconnect() async -> Bool {
        guard let connectionManager = connectionManager else { return false }

        await connectionManager.disconnect()

        // Small delay before reconnecting
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        do {
            try await connectionManager.connect()
            return true
        } catch {
            return false
        }
    }

    private func executeRestartProcess() async -> Bool {
        guard let connectionManager = connectionManager else { return false }

        await connectionManager.disconnect()

        // Small delay before restarting
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        do {
            try await connectionManager.connect()
            return true
        } catch {
            return false
        }
    }

    private func executeClearCache() async -> Bool {
        // Clear any cached data
        CLIDetector.shared.clearCache()
        return true
    }

    private func executeResetConnection() async -> Bool {
        guard let connectionManager = connectionManager else { return false }

        await connectionManager.disconnect()

        // Clear cache
        CLIDetector.shared.clearCache()

        // Longer delay for full reset
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        do {
            try await connectionManager.connect()
            return true
        } catch {
            return false
        }
    }

    private func executeRetry(delay: TimeInterval) async -> Bool {
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        return await executeReconnect()
    }
}

// MARK: - Combine Support

extension RecoveryManager {

    /// Publisher for recovery actions
    public var recoveryPublisher: AnyPublisher<RecoveryAction, Never> {
        recoverySubject.eraseToAnyPublisher()
    }
}
