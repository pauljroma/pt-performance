//
//  PainBodyDiagramView.swift
//  PTPerformance
//
//  Clinical Assessments - Interactive body diagram for pain location mapping
//  Allows clinicians to record pain locations with intensity levels
//

import SwiftUI

// MARK: - Pain Body Region

/// Body regions available for pain mapping
enum PainBodyRegion: String, CaseIterable, Identifiable, Codable {
    // Upper body
    case cervical = "cervical"
    case shoulderLeft = "shoulder_left"
    case shoulderRight = "shoulder_right"
    case elbowLeft = "elbow_left"
    case elbowRight = "elbow_right"
    case wristLeft = "wrist_left"
    case wristRight = "wrist_right"

    // Spine
    case thoracic = "thoracic"
    case lumbar = "lumbar"

    // Lower body
    case hipLeft = "hip_left"
    case hipRight = "hip_right"
    case kneeLeft = "knee_left"
    case kneeRight = "knee_right"
    case ankleLeft = "ankle_left"
    case ankleRight = "ankle_right"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .cervical: return "Cervical Spine"
        case .shoulderLeft: return "Left Shoulder"
        case .shoulderRight: return "Right Shoulder"
        case .elbowLeft: return "Left Elbow"
        case .elbowRight: return "Right Elbow"
        case .wristLeft: return "Left Wrist"
        case .wristRight: return "Right Wrist"
        case .thoracic: return "Thoracic Spine"
        case .lumbar: return "Lumbar Spine"
        case .hipLeft: return "Left Hip"
        case .hipRight: return "Right Hip"
        case .kneeLeft: return "Left Knee"
        case .kneeRight: return "Right Knee"
        case .ankleLeft: return "Left Ankle"
        case .ankleRight: return "Right Ankle"
        }
    }

    /// Short name for compact display
    var shortName: String {
        switch self {
        case .cervical: return "C-Spine"
        case .shoulderLeft: return "L Shoulder"
        case .shoulderRight: return "R Shoulder"
        case .elbowLeft: return "L Elbow"
        case .elbowRight: return "R Elbow"
        case .wristLeft: return "L Wrist"
        case .wristRight: return "R Wrist"
        case .thoracic: return "T-Spine"
        case .lumbar: return "L-Spine"
        case .hipLeft: return "L Hip"
        case .hipRight: return "R Hip"
        case .kneeLeft: return "L Knee"
        case .kneeRight: return "R Knee"
        case .ankleLeft: return "L Ankle"
        case .ankleRight: return "R Ankle"
        }
    }

    /// Whether this region is visible from the front
    var isVisibleFromFront: Bool {
        switch self {
        case .cervical, .thoracic, .lumbar:
            return true // Spine visible from both views
        default:
            return true
        }
    }

    /// Whether this region is visible from the back
    var isVisibleFromBack: Bool {
        return true // All regions visible from back
    }

    /// Relative position for front view (normalized 0-1)
    var frontPosition: CGPoint {
        switch self {
        case .cervical: return CGPoint(x: 0.5, y: 0.12)
        case .shoulderLeft: return CGPoint(x: 0.28, y: 0.22)
        case .shoulderRight: return CGPoint(x: 0.72, y: 0.22)
        case .elbowLeft: return CGPoint(x: 0.18, y: 0.38)
        case .elbowRight: return CGPoint(x: 0.82, y: 0.38)
        case .wristLeft: return CGPoint(x: 0.12, y: 0.52)
        case .wristRight: return CGPoint(x: 0.88, y: 0.52)
        case .thoracic: return CGPoint(x: 0.5, y: 0.30)
        case .lumbar: return CGPoint(x: 0.5, y: 0.45)
        case .hipLeft: return CGPoint(x: 0.35, y: 0.52)
        case .hipRight: return CGPoint(x: 0.65, y: 0.52)
        case .kneeLeft: return CGPoint(x: 0.38, y: 0.72)
        case .kneeRight: return CGPoint(x: 0.62, y: 0.72)
        case .ankleLeft: return CGPoint(x: 0.38, y: 0.92)
        case .ankleRight: return CGPoint(x: 0.62, y: 0.92)
        }
    }

    /// Relative position for back view (normalized 0-1)
    var backPosition: CGPoint {
        switch self {
        case .cervical: return CGPoint(x: 0.5, y: 0.12)
        case .shoulderLeft: return CGPoint(x: 0.72, y: 0.22) // Mirrored
        case .shoulderRight: return CGPoint(x: 0.28, y: 0.22)
        case .elbowLeft: return CGPoint(x: 0.82, y: 0.38)
        case .elbowRight: return CGPoint(x: 0.18, y: 0.38)
        case .wristLeft: return CGPoint(x: 0.88, y: 0.52)
        case .wristRight: return CGPoint(x: 0.12, y: 0.52)
        case .thoracic: return CGPoint(x: 0.5, y: 0.28)
        case .lumbar: return CGPoint(x: 0.5, y: 0.42)
        case .hipLeft: return CGPoint(x: 0.65, y: 0.52)
        case .hipRight: return CGPoint(x: 0.35, y: 0.52)
        case .kneeLeft: return CGPoint(x: 0.62, y: 0.72)
        case .kneeRight: return CGPoint(x: 0.38, y: 0.72)
        case .ankleLeft: return CGPoint(x: 0.62, y: 0.92)
        case .ankleRight: return CGPoint(x: 0.38, y: 0.92)
        }
    }

    /// Icon name for region
    var iconName: String {
        switch self {
        case .cervical, .thoracic, .lumbar:
            return "figure.stand"
        case .shoulderLeft, .shoulderRight:
            return "figure.arms.open"
        case .elbowLeft, .elbowRight:
            return "arm.2"
        case .wristLeft, .wristRight:
            return "hand.raised"
        case .hipLeft, .hipRight:
            return "figure.walk"
        case .kneeLeft, .kneeRight:
            return "figure.run"
        case .ankleLeft, .ankleRight:
            return "shoeprints.fill"
        }
    }
}

// MARK: - Pain Location Model

/// Model for a pain location with intensity
struct PainLocation: Identifiable, Codable, Equatable {
    let id: UUID
    var region: PainBodyRegion
    var intensity: Int // 0-10 scale
    var notes: String?

    init(
        id: UUID = UUID(),
        region: PainBodyRegion,
        intensity: Int = 5,
        notes: String? = nil
    ) {
        self.id = id
        self.region = region
        self.intensity = min(10, max(0, intensity))
        self.notes = notes
    }

    /// Color based on pain intensity
    var intensityColor: Color {
        switch intensity {
        case 0: return .green
        case 1...3: return .yellow
        case 4...6: return .orange
        case 7...10: return .red
        default: return .gray
        }
    }

    /// Description of intensity level
    var intensityDescription: String {
        switch intensity {
        case 0: return "No Pain"
        case 1...3: return "Mild"
        case 4...6: return "Moderate"
        case 7...9: return "Severe"
        case 10: return "Worst Possible"
        default: return "Unknown"
        }
    }
}

// MARK: - Pain Body Diagram View

/// Interactive body diagram for mapping pain locations
struct PainBodyDiagramView: View {
    // MARK: - Bindings

    @Binding var painLocations: [PainLocation]

    // MARK: - State

    @State private var showingFront: Bool = true
    @State private var selectedRegion: PainBodyRegion?
    @State private var showingIntensityEditor: Bool = false
    @State private var editingLocation: PainLocation?
    @State private var tempIntensity: Int = 5

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header with view toggle
            headerSection

            // Body diagram
            diagramSection
                .padding()

            Divider()

            // Selected locations list
            selectedLocationsSection
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        .sheet(isPresented: $showingIntensityEditor) {
            intensityEditorSheet
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            // Title
            VStack(alignment: .leading, spacing: 2) {
                Text("Pain Location")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Tap regions to add pain locations")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Front/Back toggle
            HStack(spacing: 4) {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showingFront = true
                    }
                } label: {
                    Text("Front")
                        .font(.caption.weight(.medium))
                        .foregroundColor(showingFront ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(showingFront ? Color.blue : Color.clear)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showingFront = false
                    }
                } label: {
                    Text("Back")
                        .font(.caption.weight(.medium))
                        .foregroundColor(!showingFront ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(!showingFront ? Color.blue : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.tertiarySystemBackground))
            )
        }
        .padding()
    }

    // MARK: - Diagram Section

    private var diagramSection: some View {
        GeometryReader { geometry in
            ZStack {
                // Body outline
                bodyOutline
                    .stroke(Color(.tertiaryLabel), lineWidth: 2)
                    .fill(Color(.tertiarySystemBackground).opacity(0.5))
                    .frame(width: geometry.size.width * 0.6, height: geometry.size.height * 0.95)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                // Pain regions
                ForEach(PainBodyRegion.allCases) { region in
                    let position = showingFront ? region.frontPosition : region.backPosition
                    let isVisible = showingFront ? region.isVisibleFromFront : region.isVisibleFromBack

                    if isVisible {
                        painRegionButton(
                            region: region,
                            at: CGPoint(
                                x: geometry.size.width * position.x,
                                y: geometry.size.height * position.y
                            )
                        )
                    }
                }

                // View label
                Text(showingFront ? "FRONT" : "BACK")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.secondary)
                    .position(x: geometry.size.width / 2, y: 16)
            }
        }
        .frame(height: 400)
        .accessibilityLabel("Body diagram showing \(showingFront ? "front" : "back") view")
    }

    // MARK: - Body Outline

    private var bodyOutline: some InsettableShape {
        BodyOutlineShape(isFront: showingFront)
    }

    // MARK: - Pain Region Button

    private func painRegionButton(region: PainBodyRegion, at position: CGPoint) -> some View {
        let existingLocation = painLocations.first { $0.region == region }

        // Safely extract values from existingLocation for use in the view
        let isSelected = existingLocation != nil
        let intensityColor = existingLocation?.intensityColor ?? Color(.quaternarySystemFill)
        let intensity = existingLocation?.intensity ?? 0

        return Button {
            handleRegionTap(region)
        } label: {
            ZStack {
                // Background circle
                Circle()
                    .fill(isSelected ? intensityColor.opacity(0.3) : Color(.quaternarySystemFill))
                    .frame(width: 36, height: 36)

                // Inner circle with intensity
                if isSelected {
                    Circle()
                        .fill(intensityColor)
                        .frame(width: 24, height: 24)

                    Text("\(intensity)")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white)
                } else {
                    Circle()
                        .strokeBorder(Color(.tertiaryLabel), lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                }
            }
            .shadow(color: isSelected ? intensityColor.opacity(0.4) : .clear, radius: 4)
        }
        .buttonStyle(.plain)
        .position(position)
        .accessibilityLabel("\(region.displayName)\(isSelected ? ", pain level \(intensity)" : "")")
        .accessibilityHint("Tap to \(isSelected ? "edit or remove" : "add") pain location")
    }

    // MARK: - Selected Locations Section

    private var selectedLocationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Selected Locations")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)

                Spacer()

                if !painLocations.isEmpty {
                    Button {
                        withAnimation {
                            painLocations.removeAll()
                        }
                    } label: {
                        Text("Clear All")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }

            if painLocations.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "hand.tap")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                        Text("No pain locations selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(painLocations) { location in
                            painLocationChip(location)
                        }
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Pain Location Chip

    private func painLocationChip(_ location: PainLocation) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(location.intensityColor)
                .frame(width: 12, height: 12)

            Text(location.region.shortName)
                .font(.caption.weight(.medium))
                .foregroundColor(.primary)

            Text("\(location.intensity)/10")
                .font(.caption2)
                .foregroundColor(.secondary)

            Button {
                withAnimation {
                    painLocations.removeAll { $0.id == location.id }
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .onTapGesture {
            editingLocation = location
            tempIntensity = location.intensity
            showingIntensityEditor = true
        }
    }

    // MARK: - Intensity Editor Sheet

    private var intensityEditorSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Region header
                if let location = editingLocation {
                    VStack(spacing: 8) {
                        Image(systemName: location.region.iconName)
                            .font(.system(size: 40))
                            .foregroundColor(intensityColorFor(tempIntensity))

                        Text(location.region.displayName)
                            .font(.title2.weight(.semibold))
                    }
                    .padding(.top, 16)
                }

                // Intensity display
                VStack(spacing: 12) {
                    Text("\(tempIntensity)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(intensityColorFor(tempIntensity))

                    Text(intensityDescriptionFor(tempIntensity))
                        .font(.headline)
                        .foregroundColor(.secondary)
                }

                // Intensity slider
                VStack(spacing: 8) {
                    Slider(value: Binding(
                        get: { Double(tempIntensity) },
                        set: { tempIntensity = Int($0) }
                    ), in: 0...10, step: 1)
                    .tint(intensityColorFor(tempIntensity))

                    HStack {
                        Text("0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("No Pain")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Spacer()
                        Text("Worst")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Spacer()
                        Text("10")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                // Intensity scale reference
                intensityScaleReference

                Spacer()

                // Action buttons
                HStack(spacing: 16) {
                    Button {
                        if let location = editingLocation {
                            withAnimation {
                                painLocations.removeAll { $0.id == location.id }
                            }
                        }
                        showingIntensityEditor = false
                    } label: {
                        Text("Remove")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        if var location = editingLocation {
                            location.intensity = tempIntensity
                            if let index = painLocations.firstIndex(where: { $0.id == location.id }) {
                                painLocations[index] = location
                            } else {
                                painLocations.append(location)
                            }
                        }
                        showingIntensityEditor = false
                    } label: {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle("Pain Intensity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingIntensityEditor = false
                    }
                }
            }
        }
    }

    // MARK: - Intensity Scale Reference

    private var intensityScaleReference: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pain Scale Reference")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            VStack(spacing: 4) {
                ForEach([
                    (0, "No Pain", Color.green),
                    (1, "Minimal", Color.green.opacity(0.7)),
                    (3, "Mild", Color.yellow),
                    (5, "Moderate", Color.orange),
                    (7, "Severe", Color.red.opacity(0.8)),
                    (10, "Worst Possible", Color.red)
                ], id: \.0) { level, label, color in
                    HStack {
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                        Text("\(level)")
                            .font(.caption.weight(.medium))
                            .frame(width: 20, alignment: .trailing)
                        Text("- \(label)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
    }

    // MARK: - Helper Methods

    private func handleRegionTap(_ region: PainBodyRegion) {
        if let existingIndex = painLocations.firstIndex(where: { $0.region == region }) {
            editingLocation = painLocations[existingIndex]
            tempIntensity = painLocations[existingIndex].intensity
        } else {
            editingLocation = PainLocation(region: region, intensity: 5)
            tempIntensity = 5
        }
        showingIntensityEditor = true
    }

    private func intensityColorFor(_ intensity: Int) -> Color {
        switch intensity {
        case 0: return .green
        case 1...3: return .yellow
        case 4...6: return .orange
        case 7...10: return .red
        default: return .gray
        }
    }

    private func intensityDescriptionFor(_ intensity: Int) -> String {
        switch intensity {
        case 0: return "No Pain"
        case 1...3: return "Mild Pain"
        case 4...6: return "Moderate Pain"
        case 7...9: return "Severe Pain"
        case 10: return "Worst Possible Pain"
        default: return "Unknown"
        }
    }
}

// MARK: - Body Outline Shape

/// Custom shape for body outline
struct BodyOutlineShape: InsettableShape {
    var isFront: Bool
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width - insetAmount * 2
        let height = rect.height - insetAmount * 2
        let centerX = rect.midX
        let startY = rect.minY + insetAmount

        // Head
        let headRadius = width * 0.12
        path.addEllipse(in: CGRect(
            x: centerX - headRadius,
            y: startY,
            width: headRadius * 2,
            height: headRadius * 2
        ))

        // Neck
        let neckTop = startY + headRadius * 2
        let neckWidth = width * 0.08
        path.move(to: CGPoint(x: centerX - neckWidth, y: neckTop))
        path.addLine(to: CGPoint(x: centerX + neckWidth, y: neckTop))
        path.addLine(to: CGPoint(x: centerX + neckWidth, y: neckTop + height * 0.03))
        path.addLine(to: CGPoint(x: centerX - neckWidth, y: neckTop + height * 0.03))
        path.closeSubpath()

        // Torso
        let torsoTop = neckTop + height * 0.02
        let shoulderWidth = width * 0.4
        let waistWidth = width * 0.25
        let torsoHeight = height * 0.35

        path.move(to: CGPoint(x: centerX - neckWidth, y: torsoTop))
        // Left shoulder
        path.addQuadCurve(
            to: CGPoint(x: centerX - shoulderWidth, y: torsoTop + height * 0.05),
            control: CGPoint(x: centerX - shoulderWidth * 0.7, y: torsoTop)
        )
        // Left side
        path.addLine(to: CGPoint(x: centerX - waistWidth, y: torsoTop + torsoHeight))
        // Bottom
        path.addLine(to: CGPoint(x: centerX + waistWidth, y: torsoTop + torsoHeight))
        // Right side
        path.addLine(to: CGPoint(x: centerX + shoulderWidth, y: torsoTop + height * 0.05))
        // Right shoulder
        path.addQuadCurve(
            to: CGPoint(x: centerX + neckWidth, y: torsoTop),
            control: CGPoint(x: centerX + shoulderWidth * 0.7, y: torsoTop)
        )
        path.closeSubpath()

        // Arms (simplified)
        let armWidth = width * 0.08
        let armLength = height * 0.35

        // Left arm
        path.addRoundedRect(
            in: CGRect(
                x: centerX - shoulderWidth - armWidth * 0.5,
                y: torsoTop + height * 0.04,
                width: armWidth,
                height: armLength
            ),
            cornerSize: CGSize(width: armWidth * 0.5, height: armWidth * 0.5)
        )

        // Right arm
        path.addRoundedRect(
            in: CGRect(
                x: centerX + shoulderWidth - armWidth * 0.5,
                y: torsoTop + height * 0.04,
                width: armWidth,
                height: armLength
            ),
            cornerSize: CGSize(width: armWidth * 0.5, height: armWidth * 0.5)
        )

        // Legs
        let legTop = torsoTop + torsoHeight
        let legWidth = width * 0.12
        let legLength = height * 0.45
        let legGap = width * 0.04

        // Left leg
        path.addRoundedRect(
            in: CGRect(
                x: centerX - legGap - legWidth,
                y: legTop,
                width: legWidth,
                height: legLength
            ),
            cornerSize: CGSize(width: legWidth * 0.3, height: legWidth * 0.3)
        )

        // Right leg
        path.addRoundedRect(
            in: CGRect(
                x: centerX + legGap,
                y: legTop,
                width: legWidth,
                height: legLength
            ),
            cornerSize: CGSize(width: legWidth * 0.3, height: legWidth * 0.3)
        )

        return path
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}

// MARK: - Preview

#Preview("Pain Body Diagram") {
    PainBodyDiagramView(
        painLocations: .constant([
            PainLocation(region: .shoulderRight, intensity: 6),
            PainLocation(region: .lumbar, intensity: 4),
            PainLocation(region: .kneeLeft, intensity: 8)
        ])
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Empty State") {
    PainBodyDiagramView(
        painLocations: .constant([])
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Dark Mode") {
    PainBodyDiagramView(
        painLocations: .constant([
            PainLocation(region: .cervical, intensity: 5),
            PainLocation(region: .shoulderLeft, intensity: 7)
        ])
    )
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
