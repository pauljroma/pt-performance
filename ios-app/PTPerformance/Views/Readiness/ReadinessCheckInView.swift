import SwiftUI

// MARK: - HRV Trend Indicator

/// Displays HRV deviation from baseline with directional indicator
struct HRVTrendIndicator: View {
    let hrv: Double
    let baseline: Double?

    var body: some View {
        if let baseline = baseline {
            let deviation = ((hrv - baseline) / baseline) * 100
            HStack(spacing: 2) {
                Image(systemName: deviation > 5 ? "arrow.up" : deviation < -5 ? "arrow.down" : "minus")
                Text(String(format: "%.0f%%", abs(deviation)))
            }
            .font(.caption)
            .foregroundColor(deviation > 5 ? .green : deviation < -5 ? .red : .secondary)
        }
    }
}

/// Daily readiness check-in view
/// BUILD 116 - Agent 16: ReadinessCheckInView
///
/// Responsibilities:
/// - Daily wellness metrics input form
/// - Sleep, soreness, energy, stress tracking
/// - Live score preview as user inputs
/// - Integration with ReadinessCheckInViewModel
/// - Success/error feedback
///
/// Design:
/// - Clean medical-themed UI
/// - Color-coded sliders
/// - Live score calculation
/// - Validation feedback
struct ReadinessCheckInView: View {
    // MARK: - Dependencies

    @StateObject private var viewModel: ReadinessCheckInViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - UI State

    @State private var showingSuccessAnimation = false
    @State private var isAutoFilling = false
    @State private var isAutoFilled = false
    @State private var wasAutoFilled = false
    @State private var showHealthKitPrompt = false
    @State private var hrvBaseline: Double?
    @State private var isInitialLoading = true
    @State private var healthKitIsAuthorized = false
    @State private var todayHRV: Double?
    @State private var todaySleep: SleepData?

    // MARK: - Initialization

    /// Initialize with patient ID
    /// - Parameter patientId: UUID of the patient
    init(patientId: UUID) {
        _viewModel = StateObject(wrappedValue: ReadinessCheckInViewModel(patientId: patientId))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Show initial loading state
                if isInitialLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading your check-in...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // ACP-1020: Single-screen streamlined form
                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            // Quick fill section (sticky-like at top)
                            quickFillCardSection

                            // Historical comparison inline
                            if let comparison = viewModel.historicalComparison {
                                historicalComparisonCard(comparison)
                            }

                            // Consolidated metrics card
                            metricsCard

                            // Live score preview
                            liveScoreCard

                            // Submit button
                            submitButton
                        }
                        .padding()
                    }
                    .background(Color(.systemGroupedBackground))
                    .disabled(viewModel.isLoading)
                    .springSheet(isPresented: $showHealthKitPrompt) {
                        HealthKitAuthorizationView()
                    }
                }

                // Success overlay
                if viewModel.showSuccess {
                    successOverlay
                }
            }
            .navigationTitle("Daily Check-In")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel check-in")
                    .accessibilityHint("Closes check-in form without saving")
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .task {
                // Load readiness data with timeout protection
                await withTaskGroup(of: Bool.self) { group in
                    group.addTask {
                        await viewModel.loadTodayEntry()
                        return true
                    }
                    group.addTask {
                        try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 second timeout
                        return false
                    }

                    // Wait for first to complete
                    if let result = await group.next() {
                        if !result {
                            // Timeout hit - show form with error
                            viewModel.errorMessage = "Couldn't load your previous check-in. You can still submit a new one."
                            viewModel.showError = true
                        }
                    }
                    group.cancelAll()
                }

                // Show form regardless of timeout
                isInitialLoading = false
            }
            .task {
                // Load HealthKit data in separate non-blocking task
                guard HealthKitService.isHealthKitAvailable else { return }

                let service = HealthKitService.shared
                healthKitIsAuthorized = service.isAuthorized

                if service.isAuthorized {
                    async let baselineTask = service.getHRVBaseline()
                    async let syncTask = service.syncTodayData()

                    hrvBaseline = try? await baselineTask
                    _ = try? await syncTask

                    // Update local state from service
                    todayHRV = service.todayHRV
                    todaySleep = service.todaySleep
                }
            }
        }
    }

    // MARK: - ACP-1020: Streamlined Quick Fill Card Section

    private var quickFillCardSection: some View {
        Card(shadow: Shadow.medium) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "applewatch")
                        .font(.title2)
                        .foregroundColor(.modusCyan)
                        .accessibilityHidden(true)

                    Text(dateString)
                        .font(.headline)
                        .accessibleHeader()

                    Spacer()

                    if viewModel.hasSubmittedToday {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Done")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                        }
                    }
                }

                if HealthKitService.isHealthKitAvailable {
                    if healthKitIsAuthorized {
                        // Show HealthKit data preview and auto-fill button
                        VStack(spacing: Spacing.sm) {
                            if let hrv = todayHRV {
                                HStack {
                                    Image(systemName: "waveform.path.ecg")
                                        .foregroundColor(.modusTealAccent)
                                    Text("HRV")
                                    Spacer()
                                    HRVTrendIndicator(hrv: hrv, baseline: hrvBaseline)
                                    Text("\(Int(hrv)) ms")
                                        .fontWeight(.semibold)
                                        .foregroundColor(hrvColor(hrv))
                                }
                                .font(.subheadline)
                            }

                            if let sleep = todaySleep {
                                HStack {
                                    Image(systemName: "bed.double.fill")
                                        .foregroundColor(.modusTealAccent)
                                    Text("Sleep")
                                    Spacer()
                                    Text(formatSleep(sleep.totalMinutes))
                                        .fontWeight(.semibold)
                                        .foregroundColor(sleepColor(sleep.totalMinutes))
                                }
                                .font(.subheadline)
                            }

                            Divider()

                            // Auto-fill button
                            Button {
                                HapticFeedback.medium()
                                Task {
                                    await autoFillFromHealthKit()
                                }
                            } label: {
                                HStack {
                                    if isAutoFilling {
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: isAutoFilled ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                                    }
                                    Text(isAutoFilled ? "Auto-Filled from Watch" : "Skip & Auto-Fill from Watch")
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                            }
                            .disabled(isAutoFilling)
                            .foregroundColor(isAutoFilled ? .green : .modusCyan)
                            .accessibilityLabel("Skip and auto-fill from Apple Watch")
                            .accessibilityHint("Automatically fills sleep and energy fields using HealthKit data")
                        }
                    } else {
                        // Show connect button
                        Button {
                            HapticFeedback.medium()
                            showHealthKitPrompt = true
                        } label: {
                            HStack {
                                Image(systemName: "heart.circle")
                                Text("Connect Apple Watch")
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                        }
                        .foregroundColor(.modusCyan)
                        .accessibilityLabel("Connect Apple Watch")
                    }
                }
            }
        }
    }

    // MARK: - ACP-1020: Historical Comparison Card

    private func historicalComparisonCard(_ comparison: HistoricalComparison) -> some View {
        Card(shadow: Shadow.subtle) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.modusDeepTeal)
                        .accessibilityHidden(true)

                    Text("Your Trend")
                        .font(.subheadline.bold())
                        .accessibleHeader()
                }

                HStack(spacing: Spacing.lg) {
                    trendStat(label: "7-Day Avg", value: comparison.weekAverage, icon: "calendar")
                    Divider()
                    trendStat(label: "30-Day Avg", value: comparison.monthAverage, icon: "calendar.badge.clock")
                    Divider()
                    trendStat(label: "Best", value: comparison.best, icon: "star.fill")
                }
                .frame(height: 44)
            }
        }
    }

    private func trendStat(label: String, value: Double, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(.modusCyan)
                Text(String(format: "%.0f", value))
                    .font(.title3.bold())
                    .foregroundColor(.modusCyan)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(Int(value))")
    }

    // MARK: - ACP-1020: Consolidated Metrics Card

    private var metricsCard: some View {
        Card(shadow: Shadow.medium) {
            VStack(spacing: Spacing.md) {
                // Sleep slider
                metricSlider(
                    icon: "bed.double.fill",
                    iconColor: .blue,
                    label: "Sleep",
                    value: $viewModel.sleepHours,
                    range: 0...12,
                    step: 0.5,
                    displayValue: viewModel.sleepHoursLabel,
                    minLabel: "0h",
                    maxLabel: "12h"
                )

                Divider()

                // Energy slider
                metricLevelSlider(
                    icon: "bolt.fill",
                    iconColor: viewModel.energyColor,
                    label: "Energy",
                    value: Binding(
                        get: { Double(viewModel.energyLevel) },
                        set: { viewModel.energyLevel = Int($0) }
                    ),
                    displayValue: viewModel.energyLevelLabel,
                    color: viewModel.energyColor
                )

                Divider()

                // Soreness slider
                metricLevelSlider(
                    icon: "figure.walk",
                    iconColor: viewModel.sorenessColor,
                    label: "Soreness",
                    value: Binding(
                        get: { Double(viewModel.sorenessLevel) },
                        set: { viewModel.sorenessLevel = Int($0) }
                    ),
                    displayValue: viewModel.sorenessLevelLabel,
                    color: viewModel.sorenessColor
                )

                Divider()

                // Stress slider
                metricLevelSlider(
                    icon: "brain.head.profile",
                    iconColor: viewModel.stressColor,
                    label: "Stress",
                    value: Binding(
                        get: { Double(viewModel.stressLevel) },
                        set: { viewModel.stressLevel = Int($0) }
                    ),
                    displayValue: viewModel.stressLevelLabel,
                    color: viewModel.stressColor
                )

                // Optional notes field
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Notes (Optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Any additional notes...", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(2...4)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Notes")
                }
            }
        }
    }

    private func metricSlider(
        icon: String,
        iconColor: Color,
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        displayValue: String,
        minLabel: String,
        maxLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                    .accessibilityHidden(true)

                Text(label)
                    .font(.subheadline.bold())

                Spacer()

                Text(displayValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Slider(value: value, in: range, step: step)
                .tint(iconColor)
                .accessibilityLabel("\(label): \(displayValue)")
        }
    }

    private func metricLevelSlider(
        icon: String,
        iconColor: Color,
        label: String,
        value: Binding<Double>,
        displayValue: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                    .accessibilityHidden(true)

                Text(label)
                    .font(.subheadline.bold())

                Spacer()

                Text(displayValue)
                    .font(.subheadline)
                    .foregroundColor(color)
            }

            // Visual level indicators
            HStack(spacing: 4) {
                ForEach(1...10, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(level <= Int(value.wrappedValue) ? color : Color.secondary.opacity(0.2))
                        .frame(height: 16)
                }
            }

            Slider(value: value, in: 1...10, step: 1)
                .tint(color)
                .accessibilityLabel("\(label): \(displayValue)")
        }
    }

    // MARK: - ACP-1020: Live Score Card

    private var liveScoreCard: some View {
        Card(shadow: Shadow.prominent) {
            HStack(spacing: Spacing.lg) {
                // Score circle
                ZStack {
                    Circle()
                        .fill(viewModel.liveScoreCategory.color.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Circle()
                        .fill(viewModel.liveScoreCategory.color)
                        .frame(width: 70, height: 70)

                    Text(viewModel.liveScoreFormatted)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Live Readiness")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(viewModel.liveScoreCategory.displayName)
                        .font(.title3.bold())
                        .foregroundColor(.primary)

                    Text("Updates as you adjust")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Live readiness score: \(viewModel.liveScoreFormatted), \(viewModel.liveScoreCategory.displayName)")
        }
    }

    // MARK: - ACP-1020: Submit Button

    private var submitButton: some View {
        Button {
            HapticFeedback.medium()
            Task {
                await submitCheckIn()
            }
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text(viewModel.hasSubmittedToday ? "Update Check-In" : "Submit Check-In")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(viewModel.canSubmit ? Color.modusCyan : Color.secondary.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.md)
        }
        .disabled(!viewModel.canSubmit || viewModel.isLoading)
        .accessibilityLabel(viewModel.hasSubmittedToday ? "Update today's check-in" : "Submit today's check-in")
        .shadow(color: viewModel.canSubmit ? Color.modusCyan.opacity(0.3) : Color.clear, radius: 8, y: 4)
    }



    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .scaleEffect(showingSuccessAnimation ? 1.0 : 0.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showingSuccessAnimation)

                Text(viewModel.hasSubmittedToday ? "Check-In Updated!" : "Check-In Submitted!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 20)
            )
            .onAppear {
                showingSuccessAnimation = true

                // Auto-dismiss after success animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
        .transition(.opacity)
    }

    // MARK: - Helper Methods

    /// Submit the check-in
    private func submitCheckIn() async {
        await viewModel.submitReadiness()
    }

    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }()

    /// Format today's date
    private var dateString: String {
        Self.fullDateFormatter.string(from: Date())
    }

    /// Auto-fill form fields from HealthKit data
    private func autoFillFromHealthKit() async {
        isAutoFilling = true
        defer { isAutoFilling = false }

        let service = HealthKitService.shared

        do {
            // Fetch today's data and baseline in parallel
            async let dataTask = service.syncTodayData()
            async let baselineTask = service.getHRVBaseline()

            let data = try await dataTask
            let baseline = try? await baselineTask

            // Update cached baseline for HRV trend indicator
            hrvBaseline = baseline

            // Update local state
            todayHRV = service.todayHRV
            todaySleep = service.todaySleep

            // Map sleep hours to sleep input (clamped to 0-12 range)
            if let sleepMinutes = data.sleepDurationMinutes {
                let sleepHours = Double(sleepMinutes) / 60.0
                viewModel.sleepHours = min(max(sleepHours, 0), 12)
            }

            // Calculate energy level based on HRV deviation from baseline
            if let hrv = data.hrvSDNN {
                let suggestedEnergy = calculateSuggestedEnergyLevel(currentHRV: hrv, baseline: baseline)
                viewModel.energyLevel = suggestedEnergy
            }

            isAutoFilled = true
            wasAutoFilled = true
        } catch {
            // Error is already handled by service
            DebugLogger.shared.warning("ReadinessCheckIn", "Failed to auto-fill from HealthKit: \(error.localizedDescription)")
        }
    }

    /// Calculate suggested energy level based on HRV deviation from baseline
    /// - Parameters:
    ///   - currentHRV: Today's HRV value
    ///   - baseline: 7-day rolling average HRV
    /// - Returns: Suggested energy level (1-10)
    private func calculateSuggestedEnergyLevel(currentHRV: Double, baseline: Double?) -> Int {
        guard let baseline = baseline, baseline > 0 else {
            // No baseline available - use absolute HRV ranges as fallback
            switch currentHRV {
            case 80...:
                return 10
            case 70..<80:
                return 9
            case 60..<70:
                return 8
            case 50..<60:
                return 7
            case 40..<50:
                return 5
            case 30..<40:
                return 4
            default:
                return 3
            }
        }

        let deviationPercent = ((currentHRV - baseline) / baseline) * 100

        // HRV > baseline + 10%: suggest energy 8-10
        // HRV < baseline - 10%: suggest energy 4-6
        // Otherwise: suggest energy 6-8
        if deviationPercent > 10 {
            // Good recovery - scale from 8-10 based on deviation
            let scaledEnergy = min(10, 8 + Int(deviationPercent / 10))
            return scaledEnergy
        } else if deviationPercent < -10 {
            // Poor recovery - scale from 4-6 based on deviation
            let scaledEnergy = max(4, 6 + Int(deviationPercent / 10))
            return scaledEnergy
        } else {
            // Normal range - suggest moderate energy 7
            return 7
        }
    }

    /// Request HealthKit authorization
    private func requestHealthKitAccess() async {
        do {
            let authorized = try await HealthKitService.shared.requestAuthorization()
            healthKitIsAuthorized = authorized
        } catch {
            DebugLogger.shared.warning("ReadinessCheckInView", "HealthKit authorization failed: \(error.localizedDescription)")
        }
    }

    /// Get color for HRV value display
    /// - Parameter hrv: HRV value in milliseconds
    /// - Returns: Color based on HRV range (Green >60, Yellow 40-60, Red <40)
    private func hrvColor(_ hrv: Double) -> Color {
        switch hrv {
        case 60...:
            return .green
        case 40..<60:
            return .yellow
        default:
            return .red
        }
    }

    /// Get color for sleep duration display
    /// - Parameter minutes: Total sleep duration in minutes
    /// - Returns: Color based on sleep hours (Green >=7h, Yellow 6-7h, Red <6h)
    private func sleepColor(_ minutes: Int) -> Color {
        let hours = Double(minutes) / 60.0
        if hours >= 7 { return .green }
        if hours >= 6 { return .yellow }
        return .red
    }

    /// Format sleep duration for display
    /// - Parameter minutes: Total sleep duration in minutes
    /// - Returns: Formatted string like "7h 30m"
    private func formatSleep(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
    }
}

// MARK: - Preview Provider

#if DEBUG
struct ReadinessCheckInView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Empty check-in (new entry)
            ReadinessCheckInView(patientId: UUID())
                .previewDisplayName("New Check-In")

            // Existing check-in (update)
            ReadinessCheckInView(patientId: UUID())
                .previewDisplayName("Update Check-In")
                .onAppear {
                    // Simulate existing entry in preview
                }

            // Dark mode
            ReadinessCheckInView(patientId: UUID())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")

            // iPad
            ReadinessCheckInView(patientId: UUID())
                .previewDevice("iPad Pro (12.9-inch) (6th generation)")
                .previewDisplayName("iPad")
        }
    }
}

struct HRVTrendIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Above baseline (good recovery)
            HStack {
                Text("Above baseline:")
                HRVTrendIndicator(hrv: 72.0, baseline: 60.0)
            }

            // Below baseline (poor recovery)
            HStack {
                Text("Below baseline:")
                HRVTrendIndicator(hrv: 48.0, baseline: 60.0)
            }

            // Near baseline (normal)
            HStack {
                Text("Near baseline:")
                HRVTrendIndicator(hrv: 61.0, baseline: 60.0)
            }

            // No baseline
            HStack {
                Text("No baseline:")
                HRVTrendIndicator(hrv: 65.0, baseline: nil)
            }
        }
        .padding()
        .previewDisplayName("HRV Trend Indicator")
    }
}
#endif
