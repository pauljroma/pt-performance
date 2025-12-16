import SwiftUI

struct TherapistTabView: View {
    @StateObject private var onboardingCoordinator = OnboardingCoordinator.shared

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

            TherapistSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

// MARK: - Therapist Settings View

struct TherapistSettingsView: View {
    @StateObject private var onboardingCoordinator = OnboardingCoordinator.shared

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
            }
            .navigationTitle("Settings")
        }
    }
}
