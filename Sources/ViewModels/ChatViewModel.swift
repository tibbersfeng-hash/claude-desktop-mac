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
import Models
import CLIConnector
import ErrorHandling
import CLIDetector

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

    private let executionService: CLIExecutionService
    private let detector: CLIDetector
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

    public init(executionService: CLIExecutionService = CLIExecutionService(), detector: CLIDetector = .shared) {
        self.executionService = executionService
        self.detector = detector
        self.inputState = MessageInputState()

        setupBindings()
    }

    // MARK: - Setup

    private func setupBindings() {
        // Subscribe to streaming deltas from execution service
        executionService.deltaPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] delta in
                self?.handleDelta(delta)
            }
            .store(in: &cancellables)

        // Subscribe to execution state
        executionService.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleExecutionState(state)
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
        inputState.startStreaming()

        do {
            // Execute with CLI
            let result = try await executionService.execute(
                message: text,
                workingDirectory: projectPath
            )

            // Update streaming message with final content
            streamingMessage?.content = result.content
            streamingMessage?.complete()

            // Add assistant message
            let assistantMessage = ChatMessage.assistant(result.content)
            messages.append(assistantMessage)

            streamingMessage = nil
            inputState.finishSending()

        } catch {
            handleError(error)
            inputState.finishSending()
            streamingMessage = nil
        }
    }

    /// Interrupt current streaming
    public func interruptStream() async {
        guard isStreaming else { return }

        // Cancel the execution
        executionService.cancel()

        // Complete the streaming message with current content
        streamingMessage?.complete()

        if let streaming = streamingMessage, !streaming.content.isEmpty {
            let assistantMessage = streaming.toChatMessage()
            messages.append(assistantMessage)
        }

        streamingMessage = nil
        inputState.finishSending()
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

        // Reset session for retry
        executionService.resetSession()
        await sendMessage()
    }

    /// Delete a message
    public func deleteMessage(_ messageId: UUID) {
        messages.removeAll { $0.id == messageId }
    }

    /// Edit a user message and optionally regenerate AI response
    public func editUserMessage(_ messageId: UUID, newContent: String, regenerate: Bool = false) async {
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else { return }
        let originalMessage = messages[index]

        guard originalMessage.role == .user else { return }

        // Update the message with edited content
        messages[index] = originalMessage.withEditedContent(newContent)

        // If regenerate is true, remove subsequent messages and resend
        if regenerate {
            // Remove all messages after the edited one
            messages = Array(messages.prefix(through: index))

            // Set input and resend
            inputState.text = newContent
            await sendMessage()
        }
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

    /// Connect to CLI (detect CLI presence)
    public func connect() async {
        let result = await detector.detect()

        if result.isInstalled {
            connectionState = .connected
            cliVersion = result.version
        } else {
            connectionState = .error
            errorMessage = "Claude Code CLI not found. Please install it first."
        }
    }

    /// Disconnect from CLI
    public func disconnect() async {
        executionService.resetSession()
        connectionState = .disconnected
    }

    // MARK: - Private Handlers

    private func handleExecutionState(_ state: ExecutionState) {
        switch state {
        case .idle:
            break
        case .executing:
            connectionState = .connected
        case .completed:
            inputState.finishSending()
        case .error(let message):
            errorMessage = message
            inputState.finishSending()
            streamingMessage = nil
        case .cancelled:
            inputState.finishSending()
            streamingMessage = nil
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
        if let executionError = error as? ExecutionError {
            errorMessage = executionError.errorDescription
        } else if let connectionError = error as? ConnectionError {
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
    /// Cached date formatter for performance
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    /// Create a formatted time string
    public func formattedTime(for message: ChatMessage) -> String {
        return Self.timeFormatter.string(from: message.timestamp)
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
