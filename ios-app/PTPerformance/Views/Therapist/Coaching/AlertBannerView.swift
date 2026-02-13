// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  AlertBannerView.swift
//  PTPerformance
//
//  Critical alert banner component for the coaching dashboard.
//  Displays prominent alerts for urgent patient exceptions.
//

import SwiftUI

// MARK: - AlertBannerView

struct AlertBannerView: View {
    let exception: PatientException
    var onTap: (() -> Void)?
    var onDismiss: (() -> Void)?

    @State private var isVisible = true
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if isVisible {
            Button(action: {
                HapticFeedback.medium()
                onTap?()
            }) {
                HStack(spacing: Spacing.md) {
                    // Alert icon with pulse animation
                    alertIcon

                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Critical Alert")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Spacer()

                            Text(timeAgoText)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                        }

                        Text("\(exception.patient.fullName): \(exception.message)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                    }

                    // Dismiss button
                    if onDismiss != nil {
                        Button(action: {
                            withAnimation(.easeOut(duration: AnimationDuration.quick)) {
                                isVisible = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onDismiss?()
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.red.opacity(0.9), Color.red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(CornerRadius.lg)
                .adaptiveShadow(Shadow.prominent)
            }
            .buttonStyle(PlainButtonStyle())
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Critical alert for \(exception.patient.fullName): \(exception.message)")
            .accessibilityHint("Double tap to view details")
        }
    }

    // MARK: - Alert Icon

    private var alertIcon: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 44, height: 44)

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.white)
        }
        .modifier(PulseAnimationModifier())
    }

    private var timeAgoText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: exception.createdAt, relativeTo: Date())
    }
}

// MARK: - Pulse Animation Modifier

private struct PulseAnimationModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Compact Alert Banner

/// A smaller alert banner for inline use
struct CompactAlertBanner: View {
    let title: String
    let message: String
    let severity: PatientException.Severity
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap?()
        }) {
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(severity.color)
                    .frame(width: 8, height: 8)

                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(severity.color.opacity(0.1))
            .cornerRadius(CornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Multiple Alerts Banner

/// Banner showing multiple critical alerts
struct MultipleAlertsBanner: View {
    let exceptions: [PatientException]
    var onViewAll: (() -> Void)?

    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            onViewAll?()
        }) {
            HStack(spacing: Spacing.md) {
                // Icon with count
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(.red)

                    // Count badge
                    Text("\(exceptions.count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .offset(x: 20, y: -20)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(exceptions.count) Critical Alerts")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(summaryText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red.opacity(0.6))
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(exceptions.count) critical alerts requiring attention")
        .accessibilityHint("Double tap to view all alerts")
    }

    private var summaryText: String {
        if exceptions.count == 1 {
            return exceptions.first?.patient.fullName ?? "1 patient needs attention"
        } else if exceptions.count == 2 {
            let names = exceptions.prefix(2).map { $0.patient.firstName }
            return "\(names.joined(separator: " and ")) need attention"
        } else {
            let firstName = exceptions.first?.patient.firstName ?? ""
            return "\(firstName) and \(exceptions.count - 1) others need attention"
        }
    }
}

// MARK: - Dismissible Alert Toast

/// A toast-style alert that can be dismissed
struct AlertToast: View {
    let exception: PatientException
    @Binding var isPresented: Bool
    var onAction: (() -> Void)?

    var body: some View {
        VStack {
            Spacer()

            if isPresented {
                HStack(spacing: Spacing.md) {
                    Image(systemName: exception.exceptionType.icon)
                        .font(.title3)
                        .foregroundColor(exception.severity.color)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(exception.patient.fullName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text(exception.message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button("View") {
                        HapticFeedback.light()
                        onAction?()
                        isPresented = false
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color(.label).opacity(0.2), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
    }
}

// MARK: - Critical Alert Banner

/// Simple banner showing count of critical alerts - used in TherapistIntelligenceView
struct CriticalAlertBanner: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                // Pulsing alert icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                .modifier(PulseAnimationModifier())

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(count) Critical Alert\(count == 1 ? "" : "s")")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Patients need immediate attention")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red.opacity(0.6))
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(count) critical alerts requiring attention")
        .accessibilityHint("Double tap to view coaching dashboard")
    }
}

// MARK: - Patient Alerts Section

/// Section showing active alerts for a specific patient
/// Used in PatientDetailView to show inline alerts
struct PatientAlertsSection: View {
    let patientId: UUID

    @State private var alerts: [CoachingAlert] = []
    @State private var isLoading = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
            } else if !alerts.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(.orange)
                        Text("Active Alerts")
                            .font(.headline)
                        Spacer()
                        Text("\(alerts.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    ForEach(alerts.prefix(3)) { alert in
                        CompactAlertRow(alert: alert)
                    }

                    if alerts.count > 3 {
                        Text("+ \(alerts.count - 3) more alerts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical, Spacing.sm)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.md)
                .padding(.horizontal)
            }
        }
        .task {
            await loadAlerts()
        }
    }

    private func loadAlerts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            alerts = try await CoachingAlertService.shared.fetchPatientAlerts(patientId: patientId.uuidString)
        } catch {
            // Silent fail - section just won't show
        }
    }
}

/// Compact alert row for PatientAlertsSection
private struct CompactAlertRow: View {
    let alert: CoachingAlert

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(alert.severity.color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(alert.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(timeAgo(from: alert.createdAt))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, Spacing.xs)
    }

    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#if DEBUG
struct AlertBannerView_Previews: PreviewProvider {
    static var sampleException: PatientException {
        PatientException(
            id: UUID(),
            patient: Patient(
                id: UUID(),
                therapistId: UUID(),
                firstName: "Mike",
                lastName: "Williams",
                email: "mike@example.com",
                sport: "Football",
                position: "QB",
                injuryType: "Shoulder",
                targetLevel: "Pro",
                profileImageUrl: nil,
                createdAt: Date(),
                flagCount: 2,
                highSeverityFlagCount: 1,
                adherencePercentage: 25.0,
                lastSessionDate: Calendar.current.date(byAdding: .day, value: -15, to: Date())
            ),
            exceptionType: .painSpike,
            severity: .critical,
            message: "Reported severe pain during last session",
            daysSinceLastSession: 15,
            painTrend: .up,
            adherenceTrend: .down,
            currentPain: 9.0,
            currentAdherence: 25.0,
            createdAt: Date().addingTimeInterval(-3600)
        )
    }

    static var previews: some View {
        VStack(spacing: Spacing.lg) {
            AlertBannerView(
                exception: sampleException,
                onTap: { },
                onDismiss: { }
            )

            CompactAlertBanner(
                title: "Pain Alert",
                message: "Mike Williams reported high pain",
                severity: .critical,
                onTap: { }
            )

            MultipleAlertsBanner(
                exceptions: [sampleException, sampleException, sampleException],
                onViewAll: { }
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif
