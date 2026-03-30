//
//  PerformanceMonitor.swift
//  ClaudeDesktopMac
//
//  Created by Claude Desktop Team on 2026-03-30.
//

import Foundation
import Combine

/// Performance metrics collected by the monitor
public struct PerformanceMetrics: Sendable {
    public let timestamp: Date
    public let cpuUsage: Double
    public let memoryUsage: UInt64
    public let memoryPressure: MemoryPressure
    public let threadCount: Int
    public let processCount: Int

    public init(
        timestamp: Date = Date(),
        cpuUsage: Double,
        memoryUsage: UInt64,
        memoryPressure: MemoryPressure,
        threadCount: Int,
        processCount: Int
    ) {
        self.timestamp = timestamp
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.memoryPressure = memoryPressure
        self.threadCount = threadCount
        self.processCount = processCount
    }

    /// Memory pressure level
    public enum MemoryPressure: String, Sendable {
        case normal = "Normal"
        case warning = "Warning"
        case critical = "Critical"

        public static func fromRawValue(_ value: Int) -> MemoryPressure {
            switch value {
            case 0: return .normal
            case 1: return .warning
            case 2: return .critical
            default: return .normal
            }
        }
    }
}

/// Performance alert types
public enum PerformanceAlert: Sendable {
    case highCPUUsage(percentage: Double)
    case highMemoryUsage(bytes: UInt64)
    case memoryPressure(PerformanceMetrics.MemoryPressure)
    case slowOperation(name: String, duration: TimeInterval)
    case threadExplosion(count: Int)
}

/// Performance monitoring configuration
public struct PerformanceMonitorConfig: Sendable {
    public let samplingInterval: TimeInterval
    public let cpuThreshold: Double
    public let memoryThreshold: UInt64
    public let threadThreshold: Int
    public let enableLogging: Bool

    public init(
        samplingInterval: TimeInterval = 5.0,
        cpuThreshold: Double = 80.0,
        memoryThreshold: UInt64 = 500 * 1024 * 1024, // 500 MB
        threadThreshold: Int = 100,
        enableLogging: Bool = true
    ) {
        self.samplingInterval = samplingInterval
        self.cpuThreshold = cpuThreshold
        self.memoryThreshold = memoryThreshold
        self.threadThreshold = threadThreshold
        self.enableLogging = enableLogging
    }
}

/// Performance Monitor - collects and reports performance metrics
@MainActor
public final class PerformanceMonitor: ObservableObject {
    // MARK: - Published Properties

    @Published public private(set) var currentMetrics: PerformanceMetrics?
    @Published public private(set) var isMonitoring: Bool = false
    @Published public private(set) var alerts: [PerformanceAlert] = []

    // MARK: - Private Properties

    private let config: PerformanceMonitorConfig
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let metricsQueue = DispatchQueue(label: "com.claude.desktop.metrics", qos: .utility)

    // Historical metrics storage
    private var metricsHistory: [PerformanceMetrics] = []
    private let maxHistoryCount = 100

    // MARK: - Initialization

    public init(config: PerformanceMonitorConfig = PerformanceMonitorConfig()) {
        self.config = config
    }

    // MARK: - Public Methods

    /// Start performance monitoring
    public func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true

        // Create timer on main run loop
        timer = Timer.scheduledTimer(withTimeInterval: config.samplingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.collectMetrics()
            }
        }

        // Allow some tolerance for power efficiency
        timer?.tolerance = config.samplingInterval * 0.1

        // Collect initial metrics
        Task {
            await collectMetrics()
        }
    }

    /// Stop performance monitoring
    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    /// Get metrics history
    public func getMetricsHistory() -> [PerformanceMetrics] {
        return metricsHistory
    }

    /// Get average metrics over a time period
    public func getAverageMetrics(over seconds: TimeInterval) -> PerformanceMetrics? {
        let cutoff = Date().addingTimeInterval(-seconds)
        let recentMetrics = metricsHistory.filter { $0.timestamp >= cutoff }

        guard !recentMetrics.isEmpty else { return nil }

        let avgCPU = recentMetrics.map(\.cpuUsage).reduce(0, +) / Double(recentMetrics.count)
        let avgMemory = recentMetrics.map(\.memoryUsage).reduce(0, +) / UInt64(recentMetrics.count)
        let avgThreads = recentMetrics.map(\.threadCount).reduce(0, +) / recentMetrics.count
        let avgProcesses = recentMetrics.map(\.processCount).reduce(0, +) / recentMetrics.count

        // Get most common memory pressure
        let pressureCounts = recentMetrics.reduce(into: [PerformanceMetrics.MemoryPressure: Int]()) { counts, metric in
            counts[metric.memoryPressure, default: 0] += 1
        }
        let mostCommonPressure = pressureCounts.max(by: { $0.value < $1.value })?.key ?? .normal

        return PerformanceMetrics(
            cpuUsage: avgCPU,
            memoryUsage: avgMemory,
            memoryPressure: mostCommonPressure,
            threadCount: avgThreads,
            processCount: avgProcesses
        )
    }

    /// Clear alerts
    public func clearAlerts() {
        alerts.removeAll()
    }

    /// Add a performance alert
    public func addAlert(_ alert: PerformanceAlert) {
        alerts.append(alert)

        // Keep only last 100 alerts
        if alerts.count > 100 {
            alerts.removeFirst(alerts.count - 100)
        }

        if config.enableLogging {
            logAlert(alert)
        }
    }

    /// Measure execution time of an operation
    public func measureOperation<T>(_ name: String, operation: () throws -> T) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let duration = CFAbsoluteTimeGetCurrent() - start

        // Check for slow operation
        if duration > 0.1 { // 100ms threshold
            Task { @MainActor in
                self.addAlert(.slowOperation(name: name, duration: duration))
            }
        }

        return result
    }

    /// Measure execution time of an async operation
    public func measureAsyncOperation<T>(_ name: String, operation: () async throws -> T) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let duration = CFAbsoluteTimeGetCurrent() - start

        // Check for slow operation
        if duration > 0.1 { // 100ms threshold
            await MainActor.run {
                self.addAlert(.slowOperation(name: name, duration: duration))
            }
        }

        return result
    }

    // MARK: - Private Methods

    private func collectMetrics() async {
        let metrics = await withCheckedContinuation { continuation in
            metricsQueue.async {
                let metrics = self.collectCurrentMetrics()
                continuation.resume(returning: metrics)
            }
        }

        currentMetrics = metrics
        addToHistory(metrics)
        checkThresholds(metrics)
    }

    private nonisolated func collectCurrentMetrics() -> PerformanceMetrics {
        // Get CPU usage
        let cpuUsage = getCPUUsage()

        // Get memory usage
        let memoryUsage = getMemoryUsage()

        // Get memory pressure
        let memoryPressure = getMemoryPressure()

        // Get thread count
        let threadCount = getThreadCount()

        // Get process count (child processes)
        let processCount = getChildProcessCount()

        return PerformanceMetrics(
            cpuUsage: cpuUsage,
            memoryUsage: memoryUsage,
            memoryPressure: memoryPressure,
            threadCount: threadCount,
            processCount: processCount
        )
    }

    private nonisolated func getCPUUsage() -> Double {
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0

        let result = task_threads(mach_task_self_, &threadList, &threadCount)
        guard result == KERN_SUCCESS, let threads = threadList else {
            return 0.0
        }

        var totalCPU: Double = 0.0

        for i in 0..<Int(threadCount) {
            var info = thread_basic_info()
            var count = mach_msg_type_number_t(THREAD_INFO_MAX)

            let kr = withUnsafeMutablePointer(to: &info) { infoPtr in
                infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { ptr in
                    thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), ptr, &count)
                }
            }

            if kr == KERN_SUCCESS && info.flags & TH_FLAGS_IDLE == 0 {
                totalCPU += Double(info.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
            }
        }

        // Deallocate thread list
        let size = vm_size_t(threadCount) * vm_size_t(MemoryLayout<thread_t>.stride)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), size)

        return totalCPU
    }

    private nonisolated func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { ptr in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), ptr, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return 0
        }

        return info.resident_size
    }

    private nonisolated func getMemoryPressure() -> PerformanceMetrics.MemoryPressure {
        // Use system memory pressure notification
        let memoryStatus = os_proc_available_memory()
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let availableRatio = Double(memoryStatus) / Double(totalMemory)

        if availableRatio < 0.1 {
            return .critical
        } else if availableRatio < 0.2 {
            return .warning
        } else {
            return .normal
        }
    }

    private nonisolated func getThreadCount() -> Int {
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0

        let result = task_threads(mach_task_self_, &threadList, &threadCount)
        guard result == KERN_SUCCESS, let threads = threadList else {
            return 0
        }

        // Deallocate thread list
        let size = vm_size_t(threadCount) * vm_size_t(MemoryLayout<thread_t>.stride)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), size)

        return Int(threadCount)
    }

    private nonisolated func getChildProcessCount() -> Int {
        // Get child process count
        let parentPID = getpid()
        var count = 0

        // Use sysctl to get process list
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL]
        var size = 0

        guard sysctl(&mib, 3, nil, &size, nil, 0) == 0 else { return 0 }

        let processCount = size / MemoryLayout<kinfo_proc>.stride
        var processes = [kinfo_proc](repeating: kinfo_proc(), count: processCount)

        guard sysctl(&mib, 3, &processes, &size, nil, 0) == 0 else { return 0 }

        for process in processes {
            if process.kp_eproc.e_ppid == parentPID {
                count += 1
            }
        }

        return count
    }

    private func addToHistory(_ metrics: PerformanceMetrics) {
        metricsHistory.append(metrics)

        // Keep only recent metrics
        if metricsHistory.count > maxHistoryCount {
            metricsHistory.removeFirst(metricsHistory.count - maxHistoryCount)
        }
    }

    private func checkThresholds(_ metrics: PerformanceMetrics) {
        // Check CPU threshold
        if metrics.cpuUsage > config.cpuThreshold {
            addAlert(.highCPUUsage(percentage: metrics.cpuUsage))
        }

        // Check memory threshold
        if metrics.memoryUsage > config.memoryThreshold {
            addAlert(.highMemoryUsage(bytes: metrics.memoryUsage))
        }

        // Check memory pressure
        if metrics.memoryPressure != .normal {
            addAlert(.memoryPressure(metrics.memoryPressure))
        }

        // Check thread threshold
        if metrics.threadCount > config.threadThreshold {
            addAlert(.threadExplosion(count: metrics.threadCount))
        }
    }

    private func logAlert(_ alert: PerformanceAlert) {
        let message: String
        switch alert {
        case .highCPUUsage(let percentage):
            message = "High CPU usage: \(String(format: "%.1f", percentage))%"
        case .highMemoryUsage(let bytes):
            let mb = Double(bytes) / (1024 * 1024)
            message = "High memory usage: \(String(format: "%.1f", mb)) MB"
        case .memoryPressure(let pressure):
            message = "Memory pressure: \(pressure.rawValue)"
        case .slowOperation(let name, let duration):
            message = "Slow operation '\(name)': \(String(format: "%.3f", duration * 1000))ms"
        case .threadExplosion(let count):
            message = "Thread explosion detected: \(count) threads"
        }

        print("[PerformanceMonitor] \(message)")
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

/// Performance metrics view for debugging
public struct PerformanceMetricsView: View {
    @ObservedObject private var monitor: PerformanceMonitor

    public init(monitor: PerformanceMonitor) {
        self.monitor = monitor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Metrics")
                .font(.headline)

            if let metrics = monitor.currentMetrics {
                HStack {
                    MetricRow(title: "CPU", value: String(format: "%.1f%%", metrics.cpuUsage))
                    MetricRow(title: "Memory", value: formatBytes(metrics.memoryUsage))
                }

                HStack {
                    MetricRow(title: "Threads", value: "\(metrics.threadCount)")
                    MetricRow(title: "Pressure", value: metrics.memoryPressure.rawValue)
                }
            } else {
                Text("Collecting metrics...")
                    .foregroundColor(.secondary)
            }

            if !monitor.alerts.isEmpty {
                Divider()

                Text("Recent Alerts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ForEach(monitor.alerts.suffix(5), id: \.hashValue) { alert in
                    Text(alertDescription(alert))
                        .font(.caption)
                        .foregroundColor(.orange)
                }
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

    private func alertDescription(_ alert: PerformanceAlert) -> String {
        switch alert {
        case .highCPUUsage(let percentage):
            return "High CPU: \(String(format: "%.1f", percentage))%"
        case .highMemoryUsage(let bytes):
            return "High Memory: \(formatBytes(bytes))"
        case .memoryPressure(let pressure):
            return "Memory pressure: \(pressure.rawValue)"
        case .slowOperation(let name, let duration):
            return "Slow: \(name) (\(String(format: "%.0f", duration * 1000))ms)"
        case .threadExplosion(let count):
            return "Thread explosion: \(count)"
        }
    }
}

struct MetricRow: View {
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
