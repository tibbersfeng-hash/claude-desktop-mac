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

    func testEncodeInputText() {
        let text = "Hello, Claude!"

        let data = serializer.encodeInput(text)

        XCTAssertGreaterThan(data.count, 0)
        XCTAssertTrue(String(data: data, encoding: .utf8)?.hasSuffix("\n") ?? false)
    }

    func testEncodeInputWithNewline() {
        let text = "Test message\n"

        let data = serializer.encodeInput(text)

        // Should not add another newline
        let string = String(data: data, encoding: .utf8)
        XCTAssertEqual(string?.filter { $0 == "\n" }.count, 1)
    }

    func testEncodeInputWithSessionId() {
        let (data, args) = serializer.encodeInput("Hello", resumeSessionId: "session-123")

        XCTAssertGreaterThan(data.count, 0)
        XCTAssertEqual(args, ["--resume", "session-123"])
    }

    // MARK: - Parsing Tests

    func testParseLineValid() {
        let json = """
        {"type":"assistant","message":{"id":"123","type":"message","role":"assistant","content":[{"type":"text","text":"Hello"}]},"session_id":"sess-1"}
        """

        let event = serializer.parseLine(json)

        XCTAssertNotNil(event)
        if case .assistant(let assistantEvent) = event {
            XCTAssertEqual(assistantEvent.textContent, "Hello")
        } else {
            XCTFail("Expected assistant event")
        }
    }

    func testParseLineEmpty() {
        let event = serializer.parseLine("")
        XCTAssertNil(event)
    }

    func testParseLineInvalidJSON() {
        let event = serializer.parseLine("not valid json")
        XCTAssertNil(event)
    }

    // MARK: - Event Parsing Tests

    func testParseSystemInitEvent() throws {
        let json = """
        {"type":"system","subtype":"init","cwd":"/test","session_id":"sess-123","model":"claude-3"}
        """

        let data = json.data(using: .utf8)!
        let event = try serializer.parseEvent(data)

        if case .systemInit(let initEvent) = event {
            XCTAssertEqual(initEvent.cwd, "/test")
            XCTAssertEqual(initEvent.sessionId, "sess-123")
            XCTAssertEqual(initEvent.model, "claude-3")
        } else {
            XCTFail("Expected systemInit event")
        }
    }

    func testParseResultEvent() throws {
        let json = """
        {"type":"result","subtype":"success","is_error":false,"result":"Done","session_id":"sess-456"}
        """

        let data = json.data(using: .utf8)!
        let event = try serializer.parseEvent(data)

        if case .result(let resultEvent) = event {
            XCTAssertTrue(resultEvent.isSuccess)
            XCTAssertEqual(resultEvent.result, "Done")
            XCTAssertEqual(resultEvent.sessionId, "sess-456")
        } else {
            XCTFail("Expected result event")
        }
    }

    // MARK: - Stream Parser Tests

    func testStreamParserSingleEvent() {
        let parser = StreamParser()
        let json = """
        {"type":"result","subtype":"success","is_error":false,"result":"Test"}

        """

        let events = parser.append(json)

        XCTAssertEqual(events.count, 1)
    }

    func testStreamParserMultipleEvents() {
        let parser = StreamParser()
        let json = """
        {"type":"system","subtype":"init","session_id":"s1"}
        {"type":"result","subtype":"success","is_error":false,"result":"Test"}

        """

        let events = parser.append(json)

        XCTAssertEqual(events.count, 2)
    }

    func testStreamParserIncompleteEvent() {
        let parser = StreamParser()

        let events1 = parser.append("{\"type\":\"result\",")
        XCTAssertEqual(events1.count, 0)

        let events2 = parser.append("\"subtype\":\"success\",\"is_error\":false,\"result\":\"Test\"}\n")
        XCTAssertEqual(events2.count, 1)
    }

    func testStreamParserReset() {
        let parser = StreamParser()
        _ = parser.append("incomplete json")

        parser.reset()

        XCTAssertEqual(parser.remainingBuffer(), "")
    }

    // MARK: - Event Filter Tests

    func testEventFilterExtractText() {
        let json1 = """
        {"type":"assistant","message":{"id":"1","type":"message","role":"assistant","content":[{"type":"text","text":"Hello"}]},"session_id":"s1"}
        """
        let json2 = """
        {"type":"result","subtype":"success","is_error":false,"result":" World"}

        """

        let event1 = serializer.parseLine(json1)
        let event2 = serializer.parseLine(json2)

        var events: [ParsedEvent] = []
        if let e1 = event1 { events.append(e1) }
        if let e2 = event2 { events.append(e2) }

        let text = EventFilter.extractText(from: events)
        XCTAssertEqual(text, "Hello World")
    }

    func testEventFilterHasError() {
        let json = """
        {"type":"result","subtype":"error","is_error":true,"result":"Something went wrong"}

        """

        let event = serializer.parseLine(json)
        let events = event.map { [$0] } ?? []

        let (hasError, message) = EventFilter.hasError(in: events)
        XCTAssertTrue(hasError)
        XCTAssertEqual(message, "Something went wrong")
    }

    func testEventFilterIsComplete() {
        let json = """
        {"type":"result","subtype":"success","is_error":false,"result":"Done"}

        """

        let event = serializer.parseLine(json)
        let events = event.map { [$0] } ?? []

        XCTAssertTrue(EventFilter.isComplete(in: events))
    }
}
