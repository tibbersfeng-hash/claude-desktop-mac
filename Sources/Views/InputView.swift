// InputView.swift
// Claude Desktop Mac - Input View
//
// Message input area with send functionality

import SwiftUI
import Theme
import Models
import State

// MARK: - Input View

public struct InputView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.highContrast) private var highContrast

    @ObservedObject var inputState: MessageInputState
    let connectionState: ConnectionState
    let isStreaming: Bool
    let projectPath: String?
    let model: String

    let onSend: () -> Void
    let onInterrupt: () -> Void

    @FocusState private var isInputFocused: Bool

    public init(
        inputState: MessageInputState,
        connectionState: ConnectionState,
        isStreaming: Bool,
        projectPath: String?,
        model: String,
        onSend: @escaping () -> Void,
        onInterrupt: @escaping () -> Void
    ) {
        self.inputState = inputState
        self.connectionState = connectionState
        self.isStreaming = isStreaming
        self.projectPath = projectPath
        self.model = model
        self.onSend = onSend
        self.onInterrupt = onInterrupt
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Input area
            HStack(alignment: .bottom, spacing: Spacing.md.rawValue) {
                // Attachment button
                Button(action: {}) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 16))
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                }
                .buttonStyle(.icon)
                .accessibilityLabel("Attach file")
                .accessibilityHint("Double tap to attach a file to your message")
                .help("Attach File (Cmd+Shift+A)")
                .disabled(connectionState != .connected || isStreaming)

                // Text input
                TextInputArea(
                    text: $inputState.text,
                    isFocused: $isInputFocused,
                    isSending: inputState.isSending,
                    isStreaming: isStreaming,
                    connectionState: connectionState
                )

                // Send/Stop button
                if isStreaming {
                    Button(action: onInterrupt) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.primary)
                    .accessibilityLabel("Stop response")
                    .accessibilityHint("Double tap to interrupt Claude's response")
                    .help("Stop (Escape)")
                } else {
                    Button(action: onSend) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.primary)
                    .disabled(!inputState.canSend || connectionState != .connected)
                    .accessibilityLabel("Send message")
                    .accessibilityHint("Double tap to send your message")
                    .help("Send (Cmd+Enter)")
                }
            }
            .padding(.horizontal, Spacing.lg.rawValue)
            .padding(.vertical, Spacing.md.rawValue)

            // Info bar
            InputInfoBar(
                projectPath: projectPath,
                model: model,
                connectionState: connectionState
            )
        }
        .background(Color.bgSecondary(scheme: colorScheme))
        .onSubmit {
            if inputState.canSend && !isStreaming {
                onSend()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Message input area")
    }
}

// MARK: - Text Input Area

struct TextInputArea: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.highContrast) private var highContrast

    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let isSending: Bool
    let isStreaming: Bool
    let connectionState: ConnectionState

    @State private var textEditorHeight: CGFloat = 36

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder
            if text.isEmpty {
                Text(placeholderText)
                    .font(.inputText)
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                    .padding(.horizontal, Spacing.md.rawValue)
                    .padding(.vertical, Spacing.sm.rawValue + 4)
                    .accessibilityHidden(true)
            }

            // Text editor
            TextEditor(text: $text)
                .font(.inputText)
                .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                .focused(isFocused)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 36, maxHeight: WindowDimensions.inputMaxHeight - 48)
                .disabled(connectionState != .connected || isStreaming)
        }
        .padding(.horizontal, Spacing.sm.rawValue)
        .padding(.vertical, Spacing.xs.rawValue)
        .background(Color.bgTertiary(scheme: colorScheme))
        .cornerRadius(CornerRadius.md.rawValue)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md.rawValue)
                .stroke(enhancedInputBorderColor, lineWidth: enhancedInputBorderWidth)
        )
        .accessibilityLabel("Message input")
        .accessibilityHint(placeholderText)
        .accessibilityValue(text.isEmpty ? "Empty" : text)
    }

    private var placeholderText: String {
        if connectionState != .connected {
            return "Connect to Claude to start..."
        } else if isStreaming {
            return "Waiting for response..."
        } else {
            return "Type your message... (Cmd+Enter to send)"
        }
    }

    private var enhancedInputBorderColor: Color {
        if highContrast {
            return isFocused.wrappedValue ? Color.accentPrimaryHighContrast : Color.fgSecondaryHighContrast
        }
        return isFocused.wrappedValue ? Color.accentPrimary : Color.fgTertiary(scheme: colorScheme).opacity(0.3)
    }

    private var enhancedInputBorderWidth: CGFloat {
        highContrast ? 2 : (isFocused.wrappedValue ? 2 : 1)
    }
}

// MARK: - Input Info Bar

struct InputInfoBar: View {
    @Environment(\.colorScheme) private var colorScheme

    let projectPath: String?
    let model: String
    let connectionState: ConnectionState

    var body: some View {
        HStack(spacing: Spacing.lg.rawValue) {
            // Project
            if let project = projectPath {
                HStack(spacing: Spacing.xs.rawValue) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))

                    Text(project.split(separator: "/").last.map(String.init) ?? project)
                        .font(.captionText)
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                }
            }

            // Model
            HStack(spacing: Spacing.xs.rawValue) {
                Image(systemName: "cpu")
                    .font(.system(size: 10))
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))

                Text(model)
                    .font(.captionText)
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
            }

            Spacer()

            // Keyboard hint
            Text("Cmd+Enter to send")
                .font(.caption2)
                .foregroundColor(Color.fgTertiary(scheme: colorScheme).opacity(0.7))
        }
        .padding(.horizontal, Spacing.lg.rawValue)
        .padding(.bottom, Spacing.sm.rawValue)
    }
}

// MARK: - Connection Prompt View

struct ConnectionPromptView: View {
    @Environment(\.colorScheme) private var colorScheme

    let connectionState: ConnectionState
    let onConnect: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md.rawValue) {
            switch connectionState {
            case .idle, .disconnected:
                Button("Connect to Claude") {
                    onConnect()
                }
                .buttonStyle(.primary)

            case .detecting:
                HStack(spacing: Spacing.sm.rawValue) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Detecting CLI...")
                        .font(.bodyText)
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                }

            case .connecting:
                HStack(spacing: Spacing.sm.rawValue) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Connecting...")
                        .font(.bodyText)
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                }

            case .reconnecting:
                HStack(spacing: Spacing.sm.rawValue) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Reconnecting...")
                        .font(.bodyText)
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                }

            case .error:
                VStack(spacing: Spacing.sm.rawValue) {
                    Text("Connection failed")
                        .font(.bodyText)
                        .foregroundColor(.accentError)

                    Button("Retry") {
                        onConnect()
                    }
                    .buttonStyle(.secondary)
                }

            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md.rawValue)
    }
}

// MARK: - Preview

struct InputView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()

            InputView(
                inputState: {
                    let state = MessageInputState()
                    state.text = "Hello, Claude!"
                    return state
                }(),
                connectionState: .connected,
                isStreaming: false,
                projectPath: "/Users/dev/project",
                model: "claude-sonnet-4.6",
                onSend: {},
                onInterrupt: {}
            )
        }
        .frame(width: 600, height: 300)
        .background(Color.bgPrimaryDark)
    }
}
