//
//  WatchWorkoutListView.swift
//  PTPerformanceWatch
//
//  Main workout list view showing today's scheduled sessions
//  ACP-824: Apple Watch Standalone App
//

import SwiftUI

struct WatchWorkoutListView: View {
    @ObservedObject var viewModel: WatchWorkoutViewModel
    @EnvironmentObject var sessionManager: WatchSessionManager

    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.todaysSessions.isEmpty {
                emptyStateView
            } else {
                sessionListView
            }
        }
        .navigationTitle("Today")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await viewModel.refreshSessions()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            await viewModel.loadTodaysSessions()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
            Text("Loading...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 40))
                .foregroundStyle(.modusCyan)

            Text("No Workouts Today")
                .font(.headline)

            Text("Rest day or check your schedule")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Session List View

    private var sessionListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.todaysSessions) { session in
                    NavigationLink(destination: WatchWorkoutExecutionView(session: session, viewModel: viewModel)) {
                        WatchSessionRow(session: session)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Watch Session Row

struct WatchSessionRow: View {
    let session: WatchWorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.name)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                statusIcon
            }

            HStack {
                Text(session.formattedTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(session.totalExercises) exercises")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if session.status == .inProgress {
                progressBar
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.darkGray).opacity(0.5))
        )
    }

    private var statusIcon: some View {
        Group {
            switch session.status {
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .inProgress:
                Image(systemName: "play.circle.fill")
                    .foregroundStyle(.modusCyan)
            case .scheduled:
                Image(systemName: "clock")
                    .foregroundStyle(.orange)
            case .cancelled:
                Image(systemName: "xmark.circle")
                    .foregroundStyle(.red)
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)

                Rectangle()
                    .fill(Color.modusCyan)
                    .frame(width: geometry.size.width * session.progressPercentage, height: 4)
            }
            .clipShape(Capsule())
        }
        .frame(height: 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WatchWorkoutListView(viewModel: WatchWorkoutViewModel())
            .environmentObject(WatchSessionManager.shared)
    }
}
