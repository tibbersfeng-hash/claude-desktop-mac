// StreamingResponseHandler.swift
// Claude Desktop Mac - Streaming Response Handler Module
//
// Handles streaming responses from CLI with incremental updates

import Foundation
import Combine
import Protocol

// MARK: - Streaming State

/// State of a streaming response
public enum StreamingState: Sendable, Equatable {
    case idle
    case streaming
    case completed
    case error(StreamingError)
    case cancelled
}

// MARK: - Streaming Error

/// Errors during streaming
public enum StreamingError: Error, Sendable, LocalizedError, Equatable {
    case timeout
    case connectionLost
    case parseError(String)
    case interrupted
    case invalidState

    public var errorDescription: String? {
        switch self {
        case .timeout:
            return "Streaming response timed out."
        case .connectionLost:
            return "Connection lost during streaming."
        case .parseError(let reason):
            return "Failed to parse response: \(reason)"
        case .interrupted:
            return "Streaming was interrupted."
        case .invalidState:
            return "Invalid streaming state."
        }
    }
}

// MARK: - Streaming Response

/// Represents an accumulated streaming response
public struct StreamingResponse: Sendable {
    public let messageId: String?
    public private(set) var content: String
    public private(set) var deltas: [String]
    public private(set) var toolCalls: [ToolCall]
    public private(set) var errors: [MessageError]
    public var isComplete: Bool
    public var startTime: Date
    public var lastUpdateTime: Date
    public var sessionId: String?

    public init(messageId: String? = nil, sessionId: String? = nil) {
        self.messageId = messageId
        self.sessionId = sessionId
        self.content = ""
        self.deltas = []
        self.toolCalls = []
        self.errors = []
        self.isComplete = false
        self.startTime = Date()
        self.lastUpdateTime = Date()
    }

    /// Append a delta to the response
    public mutating func appendDelta(_ delta: String) {
        content += delta
        deltas.append(delta)
        lastUpdateTime = Date()
    }

    /// Set complete content
    public mutating func setContent(_ newContent: String) {
        content = newContent
        lastUpdateTime = Date()
    }

    /// Add a tool call
    public mutating func addToolCall(_ toolCall: ToolCall) {
        toolCalls.append(toolCall)
        lastUpdateTime = Date()
    }

    /// Add an error
    public mutating func addError(_ error: MessageError) {
        errors.append(error)
        lastUpdateTime = Date()
    }

    /// Mark as complete
    public mutating func complete() {
        isComplete = true
        lastUpdateTime = Date()
    }

    /// Duration of the response
    public var duration: TimeInterval {
        return lastUpdateTime.timeIntervalSince(startTime)
    }
}

// MARK: - Streaming Response Handler

/// Handles streaming responses with incremental processing
public final class StreamingResponseHandler: @unchecked Sendable {

    // MARK: - Properties

    /// Timeout for streaming response
    public var streamTimeout: TimeInterval = 300.0 // 5 minutes default

    /// Current streaming state
    public private(set) var state: StreamingState = .idle

    /// Current streaming response
    public private(set) var currentResponse: StreamingResponse?

    /// Message serializer
    private let serializer: MessageSerializer

    /// Stream parser for parsing JSON lines
    private let streamParser: StreamParser

    /// Lock for thread safety
    private let lock = NSLock()

    /// State subject for Combine
    private let stateSubject = CurrentValueSubject<StreamingState, Never>(.idle)

    /// Response subject for Combine
    private let responseSubject = PassthroughSubject<StreamingResponse, Never>()

    /// Delta subject for Combine
    private let deltaSubject = PassthroughSubject<String, Never>()

    /// Error subject for Combine
    private let errorSubject = PassthroughSubject<StreamingError, Never>()

    /// Timeout task
    private var timeoutTask: Task<Void, Never>?

    // MARK: - Initialization

    public init(serializer: MessageSerializer = .shared) {
        self.serializer = serializer
        self.streamParser = StreamParser()
    }

    // MARK: - Public Methods

    /// Start a new streaming response
    public func start(messageId: String? = nil, sessionId: String? = nil) {
        lock.lock()
        defer { lock.unlock() }

        currentResponse = StreamingResponse(messageId: messageId, sessionId: sessionId)
        state = .streaming
        stateSubject.send(.streaming)

        // Start timeout timer
        startTimeoutTimer()
    }

    /// Process incoming data and return parsed events
    @discardableResult
    public func processData(_ data: Data) -> [ParsedEvent] {
        let events = streamParser.append(data)
        processEvents(events)
        return events
    }

    /// Cancel the current stream
    public func cancel() {
        lock.lock()
        defer { lock.unlock() }

        cancelTimeoutTimer()

        if state == .streaming {
            state = .cancelled
            currentResponse?.complete()
            stateSubject.send(.cancelled)

            if let response = currentResponse {
                responseSubject.send(response)
            }
        }
    }

    /// Reset the handler
    public func reset() {
        lock.lock()
        defer { lock.unlock() }

        cancelTimeoutTimer()
        currentResponse = nil
        state = .idle
        streamParser.reset()
        stateSubject.send(.idle)
    }

    // MARK: - Private Methods

    private func processEvents(_ events: [ParsedEvent]) {
        for event in events {
            processEvent(event)
        }
    }

    private func processEvent(_ event: ParsedEvent) {
        lock.lock()
        defer { lock.unlock() }

        switch event {
        case .systemInit(let initEvent):
            handleInitEvent(initEvent)

        case .systemHook(_):
            // Hook events are informational, we can ignore them for now
            break

        case .assistant(let assistantEvent):
            handleAssistantEvent(assistantEvent)

        case .result(let resultEvent):
            handleResultEvent(resultEvent)

        case .unknown(_):
            // Unknown events are ignored
            break
        }
    }

    private func handleInitEvent(_ event: SystemInitEvent) {
        // Initialize response with session ID if available
        if currentResponse == nil {
            currentResponse = StreamingResponse(sessionId: event.sessionId)
        } else if var response = currentResponse {
            response.sessionId = event.sessionId
            currentResponse = response
        }

        state = .streaming
        stateSubject.send(.streaming)
    }

    private func handleAssistantEvent(_ event: AssistantEvent) {
        guard var response = currentResponse else {
            // Create new response if none exists
            currentResponse = StreamingResponse(sessionId: event.sessionId)
            return
        }

        // Extract text content
        let text = event.textContent
        if !text.isEmpty {
            response.appendDelta(text)
            deltaSubject.send(text)
        }

        // Update session ID if available
        if let sessionId = event.sessionId {
            response.sessionId = sessionId
        }

        currentResponse = response
        responseSubject.send(response)
    }

    private func handleResultEvent(_ event: ResultEvent) {
        guard var response = currentResponse else { return }

        // Set final result content
        if let result = event.result {
            response.setContent(result)
        }

        // Update session ID if available
        if let sessionId = event.sessionId {
            response.sessionId = sessionId
        }

        // Handle errors
        if event.isError {
            let error = MessageError(
                code: "cli_error",
                message: event.result ?? "Unknown error"
            )
            response.addError(error)
            handleError(.parseError(event.result ?? "Unknown error"))
        }

        response.complete()
        cancelTimeoutTimer()
        state = .completed
        stateSubject.send(.completed)

        currentResponse = response
        responseSubject.send(response)
    }

    private func handleError(_ error: StreamingError) {
        lock.lock()
        defer { lock.unlock() }

        cancelTimeoutTimer()
        state = .error(error)
        stateSubject.send(.error(error))
        errorSubject.send(error)
    }

    private func startTimeoutTimer() {
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(self?.streamTimeout ?? 300) * 1_000_000_000)

            guard let self = self, !Task.isCancelled else { return }

            self.handleError(.timeout)
        }
    }

    private func cancelTimeoutTimer() {
        timeoutTask?.cancel()
        timeoutTask = nil
    }
}

// MARK: - Combine Support

extension StreamingResponseHandler {

    /// Publisher for state changes
    public var statePublisher: AnyPublisher<StreamingState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    /// Publisher for response updates
    public var responsePublisher: AnyPublisher<StreamingResponse, Never> {
        responseSubject.eraseToAnyPublisher()
    }

    /// Publisher for delta updates
    public var deltaPublisher: AnyPublisher<String, Never> {
        deltaSubject.eraseToAnyPublisher()
    }

    /// Publisher for errors
    public var errorPublisher: AnyPublisher<StreamingError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
}

// MARK: - Async Sequence Support

extension StreamingResponseHandler {

    /// Async stream of deltas
    public var deltaStream: AsyncStream<String> {
        AsyncStream { continuation in
            let cancellable = deltaSubject.sink { delta in
                continuation.yield(delta)
            }

            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}
