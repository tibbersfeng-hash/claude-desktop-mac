//
//  MemoryManager.swift
//  ClaudeDesktopMac
//
//  Created by Claude Desktop Team on 2026-03-30.
//

import Foundation
import Combine

/// Memory management configuration
public struct MemoryConfig: Sendable {
    public let maxCacheSize: UInt64
    public let maxImageCacheCount: Int
    public let maxSessionCount: Int
    public let warningThreshold: Double
    public let criticalThreshold: Double

    public init(
        maxCacheSize: UInt64 = 200 * 1024 * 1024, // 200 MB
        maxImageCacheCount: Int = 100,
        maxSessionCount: Int = 5,
        warningThreshold: Double = 0.7, // 70% of max
        criticalThreshold: Double = 0.9 // 90% of max
    ) {
        self.maxCacheSize = maxCacheSize
        self.maxImageCacheCount = maxImageCacheCount
        self.maxSessionCount = maxSessionCount
        self.warningThreshold = warningThreshold
        self.criticalThreshold = criticalThreshold
    }
}

/// Memory warning level
public enum MemoryWarningLevel: Int, Sendable, Comparable {
    case normal = 0
    case warning = 1
    case critical = 2
    case severe = 3

    public static func < (lhs: MemoryWarningLevel, rhs: MemoryWarningLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// Memory Manager - handles memory optimization and cleanup
@MainActor
public final class MemoryManager: ObservableObject {
    // MARK: - Published Properties

    @Published public private(set) var currentUsage: UInt64 = 0
    @Published public private(set) var warningLevel: MemoryWarningLevel = .normal
    @Published public private(set) var isUnderMemoryPressure: Bool = false

    // MARK: - Private Properties

    private let config: MemoryConfig
    private var cancellables = Set<AnyCancellable>()

    // Cache management
    private var caches: [String: any CacheProtocol] = [:]
    private var cleanupTimer: Timer?

    // Session data tracking
    private var loadedSessions: [String: SessionMemoryInfo] = [:]
    private var lruOrder: [String] = []

    // MARK: - Singleton

    public static let shared = MemoryManager()

    // MARK: - Initialization

    public init(config: MemoryConfig = MemoryConfig()) {
        self.config = config
        setupMemoryWarningHandling()
        startCleanupTimer()
    }

    // MARK: - Public Methods

    /// Register a cache for management
    public func registerCache(_ cache: any CacheProtocol, withName name: String) {
        caches[name] = cache
    }

    /// Unregister a cache
    public func unregisterCache(named name: String) {
        caches.removeValue(forKey: name)
    }

    /// Track session memory usage
    public func trackSession(_ sessionId: String, memoryUsage: UInt64) {
        let info = SessionMemoryInfo(
            id: sessionId,
            memoryUsage: memoryUsage,
            lastAccessed: Date()
        )

        // Update or add
        if loadedSessions[sessionId] != nil {
            lruOrder.removeAll { $0 == sessionId }
        }

        loadedSessions[sessionId] = info
        lruOrder.append(sessionId)

        // Evict old sessions if over limit
        while loadedSessions.count > config.maxSessionCount {
            evictOldestSession()
        }

        updateMemoryUsage()
    }

    /// Untrack session
    public func untrackSession(_ sessionId: String) {
        loadedSessions.removeValue(forKey: sessionId)
        lruOrder.removeAll { $0 == sessionId }
        updateMemoryUsage()
    }

    /// Update session access time (for LRU)
    public func touchSession(_ sessionId: String) {
        if var info = loadedSessions[sessionId] {
            info.lastAccessed = Date()
            loadedSessions[sessionId] = info
            lruOrder.removeAll { $0 == sessionId }
            lruOrder.append(sessionId)
        }
    }

    /// Force memory cleanup
    public func forceCleanup() {
        // Clear all caches
        for cache in caches.values {
            cache.clear()
        }

        // Clear old sessions
        while loadedSessions.count > config.maxSessionCount / 2 {
            evictOldestSession()
        }

        updateMemoryUsage()
    }

    /// Get memory report
    public func getMemoryReport() -> MemoryReport {
        var cacheReports: [CacheReport] = []

        for (name, cache) in caches {
            cacheReports.append(CacheReport(
                name: name,
                itemCount: cache.itemCount,
                memoryUsage: cache.estimatedMemoryUsage
            ))
        }

        return MemoryReport(
            totalUsage: currentUsage,
            maxAllowed: config.maxCacheSize,
            warningLevel: warningLevel,
            sessions: loadedSessions.map { (key, value) in
                SessionReport(id: key, memoryUsage: value.memoryUsage)
            },
            caches: cacheReports
        )
    }

    /// Check if should load more data
    public func canLoadMore(estimatedSize: UInt64) -> Bool {
        let projectedUsage = currentUsage + estimatedSize
        return projectedUsage < UInt64(Double(config.maxCacheSize) * config.criticalThreshold)
    }

    // MARK: - Private Methods

    private func setupMemoryWarningHandling() {
        // Listen for system memory warnings
        NotificationCenter.default
            .publisher(for: NSApplication.didReceiveMemoryWarningNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleMemoryWarning()
            }
            .store(in: &cancellables)

        // Monitor memory pressure
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkMemoryPressure()
            }
        }
    }

    private func startCleanupTimer() {
        // Periodic cleanup every 5 minutes
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.periodicCleanup()
            }
        }
        cleanupTimer?.tolerance = 60
    }

    private func checkMemoryPressure() {
        let availableMemory = os_proc_available_memory()
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let usageRatio = 1.0 - Double(availableMemory) / Double(totalMemory)

        isUnderMemoryPressure = usageRatio > config.warningThreshold

        if usageRatio > config.criticalThreshold {
            warningLevel = .critical
            handleMemoryWarning()
        } else if usageRatio > config.warningThreshold {
            warningLevel = .warning
        } else {
            warningLevel = .normal
        }
    }

    private func handleMemoryWarning() {
        // Clear caches
        for cache in caches.values {
            cache.clear()
        }

        // Evict sessions
        while loadedSessions.count > 1 {
            evictOldestSession()
        }

        warningLevel = .severe
        updateMemoryUsage()

        // Post notification
        NotificationCenter.default.post(
            name: .memoryWarningOccurred,
            object: nil,
            userInfo: ["level": warningLevel]
        )
    }

    private func periodicCleanup() {
        // Remove expired items from caches
        for cache in caches.values {
            cache.removeExpired()
        }

        // Evict old sessions
        let cutoff = Date().addingTimeInterval(-3600) // 1 hour ago
        let oldSessions = loadedSessions.filter { $0.value.lastAccessed < cutoff }

        for (sessionId, _) in oldSessions where loadedSessions.count > 1 {
            evictSession(sessionId)
        }

        updateMemoryUsage()
    }

    private func evictOldestSession() {
        guard let oldestId = lruOrder.first else { return }
        evictSession(oldestId)
    }

    private func evictSession(_ sessionId: String) {
        loadedSessions.removeValue(forKey: sessionId)
        lruOrder.removeAll { $0 == sessionId }

        // Notify about eviction
        NotificationCenter.default.post(
            name: .sessionEvicted,
            object: nil,
            userInfo: ["sessionId": sessionId]
        )
    }

    private func updateMemoryUsage() {
        var total: UInt64 = 0

        // Add cache usage
        for cache in caches.values {
            total += cache.estimatedMemoryUsage
        }

        // Add session usage
        for info in loadedSessions.values {
            total += info.memoryUsage
        }

        currentUsage = total

        // Update warning level
        let usageRatio = Double(currentUsage) / Double(config.maxCacheSize)

        if usageRatio > config.criticalThreshold {
            warningLevel = max(warningLevel, .critical)
        } else if usageRatio > config.warningThreshold {
            warningLevel = max(warningLevel, .warning)
        }
    }
}

// MARK: - Supporting Types

/// Session memory information
private struct SessionMemoryInfo: Sendable {
    let id: String
    let memoryUsage: UInt64
    let lastAccessed: Date
}

/// Memory report
public struct MemoryReport: Sendable {
    public let totalUsage: UInt64
    public let maxAllowed: UInt64
    public let warningLevel: MemoryWarningLevel
    public let sessions: [SessionReport]
    public let caches: [CacheReport]

    public var usagePercentage: Double {
        Double(totalUsage) / Double(maxAllowed) * 100
    }
}

/// Session report
public struct SessionReport: Sendable {
    public let id: String
    public let memoryUsage: UInt64
}

/// Cache report
public struct CacheReport: Sendable {
    public let name: String
    public let itemCount: Int
    public let memoryUsage: UInt64
}

/// Cache protocol for managed caches
public protocol CacheProtocol: AnyObject, Sendable {
    var itemCount: Int { get }
    var estimatedMemoryUsage: UInt64 { get }

    func clear()
    func removeExpired()
}

// MARK: - Notifications

extension Notification.Name {
    public static let memoryWarningOccurred = Notification.Name("com.claude.desktop.memoryWarning")
    public static let sessionEvicted = Notification.Name("com.claude.desktop.sessionEvicted")
}

// MARK: - Managed Cache Implementation

/// A managed cache that integrates with MemoryManager
public final class ManagedCache<Key: Hashable & Sendable, Value: Sendable>: CacheProtocol {
    private var storage: [Key: CacheEntry] = [:]
    private let lock = NSLock()
    private let defaultExpiration: TimeInterval

    public var itemCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return storage.count
    }

    public var estimatedMemoryUsage: UInt64 {
        lock.lock()
        defer { lock.unlock() }
        // Rough estimation
        return UInt64(storage.count) * 1024 // 1KB per item estimate
    }

    public init(defaultExpiration: TimeInterval = 3600) {
        self.defaultExpiration = defaultExpiration
    }

    public func get(_ key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }

        guard let entry = storage[key] else { return nil }

        if entry.isExpired {
            storage.removeValue(forKey: key)
            return nil
        }

        return entry.value
    }

    public func set(_ key: Key, value: Value, expiration: TimeInterval? = nil) {
        lock.lock()
        defer { lock.unlock() }

        let entry = CacheEntry(
            value: value,
            expirationDate: Date().addingTimeInterval(expiration ?? defaultExpiration)
        )
        storage[key] = entry
    }

    public func remove(_ key: Key) {
        lock.lock()
        defer { lock.unlock() }
        storage.removeValue(forKey: key)
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
    }

    public func removeExpired() {
        lock.lock()
        defer { lock.unlock() }

        let now = Date()
        storage = storage.filter { !$0.value.isExpired }
    }

    private struct CacheEntry: Sendable {
        let value: Value
        let expirationDate: Date

        var isExpired: Bool {
            Date() > expirationDate
        }
    }
}

// MARK: - Image Cache

/// Specialized cache for images with memory-based eviction
public final class ImageCache: CacheProtocol, @unchecked Sendable {
    private var cache = NSCache<NSString, CacheWrapper>()
    private let lock = NSLock()

    public var itemCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return cache.totalCostLimit > 0 ? cache.countLimit : 0
    }

    public var estimatedMemoryUsage: UInt64 {
        lock.lock()
        defer { lock.unlock() }
        return UInt64(cache.totalCostLimit)
    }

    public init(maxMemoryMB: Int = 50, maxCount: Int = 100) {
        cache.totalCostLimit = maxMemoryMB * 1024 * 1024
        cache.countLimit = maxCount

        // Respond to memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: NSApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    public func get(_ key: String) -> Any? {
        return cache.object(forKey: key as NSString)?.value
    }

    public func set(_ value: Any, forKey key: String, cost: Int = 0) {
        let wrapper = CacheWrapper(value: value)
        cache.setObject(wrapper, forKey: key as NSString, cost: cost)
    }

    public func remove(_ key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    public func clear() {
        cache.removeAllObjects()
    }

    public func removeExpired() {
        // NSCache handles this automatically
    }

    @objc private func clearCache() {
        cache.removeAllObjects()
    }

    private class CacheWrapper {
        let value: Any
        init(value: Any) {
            self.value = value
        }
    }
}
