import SwiftUI

/// Main Supplement Dashboard View
/// Displays today's checklist, quick-log, compliance progress, and "My Stack"
struct SupplementDashboardView: View {
    @StateObject private var viewModel = SupplementDashboardViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingQuickLog = false
    @State private var showingRoutineEditor = false

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
                        Task {
                            await viewModel.saveLog(log)
                        }
                    }
                )
            }
            .sheet(isPresented: $showingRoutineEditor) {
                MySupplementRoutineView()
            }
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
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

                // Today's Checklist
                todayChecklistSection

                // Quick Log Button
                quickLogButton

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
                Text("\(viewModel.currentStreak) day streak")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("Best: \(viewModel.bestStreak) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Today's Checklist Section

    private var todayChecklistSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Today's Checklist")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)

                Spacer()

                if !viewModel.todayChecklist.isEmpty {
                    Button {
                        HapticFeedback.light()
                        viewModel.markAllAsTaken()
                    } label: {
                        Text("Take All")
                            .font(.caption)
                            .foregroundColor(.modusCyan)
                    }
                    .accessibilityLabel("Mark all supplements as taken")
                }
            }

            if viewModel.todayChecklist.isEmpty {
                emptyChecklistView
            } else {
                ForEach(viewModel.todayChecklist) { item in
                    SupplementChecklistRow(
                        item: item,
                        onToggle: {
                            HapticFeedback.light()
                            viewModel.toggleItem(item)
                        },
                        onTap: {
                            viewModel.selectedSupplementForLog = item.supplement
                            showingQuickLog = true
                        }
                    )
                }
            }
        }
    }

    private var emptyChecklistView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "pills")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Supplements Scheduled")
                .font(.subheadline)
                .fontWeight(.medium)

            Text("Add supplements to your routine to see them here.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingRoutineEditor = true
            } label: {
                Text("Set Up Routine")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        LinearGradient(
                            colors: [.modusCyan, .modusTealAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(CornerRadius.md)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
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

// MARK: - Supplement Checklist Row

private struct SupplementChecklistRow: View {
    let item: SupplementChecklistItem
    let onToggle: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Checkbox
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(item.isTaken ? Color.modusTealAccent : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if item.isTaken {
                        Circle()
                            .fill(Color.modusTealAccent)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isTaken ? "Mark \(item.supplement.name) as not taken" : "Mark \(item.supplement.name) as taken")

            // Supplement Info
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.supplement.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(item.isTaken ? .secondary : .primary)
                            .strikethrough(item.isTaken)

                        HStack(spacing: Spacing.xs) {
                            Text(item.dosage)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("•")
                                .foregroundColor(.secondary)
                            Text(item.timing.displayName)
                                .font(.caption)
                                .foregroundColor(.modusCyan)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
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
