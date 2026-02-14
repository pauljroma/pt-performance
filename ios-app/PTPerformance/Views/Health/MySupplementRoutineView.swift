// DARK MODE: See ModeThemeModifier.swift for central theme control
import SwiftUI

/// My Supplement Routine View
/// User's routine grouped by timing (morning, pre-workout, etc.)
struct MySupplementRoutineView: View {
    @StateObject private var viewModel = MySupplementRoutineViewModel()
    @ObservedObject private var interactionService = SupplementInteractionService.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var showingAddSupplement = false
    @State private var showingEditMode = false
    @State private var supplementToEdit: RoutineSupplement?
    @State private var showingInteractionView = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.routineItems.isEmpty {
                    emptyStateView
                } else {
                    routineListView
                }
            }
            .navigationTitle("My Routine")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSupplement = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.modusCyan)
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    if !viewModel.routineItems.isEmpty {
                        EditButton()
                            .foregroundColor(.modusCyan)
                    }
                }
            }
            .sheet(isPresented: $showingAddSupplement) {
                SupplementRoutineAddSheet(onAdd: { routineSupplement in
                    Task {
                        await viewModel.addToRoutine(routineSupplement)
                    }
                })
            }
            .sheet(item: $supplementToEdit) { supplement in
                SupplementRoutineEditSheet(
                    routineSupplement: supplement,
                    onSave: { updated in
                        Task {
                            await viewModel.updateRoutineSupplement(updated)
                        }
                    }
                )
            }
            .sheet(isPresented: $showingInteractionView) {
                NavigationStack {
                    SupplementInteractionView()
                }
            }
            .task {
                await viewModel.loadRoutine()
                if let userId = PTSupabaseClient.shared.userId, let patientId = UUID(uuidString: userId) {
                    try? await interactionService.checkCurrentRoutine(patientId: patientId)
                }
            }
            .refreshable {
                await viewModel.loadRoutine()
                if let userId = PTSupabaseClient.shared.userId, let patientId = UUID(uuidString: userId) {
                    try? await interactionService.checkCurrentRoutine(patientId: patientId)
                }
            }
        }
    }

    // MARK: - Interaction Helpers

    /// Returns the worst (highest) interaction severity for a given supplement name,
    /// or nil if the supplement has no interactions in the current routine.
    private func worstSeverity(for supplementName: String) -> SupplementInteraction.Severity? {
        let matching = interactionService.interactions.filter { interaction in
            interaction.supplement1.lowercased() == supplementName.lowercased()
            || interaction.supplement2.lowercased() == supplementName.lowercased()
        }
        guard !matching.isEmpty else { return nil }
        // Severity ordering: .critical > .major > .moderate > .minor
        if matching.contains(where: { $0.severity == .critical }) { return .critical }
        if matching.contains(where: { $0.severity == .major }) { return .major }
        if matching.contains(where: { $0.severity == .moderate }) { return .moderate }
        return .minor
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading routine...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "pills")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            VStack(spacing: Spacing.sm) {
                Text("No Supplements in Routine")
                    .font(.headline)

                Text("Build your daily supplement routine by adding supplements you want to track.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: Spacing.md) {
                Button {
                    showingAddSupplement = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Supplement")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(
                        LinearGradient(
                            colors: [.modusCyan, .modusTealAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.lg)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    SupplementStacksView()
                } label: {
                    HStack {
                        Image(systemName: "square.stack.3d.up.fill")
                        Text("Browse Stacks")
                    }
                    .font(.subheadline)
                    .foregroundColor(.modusCyan)
                }
            }
        }
        .padding(Spacing.xl)
    }

    // MARK: - Routine List View

    private var routineListView: some View {
        List {
            // Summary Card
            Section {
                routineSummaryCard
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            // Interaction Safety Banner
            if let rating = interactionService.overallSafetyRating, rating != .safe {
                Section {
                    SafetyWarningBanner(
                        safetyRating: rating,
                        interactionCount: interactionService.interactions.count,
                        mostCriticalMessage: interactionService.interactions.max(by: { $0.severity < $1.severity })?.description,
                        onTap: {
                            showingInteractionView = true
                        }
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // Grouped by Timing
            ForEach(SupplementTiming.allCases, id: \.self) { timing in
                let items = viewModel.items(for: timing)
                if !items.isEmpty {
                    Section {
                        ForEach(items) { item in
                            SupplementRoutineRow(
                                item: item,
                                interactionSeverity: worstSeverity(for: item.name),
                                onTap: {
                                    supplementToEdit = item
                                }
                            )
                        }
                        .onDelete { indexSet in
                            Task {
                                await viewModel.deleteItems(at: indexSet, for: timing)
                            }
                        }
                        .onMove { source, destination in
                            viewModel.moveItems(from: source, to: destination, for: timing)
                        }
                    } header: {
                        SupplementTimingHeader(timing: timing, count: items.count)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Routine Summary Card

    private var routineSummaryCard: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Daily Routine")
                        .font(.headline)
                        .foregroundColor(.modusDeepTeal)

                    Text("\(viewModel.totalSupplements) supplements across \(viewModel.activeTimes) times")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Timing breakdown
            HStack(spacing: Spacing.sm) {
                ForEach(SupplementTiming.allCases, id: \.self) { timing in
                    let count = viewModel.items(for: timing).count
                    if count > 0 {
                        SupplementTimingBadge(timing: timing, count: count)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal)
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Timing Header

private struct SupplementTimingHeader: View {
    let timing: SupplementTiming
    let count: Int

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: timing.icon)
                .foregroundColor(timing.color)

            Text(timing.displayName)
                .foregroundColor(.modusDeepTeal)

            Spacer()

            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, 2)
                .background(timing.color.opacity(0.2))
                .foregroundColor(timing.color)
                .cornerRadius(CornerRadius.sm)
        }
    }
}

// MARK: - Timing Badge

private struct SupplementTimingBadge: View {
    let timing: SupplementTiming
    let count: Int

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: timing.icon)
                .font(.caption)
                .foregroundColor(timing.color)

            Text("\(count)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(timing.shortName)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xs)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - SupplementTiming Extension

extension SupplementTiming {
    var shortName: String {
        switch self {
        case .morning: return "AM"
        case .afternoon: return "Noon"
        case .preWorkout: return "Pre"
        case .postWorkout: return "Post"
        case .evening: return "PM"
        case .beforeBed: return "Bed"
        case .withMeal: return "Meal"
        case .emptyStomach: return "Empty"
        case .anytime: return "Any"
        }
    }

    var color: Color {
        switch self {
        case .morning: return .orange
        case .afternoon: return .yellow
        case .preWorkout: return .red
        case .postWorkout: return .green
        case .evening: return .purple
        case .beforeBed: return .indigo
        case .withMeal: return .brown
        case .emptyStomach: return .cyan
        case .anytime: return .gray
        }
    }
}

// MARK: - Routine Row

private struct SupplementRoutineRow: View {
    let item: RoutineSupplement
    /// Optional interaction severity for this supplement (nil if no interactions).
    var interactionSeverity: SupplementInteraction.Severity?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                // Icon with optional interaction severity indicator
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Circle()
                            .fill(Color.modusCyan.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: item.category.icon)
                            .foregroundColor(.modusCyan)
                    }

                    if let severity = interactionSeverity {
                        Circle()
                            .fill(severityDotColor(severity))
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemBackground), lineWidth: 1.5)
                            )
                            .offset(x: 2, y: -2)
                            .accessibilityLabel("\(severity.displayName) interaction")
                    }
                }

                // Details
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack(spacing: Spacing.xs) {
                        if let dosage = item.dosage {
                            Text("\(String(format: "%.0f", dosage.amount)) \(dosage.unit.abbreviation)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if item.withFood {
                            Text("•")
                                .foregroundColor(.secondary)
                            Label("With food", systemImage: "fork.knife")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }

                Spacer()

                // Days indicator
                if let days = item.days {
                    SupplementDaysIndicator(days: Set(days))
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func severityDotColor(_ severity: SupplementInteraction.Severity) -> Color {
        switch severity {
        case .critical: return .red
        case .major: return .orange
        case .moderate: return .yellow
        case .minor: return .green
        }
    }
}

// MARK: - Days Indicator

private struct SupplementDaysIndicator: View {
    let days: Set<Weekday>

    private let allDays = Weekday.allCases

    var body: some View {
        HStack(spacing: 2) {
            ForEach(allDays, id: \.self) { day in
                Circle()
                    .fill(days.contains(day) ? Color.modusTealAccent : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

// MARK: - Add Sheet

private struct SupplementRoutineAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SupplementPickerViewModel()

    let onAdd: (RoutineSupplement) -> Void

    @State private var selectedSupplement: Supplement?
    @State private var selectedTiming: SupplementTiming = .morning
    @State private var dosageAmount: String = ""
    @State private var dosageUnit: DosageUnit = .mg
    @State private var withFood = false
    @State private var selectedDays: Set<Weekday> = Set(Weekday.allCases)
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if selectedSupplement == nil {
                    supplementSelectionView
                } else {
                    configurationView
                }
            }
            .navigationTitle(selectedSupplement == nil ? "Add Supplement" : "Configure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if selectedSupplement != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            saveAndDismiss()
                        }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                    }
                }
            }
            .task {
                await viewModel.loadSupplements()
            }
        }
    }

    private var supplementSelectionView: some View {
        List(filteredSupplements) { supplement in
            Button {
                HapticFeedback.light()
                selectedSupplement = supplement
                // Parse dosage string for default values
                dosageAmount = extractDosageAmount(from: supplement.dosage)
                dosageUnit = extractDosageUnit(from: supplement.dosage)
                // Set default timing based on timeOfDay
                if let firstTime = supplement.timeOfDay.first {
                    selectedTiming = mapTimeOfDayToTiming(firstTime)
                }
                withFood = supplement.withFood
            } label: {
                HStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Color.modusCyan.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: supplement.category.icon)
                            .foregroundColor(.modusCyan)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(supplement.name)
                            .font(.body)
                            .foregroundColor(.primary)

                        Text(supplement.category.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search supplements")
    }

    private var filteredSupplements: [Supplement] {
        if searchText.isEmpty {
            return viewModel.supplements
        }
        return viewModel.supplements.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var configurationView: some View {
        Form {
            if let supplement = selectedSupplement {
                Section {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.modusCyan.opacity(0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: supplement.category.icon)
                                .foregroundColor(.modusCyan)
                        }

                        VStack(alignment: .leading) {
                            Text(supplement.name)
                                .font(.headline)
                            Text(supplement.category.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button("Change") {
                            selectedSupplement = nil
                        }
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                    }
                }

                Section("Dosage") {
                    HStack {
                        TextField("Amount", text: $dosageAmount)
                            .keyboardType(.decimalPad)

                        Picker("Unit", selection: $dosageUnit) {
                            ForEach(DosageUnit.allCases, id: \.self) { unit in
                                Text(unit.abbreviation).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section("Timing") {
                    Picker("When to Take", selection: $selectedTiming) {
                        ForEach(SupplementTiming.allCases, id: \.self) { timing in
                            Label(timing.displayName, systemImage: timing.icon)
                                .tag(timing)
                        }
                    }

                    Toggle(isOn: $withFood) {
                        Label("Take with Food", systemImage: "fork.knife")
                    }
                    .tint(.modusTealAccent)
                }

                Section("Days") {
                    ForEach(Weekday.allCases, id: \.self) { day in
                        Toggle(day.displayName, isOn: Binding(
                            get: { selectedDays.contains(day) },
                            set: { isOn in
                                if isOn {
                                    selectedDays.insert(day)
                                } else {
                                    selectedDays.remove(day)
                                }
                            }
                        ))
                        .tint(.modusTealAccent)
                    }
                }
            }
        }
    }

    private var isValid: Bool {
        selectedSupplement != nil && !dosageAmount.isEmpty && Double(dosageAmount) != nil && !selectedDays.isEmpty
    }

    private func saveAndDismiss() {
        guard let supplement = selectedSupplement,
              let amount = Double(dosageAmount) else { return }

        HapticFeedback.success()

        let routineSupplement = RoutineSupplement(
            id: UUID(),
            name: supplement.name,
            brand: supplement.brand,
            category: mapSupplementCategoryToCatalog(supplement.category),
            dosage: Dosage(amount: amount, unit: dosageUnit),
            timing: selectedTiming,
            days: Array(selectedDays),
            withFood: withFood,
            reminderEnabled: true
        )

        onAdd(routineSupplement)
        dismiss()
    }

    // MARK: - Helpers

    private func extractDosageAmount(from dosageString: String) -> String {
        let pattern = #"([\d.]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: dosageString, range: NSRange(dosageString.startIndex..., in: dosageString)),
              let range = Range(match.range(at: 1), in: dosageString) else {
            return ""
        }
        return String(dosageString[range])
    }

    private func extractDosageUnit(from dosageString: String) -> DosageUnit {
        let lowercased = dosageString.lowercased()
        if lowercased.contains("mg") { return .mg }
        if lowercased.contains("mcg") { return .mcg }
        if lowercased.contains("iu") { return .iu }
        if lowercased.contains("g") { return .g }
        if lowercased.contains("ml") { return .ml }
        if lowercased.contains("capsule") { return .capsule }
        if lowercased.contains("tablet") { return .tablet }
        if lowercased.contains("scoop") { return .scoop }
        return .mg
    }

    private func mapTimeOfDayToTiming(_ timeOfDay: SupplementTimeOfDay) -> SupplementTiming {
        switch timeOfDay {
        case .morning: return .morning
        case .afternoon: return .afternoon
        case .evening: return .evening
        case .night: return .beforeBed
        case .beforeBed: return .beforeBed
        case .preWorkout: return .preWorkout
        case .postWorkout: return .postWorkout
        case .withMeals: return .withMeal
        }
    }

    private func mapSupplementCategoryToCatalog(_ category: SupplementCategory) -> SupplementCatalogCategory {
        switch category {
        case .protein: return .protein
        case .creatine: return .performance
        case .vitamins: return .vitamin
        case .minerals: return .mineral
        case .omega3: return .health
        case .preworkout: return .preworkout
        case .recovery: return .recovery
        case .sleep: return .sleep
        case .adaptogens: return .cognitive
        case .other: return .other
        }
    }
}

// MARK: - Edit Sheet

private struct SupplementRoutineEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    let routineSupplement: RoutineSupplement
    let onSave: (RoutineSupplement) -> Void

    @State private var selectedTiming: SupplementTiming
    @State private var dosageAmount: String
    @State private var dosageUnit: DosageUnit
    @State private var withFood: Bool
    @State private var selectedDays: Set<Weekday>
    @State private var reminderEnabled: Bool

    init(routineSupplement: RoutineSupplement, onSave: @escaping (RoutineSupplement) -> Void) {
        self.routineSupplement = routineSupplement
        self.onSave = onSave
        _selectedTiming = State(initialValue: routineSupplement.timing ?? .morning)
        _dosageAmount = State(initialValue: String(format: "%.0f", routineSupplement.dosage?.amount ?? 0))
        _dosageUnit = State(initialValue: routineSupplement.dosage?.unit ?? .mg)
        _withFood = State(initialValue: routineSupplement.withFood)
        _selectedDays = State(initialValue: Set(routineSupplement.days ?? Weekday.allCases))
        _reminderEnabled = State(initialValue: routineSupplement.reminderEnabled)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.modusCyan.opacity(0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: routineSupplement.category.icon)
                                .foregroundColor(.modusCyan)
                        }

                        VStack(alignment: .leading) {
                            Text(routineSupplement.name)
                                .font(.headline)
                            Text(routineSupplement.category.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Dosage") {
                    HStack {
                        TextField("Amount", text: $dosageAmount)
                            .keyboardType(.decimalPad)

                        Picker("Unit", selection: $dosageUnit) {
                            ForEach(DosageUnit.allCases, id: \.self) { unit in
                                Text(unit.abbreviation).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section("Timing") {
                    Picker("When to Take", selection: $selectedTiming) {
                        ForEach(SupplementTiming.allCases, id: \.self) { timing in
                            Label(timing.displayName, systemImage: timing.icon)
                                .tag(timing)
                        }
                    }

                    Toggle(isOn: $withFood) {
                        Label("Take with Food", systemImage: "fork.knife")
                    }
                    .tint(.modusTealAccent)

                    Toggle(isOn: $reminderEnabled) {
                        Label("Reminder", systemImage: "bell")
                    }
                    .tint(.modusTealAccent)
                }

                Section("Days") {
                    ForEach(Weekday.allCases, id: \.self) { day in
                        Toggle(day.displayName, isOn: Binding(
                            get: { selectedDays.contains(day) },
                            set: { isOn in
                                if isOn {
                                    selectedDays.insert(day)
                                } else {
                                    selectedDays.remove(day)
                                }
                            }
                        ))
                        .tint(.modusTealAccent)
                    }
                }
            }
            .navigationTitle("Edit Supplement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAndDismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !dosageAmount.isEmpty && Double(dosageAmount) != nil && !selectedDays.isEmpty
    }

    private func saveAndDismiss() {
        guard let amount = Double(dosageAmount) else { return }

        HapticFeedback.success()

        var updated = routineSupplement
        updated.dosage = Dosage(amount: amount, unit: dosageUnit)
        updated.timing = selectedTiming
        updated.days = Array(selectedDays)
        updated.withFood = withFood
        updated.reminderEnabled = reminderEnabled

        onSave(updated)
        dismiss()
    }
}

// MARK: - Preview

#if DEBUG
struct MySupplementRoutineView_Previews: PreviewProvider {
    static var previews: some View {
        MySupplementRoutineView()
            .previewDisplayName("My Supplement Routine")
    }
}
#endif
