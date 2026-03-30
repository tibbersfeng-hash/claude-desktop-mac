//
//  Performance.swift
//  ClaudeDesktopMac
//
//  Created by Claude Desktop Team on 2026-03-30.
//

import Foundation

/// Performance module exports
public enum Performance {
    /// Get the shared performance monitor instance
    public static var monitor: PerformanceMonitor {
        PerformanceMonitor.shared
    }

    /// Get the shared memory manager instance
    public static var memoryManager: MemoryManager {
        MemoryManager.shared
    }

    /// Get the shared cache manager instance
    public static var cacheManager: CacheManager {
        CacheManager.shared
    }

    /// Get the shared launch optimizer instance
    public static var launchOptimizer: LaunchOptimizer {
        LaunchOptimizer.shared
    }

    /// Initialize the performance module
    public static func initialize() async {
        // Start monitoring
        await MainActor.run {
            monitor.startMonitoring()
        }

        // Start launch optimization
        await launchOptimizer.startLaunch()
    }

    /// Measure the execution time of an operation
    public static func measure<T>(_ name: String, operation: () throws -> T) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let duration = (CFAbsoluteTimeGetCurrent() - start) * 1000
        print("[Performance] \(name): \(String(format: "%.2f", duration))ms")
        return result
    }

    /// Measure the execution time of an async operation
    public static func measureAsync<T>(_ name: String, operation: () async throws -> T) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let duration = (CFAbsoluteTimeGetCurrent() - start) * 1000
        print("[Performance] \(name): \(String(format: "%.2f", duration))ms")
        return result
    }

    /// Get current memory usage
    public static var currentMemoryUsage: UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { ptr in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), ptr, &count)
            }
        }

        return result == KERN_SUCCESS ? info.resident_size : 0
    }

    /// Get current CPU usage
    public static var currentCPUUsage: Double {
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

    /// Trigger memory cleanup
    public static func cleanupMemory() {
        Task { @MainActor in
            MemoryManager.shared.forceCleanup()
            CacheManager.shared.clearAll()
        }
    }

    /// Get available memory
    public static var availableMemory: UInt64 {
        return os_proc_available_memory()
    }

    /// Get total physical memory
    public static var totalMemory: UInt64 {
        return ProcessInfo.processInfo.physicalMemory
    }

    /// Get memory pressure ratio
    public static var memoryPressureRatio: Double {
        let available = Double(availableMemory)
        let total = Double(totalMemory)
        return 1.0 - (available / total)
    }
}
