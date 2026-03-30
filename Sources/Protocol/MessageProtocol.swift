// MessageProtocol.swift
// Claude Desktop Mac - Message Protocol Module
//
// Defines message types and protocol for CLI communication

import Foundation

// MARK: - CLI Event Types (Incoming)

/// Types of events received from the CLI stream
public enum CLIEventType: String, Codable, Sendable {
    case system = "system"
    case assistant = "assistant"
    case result = "result"
    case user = "user"
}

// MARK: - System Event Subtype

/// Subtypes for system events
public enum SystemSubtype: String, Codable, Sendable {
    case initialized = "init"
    case hookStarted = "hook_started"
    case hookEnded = "hook_ended"
}

// MARK: - Result Subtype

/// Subtypes for result events
public enum ResultSubtype: String, Codable, Sendable {
    case success = "success"
    case error = "error"
    case canceled = "canceled"
}

// MARK: - CLI Event (Base)

/// Base protocol for CLI events
public protocol CLIEvent: Codable, Sendable {
    var type: CLIEventType { get }
}

// MARK: - System Init Event

/// System initialization event
public struct SystemInitEvent: CLIEvent, Codable, Sendable {
    public let type: CLIEventType
    public let subtype: SystemSubtype
    public let cwd: String?
    public let sessionId: String?
    public let tools: [ToolInfo]?
    public let model: String?
    public let permissionMode: String?

    private enum CodingKeys: String, CodingKey {
        case type, subtype, cwd
        case sessionId = "session_id"
        case tools, model, permissionMode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(CLIEventType.self, forKey: .type)
        subtype = try container.decode(SystemSubtype.self, forKey: .subtype)
        cwd = try container.decodeIfPresent(String.self, forKey: .cwd)
        sessionId = try container.decodeIfPresent(String.self, forKey: .sessionId)
        tools = try container.decodeIfPresent([ToolInfo].self, forKey: .tools)
        model = try container.decodeIfPresent(String.self, forKey: .model)
        permissionMode = try container.decodeIfPresent(String.self, forKey: .permissionMode)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(subtype, forKey: .subtype)
        try container.encodeIfPresent(cwd, forKey: .cwd)
        try container.encodeIfPresent(sessionId, forKey: .sessionId)
        try container.encodeIfPresent(tools, forKey: .tools)
        try container.encodeIfPresent(model, forKey: .model)
        try container.encodeIfPresent(permissionMode, forKey: .permissionMode)
    }
}

// MARK: - Tool Info

/// Information about a tool
public struct ToolInfo: Codable, Sendable {
    public let name: String?
    public let description: String?

    public init(name: String? = nil, description: String? = nil) {
        self.name = name
        self.description = description
    }
}

// MARK: - System Hook Event

/// System hook event
public struct SystemHookEvent: CLIEvent, Codable, Sendable {
    public let type: CLIEventType
    public let subtype: SystemSubtype
    public let hookId: String?
    public let hookName: String?

    private enum CodingKeys: String, CodingKey {
        case type, subtype
        case hookId = "hook_id"
        case hookName = "hook_name"
    }
}

// MARK: - Assistant Event

/// Assistant response event
public struct AssistantEvent: CLIEvent, Codable, Sendable {
    public let type: CLIEventType
    public let message: AssistantMessage
    public let sessionId: String?

    private enum CodingKeys: String, CodingKey {
        case type, message
        case sessionId = "session_id"
    }

    /// Extract text content from the message
    public var textContent: String {
        message.content.compactMap { block in
            if case .text(let text) = block { return text }
            return nil
        }.joined()
    }
}

// MARK: - Assistant Message

/// Message from the assistant
public struct AssistantMessage: Codable, Sendable {
    public let id: String?
    public let type: String?
    public let role: String?
    public let content: [ContentBlock]
    public let model: String?
}

// MARK: - Content Block

/// Content block in a message
public enum ContentBlock: Codable, Sendable {
    case text(String)
    case toolUse(ToolUseBlock)
    case toolResult(ToolResultBlock)
    case unknown

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        let type = (try? container.decodeIfPresent(String.self, forKey: AnyCodingKey(stringValue: "type")!)) ?? ""

        switch type {
        case "text":
            if let text = try? container.decode(String.self, forKey: AnyCodingKey(stringValue: "text")!) {
                self = .text(text)
            } else {
                self = .text("")
            }
        case "tool_use":
            let block = try ToolUseBlock(from: decoder)
            self = .toolUse(block)
        case "tool_result":
            let block = try ToolResultBlock(from: decoder)
            self = .toolResult(block)
        default:
            self = .unknown
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)

        switch self {
        case .text(let text):
            try container.encode("text", forKey: AnyCodingKey(stringValue: "type")!)
            try container.encode(text, forKey: AnyCodingKey(stringValue: "text")!)
        case .toolUse(let block):
            try container.encode("tool_use", forKey: AnyCodingKey(stringValue: "type")!)
            try block.encode(to: encoder)
        case .toolResult(let block):
            try container.encode("tool_result", forKey: AnyCodingKey(stringValue: "type")!)
            try block.encode(to: encoder)
        case .unknown:
            try container.encode("unknown", forKey: AnyCodingKey(stringValue: "type")!)
        }
    }
}

// MARK: - Any Coding Key

/// Flexible coding key for dynamic JSON parsing
public struct AnyCodingKey: CodingKey, Hashable {
    public var intValue: Int?
    public var stringValue: String

    public init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }

    public init?(stringValue: String) {
        self.stringValue = stringValue
    }
}

// MARK: - Tool Use Block

/// Tool use block in content
public struct ToolUseBlock: Codable, Sendable {
    public let id: String?
    public let name: String?
    public let input: [String: JSONValue]?

    private enum CodingKeys: String, CodingKey {
        case id, name, input
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        input = try container.decodeIfPresent([String: JSONValue].self, forKey: .input)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(input, forKey: .input)
    }
}

// MARK: - Tool Result Block

/// Tool result block in content
public struct ToolResultBlock: Codable, Sendable {
    public let toolUseId: String?
    public let content: String?
    public let isError: Bool?

    private enum CodingKeys: String, CodingKey {
        case content, isError
        case toolUseId = "tool_use_id"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        toolUseId = try container.decodeIfPresent(String.self, forKey: .toolUseId)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        isError = try container.decodeIfPresent(Bool.self, forKey: .isError)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(toolUseId, forKey: .toolUseId)
        try container.encodeIfPresent(content, forKey: .content)
        try container.encodeIfPresent(isError, forKey: .isError)
    }
}

// MARK: - Result Event

/// Final result event
public struct ResultEvent: CLIEvent, Codable, Sendable {
    public let type: CLIEventType
    public let subtype: ResultSubtype
    public let isError: Bool
    public let durationMs: Int?
    public let result: String?
    public let stopReason: String?
    public let sessionId: String?

    private enum CodingKeys: String, CodingKey {
        case type, subtype
        case isError = "is_error"
        case durationMs = "duration_ms"
        case result
        case stopReason = "stop_reason"
        case sessionId = "session_id"
    }

    /// Check if this is a successful result
    public var isSuccess: Bool {
        subtype == .success && !isError
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

// MARK: - Parsed Event

/// A parsed event from the CLI stream
public enum ParsedEvent: Sendable {
    case systemInit(SystemInitEvent)
    case systemHook(SystemHookEvent)
    case assistant(AssistantEvent)
    case result(ResultEvent)
    case unknown(Data)

    /// Get the session ID if available
    public var sessionId: String? {
        switch self {
        case .systemInit(let event):
            return event.sessionId
        case .assistant(let event):
            return event.sessionId
        case .result(let event):
            return event.sessionId
        default:
            return nil
        }
    }
}

// MARK: - Outgoing Message (for sending to CLI)

/// Message to send to the CLI (plain text)
public struct OutgoingMessage: Codable, Sendable {
    public let content: String
    public let sessionId: String?

    public init(content: String, sessionId: String? = nil) {
        self.content = content
        self.sessionId = sessionId
    }

    /// Create a text message
    public static func text(_ content: String, sessionId: String? = nil) -> OutgoingMessage {
        OutgoingMessage(content: content, sessionId: sessionId)
    }

    /// Create an interrupt message
    public static func interrupt(sessionId: String? = nil) -> OutgoingMessage {
        OutgoingMessage(content: "", sessionId: sessionId)
    }

    /// Create a ping message
    public static func ping() -> OutgoingMessage {
        OutgoingMessage(content: "")
    }
}

// MARK: - Legacy Types (for compatibility)

/// Message type (kept for compatibility)
public enum OutgoingMessageType: String, Codable, Sendable {
    case text = "text"
    case command = "command"
    case interrupt = "interrupt"
    case ping = "ping"
}

/// Incoming message type (kept for compatibility)
public enum IncomingMessageType: String, Codable, Sendable {
    case text = "text"
    case delta = "delta"
    case toolCall = "tool_call"
    case toolResult = "tool_result"
    case error = "error"
    case done = "done"
    case pong = "pong"
    case system = "system"
}

/// Incoming message (kept for compatibility)
public struct IncomingMessage: Codable, Sendable {
    public let type: IncomingMessageType
    public let content: String?
    public let delta: String?
    public let isComplete: Bool

    public init(
        type: IncomingMessageType,
        content: String? = nil,
        delta: String? = nil,
        isComplete: Bool = false
    ) {
        self.type = type
        self.content = content
        self.delta = delta
        self.isComplete = isComplete
    }
}

/// Tool call (kept for compatibility)
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

/// Tool call status
public enum ToolCallStatus: String, Codable, Sendable {
    case pending
    case running
    case completed
    case failed
}

/// Tool result (kept for compatibility)
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

/// Message error (kept for compatibility)
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
