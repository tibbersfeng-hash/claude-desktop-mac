// MCPManagerView.swift
// Claude Desktop Mac - MCP Manager View
//
// UI for managing MCP Server configurations

import SwiftUI
import Theme
import Models
import ViewModels

// MARK: - MCP Manager View

public struct MCPManagerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: MCPManagerViewModel

    public init(viewModel: MCPManagerViewModel = MCPManagerViewModel()) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            MCPHeaderBar(
                onAdd: { viewModel.prepareNewServer() },
                onRefresh: { viewModel.loadServers() }
            )

            Divider()
                .background(Color.fgTertiary(scheme: colorScheme).opacity(0.3))

            // Messages
            if let error = viewModel.errorMessage {
                MessageBanner(message: error, type: .error) {
                    viewModel.clearMessages()
                }
            }

            if let success = viewModel.successMessage {
                MessageBanner(message: success, type: .success) {
                    viewModel.clearMessages()
                }
            }

            // Content
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.servers.isEmpty {
                EmptyStateView(onAdd: { viewModel.prepareNewServer() })
            } else {
                ServerListView(viewModel: viewModel)
            }
        }
        .frame(width: 600, height: 500)
        .background(Color.bgPrimary(scheme: colorScheme))
        .sheet(isPresented: $viewModel.showServerSheet) {
            MCPServerSheet(viewModel: viewModel)
        }
        .alert("Delete Server", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelDelete()
            }
            Button("Delete", role: .destructive) {
                if let server = viewModel.serverToDelete {
                    viewModel.deleteServer(server)
                }
            }
        } message: {
            if let server = viewModel.serverToDelete {
                Text("Are you sure you want to delete '\(server.name)'? This action cannot be undone.")
            }
        }
    }
}

// MARK: - Header Bar

struct MCPHeaderBar: View {
    @Environment(\.colorScheme) private var colorScheme

    let onAdd: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        HStack {
            HStack(spacing: Spacing.sm.rawValue) {
                Image(systemName: "server.rack")
                    .font(.system(size: 20))
                    .foregroundColor(.accentPrimary)

                Text("MCP Servers")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))
            }

            Spacer()

            HStack(spacing: Spacing.sm.rawValue) {
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                }
                .buttonStyle(.icon)
                .help("Refresh")

                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                }
                .buttonStyle(.icon)
                .help("Add Server")
            }
        }
        .padding(.horizontal, Spacing.lg.rawValue)
        .padding(.vertical, Spacing.md.rawValue)
    }
}

// MARK: - Message Banner

struct MessageBanner: View {
    @Environment(\.colorScheme) private var colorScheme

    let message: String
    let type: MessageType
    let onDismiss: () -> Void

    enum MessageType {
        case error, success, warning

        var color: Color {
            switch self {
            case .error: return .accentError
            case .success: return .accentSuccess
            case .warning: return .accentWarning
            }
        }

        var iconName: String {
            switch self {
            case .error: return "xmark.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: Spacing.sm.rawValue) {
            Image(systemName: type.iconName)
                .foregroundColor(type.color)

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(Color.fgPrimary(scheme: colorScheme))

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.lg.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
        .background(type.color.opacity(0.1))
    }
}

// MARK: - Loading View

struct LoadingView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: Spacing.lg.rawValue) {
            ProgressView()
                .progressViewStyle(.circular)

            Text("Loading MCP Servers...")
                .font(.system(size: 14))
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    @Environment(\.colorScheme) private var colorScheme

    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg.rawValue) {
            Image(systemName: "server.rack")
                .font(.system(size: 48))
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))

            VStack(spacing: Spacing.sm.rawValue) {
                Text("No MCP Servers Configured")
                    .font(.headline)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                Text("Add your first MCP server to extend Claude's capabilities")
                    .font(.system(size: 14))
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                    .multilineTextAlignment(.center)
            }

            Button(action: onAdd) {
                Label("Add Server", systemImage: "plus")
            }
            .buttonStyle(.primary)
        }
        .padding(Spacing.xl.rawValue)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Server List View

struct ServerListView: View {
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var viewModel: MCPManagerViewModel

    @State private var hoveredServerId: UUID?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm.rawValue) {
                ForEach(viewModel.servers) { server in
                    ServerRowView(
                        server: server,
                        isHovered: hoveredServerId == server.id,
                        onToggle: { viewModel.toggleServer(server) },
                        onEdit: { viewModel.prepareEditServer(server) },
                        onDuplicate: { viewModel.duplicateServer(server) },
                        onDelete: { viewModel.confirmDelete(server) }
                    )
                    .onHover { isHovered in
                        hoveredServerId = isHovered ? server.id : nil
                    }
                }
            }
            .padding(Spacing.lg.rawValue)
        }
        .scrollIndicators(.automatic)
    }
}

// MARK: - Server Row View

struct ServerRowView: View {
    @Environment(\.colorScheme) private var colorScheme

    let server: MCPServer
    let isHovered: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md.rawValue) {
            // Enable Toggle
            Toggle("", isOn: Binding(
                get: { server.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
            .labelsHidden()

            // Server Type Icon
            Image(systemName: server.serverType.iconName)
                .font(.system(size: 16))
                .foregroundColor(server.isEnabled ? .accentPrimary : Color.fgTertiary(scheme: colorScheme))
                .frame(width: 24)

            // Server Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.sm.rawValue) {
                    Text(server.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(server.isEnabled ? Color.fgPrimary(scheme: colorScheme) : Color.fgSecondary(scheme: colorScheme))

                    // Type Badge
                    Text(server.serverType.displayName)
                        .font(.system(size: 10))
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                        .padding(.horizontal, Spacing.xs.rawValue)
                        .padding(.vertical, 2)
                        .background(Color.bgTertiary(scheme: colorScheme))
                        .cornerRadius(CornerRadius.sm.rawValue)
                }

                // Command or URL
                Text(server.serverType == .stdio
                     ? (server.command ?? "No command")
                     : (server.url ?? "No URL"))
                    .font(.system(size: 12))
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            // Actions
            if isHovered {
                HStack(spacing: Spacing.xs.rawValue) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                    }
                    .buttonStyle(.icon(size: 24))
                    .help("Edit")

                    Button(action: onDuplicate) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                    }
                    .buttonStyle(.icon(size: 24))
                    .help("Duplicate")

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.accentError)
                    }
                    .buttonStyle(.icon(size: 24))
                    .help("Delete")
                }
            }
        }
        .padding(.horizontal, Spacing.md.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md.rawValue)
                .fill(isHovered ? Color.bgHover(scheme: colorScheme) : Color.bgSecondary(scheme: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md.rawValue)
                .stroke(Color.fgTertiary(scheme: colorScheme).opacity(0.2), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Server Sheet (Add/Edit)

struct MCPServerSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @Bindable var viewModel: MCPManagerViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Sheet Header
            HStack {
                Text(viewModel.isEditing ? "Edit Server" : "Add Server")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.lg.rawValue)

            Divider()
                .background(Color.fgTertiary(scheme: colorScheme).opacity(0.3))

            // Form Content
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg.rawValue) {
                    // Server Name
                    FormField(label: "Server Name", required: true) {
                        TextField("e.g., memory, github, kubernetes", text: $viewModel.formName)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Server Type
                    FormField(label: "Type") {
                        Picker("", selection: $viewModel.formServerType) {
                            ForEach(MCPServerType.allCases, id: \.self) { type in
                                HStack(spacing: Spacing.sm.rawValue) {
                                    Image(systemName: type.iconName)
                                    Text(type.displayName)
                                }
                                .tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 300)
                    }

                    // Enabled Toggle
                    HStack {
                        Toggle("Enabled", isOn: $viewModel.formIsEnabled)
                            .toggleStyle(.switch)
                        Spacer()
                    }

                    Divider()
                        .background(Color.fgTertiary(scheme: colorScheme).opacity(0.3))

                    // Type-specific fields
                    if viewModel.formServerType == .stdio {
                        StdioFields(viewModel: viewModel)
                    } else {
                        SSEFields(viewModel: viewModel)
                    }
                }
                .padding(Spacing.lg.rawValue)
            }
            .scrollIndicators(.automatic)

            Divider()
                .background(Color.fgTertiary(scheme: colorScheme).opacity(0.3))

            // Footer
            HStack {
                if let error = viewModel.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.accentError)
                }

                Spacer()

                Button("Cancel") {
                    viewModel.resetForm()
                    dismiss()
                }
                .buttonStyle(.secondary)

                Button(viewModel.isEditing ? "Save" : "Add") {
                    if viewModel.isEditing {
                        viewModel.updateServer()
                    } else {
                        viewModel.addServer()
                    }

                    if !viewModel.showServerSheet {
                        dismiss()
                    }
                }
                .buttonStyle(.primary)
                .disabled(!viewModel.isFormValid)
            }
            .padding(Spacing.lg.rawValue)
        }
        .frame(width: 500, height: 550)
        .background(Color.bgPrimary(scheme: colorScheme))
    }
}

// MARK: - Form Field

struct FormField<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let label: String
    let required: Bool
    @ViewBuilder let content: () -> Content

    init(label: String, required: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.required = required
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
            HStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                if required {
                    Text("*")
                        .foregroundColor(.accentError)
                }
            }

            content()
        }
    }
}

// MARK: - Stdio Fields

struct StdioFields: View {
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var viewModel: MCPManagerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg.rawValue) {
            FormField(label: "Command", required: true) {
                TextField("e.g., node, python, /path/to/executable", text: $viewModel.formCommand)
                    .textFieldStyle(.roundedBorder)
            }

            FormField(label: "Arguments") {
                TextField("Space-separated arguments", text: $viewModel.formArgs)
                    .textFieldStyle(.roundedBorder)

                Text("Use \${VARIABLE} syntax for environment variable substitution")
                    .font(.system(size: 11))
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
            }

            FormField(label: "Environment Variables") {
                TextEditor(text: $viewModel.formEnv)
                    .frame(height: 80)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(4)
                    .background(Color.bgTertiary(scheme: colorScheme))
                    .cornerRadius(CornerRadius.sm.rawValue)

                Text("One per line: KEY=value")
                    .font(.system(size: 11))
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
            }
        }
    }
}

// MARK: - SSE Fields

struct SSEFields: View {
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var viewModel: MCPManagerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg.rawValue) {
            FormField(label: "URL", required: true) {
                TextField("https://mcp-server.example.com/sse", text: $viewModel.formUrl)
                    .textFieldStyle(.roundedBorder)
            }

            FormField(label: "Headers") {
                TextEditor(text: $viewModel.formHeaders)
                    .frame(height: 80)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(4)
                    .background(Color.bgTertiary(scheme: colorScheme))
                    .cornerRadius(CornerRadius.sm.rawValue)

                Text("One per line: Header-Name: value")
                    .font(.system(size: 11))
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
            }
        }
    }
}

// MARK: - Previews

#Preview("MCP Manager - Empty") {
    MCPManagerView(viewModel: MCPManagerViewModel())
}

#Preview("MCP Manager - With Servers") {
    MCPManagerView(viewModel: MCPManagerViewModel.preview)
}
