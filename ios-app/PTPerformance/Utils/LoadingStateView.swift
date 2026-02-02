import SwiftUI

/// Reusable skeleton loading view with shimmer animation
/// Build 60: UX Polish - Loading states
struct LoadingStateView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<5) { _ in
                SkeletonCard()
            }
        }
        .padding()
    }
}

/// Skeleton card component with shimmer effect
struct SkeletonCard: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header skeleton
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .shimmer(isAnimating: isAnimating)

                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 150, height: 16)
                        .shimmer(isAnimating: isAnimating)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 12)
                        .shimmer(isAnimating: isAnimating)
                }

                Spacer()
            }

            // Content skeleton
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 12)
                    .shimmer(isAnimating: isAnimating)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 12)
                    .shimmer(isAnimating: isAnimating)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

/// Skeleton list row component
struct SkeletonListRow: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .shimmer(isAnimating: isAnimating)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 14)
                    .shimmer(isAnimating: isAnimating)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 10)
                    .shimmer(isAnimating: isAnimating)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 10)
                .shimmer(isAnimating: isAnimating)
        }
        .padding(.vertical, 8)
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

/// Shimmer effect modifier
struct ShimmerModifier: ViewModifier {
    let isAnimating: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .white.opacity(0.5),
                        .clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: isAnimating ? 300 : -300)
                .mask(content)
            )
    }
}

extension View {
    func shimmer(isAnimating: Bool) -> some View {
        modifier(ShimmerModifier(isAnimating: isAnimating))
    }
}

// MARK: - Specialized Loading Views

/// Loading state for session list
struct SessionListLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<3) { _ in
                SkeletonCard()
            }
        }
        .padding()
    }
}

/// Loading state for patient list
struct PatientListLoadingView: View {
    var body: some View {
        List {
            ForEach(0..<8) { _ in
                SkeletonListRow()
            }
        }
        .listStyle(.plain)
    }
}

/// Loading state for chart/analytics
struct ChartLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 150, height: 20)
                .shimmer(isAnimating: isAnimating)

            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200)
                .shimmer(isAnimating: isAnimating)
        }
        .padding()
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Today Session Loading View

/// Loading state for TodaySessionView with skeleton header, session card, and exercise list
struct TodaySessionLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Skeleton for completed workouts counter (optional section)
                skeletonCompletedSection

                // Skeleton for readiness section
                skeletonReadinessSection

                // Skeleton for session card
                skeletonSessionCard

                Spacer()
            }
            .padding()
        }
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }

    // MARK: - Skeleton Completed Section

    private var skeletonCompletedSection: some View {
        HStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 28, height: 28)
                .shimmer(isAnimating: isAnimating)

            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 180, height: 16)
                    .shimmer(isAnimating: isAnimating)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 12)
                    .shimmer(isAnimating: isAnimating)
            }

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Skeleton Readiness Section

    private var skeletonReadinessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section title skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 120, height: 16)
                .shimmer(isAnimating: isAnimating)

            HStack(spacing: 16) {
                // Score circle skeleton
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 64, height: 64)
                    .shimmer(isAnimating: isAnimating)

                // Category and recommendation skeleton
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 18)
                        .shimmer(isAnimating: isAnimating)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 200, height: 14)
                        .shimmer(isAnimating: isAnimating)
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 1)
        )
    }

    // MARK: - Skeleton Session Card

    private var skeletonSessionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Session Info Header
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 12)
                        .shimmer(isAnimating: isAnimating)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 180, height: 24)
                        .shimmer(isAnimating: isAnimating)
                }

                Spacer()

                // Exercise count badge skeleton
                VStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 32)
                        .shimmer(isAnimating: isAnimating)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 12)
                        .shimmer(isAnimating: isAnimating)
                }
            }

            // Exercise preview skeleton (3-4 rows)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                            .shimmer(isAnimating: isAnimating)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 140, height: 14)
                            .shimmer(isAnimating: isAnimating)

                        Spacer()

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 12)
                            .shimmer(isAnimating: isAnimating)
                    }
                }
            }
            .padding(.vertical, 8)

            // Divider skeleton
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)

            // Start Workout Button skeleton
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 56)
                .shimmer(isAnimating: isAnimating)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .adaptiveShadow(Shadow.medium)
    }
}

// MARK: - Goals Loading View

/// Loading state for PatientGoalsView with skeleton progress summary and goal rows
struct GoalsLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        List {
            // Summary Card Skeleton
            Section {
                skeletonSummaryCard
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            // Filter Picker Skeleton
            Section {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 32)
                    .shimmer(isAnimating: isAnimating)
            }
            .listRowBackground(Color.clear)

            // Goal Rows Skeleton
            Section {
                ForEach(0..<3, id: \.self) { _ in
                    skeletonGoalRow
                }
            } header: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 12)
                    .shimmer(isAnimating: isAnimating)
            }
        }
        .listStyle(.insetGrouped)
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }

    // MARK: - Skeleton Summary Card

    private var skeletonSummaryCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                // Circular Progress Ring skeleton
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .shimmer(isAnimating: isAnimating)

                // Stats skeleton
                VStack(alignment: .leading, spacing: 10) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 150, height: 18)
                        .shimmer(isAnimating: isAnimating)

                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 70, height: 14)
                            .shimmer(isAnimating: isAnimating)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 14)
                            .shimmer(isAnimating: isAnimating)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .adaptiveShadow(Shadow.medium)
        )
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Skeleton Goal Row

    private var skeletonGoalRow: some View {
        HStack(spacing: 12) {
            // Category Icon skeleton
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .shimmer(isAnimating: isAnimating)

            // Content skeleton
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 16)
                    .shimmer(isAnimating: isAnimating)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 12)
                    .shimmer(isAnimating: isAnimating)

                // Progress Bar skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)
                    .shimmer(isAnimating: isAnimating)

                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 10)
                        .shimmer(isAnimating: isAnimating)

                    Spacer()

                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 70, height: 18)
                        .shimmer(isAnimating: isAnimating)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Nutrition Dashboard Loading View

/// Loading state for NutritionDashboardView with skeleton progress cards and meal sections
struct NutritionDashboardLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Today's Progress Card skeleton
                skeletonProgressCard

                // AI Suggestion Card skeleton
                skeletonAISuggestionCard

                // Macro Distribution skeleton
                skeletonMacroCard

                // Quick Log Section skeleton
                skeletonQuickLogSection

                // Today's Meals skeleton
                skeletonMealsSection

                // Weekly Trend skeleton
                skeletonWeeklyTrendSection
            }
            .padding()
        }
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }

    // MARK: - Skeleton Progress Card

    private var skeletonProgressCard: some View {
        VStack(spacing: 16) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 130, height: 18)
                    .shimmer(isAnimating: isAnimating)
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 14)
                    .shimmer(isAnimating: isAnimating)
            }

            // Calorie Progress skeleton
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 14)
                        .shimmer(isAnimating: isAnimating)
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 14)
                        .shimmer(isAnimating: isAnimating)
                }

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 8)
                    .shimmer(isAnimating: isAnimating)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 12)
                    .shimmer(isAnimating: isAnimating)
            }

            // Protein Progress skeleton
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 14)
                        .shimmer(isAnimating: isAnimating)
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 14)
                        .shimmer(isAnimating: isAnimating)
                }

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 8)
                    .shimmer(isAnimating: isAnimating)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 12)
                    .shimmer(isAnimating: isAnimating)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Skeleton AI Suggestion Card

    private var skeletonAISuggestionCard: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .shimmer(isAnimating: isAnimating)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 140, height: 16)
                    .shimmer(isAnimating: isAnimating)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 220, height: 12)
                    .shimmer(isAnimating: isAnimating)
            }

            Spacer()

            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 16, height: 16)
                .shimmer(isAnimating: isAnimating)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Skeleton Macro Card

    private var skeletonMacroCard: some View {
        VStack(spacing: 12) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 16)
                    .shimmer(isAnimating: isAnimating)
                Spacer()
            }

            HStack(spacing: 20) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .shimmer(isAnimating: isAnimating)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 12)
                            .shimmer(isAnimating: isAnimating)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 30, height: 10)
                            .shimmer(isAnimating: isAnimating)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Skeleton Quick Log Section

    private var skeletonQuickLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 16)
                .shimmer(isAnimating: isAnimating)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 70)
                            .shimmer(isAnimating: isAnimating)
                    }
                }
            }
        }
    }

    // MARK: - Skeleton Meals Section

    private var skeletonMealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 110, height: 16)
                    .shimmer(isAnimating: isAnimating)
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 12)
                    .shimmer(isAnimating: isAnimating)
            }

            ForEach(0..<3, id: \.self) { _ in
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 20, height: 20)
                                .shimmer(isAnimating: isAnimating)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 80, height: 14)
                                .shimmer(isAnimating: isAnimating)

                            Spacer()

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 12)
                                .shimmer(isAnimating: isAnimating)
                        }

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 150, height: 12)
                            .shimmer(isAnimating: isAnimating)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Skeleton Weekly Trend Section

    private var skeletonWeeklyTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 16)
                .shimmer(isAnimating: isAnimating)

            ForEach(0..<2, id: \.self) { _ in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 14)
                            .shimmer(isAnimating: isAnimating)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 90, height: 12)
                            .shimmer(isAnimating: isAnimating)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 70, height: 14)
                            .shimmer(isAnimating: isAnimating)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 12)
                            .shimmer(isAnimating: isAnimating)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .adaptiveShadow(Shadow.subtle)
    }
}

// MARK: - Preview

#if DEBUG
struct LoadingStateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoadingStateView()
                .previewDisplayName("Skeleton Cards")

            PatientListLoadingView()
                .previewDisplayName("Patient List Loading")

            ChartLoadingView()
                .previewDisplayName("Chart Loading")

            SessionListLoadingView()
                .previewDisplayName("Session List Loading")

            TodaySessionLoadingView()
                .previewDisplayName("Today Session Loading")

            GoalsLoadingView()
                .previewDisplayName("Goals Loading")

            NutritionDashboardLoadingView()
                .previewDisplayName("Nutrition Dashboard Loading")
        }
    }
}
#endif
