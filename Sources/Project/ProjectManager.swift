// ProjectManager.swift
// Claude Desktop Mac - Project Manager
//
// Manages project contexts and configurations

import SwiftUI
import Combine
import Theme

// MARK: - Project Model

/// Represents a Claude project
public struct Project: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var path: URL
    public var icon: String?
    public var isFavorite: Bool
    public var createdAt: Date
    public var lastAccessedAt: Date?
    public var activeSessionCount: Int

    public init(
        id: UUID = UUID(),
        name: String,
        path: URL,
        icon: String? = nil,
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        lastAccessedAt: Date? = nil,
        activeSessionCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.icon = icon
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.lastAccessedAt = lastAccessedAt
        self.activeSessionCount = activeSessionCount
    }

    /// Path to CLAUDE.md file
    public var claudeMdPath: URL {
        path.appendingPathComponent("CLAUDE.md")
    }

    /// Whether CLAUDE.md exists
    public var hasClaudeMd: Bool {
        FileManager.default.fileExists(atPath: claudeMdPath.path)
    }

    /// Relative time since last access
    public var relativeAccessTime: String {
        guard let lastAccessed = lastAccessedAt else {
            return "Never accessed"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastAccessed, relativeTo: Date())
    }

    /// Create from directory URL
    public static func from(url: URL) -> Project {
        let name = url.lastPathComponent
        return Project(name: name, path: url)
    }
}

// MARK: - Project Manager

/// Manages projects and their configurations
@MainActor
@Observable
public final class ProjectManager {

    // MARK: - Singleton

    public static let shared = ProjectManager()

    // MARK: - Properties

    /// All known projects
    public var projects: [Project] = []

    /// Currently active project
    public var currentProject: Project?

    /// Search text for filtering
    public var searchText: String = ""

    /// Storage key
    private let projectsKey = "SavedProjects"
    private let currentProjectKey = "CurrentProjectId"

    // MARK: - Computed Properties

    /// Filtered projects based on search
    public var filteredProjects: [Project] {
        if searchText.isEmpty {
            return projects
        }
        return projects.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.path.path.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Favorite projects
    public var favoriteProjects: [Project] {
        filteredProjects.filter { $0.isFavorite }
    }

    /// Non-favorite projects
    public var otherProjects: [Project] {
        filteredProjects.filter { !$0.isFavorite }
    }

    // MARK: - Initialization

    private init() {
        loadProjects()
    }

    // MARK: - Public Methods - Project Management

    /// Add a new project
    public func addProject(_ project: Project) {
        // Check for duplicates
        guard !projects.contains(where: { $0.path == project.path }) else {
            return
        }

        projects.append(project)
        saveProjects()
    }

    /// Add project from URL
    @discardableResult
    public func addProject(at url: URL) -> Project? {
        // Verify directory exists
        guard FileManager.default.isDirectory(at: url) else {
            return nil
        }

        let project = Project.from(url: url)
        addProject(project)
        return project
    }

    /// Remove a project
    public func removeProject(_ id: UUID) {
        projects.removeAll { $0.id == id }

        if currentProject?.id == id {
            currentProject = nil
        }

        saveProjects()
    }

    /// Toggle favorite status
    public func toggleFavorite(_ id: UUID) {
        guard let index = projects.firstIndex(where: { $0.id == id }) else {
            return
        }

        projects[index].isFavorite.toggle()
        saveProjects()
    }

    /// Switch to a project
    public func switchToProject(_ project: Project) {
        currentProject = project

        // Update last accessed time
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].lastAccessedAt = Date()
        }

        saveProjects()
        saveCurrentProject()
    }

    /// Switch to project by ID
    public func switchToProject(_ id: UUID) {
        guard let project = projects.first(where: { $0.id == id }) else {
            return
        }
        switchToProject(project)
    }

    /// Update project name
    public func renameProject(_ id: UUID, name: String) {
        guard let index = projects.firstIndex(where: { $0.id == id }) else {
            return
        }

        projects[index].name = name
        saveProjects()
    }

    /// Get project by ID
    public func getProject(_ id: UUID) -> Project? {
        projects.first { $0.id == id }
    }

    // MARK: - Public Methods - CLAUDE.md

    /// Load CLAUDE.md content for a project
    public func loadClaudeMd(for project: Project) async -> String? {
        guard project.hasClaudeMd else {
            return nil
        }

        do {
            return try String(contentsOf: project.claudeMdPath, encoding: .utf8)
        } catch {
            print("Failed to load CLAUDE.md: \(error)")
            return nil
        }
    }

    /// Save CLAUDE.md content for a project
    public func saveClaudeMd(_ content: String, for project: Project) async throws {
        try content.write(to: project.claudeMdPath, atomically: true, encoding: .utf8)
    }

    /// Create default CLAUDE.md for a project
    public func createDefaultClaudeMd(for project: Project) async throws {
        let template = ClaudeMdTemplate.default.template(for: project.name)
        try await saveClaudeMd(template, for: project)
    }

    // MARK: - Private Methods

    private func loadProjects() {
        // Load projects from UserDefaults
        if let data = UserDefaults.standard.data(forKey: projectsKey),
           let saved = try? JSONDecoder().decode([Project].self, from: data) {
            projects = saved
        }

        // Load current project
        if let currentId = UserDefaults.standard.string(forKey: currentProjectKey),
           let id = UUID(uuidString: currentId) {
            currentProject = projects.first { $0.id == id }
        }
    }

    private func saveProjects() {
        guard let data = try? JSONEncoder().encode(projects) else { return }
        UserDefaults.standard.set(data, forKey: projectsKey)
    }

    private func saveCurrentProject() {
        UserDefaults.standard.set(currentProject?.id.uuidString, forKey: currentProjectKey)
    }
}

// MARK: - FileManager Extension

extension FileManager {
    /// Check if URL is a directory
    func isDirectory(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}

// MARK: - Project Item View

/// A view displaying a single project
public struct ProjectItemView: View {
    @Environment(\.colorScheme) private var colorScheme

    let project: Project
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggleFavorite: (() -> Void)?

    @State private var isHovered = false

    public init(
        project: Project,
        isSelected: Bool,
        onSelect: @escaping () -> Void,
        onToggleFavorite: (() -> Void)? = nil
    ) {
        self.project = project
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.onToggleFavorite = onToggleFavorite
    }

    public var body: some View {
        HStack(spacing: Spacing.md.rawValue) {
            // Project icon
            Image(systemName: project.isFavorite ? "star.fill" : "folder.fill")
                .foregroundColor(project.isFavorite ? .yellow : .accentPrimary)
                .frame(width: 24)

            // Project info
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.callout)
                    .foregroundColor(isSelected ? .fgInverse(scheme: colorScheme) : Color.fgPrimary(scheme: colorScheme))
                    .lineLimit(1)

                HStack(spacing: Spacing.sm.rawValue) {
                    Text(project.path.path)
                        .font(.caption2)
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                        .lineLimit(1)

                    if project.activeSessionCount > 0 {
                        Text("\(project.activeSessionCount) sessions")
                            .font(.caption2)
                            .foregroundColor(.accentSuccess)
                    }
                }
            }

            Spacer()

            // CLAUDE.md indicator
            if project.hasClaudeMd {
                Image(systemName: "doc.text")
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                    .font(.caption)
            }

            // Favorite button on hover
            if isHovered, let onToggleFavorite = onToggleFavorite {
                Button(action: onToggleFavorite) {
                    Image(systemName: project.isFavorite ? "star.fill" : "star")
                        .foregroundColor(project.isFavorite ? .yellow : Color.fgSecondary(scheme: colorScheme))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.md.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
        .background(isSelected ? Color.bgSelected(scheme: colorScheme) : (isHovered ? Color.bgHover(scheme: colorScheme) : Color.clear))
        .cornerRadius(CornerRadius.md.rawValue)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovered = $0 }
    }
}
