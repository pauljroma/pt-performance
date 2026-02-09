import SwiftUI

/// Daily Readiness Check-in UI
/// Collects sleep, readiness, and pain data to calculate workout modifications
/// Part of the Auto-Regulation System (Build 39 - Phase 3)
///
/// BUILD 116 - Migrated form state to ViewModel for better testability
/// Form inputs now managed by DailyReadinessViewModel
struct DailyReadinessCheckInView: View {
    @StateObject private var viewModel = DailyReadinessViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Sleep Section
                Section(header: Text("Sleep")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Hours slept")
                            Spacer()
                            Text(viewModel.sleepHoursLabel)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $viewModel.sleepHours, in: 3...12, step: 0.5)
                            .onChange(of: viewModel.sleepHours) { _, _ in
                                viewModel.updatePreviewFromInputs()
                            }
                    }

                    Picker("Sleep Quality", selection: $viewModel.sleepQuality) {
                        Text("Very Poor (1)").tag(1)
                        Text("Poor (2)").tag(2)
                        Text("Fair (3)").tag(3)
                        Text("Good (4)").tag(4)
                        Text("Excellent (5)").tag(5)
                    }
                    .onChange(of: viewModel.sleepQuality) { _, _ in
                        viewModel.updatePreviewFromInputs()
                    }
                }

                // MARK: - Subjective Readiness Section
                Section(header: Text("How do you feel?")) {
                    Picker("Readiness Level", selection: $viewModel.subjectiveReadiness) {
                        Text("Very Low (1)").tag(1)
                        Text("Low (2)").tag(2)
                        Text("Moderate (3)").tag(3)
                        Text("Good (4)").tag(4)
                        Text("Excellent (5)").tag(5)
                    }
                    .onChange(of: viewModel.subjectiveReadiness) { _, _ in
                        viewModel.updatePreviewFromInputs()
                    }
                }

                // MARK: - Soreness & Pain Section
                Section(header: Text("Soreness & Pain")) {
                    // Arm Soreness Toggle
                    Toggle("Arm Soreness", isOn: $viewModel.armSoreness)
                        .onChange(of: viewModel.armSoreness) { _, _ in
                            viewModel.updatePreviewFromInputs()
                        }

                    // Arm Soreness Severity Picker (conditional)
                    if viewModel.armSoreness {
                        Picker("Arm Soreness Severity", selection: $viewModel.armSorenessSeverity) {
                            Text("Mild (1)").tag(1)
                            Text("Moderate (2)").tag(2)
                            Text("Severe (3)").tag(3)
                        }
                        .onChange(of: viewModel.armSorenessSeverity) { _, _ in
                            viewModel.updatePreviewFromInputs()
                        }
                    }

                    // Joint Pain Toggles
                    ForEach(JointPainLocation.allCases, id: \.self) { joint in
                        Toggle(joint.displayName, isOn: Binding(
                            get: { viewModel.jointPain.contains(joint) },
                            set: { _ in
                                viewModel.toggleJointPain(joint)
                            }
                        ))
                    }

                    // Pain Notes TextField
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pain Notes (optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Describe any pain or discomfort...", text: $viewModel.painNotes, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }

                // MARK: - Live Readiness Preview Section
                if let preview = viewModel.readinessPreview {
                    Section(header: Text("Today's Readiness")) {
                        HStack(spacing: 16) {
                            // Color indicator circle
                            Circle()
                                .fill(preview.band.color)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 2)
                                )

                            // Band information
                            VStack(alignment: .leading, spacing: 4) {
                                Text(preview.band.displayName)
                                    .font(.headline)
                                    .fontWeight(.bold)

                                Text(preview.band.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)

                        // Readiness Score
                        if let score = preview.score {
                            HStack {
                                Text("Readiness Score")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(score))/100")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(viewModel.scoreColor(score))
                            }
                        }

                        // Workout Modification Details
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Workout Modifications")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if preview.band.loadAdjustment < 0 {
                                Label(
                                    "Load: \(Int(abs(preview.band.loadAdjustment) * 100))% reduction",
                                    systemImage: "arrow.down.circle"
                                )
                                .font(.caption)
                                .foregroundColor(.orange)
                            } else {
                                Label("Load: No adjustment", systemImage: "checkmark.circle")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }

                            if preview.band.volumeAdjustment < 0 {
                                Label(
                                    "Volume: \(Int(abs(preview.band.volumeAdjustment) * 100))% reduction",
                                    systemImage: "arrow.down.circle"
                                )
                                .font(.caption)
                                .foregroundColor(.orange)
                            } else {
                                Label("Volume: No adjustment", systemImage: "checkmark.circle")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }

                            if preview.band == .orange || preview.band == .red {
                                Label("Skip top set", systemImage: "exclamationmark.triangle")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }

                            if preview.band == .red {
                                Label("Technique work only", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Daily Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.submitReadinessFromForm()
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!viewModel.canSubmit)
                }
            }
            .onAppear {
                // Initialize preview on appear
                viewModel.updatePreviewFromInputs()

                // Fetch today's check-in if it exists
                Task {
                    await viewModel.fetchTodayReadiness()
                }
            }
            .alert("Check-in Saved", isPresented: $viewModel.showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your daily readiness check-in has been saved successfully!")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }

}

// MARK: - Preview

#if DEBUG
struct DailyReadinessCheckInView_Previews: PreviewProvider {
    static var previews: some View {
        DailyReadinessCheckInView()
    }
}
#endif
