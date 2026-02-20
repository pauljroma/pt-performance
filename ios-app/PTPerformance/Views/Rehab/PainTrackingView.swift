import SwiftUI

/// Pain Tracking View - Rehab mode tab for logging pain levels
/// Uses PainBodyDiagramView for interactive body-based pain mapping
struct PainTrackingView: View {
    @EnvironmentObject var storeKit: StoreKitService

    @State private var painLocations: [PainLocation] = []
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Interactive pain body diagram
                    PainBodyDiagramView(painLocations: $painLocations)
                        .accessibilityIdentifier("pain_body_diagram")
                        .padding(.horizontal)

                    // Save button (visible when there are pain locations)
                    if !painLocations.isEmpty {
                        VStack(spacing: Spacing.sm) {
                            Button {
                                savePainLog()
                            } label: {
                                HStack {
                                    if isSaving {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "square.and.arrow.down.fill")
                                    }
                                    Text(isSaving ? "Saving..." : "Save Pain Log")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isSaving ? Color.accentColor.opacity(0.6) : Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(CornerRadius.md)
                            }
                            .disabled(isSaving)
                            .accessibilityIdentifier("pain_save_log")
                            .padding(.horizontal)

                            Text("\(painLocations.count) location\(painLocations.count == 1 ? "" : "s") selected")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            // Error message
                            if let saveError {
                                Text(saveError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    // Success toast
                    if showSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Pain log saved successfully")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(CornerRadius.md)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Instructions card when empty
                    if painLocations.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                Image(systemName: "hand.tap")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                Text("How to Log Pain")
                                    .font(.headline)
                            }

                            Text("Tap any body region on the diagram above to log a pain location with intensity. You can add multiple locations and adjust intensity levels.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.lg)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Pain Tracking")
        }
    }

    // MARK: - Save Action

    private func savePainLog() {
        guard !painLocations.isEmpty else { return }
        guard let athleteIdString = PTSupabaseClient.shared.userId,
              let athleteId = UUID(uuidString: athleteIdString) else {
            saveError = "Unable to identify your account. Please sign in again."
            return
        }

        isSaving = true
        saveError = nil
        showSuccess = false

        // Gather data from selected pain locations
        let regions = painLocations.map { $0.region.rawValue }
        let maxIntensity = painLocations.map(\.intensity).max() ?? 5
        let notes: String? = painLocations.count > 1
            ? painLocations.map { "\($0.region.displayName): \($0.intensity)/10" }.joined(separator: "; ")
            : painLocations.first?.notes

        Task {
            do {
                try await PainTrackingService.shared.savePainEntry(
                    athleteId: athleteId,
                    regions: regions,
                    intensity: maxIntensity,
                    notes: notes
                )

                isSaving = false
                withAnimation {
                    showSuccess = true
                }
                painLocations = []

                // Hide success message after 3 seconds
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                withAnimation {
                    showSuccess = false
                }
            } catch {
                isSaving = false
                saveError = "Failed to save pain log. Please try again."
            }
        }
    }
}
