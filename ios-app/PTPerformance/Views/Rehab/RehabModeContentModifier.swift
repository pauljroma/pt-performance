//
//  RehabModeContentModifier.swift
//  PTPerformance
//
//  Rehab Mode Content Modifier - Conditionally shows Rehab-specific UI
//  Adds pain tracking, safety checks, and ROM progress to views when in Rehab mode
//

import SwiftUI

/// View modifier that adds Rehab-specific content when user is in Rehab mode
struct RehabModeContentModifier: ViewModifier {
    @StateObject private var modeService = ModeService.shared

    let patientId: UUID?

    @State private var showRehabStatusCard = true
    @State private var painLocations: [PainLocation] = []
    @State private var todayPainScore: Int?
    @State private var previousPainScore: Int? // TODO: Wire when PainTrackingService is available
    @State private var hasActiveAlerts = false // TODO: Wire when PainTrackingService is available
    @State private var alertCount = 0 // TODO: Wire when PainTrackingService is available
    @State private var deloadUrgency: DeloadUrgency?
    @State private var showPainDiagram = false
    @State private var showRehabDashboard = false
    @State private var showSafetyInfo = false

    func body(content: Content) -> some View {
        if modeService.currentMode == .rehab {
            content
                .safeAreaInset(edge: .top) {
                    if showRehabStatusCard {
                        rehabStatusCardSection
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .sheet(isPresented: $showPainDiagram) {
                    painDiagramSheet
                }
                .sheet(isPresented: $showRehabDashboard) {
                    NavigationStack {
                        RehabModeDashboardView()
                    }
                }
                .sheet(isPresented: $showSafetyInfo) {
                    safetyInfoSheet
                }
                .task(id: patientId) {
                    await loadRehabData()
                }
        } else {
            content
        }
    }

    // MARK: - Rehab Status Card Section

    private var rehabStatusCardSection: some View {
        VStack(spacing: 0) {
            RehabModeStatusCard(
                todayPainScore: todayPainScore,
                previousPainScore: previousPainScore,
                activePainRegions: painLocations,
                hasActiveAlerts: hasActiveAlerts,
                alertCount: alertCount,
                deloadUrgency: deloadUrgency,
                onLogPain: { showPainDiagram = true },
                onViewAlerts: { showSafetyInfo = true },
                onViewDashboard: { showRehabDashboard = true }
            )
            .padding(.horizontal)
            .padding(.top, Spacing.xs)
            .padding(.bottom, Spacing.sm)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Pain Diagram Sheet

    private var painDiagramSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PainBodyDiagramView(painLocations: $painLocations)

                Button {
                    HapticFeedback.light()
                    Task {
                        await savePainData()
                        showPainDiagram = false
                    }
                } label: {
                    Text("Save Pain Log")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ModeTheme.rehab.primaryColor)
                        .cornerRadius(CornerRadius.md)
                }
                .accessibilityLabel("Save Pain Log")
                .accessibilityHint("Saves your current pain assessment")
                .padding()
            }
            .navigationTitle("Log Pain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticFeedback.light()
                        painLocations = []
                        showPainDiagram = false
                    }
                    .accessibilityHint("Discards pain log and returns to previous screen")
                }
            }
        }
    }

    // MARK: - Safety Info Sheet

    private var safetyInfoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // General Safety Guidelines
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Rehab Safety Guidelines")
                            .font(.headline)

                        safetyInfoCard(
                            title: "Pain Monitoring",
                            description: "Track your pain before and after each exercise. Notify your therapist if pain increases significantly.",
                            icon: "heart.text.square",
                            color: .red
                        )

                        safetyInfoCard(
                            title: "Movement Restrictions",
                            description: "Stay within your prescribed range of motion. Avoid movements that cause sharp or shooting pain.",
                            icon: "exclamationmark.triangle",
                            color: .orange
                        )

                        safetyInfoCard(
                            title: "When to Stop",
                            description: "Stop immediately if you experience: sharp pain, numbness, significant swelling, or instability.",
                            icon: "hand.raised.fill",
                            color: .red
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Safety Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticFeedback.light()
                        showSafetyInfo = false
                    }
                    .accessibilityHint("Closes safety information")
                }
            }
        }
    }

    private func safetyInfoCard(title: String, description: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.tertiarySystemBackground))
        )
    }

    // MARK: - Data Loading

    private func loadRehabData() async {
        guard let patientId = patientId else { return }

        // Load deload status
        do {
            let service = DeloadRecommendationService.shared
            try await service.fetchRecommendation(patientId: patientId)
            let recommendation = service.recommendation
            deloadUrgency = recommendation?.urgency
        } catch {
            DebugLogger.shared.log("Failed to load deload status: \(error)", level: .warning)
        }

        // Pain data and alerts are loaded by the parent RehabModeDashboardView
        // This modifier focuses on deload status for the overlay banner
    }

    private func savePainData() async {
        // NOTE: Pain data is only stored locally in @State for this session.
        // No persistence layer exists yet. Full pain tracking is available
        // through RehabModeDashboardView once PainTrackingService is implemented.
        if !painLocations.isEmpty {
            let totalIntensity = painLocations.reduce(0) { $0 + $1.intensity }
            todayPainScore = Int(round(Double(totalIntensity) / Double(painLocations.count)))
        }
    }
}

// MARK: - View Extension

extension View {
    /// Adds Rehab mode-specific content when the user is in Rehab mode
    /// Shows pain tracking, safety alerts, and quick access to rehab features
    func rehabModeContent(patientId: UUID?) -> some View {
        modifier(RehabModeContentModifier(patientId: patientId))
    }
}

// MARK: - Rehab Mode Exercise Warning Banner

/// Banner shown above exercises that may need modification in Rehab mode
struct RehabExerciseWarningBanner: View {
    let exerciseName: String
    let warningType: RehabExerciseWarning
    var onViewModification: (() -> Void)?
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: warningType.icon)
                .foregroundColor(warningType.color)
                .font(.subheadline)

            VStack(alignment: .leading, spacing: 2) {
                Text(warningType.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)

                Text(warningType.message(for: exerciseName))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let onViewModification = onViewModification {
                Button("Modify") {
                    HapticFeedback.light()
                    onViewModification()
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(warningType.color)
            }

            if let onDismiss = onDismiss {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Dismiss warning")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(warningType.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(warningType.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

/// Types of warnings for exercises in Rehab mode
enum RehabExerciseWarning {
    case painRelated       // Exercise affects painful area
    case romRestriction    // Exercise may exceed ROM limits
    case loadCaution       // Reduce load recommendation
    case skipRecommended   // Consider skipping this exercise

    var icon: String {
        switch self {
        case .painRelated: return "exclamationmark.triangle.fill"
        case .romRestriction: return "ruler"
        case .loadCaution: return "scalemass"
        case .skipRecommended: return "xmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .painRelated: return .orange
        case .romRestriction: return .purple
        case .loadCaution: return .yellow
        case .skipRecommended: return .red
        }
    }

    var title: String {
        switch self {
        case .painRelated: return "Pain Area Involved"
        case .romRestriction: return "ROM Restriction"
        case .loadCaution: return "Reduce Load"
        case .skipRecommended: return "Consider Skipping"
        }
    }

    func message(for exercise: String) -> String {
        switch self {
        case .painRelated:
            return "\(exercise) involves your painful area. Monitor closely."
        case .romRestriction:
            return "Stay within your prescribed ROM for \(exercise)."
        case .loadCaution:
            return "Consider reducing weight for \(exercise) today."
        case .skipRecommended:
            return "Your therapist may recommend skipping \(exercise)."
        }
    }
}

// MARK: - Rehab Mode Quick Pain Check

/// Quick inline pain check shown during workout
struct RehabQuickPainCheck: View {
    @Binding var painLevel: Int
    var exerciseName: String
    var onComplete: () -> Void

    @State private var selectedLevel: Int = 0

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Header
            HStack {
                Image(systemName: "heart.text.square")
                    .foregroundColor(ModeTheme.rehab.primaryColor)
                Text("Quick Pain Check")
                    .font(.headline)
                Spacer()
            }

            Text("Rate your pain after \(exerciseName)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Pain scale selector
            HStack(spacing: Spacing.xs) {
                ForEach(0...10, id: \.self) { level in
                    Button {
                        selectedLevel = level
                        HapticFeedback.light()
                    } label: {
                        Text("\(level)")
                            .font(.subheadline.weight(selectedLevel == level ? .bold : .regular))
                            .foregroundColor(selectedLevel == level ? .white : .primary)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(selectedLevel == level ? painColor(for: level) : Color(.tertiarySystemFill))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Pain level \(level)")
                }
            }

            // Labels
            HStack {
                Text("No Pain")
                    .font(.caption2)
                    .foregroundColor(.green)
                Spacer()
                Text("Worst")
                    .font(.caption2)
                    .foregroundColor(.red)
            }

            // Confirm button
            Button {
                HapticFeedback.light()
                painLevel = selectedLevel
                onComplete()
            } label: {
                Text("Continue")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(ModeTheme.rehab.primaryColor)
                    )
            }
            .accessibilityLabel("Continue with selected pain level")

            // Warning for high pain
            if selectedLevel >= 7 {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Consider stopping or modifying remaining exercises")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(Color.red.opacity(0.1))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .onAppear {
            selectedLevel = painLevel
        }
    }

    private func painColor(for level: Int) -> Color {
        switch level {
        case 0: return .green
        case 1...3: return .yellow
        case 4...6: return .orange
        case 7...10: return .red
        default: return .gray
        }
    }
}

// MARK: - Previews

#Preview("Exercise Warning Banner") {
    VStack(spacing: Spacing.sm) {
        RehabExerciseWarningBanner(
            exerciseName: "Shoulder Press",
            warningType: .painRelated,
            onViewModification: { print("Modify") },
            onDismiss: { print("Dismiss") }
        )

        RehabExerciseWarningBanner(
            exerciseName: "Squat",
            warningType: .romRestriction,
            onViewModification: { print("Modify") }
        )

        RehabExerciseWarningBanner(
            exerciseName: "Deadlift",
            warningType: .loadCaution
        )

        RehabExerciseWarningBanner(
            exerciseName: "Box Jump",
            warningType: .skipRecommended,
            onDismiss: { print("Dismiss") }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Quick Pain Check") {
    RehabQuickPainCheck(
        painLevel: .constant(0),
        exerciseName: "Shoulder Press"
    ) {
        print("Complete")
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Quick Pain Check - High Pain") {
    RehabQuickPainCheck(
        painLevel: .constant(8),
        exerciseName: "Squat"
    ) {
        print("Complete")
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
