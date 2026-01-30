//
//  ExerciseHistorySheet.swift
//  PTPerformance
//
//  BUILD 333: Quick exercise history lookup sheet
//  Shows recent sessions for a specific exercise with performance data
//

import SwiftUI

// MARK: - Exercise History Sheet

/// Sheet view for quickly viewing history of a specific exercise
struct ExerciseHistorySheet: View {
    let exerciseName: String
    let patientId: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ExerciseHistorySheetViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading history...")
                            .foregroundColor(.secondary)
                    }
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            Task {
                                await viewModel.fetchHistory(for: exerciseName, patientId: patientId)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if viewModel.sessions.isEmpty {
                    EmptyStateView(
                        title: "No History Yet",
                        message: "Complete workouts with this exercise to track your progress. Weight, reps, and performance trends will appear here.",
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: .blue,
                        action: nil
                    )
                    .padding()
                } else {
                    historyContent
                }
            }
            .navigationTitle(exerciseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.fetchHistory(for: exerciseName, patientId: patientId)
            }
        }
    }

    // MARK: - History Content

    private var historyContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Stats summary
                statsSummary

                // Session list
                sessionList
            }
            .padding()
        }
    }

    // MARK: - Stats Summary

    private var statsSummary: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                StatCard(
                    title: "Sessions",
                    value: "\(viewModel.sessions.count)",
                    icon: "calendar"
                )

                if let maxWeight = viewModel.maxWeight {
                    StatCard(
                        title: "Max Weight",
                        value: formatWeight(maxWeight),
                        icon: "trophy.fill",
                        highlight: true
                    )
                }

                if let avgWeight = viewModel.avgWeight {
                    StatCard(
                        title: "Avg Weight",
                        value: formatWeight(avgWeight),
                        icon: "chart.bar"
                    )
                }
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Session List

    private var sessionList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Sessions")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(viewModel.sessions) { session in
                SessionHistoryRow(session: session)
            }
        }
    }

    // MARK: - Helpers

    private func formatWeight(_ weight: Double) -> String {
        if weight == floor(weight) {
            return "\(Int(weight)) \(viewModel.loadUnit)"
        }
        return String(format: "%.1f %@", weight, viewModel.loadUnit)
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var highlight: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(highlight ? .yellow : .accentColor)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Session History Row

private struct SessionHistoryRow: View {
    let session: ExerciseSessionHistory

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.date, style: .date)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    if let sets = session.sets {
                        Label("\(sets) sets", systemImage: "number")
                    }
                    if let reps = session.reps {
                        Label(reps, systemImage: "repeat")
                    }
                    if let weight = session.weight, weight > 0 {
                        Label(formatWeight(weight, unit: session.loadUnit), systemImage: "scalemass")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)

                if let notes = session.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if session.isPersonalRecord {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                    .font(.title3)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func formatWeight(_ weight: Double, unit: String?) -> String {
        let unitStr = unit ?? "lbs"
        if weight == floor(weight) {
            return "\(Int(weight)) \(unitStr)"
        }
        return String(format: "%.1f %@", weight, unitStr)
    }
}

// MARK: - View Model

@MainActor
class ExerciseHistorySheetViewModel: ObservableObject {
    @Published var sessions: [ExerciseSessionHistory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var loadUnit: String = "lbs"

    private let supabase = PTSupabaseClient.shared
    private let logger = DebugLogger.shared

    var maxWeight: Double? {
        sessions.compactMap { $0.weight }.max()
    }

    var avgWeight: Double? {
        let weights = sessions.compactMap { $0.weight }.filter { $0 > 0 }
        guard !weights.isEmpty else { return nil }
        return weights.reduce(0, +) / Double(weights.count)
    }

    func fetchHistory(for exerciseName: String, patientId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // BUILD 333: Query manual_session_exercises joined with manual_sessions
            // Using direct query instead of RPC for simpler parameter handling
            let response: [ExerciseSessionHistoryRecord] = try await supabase.client
                .from("manual_session_exercises")
                .select("*, manual_sessions!inner(patient_id, completed_at)")
                .eq("exercise_name", value: exerciseName)
                .eq("manual_sessions.patient_id", value: patientId)
                .not("manual_sessions.completed_at", operator: .is, value: "null")
                .order("manual_sessions.completed_at", ascending: false)
                .limit(10)
                .execute()
                .value

            logger.log("ExerciseHistory: Fetched \(response.count) sessions for '\(exerciseName)'", level: .diagnostic)

            // Find max weight for PR calculation
            let maxWeightInHistory = response.compactMap { $0.weight }.max() ?? 0

            // Convert to display model
            sessions = response.map { record in
                ExerciseSessionHistory(
                    id: record.id,
                    date: record.sessionDate ?? Date(),
                    sets: record.sets,
                    reps: record.reps,
                    weight: record.weight,
                    loadUnit: record.loadUnit,
                    notes: record.notes,
                    isPersonalRecord: (record.weight ?? 0) > 0 && record.weight == maxWeightInHistory
                )
            }

            // Set load unit from first record
            if let firstUnit = response.first?.loadUnit, !firstUnit.isEmpty {
                loadUnit = firstUnit
            }

            isLoading = false
        } catch {
            logger.log("ExerciseHistory: Error fetching history: \(error.localizedDescription)", level: .error)
            errorMessage = "Unable to load exercise history"
            isLoading = false
        }
    }
}

// MARK: - Data Models

/// Display model for exercise session history
struct ExerciseSessionHistory: Identifiable {
    let id: UUID
    let date: Date
    let sets: Int?
    let reps: String?
    let weight: Double?
    let loadUnit: String?
    let notes: String?
    let isPersonalRecord: Bool
}

/// Database record from manual_session_exercises joined with manual_sessions
private struct ExerciseSessionHistoryRecord: Codable {
    let id: UUID
    let targetSets: Int?
    let targetReps: String?
    let targetLoad: Double?
    let loadUnit: String?
    let notes: String?
    let manualSessions: ManualSessionJoin

    struct ManualSessionJoin: Codable {
        let patientId: UUID
        let completedAt: Date?

        enum CodingKeys: String, CodingKey {
            case patientId = "patient_id"
            case completedAt = "completed_at"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case targetSets = "target_sets"
        case targetReps = "target_reps"
        case targetLoad = "target_load"
        case loadUnit = "load_unit"
        case notes
        case manualSessions = "manual_sessions"
    }

    // Convenience accessors for display model conversion
    var sessionDate: Date? { manualSessions.completedAt }
    var sets: Int? { targetSets }
    var reps: String? { targetReps }
    var weight: Double? { targetLoad }
}

// MARK: - Preview

#Preview {
    ExerciseHistorySheet(
        exerciseName: "Bench Press",
        patientId: "test-patient-id"
    )
}
