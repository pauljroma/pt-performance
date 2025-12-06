# iOS UI Implementation Plan - Final 4 Features

**Status**: Ready to Build  
**Target**: Complete all 4 remaining Linear issues (ACP-54, ACP-61, ACP-65, ACP-80)  
**Estimated Effort**: 6-8 hours  

---

## Feature 1: ACP-61 - Strength Targets in Program Editor

**Description**: Display estimated 1RM and recommended loads in therapist program editor

**Files to Create/Modify**:
1. `ios-app/PTPerformance/Views/ProgramEditorView.swift` (NEW)
2. `ios-app/PTPerformance/Components/StrengthTargetsCard.swift` (NEW)
3. `ios-app/PTPerformance/ViewModels/ProgramEditorViewModel.swift` (NEW)
4. `ios-app/PTPerformance/Utils/RMCalculator.swift` (EXISTS - use existing)

**Implementation Steps**:

### Step 1.1: Create StrengthTargetsCard Component
```swift
// Components/StrengthTargetsCard.swift
struct StrengthTargetsCard: View {
    let exercise: Exercise
    let oneRepMax: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Strength Targets")
                .font(.headline)
            
            if let rm = oneRepMax {
                Text("Estimated 1RM: \(Int(rm)) lbs")
                    .font(.title3)
                    .bold()
                
                VStack(spacing: 8) {
                    TargetRow(goal: "Strength", percentage: 0.85, oneRM: rm)
                    TargetRow(goal: "Hypertrophy", percentage: 0.70, oneRM: rm)
                    TargetRow(goal: "Endurance", percentage: 0.50, oneRM: rm)
                }
            } else {
                Text("Log exercises to see targets")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct TargetRow: View {
    let goal: String
    let percentage: Double
    let oneRM: Double
    
    var targetWeight: Int {
        Int(oneRM * percentage)
    }
    
    var body: some View {
        HStack {
            Text(goal)
            Spacer()
            Text("\(Int(percentage * 100))% = \(targetWeight) lbs")
                .foregroundColor(.secondary)
        }
    }
}
```

### Step 1.2: Create ProgramEditorView
```swift
// Views/ProgramEditorView.swift
struct ProgramEditorView: View {
    @StateObject private var viewModel = ProgramEditorViewModel()
    let patientId: UUID
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Exercise selector
                ExercisePicker(selected: $viewModel.selectedExercise)
                
                // Show strength targets if exercise selected
                if let exercise = viewModel.selectedExercise {
                    StrengthTargetsCard(
                        exercise: exercise,
                        oneRepMax: viewModel.estimatedRM
                    )
                }
                
                // Sets/reps editor
                SetsRepsEditor(
                    sets: $viewModel.sets,
                    reps: $viewModel.reps,
                    weight: $viewModel.recommendedWeight
                )
            }
            .padding()
        }
        .navigationTitle("Program Editor")
        .task {
            await viewModel.loadPatientHistory(patientId: patientId)
        }
    }
}
```

### Step 1.3: Create ViewModel with 1RM Calculation
```swift
// ViewModels/ProgramEditorViewModel.swift
class ProgramEditorViewModel: ObservableObject {
    @Published var selectedExercise: Exercise?
    @Published var estimatedRM: Double?
    @Published var sets: Int = 3
    @Published var reps: Int = 10
    @Published var recommendedWeight: Double = 0
    
    private let rmCalculator = RMCalculator()
    
    func loadPatientHistory(patientId: UUID) async {
        // Fetch patient's exercise history
        let history = await fetchExerciseHistory(patientId: patientId)
        
        // Calculate 1RM from history
        if let exercise = selectedExercise,
           let logs = history[exercise.id] {
            estimatedRM = rmCalculator.estimate1RM(from: logs)
            updateRecommendedWeight()
        }
    }
    
    func updateRecommendedWeight() {
        guard let rm = estimatedRM else { return }
        
        // Recommend 70% for hypertrophy (moderate reps)
        if reps >= 8 && reps <= 12 {
            recommendedWeight = rm * 0.70
        }
        // Recommend 85% for strength (low reps)
        else if reps <= 5 {
            recommendedWeight = rm * 0.85
        }
        // Recommend 50% for endurance (high reps)
        else {
            recommendedWeight = rm * 0.50
        }
    }
}
```

**Acceptance Criteria**:
- [ ] Estimated 1RM displayed from patient history
- [ ] Strength targets show 85%, 70%, 50% of 1RM
- [ ] Recommended weight updates based on rep range
- [ ] Falls back gracefully if no history available

---

## Feature 2: ACP-65 - Throwing Workload Flags in Dashboard

**Description**: Display throwing workload flags in therapist dashboard

**Files to Create/Modify**:
1. `ios-app/PTPerformance/Components/WorkloadFlagBanner.swift` (NEW)
2. `ios-app/PTPerformance/Models/WorkloadFlag.swift` (NEW)
3. `ios-app/PTPerformance/TherapistDashboardView.swift` (MODIFY)
4. `ios-app/PTPerformance/ViewModels/PatientListViewModel.swift` (MODIFY)

**Implementation Steps**:

### Step 2.1: Create WorkloadFlag Model
```swift
// Models/WorkloadFlag.swift
struct WorkloadFlag: Identifiable, Codable {
    let id: UUID
    let patientId: UUID
    let flagType: FlagType
    let severity: Severity
    let message: String
    let value: Double
    let threshold: Double
    let timestamp: Date
    
    enum FlagType: String, Codable {
        case highWorkload = "high_workload"
        case velocityDrop = "velocity_drop"
        case commandLoss = "command_loss"
    }
    
    enum Severity: String, Codable {
        case warning = "yellow"
        case critical = "red"
    }
    
    var icon: String {
        switch flagType {
        case .highWorkload: return "chart.line.uptrend.xyaxis"
        case .velocityDrop: return "speedometer"
        case .commandLoss: return "target"
        }
    }
    
    var color: Color {
        severity == .critical ? .red : .orange
    }
}
```

### Step 2.2: Create WorkloadFlagBanner Component
```swift
// Components/WorkloadFlagBanner.swift
struct WorkloadFlagBanner: View {
    let flag: WorkloadFlag
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: flag.icon)
                .font(.title2)
                .foregroundColor(flag.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(flag.message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(Int(flag.value)) / \(Int(flag.threshold)) threshold")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(flag.color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(flag.color, lineWidth: 1)
        )
    }
}
```

### Step 2.3: Integrate into TherapistDashboardView
```swift
// TherapistDashboardView.swift (MODIFY)
struct TherapistDashboardView: View {
    @StateObject private var viewModel = PatientListViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Active flags section
                    if !viewModel.activeFlags.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Active Alerts")
                                .font(.headline)
                            
                            ForEach(viewModel.activeFlags) { flag in
                                WorkloadFlagBanner(flag: flag)
                                    .onTapGesture {
                                        viewModel.selectedPatient = viewModel.patient(for: flag.patientId)
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Patient list
                    PatientList(patients: viewModel.patients)
                }
            }
            .navigationTitle("Dashboard")
            .task {
                await viewModel.loadPatients()
                await viewModel.loadActiveFlags()
            }
        }
    }
}
```

### Step 2.4: Update PatientListViewModel
```swift
// ViewModels/PatientListViewModel.swift (ADD)
extension PatientListViewModel {
    @Published var activeFlags: [WorkloadFlag] = []
    
    func loadActiveFlags() async {
        do {
            let response = try await supabase
                .from("workload_flags")
                .select()
                .eq("resolved", value: false)
                .order("severity", ascending: false)
                .execute()
            
            activeFlags = try JSONDecoder().decode([WorkloadFlag].self, from: response.data)
        } catch {
            print("Error loading flags: \(error)")
        }
    }
}
```

**Acceptance Criteria**:
- [ ] High workload flags displayed (pitch count > threshold)
- [ ] Velocity drop flags displayed (>3 mph decline)
- [ ] Command loss flags displayed
- [ ] Flags color-coded (red = critical, yellow = warning)
- [ ] Tapping flag navigates to patient detail

---

## Feature 3: ACP-80 - Program Builder with Protocol Selector

**Description**: Add protocol selector and constraint enforcement in program builder

**Files to Create/Modify**:
1. `ios-app/PTPerformance/Views/ProgramBuilderView.swift` (NEW)
2. `ios-app/PTPerformance/Components/ProtocolSelector.swift` (NEW)
3. `ios-app/PTPerformance/Models/Protocol.swift` (NEW)
4. `ios-app/PTPerformance/ViewModels/ProgramBuilderViewModel.swift` (NEW)

**Implementation Steps**:

### Step 3.1: Create Protocol Model
```swift
// Models/Protocol.swift
struct TherapyProtocol: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let phases: [ProtocolPhase]
    let constraints: ProtocolConstraints
    
    struct ProtocolPhase: Codable {
        let name: String
        let durationWeeks: Int
        let allowedExerciseCategories: [String]
        let restrictions: [String]
    }
    
    struct ProtocolConstraints: Codable {
        let minPhases: Int
        let maxPhases: Int
        let requiredExerciseTypes: [String]
        let prohibitedExercises: [String]
    }
}
```

### Step 3.2: Create ProtocolSelector Component
```swift
// Components/ProtocolSelector.swift
struct ProtocolSelector: View {
    @Binding var selectedProtocol: TherapyProtocol?
    let protocols: [TherapyProtocol]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Protocol")
                .font(.headline)
            
            Picker("Protocol", selection: $selectedProtocol) {
                Text("None (Custom)").tag(nil as TherapyProtocol?)
                
                ForEach(protocols) { protocol in
                    Text(protocol.name).tag(protocol as TherapyProtocol?)
                }
            }
            .pickerStyle(.menu)
            
            if let protocol = selectedProtocol {
                VStack(alignment: .leading, spacing: 8) {
                    Text(protocol.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(protocol.phases.count) phases • \(protocol.phases.map(\.durationWeeks).reduce(0, +)) weeks total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}
```

### Step 3.3: Create ProgramBuilderView
```swift
// Views/ProgramBuilderView.swift
struct ProgramBuilderView: View {
    @StateObject private var viewModel = ProgramBuilderViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Program Details") {
                    TextField("Program Name", text: $viewModel.programName)
                    
                    ProtocolSelector(
                        selectedProtocol: $viewModel.selectedProtocol,
                        protocols: viewModel.availableProtocols
                    )
                }
                
                Section("Phases") {
                    ForEach(viewModel.phases) { phase in
                        PhaseRow(
                            phase: phase,
                            constraints: viewModel.selectedProtocol?.constraints
                        )
                    }
                    
                    Button("Add Phase") {
                        viewModel.addPhase()
                    }
                    .disabled(!viewModel.canAddPhase)
                }
                
                if let error = viewModel.validationError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await viewModel.createProgram()
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
            }
            .task {
                await viewModel.loadProtocols()
            }
        }
    }
}
```

### Step 3.4: Create ViewModel with Constraint Enforcement
```swift
// ViewModels/ProgramBuilderViewModel.swift
@MainActor
class ProgramBuilderViewModel: ObservableObject {
    @Published var programName: String = ""
    @Published var selectedProtocol: TherapyProtocol?
    @Published var phases: [ProgramPhase] = []
    @Published var availableProtocols: [TherapyProtocol] = []
    @Published var validationError: String?
    
    var isValid: Bool {
        guard !programName.isEmpty else { return false }
        guard !phases.isEmpty else { return false }
        
        if let protocol = selectedProtocol {
            // Enforce protocol constraints
            if phases.count < protocol.constraints.minPhases {
                validationError = "Need at least \(protocol.constraints.minPhases) phases"
                return false
            }
            if phases.count > protocol.constraints.maxPhases {
                validationError = "Maximum \(protocol.constraints.maxPhases) phases allowed"
                return false
            }
        }
        
        validationError = nil
        return true
    }
    
    var canAddPhase: Bool {
        guard let protocol = selectedProtocol else { return true }
        return phases.count < protocol.constraints.maxPhases
    }
    
    func loadProtocols() async {
        // Fetch from Supabase
        do {
            let response = try await supabase
                .from("protocol_templates")
                .select()
                .execute()
            
            availableProtocols = try JSONDecoder().decode([TherapyProtocol].self, from: response.data)
        } catch {
            print("Error loading protocols: \(error)")
        }
    }
    
    func addPhase() {
        let newPhase = ProgramPhase(
            name: "Phase \(phases.count + 1)",
            durationWeeks: 2,
            sessions: []
        )
        phases.append(newPhase)
    }
    
    func createProgram() async {
        // Save to Supabase
        // Implementation...
    }
}
```

**Acceptance Criteria**:
- [ ] Protocol dropdown shows available protocols
- [ ] Selecting protocol enforces phase constraints
- [ ] Phase editor respects protocol restrictions
- [ ] Exercise picker filters based on protocol
- [ ] Validation errors shown clearly
- [ ] Can create custom program without protocol

---

## Feature 4: ACP-54 - iOS Performance Optimization

**Description**: Profile and optimize iOS app performance

**Implementation Steps**:

### Step 4.1: Run Xcode Instruments
```bash
# Open app in Xcode
cd ios-app/PTPerformance
open PTPerformance.xcodeproj

# Profile with Instruments:
# Product → Profile (⌘I)
# Select "Time Profiler"
# Run through test scenarios
```

### Step 4.2: Test Scenarios
1. Cold app launch
2. Load patient list (50+ patients)
3. Render charts with 90 days data
4. Log full workout session
5. Navigate between all tabs

### Step 4.3: Common Optimizations to Apply

**Lazy Loading**:
```swift
// Use LazyVStack for long lists
LazyVStack {
    ForEach(patients) { patient in
        PatientRow(patient: patient)
    }
}
```

**View Caching**:
```swift
// Cache expensive computed views
struct PatientDetailView: View {
    let patient: Patient
    
    @State private var cachedChartData: ChartData?
    
    var body: some View {
        if let chartData = cachedChartData {
            ChartView(data: chartData)
        }
    }
}
```

**Network Optimization**:
```swift
// Batch requests
func loadDashboard() async {
    async let patients = fetchPatients()
    async let flags = fetchFlags()
    async let stats = fetchStats()
    
    let (p, f, s) = await (patients, flags, stats)
    // Use results
}
```

**Acceptance Criteria**:
- [ ] Instruments profile run completed
- [ ] Memory leaks identified and fixed
- [ ] Network calls optimized (batch requests)
- [ ] List scrolling smooth (60 FPS)
- [ ] App launch < 2 seconds

---

## Implementation Order

**Recommended sequence**:

1. **ACP-80** (Program Builder) - Foundation for other features
2. **ACP-61** (Strength Targets) - Uses program editor
3. **ACP-65** (Workload Flags) - Dashboard enhancement
4. **ACP-54** (Performance) - Final optimization pass

**Total Estimated Time**: 6-8 hours
- ACP-80: 2-3 hours
- ACP-61: 2 hours
- ACP-65: 1.5 hours
- ACP-54: 1 hour

---

## Success Criteria

All 4 features complete when:
- [ ] All Swift files compile without errors
- [ ] UI matches design specifications
- [ ] Data loads from Supabase correctly
- [ ] User interactions work smoothly
- [ ] Performance targets met
- [ ] Linear issues marked Done with demos

**Ready to Build!** 🚀
