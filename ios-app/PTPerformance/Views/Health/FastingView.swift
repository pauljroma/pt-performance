import SwiftUI

struct FastingView: View {
    @StateObject private var viewModel = FastingViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.stats == nil {
                    loadingView
                } else {
                    contentView
                }
            }
            .navigationTitle("Fasting")
            .sheet(isPresented: $viewModel.showingStartSheet) {
                StartFastSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingEndSheet) {
                EndFastSheet(viewModel: viewModel)
            }
            .task {
                await viewModel.loadData()
                await viewModel.generateRecommendation(trainingTime: nil)
            }
            .refreshable {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading fasting data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Extended Fast Warning Banner (16h+)
                if viewModel.isExtendedFast {
                    extendedFastWarningBanner
                }

                // Current Fast Status
                if viewModel.isFasting {
                    activeFastCard
                } else {
                    startFastCard
                }

                // Today's Training Section
                if let workoutRec = viewModel.workoutRecommendation {
                    todaysTrainingSection(workoutRec)
                }

                // Nutrition Timing Section
                if let workoutRec = viewModel.workoutRecommendation, viewModel.isFasting {
                    nutritionTimingSection(workoutRec)
                }

                // Stats
                if let stats = viewModel.stats {
                    statsSection(stats)
                }

                // Eating Window Recommendation
                if let recommendation = viewModel.recommendation {
                    recommendationCard(recommendation)
                }

                // History
                if !viewModel.history.isEmpty {
                    historySection
                } else if !viewModel.isLoading {
                    emptyHistoryView
                }
            }
            .padding()
        }
    }

    // MARK: - Extended Fast Warning Banner

    private var extendedFastWarningBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 4) {
                Text("Extended Fast Active")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("You've been fasting for \(String(format: "%.1f", viewModel.elapsedHours)) hours. Exercise caution when training.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.orange, .red.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Extended fast warning: You've been fasting for \(String(format: "%.1f", viewModel.elapsedHours)) hours. Exercise caution when training.")
    }

    // MARK: - Today's Training Section

    private func todaysTrainingSection(_ recommendation: FastingWorkoutRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.run")
                    .foregroundColor(.modusCyan)
                Text("Today's Training")
                    .font(.headline)
                Spacer()
                NavigationLink {
                    FastingWorkoutRecommendationDetailView(recommendation: recommendation)
                } label: {
                    Text("Details")
                        .font(.subheadline)
                        .foregroundColor(.modusCyan)
                }
            }

            // Intensity Gauge
            HStack(spacing: 20) {
                // Circular gauge
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: CGFloat(recommendation.intensityModifier))
                        .stroke(
                            intensityGradient(for: recommendation.intensityPercentage),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.6), value: recommendation.intensityModifier)

                    VStack(spacing: 0) {
                        Text("\(recommendation.intensityPercentage)%")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(intensityColor(for: recommendation.intensityPercentage))
                    }
                }
                .accessibilityLabel("Training intensity: \(recommendation.intensityPercentage) percent")

                VStack(alignment: .leading, spacing: 6) {
                    Text(intensityMessage(for: recommendation))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if recommendation.workoutRecommended {
                        Label("Workout Recommended", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.modusTealAccent)
                    } else {
                        Label("Consider Resting", systemImage: "moon.zzz.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }

                    if !recommendation.safetyWarnings.isEmpty {
                        Label("\(recommendation.safetyWarnings.count) warning\(recommendation.safetyWarnings.count == 1 ? "" : "s")", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Spacer()
            }

            // Recommended workout types
            VStack(alignment: .leading, spacing: 8) {
                Text("Recommended Activities")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recommendation.recommendedWorkoutTypes, id: \.self) { type in
                            workoutTypeChip(type)
                        }
                    }
                }
            }

            // Quick warnings preview (first 2)
            if !recommendation.safetyWarnings.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(recommendation.safetyWarnings.prefix(2), id: \.self) { warning in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text(warning)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if recommendation.safetyWarnings.count > 2 {
                        Text("+\(recommendation.safetyWarnings.count - 2) more warnings")
                            .font(.caption)
                            .foregroundColor(.modusCyan)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private func intensityGradient(for percentage: Int) -> LinearGradient {
        if percentage >= 90 {
            return LinearGradient(colors: [.modusTealAccent, .modusCyan], startPoint: .leading, endPoint: .trailing)
        } else if percentage >= 75 {
            return LinearGradient(colors: [.modusCyan, .blue], startPoint: .leading, endPoint: .trailing)
        } else if percentage >= 60 {
            return LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
        } else {
            return LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
        }
    }

    private func intensityColor(for percentage: Int) -> Color {
        if percentage >= 90 {
            return .modusTealAccent
        } else if percentage >= 75 {
            return .modusCyan
        } else if percentage >= 60 {
            return .orange
        } else {
            return .red
        }
    }

    private func intensityMessage(for recommendation: FastingWorkoutRecommendation) -> String {
        let percentage = recommendation.intensityPercentage
        if percentage >= 90 {
            return "Train at full capacity"
        } else if percentage >= 75 {
            return "Train at \(percentage)% today"
        } else if percentage >= 60 {
            return "Light activity recommended"
        } else {
            return "Rest or gentle movement only"
        }
    }

    private func workoutTypeChip(_ type: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: iconForWorkoutType(type))
                .font(.caption2)
            Text(type)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.modusCyan.opacity(0.15))
        .foregroundColor(.modusCyan)
        .cornerRadius(16)
    }

    private func iconForWorkoutType(_ type: String) -> String {
        let lowercased = type.lowercased()
        if lowercased.contains("strength") {
            return "dumbbell.fill"
        } else if lowercased.contains("hiit") {
            return "bolt.fill"
        } else if lowercased.contains("cardio") {
            return "heart.fill"
        } else if lowercased.contains("walking") {
            return "figure.walk"
        } else if lowercased.contains("yoga") {
            return "figure.yoga"
        } else if lowercased.contains("mobility") || lowercased.contains("stretching") {
            return "figure.flexibility"
        } else if lowercased.contains("all") {
            return "star.fill"
        } else {
            return "checkmark.circle.fill"
        }
    }

    // MARK: - Nutrition Timing Section

    private func nutritionTimingSection(_ recommendation: FastingWorkoutRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "fork.knife.circle.fill")
                    .foregroundColor(.modusTealAccent)
                Text("Nutrition Timing")
                    .font(.headline)
                Spacer()
            }

            Text(recommendation.nutritionTiming.recommendation)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()

            // Timing cards
            VStack(spacing: 8) {
                if let preWorkout = recommendation.nutritionTiming.preWorkout {
                    NutritionTimingCard(
                        phase: "Pre-Workout",
                        advice: preWorkout,
                        icon: "arrow.right.circle.fill",
                        color: .blue
                    )
                }

                if let intraWorkout = recommendation.nutritionTiming.intraWorkout {
                    NutritionTimingCard(
                        phase: "During Workout",
                        advice: intraWorkout,
                        icon: "circle.circle.fill",
                        color: .modusCyan
                    )
                }

                NutritionTimingCard(
                    phase: "Post-Workout",
                    advice: recommendation.nutritionTiming.postWorkout,
                    icon: "checkmark.circle.fill",
                    color: .modusTealAccent
                )
            }

            if !recommendation.nutritionTiming.timingNotes.isEmpty {
                Text(recommendation.nutritionTiming.timingNotes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Empty History View

    private var emptyHistoryView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.6))

            Text("No Fasting History")
                .font(.headline)

            Text("Complete your first fast to start tracking your progress over time.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private var activeFastCard: some View {
        VStack(spacing: 16) {
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: viewModel.currentProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: viewModel.currentProgress)

                VStack(spacing: 4) {
                    Text("\(viewModel.elapsedHours, specifier: "%.1f")h")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("of \(viewModel.currentFast?.targetHours ?? 0)h")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 180, height: 180)

            // Fast Type
            if let fast = viewModel.currentFast {
                Text(fast.fastingType.displayName)
                    .font(.headline)

                Text("Started \(fast.startTime.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Remaining Time
            if viewModel.remainingHours > 0 {
                Text("\(viewModel.remainingHours, specifier: "%.1f") hours remaining")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            } else {
                Text("Goal reached!")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }

            // End Fast Button
            Button {
                viewModel.showingEndSheet = true
            } label: {
                Text("End Fast")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .accessibilityLabel("End Fast")
            .accessibilityHint("Opens form to complete and log your fasting session")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .accessibilityElement(children: .contain)
    }

    private var startFastCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 48))
                .foregroundColor(.green)
                .accessibilityHidden(true)

            Text("Ready to start fasting?")
                .font(.headline)

            Text("Choose your fasting protocol and track your progress.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                viewModel.showingStartSheet = true
            } label: {
                Text("Start Fast")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Start Fast")
            .accessibilityHint("Opens fasting protocol selection")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private func statsSection(_ stats: FastingStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Stats")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                FastingStatCard(title: "Completed", value: "\(stats.completedFasts)", icon: "checkmark.circle.fill", color: .green)
                FastingStatCard(title: "Average", value: String(format: "%.1fh", stats.averageHours), icon: "clock.fill", color: .blue)
                FastingStatCard(title: "Longest", value: String(format: "%.1fh", stats.longestFast), icon: "trophy.fill", color: .yellow)
                FastingStatCard(title: "Current Streak", value: "\(stats.currentStreak)", icon: "flame.fill", color: .orange)
            }
        }
    }

    private func recommendationCard(_ recommendation: EatingWindowRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .accessibilityHidden(true)
                Text("Recommended Eating Window")
                    .font(.headline)
            }

            HStack(spacing: 20) {
                VStack {
                    Text("Start")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(recommendation.suggestedStart.formatted(date: .omitted, time: .shortened))
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)

                VStack {
                    Text("End")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(recommendation.suggestedEnd.formatted(date: .omitted, time: .shortened))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)

            Text(recommendation.reason)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Recommended eating window: \(recommendation.suggestedStart.formatted(date: .omitted, time: .shortened)) to \(recommendation.suggestedEnd.formatted(date: .omitted, time: .shortened)). \(recommendation.reason)")
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Fasts")
                    .font(.headline)
                Spacer()
                Text("\(Int(viewModel.completionRate * 100))% completion")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(viewModel.completedFasts.prefix(5)) { fast in
                FastingHistoryRow(fast: fast)
            }
        }
    }
}

struct FastingStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .accessibilityHidden(true)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

struct FastingHistoryRow: View {
    let fast: FastingLog

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(fast.fastingType.displayName)
                    .font(.subheadline)
                Text(fast.startTime.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let hours = fast.actualHours {
                Text(String(format: "%.1fh", hours))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Image(systemName: hours >= Double(fast.targetHours) * 0.9 ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(hours >= Double(fast.targetHours) * 0.9 ? .green : .orange)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(fastAccessibilityLabel)
    }

    private var fastAccessibilityLabel: String {
        var label = "\(fast.fastingType.displayName), \(fast.startTime.formatted(date: .abbreviated, time: .omitted))"
        if let hours = fast.actualHours {
            label += ", \(String(format: "%.1f", hours)) hours"
            label += hours >= Double(fast.targetHours) * 0.9 ? ", goal reached" : ", below goal"
        }
        return label
    }
}

struct StartFastSheet: View {
    @ObservedObject var viewModel: FastingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Fasting Protocol") {
                    ForEach(FastingType.allCases, id: \.self) { type in
                        Button {
                            viewModel.selectedFastType = type
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(type.displayName)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("\(type.targetHours) hours fasting")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if viewModel.selectedFastType == type {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Start Fast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        Task {
                            await viewModel.startFast()
                        }
                    }
                }
            }
        }
    }
}

struct EndFastSheet: View {
    @ObservedObject var viewModel: FastingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("How did it go?") {
                    Stepper("Energy Level: \(viewModel.energyLevel)/10", value: $viewModel.energyLevel, in: 1...10)
                }

                Section("What did you break your fast with?") {
                    TextField("First meal", text: $viewModel.breakfastFood)
                }

                Section("Notes") {
                    TextField("Any notes?", text: $viewModel.endNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("End Fast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Complete") {
                        Task {
                            await viewModel.endFast()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Nutrition Timing Card

struct NutritionTimingCard: View {
    let phase: String
    let advice: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(phase)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)

                Text(advice)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Workout Recommendation Detail View

struct FastingWorkoutRecommendationDetailView: View {
    let recommendation: FastingWorkoutRecommendation

    var body: some View {
        ScrollView {
            FastingWorkoutRecommendationView(recommendation: recommendation)
        }
        .navigationTitle("Training Recommendations")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}
