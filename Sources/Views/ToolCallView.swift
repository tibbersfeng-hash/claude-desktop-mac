// ToolCallView.swift
// Claude Desktop Mac - Tool Call View
//
// Displays tool calls with expandable details

import SwiftUI
import Theme
import Models

// MARK: - Tool Call View

public struct ToolCallView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.reduceMotion) private var reduceMotion
    @Environment(\.highContrast) private var highContrast

    let toolCall: ToolCallDisplay

    @State private var isExpanded: Bool
    @State private var isHovered: Bool = false

    public init(toolCall: ToolCallDisplay) {
        self.toolCall = toolCall
        self._isExpanded = State(initialValue: toolCall.isExpanded)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            ToolCallHeader(
                toolCall: toolCall,
                isExpanded: $isExpanded,
                isHovered: isHovered
            )
            .onTapGesture {
                withAccessibleAnimation(.appNormal) {
                    isExpanded.toggle()
                }
            }

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
                    // Arguments
                    if let arguments = toolCall.arguments {
                        ToolCallSection(
                            title: "Arguments",
                            content: arguments,
                            copyAction: { copyToClipboard(arguments) }
                        )
                    }

                    // Result
                    if let result = toolCall.result {
                        ToolCallSection(
                            title: "Result",
                            content: result,
                            copyAction: { copyToClipboard(result) }
                        )
                    }

                    // Error
                    if let error = toolCall.error {
                        ToolCallErrorSection(error: error)
                    }
                }
                .padding(Spacing.md.rawValue)
                .background(Color.bgTertiary(scheme: colorScheme).opacity(0.5))
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .background(Color.bgSecondary(scheme: colorScheme))
        .cornerRadius(CornerRadius.md.rawValue)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md.rawValue)
                .stroke(enhancedBorderColor, lineWidth: enhancedBorderWidth)
        )
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(toolCallAccessibilityLabel)
        .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand") details")
        .accessibilityAddTraits(.isButton)
    }

    private var toolCallAccessibilityLabel: String {
        "\(toolCall.displayName) tool call, \(toolCall.status.accessibilityDescription)"
    }

    private var enhancedBorderColor: Color {
        if highContrast {
            switch toolCall.status {
            case .running:
                return .accentWarningHighContrast
            case .error:
                return .accentErrorHighContrast
            default:
                return .fgSecondaryHighContrast
            }
        }
        return statusBorderColor
    }

    private var enhancedBorderWidth: CGFloat {
        highContrast ? 2 : 1
    }

    private var statusBorderColor: Color {
        switch toolCall.status {
        case .running:
            return .accentWarning.opacity(0.5)
        case .error:
            return .accentError.opacity(0.5)
        default:
            return Color.fgTertiary(scheme: colorScheme).opacity(0.3)
        }
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

// MARK: - Tool Call Header

struct ToolCallHeader: View {
    @Environment(\.colorScheme) private var colorScheme

    let toolCall: ToolCallDisplay
    @Binding var isExpanded: Bool
    let isHovered: Bool

    var body: some View {
        HStack(spacing: Spacing.sm.rawValue) {
            // Icon with status
            ZStack {
                Circle()
                    .fill(toolCall.iconColor.opacity(0.2))
                    .frame(width: 28, height: 28)

                if toolCall.status == .running {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 28, height: 28)
                } else {
                    Image(systemName: toolCall.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(toolCall.iconColor)
                }
            }

            // Name and summary
            VStack(alignment: .leading, spacing: 2) {
                Text(toolCall.displayName)
                    .font(.toolName)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                if !isExpanded {
                    Text(toolCall.summary)
                        .font(.captionText)
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Duration
            if let duration = toolCall.durationString {
                Text(duration)
                    .font(.captionText)
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
            }

            // Status indicator
            Image(systemName: toolCall.status.iconName)
                .font(.system(size: 12))
                .foregroundColor(toolCall.status.color)

            // Expand/collapse button
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))

            // Copy button on hover
            if isHovered, let result = toolCall.result ?? toolCall.arguments {
                Button(action: {}) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                }
                .buttonStyle(.icon(size: 20))
            }
        }
        .padding(.horizontal, Spacing.md.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
        .background(Color.bgSecondary(scheme: colorScheme))
    }
}

// MARK: - Tool Call Section

struct ToolCallSection: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let content: String
    let copyAction: () -> Void

    @State private var showCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
            HStack {
                Text(title)
                    .font(.captionText)
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))

                Spacer()

                Button(action: {
                    copyAction()
                    showCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showCopied = false
                    }
                }) {
                    if showCopied {
                        Text("Copied!")
                            .font(.caption2)
                    } else {
                        Image(systemName: "doc.on.doc")
                    }
                }
                .font(.captionText)
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                .buttonStyle(.plain)
                .accessibilityLabel("Copy \(title.lowercased())")
                .accessibilityHint("Double tap to copy to clipboard")
            }

            ScrollView(.horizontal, showsIndicators: true) {
                Text(content)
                    .font(.toolArguments)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 150)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(content)")
    }
}

// MARK: - Tool Call Error Section

struct ToolCallErrorSection: View {
    @Environment(\.colorScheme) private var colorScheme

    let error: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
            HStack(spacing: Spacing.xs.rawValue) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.accentError)

                Text("Error")
                    .font(.captionText)
                    .foregroundColor(.accentError)
            }

            Text(error)
                .font(.toolArguments)
                .foregroundColor(.accentError)
                .textSelection(.enabled)
        }
        .padding(Spacing.sm.rawValue)
        .background(Color.accentError.opacity(0.1))
        .cornerRadius(CornerRadius.sm.rawValue)
    }
}

// MARK: - Tool Call Group View

public struct ToolCallGroupView: View {
    @Environment(\.colorScheme) private var colorScheme

    let toolCalls: [ToolCallDisplay]
    let maxCollapsed: Int

    @State private var isExpanded = false

    public init(toolCalls: [ToolCallDisplay], maxCollapsed: Int = 3) {
        self.toolCalls = toolCalls
        self.maxCollapsed = maxCollapsed
    }

    public var body: some View {
        VStack(spacing: Spacing.sm.rawValue) {
            ForEach(displayedToolCalls) { toolCall in
                ToolCallView(toolCall: toolCall)
            }

            if toolCalls.count > maxCollapsed && !isExpanded {
                Button(action: {
                    withAnimation(.appNormal) {
                        isExpanded = true
                    }
                }) {
                    Text("+ \(toolCalls.count - maxCollapsed) more tool calls")
                        .font(.captionText)
                        .foregroundColor(Color.accentPrimary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var displayedToolCalls: [ToolCallDisplay] {
        if isExpanded {
            return toolCalls
        }
        return Array(toolCalls.prefix(maxCollapsed))
    }
}

// MARK: - Running Tool Call View

public struct RunningToolCallView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.highContrast) private var highContrast

    let toolName: String
    let startTime: Date

    @State private var elapsedTime: TimeInterval = 0
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    public init(toolName: String, startTime: Date) {
        self.toolName = toolName
        self.startTime = startTime
    }

    public var body: some View {
        HStack(spacing: Spacing.md.rawValue) {
            ProgressView()
                .scaleEffect(0.7)
                .accessibilityHidden(true)

            Text("Running \(toolName)...")
                .font(.bodyText)
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))

            Spacer()

            Text(String(format: "%.1fs", elapsedTime))
                .font(.captionText)
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))
        }
        .padding(Spacing.md.rawValue)
        .background(Color.bgSecondary(scheme: colorScheme))
        .cornerRadius(CornerRadius.md.rawValue)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md.rawValue)
                .stroke(highContrast ? Color.accentWarningHighContrast : Color.accentWarning.opacity(0.5), lineWidth: highContrast ? 2 : 1)
        )
        .onReceive(timer) { _ in
            elapsedTime = Date().timeIntervalSince(startTime)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Running \(toolName), elapsed time: \(String(format: "%.1f", elapsedTime)) seconds")
        .accessibilityValue(String(format: "%.1f seconds", elapsedTime))
    }
}

// MARK: - Preview

struct ToolCallView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            ToolCallView(toolCall: ToolCallDisplay(
                name: "Read",
                arguments: "{ \"file_path\": \"/src/api/client.swift\" }",
                result: "245 lines read",
                status: .success,
                duration: 0.15,
                isExpanded: true
            ))

            ToolCallView(toolCall: ToolCallDisplay(
                name: "Edit",
                arguments: "{ \"file_path\": \"/src/api/client.swift\" }",
                error: "Edit failed: could not find exact match",
                status: .error,
                isExpanded: true
            ))

            ToolCallView(toolCall: ToolCallDisplay(
                name: "Grep",
                arguments: "{ \"pattern\": \"func.*api\" }",
                status: .running,
                isExpanded: false
            ))
        }
        .padding()
        .frame(width: 500)
        .background(Color.bgPrimaryDark)
    }
}
