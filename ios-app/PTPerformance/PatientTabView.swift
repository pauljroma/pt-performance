import SwiftUI

struct PatientTabView: View {
    var body: some View {
        TabView {
            TodaySessionView()
                .tabItem {
                    Label("Today", systemImage: "list.bullet")
                }

            PatientHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
        }
    }
}
