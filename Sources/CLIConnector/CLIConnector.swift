// CLIConnector.swift
// Claude Desktop Mac - CLI Connector Module
//
// Main entry point for CLI connection layer

import Foundation
import Combine
import CLIDetector
import CLIManager
import Communication
import Streaming
import Protocol
import State
import ErrorHandling

// MARK: - CLI Connector

/// Main connector class that orchestrates all CLI connection components
public final class CLIConnector: ObservableObject, @unchecked Sendable {

    // MARK: - Published Properties

    /// Current connection state
    @Published public private(set) var connectionState: ConnectionState = .idle

    /// CLI detection result
    @Published public private(set) var detectionResult: CLIDetectionResult?

    /// Current streaming response
    @Published public private(set) var currentResponse: StreamingResponse?

    /// Last error encountered
    @Published public private(set) var lastError: ErrorInfo?

    // MARK: - Components

    /// CLI detector
    public let detector: CLIDetector

    /// Process manager
    public let processManager: CLIProcessManager

    /// Communication pipeline
    public let pipeline: CommunicationPipeline

    /// Response handler
    public let responseHandler: StreamingResponseHandler

    /// Connection manager
    public let connectionManager: ConnectionManager

    /// Error handler
    public let errorHandler: ErrorHandler

    /// Recovery manager
    public let recoveryManager: RecoveryManager

    /// Message queue
    public let messageQueue: MessageQueue

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Singleton

    public static let shared = CLIConnector()

    // MARK: - Initialization

    public init(
        detector: CLIDetector = .shared,
        processManager: CLIProcessManager = CLIProcessManager(),
        pipeline: CommunicationPipeline = CommunicationPipeline(),
        responseHandler: StreamingResponseHandler = StreamingResponseHandler(),
        messageQueue: MessageQueue = MessageQueue(),
        errorHandler: ErrorHandler = .shared
    ) {
        self.detector = detector
        self.processManager = processManager
        self.pipeline = pipeline
        self.responseHandler = responseHandler
        self.messageQueue = messageQueue
        self.errorHandler = errorHandler

        self.connectionManager = ConnectionManager(
            detector: detector,
            processManager: processManager,
            pipeline: pipeline,
            responseHandler: responseHandler,
            messageQueue: messageQueue
        )

        self.recoveryManager = RecoveryManager(
            connectionManager: connectionManager,
            errorHandler: errorHandler
        )

        setupBindings()
    }

    // MARK: - Public Methods

    /// Detect CLI installation
    public func detectCLI() async -> CLIDetectionResult {
        let result = await detector.detect()
        await MainActor.run {
            self.detectionResult = result
        }
        return result
    }

    /// Connect to CLI
    public func connect() async throws {
        try await connectionManager.connect()
    }

    /// Disconnect from CLI
    public func disconnect() async {
        await connectionManager.disconnect()
    }

    /// Send a text message
    public func send(_ text: String) async throws {
        try await connectionManager.sendText(text)
    }

    /// Interrupt current operation
    public func interrupt() async throws {
        try await connectionManager.interrupt()
    }

    /// Queue a message for sending
    public func queueMessage(_ message: OutgoingMessage, highPriority: Bool = false) -> UUID {
        return messageQueue.enqueue(message, highPriority: highPriority)
    }

    /// Get error history
    public func getErrorHistory() -> [ErrorInfo] {
        return errorHandler.getErrorHistory()
    }

    /// Clear error history
    public func clearErrorHistory() {
        errorHandler.clearHistory()
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Bind connection state
        connectionManager.statePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$connectionState)

        // Bind response updates
        connectionManager.responsePublisher
            .receive(on: DispatchQueue.main)
            .map { Optional($0) }
            .assign(to: &$currentResponse)

        // Bind errors
        errorHandler.errorPublisher
            .receive(on: DispatchQueue.main)
            .map { Optional($0) }
            .assign(to: &$lastError)
    }
}

// MARK: - Convenience Methods

extension CLIConnector {

    /// Quick connect - detect and connect in one call
    public func quickConnect() async throws {
        let result = await detectCLI()

        guard result.isInstalled else {
            throw ConnectionError.cliNotFound
        }

        guard result.environmentStatus == .ready else {
            if result.environmentStatus == .missingApiKey {
                throw ConnectionError.authenticationFailed
            }
            throw ConnectionError.connectionFailed("Environment not ready")
        }

        try await connect()
    }

    /// Check if ready to send messages
    public var isReady: Bool {
        return connectionState == .connected
    }

    /// Get CLI version string
    public var cliVersionString: String? {
        return detectionResult?.version
    }

    /// Get CLI path
    public var cliPath: String? {
        return detectionResult?.path
    }
}
