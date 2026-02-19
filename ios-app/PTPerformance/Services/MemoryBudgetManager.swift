//
//  MemoryBudgetManager.swift
//  PTPerformance
//
//  ACP-935: Memory Footprint Reduction
//  Tracks real-time app memory usage via Mach kernel APIs, enforces per-subsystem
//  memory budgets, detects memory pressure, and orchestrates a prioritized
//  eviction chain across all cache subsystems. Integrates with CacheCoordinator
//  for coordinated cleanup.
//

import Foundation
import UIKit

// MARK: - MemoryPressureLevel

/// Describes the current memory pressure the app is under, derived from the
/// ratio of current resident memory to the device's physical memory.
enum MemoryPressureLevel: Int, Comparable, Sendable {
    /// Memory usage is within normal operating bounds.
    case nominal = 0

    /// Memory usage is elevated. Non-essential caches should begin downsizing.
    case warning = 1

    /// Memory usage is critically high. Aggressive eviction is required.
    case critical = 2

    /// The system has issued a memory warning. Emergency eviction of all
    /// non-essential data.
    case terminal = 3

    static func < (lhs: MemoryPressureLevel, rhs: MemoryPressureLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - SubsystemID

/// Identifies a memory-consuming subsystem for budget tracking and diagnostics.
/// Each subsystem registers its current memory footprint with the manager so it
/// can be inspected in debug UIs and used for targeted eviction.
enum SubsystemID: String, CaseIterable, Sendable {
    case imageCache = "ImageCache"
    case imagePipeline = "ImagePipeline"
    case apiResponseCache = "APIResponseCache"
    case workoutCache = "WorkoutCache"
    case videoCache = "VideoCache"
    case exerciseLibrary = "ExerciseLibrary"
    case workoutHistory = "WorkoutHistory"
    case general = "General"
}

// MARK: - SubsystemBudget

/// Memory budget and current usage for a single subsystem.
struct SubsystemBudget: Sendable {
    /// Human-readable label for diagnostics.
    let subsystemID: SubsystemID

    /// Maximum allowed memory in bytes. Zero means unlimited (tracked but not capped).
    let budgetBytes: Int64

    /// Current estimated memory usage in bytes.
    var currentBytes: Int64

    /// Eviction priority. Lower values are evicted first under pressure.
    /// Range: 0 (first to evict) to 100 (last to evict).
    let evictionPriority: Int

    /// Whether this subsystem has exceeded its budget.
    var isOverBudget: Bool {
        budgetBytes > 0 && currentBytes > budgetBytes
    }

    /// Usage ratio (0.0 - 1.0+). Values above 1.0 indicate over-budget.
    var usageRatio: Double {
        guard budgetBytes > 0 else { return 0 }
        return Double(currentBytes) / Double(budgetBytes)
    }
}

// MARK: - MemorySnapshot

/// An immutable point-in-time snapshot of the app's memory state.
/// Safe to pass between isolation contexts for logging or display.
struct MemorySnapshot: Sendable {
    /// Resident memory (RSS) in bytes — the actual physical memory the app is using.
    let residentBytes: Int64

    /// Physical memory of the device in bytes.
    let physicalMemoryBytes: Int64

    /// The percentage of device memory the app is using (0.0 - 1.0).
    let usageRatio: Double

    /// Current pressure level derived from usage ratio and system signals.
    let pressureLevel: MemoryPressureLevel

    /// Per-subsystem usage at the time of the snapshot.
    let subsystems: [SubsystemID: SubsystemBudget]

    /// Timestamp when this snapshot was taken.
    let timestamp: Date

    /// Total tracked memory across all registered subsystems.
    var totalTrackedBytes: Int64 {
        subsystems.values.reduce(0) { $0 + $1.currentBytes }
    }

    /// Formatted resident memory string.
    var formattedResident: String {
        ByteCountFormatter.string(fromByteCount: residentBytes, countStyle: .memory)
    }

    /// Formatted total tracked memory string.
    var formattedTracked: String {
        ByteCountFormatter.string(fromByteCount: totalTrackedBytes, countStyle: .memory)
    }

    /// Human-readable diagnostics report.
    var report: String {
        var output = "=== Memory Budget Report ===\n"
        output += "Resident: \(formattedResident) (\(String(format: "%.1f%%", usageRatio * 100)) of device)\n"
        output += "Pressure: \(pressureLevel)\n"
        output += "Tracked Total: \(formattedTracked)\n"
        output += "--- Subsystems ---\n"

        let sorted = subsystems.values.sorted { $0.currentBytes > $1.currentBytes }
        for sub in sorted where sub.currentBytes > 0 {
            let budgetStr: String
            if sub.budgetBytes > 0 {
                let pct = String(format: "%.0f%%", sub.usageRatio * 100)
                budgetStr = "\(ByteCountFormatter.string(fromByteCount: sub.budgetBytes, countStyle: .memory)) (\(pct))"
            } else {
                budgetStr = "unlimited"
            }
            let flag = sub.isOverBudget ? " [OVER]" : ""
            output += "  \(sub.subsystemID.rawValue): "
            output += "\(ByteCountFormatter.string(fromByteCount: sub.currentBytes, countStyle: .memory)) / \(budgetStr)\(flag)\n"
        }
        output += "============================="
        return output
    }
}

// MARK: - EvictionHandler

/// A closure that a subsystem registers to handle memory eviction requests.
/// The handler receives the current pressure level and should free memory
/// proportional to the severity. Returns the approximate number of bytes freed.
typealias EvictionHandler = @Sendable (MemoryPressureLevel) async -> Int64

// MARK: - MemoryBudgetManager

/// Singleton actor that tracks real-time app memory usage, enforces per-subsystem
/// budgets, and coordinates prioritized eviction when memory pressure is detected.
///
/// ## Architecture
/// - Uses `mach_task_basic_info` to read the app's resident memory (RSS).
/// - Maintains a registry of subsystem budgets that services update as they
///   allocate and free memory.
/// - Runs a periodic sampling timer that checks memory pressure and triggers
///   eviction when thresholds are exceeded.
/// - Integrates with ``CacheCoordinator`` for final-resort cache clearing.
///
/// ## Pressure Thresholds
/// - **Nominal**: RSS < 50% of device RAM
/// - **Warning**: RSS >= 50% of device RAM
/// - **Critical**: RSS >= 70% of device RAM
/// - **Terminal**: System memory warning received
///
/// ## Usage
/// ```swift
/// // Register subsystem usage
/// await MemoryBudgetManager.shared.updateSubsystemUsage(.imageCache, bytes: cacheSize)
///
/// // Register eviction handler
/// await MemoryBudgetManager.shared.registerEvictionHandler(for: .imageCache) { level in
///     let freed = clearSomeImages(severity: level)
///     return Int64(freed)
/// }
///
/// // Take a diagnostic snapshot
/// let snapshot = await MemoryBudgetManager.shared.takeSnapshot()
/// print(snapshot.report)
/// ```
actor MemoryBudgetManager {

    // MARK: - Singleton

    static let shared = MemoryBudgetManager()

    // MARK: - Configuration

    /// How often (in seconds) the manager samples memory and checks pressure.
    private let samplingInterval: TimeInterval = 5.0

    /// Pressure threshold ratios (RSS / physical memory).
    private let warningThreshold: Double = 0.50
    private let criticalThreshold: Double = 0.70

    /// Minimum time between eviction passes to avoid thrashing.
    private let evictionCooldown: TimeInterval = 10.0

    // MARK: - Default Budgets

    /// Default per-subsystem budgets in bytes.
    private static let defaultBudgets: [SubsystemID: (budget: Int64, priority: Int)] = [
        .imagePipeline: (budget: 80_000_000, priority: 20), // 80 MB
        .imageCache: (budget: 50_000_000, priority: 10), // 50 MB
        .apiResponseCache: (budget: 30_000_000, priority: 30), // 30 MB
        .workoutCache: (budget: 20_000_000, priority: 50), // 20 MB
        .videoCache: (budget: 100_000_000, priority: 15), // 100 MB
        .exerciseLibrary: (budget: 15_000_000, priority: 40), // 15 MB
        .workoutHistory: (budget: 10_000_000, priority: 35), // 10 MB
        .general: (budget: 0, priority: 60) // Unlimited tracking
    ]

    // MARK: - Properties

    private let logger = DebugLogger.shared
    private let physicalMemoryBytes: Int64

    /// Per-subsystem budget tracking.
    private var subsystems: [SubsystemID: SubsystemBudget]

    /// Registered eviction handlers, keyed by subsystem.
    private var evictionHandlers: [SubsystemID: EvictionHandler] = [:]

    /// Last time an eviction pass ran (for cooldown enforcement).
    private var lastEvictionTime: Date = .distantPast

    /// The most recent pressure level, used to detect transitions.
    private var currentPressureLevel: MemoryPressureLevel = .nominal

    /// Sampling timer task.
    private var samplingTask: Task<Void, Never>?

    /// Observer for system memory warnings.
    private var memoryWarningObserver: NSObjectProtocol?

    /// Rolling history of resident memory samples for trend detection.
    private var residentMemoryHistory: [Int64] = []
    private let maxHistoryCount = 60  // 5 minutes at 5s intervals

    // MARK: - Initialization

    private init() {
        self.physicalMemoryBytes = Int64(ProcessInfo.processInfo.physicalMemory)

        // Initialize subsystem budgets from defaults
        var subs: [SubsystemID: SubsystemBudget] = [:]
        for (id, config) in Self.defaultBudgets {
            subs[id] = SubsystemBudget(
                subsystemID: id,
                budgetBytes: config.budget,
                currentBytes: 0,
                evictionPriority: config.priority
            )
        }
        self.subsystems = subs

        logger.log("[MemoryBudgetManager] Initialized. Device RAM: \(ByteCountFormatter.string(fromByteCount: physicalMemoryBytes, countStyle: .memory))", level: .diagnostic)
    }

    // MARK: - Lifecycle

    /// Start the periodic memory sampling timer and register for system memory warnings.
    /// Call once during app launch (e.g., from LaunchOptimizer phase 3).
    func start() {
        guard samplingTask == nil else { return }

        startSamplingTimer()
        registerMemoryWarningObserver()

        logger.log("[MemoryBudgetManager] Started monitoring (interval: \(samplingInterval)s)", level: .diagnostic)
    }

    /// Stop monitoring and release resources.
    func stop() {
        samplingTask?.cancel()
        samplingTask = nil

        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
            memoryWarningObserver = nil
        }

        logger.log("[MemoryBudgetManager] Stopped monitoring", level: .diagnostic)
    }

    // MARK: - Public API: Subsystem Registration

    /// Update the current memory usage for a subsystem.
    ///
    /// Services should call this whenever they allocate or free significant amounts
    /// of memory (e.g., after adding images to a cache or clearing cached data).
    ///
    /// - Parameters:
    ///   - subsystem: The subsystem identifier.
    ///   - bytes: Current memory usage in bytes.
    func updateSubsystemUsage(_ subsystem: SubsystemID, bytes: Int64) {
        guard var budget = subsystems[subsystem] else { return }
        budget = SubsystemBudget(
            subsystemID: budget.subsystemID,
            budgetBytes: budget.budgetBytes,
            currentBytes: max(0, bytes),
            evictionPriority: budget.evictionPriority
        )
        subsystems[subsystem] = budget

        // If this single update puts the subsystem over budget, trigger targeted eviction
        if budget.isOverBudget {
            Task { [weak self] in
                await self?.evictSubsystem(subsystem, reason: "over_budget")
            }
        }
    }

    /// Register an eviction handler for a subsystem.
    ///
    /// The handler is called during memory pressure events. It receives the
    /// current ``MemoryPressureLevel`` and should free memory proportional to
    /// the severity. Return the estimated number of bytes freed.
    ///
    /// - Parameters:
    ///   - subsystem: The subsystem to register the handler for.
    ///   - handler: Async closure that performs eviction and returns bytes freed.
    func registerEvictionHandler(
        for subsystem: SubsystemID,
        handler: @escaping EvictionHandler
    ) {
        evictionHandlers[subsystem] = handler
        logger.log("[MemoryBudgetManager] Eviction handler registered for \(subsystem.rawValue)", level: .diagnostic)
    }

    // MARK: - Public API: Diagnostics

    /// Take an immutable snapshot of the current memory state.
    ///
    /// - Returns: A ``MemorySnapshot`` with resident memory, pressure level,
    ///   and per-subsystem usage.
    func takeSnapshot() -> MemorySnapshot {
        let resident = Self.readResidentMemory()
        let ratio = Double(resident) / Double(physicalMemoryBytes)
        let pressure = classifyPressure(ratio: ratio)

        return MemorySnapshot(
            residentBytes: resident,
            physicalMemoryBytes: physicalMemoryBytes,
            usageRatio: ratio,
            pressureLevel: pressure,
            subsystems: subsystems,
            timestamp: Date()
        )
    }

    /// Get the current memory pressure level without creating a full snapshot.
    func currentPressure() -> MemoryPressureLevel {
        currentPressureLevel
    }

    /// Get the current resident memory in bytes.
    nonisolated func residentMemoryBytes() -> Int64 {
        Self.readResidentMemory()
    }

    /// Get a formatted diagnostics string for the current memory state.
    func diagnosticsReport() -> String {
        takeSnapshot().report
    }

    /// Get memory trend over the sampling history.
    /// Returns the average change in bytes per sample (positive = growing).
    func memoryTrend() -> Int64 {
        guard residentMemoryHistory.count >= 2 else { return 0 }

        var totalDelta: Int64 = 0
        for i in 1..<residentMemoryHistory.count {
            totalDelta += residentMemoryHistory[i] - residentMemoryHistory[i - 1]
        }
        return totalDelta / Int64(residentMemoryHistory.count - 1)
    }

    // MARK: - Public API: Manual Eviction

    /// Manually trigger an eviction pass at the specified pressure level.
    ///
    /// Use this for testing or when the app detects domain-specific conditions
    /// that warrant memory reduction (e.g., entering a memory-intensive workout
    /// recording flow).
    ///
    /// - Parameter level: The pressure level to simulate.
    /// - Returns: Total bytes freed across all subsystems.
    @discardableResult
    func triggerEviction(at level: MemoryPressureLevel) async -> Int64 {
        await performEvictionPass(level: level, reason: "manual_trigger")
    }

    // MARK: - Memory Reading (Mach API)

    /// Read the app's current resident memory (RSS) using the Mach kernel API.
    ///
    /// This is the most accurate way to measure real physical memory usage on iOS.
    /// `task_info` returns the `resident_size` field which is the number of bytes
    /// of physical memory currently mapped to the process.
    nonisolated static func readResidentMemory() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)

        let result = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rawPtr in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), rawPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return 0
        }

        return Int64(info.resident_size)
    }

    // MARK: - Private: Pressure Classification

    /// Classify the current memory pressure based on the RSS/physical-memory ratio.
    private func classifyPressure(ratio: Double) -> MemoryPressureLevel {
        if ratio >= criticalThreshold {
            return .critical
        } else if ratio >= warningThreshold {
            return .warning
        }
        return .nominal
    }

    // MARK: - Private: Sampling Timer

    /// Start the periodic sampling timer that checks memory pressure.
    private func startSamplingTimer() {
        samplingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(5.0 * 1_000_000_000))

                guard !Task.isCancelled else { break }
                await self?.sampleMemory()
            }
        }
    }

    /// Perform a single memory sample and check for pressure transitions.
    private func sampleMemory() {
        let resident = Self.readResidentMemory()
        let ratio = Double(resident) / Double(physicalMemoryBytes)
        let newLevel = classifyPressure(ratio: ratio)

        // Record history
        residentMemoryHistory.append(resident)
        if residentMemoryHistory.count > maxHistoryCount {
            residentMemoryHistory.removeFirst()
        }

        // Check for pressure transitions
        let previousLevel = currentPressureLevel
        currentPressureLevel = newLevel

        if newLevel > previousLevel {
            logger.log(
                "[MemoryBudgetManager] Pressure escalated: \(previousLevel) -> \(newLevel) (RSS: \(ByteCountFormatter.string(fromByteCount: resident, countStyle: .memory)), \(String(format: "%.1f%%", ratio * 100)))",
                level: newLevel >= .critical ? .warning : .info
            )

            // Trigger eviction on escalation
            Task { [weak self] in
                await self?.performEvictionPass(level: newLevel, reason: "pressure_escalation")
            }
        }

        // Check individual subsystem budgets
        for (id, budget) in subsystems where budget.isOverBudget {
            Task { [weak self] in
                await self?.evictSubsystem(id, reason: "periodic_budget_check")
            }
        }
    }

    // MARK: - Private: Memory Warning Observer

    /// Register for UIApplication memory warning notifications.
    private func registerMemoryWarningObserver() {
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { [weak self] in
                guard let self = self else { return }
                await self.handleSystemMemoryWarning()
            }
        }
    }

    /// Handle a system memory warning by escalating to terminal pressure.
    private func handleSystemMemoryWarning() async {
        currentPressureLevel = .terminal

        logger.log(
            "[MemoryBudgetManager] System memory warning received - escalating to terminal",
            level: .warning
        )

        await performEvictionPass(level: .terminal, reason: "system_memory_warning")
    }

    // MARK: - Private: Eviction Engine

    /// Perform a full eviction pass across all registered subsystems.
    ///
    /// Subsystems are evicted in priority order (lowest priority number = evicted first).
    /// The pass stops early if pressure drops below the target level.
    ///
    /// - Parameters:
    ///   - level: The pressure level driving this eviction.
    ///   - reason: A diagnostic string describing why eviction was triggered.
    /// - Returns: Total bytes freed.
    @discardableResult
    private func performEvictionPass(level: MemoryPressureLevel, reason: String) async -> Int64 {
        // Enforce cooldown to prevent thrashing
        let timeSinceLastEviction = Date().timeIntervalSince(lastEvictionTime)
        guard level >= .critical || timeSinceLastEviction >= evictionCooldown else {
            return 0
        }

        lastEvictionTime = Date()

        logger.log(
            "[MemoryBudgetManager] Eviction pass started (level: \(level), reason: \(reason))",
            level: .diagnostic
        )

        var totalFreed: Int64 = 0

        // Sort handlers by eviction priority (lowest number = evict first)
        let sortedSubsystems = subsystems.values
            .sorted { $0.evictionPriority < $1.evictionPriority }

        for budget in sortedSubsystems {
            guard let handler = evictionHandlers[budget.subsystemID] else { continue }

            // Skip subsystems with no tracked usage
            guard budget.currentBytes > 0 else { continue }

            let freed = await handler(level)
            totalFreed += freed

            if freed > 0 {
                logger.log(
                    "[MemoryBudgetManager] \(budget.subsystemID.rawValue) freed \(ByteCountFormatter.string(fromByteCount: freed, countStyle: .memory))",
                    level: .diagnostic
                )
            }

            // For warning level, stop after freeing from low-priority subsystems
            if level == .warning && totalFreed > 20_000_000 { // 20 MB freed is enough
                break
            }

            // Re-check pressure after each subsystem eviction
            let currentRatio = Double(Self.readResidentMemory()) / Double(physicalMemoryBytes)
            let currentLevel = classifyPressure(ratio: currentRatio)
            if currentLevel < level {
                logger.log(
                    "[MemoryBudgetManager] Pressure reduced to \(currentLevel) — stopping eviction early",
                    level: .diagnostic
                )
                break
            }
        }

        // For terminal/critical pressure, also invoke CacheCoordinator
        if level >= .critical {
            await MainActor.run {
                CacheCoordinator.shared.handleMemoryWarning()
            }
        }

        logger.log(
            "[MemoryBudgetManager] Eviction pass complete. Freed: \(ByteCountFormatter.string(fromByteCount: totalFreed, countStyle: .memory))",
            level: totalFreed > 0 ? .success : .diagnostic
        )

        // Log post-eviction state
        ErrorLogger.shared.logUserAction(
            action: "memory_eviction_pass",
            properties: [
                "level": "\(level)",
                "reason": reason,
                "freed_bytes": "\(totalFreed)",
                "resident_after": "\(Self.readResidentMemory())"
            ]
        )

        return totalFreed
    }

    /// Evict a single subsystem that has exceeded its budget.
    private func evictSubsystem(_ subsystem: SubsystemID, reason: String) async {
        guard let handler = evictionHandlers[subsystem] else { return }

        let freed = await handler(.warning)
        if freed > 0 {
            logger.log(
                "[MemoryBudgetManager] Targeted eviction for \(subsystem.rawValue) (\(reason)): freed \(ByteCountFormatter.string(fromByteCount: freed, countStyle: .memory))",
                level: .diagnostic
            )
        }
    }
}
