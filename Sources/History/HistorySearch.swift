// HistorySearch.swift
// Claude Desktop Mac - History Search
//
// Provides search functionality for session history

import Foundation
import Combine

// MARK: - Search Query

/// Represents a history search query
public struct SearchQuery: Codable, Sendable {
    public let keywords: String
    public let timeRange: TimeRange?
    public let projectId: UUID?
    public let projectName: String?
    public let createdAt: Date

    public init(
        keywords: String,
        timeRange: TimeRange? = nil,
        projectId: UUID? = nil,
        projectName: String? = nil
    ) {
        self.keywords = keywords
        self.timeRange = timeRange
        self.projectId = projectId
        self.projectName = projectName
        self.createdAt = Date()
    }
}

// MARK: - Time Range

/// Time range for filtering search results
public enum TimeRange: String, Codable, CaseIterable, Identifiable, Sendable {
    case today = "Today"
    case yesterday = "Yesterday"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case lastThreeMonths = "Last 3 Months"
    case all = "All Time"

    public var id: String { rawValue }

    /// Calculate date range for this filter
    public func dateRange() -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            return (start, now)

        case .yesterday:
            let today = calendar.startOfDay(for: now)
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            return (yesterday, today)

        case .thisWeek:
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            return (start, now)

        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return (start, now)

        case .lastThreeMonths:
            let start = calendar.date(byAdding: .month, value: -3, to: now)!
            return (start, now)

        case .all:
            return nil
        }
    }
}

// MARK: - Search Result

/// A single search result
public struct SearchResult: Identifiable, Sendable {
    public let id: UUID
    public let sessionId: UUID
    public let messageId: UUID
    public let sessionTitle: String
    public let projectName: String
    public let matchedContent: String
    public let highlightRanges: [(Int, Int)]  // Store as (offset, length) pairs for Codable
    public let timestamp: Date
    public let relevanceScore: Double

    public init(
        id: UUID = UUID(),
        sessionId: UUID,
        messageId: UUID,
        sessionTitle: String,
        projectName: String,
        matchedContent: String,
        highlightRanges: [(Int, Int)],
        timestamp: Date,
        relevanceScore: Double = 1.0
    ) {
        self.id = id
        self.sessionId = sessionId
        self.messageId = messageId
        self.sessionTitle = sessionTitle
        self.projectName = projectName
        self.matchedContent = matchedContent
        self.highlightRanges = highlightRanges
        self.timestamp = timestamp
        self.relevanceScore = relevanceScore
    }

    /// Attributed string with highlights
    public func highlightedContent() -> AttributedString {
        var result = AttributedString(matchedContent)

        for (offset, length) in highlightRanges {
            let startIndex = result.characters.index(result.startIndex, offsetBy: offset)
            let endIndex = result.characters.index(startIndex, offsetBy: length)
            result[startIndex..<endIndex].backgroundColor = .yellow.opacity(0.3)
        }

        return result
    }
}

// MARK: - SearchResult Codable

extension SearchResult: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, sessionId, messageId, sessionTitle, projectName
        case matchedContent, highlightRanges, timestamp, relevanceScore
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        sessionId = try container.decode(UUID.self, forKey: .sessionId)
        messageId = try container.decode(UUID.self, forKey: .messageId)
        sessionTitle = try container.decode(String.self, forKey: .sessionTitle)
        projectName = try container.decode(String.self, forKey: .projectName)
        matchedContent = try container.decode(String.self, forKey: .matchedContent)

        // Decode highlight ranges as array of [Int] pairs
        let rangeArrays = try container.decode([[Int]].self, forKey: .highlightRanges)
        highlightRanges = rangeArrays.compactMap { array in
            guard array.count == 2 else { return nil }
            return (array[0], array[1])
        }

        timestamp = try container.decode(Date.self, forKey: .timestamp)
        relevanceScore = try container.decode(Double.self, forKey: .relevanceScore)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(messageId, forKey: .messageId)
        try container.encode(sessionTitle, forKey: .sessionTitle)
        try container.encode(projectName, forKey: .projectName)
        try container.encode(matchedContent, forKey: .matchedContent)

        // Encode highlight ranges as array of [Int] pairs
        let rangeArrays = highlightRanges.map { [$0.0, $0.1] }
        try container.encode(rangeArrays, forKey: .highlightRanges)

        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(relevanceScore, forKey: .relevanceScore)
    }
}

// MARK: - History Search Service

/// Service for searching through history
public actor HistorySearchService {

    // MARK: - Singleton

    public static let shared = HistorySearchService()

    // MARK: - Properties

    private let store: HistoryStore
    private let searchQueue = DispatchQueue(label: "com.claudedesktop.historysearch", qos: .userInitiated)

    // MARK: - Initialization

    public init(store: HistoryStore = .shared) {
        self.store = store
    }

    // MARK: - Public Methods

    /// Search history with the given query
    public func search(_ query: SearchQuery) async throws -> [SearchResult] {
        guard !query.keywords.isEmpty else {
            return []
        }

        let index = try await store.loadSearchIndex()
        let keywords = query.keywords.lowercased()
        let keywordWords = keywords.split(separator: " ").map(String.init)

        // Filter by time range
        let dateRange = query.timeRange?.dateRange()

        // Search entries
        var results: [SearchResult] = []

        for entry in index.entries {
            // Apply time filter
            if let range = dateRange {
                guard entry.timestamp >= range.start && entry.timestamp <= range.end else {
                    continue
                }
            }

            // Apply project filter
            if let projectName = query.projectName {
                guard entry.projectName.localizedCaseInsensitiveContains(projectName) else {
                    continue
                }
            }

            // Search content
            let content = entry.content.lowercased()
            let title = entry.sessionTitle.lowercased()

            // Calculate match score
            var matchScore = 0.0
            var highlightRanges: [(Int, Int)] = []

            for word in keywordWords {
                // Search in content
                if let range = content.range(of: word) {
                    matchScore += 1.0

                    // Calculate offset and length for the range
                    let offset = content.distance(from: content.startIndex, to: range.lowerBound)
                    let length = content.distance(from: range.lowerBound, to: range.upperBound)
                    highlightRanges.append((offset, length))
                }

                // Bonus for title match
                if title.contains(word) {
                    matchScore += 2.0
                }
            }

            guard matchScore > 0 else { continue }

            // Extract context around first match
            let context = extractContext(from: entry.content, around: keywords, contextLength: 150)

            let result = SearchResult(
                sessionId: entry.sessionId,
                messageId: entry.messageId,
                sessionTitle: entry.sessionTitle,
                projectName: entry.projectName,
                matchedContent: context,
                highlightRanges: highlightRanges,
                timestamp: entry.timestamp,
                relevanceScore: matchScore
            )

            results.append(result)
        }

        // Sort by relevance, then by timestamp
        results.sort { ($0.relevanceScore, $0.timestamp) > ($1.relevanceScore, $1.timestamp) }

        // Limit results
        return Array(results.prefix(50))
    }

    /// Quick search for autocomplete
    public func quickSearch(_ prefix: String) async throws -> [String] {
        guard prefix.count >= 2 else { return [] }

        let sessions = try await store.loadAllSessions()
        var suggestions = Set<String>()

        for session in sessions {
            // Add session titles that match
            if session.title.localizedCaseInsensitiveContains(prefix) {
                suggestions.insert(session.title)
            }

            // Add project names that match
            if let projectName = session.projectName,
               projectName.localizedCaseInsensitiveContains(prefix) {
                suggestions.insert(projectName)
            }
        }

        return Array(suggestions).sorted().prefix(10).map { $0 }
    }

    // MARK: - Private Methods

    private func extractContext(from content: String, around keywords: String, contextLength: Int) -> String {
        let lowercasedContent = content.lowercased()
        let lowercasedKeywords = keywords.lowercased()

        guard let range = lowercasedContent.range(of: lowercasedKeywords) else {
            // Return beginning if no match found
            let end = content.index(
                content.startIndex,
                offsetBy: min(contextLength, content.count),
                limitedBy: content.endIndex
            ) ?? content.endIndex
            return String(content[content.startIndex..<end])
        }

        // Calculate context window
        let contextStartOffset = contextLength / 2
        let start = content.index(
            range.lowerBound,
            offsetBy: -contextStartOffset,
            limitedBy: content.startIndex
        ) ?? content.startIndex

        let end = content.index(
            range.upperBound,
            offsetBy: contextLength - contextStartOffset,
            limitedBy: content.endIndex
        ) ?? content.endIndex

        var result = String(content[start..<end])

        // Add ellipsis if truncated
        if start != content.startIndex {
            result = "..." + result
        }
        if end != content.endIndex {
            result = result + "..."
        }

        return result
    }
}

// MARK: - Recent Searches

/// Manages recent search queries
@MainActor
@Observable
public final class RecentSearches {

    public static let shared = RecentSearches()

    public var searches: [SearchQuery] = []
    public var maxCount: Int = 10

    private let key = "RecentSearches"

    private init() {
        load()
    }

    public func add(_ query: SearchQuery) {
        // Remove duplicates
        searches.removeAll { $0.keywords == query.keywords }

        // Add to beginning
        searches.insert(query, at: 0)

        // Trim to max count
        if searches.count > maxCount {
            searches = Array(searches.prefix(maxCount))
        }

        save()
    }

    public func clear() {
        searches.removeAll()
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode([SearchQuery].self, from: data) else {
            return
        }
        searches = saved
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(searches) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
