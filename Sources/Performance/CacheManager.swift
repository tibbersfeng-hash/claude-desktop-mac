//
//  CacheManager.swift
//  ClaudeDesktopMac
//
//  Created by Claude Desktop Team on 2026-03-30.
//

import Foundation
import Combine

/// Cache configuration
public struct CacheConfig: Sendable {
    public let maxMemorySize: UInt64
    public let maxDiskSize: UInt64
    public let defaultExpiration: TimeInterval
    public let cleanupInterval: TimeInterval

    public init(
        maxMemorySize: UInt64 = 100 * 1024 * 1024, // 100 MB
        maxDiskSize: UInt64 = 500 * 1024 * 1024,   // 500 MB
        defaultExpiration: TimeInterval = 3600,    // 1 hour
        cleanupInterval: TimeInterval = 300        // 5 minutes
    ) {
        self.maxMemorySize = maxMemorySize
        self.maxDiskSize = maxDiskSize
        self.defaultExpiration = defaultExpiration
        self.cleanupInterval = cleanupInterval
    }
}

/// Cache entry metadata
public struct CacheEntryMetadata: Codable, Sendable {
    public let key: String
    public let createdAt: Date
    public let expiresAt: Date
    public let size: UInt64
    public let accessCount: Int
    public let lastAccessedAt: Date

    public var isExpired: Bool {
        Date() > expiresAt
    }
}

/// Cache statistics
public struct CacheStatistics: Sendable {
    public let memoryCacheCount: Int
    public let memoryCacheSize: UInt64
    public let diskCacheCount: Int
    public let diskCacheSize: UInt64
    public let hitRate: Double
    public let missRate: Double

    public var totalSize: UInt64 {
        memoryCacheSize + diskCacheSize
    }
}

/// Cache Manager - unified cache management for the application
@MainActor
public final class CacheManager: ObservableObject {
    // MARK: - Published Properties

    @Published public private(set) var statistics: CacheStatistics?

    // MARK: - Private Properties

    private let config: CacheConfig
    private let memoryCache: NSCache<NSString, CacheEntry>
    private let diskCacheURL: URL
    private var metadataCache: [String: CacheEntryMetadata] = [:]
    private var cleanupTimer: Timer?

    // Statistics tracking
    private var hitCount: Int = 0
    private var missCount: Int = 0
    private var currentMemorySize: UInt64 = 0
    private var currentDiskSize: UInt64 = 0

    // MARK: - Singleton

    public static let shared = CacheManager()

    // MARK: - Initialization

    public init(config: CacheConfig = CacheConfig()) {
        self.config = config

        // Setup memory cache
        self.memoryCache = NSCache()
        memoryCache.totalCostLimit = Int(config.maxMemorySize)
        memoryCache.countLimit = 1000

        // Setup disk cache URL
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.diskCacheURL = cacheURL.appendingPathComponent("ClaudeDesktopCache", isDirectory: true)

        // Create disk cache directory
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)

        // Start cleanup timer
        startCleanupTimer()

        // Load existing metadata
        Task {
            await loadMetadataFromDisk()
        }
    }

    // MARK: - Public Methods - Memory Cache

    /// Store value in memory cache
    public func setMemory<T: Codable & Sendable>(_ value: T, forKey key: String, expiration: TimeInterval? = nil) {
        let exp = expiration ?? config.defaultExpiration
        let entry = CacheEntry(value: value, expiresAt: Date().addingTimeInterval(exp))

        // Estimate size
        let size = estimateSize(of: value)

        memoryCache.setObject(entry, forKey: key as NSString, cost: Int(size))
        currentMemorySize += size

        // Update statistics
        updateStatistics()
    }

    /// Get value from memory cache
    public func getMemory<T: Codable & Sendable>(_ key: String) -> T? {
        guard let entry = memoryCache.object(forKey: key as NSString) else {
            missCount += 1
            return nil
        }

        if entry.isExpired {
            memoryCache.removeObject(forKey: key as NSString)
            missCount += 1
            return nil
        }

        hitCount += 1
        return entry.value as? T
    }

    /// Remove value from memory cache
    public func removeMemory(_ key: String) {
        memoryCache.removeObject(forKey: key as NSString)
        updateStatistics()
    }

    // MARK: - Public Methods - Disk Cache

    /// Store value in disk cache
    public func setDisk<T: Codable & Sendable>(_ value: T, forKey key: String, expiration: TimeInterval? = nil) async throws {
        let exp = expiration ?? config.defaultExpiration
        let fileURL = diskCacheURL.appendingPathComponent(safeFilename(from: key))

        // Encode value
        let data = try JSONEncoder().encode(value)

        // Write to disk
        try data.write(to: fileURL)

        // Update metadata
        let metadata = CacheEntryMetadata(
            key: key,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(exp),
            size: UInt64(data.count),
            accessCount: 0,
            lastAccessedAt: Date()
        )
        metadataCache[key] = metadata
        currentDiskSize += UInt64(data.count)

        // Save metadata
        try await saveMetadataToDisk()

        // Check disk size limit
        await cleanupDiskCacheIfNeeded()

        updateStatistics()
    }

    /// Get value from disk cache
    public func getDisk<T: Codable & Sendable>(_ key: String) async throws -> T? {
        guard let metadata = metadataCache[key], !metadata.isExpired else {
            missCount += 1
            return nil
        }

        let fileURL = diskCacheURL.appendingPathComponent(safeFilename(from: key))

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            metadataCache.removeValue(forKey: key)
            missCount += 1
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        let value = try JSONDecoder().decode(T.self, from: data)

        hitCount += 1

        // Update access count
        var updatedMetadata = metadata
        updatedMetadata = CacheEntryMetadata(
            key: metadata.key,
            createdAt: metadata.createdAt,
            expiresAt: metadata.expiresAt,
            size: metadata.size,
            accessCount: metadata.accessCount + 1,
            lastAccessedAt: Date()
        )
        metadataCache[key] = updatedMetadata

        return value
    }

    /// Remove value from disk cache
    public func removeDisk(_ key: String) async throws {
        let fileURL = diskCacheURL.appendingPathComponent(safeFilename(from: key))

        if let metadata = metadataCache[key] {
            currentDiskSize -= metadata.size
            metadataCache.removeValue(forKey: key)
        }

        try FileManager.default.removeItem(at: fileURL)
        try await saveMetadataToDisk()
        updateStatistics()
    }

    // MARK: - Public Methods - Unified Cache

    /// Store value in cache (memory + disk)
    public func set<T: Codable & Sendable>(_ value: T, forKey key: String, expiration: TimeInterval? = nil) async throws {
        // Store in memory
        setMemory(value, forKey: key, expiration: expiration)

        // Store on disk
        try await setDisk(value, forKey: key, expiration: expiration)
    }

    /// Get value from cache (memory first, then disk)
    public func get<T: Codable & Sendable>(_ key: String) async throws -> T? {
        // Try memory first
        if let value: T = getMemory(key) {
            return value
        }

        // Try disk
        if let value: T = try await getDisk(key) {
            // Promote to memory cache
            setMemory(value, forKey: key)
            return value
        }

        return nil
    }

    /// Remove value from all caches
    public func remove(_ key: String) async throws {
        removeMemory(key)
        try await removeDisk(key)
    }

    /// Clear all caches
    public func clearAll() async throws {
        // Clear memory cache
        memoryCache.removeAllObjects()
        currentMemorySize = 0

        // Clear disk cache
        if FileManager.default.fileExists(atPath: diskCacheURL.path) {
            try FileManager.default.removeItem(at: diskCacheURL)
            try FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        }

        metadataCache.removeAll()
        currentDiskSize = 0

        // Reset statistics
        hitCount = 0
        missCount = 0

        updateStatistics()
    }

    /// Clear expired entries
    public func clearExpired() async throws {
        // Clear expired memory entries (handled by NSCache automatically on access)

        // Clear expired disk entries
        let expiredKeys = metadataCache.filter { $0.value.isExpired }.keys

        for key in expiredKeys {
            try await removeDisk(key)
        }

        updateStatistics()
    }

    /// Get cache statistics
    public func getStatistics() -> CacheStatistics {
        return CacheStatistics(
            memoryCacheCount: memoryCache.countLimit,
            memoryCacheSize: currentMemorySize,
            diskCacheCount: metadataCache.count,
            diskCacheSize: currentDiskSize,
            hitRate: calculateHitRate(),
            missRate: calculateMissRate()
        )
    }

    // MARK: - Private Methods

    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: config.cleanupInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                try? await self?.clearExpired()
            }
        }
        cleanupTimer?.tolerance = config.cleanupInterval * 0.1
    }

    private func loadMetadataFromDisk() async {
        let metadataURL = diskCacheURL.appendingPathComponent("metadata.json")

        guard let data = try? Data(contentsOf: metadataURL),
              let metadata = try? JSONDecoder().decode([String: CacheEntryMetadata].self, from: data) else {
            return
        }

        metadataCache = metadata

        // Calculate current disk size
        currentDiskSize = metadata.values.reduce(0) { $0 + $1.size }
    }

    private func saveMetadataToDisk() async throws {
        let metadataURL = diskCacheURL.appendingPathComponent("metadata.json")
        let data = try JSONEncoder().encode(metadataCache)
        try data.write(to: metadataURL)
    }

    private func cleanupDiskCacheIfNeeded() async {
        guard currentDiskSize > config.maxDiskSize else { return }

        // Sort by last accessed (LRU eviction)
        let sortedEntries = metadataCache.sorted { $0.value.lastAccessedAt < $1.value.lastAccessedAt }

        for (key, metadata) in sortedEntries {
            if currentDiskSize <= config.maxDiskSize * 80 / 100 { // Clean to 80%
                break
            }

            try? await removeDisk(key)
        }
    }

    private func estimateSize<T: Codable>(of value: T) -> UInt64 {
        // Rough estimate based on encoded size
        guard let data = try? JSONEncoder().encode(value) else { return 1024 }
        return UInt64(data.count)
    }

    private func safeFilename(from key: String) -> String {
        // Create a safe filename from key
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
    }

    private func updateStatistics() {
        statistics = getStatistics()
    }

    private func calculateHitRate() -> Double {
        let total = hitCount + missCount
        return total > 0 ? Double(hitCount) / Double(total) : 0
    }

    private func calculateMissRate() -> Double {
        let total = hitCount + missCount
        return total > 0 ? Double(missCount) / Double(total) : 0
    }
}

// MARK: - Cache Entry

/// Internal cache entry wrapper
private final class CacheEntry: NSObject {
    let value: Any
    let expiresAt: Date

    init(value: Any, expiresAt: Date) {
        self.value = value
        self.expiresAt = expiresAt
    }

    var isExpired: Bool {
        Date() > expiresAt
    }
}

// MARK: - Specialized Caches

/// Code highlighting cache
public final class HighlightingCache: @unchecked Sendable {
    private var cache: [String: AttributedString] = [:]
    private let lock = NSLock()
    private let maxSize: Int

    public init(maxSize: Int = 500) {
        self.maxSize = maxSize
    }

    public func get(for code: String) -> AttributedString? {
        lock.lock()
        defer { lock.unlock() }
        return cache[hash(code)]
    }

    public func set(_ attributedString: AttributedString, for code: String) {
        lock.lock()
        defer { lock.unlock() }

        let key = hash(code)

        // Evict if over limit
        if cache.count >= maxSize {
            cache.removeValue(forKey: cache.keys.first!)
        }

        cache[key] = attributedString
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
    }

    private func hash(_ code: String) -> String {
        // Simple hash for cache key
        return String(code.hashValue)
    }
}

/// Markdown rendering cache
public final class MarkdownCache: @unchecked Sendable {
    private var cache: [String: AttributedString] = [:]
    private let lock = NSLock()
    private let maxSize: Int

    public init(maxSize: Int = 200) {
        self.maxSize = maxSize
    }

    public func get(for markdown: String) -> AttributedString? {
        lock.lock()
        defer { lock.unlock() }
        return cache[hash(markdown)]
    }

    public func set(_ attributedString: AttributedString, for markdown: String) {
        lock.lock()
        defer { lock.unlock() }

        let key = hash(markdown)

        // Evict if over limit
        if cache.count >= maxSize {
            cache.removeValue(forKey: cache.keys.first!)
        }

        cache[key] = attributedString
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
    }

    private func hash(_ markdown: String) -> String {
        return String(markdown.hashValue)
    }
}

/// Session data cache
public final class SessionDataCache: @unchecked Sendable {
    private var cache: [String: SessionCachedData] = [:]
    private let lock = NSLock()
    private var accessOrder: [String] = []
    private let maxCount: Int

    public init(maxCount: Int = 5) {
        self.maxCount = maxCount
    }

    public func get(sessionId: String) -> SessionCachedData? {
        lock.lock()
        defer { lock.unlock() }

        // Update access order
        accessOrder.removeAll { $0 == sessionId }
        accessOrder.append(sessionId)

        return cache[sessionId]
    }

    public func set(_ data: SessionCachedData, sessionId: String) {
        lock.lock()
        defer { lock.unlock() }

        cache[sessionId] = data
        accessOrder.removeAll { $0 == sessionId }
        accessOrder.append(sessionId)

        // Evict oldest
        while cache.count > maxCount, let oldest = accessOrder.first {
            cache.removeValue(forKey: oldest)
            accessOrder.removeFirst()
        }
    }

    public func remove(sessionId: String) {
        lock.lock()
        defer { lock.unlock() }
        cache.removeValue(forKey: sessionId)
        accessOrder.removeAll { $0 == sessionId }
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
        accessOrder.removeAll()
    }
}

/// Cached session data
public struct SessionCachedData: Sendable {
    public let messages: [String]  // Message IDs
    public let lastMessageTimestamp: Date?
    public let metadata: [String: String]

    public init(messages: [String], lastMessageTimestamp: Date?, metadata: [String: String] = [:]) {
        self.messages = messages
        self.lastMessageTimestamp = lastMessageTimestamp
        self.metadata = metadata
    }
}

// MARK: - SwiftUI View for Cache Stats

import SwiftUI

public struct CacheStatisticsView: View {
    @ObservedObject private var cacheManager: CacheManager

    public init(cacheManager: CacheManager = .shared) {
        self.cacheManager = cacheManager
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cache Statistics")
                .font(.headline)

            if let stats = cacheManager.statistics {
                HStack {
                    StatRow(title: "Memory", value: formatBytes(stats.memoryCacheSize))
                    StatRow(title: "Disk", value: formatBytes(stats.diskCacheSize))
                }

                HStack {
                    StatRow(title: "Hit Rate", value: String(format: "%.1f%%", stats.hitRate * 100))
                    StatRow(title: "Total", value: formatBytes(stats.totalSize))
                }

                HStack {
                    StatRow(title: "Memory Items", value: "\(stats.memoryCacheCount)")
                    StatRow(title: "Disk Items", value: "\(stats.diskCacheCount)")
                }
            } else {
                Text("No statistics available")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let mb = Double(bytes) / (1024 * 1024)
        return String(format: "%.1f MB", mb)
    }
}

struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .monospacedDigit()
        }
        .frame(minWidth: 80, alignment: .leading)
    }
}
