import XCTest
@testable import Models

final class ProjectManagerTests: XCTestCase {

    // MARK: - ProjectGitStatus Tests

    func testProjectGitStatusInitialization() {
        let status = ProjectGitStatus(
            currentBranch: "main",
            hasUncommittedChanges: true,
            aheadCount: 2,
            behindCount: 1,
            modifiedFiles: 5,
            isGitRepository: true
        )

        XCTAssertEqual(status.currentBranch, "main")
        XCTAssertTrue(status.hasUncommittedChanges)
        XCTAssertEqual(status.aheadCount, 2)
        XCTAssertEqual(status.behindCount, 1)
        XCTAssertEqual(status.modifiedFiles, 5)
        XCTAssertTrue(status.isGitRepository)
    }

    func testProjectGitStatusDefaultValues() {
        let status = ProjectGitStatus()

        XCTAssertNil(status.currentBranch)
        XCTAssertFalse(status.hasUncommittedChanges)
        XCTAssertEqual(status.aheadCount, 0)
        XCTAssertEqual(status.behindCount, 0)
        XCTAssertEqual(status.modifiedFiles, 0)
        XCTAssertFalse(status.isGitRepository)
    }

    func testProjectGitStatusNotARepository() {
        let status = ProjectGitStatus.notARepository

        XCTAssertFalse(status.isGitRepository)
        XCTAssertNil(status.currentBranch)
        XCTAssertFalse(status.hasUncommittedChanges)
    }

    func testProjectGitStatusCoding() throws {
        let original = ProjectGitStatus(
            currentBranch: "feature/test",
            hasUncommittedChanges: true,
            aheadCount: 3,
            behindCount: 2,
            modifiedFiles: 7,
            isGitRepository: true
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ProjectGitStatus.self, from: data)

        XCTAssertEqual(decoded.currentBranch, original.currentBranch)
        XCTAssertEqual(decoded.hasUncommittedChanges, original.hasUncommittedChanges)
        XCTAssertEqual(decoded.aheadCount, original.aheadCount)
        XCTAssertEqual(decoded.behindCount, original.behindCount)
        XCTAssertEqual(decoded.modifiedFiles, original.modifiedFiles)
        XCTAssertEqual(decoded.isGitRepository, original.isGitRepository)
    }

    func testProjectGitStatusHashable() {
        let status1 = ProjectGitStatus(currentBranch: "main", isGitRepository: true)
        let status2 = ProjectGitStatus(currentBranch: "main", isGitRepository: true)

        XCTAssertEqual(status1, status2)

        let set = Set([status1, status2])
        XCTAssertEqual(set.count, 1)
    }

    // MARK: - Project Initialization Tests

    func testProjectInitialization() {
        let url = URL(fileURLWithPath: "/path/to/project")
        let project = Project(name: "TestProject", path: url)

        XCTAssertNotNil(project.id)
        XCTAssertEqual(project.name, "TestProject")
        XCTAssertEqual(project.path, url)
        XCTAssertNil(project.icon)
        XCTAssertFalse(project.isFavorite)
        XCTAssertNotNil(project.createdAt)
        XCTAssertNil(project.lastAccessedAt)
        XCTAssertEqual(project.activeSessionCount, 0)
        XCTAssertNil(project.gitStatus)
        XCTAssertEqual(project.unsavedChangesCount, 0)
    }

    func testProjectWithAllParameters() {
        let id = UUID()
        let url = URL(fileURLWithPath: "/path/to/project")
        let createdAt = Date()
        let lastAccessedAt = Date().addingTimeInterval(-3600)
        let gitStatus = ProjectGitStatus(currentBranch: "develop", isGitRepository: true)

        let project = Project(
            id: id,
            name: "FullProject",
            path: url,
            icon: "star.fill",
            isFavorite: true,
            createdAt: createdAt,
            lastAccessedAt: lastAccessedAt,
            activeSessionCount: 3,
            gitStatus: gitStatus,
            unsavedChangesCount: 2
        )

        XCTAssertEqual(project.id, id)
        XCTAssertEqual(project.name, "FullProject")
        XCTAssertEqual(project.path, url)
        XCTAssertEqual(project.icon, "star.fill")
        XCTAssertTrue(project.isFavorite)
        XCTAssertEqual(project.createdAt, createdAt)
        XCTAssertEqual(project.lastAccessedAt, lastAccessedAt)
        XCTAssertEqual(project.activeSessionCount, 3)
        XCTAssertEqual(project.gitStatus, gitStatus)
        XCTAssertEqual(project.unsavedChangesCount, 2)
    }

    func testProjectFromUrl() {
        let url = URL(fileURLWithPath: "/Users/test/projects/MyApp")
        let project = Project.from(url: url)

        XCTAssertEqual(project.name, "MyApp")
        XCTAssertEqual(project.path, url)
    }

    // MARK: - Project Computed Properties Tests

    func testProjectClaudeMdPath() {
        let project = Project(name: "Test", path: URL(fileURLWithPath: "/projects/test"))
        let expectedPath = URL(fileURLWithPath: "/projects/test/CLAUDE.md")

        XCTAssertEqual(project.claudeMdPath, expectedPath)
    }

    func testProjectIsGitRepository() {
        let withGit = Project(
            name: "WithGit",
            path: URL(fileURLWithPath: "/test"),
            gitStatus: ProjectGitStatus(isGitRepository: true)
        )
        let withoutGit = Project(
            name: "WithoutGit",
            path: URL(fileURLWithPath: "/test"),
            gitStatus: ProjectGitStatus.notARepository
        )
        let noStatus = Project(name: "NoStatus", path: URL(fileURLWithPath: "/test"))

        XCTAssertTrue(withGit.isGitRepository)
        XCTAssertFalse(withoutGit.isGitRepository)
        XCTAssertFalse(noStatus.isGitRepository)
    }

    func testProjectGitBranch() {
        let withBranch = Project(
            name: "WithBranch",
            path: URL(fileURLWithPath: "/test"),
            gitStatus: ProjectGitStatus(currentBranch: "feature/awesome", isGitRepository: true)
        )

        XCTAssertEqual(withBranch.gitBranch, "feature/awesome")
    }

    func testProjectHasUncommittedChanges() {
        let withChanges = Project(
            name: "WithChanges",
            path: URL(fileURLWithPath: "/test"),
            gitStatus: ProjectGitStatus(hasUncommittedChanges: true, isGitRepository: true)
        )
        let withoutChanges = Project(
            name: "WithoutChanges",
            path: URL(fileURLWithPath: "/test"),
            gitStatus: ProjectGitStatus(hasUncommittedChanges: false, isGitRepository: true)
        )

        XCTAssertTrue(withChanges.hasUncommittedChanges)
        XCTAssertFalse(withoutChanges.hasUncommittedChanges)
    }

    func testProjectModifiedFilesCount() {
        let project = Project(
            name: "Modified",
            path: URL(fileURLWithPath: "/test"),
            gitStatus: ProjectGitStatus(modifiedFiles: 5, isGitRepository: true)
        )

        XCTAssertEqual(project.modifiedFilesCount, 5)
    }

    func testProjectRelativeAccessTime() {
        let recentProject = Project(
            name: "Recent",
            path: URL(fileURLWithPath: "/test"),
            lastAccessedAt: Date().addingTimeInterval(-3600) // 1 hour ago
        )
        let neverAccessedProject = Project(name: "Never", path: URL(fileURLWithPath: "/test"))

        XCTAssertFalse(recentProject.relativeAccessTime.isEmpty)
        XCTAssertEqual(neverAccessedProject.relativeAccessTime, "Never accessed")
    }

    // MARK: - Project Coding Tests

    func testProjectCoding() throws {
        let original = Project(
            name: "TestProject",
            path: URL(fileURLWithPath: "/path/to/project"),
            isFavorite: true
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Project.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.path, original.path)
        XCTAssertEqual(decoded.isFavorite, original.isFavorite)
    }

    func testProjectCodingExcludesGitStatus() throws {
        let gitStatus = ProjectGitStatus(currentBranch: "main", isGitRepository: true)
        let original = Project(
            name: "Test",
            path: URL(fileURLWithPath: "/test"),
            gitStatus: gitStatus
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Project.self, from: data)

        // gitStatus should not be persisted
        XCTAssertNil(decoded.gitStatus)
    }

    // MARK: - Project Hashable Tests

    func testProjectHashable() {
        let id = UUID()
        let project1 = Project(id: id, name: "Project1", path: URL(fileURLWithPath: "/test"))
        let project2 = Project(id: id, name: "Project2", path: URL(fileURLWithPath: "/test"))

        XCTAssertEqual(project1, project2, "Projects with same ID should be equal")
    }

    // MARK: - ProjectSortOption Tests

    func testProjectSortOptionRawValues() {
        XCTAssertEqual(ProjectSortOption.lastAccessed.rawValue, "Last Accessed")
        XCTAssertEqual(ProjectSortOption.name.rawValue, "Name")
        XCTAssertEqual(ProjectSortOption.createdAt.rawValue, "Created Date")
        XCTAssertEqual(ProjectSortOption.path.rawValue, "Path")
    }

    func testProjectSortOptionCaseIterable() {
        XCTAssertEqual(ProjectSortOption.allCases.count, 4)
    }

    func testProjectSortOptionIdentifiable() {
        XCTAssertEqual(ProjectSortOption.lastAccessed.id, "Last Accessed")
        XCTAssertEqual(ProjectSortOption.name.id, "Name")
    }

    // MARK: - Project Sorting Tests

    func testProjectSortByLastAccessed() {
        let olderProject = Project(
            name: "Older",
            path: URL(fileURLWithPath: "/older"),
            lastAccessedAt: Date().addingTimeInterval(-86400) // 1 day ago
        )
        let newerProject = Project(
            name: "Newer",
            path: URL(fileURLWithPath: "/newer"),
            lastAccessedAt: Date().addingTimeInterval(-3600) // 1 hour ago
        )

        let projects = [olderProject, newerProject]
        let sorted = projects.sorted { ($0.lastAccessedAt ?? .distantPast) > ($1.lastAccessedAt ?? .distantPast) }

        XCTAssertEqual(sorted.first?.name, "Newer")
        XCTAssertEqual(sorted.last?.name, "Older")
    }

    func testProjectSortByName() {
        let projectA = Project(name: "Alpha", path: URL(fileURLWithPath: "/a"))
        let projectB = Project(name: "Beta", path: URL(fileURLWithPath: "/b"))
        let projectC = Project(name: "Charlie", path: URL(fileURLWithPath: "/c"))

        let projects = [projectC, projectA, projectB]
        let sorted = projects.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        XCTAssertEqual(sorted[0].name, "Alpha")
        XCTAssertEqual(sorted[1].name, "Beta")
        XCTAssertEqual(sorted[2].name, "Charlie")
    }

    func testProjectSortByCreatedAt() {
        let olderProject = Project(
            name: "Older",
            path: URL(fileURLWithPath: "/older"),
            createdAt: Date().addingTimeInterval(-86400)
        )
        let newerProject = Project(
            name: "Newer",
            path: URL(fileURLWithPath: "/newer"),
            createdAt: Date()
        )

        let projects = [olderProject, newerProject]
        let sorted = projects.sorted { $0.createdAt > $1.createdAt }

        XCTAssertEqual(sorted.first?.name, "Newer")
    }

    func testProjectSortByPath() {
        let projectA = Project(name: "A", path: URL(fileURLWithPath: "/Users/test/projects/alpha"))
        let projectB = Project(name: "B", path: URL(fileURLWithPath: "/Users/test/projects/beta"))

        let projects = [projectB, projectA]
        let sorted = projects.sorted { $0.path.path.localizedCaseInsensitiveCompare($1.path.path) == .orderedAscending }

        XCTAssertEqual(sorted.first?.path.path, "/Users/test/projects/alpha")
    }

    // MARK: - Recent Projects Filter Tests

    func testRecentProjectsFilter() {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let recentProject = Project(
            name: "Recent",
            path: URL(fileURLWithPath: "/recent"),
            lastAccessedAt: Date().addingTimeInterval(-3600) // 1 hour ago
        )
        let oldProject = Project(
            name: "Old",
            path: URL(fileURLWithPath: "/old"),
            lastAccessedAt: weekAgo.addingTimeInterval(-86400) // 8 days ago
        )
        let neverAccessedProject = Project(name: "Never", path: URL(fileURLWithPath: "/never"))

        let projects = [recentProject, oldProject, neverAccessedProject]
        let recent = projects.filter { ($0.lastAccessedAt ?? .distantPast) > weekAgo }

        XCTAssertEqual(recent.count, 1)
        XCTAssertEqual(recent.first?.name, "Recent")
    }

    func testRecentProjectsIncludesWithinSevenDays() {
        let sixDaysAgo = Date().addingTimeInterval(-6 * 86400)

        let project = Project(
            name: "SixDaysAgo",
            path: URL(fileURLWithPath: "/test"),
            lastAccessedAt: sixDaysAgo
        )

        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recent = (project.lastAccessedAt ?? .distantPast) > weekAgo

        XCTAssertTrue(recent, "Project accessed 6 days ago should be considered recent")
    }

    func testRecentProjectsExcludesOlderThanSevenDays() {
        let eightDaysAgo = Date().addingTimeInterval(-8 * 86400)

        let project = Project(
            name: "EightDaysAgo",
            path: URL(fileURLWithPath: "/test"),
            lastAccessedAt: eightDaysAgo
        )

        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recent = (project.lastAccessedAt ?? .distantPast) > weekAgo

        XCTAssertFalse(recent, "Project accessed 8 days ago should not be considered recent")
    }
}
