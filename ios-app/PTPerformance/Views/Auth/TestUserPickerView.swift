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
    )
]

// MARK: - TestUserPickerView

struct TestUserPickerView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var supabase = PTSupabaseClient.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage = errorMessage {
                    Section {
                        HStack(spacing: Spacing.xxs + 2) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(DesignTokens.statusError)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(DesignTokens.statusError)
                        }
                    }
                }

                Section {
                    ForEach(testUsers) { user in
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

                                if loadingUserId == user.id {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .accessibilityHidden(true)
                                }
                            }
                            .padding(.vertical, Spacing.xxs)
                        }
                        .disabled(isLoading)
                        .opacity(isLoading && loadingUserId != user.id ? 0.5 : 1.0)
                        .accessibilityLabel("\(user.name), \(user.sport), \(user.mode) mode")
                        .accessibilityHint("Log in as \(user.name)")
                    }
                }
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
                    .disabled(isLoading)
                }
            }
        }
    }

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var loadingUserId: String?

    // MARK: - Login Function

    private func loginAsTestUser(_ user: TestUser) {
        isLoading = true
        loadingUserId = user.id
        errorMessage = nil

        Task {
            do {
                try await supabase.signInAsDemoUser(demoUserId: user.id, role: .patient)

                await MainActor.run {
                    appState.userId = supabase.userId
                    appState.userRole = .patient
                    appState.isAuthenticated = true
                    isLoading = false
                    loadingUserId = nil

                    SessionManager.shared.startMonitoring()
                    HapticFeedback.success()

                    DebugLogger.shared.info(
                        "Demo",
                        "Logged in as test user via Supabase Auth: \(user.name) (\(user.id)) -- \(user.sport), \(user.mode)"
                    )

                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    loadingUserId = nil
                    errorMessage = "Login failed: \(error.localizedDescription)"
                    HapticFeedback.formSubmission(success: false)
                }
                DebugLogger.shared.error("Demo", "Test user login failed for \(user.name): \(error)")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TestUserPickerView()
        .environmentObject(AppState())
}
#endif
