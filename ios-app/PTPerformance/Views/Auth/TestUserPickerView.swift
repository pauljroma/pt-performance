#if DEBUG
//
//  TestUserPickerView.swift
//  PTPerformance
//
//  DEBUG-only view for quickly logging in as any of 10 test user personas.
//

import SwiftUI

// MARK: - Test User Model

private struct TestUser: Identifiable {
    let id: String
    let name: String
    let sport: String
    let injury: String
    let mode: String
    let level: String
    let sportIcon: String

    var modeColor: Color {
        switch mode {
        case "rehab":
            return .orange
        case "strength":
            return .modusCyan
        case "performance":
            return .green
        default:
            return .secondary
        }
    }
}

// MARK: - Test Users Data

private let testUsers: [TestUser] = [
    TestUser(
        id: "aaaaaaaa-bbbb-cccc-dddd-000000000001",
        name: "Marcus Rivera",
        sport: "Baseball",
        injury: "Labrum Repair",
        mode: "rehab",
        level: "College",
        sportIcon: "baseball.fill"
    ),
    TestUser(
        id: "aaaaaaaa-bbbb-cccc-dddd-000000000002",
        name: "Alyssa Chen",
        sport: "Basketball",
        injury: "ACL Reconstruction",
        mode: "rehab",
        level: "Professional",
        sportIcon: "basketball.fill"
    ),
    TestUser(
        id: "aaaaaaaa-bbbb-cccc-dddd-000000000003",
        name: "Tyler Brooks",
        sport: "Football",
        injury: "Hamstring Strain",
        mode: "performance",
        level: "College",
        sportIcon: "football.fill"
    ),
    TestUser(
        id: "aaaaaaaa-bbbb-cccc-dddd-000000000004",
        name: "Emma Fitzgerald",
        sport: "Soccer",
        injury: "Ankle Sprain",
        mode: "rehab",
        level: "High School",
        sportIcon: "soccerball"
    ),
    TestUser(
        id: "aaaaaaaa-bbbb-cccc-dddd-000000000005",
        name: "Jordan Williams",
        sport: "CrossFit",
        injury: "Rotator Cuff Tendinitis",
        mode: "strength",
        level: "Recreational",
        sportIcon: "dumbbell.fill"
    ),
    TestUser(
        id: "aaaaaaaa-bbbb-cccc-dddd-000000000006",
        name: "Sophia Nakamura",
        sport: "Swimming",
        injury: "Shoulder Impingement",
        mode: "rehab",
        level: "College",
        sportIcon: "figure.pool.swim"
    ),
    TestUser(
        id: "aaaaaaaa-bbbb-cccc-dddd-000000000007",
        name: "Deshawn Patterson",
        sport: "Track & Field",
        injury: "Quad Strain",
        mode: "performance",
        level: "Semi-Pro",
        sportIcon: "figure.run"
    ),
    TestUser(
        id: "aaaaaaaa-bbbb-cccc-dddd-000000000008",
        name: "Olivia Martinez",
        sport: "Volleyball",
        injury: "Patellar Tendinitis",
        mode: "strength",
        level: "High School",
        sportIcon: "volleyball.fill"
    ),
    TestUser(
        id: "aaaaaaaa-bbbb-cccc-dddd-000000000009",
        name: "Liam O'Connor",
        sport: "Hockey",
        injury: "Hip Labral Tear",
        mode: "rehab",
        level: "Professional",
        sportIcon: "hockey.puck.fill"
    ),
    TestUser(
        id: "aaaaaaaa-bbbb-cccc-dddd-00000000000a",
        name: "Isabella Rossi",
        sport: "Tennis",
        injury: "Tennis Elbow",
        mode: "strength",
        level: "Recreational",
        sportIcon: "tennisball.fill"
    ),
]

// MARK: - TestUserPickerView

struct TestUserPickerView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var supabase = PTSupabaseClient.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(testUsers) { user in
                Button(action: {
                    loginAsTestUser(user)
                }) {
                    HStack(spacing: Spacing.sm) {
                        // Sport icon
                        Image(systemName: user.sportIcon)
                            .font(.title3)
                            .foregroundColor(.modusCyan)
                            .frame(width: 32, height: 32)
                            .accessibilityHidden(true)

                        // User details
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(user.name)
                                .font(.body.weight(.semibold))
                                .foregroundColor(.primary)

                            HStack(spacing: Spacing.xxs + 2) {
                                Text("\(user.sport) \u{2022} \(user.injury)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: Spacing.xs) {
                                // Mode badge
                                Text(user.mode)
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, Spacing.xs)
                                    .padding(.vertical, 2)
                                    .background(user.modeColor.opacity(0.15))
                                    .foregroundColor(user.modeColor)
                                    .cornerRadius(CornerRadius.xs)

                                // Level
                                Text(user.level)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, Spacing.xxs)
                }
                .accessibilityLabel("\(user.name), \(user.sport), \(user.mode) mode")
                .accessibilityHint("Log in as \(user.name)")
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Test Users")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticFeedback.light()
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Login Function

    private func loginAsTestUser(_ user: TestUser) {
        // Set both appState AND supabase client (view models read from supabase)
        appState.userId = user.id
        appState.userRole = .patient
        appState.isAuthenticated = true

        supabase.userId = user.id
        supabase.userRole = .patient

        // Start session monitoring
        SessionManager.shared.startMonitoring()

        HapticFeedback.success()

        DebugLogger.shared.info("Demo", "Logged in as test user: \(user.name) (\(user.id)) — \(user.sport), \(user.mode)")

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    TestUserPickerView()
        .environmentObject(AppState())
}
#endif
