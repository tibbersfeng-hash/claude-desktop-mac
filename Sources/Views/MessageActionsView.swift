// MessageActionsView.swift
// Claude Desktop Mac - Message Actions View
//
// Context menu and action buttons for messages

import SwiftUI
import Theme
import Models

// MARK: - Message Actions Delegate

/// Protocol for handling message actions
public protocol MessageActionsDelegate: AnyObject {
    func deleteMessage(_ messageId: UUID)
    func editMessage(_ messageId: UUID, newContent: String)
    func regenerateMessage(_ messageId: UUID)
    func copyMessage(_ content: String)
    func quoteMessage(_ content: String)
}

// MARK: - Message Context Menu

public struct MessageContextMenu: View {
    let message: ChatMessage
    let isEditing: Bool
    weak var delegate: MessageActionsDelegate?

    public init(
        message: ChatMessage,
        isEditing: Bool = false,
        delegate: MessageActionsDelegate? = nil
    ) {
        self.message = message
        self.isEditing = isEditing
        self.delegate = delegate
    }

    public var body: some View {
        Group {
            // Copy
            Button {
                delegate?.copyMessage(message.content)
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }

            // Quote
            Button {
                delegate?.quoteMessage(message.content)
            } label: {
                Label("Quote", systemImage: "quote.bubble")
            }

            Divider()

            // Edit (only for user messages)
            if message.role == .user && !isEditing {
                Button {
                    // Trigger edit mode (handled by parent view)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }

            // Regenerate (only for assistant messages)
            if message.role == .assistant {
                Button {
                    delegate?.regenerateMessage(message.id)
                } label: {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                }

                // Variations (if there are multiple versions)
                if message.hasVariations {
                    Menu {
                        ForEach(message.variations.indices, id: \.self) { index in
                            Button {
                                // Switch to variation
                            } label: {
                                Text("Variation \(index + 1)")
                            }
                        }
                    } label: {
                        Label("View Variations", systemImage: "square.on.square")
                    }
                }
            }

            Divider()

            // Delete
            Button(role: .destructive) {
                delegate?.deleteMessage(message.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Message Action Bar (Hover Actions)

public struct MessageActionBar: View {
    @Environment(\.colorScheme) private var colorScheme

    let message: ChatMessage
    let isHovered: Bool
    weak var delegate: MessageActionsDelegate?

    @State private var showDeleteConfirmation: Bool = false

    public init(
        message: ChatMessage,
        isHovered: Bool,
        delegate: MessageActionsDelegate? = nil
    ) {
        self.message = message
        self.isHovered = isHovered
        self.delegate = delegate
    }

    public var body: some View {
        HStack(spacing: Spacing.xs.rawValue) {
            // Copy
            ActionButton(
                iconName: "doc.on.doc",
                label: "Copy",
                isHovered: isHovered
            ) {
                delegate?.copyMessage(message.content)
            }

            // Role-specific actions
            if message.role == .user {
                // Edit button
                ActionButton(
                    iconName: "pencil",
                    label: "Edit",
                    isHovered: isHovered
                ) {
                    // Trigger edit mode
                }
            } else {
                // Regenerate button
                ActionButton(
                    iconName: "arrow.clockwise",
                    label: "Regenerate",
                    isHovered: isHovered
                ) {
                    delegate?.regenerateMessage(message.id)
                }
            }

            // Delete
            ActionButton(
                iconName: "trash",
                label: "Delete",
                isHovered: isHovered,
                color: .accentError
            ) {
                showDeleteConfirmation = true
            }
        }
        .confirmationDialog(
            "Delete Message?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                delegate?.deleteMessage(message.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let iconName: String
    let label: String
    let isHovered: Bool
    var color: Color = .accentPrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: iconName)
                    .font(.system(size: 11))
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.bgSecondary(scheme: colorScheme))
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .opacity(isHovered ? 1 : 0)
        .accessibilityLabel(label)
    }
}

// MARK: - Regeneration View

public struct RegenerationView: View {
    @Environment(\.colorScheme) private var colorScheme

    let onRegenerate: () -> Void
    let onCancel: () -> Void

    @State private var isRegenerating: Bool = false

    public init(
        onRegenerate: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.onRegenerate = onRegenerate
        self.onCancel = onCancel
    }

    public var body: some View {
        HStack(spacing: Spacing.md.rawValue) {
            if isRegenerating {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Regenerating...")
                    .font(.caption)
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            } else {
                Button(action: onRegenerate) {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.secondary)

                Button("Cancel", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            }
        }
        .padding(Spacing.sm.rawValue)
        .background(Color.bgSecondary(scheme: colorScheme))
        .cornerRadius(CornerRadius.sm.rawValue)
    }
}

// MARK: - Message Variations View

public struct MessageVariationsView: View {
    @Environment(\.colorScheme) private var colorScheme

    let variations: [ChatMessage]
    @Binding var selectedIndex: Int

    public init(variations: [ChatMessage], selectedIndex: Binding<Int>) {
        self.variations = variations
        self._selectedIndex = selectedIndex
    }

    public var body: some View {
        HStack(spacing: Spacing.xs.rawValue) {
            // Previous variation
            Button {
                if selectedIndex > 0 {
                    selectedIndex -= 1
                }
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)
            .disabled(selectedIndex == 0)
            .foregroundColor(selectedIndex > 0 ? Color.fgSecondary(scheme: colorScheme) : Color.fgTertiary(scheme: colorScheme))

            // Variation indicator
            Text("\(selectedIndex + 1) of \(variations.count)")
                .font(.caption)
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))

            // Next variation
            Button {
                if selectedIndex < variations.count - 1 {
                    selectedIndex += 1
                }
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
            .disabled(selectedIndex == variations.count - 1)
            .foregroundColor(selectedIndex < variations.count - 1 ? Color.fgSecondary(scheme: colorScheme) : Color.fgTertiary(scheme: colorScheme))
        }
        .padding(.horizontal, Spacing.sm.rawValue)
        .padding(.vertical, Spacing.xs.rawValue)
        .background(Color.bgTertiary(scheme: colorScheme))
        .cornerRadius(CornerRadius.sm.rawValue)
    }
}

// MARK: - ChatMessage Extension for Variations

extension ChatMessage {
    /// Whether this message has variations (multiple versions)
    public var hasVariations: Bool {
        // In a full implementation, this would check for stored variations
        false
    }

    /// Get all variations of this message
    public var variations: [ChatMessage] {
        // In a full implementation, this would return stored variations
        [self]
    }
}

// MARK: - Delete Message Confirmation Sheet

public struct DeleteMessageSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    let message: ChatMessage
    let onConfirm: () -> Void

    @State private var deleteFollowing: Bool = false

    public init(message: ChatMessage, onConfirm: @escaping () -> Void) {
        self.message = message
        self.onConfirm = onConfirm
    }

    public var body: some View {
        VStack(spacing: Spacing.lg.rawValue) {
            // Icon
            Image(systemName: "trash.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentError)

            // Title
            Text("Delete Message?")
                .font(.title2)
                .fontWeight(.semibold)

            // Description
            Text("This will permanently delete this message from the conversation.")
                .font(.callout)
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                .multilineTextAlignment(.center)

            // Message preview
            VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
                Text("Message:")
                    .font(.caption)
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))

                Text(message.content.prefix(100) + (message.content.count > 100 ? "..." : ""))
                    .font(.callout)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                    .padding(Spacing.sm.rawValue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.bgSecondary(scheme: colorScheme))
                    .cornerRadius(CornerRadius.sm.rawValue)
            }

            // Delete following option
            Toggle("Also delete all messages after this one", isOn: $deleteFollowing)
                .toggleStyle(.checkbox)
                .font(.callout)

            // Actions
            HStack(spacing: Spacing.md.rawValue) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.secondary)

                Button("Delete", role: .destructive) {
                    onConfirm()
                    dismiss()
                }
                .buttonStyle(.primary)
            }
        }
        .padding(Spacing.xl.rawValue)
        .frame(width: 400)
        .background(Color.bgPrimary(scheme: colorScheme))
    }
}

// MARK: - Preview

#Preview("Message Context Menu") {
    VStack {
        Text("Right-click for context menu")
            .padding()
            .background(Color.gray.opacity(0.2))
            .contextMenu {
                MessageContextMenu(
                    message: .user("Hello, Claude!"),
                    delegate: nil
                )
            }
    }
    .frame(width: 300, height: 200)
}
