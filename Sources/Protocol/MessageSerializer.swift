// MessageSerializer.swift
// Claude Desktop Mac - Message Serializer Module
//
// Handles serialization and deserialization of messages

import Foundation

// MARK: - Serialization Error

/// Errors during message serialization/deserialization
public enum SerializationError: Error, Sendable, LocalizedError {
    case encodingFailed(String)
    case decodingFailed(String)
    case invalidJSON(String)
    case invalidFormat(String)
    case missingField(String)

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
        }
    }
}

// MARK: - Message Serializer

/// Serializes and deserializes messages for CLI communication
public final class MessageSerializer: Sendable {

    // MARK: - Properties

    /// JSON encoder with custom configuration
    private let encoder: JSONEncoder

    /// JSON decoder with custom configuration
    private let decoder: JSONDecoder

    // MARK: - Singleton

    public static let shared = MessageSerializer()

    // MARK: - Initialization

    public init() {
        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]

        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Serialization

    /// Encode an outgoing message to JSON data
    public func encode(_ message: OutgoingMessage) throws -> Data {
        do {
            return try encoder.encode(message)
        } catch {
            throw SerializationError.encodingFailed(error.localizedDescription)
        }
    }

    /// Encode an outgoing message to JSON string
    public func encodeToString(_ message: OutgoingMessage) throws -> String {
        let data = try encode(message)
        guard let string = String(data: data, encoding: .utf8) else {
            throw SerializationError.encodingFailed("Failed to convert data to string")
        }
        return string
    }

    /// Encode an outgoing message with newline delimiter
    public func encodeWithNewline(_ message: OutgoingMessage) throws -> Data {
        var data = try encode(message)
        data.append(contentsOf: [0x0A]) // newline
        return data
    }

    // MARK: - Deserialization

    /// Decode an incoming message from JSON data
    public func decode(_ data: Data) throws -> IncomingMessage {
        do {
            return try decoder.decode(IncomingMessage.self, from: data)
        } catch {
            throw SerializationError.decodingFailed(error.localizedDescription)
        }
    }

    /// Decode an incoming message from JSON string
    public func decodeFromString(_ string: String) throws -> IncomingMessage {
        guard let data = string.data(using: .utf8) else {
            throw SerializationError.invalidJSON("Failed to convert string to data")
        }
        return try decode(data)
    }

    /// Decode multiple messages from newline-delimited JSON
    public func decodeMultiple(_ data: Data) throws -> [IncomingMessage] {
        guard let string = String(data: data, encoding: .utf8) else {
            throw SerializationError.invalidJSON("Failed to convert data to string")
        }

        let lines = string.split(separator: "\n", omittingEmptySubsequences: true)
        var messages: [IncomingMessage] = []

        for line in lines {
            guard let lineData = String(line).data(using: .utf8) else { continue }
            do {
                let message = try decode(lineData)
                messages.append(message)
            } catch {
                // Skip invalid lines
                continue
            }
        }

        return messages
    }

    // MARK: - Partial Parsing

    /// Try to parse partial JSON (for streaming scenarios)
    public func parsePartial(_ string: String) -> PartialParseResult {
        // Find complete JSON objects
        var completeMessages: [IncomingMessage] = []
        var remaining = string

        while let endIndex = findJSONEnd(in: remaining) {
            let jsonString = String(remaining[remaining.startIndex..<endIndex])
            remaining = String(remaining[endIndex...])

            // Trim whitespace
            let trimmed = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !trimmed.isEmpty else { continue }

            if let data = trimmed.data(using: .utf8) {
                do {
                    let message = try decode(data)
                    completeMessages.append(message)
                } catch {
                    // Invalid JSON, skip
                }
            }
        }

        return PartialParseResult(
            completeMessages: completeMessages,
            remainingData: remaining
        )
    }

    /// Find the end of a JSON object
    private func findJSONEnd(in string: String) -> String.Index? {
        var braceCount = 0
        var inString = false
        var escape = false

        for (index, char) in string.enumerated() {
            if escape {
                escape = false
                continue
            }

            if char == "\\" && inString {
                escape = true
                continue
            }

            if char == "\"" {
                inString.toggle()
                continue
            }

            if !inString {
                if char == "{" {
                    braceCount += 1
                } else if char == "}" {
                    braceCount -= 1
                    if braceCount == 0 {
                        return string.index(string.startIndex, offsetBy: index + 1)
                    }
                }
            }
        }

        return nil
    }
}

// MARK: - Partial Parse Result

/// Result of partial JSON parsing
public struct PartialParseResult: Sendable {
    public let completeMessages: [IncomingMessage]
    public let remainingData: String

    public init(completeMessages: [IncomingMessage], remainingData: String) {
        self.completeMessages = completeMessages
        self.remainingData = remainingData
    }
}

// MARK: - Message Builder

/// Helper for building messages
public struct MessageBuilder: Sendable {

    /// Create a text message
    public static func text(_ content: String, sessionId: String? = nil) -> OutgoingMessage {
        OutgoingMessage.text(content, sessionId: sessionId)
    }

    /// Create a command message
    public static func command(_ command: String, sessionId: String? = nil) -> OutgoingMessage {
        OutgoingMessage(type: .command, content: command, sessionId: sessionId)
    }

    /// Create an interrupt message
    public static func interrupt(sessionId: String? = nil) -> OutgoingMessage {
        OutgoingMessage.interrupt(sessionId: sessionId)
    }

    /// Create a ping message
    public static func ping() -> OutgoingMessage {
        OutgoingMessage.ping()
    }
}
