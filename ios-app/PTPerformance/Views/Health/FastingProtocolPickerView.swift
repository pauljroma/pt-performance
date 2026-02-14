// DARK MODE: See ModeThemeModifier.swift for central theme control
import SwiftUI

/// Protocol picker for selecting fasting schedule (ACP-1001)
struct FastingProtocolPickerView: View {
    @Binding var selectedProtocol: FastingProtocolType
    @Binding var customHours: Int
    let onDismiss: () -> Void

    @State private var showingCustomSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    headerSection

                    // Protocol Options
                    VStack(spacing: Spacing.md) {
                        ForEach(FastingProtocolType.allCases, id: \.self) { protocol_ in
                            ProtocolCard(
                                protocol_: protocol_,
                                isSelected: selectedProtocol == protocol_,
                                customHours: customHours
                            ) {
                                if protocol_ == .custom {
                                    showingCustomSheet = true
                                } else {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedProtocol = protocol_
                                    }
                                    HapticFeedback.selectionChanged()
                                }
                            }
                        }
                    }

                    // Info Section
                    infoSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Fasting Protocol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingCustomSheet) {
                CustomProtocolSheet(
                    customHours: $customHours,
                    selectedProtocol: $selectedProtocol
                ) {
                    showingCustomSheet = false
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "clock.badge.checkmark.fill")
                .font(.system(size: 48))
                .foregroundColor(.modusCyan)

            Text("Choose Your Protocol")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.modusDeepTeal)

            Text("Select a fasting schedule that fits your lifestyle and goals")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Tips for Success", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                InfoRow(icon: "drop.fill", text: "Stay hydrated with water, black coffee, or tea")
                InfoRow(icon: "moon.fill", text: "Start your fast after dinner for easier compliance")
                InfoRow(icon: "figure.walk", text: "Light activity is fine during fasting windows")
                InfoRow(icon: "fork.knife", text: "Break your fast with protein and healthy fats")
            }
        }
        .padding()
        .background(Color.modusLightTeal.opacity(0.5))
        .cornerRadius(CornerRadius.lg)
    }
}

// MARK: - Protocol Card

private struct ProtocolCard: View {
    let protocol_: FastingProtocolType
    let isSelected: Bool
    let customHours: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? protocol_.color : Color.gray.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: protocol_.icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : protocol_.color)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(protocol_.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if protocol_.isPopular {
                            Text("Popular")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.modusTealAccent)
                                .cornerRadius(CornerRadius.xs)
                        }
                    }

                    Text(protocol_ == .custom ? "Custom: \(customHours)h fast" : protocol_.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(protocol_.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.modusTealAccent)
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .stroke(isSelected ? protocol_.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.modusCyan)
                .frame(width: 16)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Custom Protocol Sheet

private struct CustomProtocolSheet: View {
    @Binding var customHours: Int
    @Binding var selectedProtocol: FastingProtocolType
    let onDismiss: () -> Void

    @State private var localHours: Double = 16

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                // Visual representation
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 180, height: 180)

                    Circle()
                        .trim(from: 0, to: localHours / 24)
                        .stroke(
                            LinearGradient(
                                colors: [.modusCyan, .modusTealAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 4) {
                        Text("\(Int(localHours))")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.modusDeepTeal)

                        Text("hours fasting")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                // Slider
                VStack(spacing: Spacing.sm) {
                    Slider(value: $localHours, in: 12...36, step: 1)
                        .tint(.modusCyan)

                    HStack {
                        Text("12h")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("24h")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("36h")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                // Eating window info
                VStack(spacing: Spacing.xs) {
                    Text("Eating Window")
                        .font(.headline)
                        .foregroundColor(.modusDeepTeal)

                    Text("\(24 - Int(localHours)) hours")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.modusCyan)

                    Text("per day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Custom Protocol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        customHours = Int(localHours)
                        selectedProtocol = .custom
                        HapticFeedback.success()
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                localHours = Double(customHours)
            }
        }
    }
}

// MARK: - Fasting Protocol Type

enum FastingProtocolType: String, CaseIterable, Codable {
    case sixteen8 = "16:8"
    case eighteen6 = "18:6"
    case twenty4 = "20:4"
    case omad = "OMAD"
    case fiveTwo = "5:2"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .sixteen8: return "16:8"
        case .eighteen6: return "18:6"
        case .twenty4: return "20:4"
        case .omad: return "OMAD (One Meal A Day)"
        case .fiveTwo: return "5:2 Method"
        case .custom: return "Custom"
        }
    }

    var subtitle: String {
        switch self {
        case .sixteen8: return "16h fast / 8h eating"
        case .eighteen6: return "18h fast / 6h eating"
        case .twenty4: return "20h fast / 4h eating"
        case .omad: return "23h fast / 1h eating"
        case .fiveTwo: return "5 normal days / 2 fast days"
        case .custom: return "Set your own schedule"
        }
    }

    var description: String {
        switch self {
        case .sixteen8:
            return "Most popular protocol. Easy to maintain long-term. Ideal for beginners."
        case .eighteen6:
            return "Enhanced autophagy benefits. Good for experienced fasters."
        case .twenty4:
            return "Warrior Diet style. Greater metabolic benefits, requires adaptation."
        case .omad:
            return "Maximum autophagy and simplicity. Best for experienced fasters."
        case .fiveTwo:
            return "Flexible weekly approach. Eat normally 5 days, restrict calories 2 days."
        case .custom:
            return "Create a protocol that fits your unique schedule and goals."
        }
    }

    var fastingHours: Int {
        switch self {
        case .sixteen8: return 16
        case .eighteen6: return 18
        case .twenty4: return 20
        case .omad: return 23
        case .fiveTwo: return 24 // On fasting days
        case .custom: return 16 // Default, will be overridden
        }
    }

    var eatingHours: Int {
        24 - fastingHours
    }

    var icon: String {
        switch self {
        case .sixteen8: return "16.circle.fill"
        case .eighteen6: return "18.circle.fill"
        case .twenty4: return "20.circle.fill"
        case .omad: return "1.circle.fill"
        case .fiveTwo: return "52.circle.fill"
        case .custom: return "slider.horizontal.3"
        }
    }

    var color: Color {
        switch self {
        case .sixteen8: return .modusCyan
        case .eighteen6: return .modusTealAccent
        case .twenty4: return .orange
        case .omad: return .purple
        case .fiveTwo: return .blue
        case .custom: return .modusDeepTeal
        }
    }

    var isPopular: Bool {
        self == .sixteen8
    }

    var recommendedEatingWindow: (start: Int, end: Int) {
        switch self {
        case .sixteen8: return (12, 20) // 12 PM - 8 PM
        case .eighteen6: return (12, 18) // 12 PM - 6 PM
        case .twenty4: return (14, 18) // 2 PM - 6 PM
        case .omad: return (17, 18) // 5 PM - 6 PM
        case .fiveTwo: return (12, 20) // 12 PM - 8 PM on eating days
        case .custom: return (12, 20) // Default
        }
    }

    var recommendedEatingWindowDescription: String {
        let window = recommendedEatingWindow
        let startTime = formatHour(window.start)
        let endTime = formatHour(window.end)
        return "\(startTime) - \(endTime)"
    }

    private static let hourAmPmFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter
    }()

    private func formatHour(_ hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? Date()
        return Self.hourAmPmFormatter.string(from: date)
    }
}

// MARK: - Preview

#if DEBUG
struct FastingProtocolPickerView_Previews: PreviewProvider {
    static var previews: some View {
        FastingProtocolPickerView(
            selectedProtocol: .constant(.sixteen8),
            customHours: .constant(16)
        ) {}
    }
}
#endif
