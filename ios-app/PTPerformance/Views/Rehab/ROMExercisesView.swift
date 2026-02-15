import SwiftUI

/// ROM Exercises View - Rehab mode tab for range of motion exercises
/// Shows ROM progress card with real measurement data when available
struct ROMExercisesView: View {
    @EnvironmentObject var storeKit: StoreKitService

    @State private var measurements: [ROMeasurement] = []
    @State private var isLoading = true
    @State private var loadError: String?
    /// Track whether we already logged the "table not found" diagnostic to avoid spamming on every appearance
    @State private var hasLoggedTableMissing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    if isLoading {
                        ProgressView("Loading ROM data...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let error = loadError {
                        // Error state with retry
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 36))
                                .foregroundColor(.orange)
                            Text("Failed to Load ROM Data")
                                .font(.headline)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button {
                                Task { await loadMeasurements() }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Retry")
                                }
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.modusCyan)
                                .foregroundColor(.white)
                                .cornerRadius(CornerRadius.md)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .padding()
                    } else if measurements.isEmpty {
                        // Empty state - no ROM measurements yet
                        romEmptyState
                    } else {
                        // ROM summary card with real data
                        ROMSummaryCard(
                            measurements: measurements
                        )

                        // Per-joint progress cards for joints that have measurements
                        let joints = Set(measurements.map { $0.joint })
                        ForEach(Array(joints).sorted(), id: \.self) { joint in
                            ROMProgressCard(
                                measurements: measurements,
                                targetJoint: joint,
                                targetMovement: nil
                            )
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("ROM Exercises")
            .task {
                await loadMeasurements()
            }
            .refreshable {
                await loadMeasurements()
            }
        }
    }

    // MARK: - Empty State

    private var romEmptyState: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "figure.flexibility")
                    .font(.system(size: 48))
                    .foregroundColor(.purple.opacity(0.5))

                Text("No ROM Measurements Yet")
                    .font(.headline)

                Text("Your therapist will record range of motion measurements during your sessions. Once recorded, you will see progress tracking for each joint here.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, Spacing.lg)

            // Info card about ROM tracking
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.modusCyan)
                    Text("About ROM Tracking")
                        .font(.subheadline.weight(.semibold))
                }

                Text("Range of Motion measurements track how far each joint can move. Your PT measures this at regular intervals to monitor your rehabilitation progress against normal ranges.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.lg)
        }
        .padding()
    }

    // MARK: - Data Loading

    private func loadMeasurements() async {
        isLoading = true
        loadError = nil

        do {
            guard let patientId = PTSupabaseClient.shared.userId else {
                isLoading = false
                return
            }

            let response = try await PTSupabaseClient.shared.client
                .from("rom_measurements")
                .select()
                .eq("patient_id", value: patientId)
                .order("created_at", ascending: false)
                .limit(100)
                .execute()

            let decoded = try PTSupabaseClient.flexibleDecoder.decode(
                [ROMeasurement].self,
                from: response.data
            )
            measurements = decoded
        } catch {
            let errorDesc = error.localizedDescription
            // Check if the error is about the table not existing (schema cache miss)
            if errorDesc.contains("rom_measurements") && (errorDesc.contains("schema cache") || errorDesc.contains("Could not find")) {
                // Table doesn't exist yet — show empty state, not an error
                measurements = []
                if !hasLoggedTableMissing {
                    DebugLogger.shared.diagnostic("ROMExercisesView: rom_measurements table not found in schema — showing empty state")
                    hasLoggedTableMissing = true
                }
            } else {
                DebugLogger.shared.error("ROMExercisesView", "Failed to load ROM measurements: \(errorDesc)")
                loadError = errorDesc
            }
        }

        isLoading = false
    }
}
