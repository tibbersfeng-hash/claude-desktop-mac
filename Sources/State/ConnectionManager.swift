// ConnectionManager.swift
// Claude Desktop Mac - Connection Manager Module
//
// Manages the complete connection lifecycle with state machine

import Foundation
import Combine

// MARK: - Connection Manager

/// Central manager for CLI connection lifecycle
public final class ConnectionManager: @unchecked Sendable {

    // MARK: - Properties

    /// Current connection state
    public private(set) var state: ConnectionState = .idle {
        didSet {
            stateSubject.send(state)
            notifyStateChange(state)
        }
    }

    /// Last error encountered
    public private(set) var lastError: ConnectionError?

    /// CLI detector
    private let detector: CLIDetector

    /// Process manager
    private let processManager: CLIProcessManager

    /// Communication pipeline
    private let pipeline: CommunicationPipeline

    /// Response handler
    private let responseHandler: StreamingResponseHandler

    /// Message queue
    private let messageQueue: MessageQueue

    /// Current session ID
    public private(set) var currentSessionId: String?

    /// CLI path being used
    public private(set) var cliPath: String?

    /// CLI version
    public private(set) var cliVersion: String?

    /// Lock for thread safety
    private let lock = NSLock()

    /// State subject for Combine
    private let stateSubject = CurrentValueSubject<ConnectionState, Never>(.idle)

    /// Error subject for Combine
    private let errorSubject = PassthroughSubject<ConnectionError, Never>()

    /// Reconnection configuration
    public var maxReconnectAttempts: Int = 5
    public var reconnectBaseDelay: TimeInterval = 1.0
    public var reconnectMaxDelay: TimeInterval = 30.0

    /// Current reconnect attempt
    private var reconnectAttempt: Int = 0

    /// Reconnection task
    private var reconnectTask: Task<Void, Never>?

    // MARK: - Initialization

    public init(
        detector: CLIDetector = .shared,
        processManager: CLIProcessManager = CLIProcessManager(),
        pipeline: CommunicationPipeline = CommunicationPipeline(),
        responseHandler: StreamingResponseHandler = StreamingResponseHandler(),
        messageQueue: MessageQueue = MessageQueue()
    ) {
        self.detector = detector
        self.processManager = processManager
        self.pipeline = pipeline
        self.responseHandler = responseHandler
        self.messageQueue = messageQueue

        setupObservers()
    }

    deinit {
        cancelReconnect()
        Task {
            await disconnect()
        }
    }

    // MARK: - Public Methods

    /// Connect to the CLI
    public func connect() async throws {
        lock.lock()

        guard state.canStartAction else {
            lock.unlock()
            throw ConnectionError.connectionFailed("Cannot connect in current state: \(state.description)")
        }

        state = .detecting
        lock.unlock()

        // Step 1: Detect CLI
        let detectionResult = await detector.detect()

        guard detectionResult.isInstalled else {
            let error = ConnectionError.cliNotFound
            await handleError(error)
            throw error
        }

        cliPath = detectionResult.path
        cliVersion = detectionResult.version

        // Step 2: Start CLI process
        lock.lock()
        state = .connecting
        lock.unlock()

        do {
            let processInfo = try await processManager.start(
                path: detectionResult.path!,
                arguments: ["--stdio"]
            )

            // Step 3: Connect pipeline
            guard let input = processManager.standardInput,
                  let output = processManager.standardOutput else {
                throw ConnectionError.connectionFailed("Failed to get process pipes")
            }

            try await pipeline.connect(input: input, output: output)

            // Step 4: Mark connected
            lock.lock()
            state = .connected
            currentSessionId = UUID().uuidString
            reconnectAttempt = 0
            lock.unlock()

        } catch let error as ConnectionError {
            await handleError(error)
            throw error
        } catch {
            let connectionError = ConnectionError.connectionFailed(error.localizedDescription)
            await handleError(connectionError)
            throw connectionError
        }
    }

    /// Disconnect from the CLI
    public func disconnect() async {
        lock.lock()
        guard state.isActive else {
            lock.unlock()
            return
        }
        state = .disconnecting
        lock.unlock()

        cancelReconnect()

        // Disconnect pipeline
        pipeline.disconnect()

        // Terminate process
        do {
            try await processManager.terminate()
        } catch {
            // Force kill if graceful termination fails
            try? await processManager.forceKill()
        }

        lock.lock()
        state = .disconnected
        currentSessionId = nil
        lock.unlock()
    }

    /// Send a message to the CLI
    public func send(_ message: OutgoingMessage) async throws {
        guard state == .connected else {
            throw ConnectionError.cliNotRunning
        }

        let serializer = MessageSerializer.shared
        let data = try serializer.encodeWithNewline(message)

        try await pipeline.write(data)
    }

    /// Send a text message
    public func sendText(_ text: String) async throws {
        let message = OutgoingMessage.text(text, sessionId: currentSessionId)
        try await send(message)
    }

    /// Interrupt current operation
    public func interrupt() async throws {
        let message = OutgoingMessage.interrupt(sessionId: currentSessionId)
        try await send(message)
    }

    /// Get current streaming response
    public var currentResponse: StreamingResponse? {
        return responseHandler.currentResponse
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // Observe process state changes
        processManager.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] processState in
                self?.handleProcessStateChange(processState)
            }
            .store(in: &cancellables)

        // Observe pipeline data
        pipeline.dataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.handlePipelineData(data)
            }
            .store(in: &cancellables)

        // Observe pipeline state
        pipeline.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pipelineState in
                self?.handlePipelineStateChange(pipelineState)
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    private func handleProcessStateChange(_ processState: CLIProcessState) {
        switch processState {
        case .crashed, .terminated:
            if state == .connected {
                // Unexpected disconnection
                handleUnexpectedDisconnect()
            }
        default:
            break
        }
    }

    private func handlePipelineData(_ data: Data) {
        let messages = responseHandler.processData(data)
        // Messages are processed by responseHandler
        // Additional handling can be added here
    }

    private func handlePipelineStateChange(_ pipelineState: PipelineState) {
        switch pipelineState {
        case .error, .disconnected:
            if state == .connected {
                handleUnexpectedDisconnect()
            }
        default:
            break
        }
    }

    private func handleUnexpectedDisconnect() {
        lock.lock()
        state = .error
        lastError = .unexpectedDisconnect
        lock.unlock()

        errorSubject.send(.unexpectedDisconnect)

        // Attempt reconnection
        attemptReconnect()
    }

    private func attemptReconnect() {
        cancelReconnect()

        lock.lock()
        guard reconnectAttempt < maxReconnectAttempts else {
            state = .error
            lastError = .maxRetriesExceeded
            lock.unlock()
            errorSubject.send(.maxRetriesExceeded)
            return
        }

        state = .reconnecting
        reconnectAttempt += 1

        // Calculate delay with exponential backoff
        let delay = min(
            reconnectBaseDelay * pow(2.0, Double(reconnectAttempt - 1)),
            reconnectMaxDelay
        )
        lock.unlock()

        reconnectTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            guard let self = self, !Task.isCancelled else { return }

            do {
                try await self.connect()
            } catch {
                // Reconnect failed, will try again if under max attempts
                self.attemptReconnect()
            }
        }
    }

    private func cancelReconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil
    }

    private func handleError(_ error: ConnectionError) async {
        lock.lock()
        state = .error
        lastError = error
        lock.unlock()

        errorSubject.send(error)
    }

    private func notifyStateChange(_ newState: ConnectionState) {
        // Additional state change handling can be added here
    }
}

// MARK: - Combine Support

extension ConnectionManager {

    /// Publisher for state changes
    public var statePublisher: AnyPublisher<ConnectionState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    /// Publisher for errors
    public var errorPublisher: AnyPublisher<ConnectionError, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    /// Publisher for response updates
    public var responsePublisher: AnyPublisher<StreamingResponse, Never> {
        responseHandler.responsePublisher
    }

    /// Publisher for delta updates
    public var deltaPublisher: AnyPublisher<String, Never> {
        responseHandler.deltaPublisher
    }
}
