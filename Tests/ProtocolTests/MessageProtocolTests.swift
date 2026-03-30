import XCTest
@testable import Protocol

final class MessageProtocolTests: XCTestCase {

    // MARK: - Outgoing Message Tests

    func testOutgoingMessageCreation() {
        let message = OutgoingMessage.text("Hello, Claude!")

        XCTAssertEqual(message.type, .text)
        XCTAssertEqual(message.content, "Hello, Claude!")
        XCTAssertNil(message.sessionId)
        XCTAssertNotNil(message.timestamp)
    }

    func testOutgoingMessageWithSessionId() {
        let message = OutgoingMessage.text("Hello", sessionId: "session-123")

        XCTAssertEqual(message.sessionId, "session-123")
    }

    func testInterruptMessage() {
        let message = OutgoingMessage.interrupt(sessionId: "session-456")

        XCTAssertEqual(message.type, .interrupt)
        XCTAssertEqual(message.content, "")
    }

    func testPingMessage() {
        let message = OutgoingMessage.ping()

        XCTAssertEqual(message.type, .ping)
    }

    // MARK: - Incoming Message Tests

    func testIncomingMessageDecoding() throws {
        let json = """
        {
            "type": "text",
            "content": "Hello from Claude",
            "is_complete": false
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let message = try decoder.decode(IncomingMessage.self, from: data)

        XCTAssertEqual(message.type, .text)
        XCTAssertEqual(message.content, "Hello from Claude")
        XCTAssertFalse(message.isComplete)
    }

    func testDeltaMessageDecoding() throws {
        let json = """
        {
            "type": "delta",
            "delta": " world",
            "is_complete": false
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let message = try decoder.decode(IncomingMessage.self, from: data)

        XCTAssertEqual(message.type, .delta)
        XCTAssertEqual(message.delta, " world")
    }

    // MARK: - Tool Call Tests

    func testToolCallCreation() {
        let toolCall = ToolCall(
            id: "tool-123",
            name: "read_file",
            arguments: ["path": .string("/test/file.txt")],
            status: .pending
        )

        XCTAssertEqual(toolCall.id, "tool-123")
        XCTAssertEqual(toolCall.name, "read_file")
        XCTAssertEqual(toolCall.status, .pending)
    }

    // MARK: - JSON Value Tests

    func testJSONValueString() {
        let value = JSONValue.string("test")

        XCTAssertEqual(value.stringValue, "test")
        XCTAssertNil(value.boolValue)
        XCTAssertNil(value.doubleValue)
    }

    func testJSONValueBool() {
        let value = JSONValue.bool(true)

        XCTAssertEqual(value.boolValue, true)
        XCTAssertNil(value.stringValue)
    }

    func testJSONValueNumber() {
        let value = JSONValue.number(42.5)

        XCTAssertEqual(value.doubleValue, 42.5)
    }

    func testJSONValueArray() {
        let value = JSONValue.array([.string("a"), .string("b")])

        XCTAssertEqual(value.arrayValue?.count, 2)
    }

    func testJSONValueObject() {
        let value = JSONValue.object(["key": .string("value")])

        XCTAssertEqual(value.objectValue?["key"]?.stringValue, "value")
    }
}
