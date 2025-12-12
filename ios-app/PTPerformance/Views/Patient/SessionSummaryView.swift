import SwiftUI

/// Session Summary View - Build 33
/// Shows metrics after completing a session: total volume, avg RPE, avg pain, duration
struct SessionSummaryView: View {
    let session: Session
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
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
                    }
                    .padding(.top, 32)

                    // Metrics Cards
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
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
        }
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
            id: "session-1",
            phase_id: "phase-1",
            name: "Upper Body Strength",
            sequence: 1,
            weekday: 1,
            notes: nil,
            created_at: Date(),
            completed: true,
            completed_at: Date(),
            total_volume: 12500.50,
            avg_rpe: 7.5,
            avg_pain: 3.2,
            duration_minutes: 45
        ))
    }
}
