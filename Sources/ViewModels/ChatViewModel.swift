// ChatViewModel.swift
// Claude Desktop Mac - Chat ViewModel
//
// Manages chat state and message operations

import Foundation
import SwiftUI
import Combine
import Protocol
import Streaming
import State

// MARK: - Chat ViewModel

@MainActor
@Observable
public final class ChatViewModel {

    // MARK: - Properties

    /// The current session being displayed
    public var session: Session?

    /// Messages for display
    public var messages: [ChatMessage] = []

    /// Input state
    public var inputState: MessageInputState

    /// Current streaming message
    public var streamingMessage: StreamingMessage?

    /// Whether the view is scrolled to bottom
    public var isScrolledToBottom: Bool = true

    /// Whether auto-scroll is enabled
    public var autoScrollEnabled: Bool = true

    /// Error message to display
    public var errorMessage: String?

    /// Connection state
    public var connectionState: ConnectionState = .idle

    /// CLI version string
    public var cliVersion: String?

    /// Current project path
    public var projectPath: String?

    /// Current model
    public var currentModel: String = "claude-sonnet-4.6"

    /// Available models
    public var availableModels: [String] = [
        "claude-sonnet-4.6",
        "claude-sonnet-4.5",
        "claude-opus-4.5",
        "claude-haiku-4.5"
    ]

    // MARK: - Private Properties

    private let cliConnector: CLIConnector
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    /// Whether messages can be sent
    public var canSendMessage: Bool {
        inputState.canSend && connectionState == .connected
    }

    /// Whether a response is being streamed
    public var isStreaming: Bool {
        streamingMessage != nil && !(streamingMessage?.isComplete ?? true)
    }

    /// Whether there are any messages
    public var hasMessages: Bool {
        !messages.isEmpty
    }

    /// Last message for display purposes
    public var lastMessage: ChatMessage? {
        messages.last
    }

    // MARK: - Initialization

    public init(cliConnector: CLIConnector = .shared) {
        self.cliConnector = cliConnector
        self.inputState = MessageInputState()

        setupBindings()
    }

    // MARK: - Setup

    private func setupBindings() {
        // Subscribe to connection state
        cliConnector.$connectionState
            .receive(on: DispatchQueue.main)
            .assign(to: &$connectionState)

        // Subscribe to detection result
        cliConnector.$detectionResult
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.cliVersion = result?.version
            }
            .store(in: &cancellables)

        // Subscribe to streaming response
        cliConnector.responseHandler.responsePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                self?.handleStreamingResponse(response)
            }
            .store(in: &cancellables)

        // Subscribe to streaming deltas
        cliConnector.responseHandler.deltaPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] delta in
                self?.handleDelta(delta)
            }
            .store(in: &cancellables)

        // Subscribe to errors
        cliConnector.$lastError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorInfo in
                if let error = errorInfo {
                    self?.handleError(error)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Session Management

    /// Load a session for display
    public func loadSession(_ session: Session) {
        self.session = session
        self.messages = session.messages
        self.projectPath = session.projectPath
        self.currentModel = session.model
    }

    /// Clear the current session
    public func clearSession() {
        session = nil
        messages = []
        streamingMessage = nil
        inputState.clear()
    }

    // MARK: - Message Operations

    /// Send a message
    public func sendMessage() async {
        let text = inputState.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, connectionState == .connected else { return }

        inputState.startSending()
        clearError()

        // Create user message
        let userMessage = ChatMessage.user(text)
        messages.append(userMessage)

        // Clear input
        inputState.clear()

        // Start streaming message for response
        streamingMessage = StreamingMessage()

        do {
            // Send to CLI
            try await cliConnector.send(text)

            inputState.startStreaming()
        } catch {
            handleError(error)
            inputState.finishSending()
            streamingMessage = nil
        }
    }

    /// Interrupt current streaming
    public func interruptStream() async {
        guard isStreaming else { return }

        do {
            try await cliConnector.interrupt()

            // Complete the streaming message with current content
            streamingMessage?.complete()

            if let streaming = streamingMessage {
                let assistantMessage = streaming.toChatMessage()
                messages.append(assistantMessage)
            }

            streamingMessage = nil
            inputState.finishSending()
        } catch {
            handleError(error)
        }
    }

    /// Retry the last message
    public func retryLastMessage() async {
        // Remove last assistant message if present
        if let lastMessage = messages.last, lastMessage.role == .assistant {
            messages.removeLast()
        }

        // Get last user message
        guard let lastUserMessage = messages.last(where: { $0.role == .user }) else { return }

        // Set input and send
        inputState.text = lastUserMessage.content
        messages.removeLast() // Remove the user message too, it will be re-added
        await sendMessage()
    }

    /// Delete a message
    public func deleteMessage(_ messageId: UUID) {
        messages.removeAll { $0.id == messageId }
    }

    /// Edit a message
    public func editMessage(_ messageId: UUID, newContent: String) {
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else { return }
        messages[index].content = newContent
    }

    // MARK: - Scrolling

    /// Scroll to bottom
    public func scrollToBottom() {
        isScrolledToBottom = true
        autoScrollEnabled = true
    }

    /// User scrolled away from bottom
    public func userScrolledAway() {
        autoScrollEnabled = false
    }

    /// User scrolled to bottom
    public func userScrolledToBottom() {
        isScrolledToBottom = true
        autoScrollEnabled = true
    }

    // MARK: - Model Selection

    /// Change the current model
    public func selectModel(_ model: String) {
        currentModel = model
    }

    // MARK: - Connection

    /// Connect to CLI
    public func connect() async {
        do {
            try await cliConnector.quickConnect()
        } catch {
            handleError(error)
        }
    }

    /// Disconnect from CLI
    public func disconnect() async {
        await cliConnector.disconnect()
    }

    // MARK: - Private Handlers

    private func handleStreamingResponse(_ response: StreamingResponse) {
        guard let streaming = streamingMessage else { return }

        streaming.content = response.content

        // Add any tool calls
        for toolCall in response.toolCalls {
            if !streaming.toolCalls.contains(where: { $0.id == toolCall.id }) {
                let display = ToolCallDisplay(from: toolCall)
                streaming.toolCalls.append(display)
            }
        }

        // If complete, add to messages
        if response.isComplete {
            streaming.complete()
            let assistantMessage = streaming.toChatMessage()
            messages.append(assistantMessage)
            self.streamingMessage = nil
            inputState.finishSending()
        }
    }

    private func handleDelta(_ delta: String) {
        streamingMessage?.append(delta)

        // Auto-scroll if enabled
        if autoScrollEnabled {
            isScrolledToBottom = true
        }
    }

    private func handleError(_ error: Error) {
        if let connectionError = error as? ConnectionError {
            errorMessage = connectionError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
    }

    private func handleError(_ errorInfo: ErrorInfo) {
        errorMessage = errorInfo.message
    }

    private func clearError() {
        errorMessage = nil
    }
}

// MARK: - Helper Extensions

extension ChatViewModel {
    /// Create a formatted time string
    public func formattedTime(for message: ChatMessage) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.timestamp)
    }

    /// Group messages by date
    public func messagesByDate() -> [(Date, [ChatMessage])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: messages) { message in
            calendar.startOfDay(for: message.timestamp)
        }
        return groups.sorted { $0.key < $1.key }
    }
}
