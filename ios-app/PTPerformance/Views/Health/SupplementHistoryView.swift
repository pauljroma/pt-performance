import SwiftUI

/// Supplement History View
/// Calendar compliance view with streak tracking
struct SupplementHistoryView: View {
    @StateObject private var viewModel = SupplementHistoryViewModel()
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedDate: Date = Date()
    @State private var selectedMonth: Date = Date()
    @State private var showingDatePicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if viewModel.isLoading {
                    ProgressView("Loading history...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .accessibilityLabel("Loading supplement history")
                } else if viewModel.hasNoHistory {
                    emptyHistoryView
                } else {
                    // Streak Card
                    streakCard

                    // Calendar View
                    calendarSection

                    // Selected Day Details
                    selectedDaySection

                    // Monthly Summary
                    monthlySummarySection
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Supplement History")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingDatePicker = true
                } label: {
                    Image(systemName: "calendar")
                        .foregroundColor(.modusCyan)
                }
                .accessibilityLabel("Select date")
                .accessibilityHint("Opens a date picker to navigate to a specific month")
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            SupplementDatePickerSheet(
                selectedDate: $selectedDate,
                onSelect: { date in
                    selectedMonth = date
                    showingDatePicker = false
                }
            )
        }
        .task {
            await viewModel.loadHistory(for: selectedMonth)
        }
        .onChange(of: selectedMonth) { _, newMonth in
            Task {
                await viewModel.loadHistory(for: newMonth)
            }
        }
        .alert("Error Loading History", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("Dismiss") { viewModel.error = nil }
            Button("Retry") {
                Task {
                    await viewModel.loadHistory(for: selectedMonth)
                }
            }
        } message: {
            Text(viewModel.error ?? "An unknown error occurred while loading your supplement history.")
        }
    }

    // MARK: - Empty History View

    private var emptyHistoryView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "pills.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))

            VStack(spacing: Spacing.sm) {
                Text("No Supplement History")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.modusDeepTeal)

                Text("Start tracking your supplements to see your compliance history and streaks here.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }

            Spacer()
        }
        .frame(minHeight: 300)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No supplement history. Start tracking your supplements to see your compliance history and streaks here.")
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: Spacing.lg) {
            // Current Streak
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(viewModel.currentStreak)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.modusDeepTeal)
                }
                Text("Current Streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Current streak: \(viewModel.currentStreak) days")

            Divider()
                .frame(height: 50)

            // Best Streak
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("\(viewModel.bestStreak)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.modusDeepTeal)
                }
                Text("Best Streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Best streak: \(viewModel.bestStreak) days")

            Divider()
                .frame(height: 50)

            // Total Days
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.modusTealAccent)
                    Text("\(viewModel.totalCompleteDays)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.modusDeepTeal)
                }
                Text("Complete Days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(viewModel.totalCompleteDays) complete days")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Calendar Section

    private var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    private var calendarSection: some View {
        VStack(spacing: Spacing.sm) {
            // Month Navigation
            HStack {
                Button {
                    HapticFeedback.light()
                    withAnimation {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.modusCyan)
                }
                .accessibilityLabel("Previous month")
                .accessibilityHint("Shows supplement history for the previous month")

                Spacer()

                Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)

                Spacer()

                Button {
                    HapticFeedback.light()
                    withAnimation {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(isCurrentMonth ? .modusCyan.opacity(0.3) : .modusCyan)
                }
                .disabled(isCurrentMonth)
                .accessibilityLabel(isCurrentMonth ? "Next month, disabled" : "Next month")
                .accessibilityHint(isCurrentMonth
                    ? "Cannot navigate to future months because there is no supplement data beyond the current month"
                    : "Shows supplement history for the next month")
            }
            .padding(.horizontal)

            // Weekday Headers
            HStack(spacing: 0) {
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol.prefix(1))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            // Calendar Grid
            SupplementCalendarGrid(
                month: selectedMonth,
                selectedDate: $selectedDate,
                dayData: viewModel.calendarDayData
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Calendar grid showing supplement compliance for \(selectedMonth.formatted(.dateTime.month(.wide).year()))")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Selected Day Section

    private var selectedDaySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)

                Spacer()

                if let dayData = viewModel.data(for: selectedDate) {
                    SupplementComplianceBadge(compliance: dayData.complianceRate)
                }
            }

            if let dayData = viewModel.data(for: selectedDate) {
                if dayData.logs.isEmpty {
                    emptyDayView
                } else {
                    ForEach(dayData.logs) { log in
                        SupplementHistoryLogRow(log: log)
                    }
                }
            } else {
                emptyDayView
            }
        }
    }

    private var emptyDayView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "pills")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.5))
                .accessibilityHidden(true)

            Text("No supplements logged")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if Calendar.current.isDateInToday(selectedDate) {
                Text("Log your supplements from the dashboard to track your progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No supplements logged for \(selectedDate.formatted(date: .abbreviated, time: .omitted))")
    }

    // MARK: - Monthly Summary Section

    private var monthlySummarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Monthly Summary")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: Spacing.md) {
                SupplementSummaryStatCard(
                    title: "Compliance",
                    value: "\(Int(viewModel.monthlyCompliance * 100))%",
                    icon: "chart.bar.fill",
                    color: .modusCyan
                )

                SupplementSummaryStatCard(
                    title: "Logged",
                    value: "\(viewModel.monthlyLogsCount)",
                    icon: "checkmark.circle.fill",
                    color: .modusTealAccent
                )

                SupplementSummaryStatCard(
                    title: "Missed",
                    value: "\(viewModel.monthlyMissedCount)",
                    icon: "xmark.circle.fill",
                    color: .orange
                )
            }

            // Top Supplements
            if !viewModel.topSupplements.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Most Taken")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.modusDeepTeal)
                        .padding(.top, Spacing.sm)
                        .accessibilityAddTraits(.isHeader)

                    ForEach(viewModel.topSupplements.prefix(5)) { stat in
                        HStack {
                            Image(systemName: stat.supplement.category.icon)
                                .font(.caption)
                                .foregroundColor(.modusCyan)
                                .frame(width: 20)

                            Text(stat.supplement.name)
                                .font(.caption)
                                .foregroundColor(.primary)

                            Spacer()

                            Text("\(stat.count) times")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(stat.supplement.name), taken \(stat.count) times")
                    }
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(CornerRadius.md)
            }
        }
    }
}

// MARK: - Calendar Grid

private struct SupplementCalendarGrid: View {
    let month: Date
    @Binding var selectedDate: Date
    let dayData: [Date: SupplementDayData]

    private let calendar = Calendar.current

    private var days: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var days: [Date?] = []
        var currentDate = monthFirstWeek.start

        // Add leading nil days for alignment
        while !calendar.isDate(currentDate, equalTo: monthInterval.start, toGranularity: .month) {
            days.append(nil)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        // Add month days
        while calendar.isDate(currentDate, equalTo: monthInterval.start, toGranularity: .month) {
            days.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        return days
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                if let date = date {
                    SupplementCalendarDayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        dayData: dayData[calendar.startOfDay(for: date)],
                        onTap: {
                            HapticFeedback.light()
                            selectedDate = date
                        }
                    )
                } else {
                    Color.clear
                        .frame(height: 44)
                }
            }
        }
    }
}

// MARK: - Calendar Day Cell

private struct SupplementCalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let dayData: SupplementDayData?
    let onTap: () -> Void

    private var complianceColor: Color {
        guard let data = dayData else {
            return .clear
        }

        if data.complianceRate >= 1.0 {
            return .modusTealAccent
        } else if data.complianceRate >= 0.5 {
            return .orange
        } else if data.complianceRate > 0 {
            return .orange.opacity(0.5)
        } else {
            return .clear
        }
    }

    private var accessibilityDescription: String {
        let day = Calendar.current.component(.day, from: date)
        var description = "Day \(day)"
        if isToday {
            description += ", today"
        }
        if let data = dayData {
            let percentage = Int(data.complianceRate * 100)
            if percentage >= 100 {
                description += ", fully completed"
            } else if percentage > 0 {
                description += ", \(percentage) percent complete"
            } else {
                description += ", no supplements logged"
            }
        }
        return description
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                if isSelected {
                    Circle()
                        .fill(Color.modusCyan)
                } else if isToday {
                    Circle()
                        .stroke(Color.modusCyan, lineWidth: 2)
                }

                // Compliance indicator
                if !isSelected && dayData != nil {
                    Circle()
                        .fill(complianceColor.opacity(0.3))
                }

                // Day number
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(isSelected ? .white : (isToday ? .modusCyan : .primary))
            }
            .frame(height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Tap to view supplements for this day")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Compliance Badge

private struct SupplementComplianceBadge: View {
    let compliance: Double

    private var color: Color {
        if compliance >= 1.0 {
            return .modusTealAccent
        } else if compliance >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }

    private var icon: String {
        if compliance >= 1.0 {
            return "checkmark.circle.fill"
        } else if compliance >= 0.5 {
            return "circle.lefthalf.filled"
        } else {
            return "xmark.circle.fill"
        }
    }

    private var accessibilityDescription: String {
        let percentage = Int(compliance * 100)
        if percentage >= 100 {
            return "Fully completed, \(percentage) percent"
        } else if percentage >= 80 {
            return "Almost complete, \(percentage) percent"
        } else if percentage >= 50 {
            return "Partially complete, \(percentage) percent"
        } else if percentage > 0 {
            return "Low compliance, \(percentage) percent"
        } else {
            return "No supplements taken"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text("\(Int(compliance * 100))%")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }
}

// MARK: - History Log Row

private struct SupplementHistoryLogRow: View {
    let log: SupplementLogEntry

    private var accessibilityDescription: String {
        var description = log.supplementName
        description += ", \(log.dosage)"
        description += ", taken at \(log.takenAt.formatted(date: .omitted, time: .shortened))"
        description += ", \(log.timing.displayName)"
        if log.skipped {
            description += ", skipped"
        }
        return description
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.modusCyan.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: log.supplement?.category.icon ?? "pills.fill")
                    .font(.caption)
                    .foregroundColor(.modusCyan)
            }

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(log.supplementName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                HStack(spacing: Spacing.xs) {
                    Text(log.dosage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Time
            VStack(alignment: .trailing, spacing: 2) {
                Text(log.takenAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(log.timing.displayName)
                    .font(.caption2)
                    .foregroundColor(.modusCyan)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }
}

// MARK: - Summary Stat Card

private struct SupplementSummaryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Date Picker Sheet

private struct SupplementDatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    let onSelect: (Date) -> Void

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select Month",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()

                Spacer()
            }
            .navigationTitle("Go to Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Select") {
                        onSelect(selectedDate)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct SupplementHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SupplementHistoryView()
        }
        .previewDisplayName("Supplement History")
    }
}
#endif
