import SwiftUI

/// Header component for block cards displaying type, progress, and status
struct BlockHeader: View {
    let block: Block
    let onExpand: (() -> Void)?

    init(block: Block, onExpand: (() -> Void)? = nil) {
        self.block = block
        self.onExpand = onExpand
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Block type icon with colored background
                ZStack {
                    Circle()
                        .fill(block.blockType.backgroundColor)
                        .frame(width: 44, height: 44)

                    Image(systemName: block.blockType.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(block.blockType.color)
                }

                // Block title and status
                VStack(alignment: .leading, spacing: 4) {
                    Text(block.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        // Block type badge
                        Text(block.blockType.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(block.blockType.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(block.blockType.backgroundColor)
                            .cornerRadius(6)

                        // Sets progress
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            Text("\(block.completedSets)/\(block.totalSets)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        // Estimated time
                        if block.estimatedTimeMinutes > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)

                                Text("\(block.estimatedTimeMinutes)m")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Pain flag indicator
                        if block.hasPainFlags {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }

                Spacer()

                // Completion status
                if block.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                } else if onExpand != nil {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(0)) // Can be animated
                }
            }

            // Progress bar
            ProgressBar(progress: block.progress, color: block.blockType.color)
                .frame(height: 6)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
        .onTapGesture {
            onExpand?()
        }
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray5))

                // Progress fill
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(min(max(progress, 0), 1)))
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
    }
}

// MARK: - Preview

struct BlockHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Warmup block - in progress
            BlockHeader(
                block: Block(
                    id: UUID(),
                    sessionId: UUID(),
                    blockType: .warmup,
                    title: "Warm-up",
                    orderIndex: 0,
                    items: [
                        BlockItem(
                            id: UUID(),
                            blockId: UUID(),
                            exerciseId: UUID(),
                            exerciseName: "Band Pull-Aparts",
                            orderIndex: 0,
                            prescribedSets: 3,
                            prescribedReps: "15",
                            completedSets: [
                                CompletedSet(
                                    setNumber: 1,
                                    actualReps: 15,
                                    completedAt: Date()
                                )
                            ]
                        )
                    ],
                    isCompleted: false
                ),
                onExpand: {}
            )

            // Main work - with pain flag
            BlockHeader(
                block: Block(
                    id: UUID(),
                    sessionId: UUID(),
                    blockType: .mainWork,
                    title: "Main Work",
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
                            completedSets: [
                                CompletedSet(
                                    setNumber: 1,
                                    actualReps: 5,
                                    actualLoad: 225,
                                    actualRPE: 7,
                                    painLevel: 3,
                                    painLocation: "Right knee",
                                    completedAt: Date()
                                )
                            ]
                        )
                    ],
                    isCompleted: false
                ),
                onExpand: {}
            )

            // Accessories - completed
            BlockHeader(
                block: Block(
                    id: UUID(),
                    sessionId: UUID(),
                    blockType: .accessories,
                    title: "Accessories",
                    orderIndex: 2,
                    items: [
                        BlockItem(
                            id: UUID(),
                            blockId: UUID(),
                            exerciseId: UUID(),
                            exerciseName: "Leg Curls",
                            orderIndex: 0,
                            prescribedSets: 3,
                            prescribedReps: "12",
                            completedSets: [
                                CompletedSet(setNumber: 1, actualReps: 12, completedAt: Date()),
                                CompletedSet(setNumber: 2, actualReps: 12, completedAt: Date()),
                                CompletedSet(setNumber: 3, actualReps: 12, completedAt: Date())
                            ],
                            isCompleted: true,
                            completedAt: Date()
                        )
                    ],
                    isCompleted: true,
                    completedAt: Date()
                )
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
