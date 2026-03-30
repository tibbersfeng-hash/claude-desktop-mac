// MessageSerializer.swift
// Claude Desktop Mac - Message Serializer Module
//
// Handles serialization and deserialization of CLI messages

import Foundation

// MARK: - Serialization Error

/// Errors during message serialization/deserialization
public enum SerializationError: Error, Sendable, LocalizedError {
    case encodingFailed(String)
    case decodingFailed(String)
    case invalidJSON(String)
    case invalidFormat(String)
    case missingField(String)
    case unknownEventType(String)

    public var errorDescription: String? {
        switch self {
        case .encodingFailed(let reason):
            return "Encoding failed: \(reason)"
        case .decodingFailed(let reason):
            return "Decoding failed: \(reason)"
        case .invalidJSON(let reason):
            return "Invalid JSON: \(reason)"
        case .invalidFormat(let reason):
            return "Invalid format: \(reason)"
        case .missingField(let field):
            return "Missing required field: \(field)"
        case .unknownEventType(let type):
            return "Unknown event type: \(type)"
        }
    }
}

// MARK: - Message Serializer

/// Serializes and deserializes messages for CLI communication
public final class MessageSerializer: Sendable {

    // MARK: - Properties

    /// JSON decoder with custom configuration
    private let decoder: JSONDecoder

    // MARK: - Singleton

    public static let shared = MessageSerializer()

    // MARK: - Initialization

    public init() {
        decoder = JSONDecoder()
    }

    // MARK: - Input Serialization

    /// Encode a text message for sending to CLI (stdin)
    /// The CLI accepts plain text input with newline delimiter
    public func encodeInput(_ text: String) -> Data {
        // Add newline if not present
        let normalizedText = text.hasSuffix("\n") ? text : text + "\n"
        return Data(normalizedText.utf8)
    }

    /// Encode a text message for sending to CLI with resume session
    public func encodeInput(_ text: String, resumeSessionId sessionId: String?) -> (data: Data, args: [String]) {
        var args: [String] = []

        if let sessionId = sessionId {
            args = ["--resume", sessionId]
        }

        return (encodeInput(text), args)
    }

    // MARK: - Output Deserialization

    /// Parse a single line of JSON output from CLI
    public func parseLine(_ line: String) -> ParsedEvent? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        guard let data = trimmed.data(using: .utf8) else {
            return nil
        }

        return try? parseEvent(data)
    }

    /// Parse event data from CLI
    public func parseEvent(_ data: Data) throws -> ParsedEvent {
        // First, try to determine the event type
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let typeString = json["type"] as? String,
              let eventType = CLIEventType(rawValue: typeString) else {
            throw SerializationError.missingField("type")
        }

        switch eventType {
        case .system:
            return try parseSystemEvent(data, json: json)
        case .assistant:
            return try parseAssistantEvent(data)
        case .result:
            return try parseResultEvent(data)
        case .user:
            // User events are typically not sent by CLI, but handle gracefully
            return .unknown(data)
        }
    }

    /// Parse system event
    private func parseSystemEvent(_ data: Data, json: [String: Any]) throws -> ParsedEvent {
        guard let subtypeString = json["subtype"] as? String else {
            throw SerializationError.missingField("subtype")
        }

        switch subtypeString {
        case "init":
            let event = try decoder.decode(SystemInitEvent.self, from: data)
            return .systemInit(event)
        case "hook_started", "hook_ended":
            let event = try decoder.decode(SystemHookEvent.self, from: data)
            return .systemHook(event)
        default:
            return .unknown(data)
        }
    }

    /// Parse assistant event
    private func parseAssistantEvent(_ data: Data) throws -> ParsedEvent {
        let event = try decoder.decode(AssistantEvent.self, from: data)
        return .assistant(event)
    }

    /// Parse result event
    private func parseResultEvent(_ data: Data) throws -> ParsedEvent {
        let event = try decoder.decode(ResultEvent.self, from: data)
        return .result(event)
    }

    // MARK: - Stream Parsing

    /// Parse multiple lines of JSON output
    public func parseLines(_ text: String) -> [ParsedEvent] {
        var events: [ParsedEvent] = []

        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            if let event = parseLine(String(line)) {
                events.append(event)
            }
        }

        return events
    }
}

// MARK: - Stream Parser State

/// Stateful parser for streaming CLI output
public final class StreamParser: @unchecked Sendable {
    private var buffer: String = ""
    private let lock = NSLock()

    /// Initialize a new stream parser
    public init() {}

    /// Append data to the buffer and extract complete events
    public func append(_ data: Data) -> [ParsedEvent] {
        guard let text = String(data: data, encoding: .utf8) else {
            return []
        }
        return append(text)
    }

    /// Append text to the buffer and extract complete events
    public func append(_ text: String) -> [ParsedEvent] {
        lock.lock()
        defer { lock.unlock() }

        buffer += text
        var events: [ParsedEvent] = []

        // Process complete lines
        while let newlineIndex = buffer.firstIndex(of: "\n") {
            let line = String(buffer[buffer.startIndex..<newlineIndex])
            buffer = String(buffer[buffer.index(after: newlineIndex)...])

            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            if let event = MessageSerializer.shared.parseLine(trimmed) {
                events.append(event)
            }
        }

        return events
    }

    /// Get any remaining data in the buffer
    public func remainingBuffer() -> String {
        lock.lock()
        defer { lock.unlock() }
        return buffer
    }

    /// Clear the buffer
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        buffer = ""
    }
}

// MARK: - Event Filter

/// Filter and process parsed events
public struct EventFilter: Sendable {

    /// Extract text content from events
    public static func extractText(from events: [ParsedEvent]) -> String {
        var texts: [String] = []

        for event in events {
            switch event {
            case .assistant(let assistantEvent):
                texts.append(assistantEvent.textContent)
            case .result(let resultEvent):
                if let result = resultEvent.result {
                    texts.append(result)
                }
            default:
                break
            }
        }

        return texts.joined()
    }

    /// Extract session ID from events
    public static func extractSessionId(from events: [ParsedEvent]) -> String? {
        for event in events {
            if let sessionId = event.sessionId {
                return sessionId
            }
        }
        return nil
    }

    /// Check if any event indicates an error
    public static func hasError(in events: [ParsedEvent]) -> (hasError: Bool, message: String?) {
        for event in events {
            switch event {
            case .result(let resultEvent):
                if resultEvent.isError {
                    return (true, resultEvent.result)
                }
            default:
                break
            }
        }
        return (false, nil)
    }

    /// Check if any event indicates completion
    public static func isComplete(in events: [ParsedEvent]) -> Bool {
        for event in events {
            if case .result(_) = event {
                return true
            }
        }
        return false
    }
}

// MARK: - Message Builder

/// Helper for building CLI input messages
public struct MessageBuilder: Sendable {

    /// Create a simple text input
    public static func text(_ content: String) -> String {
        return content
    }

    /// Create a text input with command
    public static func text(_ content: String, command: String) -> String {
        return "\(command): \(content)"
    }
}
