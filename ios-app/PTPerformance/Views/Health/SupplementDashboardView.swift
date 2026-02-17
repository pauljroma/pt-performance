// DARK MODE: See ModeThemeModifier.swift for central theme control
import SwiftUI

/// Main Supplement Dashboard View
/// Displays today's checklist with time-grouped supplements, one-tap logging,
/// swipe-to-log, goal-based recommendations, and evidence grades
struct SupplementDashboardView: View {
    @StateObject private var viewModel = SupplementDashboardViewModel()
    @StateObject private var interactionService = SupplementInteractionService.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingQuickLog = false
    @State private var showingRoutineEditor = false
    @State private var showingSupplementDetail: CatalogSupplement?
    @State private var showingGoalPicker = false
    @State private var showingInteractionView = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.todayChecklist.isEmpty {
                    loadingView
                } else {
                    contentView
                }
            }
            .navigationTitle("Supplements")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingRoutineEditor = true
                        } label: {
                            Label("Edit Routine", systemImage: "pencil")
                        }

                        NavigationLink {
                            SupplementHistoryView()
                        } label: {
                            Label("View History", systemImage: "calendar")
                        }

                        NavigationLink {
                            SupplementCatalogView()
                        } label: {
                            Label("Browse Catalog", systemImage: "books.vertical")
                        }

                        Divider()

                        Button {
                            showingGoalPicker = true
                        } label: {
                            Label("Change Goal", systemImage: "target")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.modusCyan)
                    }
                }
            }
            .sheet(isPresented: $showingQuickLog) {
                SupplementLogView(
                    preselectedSupplement: nil,
                    onSave: { log in
                        // Dismiss sheet before starting async save operation
                        showingQuickLog = false
                        Task {
                            await viewModel.saveLog(log)
                        }
                    }
                )
            }
            .sheet(isPresented: $showingRoutineEditor) {
                MySupplementRoutineView()
            }
            .sheet(isPresented: $showingGoalPicker) {
                GoalPickerSheet(
                    selectedGoal: $viewModel.userGoal,
                    onSelect: { goal in
                        viewModel.updateGoal(goal)
                        showingGoalPicker = false
                    }
                )
            }
            .task {
                if let userId = PTSupabaseClient.shared.userId, let patientId = UUID(uuidString: userId) {
                    async let a: () = viewModel.loadData()
                    async let b: () = { try? await interactionService.checkCurrentRoutine(patientId: patientId) }()
                    _ = await (a, b)
                } else {
                    await viewModel.loadData()
                }
            }
            .refreshable {
                if let userId = PTSupabaseClient.shared.userId, let patientId = UUID(uuidString: userId) {
                    async let a: () = viewModel.loadData()
                    async let b: () = { try? await interactionService.checkCurrentRoutine(patientId: patientId) }()
                    _ = await (a, b)
                } else {
                    await viewModel.loadData()
                }
            }
            .sheet(isPresented: $showingInteractionView) {
                NavigationStack {
                    SupplementInteractionView()
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("Dismiss") { viewModel.dismissError() }
                if viewModel.canRetryLastAction {
                    Button("Retry") { viewModel.retryLastAction() }
                }
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Streak Milestone!", isPresented: $viewModel.showStreakCelebration) {
                Button("Awesome!") { viewModel.dismissStreakCelebration() }
            } message: {
                Text(viewModel.streakCelebrationMessage)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading your supplements...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Compliance Progress Card
                complianceCard

                // Safety Warning Banner (Interaction Checker)
                if let rating = interactionService.overallSafetyRating {
                    SafetyWarningBanner(
                        safetyRating: rating,
                        interactionCount: interactionService.interactions.count,
                        mostCriticalMessage: interactionService.interactions.max(by: { $0.severity < $1.severity })?.description,
                        onTap: {
                            showingInteractionView = true
                        }
                    )
                }

                // Today's Stack Section (Grouped by Timing)
                todayStackSection

                // Quick Log Button
                quickLogButton

                // Goal-Based Recommendations
                recommendationsSection

                // My Stack Section
                myStackSection

                // Predefined Stacks Navigation
                stacksNavigationSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Compliance Card

    private var complianceCard: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Progress")
                        .font(.headline)
                        .foregroundColor(.modusDeepTeal)

                    Text("\(viewModel.completedCount) of \(viewModel.totalCount) taken")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Circular Progress
                ZStack {
                    Circle()
                        .stroke(Color.modusCyan.opacity(0.2), lineWidth: 8)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: viewModel.complianceProgress)
                        .stroke(
                            LinearGradient(
                                colors: [.modusCyan, .modusTealAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: viewModel.complianceProgress)

                    Text("\(Int(viewModel.complianceProgress * 100))%")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.modusCyan)
                }
                .accessibilityLabel("Compliance: \(Int(viewModel.complianceProgress * 100)) percent")
            }

            // Weekly Streak
            HStack(spacing: Spacing.sm) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .accessibilityHidden(true)
                Text("\(viewModel.currentStreak) day streak")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("Best: \(viewModel.bestStreak) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Current streak: \(viewModel.currentStreak) days. Best streak: \(viewModel.bestStreak) days")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Today's supplement progress")
    }

    // MARK: - Today's Stack Section (Time-Grouped)

    private var todayStackSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Section Header
            HStack {
                Image(systemName: "pills.fill")
                    .foregroundColor(.modusCyan)
                Text("TODAY'S SUPPLEMENTS")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.modusDeepTeal)

                Spacer()
            }

            if viewModel.todayChecklist.isEmpty {
                emptyChecklistView
            } else {
                // Grouped supplements by timing
                ForEach(viewModel.sortedTimingGroups) { group in
                    TimingGroupCard(
                        group: group,
                        items: viewModel.items(for: group),
                        isComplete: viewModel.isGroupComplete(group),
                        isLoggingItem: viewModel.isLoggingItem,
                        onToggleItem: { item in
                            HapticFeedback.light()
                            viewModel.toggleItem(item)
                        },
                        onSwipeLog: { item in
                            viewModel.logSupplementViaSwipe(item)
                        },
                        onTapItem: { item in
                            viewModel.selectedSupplementForLog = item.supplement
                            showingQuickLog = true
                        },
                        onLogAll: {
                            viewModel.logAllInGroup(group)
                        }
                    )
                }
            }
        }
    }

    private var emptyChecklistView: some View {
        EmptyStateView(
            title: "No Supplements Tracked",
            message: "Add supplements to your routine to track your daily intake and build healthy habits.",
            icon: "pills.fill",
            iconColor: .modusCyan,
            action: EmptyStateView.EmptyStateAction(
                title: "Set Up Routine",
                icon: "plus.circle.fill",
                action: {
                    showingRoutineEditor = true
                }
            )
        )
        .padding(Spacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Quick Log Button

    private var quickLogButton: some View {
        Button {
            HapticFeedback.medium()
            viewModel.selectedSupplementForLog = nil
            showingQuickLog = true
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                Text("Quick Log Supplement")
                    .font(.headline)
            }
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
        .shadow(color: Color.modusCyan.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    // MARK: - Goal-Based Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Section Header with Goal
            HStack {
                Text("FOR YOUR GOALS")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.modusDeepTeal)

                Text("(\(viewModel.userGoal.displayName))")
                    .font(.caption)
                    .foregroundColor(.modusCyan)

                if viewModel.isGeneratingRecommendations {
                    ProgressView()
                        .scaleEffect(0.7)
                        .padding(.leading, Spacing.xs)
                }

                Spacer()

                Button {
                    showingGoalPicker = true
                } label: {
                    Image(systemName: "chevron.down.circle")
                        .foregroundColor(.modusCyan)
                }
                .accessibilityLabel("Change fitness goal")
                .accessibilityHint("Opens goal selection sheet")
            }
            .accessibilityElement(children: .combine)

            // Show loading overlay when generating recommendations
            if viewModel.isGeneratingRecommendations {
                VStack(spacing: Spacing.sm) {
                    ProgressView()
                    Text("Updating recommendations...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.md)
            } else {
                // Essential Recommendations (Strong Evidence)
                if !viewModel.essentialRecommendations.isEmpty {
                    RecommendationGroupView(
                        title: "ESSENTIAL",
                        subtitle: "Strong Evidence",
                        recommendations: Array(viewModel.essentialRecommendations.prefix(3)),
                        onAddToStack: { recommendation in
                            Task {
                                await viewModel.addRecommendationToStack(recommendation)
                            }
                        }
                    )
                }

                // Helpful Recommendations (Moderate Evidence)
                if !viewModel.helpfulRecommendations.isEmpty {
                    RecommendationGroupView(
                        title: "HELPFUL",
                        subtitle: "Moderate Evidence",
                        recommendations: Array(viewModel.helpfulRecommendations.prefix(2)),
                        onAddToStack: { recommendation in
                            Task {
                                await viewModel.addRecommendationToStack(recommendation)
                            }
                        }
                    )
                }

                // Empty state if no recommendations
                if viewModel.recommendations.isEmpty {
                    Text("No specific recommendations for this goal yet.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, Spacing.md)
                }
            }
        }
    }

    // MARK: - My Stack Section

    private var myStackSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("My Stack")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)

                Spacer()

                NavigationLink {
                    MySupplementRoutineView()
                } label: {
                    Text("Edit")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }
            }

            if viewModel.myStack.isEmpty {
                Text("No supplements in your stack yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing.md)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Spacing.sm) {
                    ForEach(viewModel.myStack.prefix(6)) { supplement in
                        SupplementStackItemView(supplement: supplement)
                    }
                }

                if viewModel.myStack.count > 6 {
                    NavigationLink {
                        MySupplementRoutineView()
                    } label: {
                        Text("View all \(viewModel.myStack.count) supplements")
                            .font(.caption)
                            .foregroundColor(.modusCyan)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
    }

    // MARK: - Stacks Navigation Section

    private var stacksNavigationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Explore Stacks")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            NavigationLink {
                SupplementStacksView()
            } label: {
                HStack {
                    Image(systemName: "square.stack.3d.up.fill")
                        .foregroundColor(.modusCyan)
                    Text("Browse Predefined Stacks")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.md)
            }

            NavigationLink {
                SupplementCatalogView()
            } label: {
                HStack {
                    Image(systemName: "books.vertical")
                        .foregroundColor(.modusTealAccent)
                    Text("Browse Supplement Catalog")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.md)
            }
        }
    }
}

// MARK: - Timing Group Card

private struct TimingGroupCard: View {
    let group: SupplementTimingGroup
    let items: [SupplementChecklistItem]
    let isComplete: Bool
    let isLoggingItem: UUID?
    let onToggleItem: (SupplementChecklistItem) -> Void
    let onSwipeLog: (SupplementChecklistItem) -> Void
    let onTapItem: (SupplementChecklistItem) -> Void
    let onLogAll: () -> Void

    private var completedItemsCount: Int {
        items.filter { $0.isTaken }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Group Header
            HStack {
                Image(systemName: group.icon)
                    .foregroundColor(.modusCyan)
                    .font(.caption)

                Text(group.displayName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.modusDeepTeal)

                Text("(\(group.subtitle))")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.modusTealAccent)
                        .font(.caption)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(group.displayName) supplements, \(group.subtitle), \(completedItemsCount) of \(items.count) taken\(isComplete ? ", all complete" : "")")

            // Supplement Items
            VStack(spacing: 0) {
                ForEach(items) { item in
                    SwipeableSupplementRow(
                        item: item,
                        isLogging: isLoggingItem == item.id,
                        onToggle: { onToggleItem(item) },
                        onSwipeLog: { onSwipeLog(item) },
                        onTap: { onTapItem(item) }
                    )

                    if item.id != items.last?.id {
                        Divider()
                            .padding(.leading, 40)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)

            // Log All Button for Group
            if !isComplete {
                Button(action: onLogAll) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Log All \(group.displayName)")
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                    .foregroundColor(.modusCyan)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.modusCyan.opacity(0.1))
                    .cornerRadius(CornerRadius.sm)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Swipeable Supplement Row

private struct SwipeableSupplementRow: View {
    let item: SupplementChecklistItem
    let isLogging: Bool
    let onToggle: () -> Void
    let onSwipeLog: () -> Void
    let onTap: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isSwiping = false

    private let swipeThreshold: CGFloat = -80

    var body: some View {
        ZStack {
            // Swipe Background (Log action)
            HStack {
                Spacer()

                if !item.isTaken {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("LOG")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.lg)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(item.isTaken ? Color.gray : Color.modusTealAccent)

            // Main Content
            HStack(spacing: Spacing.sm) {
                // Checkbox with smooth animation
                Button(action: onToggle) {
                    ZStack {
                        Circle()
                            .stroke(item.isTaken ? Color.modusTealAccent : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)

                        Circle()
                            .fill(Color.modusTealAccent)
                            .frame(width: 24, height: 24)
                            .scaleEffect(item.isTaken ? 1.0 : 0.0)

                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .scaleEffect(item.isTaken ? 1.0 : 0.0)
                            .opacity(item.isTaken ? 1.0 : 0.0)

                        if isLogging {
                            ProgressView()
                                .scaleEffect(0.6)
                                .tint(.modusCyan)
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: item.isTaken)
                }
                .buttonStyle(.plain)
                .disabled(isLogging)
                .accessibilityLabel(item.isTaken ? "Mark \(item.supplement.name) as not taken" : "Mark \(item.supplement.name) as taken")
                .accessibilityHint(item.isTaken ? "Double tap to undo logging this supplement" : "Double tap to log this supplement as taken")

                // Supplement Info
                Button(action: onTap) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.supplement.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(item.isTaken ? .secondary : .primary)
                                .strikethrough(item.isTaken)

                            Text(item.dosage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if !item.isTaken {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(item.supplement.name), \(item.dosage), \(item.isTaken ? "taken" : "not yet taken")")
                .accessibilityHint("Double tap to open logging options")
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard !item.isTaken else { return }
                        if value.translation.width < 0 {
                            offset = value.translation.width
                            isSwiping = true
                        }
                    }
                    .onEnded { value in
                        guard !item.isTaken else { return }
                        if value.translation.width < swipeThreshold {
                            // Trigger log action
                            withAnimation(.spring(response: 0.3)) {
                                offset = -((UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.width ?? 400)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onSwipeLog()
                                withAnimation(.spring(response: 0.3)) {
                                    offset = 0
                                }
                            }
                        } else {
                            withAnimation(.spring(response: 0.3)) {
                                offset = 0
                            }
                        }
                        isSwiping = false
                    }
            )
        }
        .clipped()
    }
}

// MARK: - Recommendation Group View

private struct RecommendationGroupView: View {
    let title: String
    let subtitle: String
    let recommendations: [GoalBasedRecommendation]
    let onAddToStack: (GoalBasedRecommendation) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Group Title
            HStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.modusDeepTeal)

                Text("(\(subtitle))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Recommendation Items
            ForEach(recommendations) { recommendation in
                RecommendationRowView(
                    recommendation: recommendation,
                    onAdd: { onAddToStack(recommendation) }
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Recommendation Row View

private struct RecommendationRowView: View {
    let recommendation: GoalBasedRecommendation
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Status Icon
            Image(systemName: recommendation.isInStack ? "checkmark.circle.fill" : "circle")
                .foregroundColor(recommendation.isInStack ? .modusTealAccent : .gray)
                .font(.subheadline)
                .accessibilityHidden(true)

            // Supplement Info
            VStack(alignment: .leading, spacing: 2) {
                Text(recommendation.supplementName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(recommendation.benefit)
                    .font(.caption)
                    .foregroundColor(.modusCyan)
            }

            Spacer()

            // Add Button (if not in stack)
            if !recommendation.isInStack {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.modusCyan)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add \(recommendation.supplementName) to your stack")
                .accessibilityHint("Double tap to add this supplement to your daily routine")
            }
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recommendation.supplementName), \(recommendation.benefit), \(recommendation.evidenceGrade.displayName) evidence\(recommendation.isInStack ? ", already in your stack" : "")")
        .accessibilityHint(recommendation.isInStack ? "" : "Double tap to add to your stack")
    }
}

// MARK: - Supplement Stack Item View

private struct SupplementStackItemView: View {
    let supplement: RoutineSupplement

    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.modusCyan.opacity(0.2), .modusTealAccent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: supplement.category.icon)
                    .font(.body)
                    .foregroundColor(.modusCyan)
            }
            .accessibilityHidden(true)

            Text(supplement.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(supplement.displayName), \(supplement.category.rawValue) supplement")
    }
}

// MARK: - Goal Picker Sheet

private struct GoalPickerSheet: View {
    @Binding var selectedGoal: UserGoal
    @Environment(\.dismiss) private var dismiss
    let onSelect: (UserGoal) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(UserGoal.allCases) { goal in
                    Button {
                        onSelect(goal)
                    } label: {
                        HStack {
                            Image(systemName: goal.icon)
                                .foregroundColor(.modusCyan)
                                .frame(width: 30)

                            Text(goal.displayName)
                                .foregroundColor(.primary)

                            Spacer()

                            if goal == selectedGoal {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.modusTealAccent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Your Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Supplement Detail View with Evidence Grade

struct SupplementDetailWithEvidenceView: View {
    let supplement: CatalogSupplement
    @Environment(\.dismiss) private var dismiss
    @State private var isAddingToStack = false
    @State private var addError: String?
    @State private var showAddError = false

    private let service = SupplementService.shared

    private var evidenceGrade: EvidenceGrade {
        EvidenceGrade.from(supplement.evidenceRating)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Header
                headerSection

                // Evidence Grade
                evidenceGradeSection

                // Goal Benefits
                goalBenefitsSection

                // Dosage & Timing
                dosageTimingSection

                // Add to Stack Button
                addToStackButton
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(supplement.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(supplement.name.uppercased())
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)

                if let brand = supplement.brand {
                    Text(brand)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(Color.modusCyan.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: supplement.category.icon)
                    .font(.title2)
                    .foregroundColor(.modusCyan)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private var evidenceGradeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Evidence Grade:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    Image(systemName: index < evidenceGrade.starCount ? "star.fill" : "star")
                        .foregroundColor(index < evidenceGrade.starCount ? .yellow : .gray.opacity(0.3))
                }

                Text("(\(evidenceGrade.displayName))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(evidenceGrade.color)
                    .padding(.leading, Spacing.xs)
            }

            Text(evidenceGrade.fullDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private var goalBenefitsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("FOR YOUR GOALS:")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.modusDeepTeal)

            ForEach(supplement.benefits.prefix(4), id: \.self) { benefit in
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.modusTealAccent)
                        .font(.caption)

                    Text(benefit)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private var dosageTimingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Dosage
            HStack {
                Text("DOSAGE:")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.modusDeepTeal)

                Text(supplement.dosageRange)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            // Timing
            HStack(alignment: .top) {
                Text("TIMING:")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.modusDeepTeal)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(supplement.timing) { timing in
                        Label(timing.displayName, systemImage: timing.icon)
                            .font(.caption)
                            .foregroundColor(.modusCyan)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private var addToStackButton: some View {
        Button {
            isAddingToStack = true
            Task {
                do {
                    try await service.addToRoutine(
                        supplementId: supplement.id,
                        supplementName: supplement.name,
                        brand: supplement.brand,
                        category: supplement.category,
                        dosage: supplement.dosageRange,
                        timing: supplement.timing.first ?? .morning
                    )
                    HapticFeedback.success()
                    isAddingToStack = false
                    dismiss()
                } catch {
                    isAddingToStack = false
                    addError = error.localizedDescription
                    showAddError = true
                    HapticFeedback.error()
                }
            }
        } label: {
            HStack {
                if isAddingToStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Add to My Stack")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
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
        .disabled(isAddingToStack)
        .alert("Error", isPresented: $showAddError) {
            Button("OK") { }
        } message: {
            Text(addError ?? "Failed to add supplement")
        }
    }
}

// MARK: - Preview

#if DEBUG
struct SupplementDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        SupplementDashboardView()
            .previewDisplayName("Supplement Dashboard")
    }
}
#endif
