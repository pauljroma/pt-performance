import SwiftUI

// MARK: - Patient Settings View
// ACP-1036: Now redirects to UnifiedSettingsView

struct PatientSettingsView: View {
    @EnvironmentObject var storeKit: StoreKitService
    @EnvironmentObject var appState: AppState

    var body: some View {
        // ACP-1036: Redirect to new unified settings view
        UnifiedSettingsView()
            .environmentObject(storeKit)
            .environmentObject(appState)
    }
}
