// DARK MODE: See ModeThemeModifier.swift for central theme control
import SwiftUI

struct SupplementsView: View {
    @StateObject private var viewModel = SupplementViewModel()
    @State private var showingAIRecommendations = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // AI Recommendations Card
                    aiRecommendationsCard

                    // Today's Schedule
                    todayScheduleSection

                    // My Stack
                    if !viewModel.supplements.isEmpty {
                        myStackSection
                    }
                }
                .padding()
            }
            .navigationTitle("Supplements")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Add supplement")
                    .accessibilityHint("Opens form to add a new supplement to your routine")
                }
            }
            .sheet(isPresented: $viewModel.showingAddSheet) {
                AddSupplementSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAIRecommendations) {
                SupplementRecommendationsView()
            }
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - AI Recommendations Card

    private var aiRecommendationsCard: some View {
        Button {
            showingAIRecommendations = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.modusCyan.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.modusCyan)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Supplement Stack")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Get personalized recommendations based on your goals, labs, and recovery data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.modusCyan.opacity(0.1), Color.modusLightTeal],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(CornerRadius.lg)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("AI Supplement Stack")
        .accessibilityHint("Get personalized supplement recommendations powered by AI")
    }

    private var todayScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Schedule")
                    .font(.headline)
                Spacer()
                Text("\(Int(viewModel.completionRate * 100))%")
                    .font(.subheadline)
                    .foregroundColor(viewModel.completionRate == 1 ? .green : .orange)
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(viewModel.completionRate == 1 ? Color(.systemGreen) : Color.modusCyan)
                        .frame(width: geometry.size.width * viewModel.completionRate)
                }
            }
            .frame(height: 8)

            if viewModel.pendingToday.isEmpty && !viewModel.todaySchedule.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .accessibilityHidden(true)
                    Text("All supplements taken today!")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGreen).opacity(0.1))
                .cornerRadius(CornerRadius.md)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("All supplements taken today")
            } else if viewModel.todaySchedule.isEmpty {
                ContentUnavailableView {
                    Label("No Supplements", systemImage: "pill")
                } description: {
                    Text("Add supplements to your stack to see your daily schedule.")
                }
            } else {
                ForEach(viewModel.pendingToday) { scheduled in
                    ScheduledSupplementRow(scheduled: scheduled) {
                        Task {
                            await viewModel.markTaken(scheduled)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private var myStackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Stack")
                .font(.headline)

            ForEach(viewModel.supplementsByCategory, id: \.0) { category, supplements in
                VStack(alignment: .leading, spacing: 8) {
                    Label(category.displayName, systemImage: category.icon)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ForEach(supplements) { supplement in
                        SupplementRow(supplement: supplement) {
                            Task {
                                await viewModel.deleteSupplement(supplement)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ScheduledSupplementRow: View {
    let scheduled: ScheduledSupplement
    let onTake: () -> Void

    var body: some View {
        HStack {
            Image(systemName: scheduled.supplement.category.icon)
                .foregroundColor(.blue)
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(scheduled.supplement.name)
                    .font(.subheadline)
                Text(scheduled.supplement.dosage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(scheduled.scheduledTime.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: onTake) {
                Image(systemName: scheduled.taken ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(scheduled.taken ? .green : .gray)
                    .font(.title2)
            }
            .disabled(scheduled.taken)
            .accessibilityLabel(scheduled.taken ? "Taken" : "Mark as taken")
            .accessibilityHint(scheduled.taken ? "Already taken" : "Double tap to mark \(scheduled.supplement.name) as taken")
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
    }
}

struct SupplementRow: View {
    let supplement: Supplement
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(supplement.name)
                    .font(.subheadline)
                if let brand = supplement.brand {
                    Text(brand)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text("\(supplement.dosage) - \(supplement.frequency.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                ForEach(supplement.timeOfDay, id: \.self) { time in
                    Text(time.displayName.prefix(3))
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.modusCyan.opacity(0.2))
                        .cornerRadius(CornerRadius.xs)
                }
            }
            .accessibilityHidden(true)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            .accessibilityLabel("Delete \(supplement.name)")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(supplementAccessibilityLabel)
    }

    private var supplementAccessibilityLabel: String {
        var label = supplement.name
        if let brand = supplement.brand {
            label += " by \(brand)"
        }
        label += ", \(supplement.dosage), \(supplement.frequency.displayName)"
        let times = supplement.timeOfDay.map { $0.displayName }.joined(separator: ", ")
        label += ", taken \(times)"
        return label
    }
}

struct AddSupplementSheet: View {
    @ObservedObject var viewModel: SupplementViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $viewModel.newName)
                    TextField("Brand (optional)", text: $viewModel.newBrand)

                    Picker("Category", selection: $viewModel.newCategory) {
                        ForEach(SupplementCategory.allCases, id: \.self) { category in
                            Label(category.displayName, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }

                Section("Dosage") {
                    TextField("Dosage (e.g., 5g, 2 capsules)", text: $viewModel.newDosage)

                    Picker("Frequency", selection: $viewModel.newFrequency) {
                        ForEach(SupplementFrequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }
                }

                Section("When to Take") {
                    ForEach(TimeOfDay.allCases, id: \.self) { time in
                        Button {
                            if viewModel.newTimeOfDay.contains(time) {
                                viewModel.newTimeOfDay.remove(time)
                            } else {
                                viewModel.newTimeOfDay.insert(time)
                            }
                        } label: {
                            HStack {
                                Text(time.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if viewModel.newTimeOfDay.contains(time) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }

                    Toggle("Take with food", isOn: $viewModel.newWithFood)
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $viewModel.newNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Supplement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await viewModel.addSupplement()
                        }
                    }
                    .disabled(viewModel.newName.isEmpty || viewModel.newDosage.isEmpty)
                }
            }
        }
    }
}
