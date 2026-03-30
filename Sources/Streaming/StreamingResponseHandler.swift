// StreamingResponseHandler.swift
// Claude Desktop Mac - Streaming Response Handler Module
//
// Handles streaming responses from CLI with incremental updates

import Foundation
import Combine

// MARK: - Streaming State

/// State of a streaming response
public enum StreamingState: Sendable {
    case idle
    case streaming
    case completed
    case error(StreamingError)
    case cancelled
}

// MARK: - Streaming Error

/// Errors during streaming
public enum StreamingError: Error, Sendable, LocalizedError {
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

    public init(messageId: String? = nil) {
        self.messageId = messageId
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

    /// SSE parser
    private let sseParser: SSEParser

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
        self.sseParser = SSEParser()
    }

    // MARK: - Public Methods

    /// Start a new streaming response
    public func start(messageId: String? = nil) {
        lock.lock()
        defer { lock.unlock() }

        currentResponse = StreamingResponse(messageId: messageId)
        state = .streaming
        stateSubject.send(.streaming)

        // Start timeout timer
        startTimeoutTimer()
    }

    /// Process incoming data
    public func processData(_ data: Data) -> [IncomingMessage] {
        // First try SSE format
        let sseEvents = sseParser.parse(data)

        if !sseEvents.isEmpty {
            return processSSEEvents(sseEvents)
        }

        // Try JSON format
        do {
            let messages = try serializer.decodeMultiple(data)
            return processMessages(messages)
        } catch {
            // Handle error
            handleError(.parseError(error.localizedDescription))
            return []
        }
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
        sseParser.reset()
        stateSubject.send(.idle)
    }

    // MARK: - Private Methods

    private func processSSEEvents(_ events: [SSEEvent]) -> [IncomingMessage] {
        var messages: [IncomingMessage] = []

        for event in events {
            do {
                let message = try serializer.decodeFromString(event.data)
                messages.append(message)
                processMessage(message)
            } catch {
                // Try to create a text message from the data
                let message = IncomingMessage(
                    type: .text,
                    content: event.data,
                    isComplete: false
                )
                messages.append(message)
                processMessage(message)
            }
        }

        return messages
    }

    private func processMessages(_ messages: [IncomingMessage]) -> [IncomingMessage] {
        for message in messages {
            processMessage(message)
        }
        return messages
    }

    private func processMessage(_ message: IncomingMessage) {
        lock.lock()
        defer { lock.unlock() }

        guard var response = currentResponse else { return }

        switch message.type {
        case .text:
            if let content = message.content {
                response.setContent(content)
            }

        case .delta:
            if let delta = message.delta {
                response.appendDelta(delta)
                deltaSubject.send(delta)
            }

        case .toolCall:
            if let toolCall = message.toolCall {
                response.addToolCall(toolCall)
            }

        case .toolResult:
            // Handle tool result if needed
            break

        case .error:
            if let error = message.error {
                response.addError(error)
            }

        case .done:
            response.complete()
            cancelTimeoutTimer()
            state = .completed
            stateSubject.send(.completed)

        case .pong:
            // Health check response, ignore
            break

        case .system:
            // System message, could log or handle specially
            break
        }

        if message.isComplete {
            response.complete()
            cancelTimeoutTimer()
            state = .completed
            stateSubject.send(.completed)
        }

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
