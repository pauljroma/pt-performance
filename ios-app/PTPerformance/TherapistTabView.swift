import SwiftUI

struct TherapistTabView: View {
    @ObservedObject private var onboardingCoordinator = OnboardingCoordinator.shared

    var body: some View {
        TabView {
            TherapistDashboardView()
                .tabItem {
                    Label("Patients", systemImage: "person.3")
                }

            TherapistProgramsView()
                .tabItem {
                    Label("Programs", systemImage: "doc.richtext")
                }

            TherapistSchedulingView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }

            TherapistReportingView()
                .tabItem {
                    Label("Reports", systemImage: "chart.bar")
                }

            TherapistSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

// MARK: - Therapist Settings View

struct TherapistSettingsView: View {
    @ObservedObject private var onboardingCoordinator = OnboardingCoordinator.shared
    @EnvironmentObject var appState: AppState
    @State private var showingLogoutConfirmation = false
    @State private var isLoggingOut = false

    var body: some View {
        NavigationStack {
            List {
                Section("Help & Support") {
                    Button {
                        onboardingCoordinator.resetOnboarding()
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                            Text("View Tutorial")
                                .foregroundColor(.primary)
                        }
                    }
                }

                Section("Account") {
                    Button(role: .destructive) {
                        showingLogoutConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log Out")
                            Spacer()
                            if isLoggingOut {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isLoggingOut)
                }
            }
            .navigationTitle("Settings")
            .alert("Log Out", isPresented: $showingLogoutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    performLogout()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }

    private func performLogout() {
        isLoggingOut = true
        Task {
            do {
                try await PTSupabaseClient.shared.signOut()
                await MainActor.run {
                    appState.isAuthenticated = false
                    appState.userRole = nil
                    appState.userId = nil
                    isLoggingOut = false
                }
            } catch {
                await MainActor.run {
                    isLoggingOut = false
                }
                print("Logout failed: \(error.localizedDescription)")
            }
        }
    }
}
