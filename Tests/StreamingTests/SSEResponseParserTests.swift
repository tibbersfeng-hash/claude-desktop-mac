import XCTest
@testable import Streaming

final class SSEResponseParserTests: XCTestCase {

    var parser: SSEParser!

    override func setUp() {
        super.setUp()
        parser = SSEParser()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - Basic Parsing Tests

    func testParseSimpleEvent() {
        let data = """
        data: Hello World\n\n
        """.data(using: .utf8)!

        let events = parser.parse(data)

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].data, "Hello World")
    }

    func testParseEventWithType() {
        let data = """
        event: message\ndata: Test content\n\n
        """.data(using: .utf8)!

        let events = parser.parse(data)

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].event, "message")
        XCTAssertEqual(events[0].data, "Test content")
    }

    func testParseEventWithId() {
        let data = """
        id: 123\ndata: Content\n\n
        """.data(using: .utf8)!

        let events = parser.parse(data)

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].id, "123")
    }

    func testParseMultipleEvents() {
        let data = """
        data: First\n\ndata: Second\n\n
        """.data(using: .utf8)!

        let events = parser.parse(data)

        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0].data, "First")
        XCTAssertEqual(events[1].data, "Second")
    }

    // MARK: - Multi-line Data Tests

    func testParseMultiLineData() {
        let data = """
        data: Line 1\ndata: Line 2\n\n
        """.data(using: .utf8)!

        let events = parser.parse(data)

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].data, "Line 1\nLine 2")
    }

    // MARK: - Buffer Tests

    func testIncompleteEventBuffered() {
        // First chunk is incomplete
        let data1 = "data: Partial".data(using: .utf8)!
        let events1 = parser.parse(data1)
        XCTAssertEqual(events1.count, 0)

        // Complete with second chunk
        let data2 = "\n\n".data(using: .utf8)!
        let events2 = parser.parse(data2)
        XCTAssertEqual(events2.count, 1)
        XCTAssertEqual(events2[0].data, "Partial")
    }

    func testResetClearsBuffer() {
        let data = "data: Incomplete".data(using: .utf8)!
        _ = parser.parse(data)

        parser.reset()

        // After reset, the incomplete data should be gone
        let data2 = "data: Fresh\n\n".data(using: .utf8)!
        let events = parser.parse(data2)

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].data, "Fresh")
    }
}
