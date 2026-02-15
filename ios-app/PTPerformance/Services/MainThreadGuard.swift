//
//  MainThreadGuard.swift
//  PTPerformance
//
//  ACP-945: Main Thread Optimization — Debug-only main thread watchdog.
//  Monitors main run loop iterations and logs warnings when any single
//  iteration exceeds 16ms (one frame at 60fps). Captures symbolic stack
//  traces for violations to help identify blocking work on the main thread.
//

import Foundation

/// Debug-only watchdog that monitors main thread run loop iterations for frame drops.
///
/// Uses `CFRunLoopObserver` to measure the wall-clock duration of each main run loop
/// pass. When any pass exceeds 16ms the guard logs a warning with a symbolic stack
/// trace so developers can identify and move heavy work off the main thread.
///
/// Usage:
/// ```swift
/// // In AppDelegate or App.init (debug builds only)
/// #if DEBUG
/// MainThreadGuard.shared.start()
/// #endif
/// ```
final class MainThreadGuard {

    // MARK: - Singleton

    static let shared = MainThreadGuard()

    // MARK: - Properties

    #if DEBUG
    /// Threshold in seconds — 16ms = one frame at 60fps
    private let frameThreshold: CFAbsoluteTime = 0.016

    /// Run loop observer tracking the start of each iteration
    private var observer: CFRunLoopObserver?

    /// Timestamp captured at the beginning of each run loop pass
    private var iterationStartTime: CFAbsoluteTime = 0

    /// Whether the guard is currently active
    private(set) var isRunning = false

    /// Total number of violations detected this session
    private(set) var violationCount: Int = 0

    /// Duration (seconds) of the worst offender this session
    private(set) var worstOffenderDuration: CFAbsoluteTime = 0
    #endif

    // MARK: - Init

    private init() {}

    // MARK: - Public API

    /// Begin monitoring the main run loop for frame-budget violations.
    func start() {
        #if DEBUG
        guard !isRunning else { return }
        isRunning = true

        // Create a run loop observer that fires for both the beginning
        // and end of each run loop pass (beforeSources + afterWaiting).
        var context = CFRunLoopObserverContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        observer = CFRunLoopObserverCreate(
            kCFAllocatorDefault,
            CFRunLoopActivity.allActivities.rawValue,
            true,  // repeats
            0,     // order
            { (_, activity, info) in
                guard let info = info else { return }
                let guard_ = Unmanaged<MainThreadGuard>.fromOpaque(info).takeUnretainedValue()
                guard_.handleActivity(activity)
            },
            &context
        )

        if let observer = observer {
            CFRunLoopAddObserver(CFRunLoopGetMain(), observer, .commonModes)
        }

        DebugLogger.shared.info("MainThreadGuard", "Started monitoring main thread (threshold: \(Int(frameThreshold * 1000))ms)")
        #endif
    }

    /// Stop monitoring the main run loop.
    func stop() {
        #if DEBUG
        guard isRunning else { return }
        isRunning = false

        if let observer = observer {
            CFRunLoopRemoveObserver(CFRunLoopGetMain(), observer, .commonModes)
        }
        observer = nil

        DebugLogger.shared.info("MainThreadGuard", "Stopped. Violations: \(violationCount), worst: \(String(format: "%.1f", worstOffenderDuration * 1000))ms")
        #endif
    }

    // MARK: - Internal

    #if DEBUG
    /// Called by the run loop observer for every activity change.
    private func handleActivity(_ activity: CFRunLoopActivity) {
        switch activity {
        // Before sources / timers — marks the beginning of work
        case .beforeSources, .beforeTimers:
            if iterationStartTime == 0 {
                iterationStartTime = CFAbsoluteTimeGetCurrent()
            }

        // After waiting — the run loop has finished processing and is about
        // to sleep, or has just woken up. Either way, measure elapsed time.
        case .beforeWaiting, .afterWaiting:
            guard iterationStartTime > 0 else {
                // Capture start time if we observe afterWaiting first
                iterationStartTime = CFAbsoluteTimeGetCurrent()
                return
            }

            let elapsed = CFAbsoluteTimeGetCurrent() - iterationStartTime
            iterationStartTime = 0

            if elapsed > frameThreshold {
                recordViolation(duration: elapsed)
            }

        default:
            break
        }
    }

    /// Record a single frame-budget violation and log it.
    private func recordViolation(duration: CFAbsoluteTime) {
        violationCount += 1

        if duration > worstOffenderDuration {
            worstOffenderDuration = duration
        }

        let durationMs = String(format: "%.1f", duration * 1000)
        let stackTrace = captureSymbolicStackTrace()

        DebugLogger.shared.warning(
            "MainThreadGuard",
            "Main thread blocked for \(durationMs)ms (budget: 16ms) — violation #\(violationCount)\n\(stackTrace)"
        )
    }

    /// Capture a symbolic stack trace of the current (main) thread for debugging.
    /// Note: Since this runs inside the run loop observer callback, the blocking work
    /// has already completed. The trace shows the current call site, not the original
    /// offending code. For precise attribution, use Instruments Time Profiler.
    private func captureSymbolicStackTrace() -> String {
        let symbols = Thread.callStackSymbols
        // Skip the first few frames (this function + handleActivity + CFRunLoop internals)
        // and keep a reasonable number of frames for readability.
        let relevantFrames = symbols.dropFirst(3).prefix(10)
        return relevantFrames.enumerated().map { index, frame in
            "  [\(index)] \(frame)"
        }.joined(separator: "\n")
    }
    #endif
}
