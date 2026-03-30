import XCTest
@testable import Protocol

final class MessageProtocolTests: XCTestCase {

    // MARK: - Outgoing Message Tests

    func testOutgoingMessageCreation() {
        let message = OutgoingMessage.text("Hello, Claude!")

        XCTAssertEqual(message.content, "Hello, Claude!")
        XCTAssertNil(message.sessionId)
    }

    func testOutgoingMessageWithSessionId() {
        let message = OutgoingMessage.text("Hello", sessionId: "session-123")

        XCTAssertEqual(message.sessionId, "session-123")
    }

    func testInterruptMessage() {
        let message = OutgoingMessage.interrupt(sessionId: "session-456")

        XCTAssertEqual(message.content, "")
        XCTAssertEqual(message.sessionId, "session-456")
    }

    func testPingMessage() {
        let message = OutgoingMessage.ping()

        XCTAssertEqual(message.content, "")
    }

    // MARK: - Incoming Message Tests

    func testIncomingMessageCreation() {
        let message = IncomingMessage(
            type: .text,
            content: "Hello from Claude",
            isComplete: false
        )

        XCTAssertEqual(message.type, .text)
        XCTAssertEqual(message.content, "Hello from Claude")
        XCTAssertFalse(message.isComplete)
    }

    func testDeltaMessageCreation() {
        let message = IncomingMessage(
            type: .delta,
            delta: " world",
            isComplete: false
        )

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

    // MARK: - Event Tests

    func testCLIEventType() {
        XCTAssertEqual(CLIEventType.system.rawValue, "system")
        XCTAssertEqual(CLIEventType.assistant.rawValue, "assistant")
        XCTAssertEqual(CLIEventType.result.rawValue, "result")
    }

    func testSystemSubtype() {
        XCTAssertEqual(SystemSubtype.initialized.rawValue, "init")
        XCTAssertEqual(SystemSubtype.hookStarted.rawValue, "hook_started")
    }

    func testResultSubtype() {
        XCTAssertEqual(ResultSubtype.success.rawValue, "success")
        XCTAssertEqual(ResultSubtype.error.rawValue, "error")
    }
}
