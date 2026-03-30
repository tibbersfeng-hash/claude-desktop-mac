// CLIExecutionService.swift
// Claude Desktop Mac - CLI Execution Service
//
// Handles execution of CLI for single message exchanges

import Foundation
import Combine
import CLIDetector
import Protocol
import Streaming
import ErrorHandling

// MARK: - Execution Error

/// Errors during CLI execution
public enum ExecutionError: Error, Sendable, LocalizedError {
    case cliNotFound
    case processStartFailed(String)
    case encodingFailed
    case executionFailed(String)
    case timeout
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .cliNotFound:
            return "Claude Code CLI not found."
        case .processStartFailed(let reason):
            return "Failed to start CLI process: \(reason)"
        case .encodingFailed:
            return "Failed to encode message."
        case .executionFailed(let reason):
            return "CLI execution failed: \(reason)"
        case .timeout:
            return "CLI execution timed out."
        case .cancelled:
            return "Execution was cancelled."
        }
    }
}

// MARK: - Execution Result

/// Result of a CLI execution
public struct ExecutionResult: Sendable {
    public let sessionId: String?
    public let content: String
    public let duration: TimeInterval
    public let isError: Bool

    public init(sessionId: String? = nil, content: String, duration: TimeInterval, isError: Bool = false) {
        self.sessionId = sessionId
        self.content = content
        self.duration = duration
        self.isError = isError
    }
}

// MARK: - CLI Execution Service

/// Service for executing CLI commands and handling responses
public final class CLIExecutionService: @unchecked Sendable {

    // MARK: - Properties

    /// CLI detector
    private let detector: CLIDetector

    /// Current running process
    private var currentProcess: Process?

    /// Response handler for streaming
    private let responseHandler: StreamingResponseHandler

    /// Lock for thread safety
    private let lock = NSLock()

    /// Timeout for execution
    public var executionTimeout: TimeInterval = 300.0 // 5 minutes

    /// Current session ID for conversation continuity
    public private(set) var currentSessionId: String?

    // MARK: - Publishers

    /// Publisher for streaming deltas
    private let deltaSubject = PassthroughSubject<String, Never>()

    /// Publisher for state changes
    private let stateSubject = CurrentValueSubject<ExecutionState, Never>(.idle)

    // MARK: - Initialization

    public init(detector: CLIDetector = .shared) {
        self.detector = detector
        self.responseHandler = StreamingResponseHandler()
    }

    // MARK: - Public Methods

    /// Execute a message with the CLI
    /// - Parameters:
    ///   - message: The message to send
    ///   - workingDirectory: Optional working directory for the CLI
    /// - Returns: The execution result
    public func execute(message: String, workingDirectory: String? = nil) async throws -> ExecutionResult {
        // Check for cancellation
        try Task.checkCancellation()

        // Detect CLI
        let detection = await detector.detect()
        guard detection.isInstalled, let cliPath = detection.path else {
            throw ExecutionError.cliNotFound
        }

        // Lock and setup
        lock.lock()
        defer { lock.unlock() }

        // Cancel any existing process
        cancelCurrentProcess()

        // Update state
        stateSubject.send(.executing)

        // Build arguments
        var arguments = [
            "--output-format", "stream-json",
            "--verbose",
            "-p", message
        ]

        // Add session resume if we have a session ID
        if let sessionId = currentSessionId {
            arguments.insert(contentsOf: ["--resume", sessionId], at: 0)
        }

        // Create process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliPath)
        process.arguments = arguments

        // Set working directory
        if let workingDir = workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: workingDir)
        }

        // Setup pipes
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        // Store process
        currentProcess = process

        // Start response handler
        responseHandler.start()

        // Start reading stdout before launching
        var accumulatedOutput: Data = Data()
        let outputLock = NSLock()

        stdoutPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty {
                outputLock.lock()
                accumulatedOutput.append(data)
                outputLock.unlock()

                // Process through response handler
                let events = self?.responseHandler.processData(data) ?? []
                self?.handleEvents(events)
            }
        }

        // Track errors
        var stderrOutput: String = ""
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let str = String(data: data, encoding: .utf8), !str.isEmpty {
                stderrOutput += str
            }
        }

        // Start timing
        let startTime = Date()

        do {
            // Launch process
            try process.run()

            // Wait for completion with timeout
            let deadline = startTime.addingTimeInterval(executionTimeout)

            while process.isRunning && Date() < deadline {
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                try Task.checkCancellation()
            }

            // Check for timeout
            if process.isRunning {
                process.terminate()
                throw ExecutionError.timeout
            }

            // Check exit status
            if process.terminationStatus != 0 && !stderrOutput.isEmpty {
                throw ExecutionError.executionFailed(stderrOutput)
            }

        } catch let error as ExecutionError {
            cleanup()
            stateSubject.send(.error(error.localizedDescription))
            throw error
        } catch {
            cleanup()
            let execError = ExecutionError.processStartFailed(error.localizedDescription)
            stateSubject.send(.error(execError.localizedDescription))
            throw execError
        }

        // Get final result
        let response = responseHandler.currentResponse
        let duration = Date().timeIntervalSince(startTime)

        // Extract session ID from response
        if let sessionId = response?.sessionId {
            currentSessionId = sessionId
        }

        // Cleanup
        cleanup()

        // Update state
        stateSubject.send(.completed)

        // Build result
        let result = ExecutionResult(
            sessionId: response?.sessionId ?? currentSessionId,
            content: response?.content ?? "",
            duration: duration,
            isError: response?.errors.isEmpty == false
        )

        return result
    }

    /// Cancel current execution
    public func cancel() {
        lock.lock()
        defer { lock.unlock() }

        cancelCurrentProcess()
        responseHandler.cancel()
        stateSubject.send(.cancelled)
    }

    /// Reset session (clear session ID)
    public func resetSession() {
        lock.lock()
        defer { lock.unlock() }

        currentSessionId = nil
        responseHandler.reset()
        stateSubject.send(.idle)
    }

    // MARK: - Private Methods

    private func handleEvents(_ events: [ParsedEvent]) {
        for event in events {
            switch event {
            case .systemInit(let initEvent):
                // Store session ID
                if let sessionId = initEvent.sessionId {
                    currentSessionId = sessionId
                }

            case .assistant(let assistantEvent):
                // Extract and send delta
                let text = assistantEvent.textContent
                if !text.isEmpty {
                    deltaSubject.send(text)
                }

            case .result(let resultEvent):
                // Store session ID from result
                if let sessionId = resultEvent.sessionId {
                    currentSessionId = sessionId
                }

            default:
                break
            }
        }
    }

    private func cancelCurrentProcess() {
        if let process = currentProcess, process.isRunning {
            process.terminate()
        }
        currentProcess = nil
    }

    private func cleanup() {
        currentProcess = nil
    }
}

// MARK: - Execution State

/// State of execution
public enum ExecutionState: Sendable, Equatable {
    case idle
    case executing
    case completed
    case error(String)
    case cancelled

    public var isExecuting: Bool {
        if case .executing = self { return true }
        return false
    }
}

// MARK: - Combine Support

extension CLIExecutionService {

    /// Publisher for streaming deltas
    public var deltaPublisher: AnyPublisher<String, Never> {
        deltaSubject.eraseToAnyPublisher()
    }

    /// Publisher for state changes
    public var statePublisher: AnyPublisher<ExecutionState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
}
