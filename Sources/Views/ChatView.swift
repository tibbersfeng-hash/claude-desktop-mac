// ChatView.swift
// Claude Desktop Mac - Chat View
//
// Main chat interface with message list and input

import SwiftUI
import Theme
import Models
import ViewModels

// MARK: - Chat View

public struct ChatView: View {
    @Environment(\.colorScheme) private var colorScheme

    let session: Session?
    @Bindable var viewModel: ChatViewModel

    @State private var scrollViewProxy: ScrollViewProxy?
    @Namespace private var bottomID

    public init(session: Session?, viewModel: ChatViewModel) {
        self.session = session
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Messages area
            if let session = session {
                MessageListView(
                    messages: viewModel.messages,
                    streamingMessage: viewModel.streamingMessage,
                    autoScrollEnabled: viewModel.autoScrollEnabled,
                    isScrolledToBottom: $viewModel.isScrolledToBottom,
                    onScrollToBottom: { viewModel.scrollToBottom() }
                )
            } else {
                EmptyStateView(
                    icon: "bubble.left.and.bubble.right",
                    title: "No Session Selected",
                    subtitle: "Select a session from the sidebar or create a new one"
                )
            }

            Divider()
                .background(Color.fgTertiary(scheme: colorScheme).opacity(0.3))

            // Input area
            InputView(
                inputState: viewModel.inputState,
                connectionState: viewModel.connectionState,
                isStreaming: viewModel.isStreaming,
                projectPath: session?.projectPath,
                model: viewModel.currentModel,
                onSend: {
                    Task { await viewModel.sendMessage() }
                },
                onInterrupt: {
                    Task { await viewModel.interruptStream() }
                }
            )

            // Error banner
            if let error = viewModel.errorMessage {
                ErrorBanner(
                    message: error,
                    onDismiss: { viewModel.errorMessage = nil },
                    onRetry: {
                        Task { await viewModel.retryLastMessage() }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color.bgPrimary(scheme: colorScheme))
    }
}

// MARK: - Message List View

struct MessageListView: View {
    @Environment(\.colorScheme) private var colorScheme

    let messages: [ChatMessage]
    let streamingMessage: StreamingMessage?
    let autoScrollEnabled: Bool

    @Binding var isScrolledToBottom: Bool
    let onScrollToBottom: () -> Void

    @Namespace private var bottomAnchor

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.md.rawValue) {
                    ForEach(messages) { message in
                        MessageView(message: message)
                            .id(message.id)
                    }

                    // Streaming message
                    if let streaming = streamingMessage, !streaming.isComplete {
                        StreamingMessageView(streamingMessage: streaming)
                            .id("streaming")
                    }

                    // Bottom anchor for scrolling
                    Color.clear
                        .frame(height: 1)
                        .id(bottomAnchor)
                }
                .padding(.horizontal, Spacing.lg.rawValue)
                .padding(.vertical, Spacing.md.rawValue)
            }
            .scrollIndicators(.automatic)
            .onChange(of: messages.count) { _, _ in
                if autoScrollEnabled {
                    withAnimation(.appNormal) {
                        proxy.scrollTo(bottomAnchor, anchor: .bottom)
                    }
                }
            }
            .onChange(of: streamingMessage?.content) { _, _ in
                if autoScrollEnabled {
                    withAnimation(.appFast) {
                        proxy.scrollTo(bottomAnchor, anchor: .bottom)
                    }
                }
            }
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    @Environment(\.colorScheme) private var colorScheme

    let icon: String
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionTitle: String?

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: Spacing.lg.rawValue) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))

            Text(title)
                .font(.title3)
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.bodyText)
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.primary)
                    .padding(.top, Spacing.md.rawValue)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xxl.rawValue)
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    @Environment(\.colorScheme) private var colorScheme

    let message: String
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?

    var body: some View {
        HStack(spacing: Spacing.md.rawValue) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.accentError)

            Text(message)
                .font(.bodyText)
                .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                .lineLimit(2)

            Spacer()

            if let onRetry = onRetry {
                Button("Retry", action: onRetry)
                    .buttonStyle(.secondary)
            }

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.md.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
        .background(Color.accentError.opacity(0.1))
    }
}

// MARK: - Streaming Message View

struct StreamingMessageView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var streamingMessage: StreamingMessage

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
            // Header
            HStack(spacing: Spacing.sm.rawValue) {
                Image(systemName: "sparkles")
                    .foregroundColor(.accentPurple)

                Text("Claude")
                    .font(.headline)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                // Typing indicator
                TypingIndicator()
            }

            // Content
            if !streamingMessage.content.isEmpty {
                Text(streamingMessage.content)
                    .font(.assistantMessage)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                    .textSelection(.enabled)
            }

            // Tool calls
            if !streamingMessage.toolCalls.isEmpty {
                VStack(spacing: Spacing.sm.rawValue) {
                    ForEach(streamingMessage.toolCalls) { toolCall in
                        ToolCallView(toolCall: toolCall)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md.rawValue)
        .background(Color.bgSecondary(scheme: colorScheme).opacity(0.5))
        .cornerRadius(CornerRadius.lg.rawValue)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var animationPhase = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.fgSecondary(scheme: colorScheme))
                    .frame(width: 6, height: 6)
                    .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                    .opacity(animationPhase == index ? 1.0 : 0.5)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                animationPhase = 2
            }
        }
    }
}

// MARK: - Preview

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(
            session: Session.sample,
            viewModel: ChatViewModel()
        )
        .frame(width: 800, height: 600)
    }
}
