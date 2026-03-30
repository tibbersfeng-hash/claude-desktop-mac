// MessageProtocol.swift
// Claude Desktop Mac - Message Protocol Module
//
// Defines message types and protocol for CLI communication

import Foundation

// MARK: - Message Type (Outgoing)

/// Types of messages that can be sent to the CLI
public enum OutgoingMessageType: String, Codable, Sendable {
    case text = "text"           // Text message
    case command = "command"     // Command
    case interrupt = "interrupt" // Interrupt current operation
    case ping = "ping"           // Health check
}

// MARK: - Response Type (Incoming)

/// Types of responses from the CLI
public enum IncomingMessageType: String, Codable, Sendable {
    case text = "text"           // Text content
    case delta = "delta"         // Streaming delta
    case toolCall = "tool_call"  // Tool call
    case toolResult = "tool_result" // Tool result
    case error = "error"         // Error
    case done = "done"           // Message complete
    case pong = "pong"           // Health check response
    case system = "system"       // System message
}

// MARK: - Outgoing Message

/// Message sent to the CLI
public struct OutgoingMessage: Codable, Sendable {
    public let type: OutgoingMessageType
    public let content: String
    public let sessionId: String?
    public let metadata: [String: String]?
    public let timestamp: Date

    public init(
        type: OutgoingMessageType,
        content: String,
        sessionId: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.type = type
        self.content = content
        self.sessionId = sessionId
        self.metadata = metadata
        self.timestamp = Date()
    }

    /// Create a text message
    public static func text(_ content: String, sessionId: String? = nil) -> OutgoingMessage {
        OutgoingMessage(type: .text, content: content, sessionId: sessionId)
    }

    /// Create an interrupt message
    public static func interrupt(sessionId: String? = nil) -> OutgoingMessage {
        OutgoingMessage(type: .interrupt, content: "", sessionId: sessionId)
    }

    /// Create a ping message
    public static func ping() -> OutgoingMessage {
        OutgoingMessage(type: .ping, content: "")
    }
}

// MARK: - Incoming Message

/// Message received from the CLI
public struct IncomingMessage: Codable, Sendable {
    public let type: IncomingMessageType
    public let content: String?
    public let delta: String?
    public let toolCall: ToolCall?
    public let toolResult: ToolResult?
    public let error: MessageError?
    public let isComplete: Bool
    public let messageId: String?
    public let timestamp: Date?

    public init(
        type: IncomingMessageType,
        content: String? = nil,
        delta: String? = nil,
        toolCall: ToolCall? = nil,
        toolResult: ToolResult? = nil,
        error: MessageError? = nil,
        isComplete: Bool = false,
        messageId: String? = nil,
        timestamp: Date? = nil
    ) {
        self.type = type
        self.content = content
        self.delta = delta
        self.toolCall = toolCall
        self.toolResult = toolResult
        self.error = error
        self.isComplete = isComplete
        self.messageId = messageId
        self.timestamp = timestamp
    }
}

// MARK: - Tool Call

/// Tool call information
public struct ToolCall: Codable, Sendable {
    public let id: String
    public let name: String
    public let arguments: [String: JSONValue]?
    public let status: ToolCallStatus

    public init(id: String, name: String, arguments: [String: JSONValue]? = nil, status: ToolCallStatus = .pending) {
        self.id = id
        self.name = name
        self.arguments = arguments
        self.status = status
    }
}

/// Status of a tool call
public enum ToolCallStatus: String, Codable, Sendable {
    case pending
    case running
    case completed
    case failed
}

// MARK: - Tool Result

/// Result from a tool execution
public struct ToolResult: Codable, Sendable {
    public let toolCallId: String
    public let toolName: String
    public let output: String?
    public let error: String?
    public let success: Bool

    public init(toolCallId: String, toolName: String, output: String? = nil, error: String? = nil, success: Bool = true) {
        self.toolCallId = toolCallId
        self.toolName = toolName
        self.output = output
        self.error = error
        self.success = success
    }
}

// MARK: - Message Error

/// Error information in a message
public struct MessageError: Codable, Sendable {
    public let code: String
    public let message: String
    public let details: [String: JSONValue]?

    public init(code: String, message: String, details: [String: JSONValue]? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }
}

// MARK: - JSON Value

/// Flexible JSON value type for dynamic content
public enum JSONValue: Codable, Sendable, Equatable {
    case null
    case bool(Bool)
    case string(String)
    case number(Double)
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: JSONValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode JSONValue")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }

    // Convenience accessors
    public var stringValue: String? {
        if case .string(let s) = self { return s }
        return nil
    }

    public var boolValue: Bool? {
        if case .bool(let b) = self { return b }
        return nil
    }

    public var doubleValue: Double? {
        if case .number(let n) = self { return n }
        return nil
    }

    public var arrayValue: [JSONValue]? {
        if case .array(let a) = self { return a }
        return nil
    }

    public var objectValue: [String: JSONValue]? {
        if case .object(let o) = self { return o }
        return nil
    }
}
