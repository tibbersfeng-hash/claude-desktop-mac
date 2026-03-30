// CLIProcessManager.swift
// Claude Desktop Mac - CLI Process Manager Module
//
// Manages Claude Code CLI process lifecycle: start, monitor, terminate

import Foundation
import Combine

// MARK: - Process State

/// State of the CLI process
public enum CLIProcessState: String, Sendable, Codable {
    case notStarted    // Process not started yet
    case starting      // Process is starting
    case running       // Process is running normally
    case terminating   // Process is being terminated
    case terminated    // Process has terminated
    case crashed       // Process crashed unexpectedly
    case error         // Error state
}

// MARK: - Process Info

/// Information about the CLI process
public struct CLIProcessInfo: Sendable {
    public let processIdentifier: Int32
    public let path: String
    public let arguments: [String]
    public let startTime: Date
    public var state: CLIProcessState
    public var terminationReason: Process.TerminationReason?

    public init(
        processIdentifier: Int32,
        path: String,
        arguments: [String],
        startTime: Date = Date(),
        state: CLIProcessState = .starting
    ) {
        self.processIdentifier = processIdentifier
        self.path = path
        self.arguments = arguments
        self.startTime = startTime
        self.state = state
        self.terminationReason = nil
    }
}

// MARK: - Process Manager Error

/// Errors from the process manager
public enum CLIProcessError: Error, Sendable, LocalizedError {
    case processAlreadyRunning
    case processNotRunning
    case failedToStart(String)
    case failedToTerminate(String)
    case unexpectedTermination(Int32)
    case timeout
    case zombieProcessDetected

    public var errorDescription: String? {
        switch self {
        case .processAlreadyRunning:
            return "CLI process is already running."
        case .processNotRunning:
            return "No CLI process is running."
        case .failedToStart(let reason):
            return "Failed to start CLI process: \(reason)"
        case .failedToTerminate(let reason):
            return "Failed to terminate CLI process: \(reason)"
        case .unexpectedTermination(let exitCode):
            return "CLI process terminated unexpectedly with exit code \(exitCode)."
        case .timeout:
            return "Operation timed out."
        case .zombieProcessDetected:
            return "Zombie process detected. Please restart the application."
        }
    }

    public var suggestedSolution: String {
        switch self {
        case .processAlreadyRunning:
            return "Stop the current process before starting a new one."
        case .processNotRunning:
            return "Start the CLI process first."
        case .failedToStart:
            return "Check CLI installation and permissions."
        case .failedToTerminate:
            return "Try force quitting the application."
        case .unexpectedTermination:
            return "Restart the CLI process or check for errors."
        case .timeout:
            return "Try again or check system resources."
        case .zombieProcessDetected:
            return "Restart the application to clean up zombie processes."
        }
    }
}

// MARK: - Process Manager Delegate

/// Delegate for process manager events
public protocol CLIProcessManagerDelegate: AnyObject, Sendable {
    func processManager(_ manager: CLIProcessManager, didChangeState state: CLIProcessState)
    func processManager(_ manager: CLIProcessManager, didReceiveError error: CLIProcessError)
    func processManager(_ manager: CLIProcessManager, didOutputData data: Data)
}

// MARK: - CLI Process Manager

/// Manages the lifecycle of Claude Code CLI process
public final class CLIProcessManager: @unchecked Sendable {

    // MARK: - Properties

    /// The underlying Process instance
    private var process: Process?

    /// Process information
    private(set) public var processInfo: CLIProcessInfo?

    /// Current state
    public private(set) var state: CLIProcessState = .notStarted {
        didSet {
            notifyStateChange(state)
        }
    }

    /// Delegate for events
    public weak var delegate: CLIProcessManagerDelegate?

    /// Standard input pipe
    public private(set) var standardInput: FileHandle?

    /// Standard output pipe
    public private(set) var standardOutput: FileHandle?

    /// Standard error pipe
    public private(set) var standardError: FileHandle?

    /// Lock for thread safety
    private let lock = NSLock()

    /// State subject for Combine
    private let stateSubject = CurrentValueSubject<CLIProcessState, Never>(.notStarted)

    /// Error subject for Combine
    private let errorSubject = PassthroughSubject<CLIProcessError, Never>()

    /// Output subject for Combine
    private let outputSubject = PassthroughSubject<Data, Never>()

    // MARK: - Initialization

    public init() {}

    deinit {
        stopMonitoring()
        terminateProcessInternal(force: true)
    }

    // MARK: - Public Methods

    /// Start the CLI process
    /// - Parameters:
    ///   - path: Path to the CLI executable
    ///   - arguments: Arguments to pass to the CLI
    ///   - environment: Environment variables
    /// - Returns: Process information
    @discardableResult
    public func start(
        path: String,
        arguments: [String] = [],
        environment: [String: String]? = nil
    ) async throws -> CLIProcessInfo {
        lock.lock()
        defer { lock.unlock() }

        // Check if already running
        guard state != .running && state != .starting else {
            throw CLIProcessError.processAlreadyRunning
        }

        // Clean up any existing process
        if process != nil {
            terminateProcessInternal(force: true)
        }

        state = .starting

        // Create new process
        let newProcess = Process()
        newProcess.executableURL = URL(fileURLWithPath: path)

        // Set arguments (no default arguments - caller specifies what's needed)
        newProcess.arguments = arguments

        // Set environment
        var env = ProcessInfo.processInfo.environment
        if let customEnv = environment {
            env.merge(customEnv) { (_, new) in new }
        }
        newProcess.environment = env

        // Set up pipes
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        newProcess.standardInput = inputPipe
        newProcess.standardOutput = outputPipe
        newProcess.standardError = errorPipe

        // Set up termination handler
        newProcess.terminationHandler = { [weak self] terminatedProcess in
            Task { @MainActor in
                self?.handleProcessTermination(terminatedProcess)
            }
        }

        // Store references
        self.process = newProcess
        self.standardInput = inputPipe.fileHandleForWriting
        self.standardOutput = outputPipe.fileHandleForReading
        self.standardError = errorPipe.fileHandleForReading

        // Create process info
        let info = CLIProcessInfo(
            processIdentifier: newProcess.processIdentifier,
            path: path,
            arguments: arguments
        )
        self.processInfo = info

        do {
            try newProcess.run()
            state = .running
            processInfo?.state = .running

            // Start monitoring output
            startMonitoring()

            return info
        } catch {
            state = .error
            cleanup()
            throw CLIProcessError.failedToStart(error.localizedDescription)
        }
    }

    /// Terminate the CLI process gracefully
    public func terminate() async throws {
        try await terminateProcess(force: false)
    }

    /// Force kill the CLI process
    public func forceKill() async throws {
        try await terminateProcess(force: true)
    }

    /// Check if process is running
    public var isRunning: Bool {
        return process?.isRunning ?? false
    }

    /// Get current process ID
    public var processIdentifier: Int32? {
        return process?.processIdentifier
    }

    // MARK: - Private Methods

    private func terminateProcess(force: Bool) async throws {
        lock.lock()

        guard let currentProcess = process, currentProcess.isRunning else {
            lock.unlock()
            throw CLIProcessError.processNotRunning
        }

        state = .terminating

        do {
            if force {
                currentProcess.terminate()
            } else {
                currentProcess.interrupt()
            }

            // Wait for termination with timeout
            let deadline = Date().addingTimeInterval(5.0)
            while currentProcess.isRunning && Date() < deadline {
                lock.unlock()
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                lock.lock()
            }

            if currentProcess.isRunning {
                // Force kill if still running
                currentProcess.terminate()
            }

            cleanup()
            state = .terminated
            lock.unlock()
        } catch {
            lock.unlock()
            throw CLIProcessError.failedToTerminate(error.localizedDescription)
        }
    }

    private func terminateProcessInternal(force: Bool) {
        guard let currentProcess = process else { return }

        if currentProcess.isRunning {
            if force {
                currentProcess.terminate()
            } else {
                currentProcess.interrupt()
            }
        }

        cleanup()
    }

    private func handleProcessTermination(_ terminatedProcess: Process) {
        lock.lock()
        defer { lock.unlock() }

        let exitCode = terminatedProcess.terminationStatus
        let reason = terminatedProcess.terminationReason

        processInfo?.terminationReason = reason

        if state == .terminating {
            state = .terminated
        } else if exitCode != 0 {
            state = .crashed
            let error = CLIProcessError.unexpectedTermination(exitCode)
            errorSubject.send(error)
            delegate?.processManager(self, didReceiveError: error)
        } else {
            state = .terminated
        }

        stopMonitoring()
        cleanup()
    }

    private func cleanup() {
        standardInput?.closeFile()
        standardOutput?.closeFile()
        standardError?.closeFile()

        standardInput = nil
        standardOutput = nil
        standardError = nil
        process = nil
        processInfo?.state = state
    }

    private func notifyStateChange(_ newState: CLIProcessState) {
        stateSubject.send(newState)
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.delegate?.processManager(self, didChangeState: newState)
        }
    }

    // MARK: - Output Monitoring

    private var outputMonitorTask: Task<Void, Never>?
    private var errorMonitorTask: Task<Void, Never>?

    private func startMonitoring() {
        // Monitor stdout
        outputMonitorTask = Task { [weak self] in
            guard let outputHandle = self?.standardOutput else { return }

            outputHandle.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty {
                    self?.outputSubject.send(data)
                    self?.delegate?.processManager(self!, didOutputData: data)
                }
            }
        }

        // Monitor stderr
        errorMonitorTask = Task { [weak self] in
            guard let errorHandle = self?.standardError else { return }

            errorHandle.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty {
                    // Log stderr but don't forward as output
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("[CLI stderr] \(errorString)")
                    }
                }
            }
        }
    }

    private func stopMonitoring() {
        outputMonitorTask?.cancel()
        errorMonitorTask?.cancel()

        standardOutput?.readabilityHandler = nil
        standardError?.readabilityHandler = nil

        outputMonitorTask = nil
        errorMonitorTask = nil
    }

    // MARK: - Zombie Process Cleanup

    /// Check for and clean up zombie processes
    public func cleanupZombieProcesses() async {
        // Use shell to find and kill zombie processes
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", """
            ps aux | grep -E 'claude.*defunct|claude.*<defunct>' | awk '{print $2}' | xargs -r kill -9 2>/dev/null || true
            """]

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            // Ignore errors during cleanup
        }
    }
}

// MARK: - Combine Publishers

extension CLIProcessManager {

    /// Publisher for state changes
    public var statePublisher: AnyPublisher<CLIProcessState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    /// Publisher for errors
    public var errorPublisher: AnyPublisher<CLIProcessError, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    /// Publisher for output data
    public var outputPublisher: AnyPublisher<Data, Never> {
        outputSubject.eraseToAnyPublisher()
    }
}
