import SwiftUI

struct TherapistProgramsView: View {
    @StateObject private var viewModel = ProgramsListViewModel()
    @State private var selectedProgram: ProgramListItem?
    @State private var showProgramViewer = false
    @State private var showProgramBuilder = false
    @State private var showProgramManager = false
    @State private var editingProgramId: String?
    @State private var editingPatientId: UUID?
    @State private var showEditor = false
    @State private var selectedTypeFilter: ProgramType? = nil

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
                            showProgramManager = true
                        } label: {
                            Label("Manage Programs", systemImage: "pencil.circle")
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
                ProgramListCard(program: program)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Program name
            Text(program.programName)
                .font(.headline)
                .foregroundColor(.primary)

            // Program type badge
            HStack(spacing: 4) {
                Image(systemName: program.resolvedProgramType.icon)
                    .font(.caption2)
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

            // Created date
            if let createdAt = program.createdAt {
                Text("Created \(createdAt, style: .relative)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
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
