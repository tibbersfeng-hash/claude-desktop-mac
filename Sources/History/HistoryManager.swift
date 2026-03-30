// HistoryManager.swift
// Claude Desktop Mac - History Manager
//
// Main manager for session history operations

import SwiftUI
import Combine

// MARK: - History Manager

/// Main manager for history operations
@MainActor
@Observable
public final class HistoryManager {

    // MARK: - Singleton

    public static let shared = HistoryManager()

    // MARK: - Properties

    /// All sessions in history
    public var sessions: [Session] = []

    /// Current search query
    public var searchQuery: String = ""

    /// Selected time range filter
    public var selectedTimeRange: TimeRange = .all

    /// Selected project filter
    public var selectedProject: String?

    /// Search results
    public var searchResults: [SearchResult] = []

    /// Is currently searching
    public var isSearching: Bool = false

    /// Recent searches
    public var recentSearches: RecentSearches

    /// Statistics
    public var statistics: HistoryStatistics?

    /// Available projects for filtering
    public var availableProjects: [String] {
        Array(Set(sessions.compactMap { $0.projectName ?? $0.projectPath?.split(separator: "/").last.map(String.init) }))
            .sorted()
    }

    // MARK: - Private Properties

    private let store: HistoryStore
    private let searchService: HistorySearchService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init(
        store: HistoryStore = .shared,
        searchService: HistorySearchService = .shared,
        recentSearches: RecentSearches = .shared
    ) {
        self.store = store
        self.searchService = searchService
        self.recentSearches = recentSearches

        Task {
            await loadHistory()
        }
    }

    // MARK: - Public Methods - Loading

    /// Load all history
    public func loadHistory() async {
        do {
            sessions = try await store.loadAllSessions()
            statistics = try await store.getStatistics()
        } catch {
            print("Failed to load history: \(error)")
        }
    }

    /// Refresh history from storage
    public func refresh() async {
        await loadHistory()
    }

    // MARK: - Public Methods - Session Management

    /// Save a session to history
    public func saveSession(_ session: Session) async {
        do {
            try await store.saveSession(session)
            await loadHistory()
        } catch {
            print("Failed to save session: \(error)")
        }
    }

    /// Load a specific session from history
    public func loadSession(_ id: UUID) async -> Session? {
        do {
            return try await store.loadSession(id: id)
        } catch {
            print("Failed to load session: \(error)")
            return nil
        }
    }

    /// Delete a session from history
    public func deleteSession(_ id: UUID) async {
        do {
            try await store.deleteSession(id)
            sessions.removeAll { $0.id == id }
            statistics = try await store.getStatistics()
        } catch {
            print("Failed to delete session: \(error)")
        }
    }

    /// Clear all history
    public func clearAllHistory() async {
        do {
            try await store.clearAllHistory()
            sessions.removeAll()
            searchResults.removeAll()
            statistics = try await store.getStatistics()
        } catch {
            print("Failed to clear history: \(error)")
        }
    }

    // MARK: - Public Methods - Search

    /// Perform a search
    public func search() async {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        defer { isSearching = false }

        let query = SearchQuery(
            keywords: searchQuery,
            timeRange: selectedTimeRange == .all ? nil : selectedTimeRange,
            projectName: selectedProject
        )

        do {
            searchResults = try await searchService.search(query)

            // Add to recent searches
            recentSearches.add(query)
        } catch {
            print("Search failed: \(error)")
            searchResults = []
        }
    }

    /// Clear search
    public func clearSearch() {
        searchQuery = ""
        searchResults = []
    }

    /// Quick search for suggestions
    public func getSuggestions(for prefix: String) async -> [String] {
        do {
            return try await searchService.quickSearch(prefix)
        } catch {
            return []
        }
    }

    // MARK: - Public Methods - Session Resume

    /// Resume a session from history
    public func resumeSession(_ id: UUID) async -> Session? {
        guard let session = await loadSession(id) else {
            return nil
        }

        // Create a new session continuing from the historical one
        let resumedSession = Session(
            title: "Continued: \(session.title)",
            projectPath: session.projectPath,
            projectName: session.projectName,
            model: session.model,
            messages: session.messages,
            createdAt: Date(),
            updatedAt: Date()
        )

        return resumedSession
    }

    /// Get session summary for display
    public func getSessionSummary(_ id: UUID) -> SessionSummary? {
        guard let session = sessions.first(where: { $0.id == id }) else {
            return nil
        }
        return SessionSummary(from: session)
    }
}

// MARK: - History Search View

/// A view for searching history
public struct HistorySearchView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @Bindable var manager: HistoryManager

    @State private var suggestions: [String] = []
    @State private var showSuggestions = false

    let onSelectResult: (SearchResult) -> Void

    public init(manager: HistoryManager, onSelectResult: @escaping (SearchResult) -> Void) {
        self.manager = manager
        self.onSelectResult = onSelectResult
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search header
            searchHeader

            Divider()

            // Filters
            if manager.searchQuery.isEmpty {
                filtersView
                Divider()
            }

            // Results or recent searches
            ScrollView {
                if manager.isSearching {
                    ProgressView("Searching...")
                        .padding()
                } else if !manager.searchResults.isEmpty {
                    searchResultsView
                } else if manager.searchQuery.isEmpty {
                    recentSearchesView
                } else {
                    emptyStateView
                }
            }
        }
        .frame(width: 600, height: 500)
        .background(Color.bgPrimary(scheme: colorScheme))
    }

    // MARK: - Search Header

    private var searchHeader: some View {
        HStack(spacing: Spacing.sm.rawValue) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))

            TextField("Search history...", text: $manager.searchQuery)
                .textFieldStyle(.plain)
                .font(.bodyText)
                .onSubmit {
                    Task { await manager.search() }
                }
                .onChange(of: manager.searchQuery) { _, newValue in
                    Task {
                        suggestions = await manager.getSuggestions(for: newValue)
                        showSuggestions = !suggestions.isEmpty && !newValue.isEmpty
                    }

                    // Debounced search
                    Task {
                        try? await Task.sleep(nanoseconds: 300_000_000)  // 300ms
                        if manager.searchQuery == newValue {
                            await manager.search()
                        }
                    }
                }

            if !manager.searchQuery.isEmpty {
                Button(action: { manager.clearSearch() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                }
                .buttonStyle(.plain)
            }

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.bgSecondary(scheme: colorScheme))
    }

    // MARK: - Filters View

    private var filtersView: some View {
        HStack(spacing: Spacing.lg.rawValue) {
            // Time range picker
            Picker("Time", selection: $manager.selectedTimeRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)

            // Project picker
            Picker("Project", selection: $manager.selectedProject) {
                Text("All Projects").tag(nil as String?)
                ForEach(manager.availableProjects, id: \.self) { project in
                    Text(project).tag(project as String?)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 150)

            Spacer()

            if manager.selectedTimeRange != .all || manager.selectedProject != nil {
                Button("Clear Filters") {
                    manager.selectedTimeRange = .all
                    manager.selectedProject = nil
                }
                .font(.caption)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, Spacing.sm.rawValue)
    }

    // MARK: - Search Results View

    private var searchResultsView: some View {
        LazyVStack(spacing: Spacing.sm.rawValue) {
            Text("\(manager.searchResults.count) results")
                .font(.caption)
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ForEach(manager.searchResults) { result in
                SearchResultRow(
                    result: result,
                    colorScheme: colorScheme,
                    onSelect: { onSelectResult(result) }
                )
            }
        }
        .padding()
    }

    // MARK: - Recent Searches View

    private var recentSearchesView: some View {
        VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
            Text("Recent Searches")
                .font(.headline)
                .foregroundColor(Color.fgPrimary(scheme: colorScheme))

            ForEach(manager.recentSearches.searches, id: \.createdAt) { query in
                Button(action: {
                    manager.searchQuery = query.keywords
                    Task { await manager.search() }
                }) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(Color.fgTertiary(scheme: colorScheme))

                        Text(query.keywords)
                            .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }

            if !manager.sessions.isEmpty {
                Divider()

                Text("Recent Sessions")
                    .font(.headline)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                ForEach(manager.sessions.prefix(10)) { session in
                    SessionRow(session: session, colorScheme: colorScheme)
                }
            }
        }
        .padding()
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: Spacing.md.rawValue) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))

            Text("No results found")
                .font(.headline)
                .foregroundColor(Color.fgPrimary(scheme: colorScheme))

            Text("Try different keywords or check your filters")
                .font(.caption)
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))
        }
        .padding()
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let result: SearchResult
    let colorScheme: ColorScheme
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
            // Title and project
            HStack {
                Image(systemName: "bubble.left.and.bubble.right")
                    .foregroundColor(.accentPrimary)

                Text(result.sessionTitle)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                Spacer()

                Text(result.projectName)
                    .font(.caption)
                    .foregroundColor(Color.fgSecondary(scheme: colorScheme))
            }

            // Matched content
            Text(result.matchedContent)
                .font(.caption)
                .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                .lineLimit(3)

            // Timestamp
            HStack {
                Text(relativeTime(from: result.timestamp))
                    .font(.caption2)
                    .foregroundColor(Color.fgTertiary(scheme: colorScheme))

                Spacer()

                Button("Open") {
                    onSelect()
                }
                .font(.caption)
            }
        }
        .padding(Spacing.sm.rawValue)
        .background(isHovered ? Color.bgHover(scheme: colorScheme) : Color.bgSecondary(scheme: colorScheme))
        .cornerRadius(CornerRadius.md.rawValue)
        .onHover { isHovered = $0 }
        .onTapGesture(perform: onSelect)
    }

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Session Row

private struct SessionRow: View {
    let session: Session
    let colorScheme: ColorScheme

    @State private var isHovered = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.title)
                    .font(.callout)
                    .foregroundColor(Color.fgPrimary(scheme: colorScheme))

                HStack {
                    if let project = session.projectName {
                        Text(project)
                            .font(.caption2)
                            .foregroundColor(Color.fgSecondary(scheme: colorScheme))
                    }

                    Text(session.relativeTime)
                        .font(.caption2)
                        .foregroundColor(Color.fgTertiary(scheme: colorScheme))
                }
            }

            Spacer()

            Text("\(session.messages.count) messages")
                .font(.caption2)
                .foregroundColor(Color.fgTertiary(scheme: colorScheme))
        }
        .padding(.vertical, Spacing.xs.rawValue)
        .background(isHovered ? Color.bgHover(scheme: colorScheme) : Color.clear)
        .cornerRadius(CornerRadius.sm.rawValue)
        .onHover { isHovered = $0 }
    }
}
