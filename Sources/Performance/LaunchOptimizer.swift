//
//  LaunchOptimizer.swift
//  ClaudeDesktopMac
//
//  Created by Claude Desktop Team on 2026-03-30.
//

import Foundation
import Combine

/// Launch phase for tracking startup progress
public enum LaunchPhase: Int, Sendable, Comparable {
    case notStarted = 0
    case initializing = 1
    case loadingUI = 2
    case connecting = 3
    case ready = 4

    public var description: String {
        switch self {
        case .notStarted: return "Not Started"
        case .initializing: return "Initializing..."
        case .loadingUI: return "Loading UI..."
        case .connecting: return "Connecting..."
        case .ready: return "Ready"
        }
    }

    public static func < (lhs: LaunchPhase, rhs: LaunchPhase) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// Launch metrics tracking
public struct LaunchMetrics: Sendable {
    public let launchStartTime: Date
    public let firstFrameTime: Date?
    public let connectionEstablishedTime: Date?
    public let readyTime: Date?
    public let phaseTimings: [LaunchPhase: TimeInterval]

    public var totalLaunchTime: TimeInterval? {
        guard let readyTime = readyTime else { return nil }
        return readyTime.timeIntervalSince(launchStartTime)
    }

    public var timeToFirstFrame: TimeInterval? {
        guard let firstFrameTime = firstFrameTime else { return nil }
        return firstFrameTime.timeIntervalSince(launchStartTime)
    }

    public var timeToConnection: TimeInterval? {
        guard let connectionEstablishedTime = connectionEstablishedTime else { return nil }
        return connectionEstablishedTime.timeIntervalSince(launchStartTime)
    }
}

/// Launch task priority
public enum LaunchTaskPriority: Sendable {
    case critical      // Must complete before UI shows
    case high         // Should complete quickly after UI shows
    case normal       // Can be delayed slightly
    case low          // Can be delayed significantly
    case background   // Can run anytime after launch
}

/// A launch task to be executed during startup
public struct LaunchTask: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let priority: LaunchTaskPriority
    public let action: @Sendable () async throws -> Void
    public let timeout: TimeInterval?

    public init(
        id: String,
        name: String,
        priority: LaunchTaskPriority,
        timeout: TimeInterval? = nil,
        action: @escaping @Sendable () async throws -> Void
    ) {
        self.id = id
        self.name = name
        self.priority = priority
        self.timeout = timeout
        self.action = action
    }
}

/// Launch Optimizer - manages application startup sequence
@MainActor
public final class LaunchOptimizer: ObservableObject {
    // MARK: - Published Properties

    @Published public private(set) var currentPhase: LaunchPhase = .notStarted
    @Published public private(set) var phaseProgress: Double = 0.0
    @Published public private(set) var currentTask: String = ""
    @Published public private(set) var isReady: Bool = false
    @Published public private(set) var launchMetrics: LaunchMetrics?

    // MARK: - Private Properties

    private var tasks: [LaunchTask] = []
    private var phaseTimings: [LaunchPhase: TimeInterval] = [:]
    private var launchStartTime: Date?
    private var firstFrameTime: Date?
    private var connectionEstablishedTime: Date?

    // Preloaded resources
    private var preloadedResources: [String: Any] = [:]
    private let preloadQueue = DispatchQueue(label: "com.claude.desktop.preload", qos: .userInitiated)

    // MARK: - Initialization

    public init() {}

    // MARK: - Public Methods

    /// Register a launch task
    public func registerTask(_ task: LaunchTask) {
        tasks.append(task)
    }

    /// Register multiple launch tasks
    public func registerTasks(_ tasks: [LaunchTask]) {
        self.tasks.append(contentsOf: tasks)
    }

    /// Start the launch sequence
    public func startLaunch() async {
        launchStartTime = Date()
        currentPhase = .initializing

        // Record start time
        phaseTimings[.initializing] = 0

        // Execute critical tasks first
        await executeTasks(withPriority: .critical)

        // Transition to UI loading
        currentPhase = .loadingUI
        phaseTimings[.loadingUI] = Date().timeIntervalSince(launchStartTime!)
        firstFrameTime = Date()

        // Execute high priority tasks
        await executeTasks(withPriority: .high)

        // Start background preloading
        startBackgroundPreloading()

        // Mark as ready for user interaction
        currentPhase = .connecting
        phaseTimings[.connecting] = Date().timeIntervalSince(launchStartTime!)

        // Execute normal priority tasks
        await executeTasks(withPriority: .normal)

        // Execute low priority tasks
        await executeTasks(withPriority: .low)

        // Mark as fully ready
        currentPhase = .ready
        phaseTimings[.ready] = Date().timeIntervalSince(launchStartTime!)
        isReady = true

        // Record metrics
        launchMetrics = LaunchMetrics(
            launchStartTime: launchStartTime!,
            firstFrameTime: firstFrameTime,
            connectionEstablishedTime: connectionEstablishedTime,
            readyTime: Date(),
            phaseTimings: phaseTimings
        )

        // Log launch metrics
        logLaunchMetrics()
    }

    /// Record connection established
    public func recordConnectionEstablished() {
        connectionEstablishedTime = Date()
    }

    /// Get preloaded resource
    public func getPreloadedResource<T>(key: String) -> T? {
        return preloadedResources[key] as? T
    }

    /// Set preloaded resource
    public func setPreloadedResource<T>(key: String, value: T) {
        preloadedResources[key] = value
    }

    /// Clear preloaded resources (call after they're no longer needed)
    public func clearPreloadedResources() {
        preloadedResources.removeAll()
    }

    // MARK: - Private Methods

    private func executeTasks(withPriority priority: LaunchTaskPriority) async {
        let tasksToExecute = tasks
            .filter { $0.priority == priority }
            .sorted { $0.id < $1.id }

        for task in tasksToExecute {
            currentTask = task.name

            do {
                if let timeout = task.timeout {
                    try await withTimeout(timeout) {
                        try await task.action()
                    }
                } else {
                    try await task.action()
                }
            } catch {
                // Log error but continue
                print("[LaunchOptimizer] Task '\(task.name)' failed: \(error)")
            }

            // Update progress
            updateProgress()
        }

        currentTask = ""
    }

    private func startBackgroundPreloading() {
        // Start background task for low priority preloading
        Task.detached(priority: .background) { [weak self] in
            await self?.preloadCommonResources()
        }
    }

    private nonisolated func preloadCommonResources() async {
        // Preload common resources in background
        // This could include fonts, icons, cached data, etc.

        // Example: Preload common fonts
        _ = NSFont.systemFont(ofSize: 13)
        _ = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        _ = NSFont.systemFont(ofSize: 13, weight: .medium)

        // Notify main thread when done
        await MainActor.run {
            NotificationCenter.default.post(
                name: .preloadCompleted,
                object: nil
            )
        }
    }

    private func updateProgress() {
        let totalTasks = tasks.count
        let completedTasks = tasks.filter { task in
            // Check if task was completed (simplified)
            return true
        }.count

        phaseProgress = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 1.0
    }

    private func logLaunchMetrics() {
        guard let metrics = launchMetrics else { return }

        var log = "[LaunchOptimizer] Launch completed:\n"

        if let ttf = metrics.timeToFirstFrame {
            log += "  Time to first frame: \(String(format: "%.2f", ttf * 1000))ms\n"
        }

        if let ttc = metrics.timeToConnection {
            log += "  Time to connection: \(String(format: "%.2f", ttc * 1000))ms\n"
        }

        if let total = metrics.totalLaunchTime {
            log += "  Total launch time: \(String(format: "%.2f", total * 1000))ms"
        }

        print(log)
    }

    private func withTimeout<T>(_ seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw LaunchError.timeout
            }

            guard let result = try await group.next() else {
                throw LaunchError.noResult
            }

            group.cancelAll()
            return result
        }
    }
}

// MARK: - Launch Error

public enum LaunchError: Error, LocalizedError {
    case timeout
    case noResult
    case taskFailed(String)

    public var errorDescription: String? {
        switch self {
        case .timeout:
            return "Launch task timed out"
        case .noResult:
            return "Launch task returned no result"
        case .taskFailed(let message):
            return "Launch task failed: \(message)"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    public static let preloadCompleted = Notification.Name("com.claude.desktop.preloadCompleted")
}

// MARK: - Resource Preloader

/// Resource Preloader - preloads resources for faster access
public actor ResourcePreloader {
    public static let shared = ResourcePreloader()

    private var preloadedImages: [String: NSImage] = [:]
    private var preloadedFonts: [String: NSFont] = [:]
    private var preloadedData: [String: Data] = [:]

    private init() {}

    /// Preload an image
    public func preloadImage(named name: String) {
        if let image = NSImage(named: name) {
            preloadedImages[name] = image
        }
    }

    /// Get a preloaded image
    public func getImage(named name: String) -> NSImage? {
        return preloadedImages[name] ?? NSImage(named: name)
    }

    /// Preload a font
    public func preloadFont(name: String, size: CGFloat, weight: NSFont.Weight = .regular) {
        let font = NSFont.systemFont(ofSize: size, weight: weight)
        preloadedFonts[name] = font
    }

    /// Get a preloaded font
    public func getFont(named name: String) -> NSFont? {
        return preloadedFonts[name]
    }

    /// Preload data from file
    public func preloadData(from url: URL, key: String) async throws {
        let data = try Data(contentsOf: url)
        preloadedData[key] = data
    }

    /// Get preloaded data
    public func getData(key: String) -> Data? {
        return preloadedData[key]
    }

    /// Clear all preloaded resources
    public func clearAll() {
        preloadedImages.removeAll()
        preloadedFonts.removeAll()
        preloadedData.removeAll()
    }
}

// MARK: - App Startup Configuration

/// Startup configuration
public struct StartupConfig: Sendable {
    public let showSplashScreen: Bool
    public let quickLaunchEnabled: Bool
    public let preloadCommonResources: Bool
    public let maxCriticalTaskDuration: TimeInterval
    public let maxHighTaskDuration: TimeInterval

    public init(
        showSplashScreen: Bool = false,
        quickLaunchEnabled: Bool = true,
        preloadCommonResources: Bool = true,
        maxCriticalTaskDuration: TimeInterval = 0.5,
        maxHighTaskDuration: TimeInterval = 1.0
    ) {
        self.showSplashScreen = showSplashScreen
        self.quickLaunchEnabled = quickLaunchEnabled
        self.preloadCommonResources = preloadCommonResources
        self.maxCriticalTaskDuration = maxCriticalTaskDuration
        self.maxHighTaskDuration = maxHighTaskDuration
    }
}

// MARK: - SwiftUI View Extensions

import SwiftUI

/// Launch progress view
public struct LaunchProgressView: View {
    @ObservedObject private var optimizer: LaunchOptimizer

    public init(optimizer: LaunchOptimizer) {
        self.optimizer = optimizer
    }

    public var body: some View {
        VStack(spacing: 16) {
            // App icon
            Image(systemName: "cpu.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            // App name
            Text("Claude Desktop")
                .font(.title2)
                .fontWeight(.medium)

            // Progress
            VStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(.linear)
                    .frame(width: 200)

                Text(optimizer.currentPhase.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if !optimizer.currentTask.isEmpty {
                    Text(optimizer.currentTask)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(32)
    }
}
