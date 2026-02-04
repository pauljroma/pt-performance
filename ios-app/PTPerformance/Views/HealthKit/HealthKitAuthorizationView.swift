import SwiftUI

/// View for explaining and requesting HealthKit authorization
/// Presents a clear explanation of what data will be accessed and why
struct HealthKitAuthorizationView: View {
    // MARK: - Dependencies

    @StateObject private var healthKitService = HealthKitService.shared
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var isRequesting = false
    @State private var showError = false
    @State private var errorMessage = ""

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header icon
                    Image(systemName: "applewatch")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .padding(.top, 20)

                    // Title
                    Text("Connect Apple Watch")
                        .font(.title.bold())

                    // Description
                    Text("Modus can read health data from your Apple Watch to automatically fill in your daily readiness check-in.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Data access list
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Data We Access")
                            .font(.headline)
                            .padding(.bottom, 4)

                        DataAccessRow(
                            icon: "heart.fill",
                            iconColor: .red,
                            title: "Heart Rate Variability (HRV)",
                            description: "Used to assess recovery and readiness"
                        )

                        DataAccessRow(
                            icon: "bed.double.fill",
                            iconColor: .purple,
                            title: "Sleep Analysis",
                            description: "Duration and quality of your sleep"
                        )

                        DataAccessRow(
                            icon: "heart.circle.fill",
                            iconColor: .pink,
                            title: "Resting Heart Rate",
                            description: "Indicator of cardiovascular health"
                        )

                        DataAccessRow(
                            icon: "flame.fill",
                            iconColor: .orange,
                            title: "Active Energy",
                            description: "Calories burned during activity"
                        )

                        DataAccessRow(
                            icon: "figure.walk",
                            iconColor: .green,
                            title: "Exercise & Steps",
                            description: "Daily activity tracking"
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Privacy note
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Privacy is Protected")
                                .font(.subheadline.bold())
                            Text("Your health data stays on your device and is only used to pre-fill your check-in form. We never share this data with third parties.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    Spacer(minLength: 20)

                    // Authorize button
                    Button {
                        Task {
                            await requestAuthorization()
                        }
                    } label: {
                        HStack {
                            if isRequesting {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.shield.fill")
                            }
                            Text("Authorize HealthKit Access")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isRequesting)
                    .padding(.horizontal)

                    // Skip button
                    Button("Not Now") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Authorization Failed", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Methods

    private func requestAuthorization() async {
        isRequesting = true
        defer { isRequesting = false }

        do {
            // Request authorization - this shows the iOS HealthKit permission dialog
            _ = try await healthKitService.requestAuthorization()

            // Verify connection by actually trying to query data
            // This is the only reliable way to check if user granted read permissions
            let connected = await healthKitService.verifyConnection()

            if connected {
                // Try to sync data immediately to populate the UI
                _ = try? await healthKitService.syncTodayData()
                dismiss()
            } else {
                // User may have denied permissions or has no data
                // Still dismiss but they can try again from settings
                errorMessage = "HealthKit access was not fully granted. You can enable it in Settings > Privacy > Health > Modus."
                showError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Data Access Row Component

/// Row component showing a single data type that will be accessed
private struct DataAccessRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct HealthKitAuthorizationView_Previews: PreviewProvider {
    static var previews: some View {
        HealthKitAuthorizationView()
            .previewDisplayName("Light Mode")

        HealthKitAuthorizationView()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
    }
}
#endif
