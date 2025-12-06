import SwiftUI

struct TherapistTabView: View {
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
        }
    }
}
