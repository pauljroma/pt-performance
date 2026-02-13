//
//  ShoulderHealthDashboard.swift
//  PTPerformance
//
//  ACP-545: Shoulder Health Dashboard
//  Visual dashboard for ROM tracking, strength balance, and trend alerts
//

import SwiftUI
import Charts

/// Main dashboard for shoulder health monitoring
struct ShoulderHealthDashboard: View {
    @StateObject private var viewModel = ShoulderHealthDashboardViewModel()
    @State private var selectedSide: ShoulderSide = .right
    @State private var showROMEntry = false
    @State private var showStrengthEntry = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.healthStatus == nil {
                loadingView
            } else {
                dashboardContent
            }
        }
        .navigationTitle("Shoulder Health")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showROMEntry = true
                    } label: {
                        Label("Log ROM", systemImage: "ruler")
                    }

                    Button {
                        showStrengthEntry = true
                    } label: {
                        Label("Log Strength", systemImage: "dumbbell")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("Add Measurement")
            }
        }
        .task {
            await viewModel.loadDashboard(side: selectedSide)
        }
        .refreshable {
            HapticFeedback.light()
            await viewModel.refresh(side: selectedSide)
        }
        .sheet(isPresented: $showROMEntry) {
            NavigationStack {
                ShoulderROMEntry(side: selectedSide) {
                    Task {
                        await viewModel.refresh(side: selectedSide)
                    }
                }
            }
        }
        .sheet(isPresented: $showStrengthEntry) {
            NavigationStack {
                ShoulderStrengthEntry(side: selectedSide) {
                    Task {
                        await viewModel.refresh(side: selectedSide)
                    }
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }

    // MARK: - Loading View

    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
            Text("Loading shoulder health data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Dashboard Content

    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Side Selector
                sideSelectorSection

                // Visual Shoulder Diagram
                shoulderDiagramSection

                // Active Alerts
                if !viewModel.alerts.isEmpty {
                    alertsSection
                }

                // ROM Measurements
                romSection

                // Strength Balance
                strengthSection

                // Historical Trends
                if viewModel.hasTrendData {
                    trendSection
                }

                // Recommendations
                if let status = viewModel.healthStatus, !status.recommendations.isEmpty {
                    recommendationsSection
                }
            }
            .padding()
        }
    }

    // MARK: - Side Selector

    private var sideSelectorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Side")
                .font(.caption)
                .foregroundColor(.secondary)

            Picker("Side", selection: $selectedSide) {
                ForEach(ShoulderSide.allCases, id: \.self) { side in
                    Text(side.displayName).tag(side)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedSide) { _, newSide in
                Task {
                    await viewModel.loadDashboard(side: newSide)
                }
            }
        }
    }

    // MARK: - Shoulder Diagram

    private var shoulderDiagramSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Shoulder Status")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if let status = viewModel.healthStatus {
                    healthBadge(for: status.overallHealth)
                }
            }

            // Visual shoulder diagram
            ShoulderDiagramView(
                side: selectedSide,
                healthLevel: viewModel.healthStatus?.overallHealth ?? .good,
                romStatus: viewModel.healthStatus?.romStatus,
                strengthStatus: viewModel.healthStatus?.strengthStatus
            )
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    private func healthBadge(for level: HealthLevel) -> some View {
        HStack(spacing: 4) {
            Image(systemName: level.icon)
            Text(level.displayName)
        }
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(level.color)
        .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Alerts Section

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Active Alerts")
                    .font(.headline)
                Spacer()
            }

            ForEach(viewModel.alerts) { alert in
                ShoulderAlertCard(alert: alert)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - ROM Section

    private var romSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Range of Motion")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button {
                    showROMEntry = true
                } label: {
                    Image(systemName: "plus")
                        .font(.caption)
                }
                .accessibilityLabel("Add ROM measurement")
            }

            if let romStatus = viewModel.healthStatus?.romStatus {
                ROMDisplayCard(romStatus: romStatus)
            } else {
                emptyROMState
            }

            // Recent ROM measurements
            if !viewModel.recentROMMeasurements.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Measurements")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ForEach(viewModel.recentROMMeasurements.prefix(3)) { measurement in
                        ROMMeasurementRow(measurement: measurement)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    private var emptyROMState: some View {
        VStack(spacing: 12) {
            Image(systemName: "ruler")
                .font(.title)
                .foregroundColor(.secondary)
            Text("No ROM data yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button("Log First Measurement") {
                showROMEntry = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Strength Section

    private var strengthSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Strength Balance")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button {
                    showStrengthEntry = true
                } label: {
                    Image(systemName: "plus")
                        .font(.caption)
                }
                .accessibilityLabel("Add strength measurement")
            }

            if let strengthStatus = viewModel.healthStatus?.strengthStatus,
               strengthStatus.internalRotationStrength > 0 {
                StrengthBalanceCard(strengthStatus: strengthStatus)
            } else {
                emptyStrengthState
            }

            // Recent strength measurements
            if !viewModel.recentStrengthMeasurements.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Measurements")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ForEach(viewModel.recentStrengthMeasurements.prefix(3)) { measurement in
                        StrengthMeasurementRow(measurement: measurement)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    private var emptyStrengthState: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell")
                .font(.title)
                .foregroundColor(.secondary)
            Text("No strength data yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button("Log First Measurement") {
                showStrengthEntry = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Trend Section

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trends (Last 30 Days)")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            // ROM Trend Chart
            if let romPoints = viewModel.trendData.romTrends[selectedSide], !romPoints.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Arc ROM")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Chart(romPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Degrees", point.value)
                        )
                        .foregroundStyle(Color.blue)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Degrees", point.value)
                        )
                        .foregroundStyle(Color.blue)
                    }
                    .frame(height: 150)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                }
            }

            // Ratio Trend Chart
            if let ratioPoints = viewModel.trendData.ratioTrends[selectedSide], !ratioPoints.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ER:IR Ratio")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Chart {
                        // Target range band
                        RectangleMark(
                            xStart: .value("Start", ratioPoints.first?.date ?? Date()),
                            xEnd: .value("End", ratioPoints.last?.date ?? Date()),
                            yStart: .value("Low", 66),
                            yEnd: .value("High", 75)
                        )
                        .foregroundStyle(Color.green.opacity(0.2))

                        // Data line
                        ForEach(ratioPoints) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Ratio", point.value)
                            )
                            .foregroundStyle(Color.orange)

                            PointMark(
                                x: .value("Date", point.date),
                                y: .value("Ratio", point.value)
                            )
                            .foregroundStyle(point.value >= 66 && point.value <= 75 ? Color.green : Color.orange)
                        }
                    }
                    .frame(height: 150)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }

                    Text("Target: 66-75%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Recommendations")
                    .font(.headline)
            }

            if let status = viewModel.healthStatus {
                ForEach(status.recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(recommendation)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }
}

// MARK: - Supporting Views

/// Visual shoulder diagram showing health status
struct ShoulderDiagramView: View {
    let side: ShoulderSide
    let healthLevel: HealthLevel
    let romStatus: ROMStatus?
    let strengthStatus: StrengthStatus?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background shoulder outline
                shoulderOutline
                    .stroke(healthLevel.color, lineWidth: 3)
                    .frame(width: geometry.size.width * 0.6, height: geometry.size.height * 0.8)

                // ROM arc indicators
                if let rom = romStatus {
                    romArcIndicator(rom: rom, size: geometry.size)
                }

                // Strength indicator
                if let strength = strengthStatus {
                    strengthIndicator(strength: strength, size: geometry.size)
                }

                // Side label
                VStack {
                    Spacer()
                    Text(side.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var shoulderOutline: some Shape {
        Circle()
    }

    private func romArcIndicator(rom: ROMStatus, size: CGSize) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 20) {
                VStack {
                    Text("IR")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(rom.internalRotation))°")
                        .font(.headline)
                        .foregroundColor(rom.deficit?.type == .internalRotation ? .orange : .primary)
                }

                VStack {
                    Text("ER")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(rom.externalRotation))°")
                        .font(.headline)
                }
            }

            Text("Total: \(Int(rom.totalArc))°")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
    }

    private func strengthIndicator(strength: StrengthStatus, size: CGSize) -> some View {
        VStack(spacing: 2) {
            Text("ER:IR")
                .font(.caption2)
                .foregroundColor(.secondary)
            Text("\(Int(strength.erIrRatio))%")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(strength.category.color)
        }
        .padding(6)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
        .offset(y: 50)
    }
}

/// Card showing ROM measurements
struct ROMDisplayCard: View {
    let romStatus: ROMStatus

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 30) {
                // Internal Rotation
                VStack(spacing: 4) {
                    Text("Internal Rotation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(romStatus.internalRotation))°")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(romStatus.deficit?.type == .internalRotation ? .orange : .primary)
                }

                Divider()
                    .frame(height: 40)

                // External Rotation
                VStack(spacing: 4) {
                    Text("External Rotation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(romStatus.externalRotation))°")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Divider()
                    .frame(height: 40)

                // Total Arc
                VStack(spacing: 4) {
                    Text("Total Arc")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(romStatus.totalArc))°")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }

            // Deficit warning if present
            if let deficit = romStatus.deficit {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(deficit.severity.color)
                    Text(deficit.type.displayName)
                        .font(.caption)
                        .foregroundColor(deficit.severity.color)
                    Spacer()
                    Text("-\(Int(deficit.amount))°")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(deficit.severity.color)
                }
                .padding(8)
                .background(deficit.severity.color.opacity(0.1))
                .cornerRadius(CornerRadius.sm)
            }
        }
    }
}

/// Card showing strength balance with ER:IR ratio
struct StrengthBalanceCard: View {
    let strengthStatus: StrengthStatus

    var body: some View {
        VStack(spacing: 16) {
            // Ratio gauge
            ZStack {
                // Background arc
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .rotationEffect(.degrees(180))

                // Target range
                Circle()
                    .trim(from: normalizedPosition(for: 66), to: normalizedPosition(for: 75))
                    .stroke(Color.green.opacity(0.3), lineWidth: 20)
                    .rotationEffect(.degrees(180))

                // Current value
                Circle()
                    .trim(from: 0, to: normalizedPosition(for: strengthStatus.erIrRatio))
                    .stroke(strengthStatus.category.color, lineWidth: 20)
                    .rotationEffect(.degrees(180))

                // Value display
                VStack(spacing: 2) {
                    Text("\(Int(strengthStatus.erIrRatio))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(strengthStatus.category.color)
                    Text("ER:IR Ratio")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 100)

            // Target range indicator
            HStack {
                Text("Target: 66-75%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(strengthStatus.category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(strengthStatus.category.color)
            }

            // Raw values
            HStack(spacing: 30) {
                VStack(spacing: 2) {
                    Text("IR Strength")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(strengthStatus.internalRotationStrength)) lbs")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                VStack(spacing: 2) {
                    Text("ER Strength")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(strengthStatus.externalRotationStrength)) lbs")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
    }

    private func normalizedPosition(for value: Double) -> Double {
        // Map 0-100% to 0-0.5 (half circle)
        return min(max(value / 200, 0), 0.5)
    }
}

/// Alert card for shoulder health alerts
struct ShoulderAlertCard: View {
    let alert: ShoulderAlert

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: alert.type.icon)
                    .foregroundColor(alert.severity.color)
                Text(alert.type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(alert.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(alert.message)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: "lightbulb")
                    .font(.caption2)
                Text(alert.recommendation)
                    .font(.caption)
            }
            .foregroundColor(.blue)
        }
        .padding()
        .background(alert.severity.color.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
    }
}

/// Row displaying a single ROM measurement
struct ROMMeasurementRow: View {
    let measurement: ShoulderROMMeasurement

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(measurement.measuredAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("IR: \(Int(measurement.internalRotation))° | ER: \(Int(measurement.externalRotation))°")
                    .font(.subheadline)
            }
            Spacer()
            Text("Total: \(Int(measurement.totalArc))°")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

/// Row displaying a single strength measurement
struct StrengthMeasurementRow: View {
    let measurement: ShoulderStrengthMeasurement

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(measurement.measuredAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("IR: \(Int(measurement.internalRotationStrength)) | ER: \(Int(measurement.externalRotationStrength)) \(measurement.unit.displayName)")
                    .font(.subheadline)
            }
            Spacer()
            Text("\(Int(measurement.erIrRatio))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(measurement.ratioCategory.color)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ShoulderHealthDashboard()
    }
}
