// ProjectSelectorView.swift
// Claude Desktop Mac - Project Selector View
//
// Dropdown selector for switching between projects

import SwiftUI
import Theme
import Models
import Project

// MARK: - Project Selector View

public struct ProjectSelectorView: View {
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var projectManager: ProjectManager
    let onSelectProject: (Project) -> Void

    @State private var isExpanded: Bool = false
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool

    public init(
        projectManager: ProjectManager,
        onSelectProject: @escaping (Project) -> Void
    ) {
        self.projectManager = projectManager
        self.onSelectProject = onSelectProject
    }

    public var body: some View {
        Menu {
            // Search field
            Menu {
                TextField("Search projects...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(4)
            } label: {
                Image(systemName: "magnifyingglass")
                Text("Search")
            }

            Divider()

            // Recent projects
            if !projectManager.recentProjects.isEmpty {
                Section("Recent") {
                    ForEach(projectManager.recentProjects.prefix(5)) { project in
                        ProjectMenuItem(
                            project: project,
                            isSelected: projectManager.currentProject?.id == project.id,
                            onSelect: { selectProject(project) }
                        )
                    }
                }
            }

            // Favorite projects
            if !projectManager.favoriteProjects.isEmpty {
                Section("Favorites") {
                    ForEach(projectManager.favoriteProjects) { project in
                        ProjectMenuItem(
                            project: project,
                            isSelected: projectManager.currentProject?.id == project.id,
                            onSelect: { selectProject(project) }
                        )
                    }
                }
            }

            // All projects
            Section("All Projects") {
                ForEach(filteredProjects) { project in
                    ProjectMenuItem(
                        project: project,
                        isSelected: projectManager.currentProject?.id == project.id,
                        onSelect: { selectProject(project) }
                    )
                }
            }

            Divider()

            // Add project
            Button {
                // Open file picker to add project
            } label: {
                Label("Add Project...", systemImage: "plus")
            }

            // Manage projects
            Button {
                // Open project management sheet
            } label: {
                Label("Manage Projects...", systemImage: "folder.badge.gearshape")
            }
        } label: {
            HStack(spacing: Spacing.sm.rawValue) {
                // Project icon
                if let current = projectManager.currentProject {
                    Image(systemName: current.isFavorite ? "star.fill" : "folder.fill")
                        .foregroundColor(current.isFavorite ? .yellow : .accentPrimary)
                } else {
                    Image(systemName: "folder.badge.plus")
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                }

                // Project name
                Text(projectManager.currentProject?.name ?? "Select Project")
                    .font(.callout)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))
                    .lineLimit(1)

                // Git branch (if available)
                if let branch = projectManager.currentProject?.gitBranch {
                    HStack(spacing: 2) {
                        Image(systemName: "git.branch")
                            .font(.system(size: 9))
                        Text(branch)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.bgTertiary(scheme: colorScheme))
                    .cornerRadius(3)
                }

                Spacer()

                // Dropdown indicator
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            }
            .padding(.horizontal, Spacing.md.rawValue)
            .padding(.vertical, Spacing.sm.rawValue)
            .background(Color.bgSecondary(scheme: colorScheme))
            .cornerRadius(CornerRadius.md.rawValue)
        }
        .menuStyle(.borderlessButton)
        .frame(minWidth: 200, maxWidth: 300)
    }

    // MARK: - Private Methods

    private var filteredProjects: [Project] {
        if searchText.isEmpty {
            return projectManager.otherProjects
        }
        return projectManager.filteredProjects.filter { project in
            !projectManager.favoriteProjects.contains { $0.id == project.id } &&
            !projectManager.recentProjects.contains { $0.id == project.id }
        }
    }

    private func selectProject(_ project: Project) {
        projectManager.switchToProject(project)
        onSelectProject(project)
    }
}

// MARK: - Project Menu Item

struct ProjectMenuItem: View {
    let project: Project
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentPrimary)
                } else {
                    Spacer()
                        .frame(width: 12)
                }

                // Project icon
                Image(systemName: project.isFavorite ? "star.fill" : "folder.fill")
                    .foregroundColor(project.isFavorite ? .yellow : .secondary)

                // Project name
                Text(project.name)

                Spacer()

                // Git branch
                if let branch = project.gitBranch {
                    HStack(spacing: 2) {
                        Image(systemName: "git.branch")
                            .font(.system(size: 8))
                        Text(branch)
                            .font(.system(size: 9))
                    }
                    .foregroundColor(.secondary)
                }

                // Uncommitted changes indicator
                if project.hasUncommittedChanges {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                }
            }
        }
    }
}

// MARK: - Compact Project Selector (for toolbar)

public struct CompactProjectSelector: View {
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var projectManager: ProjectManager
    let onSelectProject: (Project) -> Void

    public init(
        projectManager: ProjectManager,
        onSelectProject: @escaping (Project) -> Void
    ) {
        self.projectManager = projectManager
        self.onSelectProject = onSelectProject
    }

    public var body: some View {
        Menu {
            ForEach(projectManager.filteredProjects) { project in
                Button {
                    projectManager.switchToProject(project)
                    onSelectProject(project)
                } label: {
                    HStack {
                        Image(systemName: project.isFavorite ? "star.fill" : "folder.fill")
                        Text(project.name)
                        if let branch = project.gitBranch {
                            Text("(\(branch))")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Divider()

            Button {
                // Add project
            } label: {
                Label("Add Project...", systemImage: "plus")
            }
        } label: {
            HStack(spacing: Spacing.xs.rawValue) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 12))

                Text(projectManager.currentProject?.name ?? "Project")
                    .font(.caption)

                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
            }
            .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            .padding(.horizontal, Spacing.sm.rawValue)
            .padding(.vertical, Spacing.xs.rawValue)
            .background(Color.bgTertiary(scheme: colorScheme))
            .cornerRadius(CornerRadius.sm.rawValue)
        }
        .menuStyle(.borderlessButton)
    }
}

// MARK: - Project Dropdown Sheet

public struct ProjectDropdownSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @Bindable var projectManager: ProjectManager
    let onSelectProject: (Project) -> Void

    @State private var searchText: String = ""
    @State private var showAddProject: Bool = false

    public init(
        projectManager: ProjectManager,
        onSelectProject: @escaping (Project) -> Void
    ) {
        self.projectManager = projectManager
        self.onSelectProject = onSelectProject
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: Spacing.sm.rawValue) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))

                TextField("Search projects...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.callout)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Spacing.md.rawValue)
            .background(Color.bgSecondary(scheme: colorScheme))

            Divider()

            // Project list
            ScrollView {
                LazyVStack(spacing: Spacing.xs.rawValue) {
                    // Favorites section
                    if !projectManager.favoriteProjects.isEmpty {
                        SectionHeader(title: "Favorites")

                        ForEach(projectManager.favoriteProjects) { project in
                            ProjectDropdownRow(
                                project: project,
                                isSelected: projectManager.currentProject?.id == project.id,
                                onSelect: {
                                    selectAndDismiss(project)
                                },
                                onToggleFavorite: {
                                    projectManager.toggleFavorite(project.id)
                                }
                            )
                        }
                    }

                    // Recent section
                    if !recentNonFavorites.isEmpty && searchText.isEmpty {
                        SectionHeader(title: "Recent")

                        ForEach(recentNonFavorites.prefix(5)) { project in
                            ProjectDropdownRow(
                                project: project,
                                isSelected: projectManager.currentProject?.id == project.id,
                                onSelect: {
                                    selectAndDismiss(project)
                                },
                                onToggleFavorite: {
                                    projectManager.toggleFavorite(project.id)
                                }
                            )
                        }
                    }

                    // All projects
                    if !filteredOtherProjects.isEmpty {
                        SectionHeader(title: "All Projects")

                        ForEach(filteredOtherProjects) { project in
                            ProjectDropdownRow(
                                project: project,
                                isSelected: projectManager.currentProject?.id == project.id,
                                onSelect: {
                                    selectAndDismiss(project)
                                },
                                onToggleFavorite: {
                                    projectManager.toggleFavorite(project.id)
                                }
                            )
                        }
                    }

                    // Empty state
                    if filteredProjects.isEmpty {
                        emptyStateView
                    }
                }
                .padding(Spacing.sm.rawValue)
            }
            .scrollIndicators(.automatic)

            Divider()

            // Footer actions
            HStack {
                Button(action: { showAddProject = true }) {
                    Label("Add Project...", systemImage: "plus")
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentPrimary)

                Spacer()

                Text("\(projectManager.projects.count) projects")
                    .font(.caption)
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
            }
            .padding(Spacing.md.rawValue)
            .background(Color.bgSecondary(scheme: colorScheme))
        }
        .frame(width: 350, height: 450)
        .background(Color.bgPrimary(scheme: colorScheme))
        .sheet(isPresented: $showAddProject) {
            AddProjectSheet(projectManager: projectManager)
        }
    }

    // MARK: - Private Properties

    private var filteredProjects: [Project] {
        if searchText.isEmpty {
            return projectManager.projects
        }
        return projectManager.projects.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.path.path.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var recentNonFavorites: [Project] {
        projectManager.recentProjects.filter { !$0.isFavorite }
    }

    private var filteredOtherProjects: [Project] {
        if searchText.isEmpty {
            return projectManager.otherProjects
        }
        return filteredProjects.filter { !$0.isFavorite }
    }

    // MARK: - Views

    private var emptyStateView: some View {
        VStack(spacing: Spacing.md.rawValue) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 32))
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))

            Text("No projects found")
                .font(.callout)
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))

            if !searchText.isEmpty {
                Button("Clear search") {
                    searchText = ""
                }
                .buttonStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl.rawValue)
    }

    // MARK: - Actions

    private func selectAndDismiss(_ project: Project) {
        projectManager.switchToProject(project)
        onSelectProject(project)
        dismiss()
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String

    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(Color.fgTertiary(scheme: colorScheme))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Spacing.sm.rawValue)
    }
}

// MARK: - Project Dropdown Row

private struct ProjectDropdownRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let project: Project
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggleFavorite: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Spacing.sm.rawValue) {
            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentPrimary)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
            }

            // Project icon
            Image(systemName: project.isFavorite ? "star.fill" : "folder.fill")
                .foregroundColor(project.isFavorite ? .yellow : .accentPrimary)

            // Project info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs.rawValue) {
                    Text(project.name)
                        .font(.callout)
                        .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                    // Git branch badge
                    if let branch = project.gitBranch {
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

                    // Uncommitted changes indicator
                    if project.hasUncommittedChanges {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                    }
                }

                Text(project.displayPath)
                    .font(.caption2)
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                    .lineLimit(1)
            }

            Spacer()

            // Favorite toggle on hover
            if isHovered {
                Button(action: onToggleFavorite) {
                    Image(systemName: project.isFavorite ? "star.fill" : "star")
                        .foregroundColor(project.isFavorite ? .yellow : Color.fgSecondary(scheme: colorScheme))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.sm.rawValue)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm.rawValue)
                .fill(isSelected ? Color.bgSelected(scheme: colorScheme).opacity(0.5) :
                      isHovered ? Color.bgHover(scheme: colorScheme) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Add Project Sheet

public struct AddProjectSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @Bindable var projectManager: ProjectManager

    @State private var selectedPath: String = ""
    @State private var projectName: String = ""
    @State private var isFavorite: Bool = false

    public init(projectManager: ProjectManager) {
        self.projectManager = projectManager
    }

    public var body: some View {
        VStack(spacing: Spacing.lg.rawValue) {
            // Header
            HStack {
                Text("Add Project")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                }
                .buttonStyle(.plain)
            }

            // Form
            VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
                // Path selector
                VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
                    Text("Project Path")
                        .font(.callout)
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))

                    HStack {
                        TextField("Select a directory...", text: $selectedPath)
                            .textFieldStyle(.roundedBorder)

                        Button("Browse...") {
                            browseForProject()
                        }
                        .buttonStyle(.secondary)
                    }
                }

                // Project name
                VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
                    Text("Project Name")
                        .font(.callout)
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))

                    TextField("Project name", text: $projectName)
                        .textFieldStyle(.roundedBorder)
                }

                // Favorite toggle
                Toggle("Add to Favorites", isOn: $isFavorite)
                    .toggleStyle(.checkbox)
            }
            .padding(Spacing.md.rawValue)
            .background(Color.bgSecondary(scheme: colorScheme))
            .cornerRadius(CornerRadius.md.rawValue)

            // Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.secondary)

                Spacer()

                Button("Add Project") {
                    addProject()
                }
                .buttonStyle(.primary)
                .disabled(selectedPath.isEmpty)
            }
        }
        .padding(Spacing.lg.rawValue)
        .frame(width: 450)
        .background(Color.bgPrimary(scheme: colorScheme))
    }

    private func browseForProject() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a project directory"

        if panel.runModal() == .OK, let url = panel.url {
            selectedPath = url.path
            if projectName.isEmpty {
                projectName = url.lastPathComponent
            }
        }
    }

    private func addProject() {
        let url = URL(fileURLWithPath: selectedPath)
        var project = Project.from(url: url)
        project.isFavorite = isFavorite

        if !projectName.isEmpty {
            project.name = projectName
        }

        projectManager.addProject(project)
        dismiss()
    }
}

// MARK: - Preview

#Preview("Project Selector") {
    let manager = ProjectManager()
    manager.projects = [
        Project(name: "My App", path: URL(fileURLWithPath: "/Users/dev/myapp"), isFavorite: true),
        Project(name: "API Server", path: URL(fileURLWithPath: "/Users/dev/api")),
        Project(name: "Utils", path: URL(fileURLWithPath: "/Users/dev/utils"))
    ]

    return VStack {
        ProjectSelectorView(
            projectManager: manager,
            onSelectProject: { _ in }
        )
        .padding()

        Spacer()
    }
    .frame(width: 400, height: 200)
}
