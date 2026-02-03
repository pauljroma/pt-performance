import SwiftUI

struct RecoveryView: View {
    @StateObject private var viewModel = RecoveryViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Weekly Stats Card
                    weeklyStatsCard

                    // Recommendations
                    if !viewModel.recommendations.isEmpty {
                        recommendationsSection
                    }

                    // Protocol Buttons
                    protocolGrid

                    // Recent Sessions
                    if !viewModel.sessions.isEmpty {
                        recentSessionsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Recovery")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingLogSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingLogSheet) {
                LogRecoverySessionSheet(viewModel: viewModel)
            }
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
        }
    }

    private var weeklyStatsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("This Week")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 24) {
                RecoveryStatItem(
                    value: "\(viewModel.weeklyStats.sessions)",
                    label: "Sessions",
                    icon: "figure.mind.and.body"
                )

                RecoveryStatItem(
                    value: "\(viewModel.weeklyStats.minutes)",
                    label: "Minutes",
                    icon: "clock"
                )

                if let favorite = viewModel.weeklyStats.favorite {
                    RecoveryStatItem(
                        value: favorite.displayName,
                        label: "Favorite",
                        icon: favorite.icon
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended Today")
                .font(.headline)

            ForEach(viewModel.recommendations) { rec in
                RecommendationCard(recommendation: rec) {
                    viewModel.selectedProtocol = rec.protocolType
                    viewModel.logDuration = rec.suggestedDuration
                    viewModel.showingLogSheet = true
                }
            }
        }
    }

    private var protocolGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recovery Protocols")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(RecoveryProtocolType.allCases, id: \.self) { protocol_ in
                    ProtocolButton(protocol_: protocol_) {
                        viewModel.selectedProtocol = protocol_
                        viewModel.showingLogSheet = true
                    }
                }
            }
        }
    }

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)

            ForEach(viewModel.sessions.prefix(5)) { session in
                RecoverySessionRow(session: session)
            }
        }
    }
}

struct RecoveryStatItem: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RecommendationCard: View {
    let recommendation: RecoveryRecommendation
    let action: () -> Void

    var body: some View {
        HStack {
            Image(systemName: recommendation.protocolType.icon)
                .font(.title2)
                .foregroundColor(priorityColor)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.protocolType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(recommendation.reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(recommendation.suggestedDuration) min suggested")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }

            Spacer()

            Button("Log", action: action)
                .buttonStyle(.bordered)
        }
        .padding()
        .background(priorityColor.opacity(0.1))
        .cornerRadius(12)
    }

    private var priorityColor: Color {
        switch recommendation.priority {
        case .high: return .orange
        case .medium: return .blue
        case .low: return .green
        }
    }
}

struct ProtocolButton: View {
    let protocol_: RecoveryProtocolType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: protocol_.icon)
                    .font(.title)
                Text(protocol_.displayName)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct RecoverySessionRow: View {
    let session: RecoverySession

    var body: some View {
        HStack {
            Image(systemName: session.protocolType.icon)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.protocolType.displayName)
                    .font(.subheadline)
                Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(session.duration / 60) min")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct LogRecoverySessionSheet: View {
    @ObservedObject var viewModel: RecoveryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Protocol") {
                    Picker("Type", selection: $viewModel.selectedProtocol) {
                        ForEach(RecoveryProtocolType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                }

                Section("Duration") {
                    Stepper("\(viewModel.logDuration) minutes", value: $viewModel.logDuration, in: 1...120)
                }

                Section("Optional Details") {
                    if viewModel.selectedProtocol == .sauna {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            TextField("°F", value: $viewModel.logTemperature, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                        }
                    }

                    if viewModel.selectedProtocol == .coldPlunge {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            TextField("°F", value: $viewModel.logTemperature, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                        }
                    }

                    Stepper("Effort: \(viewModel.logEffort)/10", value: $viewModel.logEffort, in: 1...10)

                    TextField("Notes", text: $viewModel.logNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.logSession()
                        }
                    }
                }
            }
        }
    }
}
