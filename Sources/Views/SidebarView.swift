// SidebarView.swift
// Claude Desktop Mac - Sidebar View
//
// Displays session list and navigation

import SwiftUI
import Theme
import Models
import ViewModels

// MARK: - Sidebar View

public struct SidebarView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.highContrast) private var highContrast

    @Bindable var viewModel: SessionListViewModel
    let isCollapsed: Bool

    @State private var hoveredSessionId: UUID?
    @FocusState private var focusedSessionId: UUID?

    public init(viewModel: SessionListViewModel, isCollapsed: Bool = false) {
        self.viewModel = viewModel
        self.isCollapsed = isCollapsed
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            SidebarHeader(
                isCollapsed: isCollapsed,
                onNewSession: { viewModel.createSession() },
                onToggleCollapse: {} // Handled by parent
            )

            Divider()
                .background(Color.fgTertiary(scheme: colorScheme).opacity(0.3))

            // Session list
            if isCollapsed {
                CollapsedSidebarContent(
                    viewModel: viewModel,
                    hoveredSessionId: $hoveredSessionId,
                    focusedSessionId: $focusedSessionId
                )
            } else {
                ExpandedSidebarContent(
                    viewModel: viewModel,
                    hoveredSessionId: $hoveredSessionId,
                    focusedSessionId: $focusedSessionId
                )
            }

            Divider()
                .background(Color.fgTertiary(scheme: colorScheme).opacity(0.3))

            // Footer
            SidebarFooter(isCollapsed: isCollapsed)
        }
        .background(Color.bgSecondary(scheme: colorScheme))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sessions sidebar")
    }
}

// MARK: - Sidebar Header

struct SidebarHeader: View {
    @Environment(\.colorScheme) private var colorScheme

    let isCollapsed: Bool
    let onNewSession: () -> Void
    let onToggleCollapse: () -> Void

    var body: some View {
        HStack {
            if !isCollapsed {
                Text("Sessions")
                    .font(.headline)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                Spacer()

                Button(action: onNewSession) {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                }
                .buttonStyle(.icon)
                .accessibilityLabel("New session")
                .accessibilityHint("Double tap to create a new chat session")
                .help("New Session (Cmd+N)")
            } else {
                Button(action: onNewSession) {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                }
                .buttonStyle(.icon)
                .accessibilityLabel("New session")
                .accessibilityHint("Double tap to create a new chat session")
                .help("New Session")
            }
        }
        .padding(.horizontal, Spacing.md.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
    }
}

// MARK: - Expanded Sidebar Content

struct ExpandedSidebarContent: View {
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var viewModel: SessionListViewModel
    @Binding var hoveredSessionId: UUID?
    var focusedSessionId: FocusState<UUID?>.Binding

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.xs.rawValue) {
                ForEach(viewModel.filteredSessions) { session in
                    SessionRowView(
                        session: session,
                        isSelected: viewModel.selectedSessionId == session.id,
                        isHovered: hoveredSessionId == session.id,
                        isRenaming: viewModel.renamingSessionId == session.id,
                        newTitle: $viewModel.newTitle
                    )
                    .focused(focusedSessionId, equals: session.id)
                    .onTapGesture {
                        viewModel.selectSession(session.id)
                    }
                    .onHover { isHovered in
                        hoveredSessionId = isHovered ? session.id : nil
                    }
                    .contextMenu {
                        Button("Rename") {
                            viewModel.startRenaming(session.id)
                        }

                        Button("Duplicate") {
                            viewModel.duplicateSession(session.id)
                        }

                        Divider()

                        Button("Delete", role: .destructive) {
                            viewModel.deleteSession(session.id)
                        }
                    }
                    .onSubmit {
                        if viewModel.renamingSessionId == session.id {
                            viewModel.completeRenaming()
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.sm.rawValue)
            .padding(.vertical, Spacing.sm.rawValue)
        }
        .scrollIndicators(.automatic)
        .accessibilityLabel("Session list")

        // Search bar
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))

            TextField("Search sessions...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(.captionText)
                .foregroundColor(Color.fgPrimary(scheme: colorScheme))
        }
        .padding(.horizontal, Spacing.md.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
        .background(Color.bgTertiary(scheme: colorScheme).opacity(0.5))
        .padding(.horizontal, Spacing.sm.rawValue)
        .padding(.bottom, Spacing.sm.rawValue)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Search sessions")
        .accessibilityHint("Type to filter your session history")
    }
}

// MARK: - Collapsed Sidebar Content

struct CollapsedSidebarContent: View {
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var viewModel: SessionListViewModel
    @Binding var hoveredSessionId: UUID?
    var focusedSessionId: FocusState<UUID?>.Binding

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.xs.rawValue) {
                ForEach(viewModel.filteredSessions.prefix(10)) { session in
                    CollapsedSessionRow(
                        session: session,
                        isSelected: viewModel.selectedSessionId == session.id,
                        isHovered: hoveredSessionId == session.id
                    )
                    .focused(focusedSessionId, equals: session.id)
                    .onTapGesture {
                        viewModel.selectSession(session.id)
                    }
                    .onHover { isHovered in
                        hoveredSessionId = isHovered ? session.id : nil
                    }
                }
            }
            .padding(.vertical, Spacing.sm.rawValue)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Session Row View

struct SessionRowView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.highContrast) private var highContrast

    let session: Session
    let isSelected: Bool
    let isHovered: Bool
    let isRenaming: Bool
    @Binding var newTitle: String

    var body: some View {
        HStack(spacing: Spacing.sm.rawValue) {
            // Icon
            Image(systemName: "message.fill")
                .font(.system(size: 14))
                .foregroundColor(isSelected ? Color.accentPrimary : Color.fgSecondary(scheme: colorScheme))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                // Title
                if isRenaming {
                    TextField("Session name", text: $newTitle)
                        .textFieldStyle(.plain)
                        .font(.sessionTitle)
                        .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                        .onSubmit {
                            // Handled by parent
                        }
                } else {
                    Text(session.title)
                        .font(.sessionTitle)
                        .foregroundColor(isSelected ? Color.fgPrimary(scheme: colorScheme) : Color.fgSecondary(scheme: colorScheme))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                // Subtitle
                HStack(spacing: Spacing.xs.rawValue) {
                    if let projectName = session.projectName {
                        Text(projectName)
                            .font(.sessionSubtitle)
                            .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(session.relativeTime)
                        .font(.sessionTimestamp)
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.sm.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md.rawValue)
                .fill(isSelected ? Color.bgSelected(scheme: colorScheme) :
                      isHovered ? Color.bgHover(scheme: colorScheme) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md.rawValue)
                .stroke(highContrastBorder, lineWidth: highContrastBorderWidth)
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(sessionAccessibilityLabel)
        .accessibilityHint("Double tap to open session")
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var sessionAccessibilityLabel: String {
        var label = session.title
        if let projectName = session.projectName {
            label += ", \(projectName)"
        }
        label += ", \(session.relativeTime)"
        return label
    }

    private var highContrastBorder: Color {
        if highContrast {
            return isSelected ? Color.accentPrimaryAccessible() : Color.fgTertiary(scheme: colorScheme).opacity(0.5)
        }
        return Color.clear
    }

    private var highContrastBorderWidth: CGFloat {
        highContrast ? 2 : 0
    }
}

// MARK: - Collapsed Session Row

struct CollapsedSessionRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.highContrast) private var highContrast

    let session: Session
    let isSelected: Bool
    let isHovered: Bool

    var body: some View {
        VStack(spacing: Spacing.xs.rawValue) {
            Image(systemName: "message.fill")
                .font(.system(size: 16))
                .foregroundColor(isSelected ? Color.accentPrimary : Color.fgSecondary(scheme: colorScheme))
                .accessibilityHidden(true)

            // Show first letter of title
            Text(String(session.title.prefix(1)))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))
        }
        .frame(width: 36, height: 36)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md.rawValue)
                .fill(isSelected ? Color.bgSelected(scheme: colorScheme) :
                      isHovered ? Color.bgHover(scheme: colorScheme) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md.rawValue)
                .stroke(highContrastBorder, lineWidth: highContrastBorderWidth)
        )
        .contentShape(Rectangle())
        .accessibilityLabel("\(session.title)")
        .accessibilityHint("Double tap to open session")
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var highContrastBorder: Color {
        if highContrast {
            return isSelected ? Color.accentPrimaryAccessible() : Color.fgTertiary(scheme: colorScheme).opacity(0.5)
        }
        return Color.clear
    }

    private var highContrastBorderWidth: CGFloat {
        highContrast ? 2 : 0
    }
}

// MARK: - Sidebar Footer

struct SidebarFooter: View {
    @Environment(\.colorScheme) private var colorScheme

    let isCollapsed: Bool

    var body: some View {
        HStack {
            if !isCollapsed {
                Button(action: {}) {
                    Label("Settings", systemImage: "gearshape")
                        .font(.captionText)
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(.horizontal, Spacing.md.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
    }
}

// MARK: - Preview

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 0) {
            SidebarView(
                viewModel: {
                    let vm = SessionListViewModel()
                    vm.sessions = Session.samples
                    return vm
                }()
            )
            .frame(width: WindowDimensions.sidebarWidth)

            Color.bgPrimaryDark
        }
        .frame(width: 600, height: 600)
    }
}
