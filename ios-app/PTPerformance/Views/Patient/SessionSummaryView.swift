import SwiftUI

/// Session Summary View - Build 60: Enhanced with PRs and motivational messages
/// Shows metrics after completing a session: exercises, volume, duration, PRs, compliance
struct SessionSummaryView: View {
    let session: Session
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = SessionSummaryViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Calculating stats...")
                } else if let error = viewModel.errorMessage {
                    ErrorStateView.genericError(message: error) {
                        Task {
                            if let patientId = appState.userId {
                                await viewModel.calculateSummary(for: session, patientId: patientId)
                            }
                        }
                    }
                } else {
                    summaryContent
                }
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if let patientId = appState.userId {
                    await viewModel.calculateSummary(for: session, patientId: patientId)
                }
            }
        }
    }

    @ViewBuilder
    private var summaryContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success Header
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.green)

                    Text("Session Complete!")
                        .font(.title)
                        .bold()

                    Text(session.name)
                        .font(.title3)
                        .foregroundColor(.secondary)

                    if let completedAt = session.completed_at {
                        Text(formatDate(completedAt))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Motivational Message
                    if let summary = viewModel.summary {
                        Text(summary.motivationalMessage)
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                }
                .padding(.top, 32)

                // Stats Grid
                if let summary = viewModel.summary {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: "Exercises",
                            value: "\(summary.exercisesCompleted)",
                            icon: "list.bullet",
                            color: .blue
                        )

                        StatCard(
                            title: "PRs",
                            value: "\(summary.prCount)",
                            icon: "star.fill",
                            color: summary.prCount > 0 ? .yellow : .gray
                        )

                        StatCard(
                            title: "Volume",
                            value: summary.volumeFormatted,
                            icon: "scalemass.fill",
                            color: .purple
                        )

                        StatCard(
                            title: "Duration",
                            value: summary.durationFormatted,
                            icon: "clock.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)

                    // Compliance Score
                    VStack(spacing: 12) {
                        Text("Compliance Score")
                            .font(.headline)

                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                                .frame(width: 120, height: 120)

                            Circle()
                                .trim(from: 0, to: summary.complianceScore / 100)
                                .stroke(complianceColor(summary.complianceScore), lineWidth: 15)
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut, value: summary.complianceScore)

                            VStack(spacing: 4) {
                                Text(summary.complianceFormatted)
                                    .font(.title)
                                    .bold()
                                    .foregroundColor(complianceColor(summary.complianceScore))

                                Text("achieved")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }

                // Legacy metrics (if calculated server-side)
                if viewModel.summary == nil {
                    legacyMetricsView
                }

                // Done Button
                Button(action: {
                    dismiss()
                }) {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 16)

                Spacer()
            }
        }
    }

    // Legacy metrics view (Build 33 format)
    @ViewBuilder
    private var legacyMetricsView: some View {
        VStack(spacing: 16) {
            if let volume = session.total_volume, volume > 0 {
                MetricCard(
                    title: "Total Volume",
                    value: formatVolume(volume),
                    icon: "scalemass.fill",
                    color: .blue
                )
            }

            if let rpe = session.avg_rpe {
                MetricCard(
                    title: "Average RPE",
                    value: formatScore(rpe),
                    subtitle: "out of 10",
                    icon: "bolt.fill",
                    color: rpeColor(rpe)
                )
            }

            if let pain = session.avg_pain {
                MetricCard(
                    title: "Average Pain",
                    value: formatScore(pain),
                    subtitle: "out of 10",
                    icon: "hand.raised.fill",
                    color: painColor(pain)
                )
            }

            if let duration = session.duration_minutes, duration > 0 {
                MetricCard(
                    title: "Duration",
                    value: "\(duration) min",
                    icon: "clock.fill",
                    color: .purple
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Formatting Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk lbs", volume / 1000)
        }
        return String(format: "%.0f lbs", volume)
    }

    private func formatScore(_ score: Double) -> String {
        return String(format: "%.1f", score)
    }

    // MARK: - Color Helpers

    private func rpeColor(_ rpe: Double) -> Color {
        switch rpe {
        case 0..<4:
            return .green
        case 4..<7:
            return .yellow
        case 7..<9:
            return .orange
        default:
            return .red
        }
    }

    private func painColor(_ pain: Double) -> Color {
        switch pain {
        case 0..<3:
            return .green
        case 3..<6:
            return .yellow
        case 6..<8:
            return .orange
        default:
            return .red
        }
    }

    private func complianceColor(_ compliance: Double) -> Color {
        switch compliance {
        case 95...:
            return .green
        case 80..<95:
            return .blue
        case 60..<80:
            return .yellow
        default:
            return .orange
        }
    }
}

// MARK: - Stat Card Component (Build 60)
// Made private to avoid conflict with Analytics chart StatCard views

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .bold()

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

/// Metric Card Component
struct MetricCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(color.opacity(0.1))
                .cornerRadius(12)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .bold()

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Preview

struct SessionSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SessionSummaryView(session: Session(
            id: UUID(),
            phase_id: UUID(),
            name: "Upper Body Strength",
            sequence: 1,
            weekday: 1,
            notes: nil,
            created_at: Date(),
            completed: true,
            started_at: Date().addingTimeInterval(-2700), // BUILD 123: 45 min ago
            completed_at: Date(),
            total_volume: 12500.50,
            avg_rpe: 7.5,
            avg_pain: 3.2,
            duration_minutes: 45
        ))
    }
}
