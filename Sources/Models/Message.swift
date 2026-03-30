// Message.swift
// Claude Desktop Mac - Message Model
//
// Represents a message in a conversation

import Foundation
import SwiftUI

// MARK: - Message Role

/// Role of a message sender
public enum MessageRole: String, Codable, Sendable, CaseIterable {
    case user
    case assistant
    case system

    /// Display name for the role
    public var displayName: String {
        switch self {
        case .user: return "You"
        case .assistant: return "Claude"
        case .system: return "System"
        }
    }

    /// Icon name for the role
    public var iconName: String {
        switch self {
        case .user: return "person.fill"
        case .assistant: return "sparkles"
        case .system: return "gearshape.fill"
        }
    }
}

// MARK: - Message Status

/// Status of a message
public enum MessageStatus: String, Codable, Sendable {
    case pending     // Waiting to be sent
    case sending     // Currently being sent
    case streaming   // Receiving streaming response
    case completed   // Message completed
    case error       // Error occurred

    /// Whether the message is in a transient state
    public var isTransient: Bool {
        switch self {
        case .pending, .sending, .streaming:
            return true
        default:
            return false
        }
    }
}

// MARK: - Chat Message

/// Represents a message in the conversation
public struct ChatMessage: Identifiable, Codable, Sendable {
    public let id: UUID
    public let role: MessageRole
    public var content: String
    public var toolCalls: [ToolCallDisplay]?
    public var timestamp: Date
    public var status: MessageStatus
    public var isEdited: Bool

    public init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        toolCalls: [ToolCallDisplay]? = nil,
        timestamp: Date = Date(),
        status: MessageStatus = .completed,
        isEdited: Bool = false
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.toolCalls = toolCalls
        self.timestamp = timestamp
        self.status = status
        self.isEdited = isEdited
    }

    /// Create a user message
    public static func user(_ content: String) -> ChatMessage {
        ChatMessage(role: .user, content: content)
    }

    /// Create an assistant message
    public static func assistant(_ content: String, toolCalls: [ToolCallDisplay]? = nil) -> ChatMessage {
        ChatMessage(role: .assistant, content: content, toolCalls: toolCalls)
    }

    /// Create a system message
    public static func system(_ content: String) -> ChatMessage {
        ChatMessage(role: .system, content: content)
    }

    /// Create an edited version of this message
    public func withEditedContent(_ newContent: String) -> ChatMessage {
        ChatMessage(
            id: id,
            role: role,
            content: newContent,
            toolCalls: toolCalls,
            timestamp: timestamp,
            status: status,
            isEdited: true
        )
    }

    /// Formatted timestamp
    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

// MARK: - Streaming Message

/// A message that is being streamed
@Observable
public final class StreamingMessage: Sendable {
    public var content: String = ""
    public var isComplete: Bool = false
    public var toolCalls: [ToolCallDisplay] = []

    public let messageId: UUID
    public let startTime: Date

    public init(messageId: UUID = UUID()) {
        self.messageId = messageId
        self.startTime = Date()
    }

    /// Append content to the message
    public func append(_ delta: String) {
        content += delta
    }

    /// Complete the message
    public func complete() {
        isComplete = true
    }

    /// Convert to a ChatMessage
    public func toChatMessage() -> ChatMessage {
        ChatMessage(
            id: messageId,
            role: .assistant,
            content: content,
            toolCalls: toolCalls.isEmpty ? nil : toolCalls,
            timestamp: startTime,
            status: .completed
        )
    }
}

// MARK: - Input State

/// State for the message input area
@Observable
public final class MessageInputState: Sendable {
    public var text: String = ""
    public var isSending: Bool = false
    public var isStreaming: Bool = false
    public var cursorPosition: Int = 0

    public init() {}

    public var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending && !isStreaming
    }

    public func clear() {
        text = ""
        cursorPosition = 0
    }

    public func startSending() {
        isSending = true
    }

    public func finishSending() {
        isSending = false
        isStreaming = false
    }

    public func startStreaming() {
        isStreaming = true
        isSending = false
    }
}

// MARK: - Sample Data

extension ChatMessage {
    public static var samples: [ChatMessage] {
        [
            .user("Can you help me implement an API client for my Swift application?"),
            .assistant(
                """
                I'd be happy to help you implement an API client! Let me first check the existing code structure to understand your project better.

                I'll create a modern, async/await-based API client that follows Swift best practices.
                """,
                toolCalls: [.sample]
            ),
            .user("Yes, please proceed with the implementation."),
            .assistant(
                """
                Here's a robust API client implementation:

                ```swift
                import Foundation

                struct APIClient {
                    let baseURL: URL
                    let session: URLSession

                    func fetch<T: Decodable>(_ endpoint: String) async throws -> T {
                        let url = baseURL.appendingPathComponent(endpoint)
                        let (data, response) = try await session.data(from: url)

                        guard let httpResponse = response as? HTTPURLResponse else {
                            throw APIError.invalidResponse
                        }

                        guard (200...299).contains(httpResponse.statusCode) else {
                            throw APIError.httpError(httpResponse.statusCode)
                        }

                        return try JSONDecoder().decode(T.self, from: data)
                    }
                }
                ```
                """,
                toolCalls: nil
            )
        ]
    }

    public static var sample: ChatMessage {
        samples[0]
    }
}
