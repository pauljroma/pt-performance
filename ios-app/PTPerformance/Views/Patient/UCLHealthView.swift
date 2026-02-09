//
//  UCLHealthView.swift
//  PTPerformance
//
//  ACP-544: UCL Health Assessment View
//  Weekly check-in for UCL health tracking with trend visualization
//

import SwiftUI
import Charts

// MARK: - UCL Health View

/// Main view for UCL health assessment and tracking
struct UCLHealthView: View {
    @StateObject private var viewModel = UCLHealthViewModel()
    @EnvironmentObject var appState: AppState
    @State private var showCheckIn = false
    @State private var showEducation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if appState.userId != nil {
                        // Current Status Card
                        currentStatusCard

                        // Weekly Check-in Prompt
                        if viewModel.shouldShowCheckInPrompt {
                            checkInPromptCard
                        }

                        // Trend Chart
                        if !viewModel.assessments.isEmpty {
                            trendChartSection
                        }

                        // Recent Assessments
                        if !viewModel.assessments.isEmpty {
                            recentAssessmentsSection
                        }

                        // Educational Content
                        educationSection
                    } else {
                        notSignedInView
                    }
                }
                .padding()
            }
            .navigationTitle("UCL Health")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCheckIn = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showEducation = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $showCheckIn) {
                UCLCheckInSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showEducation) {
                UCLEducationSheet()
            }
            .refreshable {
                if let patientId = appState.userId {
                    await viewModel.loadAssessments(for: patientId)
                }
            }
            .task {
                if let patientId = appState.userId {
                    await viewModel.loadAssessments(for: patientId)
                }
            }
        }
    }

    // MARK: - Current Status Card

    private var currentStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Current Status")
                    .font(.headline)
                Spacer()
                if let trend = viewModel.trendData {
                    HStack(spacing: 4) {
                        Image(systemName: trend.trendDirection.icon)
                        Text(trend.trendDirection.displayName)
                    }
                    .font(.caption)
                    .foregroundColor(trend.trendDirection.color)
                }
            }

            if let latest = viewModel.latestAssessment {
                HStack(spacing: 20) {
                    // Risk Level Indicator
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(latest.riskLevel.color.opacity(0.2))
                                .frame(width: 80, height: 80)

                            Circle()
                                .stroke(latest.riskLevel.color, lineWidth: 4)
                                .frame(width: 80, height: 80)

                            VStack(spacing: 2) {
                                Image(systemName: latest.riskLevel.icon)
                                    .font(.title2)
                                    .foregroundColor(latest.riskLevel.color)
                                Text("\(Int(latest.riskScore))")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                        }

                        Text(latest.riskLevel.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    // Score Breakdown
                    VStack(alignment: .leading, spacing: 8) {
                        ScoreRow(
                            label: "Symptoms",
                            value: latest.symptomScore,
                            maxValue: 100,
                            color: scoreColor(latest.symptomScore)
                        )

                        ScoreRow(
                            label: "Workload",
                            value: latest.workloadScore,
                            maxValue: 100,
                            color: scoreColor(latest.workloadScore)
                        )

                        Text("Last assessed: \(latest.assessmentDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Recommendation
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text(latest.riskLevel.recommendation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(8)
            } else {
                // No assessment yet
                VStack(spacing: 12) {
                    Image(systemName: "clipboard.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)

                    Text("No Assessment Yet")
                        .font(.headline)

                    Text("Complete your first UCL health check-in to start tracking.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        showCheckIn = true
                    } label: {
                        Text("Start Check-In")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Check-in Prompt Card

    private var checkInPromptCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(.orange)
                Text("Weekly Check-In Due")
                    .font(.headline)
                Spacer()
            }

            Text("It's been more than 7 days since your last UCL health assessment. Regular monitoring helps catch issues early.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button {
                showCheckIn = true
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Complete Check-In")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange, lineWidth: 1)
        )
    }

    // MARK: - Trend Chart Section

    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Risk Trend")
                .font(.headline)

            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(viewModel.assessments.prefix(8).reversed()) { assessment in
                        LineMark(
                            x: .value("Date", assessment.assessmentDate),
                            y: .value("Risk Score", assessment.riskScore)
                        )
                        .foregroundStyle(Color.blue)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", assessment.assessmentDate),
                            y: .value("Risk Score", assessment.riskScore)
                        )
                        .foregroundStyle(assessment.riskLevel.color)
                        .symbolSize(60)
                    }

                    // Risk level thresholds
                    RuleMark(y: .value("Moderate", 25))
                        .foregroundStyle(.yellow.opacity(0.5))
                        .lineStyle(StrokeStyle(dash: [5, 5]))

                    RuleMark(y: .value("High", 50))
                        .foregroundStyle(.orange.opacity(0.5))
                        .lineStyle(StrokeStyle(dash: [5, 5]))

                    RuleMark(y: .value("Critical", 75))
                        .foregroundStyle(.red.opacity(0.5))
                        .lineStyle(StrokeStyle(dash: [5, 5]))
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 25, 50, 75, 100])
                }
                .frame(height: 200)
            } else {
                // Fallback for older iOS versions
                LegacyTrendChart(assessments: Array(viewModel.assessments.prefix(8)))
                    .frame(height: 200)
            }

            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .green, label: "Low (<25)")
                LegendItem(color: .yellow, label: "Moderate")
                LegendItem(color: .orange, label: "High")
                LegendItem(color: .red, label: "Critical (>75)")
            }
            .font(.caption2)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Recent Assessments Section

    private var recentAssessmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Assessments")
                .font(.headline)

            ForEach(viewModel.assessments.prefix(5)) { assessment in
                AssessmentRow(assessment: assessment)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Education Section

    private var educationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("UCL Health Tips")
                    .font(.headline)
                Spacer()
                Button("Learn More") {
                    showEducation = true
                }
                .font(.caption)
            }

            // Random prevention tip
            let tip = UCLEducationalContent.preventionStrategies.randomElement() ?? ""
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .padding(.top, 2)

                Text(tip)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Not Signed In View

    private var notSignedInView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Sign In Required")
                .font(.headline)

            Text("Sign in to track your UCL health and monitor risk factors over time.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }

    // MARK: - Helper Functions

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0..<25: return .green
        case 25..<50: return .yellow
        case 50..<75: return .orange
        default: return .red
        }
    }
}

// MARK: - Score Row Component

private struct ScoreRow: View {
    let label: String
    let value: Double
    let maxValue: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(value))")
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.tertiarySystemGroupedBackground))
                        .frame(height: 6)
                        .cornerRadius(3)

                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * (value / maxValue), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Legend Item

private struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Assessment Row

private struct AssessmentRow: View {
    let assessment: UCLHealthAssessment

    var body: some View {
        HStack {
            Circle()
                .fill(assessment.riskLevel.color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(assessment.assessmentDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(assessment.riskLevel.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(Int(assessment.riskScore))")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(assessment.riskLevel.color)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Legacy Trend Chart (iOS 15 fallback)

private struct LegacyTrendChart: View {
    let assessments: [UCLHealthAssessment]

    var body: some View {
        GeometryReader { geometry in
            let sorted = assessments.sorted { $0.assessmentDate < $1.assessmentDate }
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                // Background grid lines
                ForEach([25.0, 50.0, 75.0], id: \.self) { threshold in
                    Path { path in
                        let y = height - (threshold / 100.0 * height)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(dash: [5, 5]))
                }

                // Line path
                if sorted.count > 1 {
                    Path { path in
                        for (index, assessment) in sorted.enumerated() {
                            let x = width * CGFloat(index) / CGFloat(sorted.count - 1)
                            let y = height - (assessment.riskScore / 100.0 * height)

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.blue, lineWidth: 2)
                }

                // Points
                ForEach(Array(sorted.enumerated()), id: \.element.id) { index, assessment in
                    let x = sorted.count > 1 ? width * CGFloat(index) / CGFloat(sorted.count - 1) : width / 2
                    let y = height - (assessment.riskScore / 100.0 * height)

                    Circle()
                        .fill(assessment.riskLevel.color)
                        .frame(width: 10, height: 10)
                        .position(x: x, y: y)
                }
            }
        }
    }
}

// MARK: - UCL Check-In Sheet

struct UCLCheckInSheet: View {
    @ObservedObject var viewModel: UCLHealthViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    // Form state
    @State private var currentStep = 0
    @State private var input = UCLAssessmentInput(
        patientId: "",
        assessmentDate: ""
    )

    // Pain questions
    @State private var medialElbowPain = false
    @State private var medialPainSeverity: Double = 5
    @State private var painDuringThrowing = false
    @State private var painAfterThrowing = false
    @State private var painAtRest = false

    // Valgus stress
    @State private var valgusStressDiscomfort = false
    @State private var elbowInstabilityFelt = false
    @State private var decreasedVelocity = false
    @State private var decreasedControlAccuracy = false

    // Neurological
    @State private var numbnessOrTingling = false
    @State private var ringFingerNumbness = false
    @State private var pinkyFingerNumbness = false

    // Workload
    @State private var totalPitchCount: String = ""
    @State private var highIntensityThrows: String = ""
    @State private var throwingDays: Double = 4
    @State private var longestSession: String = ""

    // Recovery
    @State private var armFatigue: Double = 5
    @State private var recoveryQuality: Double = 3
    @State private var adequateRestDays = true
    @State private var notes = ""

    // State
    @State private var showResult = false
    @State private var calculatedRiskLevel: UCLRiskLevel = .low

    let steps = ["Pain", "Stress", "Neuro", "Workload", "Recovery"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator

                // Content
                TabView(selection: $currentStep) {
                    painQuestionsView.tag(0)
                    valgusStressView.tag(1)
                    neurologicalView.tag(2)
                    workloadView.tag(3)
                    recoveryView.tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)

                // Navigation buttons
                navigationButtons
            }
            .navigationTitle("UCL Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Assessment Complete", isPresented: $showResult) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Your UCL risk level: \(calculatedRiskLevel.displayName)\n\n\(calculatedRiskLevel.recommendation)")
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<steps.count, id: \.self) { index in
                VStack(spacing: 4) {
                    Circle()
                        .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)

                    Text(steps[index])
                        .font(.caption2)
                        .foregroundColor(index <= currentStep ? .primary : .secondary)
                }

                if index < steps.count - 1 {
                    Rectangle()
                        .fill(index < currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
    }

    // MARK: - Pain Questions View

    private var painQuestionsView: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Medial Elbow Pain")
                        .font(.headline)
                    Text("Pain on the inside of your elbow (where the UCL is located)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Toggle("Do you have medial elbow pain?", isOn: $medialElbowPain)

                if medialElbowPain {
                    VStack(alignment: .leading) {
                        Text("Pain Severity: \(Int(medialPainSeverity))/10")
                            .font(.subheadline)
                        Slider(value: $medialPainSeverity, in: 1...10, step: 1)
                    }

                    Toggle("Pain during throwing", isOn: $painDuringThrowing)
                    Toggle("Pain after throwing", isOn: $painAfterThrowing)
                    Toggle("Pain at rest", isOn: $painAtRest)
                }
            }

            Section {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Pain on the medial (inner) side of the elbow during or after throwing is the most common early warning sign of UCL stress.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Valgus Stress View

    private var valgusStressView: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Valgus Stress Indicators")
                        .font(.headline)
                    Text("Signs of UCL stress and elbow stability")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Toggle("Discomfort during valgus stress", isOn: $valgusStressDiscomfort)
                Toggle("Feeling of elbow instability", isOn: $elbowInstabilityFelt)
            }

            Section(header: Text("Performance Changes")) {
                Toggle("Decreased throwing velocity", isOn: $decreasedVelocity)
                Toggle("Decreased control/accuracy", isOn: $decreasedControlAccuracy)
            }

            Section {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Decreased velocity or accuracy can be early signs of UCL fatigue before pain develops.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Neurological View

    private var neurologicalView: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Neurological Symptoms")
                        .font(.headline)
                    Text("Ulnar nerve involvement can indicate UCL issues")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Toggle("Any numbness or tingling in hand/fingers", isOn: $numbnessOrTingling)

                if numbnessOrTingling {
                    Toggle("Ring finger numbness/tingling", isOn: $ringFingerNumbness)
                    Toggle("Pinky finger numbness/tingling", isOn: $pinkyFingerNumbness)
                }
            }

            Section {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("The ulnar nerve runs near the UCL. Numbness in the ring and pinky fingers can indicate nerve irritation from UCL inflammation.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Workload View

    private var workloadView: some View {
        Form {
            Section(header: Text("This Week's Throwing Activity")) {
                VStack(alignment: .leading) {
                    Text("Total Pitch Count")
                    TextField("Number of pitches", text: $totalPitchCount)
                        .keyboardType(.numberPad)
                }

                VStack(alignment: .leading) {
                    Text("High Intensity Throws (>80% effort)")
                    TextField("Number of throws", text: $highIntensityThrows)
                        .keyboardType(.numberPad)
                }

                VStack(alignment: .leading) {
                    Text("Throwing Days: \(Int(throwingDays))")
                    Slider(value: $throwingDays, in: 0...7, step: 1)
                }

                VStack(alignment: .leading) {
                    Text("Longest Single Session (pitches)")
                    TextField("Number of pitches", text: $longestSession)
                        .keyboardType(.numberPad)
                }
            }

            Section {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Pitch count and throwing intensity are major factors in UCL stress. Following guidelines helps prevent injury.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Recovery View

    private var recoveryView: some View {
        Form {
            Section(header: Text("Recovery & Fatigue")) {
                VStack(alignment: .leading) {
                    Text("Arm Fatigue Level: \(Int(armFatigue))/10")
                    Slider(value: $armFatigue, in: 1...10, step: 1)
                    Text("1 = Fresh, 10 = Extremely fatigued")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading) {
                    Text("Recovery Quality: \(Int(recoveryQuality))/5")
                    Slider(value: $recoveryQuality, in: 1...5, step: 1)
                    Text("1 = Poor recovery, 5 = Excellent recovery")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Toggle("Had adequate rest days this week", isOn: $adequateRestDays)
            }

            Section(header: Text("Additional Notes")) {
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
            }

            Section {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Throwing while fatigued significantly increases UCL injury risk. Always prioritize recovery.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button {
                    withAnimation {
                        currentStep -= 1
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if currentStep < steps.count - 1 {
                Button {
                    withAnimation {
                        currentStep += 1
                    }
                } label: {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    submitAssessment()
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Submit")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
            }
        }
        .padding()
    }

    // MARK: - Submit Assessment

    private func submitAssessment() {
        guard let patientId = appState.userId else { return }

        Task {
            // Calculate scores
            let symptomScore = UCLRiskCalculator.calculateSymptomScore(
                medialElbowPain: medialElbowPain,
                medialPainSeverity: medialElbowPain ? Int(medialPainSeverity) : nil,
                painDuringThrowing: painDuringThrowing,
                painAfterThrowing: painAfterThrowing,
                painAtRest: painAtRest,
                valgusStressDiscomfort: valgusStressDiscomfort,
                elbowInstabilityFelt: elbowInstabilityFelt,
                decreasedVelocity: decreasedVelocity,
                decreasedControlAccuracy: decreasedControlAccuracy,
                numbnessOrTingling: numbnessOrTingling,
                ringFingerNumbness: ringFingerNumbness,
                pinkyFingerNumbness: pinkyFingerNumbness
            )

            let workloadScore = UCLRiskCalculator.calculateWorkloadScore(
                totalPitchCount: Int(totalPitchCount),
                highIntensityThrows: Int(highIntensityThrows),
                throwingDays: Int(throwingDays),
                longestSession: Int(longestSession),
                armFatigue: Int(armFatigue),
                recoveryQuality: Int(recoveryQuality),
                adequateRestDays: adequateRestDays
            )

            let riskScore = UCLRiskCalculator.calculateRiskScore(
                symptomScore: symptomScore,
                workloadScore: workloadScore
            )

            calculatedRiskLevel = UCLRiskCalculator.determineRiskLevel(riskScore: riskScore)

            // Build input
            var assessmentInput = UCLAssessmentInput(
                patientId: patientId,
                assessmentDate: ISO8601DateFormatter().string(from: Date())
            )

            assessmentInput.medialElbowPain = medialElbowPain
            assessmentInput.medialPainSeverity = medialElbowPain ? Int(medialPainSeverity) : nil
            assessmentInput.painDuringThrowing = painDuringThrowing
            assessmentInput.painAfterThrowing = painAfterThrowing
            assessmentInput.painAtRest = painAtRest
            assessmentInput.valgusStressDiscomfort = valgusStressDiscomfort
            assessmentInput.elbowInstabilityFelt = elbowInstabilityFelt
            assessmentInput.decreasedVelocity = decreasedVelocity
            assessmentInput.decreasedControlAccuracy = decreasedControlAccuracy
            assessmentInput.numbnessOrTingling = numbnessOrTingling
            assessmentInput.ringFingerNumbness = ringFingerNumbness
            assessmentInput.pinkyFingerNumbness = pinkyFingerNumbness
            assessmentInput.totalPitchCount = Int(totalPitchCount)
            assessmentInput.highIntensityThrows = Int(highIntensityThrows)
            assessmentInput.throwingDays = Int(throwingDays)
            assessmentInput.longestSession = Int(longestSession)
            assessmentInput.armFatigue = Int(armFatigue)
            assessmentInput.recoveryQuality = Int(recoveryQuality)
            assessmentInput.adequateRestDays = adequateRestDays
            assessmentInput.notes = notes.isEmpty ? nil : notes

            await viewModel.submitAssessment(
                input: assessmentInput,
                symptomScore: symptomScore,
                workloadScore: workloadScore,
                riskScore: riskScore,
                riskLevel: calculatedRiskLevel
            )

            if viewModel.errorMessage == nil {
                showResult = true
            }
        }
    }
}

// MARK: - UCL Education Sheet

struct UCLEducationSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Key Facts")) {
                    ForEach(UCLEducationalContent.keyFacts, id: \.self) { fact in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                                .padding(.top, 2)
                            Text(fact)
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(header: Text("Warning Signs")) {
                    ForEach(UCLEducationalContent.warningSigns, id: \.self) { sign in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .padding(.top, 2)
                            Text(sign)
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(header: Text("Prevention Strategies")) {
                    ForEach(UCLEducationalContent.preventionStrategies, id: \.self) { strategy in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "shield.checkered")
                                .foregroundColor(.green)
                                .padding(.top, 2)
                            Text(strategy)
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(header: Text("Pitch Count Guidelines by Age")) {
                    ForEach(UCLEducationalContent.pitchCountGuidelines, id: \.age) { guideline in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Age \(guideline.age)")
                                    .font(.headline)
                                Spacer()
                                Text("Max: \(guideline.maxPitches)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Text("Rest: \(guideline.restDays)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("UCL Education")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - View Model

@MainActor
class UCLHealthViewModel: ObservableObject {
    @Published var assessments: [UCLHealthAssessment] = []
    @Published var trendData: UCLTrendData?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = UCLHealthService.shared

    var latestAssessment: UCLHealthAssessment? {
        assessments.first
    }

    var shouldShowCheckInPrompt: Bool {
        guard let latest = latestAssessment else { return true }
        let daysSinceLastAssessment = Calendar.current.dateComponents(
            [.day],
            from: latest.assessmentDate,
            to: Date()
        ).day ?? 0
        return daysSinceLastAssessment >= 7
    }

    func loadAssessments(for patientId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            assessments = try await service.fetchAssessments(for: patientId, limit: 12)
            trendData = UCLTrendData.calculate(from: assessments)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func submitAssessment(
        input: UCLAssessmentInput,
        symptomScore: Double,
        workloadScore: Double,
        riskScore: Double,
        riskLevel: UCLRiskLevel
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            let assessment = try await service.submitAssessment(
                input: input,
                symptomScore: symptomScore,
                workloadScore: workloadScore,
                riskScore: riskScore,
                riskLevel: riskLevel
            )

            // Prepend to assessments list
            assessments.insert(assessment, at: 0)
            trendData = UCLTrendData.calculate(from: assessments)

            // Check if we need to send an alert
            if riskLevel == .high || riskLevel == .critical {
                await service.sendElevatedRiskAlert(
                    patientId: input.patientId,
                    riskLevel: riskLevel,
                    riskScore: riskScore
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Preview

#if DEBUG
struct UCLHealthView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        appState.userId = "test-patient-id"
        appState.isAuthenticated = true

        return Group {
            UCLHealthView()
                .environmentObject(appState)
                .previewDisplayName("Authenticated")

            UCLHealthView()
                .environmentObject(AppState())
                .previewDisplayName("Not Authenticated")
        }
    }
}
#endif
