// MessageQueue.swift
// Claude Desktop Mac - Message Queue Module
//
// Manages message queuing for reliable delivery

import Foundation
import Combine

// MARK: - Queued Message

/// A message in the queue with metadata
public struct QueuedMessage: Sendable {
    public let id: UUID
    public let message: OutgoingMessage
    public let queuedAt: Date
    public var attemptCount: Int
    public var lastAttemptAt: Date?
    public var status: QueuedMessageStatus

    public init(message: OutgoingMessage) {
        self.id = UUID()
        self.message = message
        self.queuedAt = Date()
        self.attemptCount = 0
        self.lastAttemptAt = nil
        self.status = .pending
    }
}

// MARK: - Queued Message Status

/// Status of a queued message
public enum QueuedMessageStatus: String, Sendable, Codable {
    case pending
    case sending
    case sent
    case failed
    case cancelled
}

// MARK: - Message Queue

/// Thread-safe message queue with priority support
public final class MessageQueue: @unchecked Sendable {

    // MARK: - Properties

    /// Maximum queue size
    public var maxQueueSize: Int = 100

    /// Maximum retry attempts
    public var maxRetryAttempts: Int = 3

    /// Queue for high priority messages
    private var highPriorityQueue: [QueuedMessage] = []

    /// Queue for normal priority messages
    private var normalPriorityQueue: [QueuedMessage] = []

    /// Lock for thread safety
    private let lock = NSLock()

    /// Subject for queue changes
    private let queueSubject = PassthroughSubject<[QueuedMessage], Never>()

    /// Subject for message status changes
    private let statusSubject = PassthroughSubject<(UUID, QueuedMessageStatus), Never>()

    // MARK: - Initialization

    public init() {}

    // MARK: - Enqueue

    /// Add a message to the queue
    @discardableResult
    public func enqueue(_ message: OutgoingMessage, highPriority: Bool = false) -> UUID {
        lock.lock()
        defer { lock.unlock() }

        // Check queue size limit
        let currentSize = highPriorityQueue.count + normalPriorityQueue.count
        if currentSize >= maxQueueSize {
            // Remove oldest normal priority message
            if !normalPriorityQueue.isEmpty {
                normalPriorityQueue.removeFirst()
            }
        }

        let queuedMessage = QueuedMessage(message: message)

        if highPriority {
            highPriorityQueue.append(queuedMessage)
        } else {
            normalPriorityQueue.append(queuedMessage)
        }

        notifyQueueChange()
        return queuedMessage.id
    }

    /// Add multiple messages to the queue
    public func enqueue(_ messages: [OutgoingMessage], highPriority: Bool = false) -> [UUID] {
        return messages.map { enqueue($0, highPriority: highPriority) }
    }

    // MARK: - Dequeue

    /// Get the next message to process
    public func dequeue() -> QueuedMessage? {
        lock.lock()
        defer { lock.unlock() }

        // High priority first
        if !highPriorityQueue.isEmpty {
            var message = highPriorityQueue.removeFirst()
            message.status = .sending
            message.attemptCount += 1
            message.lastAttemptAt = Date()
            notifyQueueChange()
            notifyStatusChange(message.id, message.status)
            return message
        }

        // Then normal priority
        if !normalPriorityQueue.isEmpty {
            var message = normalPriorityQueue.removeFirst()
            message.status = .sending
            message.attemptCount += 1
            message.lastAttemptAt = Date()
            notifyQueueChange()
            notifyStatusChange(message.id, message.status)
            return message
        }

        return nil
    }

    /// Peek at the next message without removing it
    public func peek() -> QueuedMessage? {
        lock.lock()
        defer { lock.unlock() }

        if !highPriorityQueue.isEmpty {
            return highPriorityQueue.first
        }

        if !normalPriorityQueue.isEmpty {
            return normalPriorityQueue.first
        }

        return nil
    }

    // MARK: - Status Management

    /// Mark a message as sent successfully
    public func markSent(_ messageId: UUID) {
        notifyStatusChange(messageId, .sent)
    }

    /// Mark a message as failed and optionally requeue
    public func markFailed(_ messageId: UUID, retry: Bool = false) {
        lock.lock()
        defer { lock.unlock() }

        if retry {
            // Find and requeue if under retry limit
            if let index = highPriorityQueue.firstIndex(where: { $0.id == messageId }) {
                var message = highPriorityQueue[index]
                if message.attemptCount < maxRetryAttempts {
                    message.status = .pending
                    highPriorityQueue[index] = message
                    notifyStatusChange(messageId, .pending)
                    return
                }
            } else if let index = normalPriorityQueue.firstIndex(where: { $0.id == messageId }) {
                var message = normalPriorityQueue[index]
                if message.attemptCount < maxRetryAttempts {
                    message.status = .pending
                    normalPriorityQueue[index] = message
                    notifyStatusChange(messageId, .pending)
                    return
                }
            }
        }

        notifyStatusChange(messageId, .failed)
    }

    /// Cancel a message
    public func cancel(_ messageId: UUID) {
        lock.lock()
        defer { lock.unlock() }

        highPriorityQueue.removeAll { $0.id == messageId }
        normalPriorityQueue.removeAll { $0.id == messageId }

        notifyStatusChange(messageId, .cancelled)
        notifyQueueChange()
    }

    // MARK: - Queue Operations

    /// Clear all messages from the queue
    public func clear() {
        lock.lock()
        defer { lock.unlock() }

        highPriorityQueue.removeAll()
        normalPriorityQueue.removeAll()

        notifyQueueChange()
    }

    /// Get current queue size
    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return highPriorityQueue.count + normalPriorityQueue.count
    }

    /// Check if queue is empty
    public var isEmpty: Bool {
        return count == 0
    }

    /// Get all queued messages
    public func allMessages() -> [QueuedMessage] {
        lock.lock()
        defer { lock.unlock() }
        return highPriorityQueue + normalPriorityQueue
    }

    // MARK: - Notifications

    private func notifyQueueChange() {
        queueSubject.send(highPriorityQueue + normalPriorityQueue)
    }

    private func notifyStatusChange(_ id: UUID, _ status: QueuedMessageStatus) {
        statusSubject.send((id, status))
    }
}

// MARK: - Combine Support

extension MessageQueue {

    /// Publisher for queue changes
    public var queuePublisher: AnyPublisher<[QueuedMessage], Never> {
        queueSubject.eraseToAnyPublisher()
    }

    /// Publisher for status changes
    public var statusPublisher: AnyPublisher<(UUID, QueuedMessageStatus), Never> {
        statusSubject.eraseToAnyPublisher()
    }
}
