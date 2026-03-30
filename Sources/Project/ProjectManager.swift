// ProjectManager.swift
// Claude Desktop Mac - Project Manager
//
// Manages project contexts and configurations

import SwiftUI
import Combine
import Theme

// MARK: - Project Status

/// Git status information for a project
public struct ProjectGitStatus: Codable, Hashable, Sendable {
    public let currentBranch: String?
    public let hasUncommittedChanges: Bool
    public let aheadCount: Int
    public let behindCount: Int
    public let modifiedFiles: Int
    public let isGitRepository: Bool

    public init(
        currentBranch: String? = nil,
        hasUncommittedChanges: Bool = false,
        aheadCount: Int = 0,
        behindCount: Int = 0,
        modifiedFiles: Int = 0,
        isGitRepository: Bool = false
    ) {
        self.currentBranch = currentBranch
        self.hasUncommittedChanges = hasUncommittedChanges
        self.aheadCount = aheadCount
        self.behindCount = behindCount
        self.modifiedFiles = modifiedFiles
        self.isGitRepository = isGitRepository
    }

    public static let notARepository = ProjectGitStatus(isGitRepository: false)
}

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

    // Git status (not persisted, refreshed on demand)
    public var gitStatus: ProjectGitStatus?

    // Unsaved changes count (for editors)
    public var unsavedChangesCount: Int

    public init(
        id: UUID = UUID(),
        name: String,
        path: URL,
        icon: String? = nil,
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        lastAccessedAt: Date? = nil,
        activeSessionCount: Int = 0,
        gitStatus: ProjectGitStatus? = nil,
        unsavedChangesCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.icon = icon
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.lastAccessedAt = lastAccessedAt
        self.activeSessionCount = activeSessionCount
        self.gitStatus = gitStatus
        self.unsavedChangesCount = unsavedChangesCount
    }

    /// Path to CLAUDE.md file
    public var claudeMdPath: URL {
        path.appendingPathComponent("CLAUDE.md")
    }

    /// Whether CLAUDE.md exists
    public var hasClaudeMd: Bool {
        FileManager.default.fileExists(atPath: claudeMdPath.path)
    }

    /// Whether project is a Git repository
    public var isGitRepository: Bool {
        gitStatus?.isGitRepository ?? false
    }

    /// Current Git branch name
    public var gitBranch: String? {
        gitStatus?.currentBranch
    }

    /// Whether there are uncommitted changes
    public var hasUncommittedChanges: Bool {
        gitStatus?.hasUncommittedChanges ?? false
    }

    /// Number of modified files
    public var modifiedFilesCount: Int {
        gitStatus?.modifiedFiles ?? 0
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

    /// Formatted path for display (shows home directory as ~)
    public var displayPath: String {
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        if path.path.hasPrefix(homePath) {
            return "~" + path.path.dropFirst(homePath.count)
        }
        return path.path
    }

    /// Create from directory URL
    public static func from(url: URL) -> Project {
        let name = url.lastPathComponent
        return Project(name: name, path: url)
    }

    // MARK: - Codable (exclude non-persisted fields)

    enum CodingKeys: String, CodingKey {
        case id, name, path, icon, isFavorite, createdAt, lastAccessedAt, activeSessionCount
    }
}

// MARK: - Project Sort Option

/// Sort options for project list
public enum ProjectSortOption: String, CaseIterable, Identifiable, Codable {
    case lastAccessed = "Last Accessed"
    case name = "Name"
    case createdAt = "Created Date"
    case path = "Path"

    public var id: String { rawValue }
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

    /// Current sort option
    public var sortOption: ProjectSortOption = .lastAccessed

    /// Storage key
    private let projectsKey = "SavedProjects"
    private let currentProjectKey = "CurrentProjectId"
    private let sortOptionKey = "ProjectSortOption"

    // MARK: - Computed Properties

    /// Sorted and filtered projects
    public var sortedProjects: [Project] {
        let sorted: [Project]
        switch sortOption {
        case .lastAccessed:
            sorted = projects.sorted { ($0.lastAccessedAt ?? .distantPast) > ($1.lastAccessedAt ?? .distantPast) }
        case .name:
            sorted = projects.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .createdAt:
            sorted = projects.sorted { $0.createdAt > $1.createdAt }
        case .path:
            sorted = projects.sorted { $0.path.path.localizedCaseInsensitiveCompare($1.path.path) == .orderedAscending }
        }
        return sorted
    }

    /// Filtered projects based on search
    public var filteredProjects: [Project] {
        if searchText.isEmpty {
            return sortedProjects
        }
        return sortedProjects.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.path.path.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Favorite projects (sorted)
    public var favoriteProjects: [Project] {
        filteredProjects.filter { $0.isFavorite }
    }

    /// Non-favorite projects (sorted)
    public var otherProjects: [Project] {
        filteredProjects.filter { !$0.isFavorite }
    }

    /// Projects with recent activity (last 7 days)
    public var recentProjects: [Project] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return projects.filter { ($0.lastAccessedAt ?? .distantPast) > weekAgo }
            .sorted { ($0.lastAccessedAt ?? .distantPast) > ($1.lastAccessedAt ?? .distantPast) }
    }

    // MARK: - Initialization

    private init() {
        loadProjects()
        loadSortOption()
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

    // MARK: - Public Methods - Git Status

    /// Refresh Git status for a single project
    public func refreshGitStatus(for projectId: UUID) async {
        guard let index = projects.firstIndex(where: { $0.id == projectId }) else {
            return
        }

        let project = projects[index]
        let gitStatus = await fetchGitStatus(for: project.path)
        projects[index].gitStatus = gitStatus
    }

    /// Refresh Git status for all projects
    public func refreshAllGitStatus() async {
        await withTaskGroup(of: (UUID, ProjectGitStatus).self) { group in
            for project in projects {
                group.addTask {
                    let status = await self.fetchGitStatus(for: project.path)
                    return (project.id, status)
                }
            }

            for await (id, status) in group {
                if let index = projects.firstIndex(where: { $0.id == id }) {
                    projects[index].gitStatus = status
                }
            }
        }
    }

    /// Fetch Git status for a path
    private func fetchGitStatus(for path: URL) async -> ProjectGitStatus {
        let gitDir = path.appendingPathComponent(".git")

        // Check if it's a git repository
        guard FileManager.default.fileExists(atPath: gitDir.path) else {
            return .notARepository
        }

        // Get current branch
        let branch = await runGitCommand(at: path, args: ["rev-parse", "--abbrev-ref", "HEAD"])

        // Get modified files count
        let statusOutput = await runGitCommand(at: path, args: ["status", "--porcelain"])
        let modifiedFiles = statusOutput?.components(separatedBy: "\n").filter { !$0.isEmpty }.count ?? 0
        let hasUncommittedChanges = modifiedFiles > 0

        // Get ahead/behind counts
        var aheadCount = 0
        var behindCount = 0
        if let branch = branch, branch != "HEAD" {
            let trackingInfo = await runGitCommand(at: path, args: ["rev-list", "--left-right", "--count", "\(branch)...\(branch)@{upstream}"])
            if let info = trackingInfo {
                let parts = info.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespaces)
                if parts.count >= 2 {
                    aheadCount = Int(parts[0]) ?? 0
                    behindCount = Int(parts[1]) ?? 0
                }
            }
        }

        return ProjectGitStatus(
            currentBranch: branch,
            hasUncommittedChanges: hasUncommittedChanges,
            aheadCount: aheadCount,
            behindCount: behindCount,
            modifiedFiles: modifiedFiles,
            isGitRepository: true
        )
    }

    /// Run a git command and return the output
    private func runGitCommand(at path: URL, args: [String]) async -> String? {
        return await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            process.arguments = args
            process.currentDirectoryURL = path

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()

            do {
                try process.run()
                process.waitUntilExit()

                if process.terminationStatus == 0 {
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                    continuation.resume(returning: output)
                } else {
                    continuation.resume(returning: nil)
                }
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    // MARK: - Public Methods - Sorting

    /// Update sort option
    public func setSortOption(_ option: ProjectSortOption) {
        sortOption = option
        saveSortOption()
    }

    private func loadSortOption() {
        if let savedValue = UserDefaults.standard.string(forKey: sortOptionKey),
           let option = ProjectSortOption(rawValue: savedValue) {
            sortOption = option
        }
    }

    private func saveSortOption() {
        UserDefaults.standard.set(sortOption.rawValue, forKey: sortOptionKey)
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

/// A view displaying a single project with enhanced status information
public struct ProjectItemView: View {
    @Environment(\.colorScheme) private var colorScheme

    let project: Project
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggleFavorite: (() -> Void)?
    let onDelete: (() -> Void)?

    @State private var isHovered = false
    @State private var showDeleteConfirmation = false

    public init(
        project: Project,
        isSelected: Bool,
        onSelect: @escaping () -> Void,
        onToggleFavorite: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.project = project
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.onToggleFavorite = onToggleFavorite
        self.onDelete = onDelete
    }

    public var body: some View {
        HStack(spacing: Spacing.md.rawValue) {
            // Project icon
            projectIcon

            // Project info
            VStack(alignment: .leading, spacing: 3) {
                // Name row with status indicators
                HStack(spacing: Spacing.xs.rawValue) {
                    Text(project.name)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .fgInverse(scheme: colorScheme) : Color.fgPrimary(scheme: colorScheme))
                        .lineLimit(1)

                    // Git branch badge
                    if let branch = project.gitBranch {
                        gitBranchBadge(branch)
                    }

                    // Uncommitted changes indicator
                    if project.hasUncommittedChanges {
                        uncommittedBadge
                    }
                }

                // Path and last accessed
                HStack(spacing: Spacing.sm.rawValue) {
                    Text(project.displayPath)
                        .font(.caption2)
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Text("•")
                        .font(.caption2)
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))

                    Text(project.relativeAccessTime)
                        .font(.caption2)
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                }

                // Status row
                statusRow
            }

            Spacer()

            // Right side indicators and actions
            rightIndicators
        }
        .padding(.horizontal, Spacing.md.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
        .background(isSelected ? Color.bgSelected(scheme: colorScheme) : (isHovered ? Color.bgHover(scheme: colorScheme) : Color.clear))
        .cornerRadius(CornerRadius.md.rawValue)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovered = $0 }
        .confirmationDialog(
            "Remove Project?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove from List", role: .destructive) {
                onDelete?()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove '\(project.name)' from your project list. The project files will not be deleted.")
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var projectIcon: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: project.isFavorite ? "star.fill" : "folder.fill")
                .foregroundColor(project.isFavorite ? .yellow : .accentPrimary)
                .font(.system(size: 20))

            // Git indicator
            if project.isGitRepository {
                Circle()
                    .fill(Color.accentSuccess)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(Color.bgPrimary(scheme: colorScheme), lineWidth: 1.5)
                    )
            }
        }
        .frame(width: 24, height: 24)
    }

    @ViewBuilder
    private func gitBranchBadge(_ branch: String) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "git.branch")
                .font(.system(size: 8))
            Text(branch)
                .font(.system(size: 9, weight: .medium))
        }
        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
        .background(Color.bgTertiary(scheme: colorScheme))
        .cornerRadius(3)
    }

    @ViewBuilder
    private var uncommittedBadge: some View {
        Circle()
            .fill(Color.accentWarning)
            .frame(width: 6, height: 6)
    }

    @ViewBuilder
    private var statusRow: some View {
        HStack(spacing: Spacing.sm.rawValue) {
            // CLAUDE.md indicator
            if project.hasClaudeMd {
                statusChip(
                    icon: "doc.text.fill",
                    text: "CLAUDE.md",
                    color: .accentPrimary
                )
            }

            // Modified files count
            if project.modifiedFilesCount > 0 {
                statusChip(
                    icon: "pencil.circle.fill",
                    text: "\(project.modifiedFilesCount) modified",
                    color: .accentWarning
                )
            }

            // Active sessions
            if project.activeSessionCount > 0 {
                statusChip(
                    icon: "bubble.left.and.bubble.right.fill",
                    text: "\(project.activeSessionCount) sessions",
                    color: .accentSuccess
                )
            }

            // Unsaved changes
            if project.unsavedChangesCount > 0 {
                statusChip(
                    icon: "square.and.pencil",
                    text: "\(project.unsavedChangesCount) unsaved",
                    color: .accentOrange
                )
            }
        }
    }

    @ViewBuilder
    private func statusChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(text)
                .font(.system(size: 9))
        }
        .foregroundColor(color)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }

    @ViewBuilder
    private var rightIndicators: some View {
        HStack(spacing: Spacing.sm.rawValue) {
            // Ahead/behind indicators
            if let status = project.gitStatus, status.isGitRepository {
                if status.aheadCount > 0 || status.behindCount > 0 {
                    aheadBehindIndicator(status)
                }
            }

            // Action buttons on hover
            if isHovered {
                actionButtons
            }
        }
    }

    @ViewBuilder
    private func aheadBehindIndicator(_ status: ProjectGitStatus) -> some View {
        HStack(spacing: 2) {
            if status.aheadCount > 0 {
                HStack(spacing: 1) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 8))
                    Text("\(status.aheadCount)")
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundColor(.accentSuccess)
            }

            if status.behindCount > 0 {
                HStack(spacing: 1) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 8))
                    Text("\(status.behindCount)")
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundColor(.accentOrange)
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: Spacing.xs.rawValue) {
            if let onToggleFavorite = onToggleFavorite {
                Button(action: onToggleFavorite) {
                    Image(systemName: project.isFavorite ? "star.fill" : "star")
                        .foregroundColor(project.isFavorite ? .yellow : Color.fgSecondary(scheme: colorScheme))
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help(project.isFavorite ? "Remove from favorites" : "Add to favorites")
            }

            if let _ = onDelete {
                Button(action: { showDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help("Remove project from list")
            }
        }
    }
}
