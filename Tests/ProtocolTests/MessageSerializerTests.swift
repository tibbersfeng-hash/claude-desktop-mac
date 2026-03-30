import XCTest
@testable import Protocol

final class MessageSerializerTests: XCTestCase {

    var serializer: MessageSerializer!

    override func setUp() {
        super.setUp()
        serializer = MessageSerializer.shared
    }

    override func tearDown() {
        serializer = nil
        super.tearDown()
    }

    // MARK: - Encoding Tests

    func testEncodeOutgoingMessage() throws {
        let message = OutgoingMessage.text("Hello, Claude!")

        let data = try serializer.encode(message)

        XCTAssertGreaterThan(data.count, 0)

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["type"] as? String, "text")
        XCTAssertEqual(json?["content"] as? String, "Hello, Claude!")
    }

    func testEncodeToString() throws {
        let message = OutgoingMessage.text("Test message")

        let string = try serializer.encodeToString(message)

        XCTAssertTrue(string.contains("\"type\":\"text\""))
        XCTAssertTrue(string.contains("\"content\":\"Test message\""))
    }

    func testEncodeWithNewline() throws {
        let message = OutgoingMessage.text("Test")

        let data = try serializer.encodeWithNewline(message)

        XCTAssertTrue(data.last == 0x0A) // Newline character
    }

    // MARK: - Decoding Tests

    func testDecodeIncomingMessage() throws {
        let json = """
        {"type":"text","content":"Hello","is_complete":false}
        """

        let data = json.data(using: .utf8)!
        let message = try serializer.decode(data)

        XCTAssertEqual(message.type, .text)
        XCTAssertEqual(message.content, "Hello")
        XCTAssertFalse(message.isComplete)
    }

    func testDecodeFromString() throws {
        let json = """
        {"type":"delta","delta":" test","is_complete":false}
        """

        let message = try serializer.decodeFromString(json)

        XCTAssertEqual(message.type, .delta)
        XCTAssertEqual(message.delta, " test")
    }

    func testDecodeMultiple() throws {
        let json = """
        {"type":"text","content":"Line 1","is_complete":false}
        {"type":"delta","delta":" delta","is_complete":false}
        {"type":"done","is_complete":true}
        """

        let data = json.data(using: .utf8)!
        let messages = try serializer.decodeMultiple(data)

        XCTAssertEqual(messages.count, 3)
        XCTAssertEqual(messages[0].type, .text)
        XCTAssertEqual(messages[1].type, .delta)
        XCTAssertEqual(messages[2].type, .done)
    }

    // MARK: - Partial Parsing Tests

    func testParsePartialComplete() throws {
        let json = """
        {"type":"text","content":"Complete","is_complete":true}
        """

        let result = serializer.parsePartial(json)

        XCTAssertEqual(result.completeMessages.count, 1)
        XCTAssertEqual(result.remainingData, "")
    }

    func testParsePartialIncomplete() throws {
        let json = """
        {"type":"text","content":"Incomplete"
        """

        let result = serializer.parsePartial(json)

        XCTAssertEqual(result.completeMessages.count, 0)
        XCTAssertFalse(result.remainingData.isEmpty)
    }

    func testParsePartialMultiple() throws {
        let json = """
        {"type":"text","content":"First","is_complete":false}
        {"type":"delta","delta":" second","is_complete":false}
        """

        let result = serializer.parsePartial(json)

        XCTAssertEqual(result.completeMessages.count, 2)
    }

    // MARK: - Message Builder Tests

    func testMessageBuilderText() {
        let message = MessageBuilder.text("Hello")

        XCTAssertEqual(message.type, .text)
        XCTAssertEqual(message.content, "Hello")
    }

    func testMessageBuilderInterrupt() {
        let message = MessageBuilder.interrupt(sessionId: "session-123")

        XCTAssertEqual(message.type, .interrupt)
        XCTAssertEqual(message.sessionId, "session-123")
    }

    func testMessageBuilderPing() {
        let message = MessageBuilder.ping()

        XCTAssertEqual(message.type, .ping)
    }
}
