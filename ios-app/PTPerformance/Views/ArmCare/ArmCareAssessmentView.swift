import SwiftUI

/// ACP-522: Arm Care Daily Assessment View
/// 30-second shoulder/elbow check with visual body diagram and traffic light system
///
/// Features:
/// - Quick slider-based questions (under 30 seconds to complete)
/// - Visual body diagram for pain location selection
/// - Instant traffic light result display
/// - Workout modification recommendations
struct ArmCareAssessmentView: View {
    // MARK: - Properties

    @StateObject private var viewModel: ArmCareAssessmentViewModel
    @Environment(\.dismiss) private var dismiss

    // Shoulder metrics (0-10, higher is better)
    @State private var shoulderPainScore: Double = 10
    @State private var shoulderStiffnessScore: Double = 10
    @State private var shoulderStrengthScore: Double = 10

    // Elbow metrics (0-10, higher is better)
    @State private var elbowPainScore: Double = 10
    @State private var elbowTightnessScore: Double = 10
    @State private var valgusStressScore: Double = 10

    // Pain locations
    @State private var selectedPainLocations: Set<ArmPainLocation> = []

    // Notes
    @State private var notes: String = ""

    // UI state
    @State private var showingSuccessAnimation = false
    @State private var currentSection: AssessmentSection = .shoulder

    // MARK: - Initialization

    init(patientId: UUID) {
        _viewModel = StateObject(wrappedValue: ArmCareAssessmentViewModel(patientId: patientId))
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Progress indicator
                        progressIndicator

                        // Quick intro
                        introCard

                        // Body diagram for pain location
                        bodyDiagramSection

                        // Shoulder section
                        shoulderSection

                        // Elbow section
                        elbowSection

                        // Live traffic light preview
                        trafficLightPreview

                        // Notes section
                        notesSection

                        // Submit button
                        submitButton
                    }
                    .padding()
                }

                // Success overlay
                if viewModel.showSuccess {
                    successOverlay
                }
            }
            .navigationTitle("Arm Care Check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .disabled(viewModel.isLoading)
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .task {
                await viewModel.loadTodayAssessment()
            }
            .onChange(of: shoulderPainScore) { _, _ in updatePreview() }
            .onChange(of: shoulderStiffnessScore) { _, _ in updatePreview() }
            .onChange(of: shoulderStrengthScore) { _, _ in updatePreview() }
            .onChange(of: elbowPainScore) { _, _ in updatePreview() }
            .onChange(of: elbowTightnessScore) { _, _ in updatePreview() }
            .onChange(of: valgusStressScore) { _, _ in updatePreview() }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Quick Check")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("~30 seconds")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(viewModel.currentTrafficLight.color)
                        .frame(width: geometry.size.width * progressPercentage, height: 4)
                        .animation(.easeInOut, value: progressPercentage)
                }
            }
            .frame(height: 4)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Assessment progress")
            .accessibilityValue("\(Int(progressPercentage * 100)) percent complete")
        }
    }

    private var progressPercentage: Double {
        var filled = 0.0

        // Each section contributes to progress
        if shoulderPainScore < 10 { filled += 0.15 }
        if shoulderStiffnessScore < 10 { filled += 0.15 }
        if shoulderStrengthScore < 10 { filled += 0.1 }
        if elbowPainScore < 10 { filled += 0.15 }
        if elbowTightnessScore < 10 { filled += 0.15 }
        if valgusStressScore < 10 { filled += 0.1 }
        if !selectedPainLocations.isEmpty { filled += 0.1 }

        return min(filled + 0.1, 1.0) // Start at 10% for just opening
    }

    // MARK: - Intro Card

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "figure.baseball")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("How's Your Arm Today?")
                    .font(.headline)
            }

            Text("Rate each area on a scale of 0-10, where 10 means no issues at all.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }

    // MARK: - Body Diagram Section

    private var bodyDiagramSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tap to mark pain locations")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                // Shoulder diagram
                VStack(spacing: 8) {
                    Text("Shoulder")
                        .font(.caption.weight(.medium))

                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 100, height: 100)

                        // Pain location buttons
                        ForEach(ArmPainLocation.allCases.filter { $0.isShoulder }) { location in
                            painLocationButton(for: location)
                        }
                    }
                }

                // Elbow diagram
                VStack(spacing: 8) {
                    Text("Elbow")
                        .font(.caption.weight(.medium))

                    ZStack {
                        Capsule()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 60, height: 100)

                        // Pain location buttons
                        ForEach(ArmPainLocation.allCases.filter { $0.isElbow }) { location in
                            painLocationButton(for: location)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // Selected locations display
            if !selectedPainLocations.isEmpty {
                ArmCareFlowLayout(spacing: 8) {
                    ForEach(Array(selectedPainLocations), id: \.self) { location in
                        HStack(spacing: 4) {
                            Text(location.displayName)
                                .font(.caption)
                            Button {
                                selectedPainLocations.remove(location)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.2))
                        )
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }

    private func painLocationButton(for location: ArmPainLocation) -> some View {
        let isSelected = selectedPainLocations.contains(location)
        let offset = painLocationOffset(for: location)

        return Button {
            if isSelected {
                selectedPainLocations.remove(location)
            } else {
                selectedPainLocations.insert(location)
            }
            HapticFeedback.light()
        } label: {
            Circle()
                .fill(isSelected ? Color.red : Color.gray.opacity(0.3))
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.red : Color.clear, lineWidth: 2)
                )
        }
        .offset(x: offset.x, y: offset.y)
        .accessibilityLabel(location.displayName)
        .accessibilityHint(isSelected ? "Double tap to remove pain location" : "Double tap to mark as pain location")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func painLocationOffset(for location: ArmPainLocation) -> CGPoint {
        switch location {
        case .anteriorShoulder: return CGPoint(x: 0, y: -20)
        case .posteriorShoulder: return CGPoint(x: 0, y: 20)
        case .lateralShoulder: return CGPoint(x: 30, y: 0)
        case .rotatorCuff: return CGPoint(x: -30, y: 0)
        case .medialElbow: return CGPoint(x: -15, y: 0)
        case .lateralElbow: return CGPoint(x: 15, y: 0)
        case .posteriorElbow: return CGPoint(x: 0, y: 25)
        case .forearm: return CGPoint(x: 0, y: -25)
        }
    }

    // MARK: - Shoulder Section

    private var shoulderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.arms.open")
                    .foregroundColor(.blue)
                Text("Shoulder")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.0f/10", averageShoulderScore))
                    .font(.subheadline)
                    .foregroundColor(scoreColor(for: averageShoulderScore))
            }

            metricSlider(
                title: "Pain Level",
                subtitle: "10 = no pain, 0 = severe pain",
                value: $shoulderPainScore,
                icon: "bolt.slash.fill"
            )

            metricSlider(
                title: "Stiffness",
                subtitle: "10 = no stiffness, 0 = very stiff",
                value: $shoulderStiffnessScore,
                icon: "arrow.left.arrow.right"
            )

            metricSlider(
                title: "Strength",
                subtitle: "10 = full strength, 0 = very weak",
                value: $shoulderStrengthScore,
                icon: "bolt.fill"
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }

    // MARK: - Elbow Section

    private var elbowSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "hand.raised.fill")
                    .foregroundColor(.orange)
                Text("Elbow")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.0f/10", averageElbowScore))
                    .font(.subheadline)
                    .foregroundColor(scoreColor(for: averageElbowScore))
            }

            metricSlider(
                title: "Pain Level",
                subtitle: "10 = no pain, 0 = severe pain",
                value: $elbowPainScore,
                icon: "bolt.slash.fill"
            )

            metricSlider(
                title: "Tightness",
                subtitle: "10 = no tightness, 0 = very tight",
                value: $elbowTightnessScore,
                icon: "arrow.up.and.down.and.arrow.left.and.right"
            )

            metricSlider(
                title: "Valgus Stress",
                subtitle: "10 = no discomfort, 0 = significant discomfort",
                value: $valgusStressScore,
                icon: "arrow.left.and.right.righttriangle.left.righttriangle.right.fill"
            )

            // UCL concern indicator
            if valgusStressScore < 6 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Consider checking with your therapist about UCL stress")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }

    // MARK: - Metric Slider

    private func metricSlider(title: String, subtitle: String, value: Binding<Double>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.0f", value.wrappedValue))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(scoreColor(for: value.wrappedValue))
            }

            Slider(value: value, in: 0...10, step: 1) {
                Text(title)
            } minimumValueLabel: {
                Text("0")
                    .font(.caption2)
                    .foregroundColor(.red)
            } maximumValueLabel: {
                Text("10")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
            .tint(scoreColor(for: value.wrappedValue))
            .onChange(of: value.wrappedValue) { _, _ in
                HapticFeedback.light()
            }
            .accessibilityLabel(title)
            .accessibilityValue("\(Int(value.wrappedValue)) out of 10")
            .accessibilityHint(subtitle)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Traffic Light Preview

    private var trafficLightPreview: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Arm Status")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 20) {
                // Traffic light indicator
                ZStack {
                    Circle()
                        .fill(viewModel.currentTrafficLight.color)
                        .frame(width: 80, height: 80)
                        .shadow(color: viewModel.currentTrafficLight.color.opacity(0.5), radius: 10, x: 0, y: 4)

                    Image(systemName: viewModel.currentTrafficLight.iconName)
                        .font(.title)
                        .foregroundColor(.white)
                }
                .animation(.spring(), value: viewModel.currentTrafficLight)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Arm status: \(viewModel.currentTrafficLight.displayName)")

                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.currentTrafficLight.displayName)
                        .font(.title3.weight(.bold))
                        .foregroundColor(viewModel.currentTrafficLight.color)

                    Text(viewModel.currentTrafficLight.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            // Workout modification summary
            VStack(alignment: .leading, spacing: 8) {
                Divider()

                HStack {
                    Label(
                        throwingVolumeText,
                        systemImage: "baseball"
                    )
                    .font(.subheadline)
                    .foregroundColor(viewModel.currentTrafficLight == .red ? .red : .primary)

                    Spacer()
                }

                if viewModel.currentTrafficLight.requiresExtraArmCare {
                    Label(
                        "Extra arm care recommended",
                        systemImage: "plus.circle.fill"
                    )
                    .font(.subheadline)
                    .foregroundColor(.orange)
                }

                if viewModel.currentTrafficLight.requiresRecoveryProtocol {
                    Label(
                        "Recovery protocol required",
                        systemImage: "bed.double.fill"
                    )
                    .font(.subheadline)
                    .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.currentTrafficLight.color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(viewModel.currentTrafficLight.color.opacity(0.3), lineWidth: 2)
        )
    }

    private var throwingVolumeText: String {
        switch viewModel.currentTrafficLight {
        case .green:
            return "Full throwing volume OK"
        case .yellow:
            return "Reduce throwing volume 50%"
        case .red:
            return "No throwing today"
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Additional Notes (optional)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            TextField("Any other concerns...", text: $notes, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
        }
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            Task {
                await submitAssessment()
            }
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Image(systemName: viewModel.hasSubmittedToday ? "arrow.clockwise" : "checkmark.circle.fill")
                    Text(viewModel.hasSubmittedToday ? "Update Assessment" : "Submit Assessment")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.currentTrafficLight.color)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(viewModel.isLoading)
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: viewModel.currentTrafficLight.iconName)
                    .font(.system(size: 60))
                    .foregroundColor(viewModel.currentTrafficLight.color)
                    .scaleEffect(showingSuccessAnimation ? 1.0 : 0.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showingSuccessAnimation)

                Text("Assessment Complete!")
                    .font(.title2.weight(.semibold))

                Text(viewModel.currentTrafficLight.displayName)
                    .font(.headline)
                    .foregroundColor(viewModel.currentTrafficLight.color)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 20)
            )
            .onAppear {
                showingSuccessAnimation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
        .transition(.opacity)
    }

    // MARK: - Helper Methods

    private var averageShoulderScore: Double {
        (shoulderPainScore + shoulderStiffnessScore + shoulderStrengthScore) / 3.0
    }

    private var averageElbowScore: Double {
        (elbowPainScore + elbowTightnessScore + valgusStressScore) / 3.0
    }

    private func scoreColor(for score: Double) -> Color {
        if score >= 8 {
            return .green
        } else if score >= 5 {
            return .yellow
        } else {
            return .red
        }
    }

    private func updatePreview() {
        viewModel.updatePreview(
            shoulderPainScore: Int(shoulderPainScore),
            shoulderStiffnessScore: Int(shoulderStiffnessScore),
            shoulderStrengthScore: Int(shoulderStrengthScore),
            elbowPainScore: Int(elbowPainScore),
            elbowTightnessScore: Int(elbowTightnessScore),
            valgusStressScore: Int(valgusStressScore)
        )
    }

    private func submitAssessment() async {
        await viewModel.submitAssessment(
            shoulderPainScore: Int(shoulderPainScore),
            shoulderStiffnessScore: Int(shoulderStiffnessScore),
            shoulderStrengthScore: Int(shoulderStrengthScore),
            elbowPainScore: Int(elbowPainScore),
            elbowTightnessScore: Int(elbowTightnessScore),
            valgusStressScore: Int(valgusStressScore),
            painLocations: Array(selectedPainLocations),
            notes: notes.isEmpty ? nil : notes
        )
    }
}

// MARK: - Assessment Section Enum

private enum AssessmentSection {
    case shoulder
    case elbow
}

// MARK: - Flow Layout for Tags

private struct ArmCareFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > containerWidth {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return CGSize(width: containerWidth, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ArmCareAssessmentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ArmCareAssessmentView(patientId: UUID())
                .previewDisplayName("Default")

            ArmCareAssessmentView(patientId: UUID())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
#endif
