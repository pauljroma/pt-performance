// DARK MODE: See ModeThemeModifier.swift for central theme control
import SwiftUI

/// Supplement Stacks View - Browse and add pre-built supplement stacks
struct SupplementStacksView: View {
    @StateObject private var viewModel = SupplementStacksViewModel()
    @Environment(\.colorScheme) private var colorScheme

    @State private var showAddSuccess = false
    @State private var addedStackName = ""

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.stacks.isEmpty {
                    ProgressView("Loading stacks...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.stacks.isEmpty {
                    emptyView
                } else {
                    stacksList
                }
            }
            .navigationTitle("Supplement Stacks")
            .task {
                await viewModel.loadData()
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .alert("Stack Added", isPresented: $showAddSuccess) {
                Button("OK") { }
            } message: {
                Text("\(addedStackName) has been added to your routine.")
            }
        }
    }

    private var stacksList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(viewModel.stacks) { stack in
                    StackCard(stack: stack) {
                        Task {
                            await viewModel.addStackToRoutine(stack)
                            if viewModel.error == nil {
                                addedStackName = stack.name
                                showAddSuccess = true
                                HapticFeedback.success()
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var emptyView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text("No stacks available")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Pre-built supplement stacks will appear here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Stack Card

private struct StackCard: View {
    let stack: SupplementStack
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stack.name)
                        .font(.headline)
                        .foregroundColor(.modusDeepTeal)

                    Text(stack.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "square.stack.3d.up.fill")
                    .font(.title2)
                    .foregroundColor(.modusCyan)
            }

            // Items
            if !stack.items.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(stack.items.prefix(3)) { item in
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.modusTealAccent)

                            Text(item.supplementName)
                                .font(.caption)
                                .foregroundColor(.primary)

                            Spacer()

                            Text(item.dosage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if stack.items.count > 3 {
                        Text("+ \(stack.items.count - 3) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, Spacing.xs)
            }

            // Add Button
            Button(action: onAdd) {
                Text("Add Stack to Routine")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.modusCyan)
                    .cornerRadius(CornerRadius.md)
            }
            .accessibilityLabel("Add \(stack.name) stack to routine")
            .accessibilityHint("Double tap to add all \(stack.items.count) supplements in this stack")
            .padding(.top, Spacing.xs)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(stack.name) stack, \(stack.items.count) supplements")
    }
}

#if DEBUG
struct SupplementStacksView_Previews: PreviewProvider {
    static var previews: some View {
        SupplementStacksView()
    }
}
#endif
