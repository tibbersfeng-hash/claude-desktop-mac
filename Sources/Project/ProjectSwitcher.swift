// ProjectSwitcher.swift
// Claude Desktop Mac - Project Switcher
//
// UI for switching between projects

import SwiftUI
import Combine
import Theme

// MARK: - Project Picker View

/// A view for quickly switching between projects with enhanced features
public struct ProjectPickerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @Bindable var projectManager: ProjectManager
    @State private var searchText: String = ""
    @State private var showAddProject: Bool = false
    @State private var showManageProjects: Bool = false
    @State private var isRefreshing: Bool = false

    let onSelect: (Project) -> Void

    public init(projectManager: ProjectManager, onSelect: @escaping (Project) -> Void) {
        self.projectManager = projectManager
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            sortOptionsBar
            Divider()
            projectList
            Divider()
            footerActions
        }
        .frame(width: 400)
        .frame(maxHeight: 500)
        .sheet(isPresented: $showAddProject) {
            AddProjectSheet(projectManager: projectManager)
        }
        .sheet(isPresented: $showManageProjects) {
            ProjectManagementView(projectManager: projectManager)
        }
        .onChange(of: searchText) { _, newValue in
            projectManager.searchText = newValue
        }
        .task {
            await refreshGitStatus()
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var searchField: some View {
        HStack(spacing: Spacing.sm.rawValue) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))

            TextField("Search by name or path...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.bodyText)

            if isRefreshing {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 16, height: 16)
            }
        }
        .padding(Spacing.sm.rawValue)
        .background(Color.bgSecondary(scheme: colorScheme))
    }

    @ViewBuilder
    private var sortOptionsBar: some View {
        HStack(spacing: Spacing.sm.rawValue) {
            Text("Sort by:")
                .font(.caption)
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))

            ForEach(ProjectSortOption.allCases) { option in
                Button(action: {
                    projectManager.setSortOption(option)
                }) {
                    Text(option.rawValue)
                        .font(.caption)
                        .foregroundColor(projectManager.sortOption == option ? .accentPrimary : Color.fgSecondary(scheme: colorScheme))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(projectManager.sortOption == option ? Color.accentPrimary.opacity(0.15) : Color.clear)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Text("\(projectManager.filteredProjects.count) projects")
                .font(.caption)
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))
        }
        .padding(.horizontal, Spacing.sm.rawValue)
        .padding(.vertical, Spacing.xs.rawValue)
        .background(Color.bgTertiary(scheme: colorScheme))
    }

    @ViewBuilder
    private var projectList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Recent projects section (if any)
                recentProjectsSection

                // Favorites section
                favoritesSection

                // All projects section
                allProjectsSection

                // Empty state
                emptyStateSection
            }
            .padding(Spacing.sm.rawValue)
        }
    }

    @ViewBuilder
    private var recentProjectsSection: some View {
        let recent = projectManager.recentProjects.filter { !$0.isFavorite }.prefix(3)
        if !recent.isEmpty && searchText.isEmpty {
            Section("Recent") {
                ForEach(recent) { project in
                    ProjectItemView(
                        project: project,
                        isSelected: projectManager.currentProject?.id == project.id,
                        onSelect: { selectProject(project) },
                        onToggleFavorite: { projectManager.toggleFavorite(project.id) },
                        onDelete: { projectManager.removeProject(project.id) }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var favoritesSection: some View {
        if !favoriteProjects.isEmpty {
            Section("Favorites") {
                ForEach(favoriteProjects) { project in
                    ProjectItemView(
                        project: project,
                        isSelected: projectManager.currentProject?.id == project.id,
                        onSelect: { selectProject(project) },
                        onToggleFavorite: { projectManager.toggleFavorite(project.id) },
                        onDelete: { projectManager.removeProject(project.id) }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var allProjectsSection: some View {
        if !otherProjects.isEmpty {
            let hasFavorites = !favoriteProjects.isEmpty
            let hasRecent = !projectManager.recentProjects.filter({ !$0.isFavorite }).isEmpty && searchText.isEmpty
            Section(hasFavorites || hasRecent ? "All Projects" : "") {
                ForEach(otherProjects) { project in
                    ProjectItemView(
                        project: project,
                        isSelected: projectManager.currentProject?.id == project.id,
                        onSelect: { selectProject(project) },
                        onToggleFavorite: { projectManager.toggleFavorite(project.id) },
                        onDelete: { projectManager.removeProject(project.id) }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var emptyStateSection: some View {
        if projectManager.projects.isEmpty {
            emptyStateView
        }
    }

    @ViewBuilder
    private var footerActions: some View {
        HStack {
            Button(action: { showAddProject = true }) {
                Label("Add Project", systemImage: "plus")
            }
            .buttonStyle(.secondary)

            Button(action: {
                Task {
                    await refreshGitStatus()
                }
            }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.secondary)
            .help("Refresh Git status")

            Spacer()

            if !projectManager.projects.isEmpty {
                Button("Manage All...") {
                    showManageProjects = true
                }
                .buttonStyle(.secondary)
            }
        }
        .padding(Spacing.sm.rawValue)
        .background(Color.bgSecondary(scheme: colorScheme))
    }

    private var favoriteProjects: [Project] {
        projectManager.filteredProjects.filter { $0.isFavorite }
    }

    private var otherProjects: [Project] {
        let recent = Set(projectManager.recentProjects.prefix(3).map(\.id))
        return projectManager.filteredProjects.filter { !$0.isFavorite && !recent.contains($0.id) }
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.md.rawValue) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))

            Text("No Projects")
                .font(.headline)
                .foregroundColor(Color.fgPrimary(scheme: colorScheme))

            Text("Add a project directory to get started")
                .font(.caption)
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))

            Button("Add Project") {
                showAddProject = true
            }
            .buttonStyle(.primary)
        }
        .padding()
    }

    private func selectProject(_ project: Project) {
        projectManager.switchToProject(project)
        onSelect(project)
        dismiss()
    }

    private func refreshGitStatus() async {
        isRefreshing = true
        await projectManager.refreshAllGitStatus()
        isRefreshing = false
    }
}

// MARK: - Add Project Sheet

/// A sheet for adding new projects
public struct AddProjectSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @Bindable var projectManager: ProjectManager

    @State private var selectedPath: URL?
    @State private var projectName: String = ""
    @State private var showFilePicker = false

    public init(projectManager: ProjectManager) {
        self.projectManager = projectManager
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Project")
                    .font(.headline)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.bgSecondary(scheme: colorScheme))

            Divider()

            // Content
            VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
                // Path selection
                VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
                    Text("Project Directory")
                        .font(.caption)
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))

                    HStack {
                        Text(selectedPath?.path ?? "Select a directory...")
                            .font(.bodyText)
                            .foregroundColor(selectedPath == nil ? Color.fgTertiary(scheme: colorScheme) : Color.fgPrimary(scheme: colorScheme))
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Spacer()

                        Button("Browse...") {
                            showFilePicker = true
                        }
                        .buttonStyle(.secondary)
                    }
                    .padding(Spacing.sm.rawValue)
                    .background(Color.bgTertiary(scheme: colorScheme))
                    .cornerRadius(CornerRadius.md.rawValue)
                }

                // Project name
                VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
                    Text("Project Name")
                        .font(.caption)
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))

                    TextField("Project name", text: $projectName)
                        .textFieldStyle(.plain)
                        .font(.bodyText)
                        .padding(Spacing.sm.rawValue)
                        .background(Color.bgTertiary(scheme: colorScheme))
                        .cornerRadius(CornerRadius.md.rawValue)
                }

                // Info
                if let path = selectedPath {
                    HStack(spacing: Spacing.sm.rawValue) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.accentPrimary)

                        VStack(alignment: .leading, spacing: 2) {
                            if FileManager.default.fileExists(atPath: path.appendingPathComponent("CLAUDE.md").path) {
                                Text("CLAUDE.md found - configuration will be loaded")
                                    .font(.caption)
                                    .foregroundColor(.accentSuccess)
                            } else {
                                Text("No CLAUDE.md - you can create one after adding")
                                    .font(.caption)
                                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                            }
                        }
                    }
                    .padding(Spacing.sm.rawValue)
                    .background(Color.accentPrimary.opacity(0.1))
                    .cornerRadius(CornerRadius.md.rawValue)
                }
            }
            .padding()

            Divider()

            // Footer
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.secondary)

                Spacer()

                Button("Add Project") {
                    if let path = selectedPath {
                        let name = projectName.isEmpty ? path.lastPathComponent : projectName
                        let project = Project(name: name, path: path)
                        projectManager.addProject(project)
                        dismiss()
                    }
                }
                .buttonStyle(.primary)
                .disabled(selectedPath == nil)
            }
            .padding()
            .background(Color.bgSecondary(scheme: colorScheme))
        }
        .frame(width: 450, height: 300)
        .background(Color.bgPrimary(scheme: colorScheme))
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    selectedPath = url
                    if projectName.isEmpty {
                        projectName = url.lastPathComponent
                    }
                }
            case .failure(let error):
                print("Failed to select directory: \(error)")
            }
        }
    }
}

// MARK: - Quick Project Switcher

/// A quick project switcher (Cmd+P style)
public struct QuickProjectSwitcher: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @Bindable var projectManager: ProjectManager
    @State private var searchText: String = ""

    let onSelect: (Project) -> Void

    public init(projectManager: ProjectManager, onSelect: @escaping (Project) -> Void) {
        self.projectManager = projectManager
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: Spacing.sm.rawValue) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))

                TextField("Switch to project...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.bodyText)
                    .onSubmit {
                        if let first = filteredProjects.first {
                            selectProject(first)
                        }
                    }
            }
            .padding()
            .background(Color.bgSecondary(scheme: colorScheme))

            Divider()

            // Projects
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredProjects.prefix(10)) { project in
                        QuickProjectRow(
                            project: project,
                            isSelected: projectManager.currentProject?.id == project.id,
                            colorScheme: colorScheme,
                            onSelect: { selectProject(project) }
                        )
                    }

                    if filteredProjects.isEmpty {
                        Text("No matching projects")
                            .font(.caption)
                            .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                            .padding()
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .frame(width: 400)
        .background(Color.bgPrimary(scheme: colorScheme))
        .cornerRadius(CornerRadius.lg.rawValue)
        .shadow(AppShadow.lg)
        .onChange(of: searchText) { _, newValue in
            projectManager.searchText = newValue
        }
    }

    private var filteredProjects: [Project] {
        if searchText.isEmpty {
            return projectManager.projects.sorted { ($0.lastAccessedAt ?? .distantPast) > ($1.lastAccessedAt ?? .distantPast) }
        }
        return projectManager.filteredProjects
    }

    private func selectProject(_ project: Project) {
        projectManager.switchToProject(project)
        onSelect(project)
        dismiss()
    }
}

// MARK: - Quick Project Row

private struct QuickProjectRow: View {
    let project: Project
    let isSelected: Bool
    let colorScheme: ColorScheme
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Spacing.md.rawValue) {
            Image(systemName: project.isFavorite ? "star.fill" : "folder")
                .foregroundColor(project.isFavorite ? .yellow : .accentPrimary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.callout)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                Text(project.relativeAccessTime)
                    .font(.caption2)
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
            }

            Spacer()

            if project.hasClaudeMd {
                Image(systemName: "doc.text")
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                    .font(.caption)
            }

            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentPrimary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, Spacing.sm.rawValue)
        .background(isSelected ? Color.accentPrimary.opacity(0.1) : (isHovered ? Color.bgHover(scheme: colorScheme) : Color.clear))
        .onTapGesture(perform: onSelect)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Project Status Indicator

/// Shows the current project in the toolbar
public struct ProjectStatusIndicator: View {
    @Environment(\.colorScheme) private var colorScheme

    let project: Project?
    let onTap: () -> Void

    @State private var isHovered = false

    public init(project: Project?, onTap: @escaping () -> Void) {
        self.project = project
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.xs.rawValue) {
                Image(systemName: project?.isFavorite == true ? "star.fill" : "folder.fill")
                    .foregroundColor(project?.isFavorite == true ? .yellow : .accentPrimary)

                Text(project?.name ?? "No Project")
                    .font(.callout)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                // Git branch indicator
                if let branch = project?.gitBranch {
                    HStack(spacing: 2) {
                        Image(systemName: "git.branch")
                            .font(.system(size: 8))
                        Text(branch)
                            .font(.system(size: 9))
                    }
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.bgTertiary(scheme: colorScheme))
                    .cornerRadius(3)
                }

                // Changes indicator
                if project?.hasUncommittedChanges == true {
                    Circle()
                        .fill(Color.accentWarning)
                        .frame(width: 6, height: 6)
                }

                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            }
            .padding(.horizontal, Spacing.sm.rawValue)
            .padding(.vertical, Spacing.xs.rawValue)
            .background(isHovered ? Color.bgHover(scheme: colorScheme) : Color.bgTertiary(scheme: colorScheme))
            .cornerRadius(CornerRadius.md.rawValue)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Project Management View

/// Full project management view with comprehensive features
public struct ProjectManagementView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @Bindable var projectManager: ProjectManager
    @State private var searchText: String = ""
    @State private var selectedProjectId: UUID?
    @State private var showAddProject: Bool = false
    @State private var isRefreshing: Bool = false
    @State private var editingProjectId: UUID?
    @State private var editingName: String = ""

    public init(projectManager: ProjectManager) {
        self.projectManager = projectManager
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Main content
            HSplitView {
                // Project list
                projectListView
                    .frame(minWidth: 300, maxWidth: 400)

                // Project details
                if let projectId = selectedProjectId,
                   let project = projectManager.getProject(projectId) {
                    ProjectDetailView(
                        project: project,
                        projectManager: projectManager,
                        onRename: { newName in
                            projectManager.renameProject(projectId, name: newName)
                        }
                    )
                    .frame(minWidth: 400)
                } else {
                    emptyDetailView
                        .frame(minWidth: 400)
                }
            }

            Divider()

            // Footer
            footerView
        }
        .frame(width: 800, height: 600)
        .background(Color.bgPrimary(scheme: colorScheme))
        .sheet(isPresented: $showAddProject) {
            AddProjectSheet(projectManager: projectManager)
        }
        .onChange(of: searchText) { _, newValue in
            projectManager.searchText = newValue
        }
        .task {
            await refreshGitStatus()
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerView: some View {
        HStack {
            Text("Project Management")
                .font(.headline)
                .foregroundColor(Color.fgPrimary(scheme: colorScheme))

            Spacer()

            HStack(spacing: Spacing.sm.rawValue) {
                // Search field
                HStack(spacing: Spacing.xs.rawValue) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                        .font(.caption)

                    TextField("Search projects...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.bodyText)
                        .frame(width: 200)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.bgTertiary(scheme: colorScheme))
                .cornerRadius(6)

                Button(action: { showAddProject = true }) {
                    Label("Add", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.secondary)

                Button(action: {
                    Task {
                        await refreshGitStatus()
                    }
                }) {
                    if isRefreshing {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.secondary)
                .help("Refresh Git status")

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.bgSecondary(scheme: colorScheme))
    }

    // MARK: - Project List

    @ViewBuilder
    private var projectListView: some View {
        VStack(spacing: 0) {
            // Sort options
            HStack(spacing: Spacing.sm.rawValue) {
                Text("Sort:")
                    .font(.caption)
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))

                Menu(projectManager.sortOption.rawValue) {
                    ForEach(ProjectSortOption.allCases) { option in
                        Button(option.rawValue) {
                            projectManager.setSortOption(option)
                        }
                    }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Spacer()

                Text("\(projectManager.filteredProjects.count) projects")
                    .font(.caption)
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
            }
            .padding(.horizontal)
            .padding(.vertical, Spacing.xs.rawValue)
            .background(Color.bgTertiary(scheme: colorScheme))

            Divider()

            // List
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Favorites section
                    if !projectManager.favoriteProjects.isEmpty {
                        sectionHeader("Favorites")
                        ForEach(projectManager.favoriteProjects) { project in
                            projectListRow(project)
                        }
                    }

                    // All projects section
                    let otherProjects = projectManager.filteredProjects.filter { !$0.isFavorite }
                    if !otherProjects.isEmpty {
                        sectionHeader(projectManager.favoriteProjects.isEmpty ? "All Projects" : "Other Projects")
                        ForEach(otherProjects) { project in
                            projectListRow(project)
                        }
                    }

                    // Empty state
                    if projectManager.filteredProjects.isEmpty && !projectManager.projects.isEmpty {
                        Text("No projects match your search")
                            .font(.caption)
                            .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                            .padding()
                    }

                    if projectManager.projects.isEmpty {
                        emptyListState
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, Spacing.xs.rawValue)
        .background(Color.bgSecondary(scheme: colorScheme))
    }

    @ViewBuilder
    private func projectListRow(_ project: Project) -> some View {
        HStack(spacing: Spacing.sm.rawValue) {
            // Selection indicator
            Circle()
                .fill(selectedProjectId == project.id ? Color.accentPrimary : Color.clear)
                .frame(width: 6, height: 6)

            // Icon
            Image(systemName: project.isFavorite ? "star.fill" : "folder.fill")
                .foregroundColor(project.isFavorite ? .yellow : .accentPrimary)
                .frame(width: 16)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.callout)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let branch = project.gitBranch {
                        HStack(spacing: 2) {
                            Image(systemName: "git.branch")
                                .font(.system(size: 8))
                            Text(branch)
                                .font(.system(size: 9))
                        }
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                    }

                    Text(project.relativeAccessTime)
                        .font(.caption2)
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                }
            }

            Spacer()

            // Status indicators
            HStack(spacing: 4) {
                if project.hasClaudeMd {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                }

                if project.hasUncommittedChanges {
                    Circle()
                        .fill(Color.accentWarning)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, Spacing.sm.rawValue)
        .background(selectedProjectId == project.id ? Color.accentPrimary.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedProjectId = project.id
        }
    }

    @ViewBuilder
    private var emptyListState: some View {
        VStack(spacing: Spacing.md.rawValue) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))

            Text("No Projects Yet")
                .font(.headline)
                .foregroundColor(Color.fgPrimary(scheme: colorScheme))

            Text("Add your first project to get started")
                .font(.caption)
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))

            Button("Add Project") {
                showAddProject = true
            }
            .buttonStyle(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Detail View

    @ViewBuilder
    private var emptyDetailView: some View {
        VStack(spacing: Spacing.md.rawValue) {
            Image(systemName: "sidebar.right")
                .font(.system(size: 40))
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))

            Text("Select a Project")
                .font(.headline)
                .foregroundColor(Color.fgPrimary(scheme: colorScheme))

            Text("Choose a project from the list to view details")
                .font(.caption)
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgPrimary(scheme: colorScheme))
    }

    // MARK: - Footer

    @ViewBuilder
    private var footerView: some View {
        HStack {
            if let projectId = selectedProjectId {
                Button("Remove from List") {
                    projectManager.removeProject(projectId)
                    selectedProjectId = nil
                }
                .buttonStyle(.secondary)
            }

            Spacer()

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.primary)
        }
        .padding()
        .background(Color.bgSecondary(scheme: colorScheme))
    }

    private func refreshGitStatus() async {
        isRefreshing = true
        await projectManager.refreshAllGitStatus()
        isRefreshing = false
    }
}

// MARK: - Project Detail View

/// Detailed view for a single project
private struct ProjectDetailView: View {
    @Environment(\.colorScheme) private var colorScheme

    let project: Project
    let projectManager: ProjectManager
    let onRename: (String) -> Void

    @State private var editedName: String = ""
    @State private var isEditingName: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg.rawValue) {
                // Header
                headerSection

                // Path section
                pathSection

                // Status section
                statusSection

                // Git section
                if project.isGitRepository {
                    gitSection
                }

                // CLAUDE.md section
                claudeMdSection

                // Activity section
                activitySection

                Spacer()
            }
            .padding()
        }
        .background(Color.bgPrimary(scheme: colorScheme))
        .onAppear {
            editedName = project.name
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var headerSection: some View {
        HStack(alignment: .top) {
            Image(systemName: project.isFavorite ? "star.fill" : "folder.fill")
                .font(.system(size: 32))
                .foregroundColor(project.isFavorite ? .yellow : .accentPrimary)

            VStack(alignment: .leading, spacing: 4) {
                if isEditingName {
                    TextField("Project name", text: $editedName)
                        .textFieldStyle(.plain)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                        .onSubmit {
                            if !editedName.isEmpty {
                                onRename(editedName)
                            }
                            isEditingName = false
                        }
                } else {
                    Text(project.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                        .onTapGesture(count: 2) {
                            isEditingName = true
                            editedName = project.name
                        }
                }

                Text("Double-click to rename")
                    .font(.caption2)
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
            }

            Spacer()

            // Favorite toggle
            Button(action: {
                projectManager.toggleFavorite(project.id)
            }) {
                Image(systemName: project.isFavorite ? "star.fill" : "star")
                    .foregroundColor(project.isFavorite ? .yellow : Color.fgSecondary(scheme: colorScheme))
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help(project.isFavorite ? "Remove from favorites" : "Add to favorites")
        }
    }

    @ViewBuilder
    private var pathSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
            Text("Path")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))

            HStack {
                Text(project.displayPath)
                    .font(.bodyText)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                    .textSelection(.enabled)

                Spacer()

                Button("Reveal in Finder") {
                    NSWorkspace.shared.selectFile(project.path.path, inFileViewerRootedAtPath: "")
                }
                .buttonStyle(.secondary)
                .font(.caption)
            }
            .padding()
            .background(Color.bgSecondary(scheme: colorScheme))
            .cornerRadius(CornerRadius.md.rawValue)
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
            Text("Status")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))

            HStack(spacing: Spacing.lg.rawValue) {
                // CLAUDE.md status
                statusItem(
                    icon: "doc.text.fill",
                    label: "CLAUDE.md",
                    value: project.hasClaudeMd ? "Present" : "Not found",
                    color: project.hasClaudeMd ? .accentSuccess : .accentWarning
                )

                // Git status
                statusItem(
                    icon: "git.branch",
                    label: "Git",
                    value: project.isGitRepository ? "Repository" : "Not a repo",
                    color: project.isGitRepository ? .accentSuccess : Color.fgTertiary(scheme: colorScheme)
                )

                // Sessions
                statusItem(
                    icon: "bubble.left.and.bubble.right.fill",
                    label: "Sessions",
                    value: "\(project.activeSessionCount)",
                    color: project.activeSessionCount > 0 ? .accentPrimary : Color.fgTertiary(scheme: colorScheme)
                )
            }
            .padding()
            .background(Color.bgSecondary(scheme: colorScheme))
            .cornerRadius(CornerRadius.md.rawValue)
        }
    }

    @ViewBuilder
    private func statusItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(label)
                .font(.caption2)
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var gitSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
            Text("Git Status")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))

            VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
                // Branch
                if let branch = project.gitBranch {
                    HStack {
                        Image(systemName: "git.branch")
                            .foregroundColor(.accentPrimary)
                            .frame(width: 20)

                        Text("Branch:")
                            .font(.bodyText)
                            .foregroundColor(Color.fgSecondary(scheme: colorScheme))

                        Text(branch)
                            .font(.bodyText)
                            .fontWeight(.medium)
                            .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                    }
                }

                // Sync status
                if let status = project.gitStatus {
                    HStack(spacing: Spacing.lg.rawValue) {
                        if status.aheadCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up")
                                    .font(.caption)
                                Text("\(status.aheadCount) ahead")
                                    .font(.caption)
                            }
                            .foregroundColor(.accentSuccess)
                        }

                        if status.behindCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down")
                                    .font(.caption)
                                Text("\(status.behindCount) behind")
                                    .font(.caption)
                            }
                            .foregroundColor(.accentOrange)
                        }

                        if status.aheadCount == 0 && status.behindCount == 0 {
                            Text("Up to date")
                                .font(.caption)
                                .foregroundColor(.accentSuccess)
                        }
                    }
                }

                // Modified files
                if project.hasUncommittedChanges {
                    HStack {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.accentWarning)
                            .frame(width: 20)

                        Text("\(project.modifiedFilesCount) modified file\(project.modifiedFilesCount == 1 ? "" : "s")")
                            .font(.bodyText)
                            .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                    }
                }
            }
            .padding()
            .background(Color.bgSecondary(scheme: colorScheme))
            .cornerRadius(CornerRadius.md.rawValue)
        }
    }

    @ViewBuilder
    private var claudeMdSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
            HStack {
                Text("CLAUDE.md Configuration")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))

                Spacer()

                if project.hasClaudeMd {
                    Button("Edit") {
                        // Open editor
                    }
                    .buttonStyle(.secondary)
                    .font(.caption)
                } else {
                    Button("Create") {
                        Task {
                            try? await projectManager.createDefaultClaudeMd(for: project)
                        }
                    }
                    .buttonStyle(.primary)
                    .font(.caption)
                }
            }

            HStack(spacing: Spacing.sm.rawValue) {
                Image(systemName: project.hasClaudeMd ? "checkmark.circle.fill" : "info.circle")
                    .foregroundColor(project.hasClaudeMd ? .accentSuccess : Color.fgTertiary(scheme: colorScheme))

                Text(project.hasClaudeMd
                     ? "Project configuration file is present"
                     : "No CLAUDE.md file - create one to customize Claude's behavior for this project")
                    .font(.caption)
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            }
            .padding()
            .background(Color.bgSecondary(scheme: colorScheme))
            .cornerRadius(CornerRadius.md.rawValue)
        }
    }

    @ViewBuilder
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
            Text("Activity")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))

            VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                        .frame(width: 20)

                    Text("Last accessed:")
                        .font(.bodyText)
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))

                    Text(project.relativeAccessTime)
                        .font(.bodyText)
                        .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                }

                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                        .frame(width: 20)

                    Text("Added:")
                        .font(.bodyText)
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))

                    Text(project.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.bodyText)
                        .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                }

                HStack {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                        .frame(width: 20)

                    Text("Active sessions:")
                        .font(.bodyText)
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))

                    Text("\(project.activeSessionCount)")
                        .font(.bodyText)
                        .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                }
            }
            .padding()
            .background(Color.bgSecondary(scheme: colorScheme))
            .cornerRadius(CornerRadius.md.rawValue)
        }
    }
}
