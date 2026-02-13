// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  OutcomeMeasureView.swift
//  PTPerformance
//
//  Questionnaire interface for patient-reported outcome measures including
//  LEFS, DASH, QuickDASH, and PSFS with live scoring and MCID tracking.
//

import SwiftUI

/// Outcome measure questionnaire view with question-by-question flow
/// Features live score display, progress bar, and previous score comparison
struct OutcomeMeasureView: View {
    // MARK: - Properties

    @StateObject private var viewModel: OutcomeMeasureViewModel
    @Environment(\.dismiss) private var dismiss

    let patientId: UUID
    let therapistId: UUID
    let initialMeasureType: OutcomeMeasureType

    // UI State
    @State private var showingMeasureSelector = false
    @State private var showingSubmitConfirmation = false
    @State private var showingSuccessOverlay = false

    // MARK: - Initialization

    init(patientId: UUID, therapistId: UUID, measureType: OutcomeMeasureType = .LEFS, clinicalAssessmentId: UUID? = nil) {
        self.patientId = patientId
        self.therapistId = therapistId
        self.initialMeasureType = measureType

        _viewModel = StateObject(wrappedValue: {
            let vm = OutcomeMeasureViewModel()
            vm.initialize(patientId: patientId, therapistId: therapistId, measureType: measureType, clinicalAssessmentId: clinicalAssessmentId)
            return vm
        }())
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Progress header
                    progressHeader

                    // Main content
                    if viewModel.questions.isEmpty {
                        emptyQuestionsView
                    } else {
                        questionFlowView
                    }

                    // Score footer
                    scoreFooter
                }

                // Success overlay
                if showingSuccessOverlay {
                    successOverlay
                }
            }
            .navigationTitle(viewModel.selectedMeasureType.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .principal) {
                    Button {
                        showingMeasureSelector = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.selectedMeasureType.rawValue)
                                .font(.headline)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingMeasureSelector) {
                MeasureTypeSelector(selectedType: $viewModel.selectedMeasureType)
            }
            .alert("Submit Assessment", isPresented: $showingSubmitConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Submit") {
                    Task {
                        await viewModel.submitMeasure()
                        if viewModel.errorMessage == nil {
                            showingSuccessOverlay = true
                        }
                    }
                }
            } message: {
                Text("Submit this \(viewModel.selectedMeasureType.rawValue) assessment with a score of \(viewModel.formattedScore)?")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK", role: .cancel) {
                    viewModel.clearMessages()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 12) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * (viewModel.completionProgress / 100), height: 8)
                        .animation(.easeInOut, value: viewModel.completionProgress)
                }
            }
            .frame(height: 8)

            // Progress info
            HStack {
                Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.totalQuestions)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(viewModel.completionProgress))% complete")
                    .font(.caption.weight(.medium))
                    .foregroundColor(progressColor)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var progressColor: Color {
        let progress = viewModel.completionProgress
        if progress >= 100 { return .green }
        if progress >= 50 { return .blue }
        return .orange
    }

    // MARK: - Question Flow View

    private var questionFlowView: some View {
        TabView(selection: $viewModel.currentQuestionIndex) {
            ForEach(Array(viewModel.questions.enumerated()), id: \.offset) { index, question in
                QuestionCard(
                    question: question,
                    questionNumber: index + 1,
                    totalQuestions: viewModel.totalQuestions,
                    onAnswer: { value in
                        viewModel.recordAnswer(questionId: question.id, value: value)
                        // Auto-advance after a brief delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if index < viewModel.questions.count - 1 {
                                withAnimation {
                                    viewModel.nextQuestion()
                                }
                            }
                        }
                    }
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 {
                        withAnimation { viewModel.nextQuestion() }
                    } else if value.translation.width > 50 {
                        withAnimation { viewModel.previousQuestion() }
                    }
                }
        )
    }

    // MARK: - Score Footer

    private var scoreFooter: some View {
        VStack(spacing: 16) {
            // Live score display
            HStack(spacing: 20) {
                // Current score
                VStack(spacing: 4) {
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.formattedScore)
                        .font(.title.weight(.bold))
                        .foregroundColor(viewModel.scoreColor)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                // Previous score comparison
                if let previousScore = viewModel.previousScore {
                    VStack(spacing: 4) {
                        Text("Previous")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", previousScore))
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                        .frame(height: 40)
                }

                // Change indicator
                VStack(spacing: 4) {
                    Text("Change")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let change = viewModel.formattedChange {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.progressStatus.iconName)
                            Text(change)
                        }
                        .font(.title2.weight(.semibold))
                        .foregroundColor(viewModel.progressStatus.color)
                    } else {
                        Text("--")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )

            // Interpretation
            if !viewModel.interpretation.isEmpty {
                Text(viewModel.interpretation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // MCID indicator
            if viewModel.meetsMcid {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("Clinically Meaningful Improvement Achieved!")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.green)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(0.1))
                )
            }

            // Navigation and submit buttons
            HStack(spacing: 12) {
                // Previous button
                Button {
                    withAnimation { viewModel.previousQuestion() }
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 50, height: 50)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.xl)
                }
                .disabled(viewModel.currentQuestionIndex == 0)

                // Submit button
                Button {
                    showingSubmitConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Submit")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canSubmit ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.md)
                }
                .disabled(!viewModel.canSubmit)

                // Next button
                Button {
                    withAnimation { viewModel.nextQuestion() }
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 50, height: 50)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.xl)
                }
                .disabled(viewModel.currentQuestionIndex >= viewModel.questions.count - 1)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Empty Questions View

    private var emptyQuestionsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Questions Available")
                .font(.headline)

            Text("This outcome measure is not yet configured.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color(.label).opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Animated checkmark
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                }
                .scaleEffect(showingSuccessOverlay ? 1.0 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showingSuccessOverlay)

                Text("Assessment Submitted!")
                    .font(.title2.weight(.semibold))

                VStack(spacing: 8) {
                    Text(viewModel.selectedMeasureType.displayName)
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Score: \(viewModel.formattedScore)")
                        .font(.title.weight(.bold))
                        .foregroundColor(viewModel.scoreColor)

                    if viewModel.meetsMcid {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("MCID Achieved")
                            Image(systemName: "star.fill")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.yellow)
                    }
                }

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
            )
            .padding(32)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                dismiss()
            }
        }
    }
}

// MARK: - Question Card

private struct QuestionCard: View {
    let question: QuestionItem
    let questionNumber: Int
    let totalQuestions: Int
    let onAnswer: (Int) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Question text
                VStack(spacing: 12) {
                    Text("Q\(questionNumber)")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.blue.opacity(0.2)))
                        .foregroundColor(.blue)

                    Text(question.text)
                        .font(.title3.weight(.medium))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Answer options
                VStack(spacing: 12) {
                    ForEach(question.options) { option in
                        AnswerOptionButton(
                            label: option.label,
                            isSelected: question.selectedValue == option.value,
                            action: { onAnswer(option.value) }
                        )
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.vertical, 24)
        }
    }
}

// MARK: - Answer Option Button

private struct AnswerOptionButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Measure Type Selector

private struct MeasureTypeSelector: View {
    @Binding var selectedType: OutcomeMeasureType
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Upper Extremity") {
                    ForEach(OutcomeMeasureType.allCases.filter { $0.bodyRegion == "Upper Extremity" }) { type in
                        MeasureTypeRow(type: type, isSelected: selectedType == type) {
                            selectedType = type
                            dismiss()
                        }
                    }
                }

                Section("Lower Extremity") {
                    ForEach(OutcomeMeasureType.allCases.filter { $0.bodyRegion == "Lower Extremity" }) { type in
                        MeasureTypeRow(type: type, isSelected: selectedType == type) {
                            selectedType = type
                            dismiss()
                        }
                    }
                }

                Section("Spine") {
                    ForEach(OutcomeMeasureType.allCases.filter { $0.bodyRegion == "Cervical Spine" || $0.bodyRegion == "Lumbar Spine" }) { type in
                        MeasureTypeRow(type: type, isSelected: selectedType == type) {
                            selectedType = type
                            dismiss()
                        }
                    }
                }

                Section("General") {
                    ForEach(OutcomeMeasureType.allCases.filter { $0.bodyRegion == "General" }) { type in
                        MeasureTypeRow(type: type, isSelected: selectedType == type) {
                            selectedType = type
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Select Measure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

private struct MeasureTypeRow: View {
    let type: OutcomeMeasureType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(type.rawValue)
                            .font(.headline)
                        Text("-")
                        Text("\(type.questionCount) questions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Question Dot Indicator

private struct QuestionDotIndicator: View {
    let currentIndex: Int
    let totalCount: Int
    let answeredQuestions: Set<Int>
    let onTap: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<totalCount, id: \.self) { index in
                    Button {
                        onTap(index)
                    } label: {
                        Circle()
                            .fill(dotColor(for: index))
                            .frame(width: index == currentIndex ? 12 : 8, height: index == currentIndex ? 12 : 8)
                            .animation(.easeInOut, value: currentIndex)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func dotColor(for index: Int) -> Color {
        if index == currentIndex {
            return .blue
        } else if answeredQuestions.contains(index) {
            return .green
        } else {
            return .gray.opacity(0.3)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct OutcomeMeasureView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OutcomeMeasureView(
                patientId: UUID(),
                therapistId: UUID(),
                measureType: .LEFS
            )
            .previewDisplayName("LEFS")

            OutcomeMeasureView(
                patientId: UUID(),
                therapistId: UUID(),
                measureType: .QuickDASH
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("QuickDASH - Dark")

            OutcomeMeasureView(
                patientId: UUID(),
                therapistId: UUID(),
                measureType: .PSFS
            )
            .previewDisplayName("PSFS")
        }
    }
}
#endif
