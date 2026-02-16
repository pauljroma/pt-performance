//
//  AdherenceDashboardView.swift
//  PTPerformance
//
//  Practice-wide adherence overview for therapists.
//  Shows adherence trends, at-risk patients, and intervention tools.
//

import SwiftUI

// MARK: - AdherenceDashboardView

struct AdherenceDashboardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AdherenceDashboardViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPatient: Patient?
    @State private var selectedTimeframe: Timeframe = .week

    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Spacing.lg) {
                    // Practice-wide adherence summary
                    adherenceSummaryCard

                    // Timeframe selector
                    timeframeSelector

                    // Adherence distribution
                    adherenceDistributionCard

                    // Trend chart
                    adherenceTrendCard

                    // At-risk patients section
                    atRiskSection

                    // High performers section
                    highPerformersSection
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Adherence Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { viewModel.exportReport() }) {
                            Label("Export Report", systemImage: "square.and.arrow.up")
                        }
                        Button(action: { viewModel.sendBulkReminders() }) {
                            Label("Send Reminders", systemImage: "bell.badge")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                if let therapistId = appState.userId {
                    await viewModel.loadData(therapistId: therapistId)
                }
            }
            .refreshable {
                if let therapistId = appState.userId {
                    await viewModel.refresh(therapistId: therapistId)
                }
            }
            .navigationDestination(item: $selectedPatient) { patient in
                PatientDetailView(patient: patient)
            }
        }
    }

    // MARK: - Adherence Summary Card

    private var adherenceSummaryCard: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Text("Practice Adherence")
                    .font(.headline)

                Spacer()

                // Trend indicator
                if let trend = viewModel.adherenceTrend {
                    HStack(spacing: 4) {
                        Image(systemName: trend.icon)
                            .font(.caption)
                        Text(trend.text)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(trend.color)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(trend.color.opacity(0.15))
                    .cornerRadius(CornerRadius.xs)
                }
            }

            // Main adherence gauge
            HStack(spacing: Spacing.xl) {
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray4), lineWidth: 12)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: viewModel.averageAdherence / 100)
                        .stroke(
                            adherenceColor(for: viewModel.averageAdherence),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(Int(viewModel.averageAdherence))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("Average")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Stats column
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    statRow(label: "Above 80%", value: "\(viewModel.highAdherenceCount)", color: .green)
                    statRow(label: "50-80%", value: "\(viewModel.mediumAdherenceCount)", color: .yellow)
                    statRow(label: "Below 50%", value: "\(viewModel.lowAdherenceCount)", color: .red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
        .padding(.horizontal)
    }

    private func statRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }

    // MARK: - Timeframe Selector

    private var timeframeSelector: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                Button(action: {
                    HapticFeedback.selectionChanged()
                    withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                        selectedTimeframe = timeframe
                    }
                }) {
                    Text(timeframe.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedTimeframe == timeframe ? .semibold : .regular)
                        .foregroundColor(selectedTimeframe == timeframe ? .white : .primary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(selectedTimeframe == timeframe ? Color.orange : Color(.secondarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Adherence Distribution Card

    private var adherenceDistributionCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Adherence Distribution")
                .font(.subheadline)
                .fontWeight(.semibold)

            // Bar chart
            GeometryReader { geometry in
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(viewModel.distributionBuckets, id: \.range) { bucket in
                        VStack(spacing: 4) {
                            // Bar
                            RoundedRectangle(cornerRadius: 4)
                                .fill(bucket.color)
                                .frame(
                                    width: (geometry.size.width - 40) / CGFloat(viewModel.distributionBuckets.count),
                                    height: max(4, CGFloat(bucket.count) / CGFloat(max(viewModel.maxBucketCount, 1)) * 60)
                                )

                            // Count label
                            if bucket.count > 0 {
                                Text("\(bucket.count)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(height: 80)
            }
            .frame(height: 80)

            // X-axis labels
            HStack {
                Text("0%")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Text("50%")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Text("100%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal)
    }

    // MARK: - Adherence Trend Card

    private var adherenceTrendCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Weekly Trend")
                .font(.subheadline)
                .fontWeight(.semibold)

            // Simple trend line visualization
            GeometryReader { geometry in
                let points = viewModel.weeklyTrendData
                let maxValue = points.map { $0.value }.max() ?? 100
                let minValue = max(0, (points.map { $0.value }.min() ?? 0) - 10)

                Path { path in
                    guard points.count > 1 else { return }

                    let stepX = geometry.size.width / CGFloat(points.count - 1)
                    let range = maxValue - minValue

                    for (index, point) in points.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = geometry.size.height - ((point.value - minValue) / range * geometry.size.height)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                // Data points
                ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                    let stepX = geometry.size.width / CGFloat(points.count - 1)
                    let range = maxValue - minValue
                    let x = CGFloat(index) * stepX
                    let y = geometry.size.height - ((point.value - minValue) / range * geometry.size.height)

                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
            }
            .frame(height: 80)

            // Week labels
            HStack {
                ForEach(viewModel.weeklyTrendData, id: \.label) { point in
                    Text(point.label)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal)
    }

    // MARK: - At-Risk Section

    private var atRiskSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Label {
                    Text("Needs Attention")
                        .font(.headline)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }

                Spacer()

                if viewModel.atRiskPatients.count > 3 {
                    Button("View All") {
                        // Navigate to full list
                    }
                    .font(.subheadline)
                    .foregroundColor(.modusCyan)
                }
            }
            .padding(.horizontal)

            if viewModel.atRiskPatients.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                        Text("All patients meeting goals")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(Spacing.lg)
                    Spacer()
                }
            } else {
                ForEach(viewModel.atRiskPatients.prefix(3)) { patient in
                    AdherencePatientRow(
                        patient: patient,
                        adherence: patient.adherencePercentage ?? 0,
                        trend: .declining,
                        onTap: {
                            selectedPatient = patient
                        },
                        onSendReminder: {
                            viewModel.sendReminder(to: patient)
                        }
                    )
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - High Performers Section

    private var highPerformersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Label {
                    Text("Top Performers")
                        .font(.headline)
                } icon: {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }

                Spacer()
            }
            .padding(.horizontal)

            if viewModel.topPerformers.isEmpty {
                Text("No data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.md) {
                        ForEach(viewModel.topPerformers.prefix(5)) { patient in
                            TopPerformerCard(
                                patient: patient,
                                adherence: patient.adherencePercentage ?? 0
                            ) {
                                selectedPatient = patient
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Helper

    private func adherenceColor(for percentage: Double) -> Color {
        switch percentage {
        case 80...: return .green
        case 50..<80: return .yellow
        default: return .red
        }
    }
}

// MARK: - ViewModel

@MainActor
final class AdherenceDashboardViewModel: ObservableObject {
    @Published var patients: [Patient] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = PTSupabaseClient.shared

    // MARK: - Computed Properties

    var averageAdherence: Double {
        let values = patients.compactMap { $0.adherencePercentage }
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    var adherenceTrend: (icon: String, text: String, color: Color)? {
        // No previous period data available to calculate a real trend
        return nil
    }

    var highAdherenceCount: Int {
        patients.filter { ($0.adherencePercentage ?? 0) >= 80 }.count
    }

    var mediumAdherenceCount: Int {
        patients.filter { adherence in
            let value = adherence.adherencePercentage ?? 0
            return value >= 50 && value < 80
        }.count
    }

    var lowAdherenceCount: Int {
        patients.filter { ($0.adherencePercentage ?? 0) < 50 }.count
    }

    var atRiskPatients: [Patient] {
        patients
            .filter { ($0.adherencePercentage ?? 0) < 60 }
            .sorted { ($0.adherencePercentage ?? 0) < ($1.adherencePercentage ?? 0) }
    }

    var topPerformers: [Patient] {
        patients
            .filter { ($0.adherencePercentage ?? 0) >= 90 }
            .sorted { ($0.adherencePercentage ?? 0) > ($1.adherencePercentage ?? 0) }
    }

    struct DistributionBucket: Identifiable {
        let id = UUID()
        let range: String
        let count: Int
        let color: Color
    }

    var distributionBuckets: [DistributionBucket] {
        let ranges: [(String, ClosedRange<Double>, Color)] = [
            ("0-10", 0...10, .red),
            ("10-20", 10...20, .red),
            ("20-30", 20...30, .red),
            ("30-40", 30...40, .orange),
            ("40-50", 40...50, .orange),
            ("50-60", 50...60, .yellow),
            ("60-70", 60...70, .yellow),
            ("70-80", 70...80, .green.opacity(0.7)),
            ("80-90", 80...90, .green),
            ("90-100", 90...100, .green)
        ]

        return ranges.map { range, bounds, color in
            let count = patients.filter { patient in
                let adherence = patient.adherencePercentage ?? 0
                return bounds.contains(adherence)
            }.count
            return DistributionBucket(range: range, count: count, color: color)
        }
    }

    var maxBucketCount: Int {
        distributionBuckets.map { $0.count }.max() ?? 1
    }

    struct TrendPoint {
        let label: String
        let value: Double
    }

    var weeklyTrendData: [TrendPoint] {
        // Only show the current week's real average; no historical data available
        guard averageAdherence > 0 else { return [] }
        return [
            TrendPoint(label: "This Week", value: averageAdherence)
        ]
    }

    // MARK: - Data Loading

    func loadData(therapistId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await supabase.client
                .from("patients")
                .select()
                .eq("therapist_id", value: therapistId)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            patients = try decoder.decode([Patient].self, from: response.data)

        } catch {
            ErrorLogger.shared.logError(error, context: "AdherenceDashboardViewModel.loadData")
            errorMessage = "Failed to load adherence data."
        }
    }

    func refresh(therapistId: String) async {
        await loadData(therapistId: therapistId)
    }

    // MARK: - Actions

    func sendReminder(to patient: Patient) {
        // In production, send push notification or email
        HapticFeedback.success()
    }

    func sendBulkReminders() {
        // Send reminders to all at-risk patients
        HapticFeedback.success()
    }

    func exportReport() {
        // Export adherence report
        HapticFeedback.success()
    }
}

// MARK: - AdherencePatientRow

struct AdherencePatientRow: View {
    let patient: Patient
    let adherence: Double
    let trend: PatientException.TrendDirection
    var onTap: (() -> Void)?
    var onSendReminder: (() -> Void)?

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(adherenceColor.opacity(0.2))
                    .frame(width: 44, height: 44)

                Text(patient.initials)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(adherenceColor)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(patient.fullName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                // Adherence bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.systemGray4))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(adherenceColor)
                            .frame(width: geometry.size.width * min(adherence / 100, 1.0), height: 6)
                    }
                }
                .frame(height: 6)
            }

            // Adherence percentage
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 2) {
                    Text("\(Int(adherence))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(adherenceColor)

                    Image(systemName: trend.icon)
                        .font(.caption2)
                        .foregroundColor(trend == .declining ? .red : .green)
                }
            }

            // Actions
            Button(action: {
                HapticFeedback.light()
                onSendReminder?()
            }) {
                Image(systemName: "bell.badge.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                HapticFeedback.light()
                onTap?()
            }) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    private var adherenceColor: Color {
        switch adherence {
        case 80...: return .green
        case 50..<80: return .yellow
        default: return .red
        }
    }
}

// MARK: - TopPerformerCard

struct TopPerformerCard: View {
    let patient: Patient
    let adherence: Double
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap?()
        }) {
            VStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.6), Color.green],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Text(patient.initials)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

                Text(patient.firstName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("\(Int(adherence))%")
                    .font(.caption)
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
            }
            .frame(width: 80)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.md)
            .adaptiveShadow(Shadow.subtle)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#if DEBUG
struct AdherenceDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        AdherenceDashboardView()
            .environmentObject(AppState())
    }
}
#endif
