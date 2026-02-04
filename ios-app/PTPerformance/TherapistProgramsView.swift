import SwiftUI

struct TherapistProgramsView: View {
    @StateObject private var viewModel = ProgramsListViewModel()
    @State private var selectedProgram: ProgramListItem?
    @State private var showProgramViewer = false
    @State private var showProgramBuilder = false
    @State private var showLibraryProgramBuilder = false
    @State private var showProgramManager = false
    @State private var editingProgramId: String?
    @State private var editingPatientId: UUID?
    @State private var showEditor = false
    @State private var selectedTypeFilter: ProgramType? = nil
    @State private var showProgramAnalytics = false
    @State private var showComparePrograms = false
    @State private var analyticsProgramId: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading programs...")
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView {
                        Label("Error Loading Programs", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") {
                            Task {
                                await viewModel.loadPrograms()
                            }
                        }
                    }
                } else if viewModel.programs.isEmpty {
                    ContentUnavailableView {
                        Label("No Programs Yet", systemImage: "doc.richtext")
                    } description: {
                        Text("Programs created for patients will appear here")
                    } actions: {
                        Button("Create Program") {
                            showProgramBuilder = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    programsList
                }
            }
            .navigationTitle("Programs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ContextualHelpButton(articleId: nil)
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showProgramBuilder = true
                        } label: {
                            Label("Create Program", systemImage: "plus.circle")
                        }

                        Button {
                            showLibraryProgramBuilder = true
                        } label: {
                            Label("Build Library Program", systemImage: "books.vertical")
                        }

                        Button {
                            showProgramManager = true
                        } label: {
                            Label("Manage Programs", systemImage: "pencil.circle")
                        }

                        Divider()

                        Button {
                            showProgramAnalytics = true
                        } label: {
                            Label("Program Analytics", systemImage: "chart.bar.xaxis")
                        }

                        Button {
                            showComparePrograms = true
                        } label: {
                            Label("Compare Programs", systemImage: "arrow.left.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $selectedProgram) { program in
                NavigationStack {
                    ProgramViewerView(patientId: program.patientId)
                }
            }
            .sheet(isPresented: $showProgramBuilder) {
                // Refresh programs list when builder is dismissed
                Task {
                    await viewModel.loadPrograms()
                }
            } content: {
                ProgramBuilderView(patientId: nil)
            }
            .sheet(isPresented: $showLibraryProgramBuilder) {
                // Refresh programs list when library builder is dismissed
                Task {
                    await viewModel.loadPrograms()
                }
            } content: {
                TherapistProgramBuilderView()
            }
            .sheet(isPresented: $showProgramManager) {
                ProgramManagerView()
            }
            .sheet(isPresented: $showEditor) {
                // Refresh programs list when editor is dismissed
                Task {
                    await viewModel.loadPrograms()
                }
            } content: {
                if let programId = editingProgramId, let patientId = editingPatientId {
                    ProgramEditorView(programId: programId, patientId: patientId)
                }
            }
            .sheet(isPresented: $showProgramAnalytics) {
                NavigationStack {
                    ProgramEffectivenessView()
                }
            }
            .sheet(isPresented: $showComparePrograms) {
                NavigationStack {
                    ProgramEffectivenessView()
                }
            }
            .task {
                await viewModel.loadPrograms()
            }
            .refreshable {
                await viewModel.loadPrograms()
            }
        }
    }

    private var programsList: some View {
        VStack(spacing: 0) {
            filterBar

            List(filteredPrograms) { program in
                ProgramListCard(program: program) {
                    // Open analytics for this program
                    if let programUUID = UUID(uuidString: program.id) {
                        analyticsProgramId = programUUID
                        showProgramAnalytics = true
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        // Navigate to editor
                        if let patientId = UUID(uuidString: program.patientId) {
                            showProgramEditor(programId: program.id, patientId: patientId)
                        }
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)

                    Button {
                        // Open analytics
                        if let programUUID = UUID(uuidString: program.id) {
                            analyticsProgramId = programUUID
                            showProgramAnalytics = true
                        }
                    } label: {
                        Label("Analytics", systemImage: "chart.bar.xaxis")
                    }
                    .tint(.purple)
                }
                .onTapGesture {
                    selectedProgram = program
                }
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", isSelected: selectedTypeFilter == nil) {
                    selectedTypeFilter = nil
                }
                ForEach(ProgramType.allCases) { type in
                    FilterChip(
                        label: type.displayName,
                        icon: type.icon,
                        color: type.color,
                        isSelected: selectedTypeFilter == type
                    ) {
                        selectedTypeFilter = type
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private var filteredPrograms: [ProgramListItem] {
        guard let filter = selectedTypeFilter else { return viewModel.programs }
        return viewModel.programs.filter { $0.resolvedProgramType == filter }
    }

    private func showProgramEditor(programId: String, patientId: UUID) {
        editingProgramId = programId
        editingPatientId = patientId
        showEditor = true
    }
}

// MARK: - Program List Card

struct ProgramListCard: View {
    let program: ProgramListItem
    var onAnalytics: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with name and effectiveness badge
            HStack {
                Text(program.programName)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                // Effectiveness score badge (placeholder - would be fetched from analytics)
                ProgramEffectivenessIndicator()
            }

            // Program type badge
            HStack(spacing: 4) {
                Image(systemName: program.resolvedProgramType.icon)
                    .font(.caption2)
                    .accessibilityHidden(true)
                Text(program.resolvedProgramType.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(program.resolvedProgramType.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(program.resolvedProgramType.color.opacity(0.15))
            .cornerRadius(8)

            // Patient name
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)
                Text(program.patientName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Program details
            HStack(spacing: 16) {
                Label("\(program.durationWeeks) weeks", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Label(program.targetLevel, systemImage: "target")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Footer with created date and analytics button
            HStack {
                if let createdAt = program.createdAt {
                    Text("Created \(createdAt, style: .relative)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let onAnalytics = onAnalytics {
                    Button {
                        onAnalytics()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.xaxis")
                            Text("Analytics")
                        }
                        .font(.caption2)
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(program.programName), \(program.resolvedProgramType.displayName) program for \(program.patientName), \(program.durationWeeks) weeks, \(program.targetLevel) level")
        .accessibilityHint("Double tap to view program details, swipe left to edit")
    }
}

// MARK: - Program Effectiveness Indicator

/// Small badge showing program effectiveness score
struct ProgramEffectivenessIndicator: View {
    // In a real implementation, this would receive the actual score
    // For now, we show a placeholder that indicates analytics are available
    var score: Double? = nil

    var body: some View {
        if let score = score {
            HStack(spacing: 2) {
                Image(systemName: iconForScore(score))
                    .font(.caption2)
                Text(String(format: "%.0f%%", score * 100))
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .foregroundColor(colorForScore(score))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(colorForScore(score).opacity(0.15))
            .cornerRadius(6)
        } else {
            // Show analytics available indicator
            Image(systemName: "chart.bar.xaxis")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(4)
                .background(Color(.systemGray5))
                .cornerRadius(4)
        }
    }

    private func iconForScore(_ score: Double) -> String {
        switch score {
        case 0.8...: return "star.fill"
        case 0.6..<0.8: return "hand.thumbsup.fill"
        case 0.4..<0.6: return "minus.circle.fill"
        default: return "exclamationmark.triangle.fill"
        }
    }

    private func colorForScore(_ score: Double) -> Color {
        switch score {
        case 0.8...: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

// MARK: - Programs List ViewModel

@MainActor
class ProgramsListViewModel: ObservableObject {
    @Published var programs: [ProgramListItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase: PTSupabaseClient

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    func loadPrograms() async {
        let logger = DebugLogger.shared
        isLoading = true
        errorMessage = nil

        logger.log("📚 Loading all programs...")

        do {
            // Fetch programs with patient names via join
            let response = try await supabase.client
                .from("programs")
                .select("""
                    id,
                    patient_id,
                    name,
                    target_level,
                    duration_weeks,
                    created_at,
                    program_type,
                    patients!inner(
                        first_name,
                        last_name
                    )
                """)
                .order("created_at", ascending: false)
                .execute()

            logger.log("📚 Programs response size: \(response.data.count) bytes")

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            programs = try decoder.decode([ProgramListItem].self, from: response.data)
            logger.log("✅ Loaded \(programs.count) programs", level: .success)

            isLoading = false
        } catch {
            logger.log("❌ Error loading programs: \(error)", level: .error)
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: - Program List Item Model

struct ProgramListItem: Codable, Identifiable {
    let id: String
    let patientId: String
    let programName: String
    let targetLevel: String
    let durationWeeks: Int
    let createdAt: Date?
    let programType: ProgramType?
    let patient: PatientInfo

    var patientName: String {
        "\(patient.firstName) \(patient.lastName)"
    }

    /// Resolved program type (defaults to .rehab for legacy programs)
    var resolvedProgramType: ProgramType {
        programType ?? .rehab
    }

    struct PatientInfo: Codable {
        let firstName: String
        let lastName: String

        enum CodingKeys: String, CodingKey {
            case firstName = "first_name"
            case lastName = "last_name"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case programName = "name"
        case targetLevel = "target_level"
        case durationWeeks = "duration_weeks"
        case createdAt = "created_at"
        case programType = "program_type"
        case patient = "patients"
    }
}
