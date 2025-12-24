import SwiftUI

/// Main block card component with 1-tap completion and adaptive UI
struct BlockCard: View {
    @Binding var block: Block
    let onBlockComplete: (Block) -> Void
    let onSetComplete: (UUID, CompletedSet) -> Void
    let onQuickAdjust: (UUID, String, Double) -> Void
    let onPainReport: (UUID, Int, String?) -> Void

    @State private var isExpanded = false
    @State private var showCompleteConfirmation = false
    @State private var completionAnimating = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with tap to expand
            BlockHeader(block: block) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }

            // Expandable content
            if isExpanded && !block.isCompleted {
                VStack(spacing: 12) {
                    Divider()
                        .padding(.horizontal, 16)

                    // 1-tap completion button
                    OneTabCompleteButton(
                        block: block,
                        isAnimating: $completionAnimating
                    ) {
                        handleOneTabComplete()
                    }
                    .padding(.horizontal, 16)

                    // Items list
                    VStack(spacing: 12) {
                        ForEach(block.items.indices, id: \.self) { index in
                            BlockItemRow(
                                item: bindingForItem(at: index),
                                onSetComplete: { completedSet in
                                    handleSetComplete(itemId: block.items[index].id, set: completedSet)
                                },
                                onQuickAdjustLoad: { delta in
                                    onQuickAdjust(block.items[index].id, "load", delta)
                                },
                                onQuickAdjustReps: { delta in
                                    onQuickAdjust(block.items[index].id, "reps", Double(delta))
                                },
                                onPainReport: { level, location in
                                    onPainReport(block.items[index].id, level, location)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // Completed state
            if block.isCompleted {
                CompletedBlockView(block: block)
                    .padding(16)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(block.blockType.color.opacity(0.3), lineWidth: 2)
        )
        .alert("Complete Block?", isPresented: $showCompleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Complete", role: .destructive) {
                performOneTabComplete()
            }
        } message: {
            Text("This will log all exercises as prescribed. You can adjust individual sets afterwards.")
        }
    }

    // MARK: - Actions

    private func handleOneTabComplete() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Show confirmation
        showCompleteConfirmation = true
    }

    private func performOneTabComplete() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            completionAnimating = true

            // Complete block
            var updatedBlock = block
            updatedBlock.completeAsPrescribed()
            block = updatedBlock

            // Notify parent
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onBlockComplete(updatedBlock)
                completionAnimating = false
                isExpanded = false
            }
        }

        // Success haptic
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }

    private func handleSetComplete(itemId: UUID, set: CompletedSet) {
        onSetComplete(itemId, set)

        // Light haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        // Check if block is now complete
        if block.items.allSatisfy({ $0.isCompleted }) {
            var updatedBlock = block
            updatedBlock.isCompleted = true
            updatedBlock.completedAt = Date()
            block = updatedBlock
            onBlockComplete(updatedBlock)
        }
    }

    private func bindingForItem(at index: Int) -> Binding<BlockItem> {
        Binding(
            get: { block.items[index] },
            set: { newValue in
                block.items[index] = newValue
            }
        )
    }
}

// MARK: - One-Tap Complete Button

struct OneTabCompleteButton: View {
    let block: Block
    @Binding var isAnimating: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isAnimating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 18, weight: .bold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Complete as Prescribed")
                        .font(.system(size: 16, weight: .bold))

                    Text("Logs all \(block.totalSets) sets in <2 seconds")
                        .font(.system(size: 12, weight: .medium))
                        .opacity(0.9)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        block.blockType.color,
                        block.blockType.color.opacity(0.8)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: block.blockType.color.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .disabled(isAnimating)
        .scaleEffect(isAnimating ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
    }
}

// MARK: - Completed Block View

struct CompletedBlockView: View {
    let block: Block

    private var metrics: QuickMetrics {
        QuickMetrics.from(blocks: [block])
    }

    var body: some View {
        VStack(spacing: 16) {
            // Completion message
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Block Complete!")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    if let completedAt = block.completedAt {
                        Text(completedAt, style: .time)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            // Quick metrics summary
            QuickMetricsSummary(metrics: metrics, compact: true)
                .background(Color(.systemGray6))
                .cornerRadius(12)

            // View details button
            Button(action: {
                // Navigate to detailed view
            }) {
                HStack {
                    Text("View Details")
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(block.blockType.color)
            }
        }
    }
}

// MARK: - Preview

struct BlockCard_Previews: PreviewProvider {
    static var sampleBlock: Block {
        Block(
            id: UUID(),
            sessionId: UUID(),
            blockType: .mainWork,
            title: "Main Work - Back Squat",
            orderIndex: 1,
            items: [
                BlockItem(
                    id: UUID(),
                    blockId: UUID(),
                    exerciseId: UUID(),
                    exerciseName: "Back Squat",
                    orderIndex: 0,
                    prescribedSets: 5,
                    prescribedReps: "5",
                    prescribedLoad: 225,
                    prescribedRPE: 8,
                    tempo: "3-1-1-0",
                    notes: "Focus on depth and bar speed",
                    completedSets: [
                        CompletedSet(setNumber: 1, actualReps: 5, actualLoad: 225, actualRPE: 7, completedAt: Date())
                    ]
                ),
                BlockItem(
                    id: UUID(),
                    blockId: UUID(),
                    exerciseId: UUID(),
                    exerciseName: "Front Squat",
                    orderIndex: 1,
                    prescribedSets: 3,
                    prescribedReps: "8",
                    prescribedLoad: 185,
                    prescribedRPE: 7,
                    completedSets: []
                )
            ],
            isCompleted: false
        )
    }

    static var completedBlock: Block {
        var block = sampleBlock
        block.completeAsPrescribed()
        return block
    }

    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                // In progress
                BlockCard(
                    block: .constant(sampleBlock),
                    onBlockComplete: { _ in },
                    onSetComplete: { _, _ in },
                    onQuickAdjust: { _, _, _ in },
                    onPainReport: { _, _, _ in }
                )

                // Completed
                BlockCard(
                    block: .constant(completedBlock),
                    onBlockComplete: { _ in },
                    onSetComplete: { _, _ in },
                    onQuickAdjust: { _, _, _ in },
                    onPainReport: { _, _, _ in }
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}
