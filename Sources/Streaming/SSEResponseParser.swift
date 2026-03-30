// SSEResponseParser.swift
// Claude Desktop Mac - SSE Response Parser Module
//
// Parses Server-Sent Events format responses from CLI

import Foundation
import Combine

// MARK: - SSE Event

/// A parsed SSE event
public struct SSEEvent: Sendable {
    public let id: String?
    public let event: String?
    public let data: String
    public let retry: Int?

    public init(id: String? = nil, event: String? = nil, data: String, retry: Int? = nil) {
        self.id = id
        self.event = event
        self.data = data
        self.retry = retry
    }
}

// MARK: - SSE Parser Error

/// Errors from SSE parsing
public enum SSEParseError: Error, Sendable, LocalizedError {
    case invalidFormat(String)
    case incompleteEvent
    case invalidEncoding

    public var errorDescription: String? {
        switch self {
        case .invalidFormat(let reason):
            return "Invalid SSE format: \(reason)"
        case .incompleteEvent:
            return "Incomplete SSE event"
        case .invalidEncoding:
            return "Invalid text encoding"
        }
    }
}

// MARK: - SSE Parser

/// Parses Server-Sent Events format
public final class SSEParser: @unchecked Sendable {

    // MARK: - Properties

    /// Buffer for incomplete data
    private var buffer: String = ""

    /// Lock for thread safety
    private let lock = NSLock()

    /// Subject for parsed events
    private let eventSubject = PassthroughSubject<SSEEvent, Never>()

    /// Subject for parsing errors
    private let errorSubject = PassthroughSubject<SSEParseError, Never>()

    // MARK: - Parsing

    /// Parse incoming data and emit complete events
    public func parse(_ data: Data) -> [SSEEvent] {
        guard let string = String(data: data, encoding: .utf8) else {
            errorSubject.send(.invalidEncoding)
            return []
        }

        return parse(string)
    }

    /// Parse incoming string and emit complete events
    public func parse(_ string: String) -> [SSEEvent] {
        lock.lock()
        defer { lock.unlock() }

        buffer += string

        var events: [SSEEvent] = []

        // Process complete events (separated by double newline)
        while let eventEndRange = buffer.range(of: "\n\n") {
            let eventData = String(buffer[buffer.startIndex..<eventEndRange.lowerBound])
            buffer = String(buffer[eventEndRange.upperBound...])

            if let event = parseEvent(eventData) {
                events.append(event)
                eventSubject.send(event)
            }
        }

        return events
    }

    /// Parse a single event block
    private func parseEvent(_ eventData: String) -> SSEEvent? {
        var id: String?
        var event: String?
        var data: String = ""
        var retry: Int?

        let lines = eventData.split(separator: "\n", omittingEmptySubsequences: false)

        for line in lines {
            // Skip empty lines (should not happen as we split on \n\n)
            if line.isEmpty { continue }

            // Parse field
            if let colonIndex = line.firstIndex(of: ":") {
                let field = String(line[line.startIndex..<colonIndex])
                var value = String(line[line.index(after: colonIndex)...])

                // Remove leading space if present
                if value.hasPrefix(" ") {
                    value = String(value.dropFirst())
                }

                switch field {
                case "id":
                    id = value
                case "event":
                    event = value
                case "data":
                    if data.isEmpty {
                        data = value
                    } else {
                        data += "\n" + value
                    }
                case "retry":
                    retry = Int(value)
                default:
                    // Unknown field, ignore
                    break
                }
            } else {
                // Field without colon - treat as field name with empty value
                // For "data" this is valid
                if line == "data" {
                    // Empty data line, ignore
                }
            }
        }

        // Return event only if we have data
        guard !data.isEmpty else { return nil }

        return SSEEvent(id: id, event: event, data: data, retry: retry)
    }

    /// Clear the buffer
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        buffer = ""
    }
}

// MARK: - Combine Support

extension SSEParser {

    /// Publisher for parsed events
    public var eventPublisher: AnyPublisher<SSEEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    /// Publisher for parsing errors
    public var errorPublisher: AnyPublisher<SSEParseError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
}
