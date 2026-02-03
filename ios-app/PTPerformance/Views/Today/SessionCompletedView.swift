import SwiftUI

/// View displayed when today's session has been completed
/// Shows success message, metrics summary, and options for next steps
struct SessionCompletedView: View {
    let session: Session?
    let onBrowseLibrary: () -> Void
    let onCreateCustomWorkout: () -> Void
    let onViewSummary: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Success icon and message
            successSection

            Divider()
                .padding(.vertical, 8)

            // Options for next steps
            nextStepsSection
        }
        .padding(DesignTokens.spacingXLarge)
        .background(Color(.systemBackground))
        .cornerRadius(DesignTokens.cornerRadiusLarge)
        .adaptiveShadow(Shadow.medium)
        .padding()
    }

    // MARK: - Success Section

    @ViewBuilder
    private var successSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(.green)

            Text("Session Complete!")
                .font(.title)
                .bold()

            if let session = session {
                Text(session.name)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            // Show metrics if available
            if let session = session {
                metricsRow(session)
            }
        }
    }

    @ViewBuilder
    private func metricsRow(_ session: Session) -> some View {
        HStack(spacing: 24) {
            if let volume = session.total_volume, volume > 0 {
                VStack {
                    Text(volume >= 1000 ? String(format: "%.1fk", volume / 1000) : "\(Int(volume))")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("lbs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let duration = session.duration_minutes {
                VStack {
                    Text("\(duration)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let rpe = session.avg_rpe {
                VStack {
                    Text(String(format: "%.1f", rpe))
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("RPE")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Next Steps Section

    @ViewBuilder
    private var nextStepsSection: some View {
        VStack(spacing: 12) {
            Text("Want to do more?")
                .font(.headline)
                .foregroundColor(.secondary)

            // Start another workout from library
            Button(action: {
                HapticFeedback.light()
                onBrowseLibrary()
            }) {
                HStack {
                    Image(systemName: "books.vertical.fill")
                    Text("Browse Workout Library")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(DesignTokens.cornerRadiusMedium)
            }
            .accessibilityLabel("Browse Workout Library")
            .accessibilityHint("Opens saved workout templates")

            // Create custom workout
            Button(action: {
                HapticFeedback.light()
                onCreateCustomWorkout()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Custom Workout")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.15))
                .foregroundColor(.green)
                .cornerRadius(DesignTokens.cornerRadiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                        .stroke(Color.green, lineWidth: 1)
                )
            }
            .accessibilityLabel("Create Custom Workout")
            .accessibilityHint("Opens workout builder to create a new workout")

            // View summary
            Button(action: onViewSummary) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                    Text("View Session Summary")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            .padding(.top, 8)
            .accessibilityLabel("View Session Summary")
            .accessibilityHint("Shows detailed summary of completed workout")
        }
    }
}

#if DEBUG
struct SessionCompletedView_Previews: PreviewProvider {
    static var previews: some View {
        SessionCompletedView(
            session: nil,
            onBrowseLibrary: {},
            onCreateCustomWorkout: {},
            onViewSummary: {}
        )
        .background(Color(.systemGroupedBackground))
    }
}
#endif
