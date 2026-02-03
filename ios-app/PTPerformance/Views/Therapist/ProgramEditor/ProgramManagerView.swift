//
//  ProgramManagerView.swift
//  PTPerformance
//
//  Build 50: List and manage existing programs
//

import SwiftUI

struct ProgramManagerView: View {
    @StateObject private var viewModel: ProgramManagerViewModel
    @Environment(\.dismiss) private var dismiss

    init(patientId: UUID? = nil) {
        _viewModel = StateObject(wrappedValue: ProgramManagerViewModel(patientId: patientId))
    }

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading programs...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let error = viewModel.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            Task {
                                await viewModel.loadPrograms()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if viewModel.programs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No programs found")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Create a new program to get started")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(viewModel.programs) { program in
                            NavigationLink {
                                ProgramStructureView(
                                    viewModel: ProgramEditorViewModel(
                                        patientId: program.patientId,
                                        exerciseId: nil
                                    ),
                                    program: program
                                )
                            } label: {
                                ProgramRowView(program: program)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await viewModel.loadPrograms()
                    }
                }
            }
            .navigationTitle("Manage Programs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.loadPrograms()
        }
    }
}

struct ProgramRowView: View {
    let program: Program

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(program.name)
                    .font(.headline)
                Spacer()
                if let status = program.status {
                    ProgramStatusBadge(status: status)
                }
            }

            HStack(spacing: 8) {
                Label(
                    "\(program.durationWeeks) \(program.durationWeeks == 1 ? "week" : "weeks")",
                    systemImage: "calendar"
                )
                .font(.caption)
                .foregroundColor(.secondary)

                Text("•")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(program.targetLevel.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("Created \(program.createdAt, format: .dateTime.month().day().year())")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(program.name)\(program.status.map { ", \($0.capitalized)" } ?? ""), \(program.durationWeeks) \(program.durationWeeks == 1 ? "week" : "weeks"), \(program.targetLevel.capitalized) level")
        .accessibilityHint("Double tap to view and edit program")
    }
}

struct ProgramStatusBadge: View {
    let status: String

    var body: some View {
        Text(status.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(8)
            .accessibilityLabel("Status: \(status.capitalized)")
    }

    private var backgroundColor: Color {
        switch status.lowercased() {
        case "active":
            return .green
        case "completed":
            return .blue
        case "paused":
            return .orange
        default:
            return .gray
        }
    }
}

@MainActor
class ProgramManagerViewModel: ObservableObject {
    @Published var programs: [Program] = []
    @Published var isLoading = false
    @Published var error: String?

    private let patientId: UUID?
    private let supabase: PTSupabaseClient

    init(patientId: UUID? = nil, supabase: PTSupabaseClient = .shared) {
        self.patientId = patientId
        self.supabase = supabase
    }

    func loadPrograms() async {
        let logger = DebugLogger.shared
        isLoading = true
        error = nil
        defer { isLoading = false }

        logger.log("📚 Loading programs for ProgramManagerView...")

        do {
            let decoder = JSONDecoder()
            // NOTE: Do NOT use .convertFromSnakeCase because Program model has explicit CodingKeys
            decoder.dateDecodingStrategy = .iso8601

            // Use same query structure as TherapistProgramsView which works
            let query = supabase.client
                .from("programs")
                .select("""
                    *
                """)
                .order("created_at", ascending: false)

            let result = try await query.execute()

            logger.log("   Response size: \(result.data.count) bytes")

            // Debug: Log raw JSON to see what fields are actually returned
            if let jsonString = String(data: result.data, encoding: .utf8) {
                logger.log("   Raw JSON: \(jsonString.prefix(500))")
            }

            programs = try decoder.decode([Program].self, from: result.data)

            // Filter by patient after loading if needed
            if let patientId = patientId {
                programs = programs.filter { $0.patientId == patientId }
                logger.log("   Filtered to \(programs.count) programs for patient")
            }

            logger.log("✅ Loaded \(programs.count) programs", level: .success)
        } catch {
            self.error = "Failed to load programs: \(error.localizedDescription)"
            logger.log("❌ Failed to load programs: \(error.localizedDescription)", level: .error)
            logger.log("Error details: \(error)", level: .error)
        }
    }
}

#Preview {
    ProgramManagerView()
}
