// ProjectSwitcher.swift
// Claude Desktop Mac - Project Switcher
//
// UI for switching between projects

import SwiftUI
import Combine
import Theme

// MARK: - Project Picker View

/// A view for quickly switching between projects
public struct ProjectPickerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @Bindable var projectManager: ProjectManager
    @State private var searchText: String = ""
    @State private var showAddProject: Bool = false

    let onSelect: (Project) -> Void

    public init(projectManager: ProjectManager, onSelect: @escaping (Project) -> Void) {
        self.projectManager = projectManager
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            projectList
            Divider()
            footerActions
        }
        .frame(width: 350)
        .frame(maxHeight: 450)
        .sheet(isPresented: $showAddProject) {
            AddProjectSheet(projectManager: projectManager)
        }
        .onChange(of: searchText) { _, newValue in
            projectManager.searchText = newValue
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var searchField: some View {
        HStack(spacing: Spacing.sm.rawValue) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))

            TextField("Search projects...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.bodyText)
        }
        .padding(Spacing.sm.rawValue)
        .background(Color.bgSecondary(scheme: colorScheme))
    }

    @ViewBuilder
    private var projectList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                favoritesSection
                allProjectsSection
                emptyStateSection
            }
            .padding(Spacing.sm.rawValue)
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
                        onToggleFavorite: { projectManager.toggleFavorite(project.id) }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var allProjectsSection: some View {
        if !otherProjects.isEmpty {
            Section(favoriteProjects.isEmpty ? "" : "All Projects") {
                ForEach(otherProjects) { project in
                    ProjectItemView(
                        project: project,
                        isSelected: projectManager.currentProject?.id == project.id,
                        onSelect: { selectProject(project) },
                        onToggleFavorite: { projectManager.toggleFavorite(project.id) }
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

            Spacer()

            if !projectManager.projects.isEmpty {
                Button("Manage...") {
                    // Open project management
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
        projectManager.filteredProjects.filter { !$0.isFavorite }
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.md.rawValue) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))

            Text("No Projects")
                .font(.headline)
                .foregroundColor(Color.fgPrimary(scheme: colorScheme))

            Text("Add a project to get started")
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
