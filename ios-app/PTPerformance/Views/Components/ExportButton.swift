import SwiftUI
import PDFKit

/// Reusable export button component for workout history
struct ExportButton: View {
    let sessions: [SessionWithLogs]
    let patientName: String

    @State private var showingExportOptions = false
    @State private var isExporting = false
    @State private var exportError: Error?
    @State private var showingError = false
    @State private var shareURL: URL?
    @State private var showingShareSheet = false

    private let exportService = ExportService()

    var body: some View {
        Button {
            showingExportOptions = true
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
        .disabled(sessions.isEmpty || isExporting)
        .confirmationDialog(
            "Export Workout History",
            isPresented: $showingExportOptions,
            titleVisibility: .visible
        ) {
            Button("Export as PDF") {
                Task {
                    await exportAs(.pdf)
                }
            }

            Button("Export as CSV") {
                Task {
                    await exportAs(.csv)
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose export format for your workout history")
        }
        .overlay {
            if isExporting {
                exportingOverlay
            }
        }
        .alert("Export Error", isPresented: $showingError, presenting: exportError) { error in
            Button("OK") {
                exportError = nil
            }
        } message: { error in
            Text(error.localizedDescription)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = shareURL {
                ShareSheet(items: [url])
            }
        }
    }

    private var exportingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text("Generating export...")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray))
            )
        }
    }

    // MARK: - Export Logic

    @MainActor
    private func exportAs(_ format: ExportService.ExportFormat) async {
        isExporting = true
        exportError = nil

        do {
            let url: URL

            switch format {
            case .pdf:
                url = try await exportService.exportToPDF(
                    sessions: sessions,
                    patientName: patientName
                )

            case .csv:
                // Get date range from sessions
                let dates = sessions.map { $0.sessionDate }
                let startDate = dates.min() ?? Date()
                let endDate = dates.max() ?? Date()

                url = try await exportService.exportToCSV(
                    sessions: sessions,
                    startDate: startDate,
                    endDate: endDate
                )
            }

            // Present share sheet
            shareURL = url
            showingShareSheet = true

        } catch {
            exportError = error
            showingError = true
        }

        isExporting = false
    }
}

// MARK: - Preview

#if DEBUG
struct ExportButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // With data
            ExportButton(
                sessions: [
                    SessionWithLogs(
                        id: "1",
                        sessionNumber: 1,
                        sessionDate: Date(),
                        completed: true,
                        notes: "Great workout!",
                        exerciseLogs: [
                            ExerciseLogDetail(
                                id: "log1",
                                exerciseName: "Squat",
                                actualSets: 3,
                                actualReps: [10, 10, 8],
                                actualLoad: 135,
                                loadUnit: "lbs",
                                rpe: 7,
                                painScore: 2,
                                notes: "Felt strong",
                                loggedAt: Date()
                            ),
                            ExerciseLogDetail(
                                id: "log2",
                                exerciseName: "Bench Press",
                                actualSets: 3,
                                actualReps: [8, 8, 6],
                                actualLoad: 185,
                                loadUnit: "lbs",
                                rpe: 8,
                                painScore: 1,
                                notes: nil,
                                loggedAt: Date()
                            )
                        ]
                    ),
                    SessionWithLogs(
                        id: "2",
                        sessionNumber: 2,
                        sessionDate: Date().addingTimeInterval(-86400),
                        completed: true,
                        notes: nil,
                        exerciseLogs: [
                            ExerciseLogDetail(
                                id: "log3",
                                exerciseName: "Deadlift",
                                actualSets: 4,
                                actualReps: [5, 5, 5, 3],
                                actualLoad: 225,
                                loadUnit: "lbs",
                                rpe: 9,
                                painScore: 3,
                                notes: "Back felt tight",
                                loggedAt: Date().addingTimeInterval(-86400)
                            )
                        ]
                    )
                ],
                patientName: "John Doe"
            )
            .padding()
            .previewDisplayName("With Data")

            // Empty state
            ExportButton(
                sessions: [],
                patientName: "Jane Smith"
            )
            .padding()
            .previewDisplayName("No Data")
        }
    }
}
#endif
