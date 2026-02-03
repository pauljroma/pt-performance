import SwiftUI

struct FastingView: View {
    @StateObject private var viewModel = FastingViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Fast Status
                    if viewModel.isFasting {
                        activeFastCard
                    } else {
                        startFastCard
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
                    }
                }
                .padding()
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
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var startFastCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 48))
                .foregroundColor(.green)

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
        }
        .padding()
        .background(Color(.systemGray6))
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
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
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
            }
        }
        .padding(.vertical, 4)
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
