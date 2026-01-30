//
//  NutritionHistoryView.swift
//  PTPerformance
//
//  BUILD 237: Nutrition Module - View nutrition history
//

import SwiftUI

/// View for viewing nutrition log history
struct NutritionHistoryView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var logs: [NutritionLog] = []
    @State private var isLoading = true
    @State private var selectedDate = Date()
    @State private var error: String?
    @State private var showError = false

    private let nutritionService = NutritionService.shared
    private let supabase = PTSupabaseClient.shared
    private let logger = DebugLogger.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date Picker
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal)
                .onChange(of: selectedDate) { _, _ in
                    Task {
                        await loadLogs()
                    }
                }

                Divider()

                // Summary for selected date
                if !logsForSelectedDate.isEmpty {
                    daySummaryCard
                }

                // Logs List
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if logsForSelectedDate.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No meals logged")
                            .font(.headline)
                        Text("Tap + to log a meal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(logsForSelectedDate) { log in
                            NutritionLogRow(log: log)
                        }
                        .onDelete(perform: deleteLogs)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Nutrition History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadLogs()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(error ?? "An error occurred")
            }
        }
    }

    // MARK: - Day Summary Card

    private var daySummaryCard: some View {
        HStack(spacing: 0) {
            DaySummaryItem(
                value: totalCalories,
                label: "Calories",
                color: .orange
            )

            DaySummaryItem(
                value: Int(totalProtein),
                label: "Protein",
                unit: "g",
                color: .red
            )

            DaySummaryItem(
                value: Int(totalCarbs),
                label: "Carbs",
                unit: "g",
                color: .blue
            )

            DaySummaryItem(
                value: Int(totalFat),
                label: "Fat",
                unit: "g",
                color: .yellow
            )
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Computed Properties

    private var logsForSelectedDate: [NutritionLog] {
        let calendar = Calendar.current
        return logs.filter { log in
            calendar.isDate(log.loggedAt, inSameDayAs: selectedDate)
        }
    }

    private var totalCalories: Int {
        logsForSelectedDate.reduce(0) { $0 + ($1.totalCalories ?? 0) }
    }

    private var totalProtein: Double {
        logsForSelectedDate.reduce(0) { $0 + ($1.totalProteinG ?? 0) }
    }

    private var totalCarbs: Double {
        logsForSelectedDate.reduce(0) { $0 + ($1.totalCarbsG ?? 0) }
    }

    private var totalFat: Double {
        logsForSelectedDate.reduce(0) { $0 + ($1.totalFatG ?? 0) }
    }

    // MARK: - Data Loading

    private func loadLogs() async {
        guard let patientId = supabase.userId else { return }

        logger.info("HISTORY", "Loading nutrition logs")
        isLoading = true

        do {
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())
            logs = try await nutritionService.fetchNutritionLogs(
                patientId: patientId,
                startDate: thirtyDaysAgo
            )
            logger.success("HISTORY", "Loaded \(logs.count) logs")
            isLoading = false
        } catch {
            logger.error("HISTORY", "Failed to load logs: \(error)")
            self.error = "Failed to load history: \(error.localizedDescription)"
            self.showError = true
            isLoading = false
        }
    }

    private func deleteLogs(at offsets: IndexSet) {
        let logsToDelete = offsets.map { logsForSelectedDate[$0] }

        Task {
            for log in logsToDelete {
                do {
                    try await nutritionService.deleteNutritionLog(id: log.id)
                    logs.removeAll { $0.id == log.id }
                } catch {
                    logger.error("HISTORY", "Failed to delete log: \(error)")
                }
            }
        }
    }
}

// MARK: - Day Summary Item

struct DaySummaryItem: View {
    let value: Int
    let label: String
    var unit: String = ""
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)\(unit)")
                .font(.headline)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Nutrition Log Row

struct NutritionLogRow: View {
    let log: NutritionLog

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let mealType = log.mealType {
                    Label(mealType.displayName, systemImage: mealType.icon)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                Text(log.loggedAt, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Food items
            if !log.foodItems.isEmpty {
                Text(log.foodItems.map { $0.name }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Macros
            HStack(spacing: 16) {
                if let cal = log.totalCalories {
                    Text("\(cal) cal")
                }
                if let protein = log.totalProteinG {
                    Text("\(Int(protein))g P")
                }
                if let carbs = log.totalCarbsG {
                    Text("\(Int(carbs))g C")
                }
                if let fat = log.totalFatG {
                    Text("\(Int(fat))g F")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
