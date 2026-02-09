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
                    // Main content
                    Form {
                        quickFillSection

                        // Data from Apple Watch badge
                        if wasAutoFilled {
                            HStack {
                                Image(systemName: "applewatch")
                                Text("Data from Apple Watch")
                            }
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal)
                            .listRowBackground(Color.clear)
                        }

                        headerSection
                        sleepSection
                        sorenessSection
                        energySection
                        stressSection
                        notesSection
                        scorePreviewSection
                        submitSection
                    }
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

    // MARK: - Quick Fill Section

    private var quickFillSection: some View {
        Section {
            if HealthKitService.isHealthKitAvailable {
                if healthKitIsAuthorized {
                    // Authorized: Show auto-fill button and health data
                    VStack(alignment: .leading, spacing: 12) {
                        // Auto-fill button
                        Button {
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
                                    Image(systemName: "applewatch")
                                }
                                Text("Fill from Apple Watch")
                                Spacer()
                                if isAutoFilled {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .disabled(isAutoFilling)
                        .accessibilityLabel("Fill from Apple Watch")
                        .accessibilityHint("Imports sleep and HRV data from your Apple Watch")

                        // Show today's HRV with trend indicator
                        if let hrv = todayHRV {
                            HStack {
                                Text("Today's HRV")
                                Spacer()
                                HRVTrendIndicator(hrv: hrv, baseline: hrvBaseline)
                                Text("\(Int(hrv)) ms")
                                    .foregroundColor(hrvColor(hrv))
                            }
                            .font(.subheadline)
                        }

                        // Show sleep from Apple Watch
                        if let sleep = todaySleep {
                            HStack {
                                Text("Last Night's Sleep")
                                Spacer()
                                Text(formatSleep(sleep.totalMinutes))
                                    .foregroundColor(sleepColor(sleep.totalMinutes))
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    // Not authorized: Show connect button
                    Button("Connect Apple Watch") {
                        showHealthKitPrompt = true
                    }
                    .accessibilityLabel("Connect Apple Watch")
                    .accessibilityHint("Opens Apple Health permissions to sync watch data")
                }
            }
        } header: {
            if HealthKitService.isHealthKitAvailable {
                Text("Quick Fill")
            }
        } footer: {
            if HealthKitService.isHealthKitAvailable && healthKitIsAuthorized {
                Text("Pull sleep hours and HRV from your Apple Watch to auto-fill the form")
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(dateString)
                    .font(.headline)
                    .foregroundColor(.primary)

                if viewModel.hasSubmittedToday {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("You've already checked in today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("How are you feeling today?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today's date: \(dateString)")
    }

    // MARK: - Sleep Section

    private var sleepSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    Text("Sleep")
                        .font(.headline)
                    Spacer()
                    Text(viewModel.sleepHoursLabel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Slider(
                    value: $viewModel.sleepHours,
                    in: 0...12,
                    step: 0.5
                ) {
                    Text("Sleep Hours")
                } minimumValueLabel: {
                    Text("0")
                        .font(.caption)
                } maximumValueLabel: {
                    Text("12")
                        .font(.caption)
                }
                .tint(.blue)
                .accessibilityLabel("Hours of sleep")
                .accessibilityValue(viewModel.sleepHoursLabel)
                .accessibilityHint("Adjust to set hours slept last night")
            }
            .padding(.vertical, 4)
        } header: {
            Text("Sleep Quality")
        } footer: {
            Text("How many hours did you sleep last night?")
        }
    }

    // MARK: - Soreness Section

    private var sorenessSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(viewModel.sorenessColor)
                        .frame(width: 24)
                    Text("Soreness")
                        .font(.headline)
                    Spacer()
                    Text(viewModel.sorenessLevelLabel)
                        .font(.subheadline)
                        .foregroundColor(viewModel.sorenessColor)
                }

                HStack(spacing: 4) {
                    ForEach(1...10, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(level <= viewModel.sorenessLevel ? viewModel.sorenessColor : Color.gray.opacity(0.3))
                            .frame(height: 24)
                    }
                }

                Slider(
                    value: Binding(
                        get: { Double(viewModel.sorenessLevel) },
                        set: { viewModel.sorenessLevel = Int($0) }
                    ),
                    in: 1...10,
                    step: 1
                ) {
                    Text("Soreness Level")
                } minimumValueLabel: {
                    VStack {
                        Text("😊")
                        Text("None")
                            .font(.caption2)
                    }
                } maximumValueLabel: {
                    VStack {
                        Text("😣")
                        Text("Severe")
                            .font(.caption2)
                    }
                }
                .tint(viewModel.sorenessColor)
                .accessibilityLabel("Muscle soreness level")
                .accessibilityValue("\(viewModel.sorenessLevel) out of 10, \(viewModel.sorenessLevelLabel)")
                .accessibilityHint("1 is no soreness, 10 is severe soreness")
            }
            .padding(.vertical, 4)
        } header: {
            Text("Muscle Soreness")
        } footer: {
            Text("Rate your overall muscle soreness (1 = no soreness, 10 = extreme)")
        }
    }

    // MARK: - Energy Section

    private var energySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(viewModel.energyColor)
                        .frame(width: 24)
                    Text("Energy")
                        .font(.headline)
                    Spacer()
                    Text(viewModel.energyLevelLabel)
                        .font(.subheadline)
                        .foregroundColor(viewModel.energyColor)
                }

                HStack(spacing: 4) {
                    ForEach(1...10, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(level <= viewModel.energyLevel ? viewModel.energyColor : Color.gray.opacity(0.3))
                            .frame(height: 24)
                    }
                }

                Slider(
                    value: Binding(
                        get: { Double(viewModel.energyLevel) },
                        set: { viewModel.energyLevel = Int($0) }
                    ),
                    in: 1...10,
                    step: 1
                ) {
                    Text("Energy Level")
                } minimumValueLabel: {
                    VStack {
                        Text("😴")
                        Text("Low")
                            .font(.caption2)
                    }
                } maximumValueLabel: {
                    VStack {
                        Text("⚡️")
                        Text("High")
                            .font(.caption2)
                    }
                }
                .tint(viewModel.energyColor)
                .accessibilityLabel("Energy level")
                .accessibilityValue("\(viewModel.energyLevel) out of 10, \(viewModel.energyLevelLabel)")
                .accessibilityHint("1 is exhausted, 10 is fully energized")
            }
            .padding(.vertical, 4)
        } header: {
            Text("Energy Level")
        } footer: {
            Text("How energized do you feel? (1 = exhausted, 10 = fully energized)")
        }
    }

    // MARK: - Stress Section

    private var stressSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(viewModel.stressColor)
                        .frame(width: 24)
                    Text("Stress")
                        .font(.headline)
                    Spacer()
                    Text(viewModel.stressLevelLabel)
                        .font(.subheadline)
                        .foregroundColor(viewModel.stressColor)
                }

                HStack(spacing: 4) {
                    ForEach(1...10, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(level <= viewModel.stressLevel ? viewModel.stressColor : Color.gray.opacity(0.3))
                            .frame(height: 24)
                    }
                }

                Slider(
                    value: Binding(
                        get: { Double(viewModel.stressLevel) },
                        set: { viewModel.stressLevel = Int($0) }
                    ),
                    in: 1...10,
                    step: 1
                ) {
                    Text("Stress Level")
                } minimumValueLabel: {
                    VStack {
                        Text("😌")
                        Text("Calm")
                            .font(.caption2)
                    }
                } maximumValueLabel: {
                    VStack {
                        Text("😰")
                        Text("High")
                            .font(.caption2)
                    }
                }
                .tint(viewModel.stressColor)
                .accessibilityLabel("Stress level")
                .accessibilityValue("\(viewModel.stressLevel) out of 10, \(viewModel.stressLevelLabel)")
                .accessibilityHint("1 is calm, 10 is extreme stress")
            }
            .padding(.vertical, 4)
        } header: {
            Text("Stress Level")
        } footer: {
            Text("How stressed do you feel? (1 = no stress, 10 = extreme stress)")
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        Section {
            TextField("Add any notes...", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.plain)
                .accessibilityLabel("Notes")
                .accessibilityHint("Optional notes about your wellness today")
        } header: {
            Text("Notes (Optional)")
        } footer: {
            Text("Any additional details about how you're feeling?")
        }
    }

    // MARK: - Score Preview Section

    private var scorePreviewSection: some View {
        Section {
            // BUILD 123: Show live score preview during form entry
            if let entry = viewModel.todayEntry, let score = entry.readinessScore {
                // Submitted entry - show actual score from database
                scorePreviewCard(score: score)
            } else {
                // No submission yet - show live calculated score
                liveScorePreviewCard
            }
        } header: {
            Text("Readiness Score Preview")
        }
    }

    /// BUILD 123: Live score preview card with battery visualization
    private var liveScorePreviewCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Battery-style circle indicator
                ZStack {
                    Circle()
                        .fill(viewModel.liveScoreCategory.color)
                        .frame(width: 80, height: 80)

                    Text(viewModel.liveScoreFormatted)
                        .font(.title.bold())
                        .foregroundColor(.white)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.liveScoreCategory.displayName)
                        .font(.title2.bold())
                        .foregroundColor(viewModel.liveScoreCategory.color)

                    Text("Live Preview")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Updates as you adjust sliders")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(viewModel.liveScoreCategory.color.opacity(0.1))
            .cornerRadius(12)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Live readiness score preview: \(viewModel.liveScoreFormatted), \(viewModel.liveScoreCategory.displayName)")
            .accessibilityHint("Score updates automatically as you adjust the sliders")
        }
    }

    // MARK: - Submit Section

    private var submitSection: some View {
        Section {
            Button {
                Task {
                    await submitCheckIn()
                }
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Text(viewModel.hasSubmittedToday ? "Update Check-In" : "Submit Check-In")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .disabled(!viewModel.canSubmit)
            .buttonStyle(.borderedProminent)
            .listRowBackground(viewModel.canSubmit ? Color.accentColor : Color.gray.opacity(0.3))
            .accessibilityLabel(viewModel.hasSubmittedToday ? "Update today's check-in" : "Submit today's check-in")
            .accessibilityHint(viewModel.canSubmit ? "Tap to submit" : "Complete all required fields to enable")
        }
    }

    // MARK: - Score Preview Card

    private func scorePreviewCard(score: Double) -> some View {
        let category = ReadinessCategory.category(for: score)

        return VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Score")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", score))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(category.color)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(category.displayName)
                        .font(.headline)
                        .foregroundColor(category.color)
                    Text("Readiness")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            HStack {
                Image(systemName: category.recommendsRest ? "bed.double.fill" : "figure.run")
                    .foregroundColor(category.color)
                Text(category.recommendation)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(category.color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(category.color.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Readiness score: \(String(format: "%.1f", score)), \(category.displayName). \(category.recommendation)")
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

    /// Format today's date
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: Date())
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
