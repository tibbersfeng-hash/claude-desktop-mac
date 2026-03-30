// ProcessMonitor.swift
// Claude Desktop Mac - CLI Process Monitor
//
// Monitors CLI process health and provides heartbeat functionality

import Foundation
import Combine

// MARK: - Process Health Status

/// Health status of the CLI process
public enum ProcessHealthStatus: Sendable {
    case healthy
    case degraded(String)
    case unhealthy(String)
    case unknown
}

// MARK: - Process Monitor

/// Monitors CLI process health
public final class ProcessMonitor: @unchecked Sendable {

    // MARK: - Properties

    /// Interval for heartbeat checks
    public var heartbeatInterval: TimeInterval = 30.0

    /// Timeout for health check responses
    public var healthCheckTimeout: TimeInterval = 5.0

    /// Current health status
    public private(set) var healthStatus: ProcessHealthStatus = .unknown

    /// Whether monitoring is active
    public private(set) var isMonitoring = false

    /// Reference to the process manager
    private weak var processManager: CLIProcessManager?

    /// Timer for periodic checks
    private var heartbeatTimer: Timer?

    /// Subject for health updates
    private let healthSubject = CurrentValueSubject<ProcessHealthStatus, Never>(.unknown)

    /// Lock for thread safety
    private let lock = NSLock()

    // MARK: - Initialization

    public init(processManager: CLIProcessManager) {
        self.processManager = processManager
    }

    // MARK: - Public Methods

    /// Start monitoring
    public func startMonitoring() {
        lock.lock()
        defer { lock.unlock() }

        guard !isMonitoring else { return }

        isMonitoring = true

        // Start heartbeat timer on main thread
        DispatchQueue.main.async { [weak self] in
            self?.startHeartbeatTimer()
        }
    }

    /// Stop monitoring
    public func stopMonitoring() {
        lock.lock()
        defer { lock.unlock() }

        isMonitoring = false

        // Stop timer on main thread
        DispatchQueue.main.async { [weak self] in
            self?.heartbeatTimer?.invalidate()
            self?.heartbeatTimer = nil
        }
    }

    /// Perform an immediate health check
    public func checkHealth() async -> ProcessHealthStatus {
        guard let processManager = processManager else {
            return .unhealthy("Process manager not available")
        }

        // Check if process is running
        guard processManager.isRunning else {
            let status = ProcessHealthStatus.unhealthy("Process is not running")
            updateHealthStatus(status)
            return status
        }

        // Check if pipes are valid
        guard processManager.standardInput != nil && processManager.standardOutput != nil else {
            let status = ProcessHealthStatus.unhealthy("Communication pipes are not available")
            updateHealthStatus(status)
            return status
        }

        // Send a ping and wait for response
        // Note: This depends on the CLI protocol supporting a ping/health check
        // For now, just check if the process is alive
        let status = ProcessHealthStatus.healthy
        updateHealthStatus(status)
        return status
    }

    // MARK: - Private Methods

    private func startHeartbeatTimer() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            Task {
                _ = await self?.checkHealth()
            }
        }
    }

    private func updateHealthStatus(_ status: ProcessHealthStatus) {
        lock.lock()
        defer { lock.unlock() }
        healthStatus = status
        healthSubject.send(status)
    }
}

// MARK: - Combine Support

extension ProcessMonitor {

    /// Publisher for health status updates
    public var healthPublisher: AnyPublisher<ProcessHealthStatus, Never> {
        healthSubject.eraseToAnyPublisher()
    }
}
