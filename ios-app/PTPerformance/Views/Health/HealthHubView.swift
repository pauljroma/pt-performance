import SwiftUI

struct HealthHubView: View {
    @EnvironmentObject var storeKit: StoreKitService

    var body: some View {
        NavigationStack {
            if storeKit.isPremium {
                premiumContent
            } else {
                paywallContent
            }
        }
    }

    private var premiumContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Health Score Card
                HealthScoreCard()

                // Feature Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    HealthFeatureCard(
                        title: "Lab Results",
                        icon: "cross.case.fill",
                        color: .red,
                        destination: AnyView(LabResultsView())
                    )

                    HealthFeatureCard(
                        title: "Recovery",
                        icon: "heart.fill",
                        color: .pink,
                        destination: AnyView(RecoveryView())
                    )

                    HealthFeatureCard(
                        title: "Fasting",
                        icon: "fork.knife.circle.fill",
                        color: .green,
                        destination: AnyView(FastingView())
                    )

                    HealthFeatureCard(
                        title: "Supplements",
                        icon: "pill.fill",
                        color: .orange,
                        destination: AnyView(SupplementsView())
                    )
                }

                // AI Coach Card
                NavigationLink {
                    AIHealthCoachView()
                } label: {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.title)
                            .foregroundColor(.purple)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI Health Coach")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Get personalized health insights")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(16)
                }
            }
            .padding()
        }
        .navigationTitle("Health")
    }

    private var paywallContent: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)

            Text("Health Intelligence")
                .font(.title)
                .fontWeight(.bold)

            Text("Unlock premium features to track your labs, recovery protocols, fasting, supplements, and get AI-powered health insights.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                HealthFeatureRow(icon: "cross.case.fill", text: "Lab Results Analysis")
                HealthFeatureRow(icon: "heart.fill", text: "Recovery Protocol Tracking")
                HealthFeatureRow(icon: "fork.knife.circle.fill", text: "Intermittent Fasting")
                HealthFeatureRow(icon: "pill.fill", text: "Supplement Management")
                HealthFeatureRow(icon: "brain.head.profile", text: "AI Health Coach")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal)

            Spacer()

            NavigationLink {
                SubscriptionView()
                    .environmentObject(StoreKitService.shared)
            } label: {
                Text("Upgrade to Premium")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Health")
    }
}

struct HealthScoreCard: View {
    @StateObject private var viewModel = HealthCoachViewModel()

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Health Score")
                    .font(.headline)
                Spacer()
                NavigationLink {
                    AIHealthCoachView()
                } label: {
                    Text("Details")
                        .font(.caption)
                }
            }

            HStack(spacing: 20) {
                // Main Score
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: Double(viewModel.overallScore) / 100)
                        .stroke(viewModel.scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack {
                        Text("\(viewModel.overallScore)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("/ 100")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 80, height: 80)

                // Breakdown
                VStack(alignment: .leading, spacing: 6) {
                    if let score = viewModel.healthScore {
                        HealthScoreRow(label: "Sleep", value: score.sleepScore)
                        HealthScoreRow(label: "Recovery", value: score.recoveryScore)
                        HealthScoreRow(label: "Activity", value: score.activityScore)
                    } else {
                        Text("Loading...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .task {
            await viewModel.loadData()
        }
    }
}

struct HealthScoreRow: View {
    let label: String
    let value: Int

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text("\(value)")
                .font(.caption)
                .fontWeight(.medium)

            // Mini bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.3))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(scoreColor(value))
                        .frame(width: geometry.size.width * Double(value) / 100)
                }
            }
            .frame(width: 50, height: 4)
        }
    }

    private func scoreColor(_ value: Int) -> Color {
        switch value {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
}

struct HealthFeatureCard: View {
    let title: String
    let icon: String
    let color: Color
    let destination: AnyView

    var body: some View {
        NavigationLink {
            destination
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(color.opacity(0.1))
            .cornerRadius(16)
        }
    }
}

struct HealthFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
            Image(systemName: "checkmark")
                .foregroundColor(.green)
        }
    }
}
