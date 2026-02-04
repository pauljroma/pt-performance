import SwiftUI

/// ACP-902: Recovery Session Log View
/// Allows users to log a new recovery session with type, duration, temperature, and notes
struct RecoverySessionLogView: View {
    @Environment(\.dismiss) private var dismiss

    let selectedType: RecoverySessionType?
    let onSave: (RecoverySessionInput) -> Void

    @State private var sessionType: RecoverySessionType
    @State private var duration: Int = 15
    @State private var useTimer: Bool = true
    @State private var temperature: Double?
    @State private var selectedPreset: TemperaturePreset?
    @State private var notes: String = ""
    @State private var perceivedEffort: Int = 5
    @State private var isSaving: Bool = false
    @State private var showingTimer: Bool = false

    init(
        selectedType: RecoverySessionType? = nil,
        onSave: @escaping (RecoverySessionInput) -> Void
    ) {
        self.selectedType = selectedType
        self.onSave = onSave
        _sessionType = State(initialValue: selectedType ?? .traditionalSauna)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Session Type Section
                sessionTypeSection

                // Duration Section
                durationSection

                // Temperature Section (conditional)
                if sessionType.supportsTemperature {
                    temperatureSection
                }

                // Effort & Notes Section
                effortSection

                notesSection
            }
            .navigationTitle("Log Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(useTimer ? "Start Timer" : "Save") {
                        if useTimer {
                            showingTimer = true
                        } else {
                            saveSession()
                        }
                    }
                    .disabled(isSaving)
                    .fontWeight(.semibold)
                }
            }
            .fullScreenCover(isPresented: $showingTimer) {
                RecoverySessionTimerView(
                    sessionType: sessionType,
                    targetDuration: duration * 60,
                    temperature: temperature,
                    onComplete: { actualDuration, timerNotes in
                        duration = actualDuration / 60
                        if !timerNotes.isEmpty {
                            notes = timerNotes
                        }
                        saveSession()
                    },
                    onCancel: {
                        showingTimer = false
                    }
                )
            }
        }
    }

    // MARK: - Session Type Section

    private var sessionTypeSection: some View {
        Section {
            Picker("Session Type", selection: $sessionType) {
                ForEach(RecoverySessionType.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: type.icon)
                        .tag(type)
                }
            }
            .pickerStyle(.navigationLink)
            .onChange(of: sessionType) { _, newValue in
                // Reset temperature preset when type changes
                selectedPreset = nil
                temperature = nil
                // Set default duration based on type
                duration = newValue.defaultDuration
            }

            // Session type description
            HStack(spacing: Spacing.sm) {
                Image(systemName: sessionType.icon)
                    .font(.title2)
                    .foregroundStyle(sessionType.gradient)
                    .frame(width: 44)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(sessionType.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(sessionType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .listRowBackground(sessionType.color.opacity(0.1))
        } header: {
            Text("Recovery Type")
        }
    }

    // MARK: - Duration Section

    private var durationSection: some View {
        Section {
            // Timer toggle
            Toggle("Use Timer", isOn: $useTimer)

            // Duration picker
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text("Duration")
                    Spacer()
                    Text("\(duration) minutes")
                        .foregroundColor(.modusCyan)
                        .fontWeight(.medium)
                }

                Slider(
                    value: Binding(
                        get: { Double(duration) },
                        set: { duration = Int($0) }
                    ),
                    in: Double(sessionType.minDuration)...Double(sessionType.maxDuration),
                    step: sessionType.durationStep
                )
                .tint(.modusCyan)

                // Duration presets
                HStack(spacing: Spacing.xs) {
                    ForEach(sessionType.durationPresets, id: \.self) { preset in
                        Button {
                            HapticFeedback.selectionChanged()
                            duration = preset
                        } label: {
                            Text("\(preset)m")
                                .font(.caption)
                                .fontWeight(duration == preset ? .semibold : .regular)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xs)
                                .background(
                                    duration == preset
                                        ? Color.modusCyan
                                        : Color(.tertiarySystemGroupedBackground)
                                )
                                .foregroundColor(duration == preset ? .white : .primary)
                                .cornerRadius(CornerRadius.sm)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        } header: {
            Text("Duration")
        } footer: {
            Text(sessionType.durationGuidance)
        }
    }

    // MARK: - Temperature Section

    private var temperatureSection: some View {
        Section {
            // Temperature presets
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Quick Select")
                    .font(.caption)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Spacing.xs) {
                    ForEach(sessionType.temperaturePresets, id: \.self) { preset in
                        Button {
                            HapticFeedback.selectionChanged()
                            selectedPreset = preset
                            temperature = preset.value
                        } label: {
                            VStack(spacing: 2) {
                                Text(preset.label)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text(preset.formattedValue)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                selectedPreset == preset
                                    ? sessionType.color.opacity(0.2)
                                    : Color(.tertiarySystemGroupedBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.sm)
                                    .stroke(
                                        selectedPreset == preset ? sessionType.color : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                            .cornerRadius(CornerRadius.sm)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Custom temperature input
            HStack {
                Text("Custom")
                Spacer()
                TextField(
                    sessionType.isColdTherapy ? "°F" : "°F",
                    value: $temperature,
                    format: .number
                )
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .onChange(of: temperature) { _, _ in
                    selectedPreset = nil
                }

                Text("°F")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("Temperature (Optional)")
        } footer: {
            Text(sessionType.temperatureGuidance)
        }
    }

    // MARK: - Effort Section

    private var effortSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text("Perceived Effort")
                    Spacer()
                    Text("\(perceivedEffort)/10")
                        .foregroundColor(effortColor)
                        .fontWeight(.medium)
                }

                Slider(
                    value: Binding(
                        get: { Double(perceivedEffort) },
                        set: { perceivedEffort = Int($0) }
                    ),
                    in: 1...10,
                    step: 1
                )
                .tint(effortColor)

                Text(effortDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("Intensity")
        }
    }

    private var effortColor: Color {
        switch perceivedEffort {
        case 1...3: return .green
        case 4...6: return .yellow
        case 7...8: return .orange
        default: return .red
        }
    }

    private var effortDescription: String {
        switch perceivedEffort {
        case 1...2: return "Very easy - could continue much longer"
        case 3...4: return "Easy - comfortable throughout"
        case 5...6: return "Moderate - noticeable but manageable"
        case 7...8: return "Hard - challenging, near limit"
        case 9...10: return "Maximum effort - could barely complete"
        default: return ""
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        Section {
            TextField("Add notes...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Text("Notes (Optional)")
        }
    }

    // MARK: - Actions

    private func saveSession() {
        isSaving = true

        let input = RecoverySessionInput(
            sessionType: sessionType,
            duration: duration * 60, // Convert to seconds
            temperature: temperature,
            perceivedEffort: perceivedEffort,
            notes: notes.isEmpty ? nil : notes
        )

        onSave(input)
        dismiss()
    }
}

// MARK: - Recovery Session Type

enum RecoverySessionType: String, CaseIterable, Identifiable {
    case traditionalSauna = "traditional_sauna"
    case infraredSauna = "infrared_sauna"
    case steamRoom = "steam_room"
    case iceBath = "ice_bath"
    case coldShower = "cold_shower"
    case coldPlunge = "cold_plunge"
    case contrastTherapy = "contrast"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .traditionalSauna: return "Traditional Sauna"
        case .infraredSauna: return "Infrared Sauna"
        case .steamRoom: return "Steam Room"
        case .iceBath: return "Ice Bath"
        case .coldShower: return "Cold Shower"
        case .coldPlunge: return "Cold Plunge"
        case .contrastTherapy: return "Contrast Therapy"
        }
    }

    var description: String {
        switch self {
        case .traditionalSauna: return "Dry heat sauna, typically 150-195°F"
        case .infraredSauna: return "Lower temperature infrared heat, 120-150°F"
        case .steamRoom: return "Humid heat therapy, 110-120°F"
        case .iceBath: return "Full body immersion in ice water"
        case .coldShower: return "Cold water exposure in shower"
        case .coldPlunge: return "Cold water immersion, typically 39-59°F"
        case .contrastTherapy: return "Alternating hot and cold exposure"
        }
    }

    var icon: String {
        switch self {
        case .traditionalSauna, .infraredSauna: return "flame.fill"
        case .steamRoom: return "cloud.fill"
        case .iceBath, .coldPlunge, .coldShower: return "snowflake"
        case .contrastTherapy: return "arrow.left.arrow.right"
        }
    }

    var color: Color {
        switch self {
        case .traditionalSauna: return .orange
        case .infraredSauna: return .red
        case .steamRoom: return .mint
        case .iceBath, .coldPlunge, .coldShower: return .cyan
        case .contrastTherapy: return .purple
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .traditionalSauna:
            return LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
        case .infraredSauna:
            return LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom)
        case .steamRoom:
            return LinearGradient(colors: [.mint, .teal], startPoint: .top, endPoint: .bottom)
        case .iceBath, .coldPlunge, .coldShower:
            return LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom)
        case .contrastTherapy:
            return LinearGradient(colors: [.purple, .indigo], startPoint: .top, endPoint: .bottom)
        }
    }

    var isColdTherapy: Bool {
        switch self {
        case .iceBath, .coldShower, .coldPlunge: return true
        default: return false
        }
    }

    var supportsTemperature: Bool {
        switch self {
        case .coldShower: return false
        default: return true
        }
    }

    // MARK: - Duration Configuration

    var defaultDuration: Int {
        switch self {
        case .traditionalSauna: return 15
        case .infraredSauna: return 30
        case .steamRoom: return 15
        case .iceBath: return 3
        case .coldShower: return 3
        case .coldPlunge: return 3
        case .contrastTherapy: return 15
        }
    }

    var minDuration: Int {
        switch self {
        case .iceBath, .coldPlunge, .coldShower: return 1
        default: return 5
        }
    }

    var maxDuration: Int {
        switch self {
        case .traditionalSauna, .infraredSauna, .steamRoom: return 45
        case .iceBath, .coldPlunge, .coldShower: return 15
        case .contrastTherapy: return 30
        }
    }

    var durationStep: Double {
        switch self {
        case .iceBath, .coldPlunge, .coldShower: return 1
        default: return 5
        }
    }

    var durationPresets: [Int] {
        switch self {
        case .traditionalSauna: return [10, 15, 20, 25]
        case .infraredSauna: return [20, 30, 40, 45]
        case .steamRoom: return [10, 15, 20]
        case .iceBath, .coldPlunge: return [2, 3, 5, 10]
        case .coldShower: return [1, 2, 3, 5]
        case .contrastTherapy: return [10, 15, 20, 25]
        }
    }

    var durationGuidance: String {
        switch self {
        case .traditionalSauna:
            return "15-20 minutes is optimal for most people. Start shorter if new to sauna."
        case .infraredSauna:
            return "30-45 minutes recommended. Infrared saunas work at lower temperatures."
        case .steamRoom:
            return "10-20 minutes is typical. Stay hydrated."
        case .iceBath, .coldPlunge:
            return "2-5 minutes is effective. Never exceed 15 minutes."
        case .coldShower:
            return "1-3 minutes at the end of your shower provides benefits."
        case .contrastTherapy:
            return "Alternate 3-4 minutes hot, 1 minute cold. Repeat 3-4 times."
        }
    }

    // MARK: - Temperature Configuration

    var temperaturePresets: [TemperaturePreset] {
        switch self {
        case .traditionalSauna:
            return [
                TemperaturePreset(label: "Mild", value: 150, unit: "°F"),
                TemperaturePreset(label: "Standard", value: 175, unit: "°F"),
                TemperaturePreset(label: "Hot", value: 195, unit: "°F")
            ]
        case .infraredSauna:
            return [
                TemperaturePreset(label: "Low", value: 120, unit: "°F"),
                TemperaturePreset(label: "Medium", value: 135, unit: "°F"),
                TemperaturePreset(label: "High", value: 150, unit: "°F")
            ]
        case .steamRoom:
            return [
                TemperaturePreset(label: "Standard", value: 110, unit: "°F"),
                TemperaturePreset(label: "Hot", value: 115, unit: "°F"),
                TemperaturePreset(label: "Very Hot", value: 120, unit: "°F")
            ]
        case .iceBath, .coldPlunge:
            return [
                TemperaturePreset(label: "Cold", value: 55, unit: "°F"),
                TemperaturePreset(label: "Very Cold", value: 45, unit: "°F"),
                TemperaturePreset(label: "Ice Cold", value: 39, unit: "°F")
            ]
        case .coldShower:
            return []
        case .contrastTherapy:
            return [
                TemperaturePreset(label: "Mild", value: 160, unit: "°F"),
                TemperaturePreset(label: "Standard", value: 180, unit: "°F"),
                TemperaturePreset(label: "Intense", value: 195, unit: "°F")
            ]
        }
    }

    var temperatureGuidance: String {
        switch self {
        case .traditionalSauna:
            return "Traditional saunas typically range from 150-195°F."
        case .infraredSauna:
            return "Infrared saunas operate at lower temperatures, 120-150°F."
        case .steamRoom:
            return "Steam rooms are usually 110-120°F with high humidity."
        case .iceBath, .coldPlunge:
            return "Cold therapy is most effective between 39-59°F. Colder is more intense."
        case .coldShower:
            return ""
        case .contrastTherapy:
            return "Hot phase temperature. Cold phase is typically 40-60°F."
        }
    }

    /// Maps to RecoveryProtocolType for database storage
    var protocolType: RecoveryProtocolType {
        switch self {
        case .traditionalSauna: return .saunaTraditional
        case .infraredSauna: return .saunaInfrared
        case .steamRoom: return .saunaSteam
        case .coldPlunge: return .coldPlunge
        case .coldShower: return .coldShower
        case .iceBath: return .iceBath
        case .contrastTherapy: return .contrast
        }
    }
}

// MARK: - Temperature Preset

struct TemperaturePreset: Hashable {
    let label: String
    let value: Double
    let unit: String

    var formattedValue: String {
        "\(Int(value))\(unit)"
    }
}

// MARK: - Recovery Session Input

struct RecoverySessionInput {
    let sessionType: RecoverySessionType
    let duration: Int // seconds
    let temperature: Double?
    let perceivedEffort: Int
    let notes: String?

    var protocolType: RecoveryProtocolType {
        sessionType.protocolType
    }
}

// MARK: - Preview

#if DEBUG
struct RecoverySessionLogView_Previews: PreviewProvider {
    static var previews: some View {
        RecoverySessionLogView(
            selectedType: .traditionalSauna,
            onSave: { _ in }
        )
        .previewDisplayName("Sauna Log")

        RecoverySessionLogView(
            selectedType: .coldPlunge,
            onSave: { _ in }
        )
        .previewDisplayName("Cold Plunge Log")

        RecoverySessionLogView(
            selectedType: .contrastTherapy,
            onSave: { _ in }
        )
        .previewDisplayName("Contrast Therapy Log")
    }
}
#endif
