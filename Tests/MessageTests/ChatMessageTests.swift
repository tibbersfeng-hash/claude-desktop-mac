import XCTest
@testable import Models

final class ChatMessageTests: XCTestCase {

    // MARK: - Initialization Tests

    func testChatMessageInitialization() {
        let message = ChatMessage(
            role: .user,
            content: "Hello, Claude!"
        )

        XCTAssertNotNil(message.id)
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "Hello, Claude!")
        XCTAssertNil(message.toolCalls)
        XCTAssertEqual(message.status, .completed)
        XCTAssertFalse(message.isEdited)
    }

    func testChatMessageWithAllParameters() {
        let toolCalls: [ToolCallDisplay] = [
            ToolCallDisplay(name: "read_file", status: .completed)
        ]
        let timestamp = Date()

        let message = ChatMessage(
            id: UUID(),
            role: .assistant,
            content: "Response",
            toolCalls: toolCalls,
            timestamp: timestamp,
            status: .streaming,
            isEdited: true
        )

        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.content, "Response")
        XCTAssertEqual(message.toolCalls?.count, 1)
        XCTAssertEqual(message.timestamp, timestamp)
        XCTAssertEqual(message.status, .streaming)
        XCTAssertTrue(message.isEdited)
    }

    // MARK: - isEdited Default Value Tests

    func testIsEditedDefaultValue() {
        let userMessage = ChatMessage.user("Test")
        XCTAssertFalse(userMessage.isEdited, "isEdited should default to false for user messages")

        let assistantMessage = ChatMessage.assistant("Response")
        XCTAssertFalse(assistantMessage.isEdited, "isEdited should default to false for assistant messages")

        let systemMessage = ChatMessage.system("System prompt")
        XCTAssertFalse(systemMessage.isEdited, "isEdited should default to false for system messages")
    }

    // MARK: - withEditedContent Tests

    func testWithEditedContentReturnsNewMessage() {
        let originalMessage = ChatMessage.user("Original content")
        let editedMessage = originalMessage.withEditedContent("New content")

        // Should return a new message with same ID
        XCTAssertEqual(originalMessage.id, editedMessage.id, "Edited message should preserve original ID")

        // Content should be updated
        XCTAssertEqual(editedMessage.content, "New content")
        XCTAssertEqual(originalMessage.content, "Original content", "Original message should not be modified")
    }

    func testWithEditedContentSetsIsEditedToTrue() {
        let originalMessage = ChatMessage.user("Original")
        let editedMessage = originalMessage.withEditedContent("Edited")

        XCTAssertTrue(editedMessage.isEdited, "withEditedContent should set isEdited to true")
        XCTAssertFalse(originalMessage.isEdited, "Original message isEdited should remain false")
    }

    func testWithEditedContentPreservesOtherProperties() {
        let timestamp = Date()
        let toolCalls: [ToolCallDisplay] = [ToolCallDisplay(name: "test", status: .pending)]

        let originalMessage = ChatMessage(
            id: UUID(),
            role: .assistant,
            content: "Original",
            toolCalls: toolCalls,
            timestamp: timestamp,
            status: .streaming,
            isEdited: false
        )

        let editedMessage = originalMessage.withEditedContent("Edited")

        XCTAssertEqual(editedMessage.role, originalMessage.role)
        XCTAssertEqual(editedMessage.toolCalls?.count, originalMessage.toolCalls?.count)
        XCTAssertEqual(editedMessage.timestamp, originalMessage.timestamp)
        XCTAssertEqual(editedMessage.status, originalMessage.status)
    }

    // MARK: - Factory Method Tests

    func testUserFactoryMethod() {
        let message = ChatMessage.user("User input")

        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "User input")
        XCTAssertNil(message.toolCalls)
    }

    func testAssistantFactoryMethod() {
        let message = ChatMessage.assistant("Assistant response")

        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.content, "Assistant response")
        XCTAssertNil(message.toolCalls)
    }

    func testAssistantFactoryMethodWithToolCalls() {
        let toolCalls: [ToolCallDisplay] = [
            ToolCallDisplay(name: "read_file", status: .completed)
        ]
        let message = ChatMessage.assistant("Response", toolCalls: toolCalls)

        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.toolCalls?.count, 1)
    }

    func testSystemFactoryMethod() {
        let message = ChatMessage.system("System prompt")

        XCTAssertEqual(message.role, .system)
        XCTAssertEqual(message.content, "System prompt")
    }

    // MARK: - MessageRole Tests

    func testMessageRoleDisplayName() {
        XCTAssertEqual(MessageRole.user.displayName, "You")
        XCTAssertEqual(MessageRole.assistant.displayName, "Claude")
        XCTAssertEqual(MessageRole.system.displayName, "System")
    }

    func testMessageRoleIconName() {
        XCTAssertEqual(MessageRole.user.iconName, "person.fill")
        XCTAssertEqual(MessageRole.assistant.iconName, "sparkles")
        XCTAssertEqual(MessageRole.system.iconName, "gearshape.fill")
    }

    func testMessageRoleCaseIterable() {
        XCTAssertEqual(MessageRole.allCases.count, 3)
        XCTAssertTrue(MessageRole.allCases.contains(.user))
        XCTAssertTrue(MessageRole.allCases.contains(.assistant))
        XCTAssertTrue(MessageRole.allCases.contains(.system))
    }

    // MARK: - MessageStatus Tests

    func testMessageStatusIsTransient() {
        XCTAssertTrue(MessageStatus.pending.isTransient)
        XCTAssertTrue(MessageStatus.sending.isTransient)
        XCTAssertTrue(MessageStatus.streaming.isTransient)

        XCTAssertFalse(MessageStatus.completed.isTransient)
        XCTAssertFalse(MessageStatus.error.isTransient)
    }

    // MARK: - Codable Tests

    func testChatMessageEncodingDecoding() throws {
        let original = ChatMessage.user("Test message")

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ChatMessage.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.role, original.role)
        XCTAssertEqual(decoded.content, original.content)
        XCTAssertEqual(decoded.status, original.status)
        XCTAssertEqual(decoded.isEdited, original.isEdited)
    }

    func testChatMessageEncodingDecodingWithEditedFlag() throws {
        let original = ChatMessage.user("Original").withEditedContent("Edited")

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ChatMessage.self, from: data)

        XCTAssertTrue(decoded.isEdited)
        XCTAssertEqual(decoded.content, "Edited")
    }

    // MARK: - FormattedTime Tests

    func testFormattedTime() {
        let message = ChatMessage.user("Test")

        // Verify formattedTime returns a non-empty string
        XCTAssertFalse(message.formattedTime.isEmpty)
    }

    // MARK: - Sample Data Tests

    func testSampleMessages() {
        let samples = ChatMessage.samples

        XCTAssertFalse(samples.isEmpty)
        XCTAssertTrue(samples.contains { $0.role == .user })
        XCTAssertTrue(samples.contains { $0.role == .assistant })
    }
}
