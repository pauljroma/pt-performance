//
//  ConflictResolutionSheet.swift
//  PTPerformance
//
//  Phase 3 Integration - Conflict Resolution UI
//  Allows therapists to resolve data conflicts in the timeline
//

import SwiftUI

// MARK: - Conflict Resolution Sheet

struct ConflictGroupResolutionSheet: View {

    // MARK: - Properties

    let conflict: ConflictGroup
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedResolution: ResolutionOption = .useFirst
    @State private var customValue = ""
    @State private var notes = ""
    @State private var isResolving = false
    @State private var animateIn = false
    @State private var showError = false
    @State private var errorMessage: String?

    // MARK: - Resolution Options

    enum ResolutionOption: String, CaseIterable {
        case useFirst = "Use First Source"
        case useSecond = "Use Second Source"
        case useAverage = "Use Average"
        case dismiss = "Dismiss Conflict"
        case manual = "Enter Manual Value"

        var icon: String {
            switch self {
            case .useFirst: return "1.circle.fill"
            case .useSecond: return "2.circle.fill"
            case .useAverage: return "divide.circle.fill"
            case .dismiss: return "xmark.circle.fill"
            case .manual: return "pencil.circle.fill"
            }
        }

        var description: String {
            switch self {
            case .useFirst: return "Accept the first data source as correct"
            case .useSecond: return "Accept the second data source as correct"
            case .useAverage: return "Calculate the average of both values"
            case .dismiss: return "Ignore this conflict - data is acceptable"
            case .manual: return "Enter a corrected value manually"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Conflict header
                    conflictHeader
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : -20)

                    // Conflicting values
                    conflictingValuesCard
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)

                    // Resolution options
                    resolutionOptionsCard
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)

                    // Notes section
                    notesSection
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)

                    // Action button
                    resolveButton
                        .opacity(animateIn ? 1 : 0)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Resolve Conflict")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                        onDismiss()
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    animateIn = true
                }
            }
            .alert("Resolution Failed", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unexpected error occurred while resolving the conflict")
            }
        }
    }

    // MARK: - Conflict Header

    private var conflictHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(conflict.conflictType.color.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: conflict.conflictType.iconName)
                    .font(.system(size: 36))
                    .foregroundColor(conflict.conflictType.color)
            }

            VStack(spacing: 4) {
                Text(conflict.conflictType.displayName)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.primary)

                Text("\(conflict.eventIds.count) events involved")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Conflicting Values Card

    private var conflictingValuesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Conflicting Data")
                .font(.headline)
                .foregroundColor(.primary)

            Text(conflict.description)
                .font(.body)
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                // Source 1
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        HapticService.selection()
                        selectedResolution = .useFirst
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "1.circle.fill")
                            .font(.title2)
                            .foregroundColor(.modusCyan)

                        Text("Source 1")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Value A")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(selectedResolution == .useFirst ? Color.modusCyan.opacity(0.1) : Color(.tertiarySystemFill))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(selectedResolution == .useFirst ? Color.modusCyan : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Source 1, Value A")
                .accessibilityHint("Double tap to select this source for resolution")
                .accessibilityAddTraits(selectedResolution == .useFirst ? .isSelected : [])

                Text("vs")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)

                // Source 2
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        HapticService.selection()
                        selectedResolution = .useSecond
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "2.circle.fill")
                            .font(.title2)
                            .foregroundColor(.purple)

                        Text("Source 2")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Value B")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(selectedResolution == .useSecond ? Color.purple.opacity(0.1) : Color(.tertiarySystemFill))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(selectedResolution == .useSecond ? Color.purple : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Source 2, Value B")
                .accessibilityHint("Double tap to select this source for resolution")
                .accessibilityAddTraits(selectedResolution == .useSecond ? .isSelected : [])
            }

            Text(conflict.timestamp, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Resolution Options Card

    private var resolutionOptionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Resolution Method")
                .font(.headline)
                .foregroundColor(.primary)

            ForEach(ResolutionOption.allCases, id: \.self) { option in
                resolutionOptionRow(option)
            }

            // Manual value input
            if selectedResolution == .manual {
                TextField("Enter corrected value", text: $customValue)
                    .textFieldStyle(.roundedBorder)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .animation(.spring(response: 0.3), value: selectedResolution)
    }

    private func resolutionOptionRow(_ option: ResolutionOption) -> some View {
        let isSelected = selectedResolution == option

        return Button {
            withAnimation(.spring(response: 0.3)) {
                HapticService.selection()
                selectedResolution = option
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : option.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .modusCyan : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(option.rawValue)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)

                    Text(option.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resolution Notes (Optional)")
                .font(.headline)
                .foregroundColor(.primary)

            TextEditor(text: $notes)
                .frame(minHeight: 80)
                .padding(Spacing.xs)
                .background(Color(.systemBackground))
                .cornerRadius(CornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .stroke(Color(.separator), lineWidth: 1)
                )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Resolve Button

    private var resolveButton: some View {
        Button {
            Task { await resolveConflict() }
        } label: {
            HStack {
                if isResolving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text("Apply Resolution")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.modusCyan)
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.md)
        }
        .disabled(isResolving || (selectedResolution == .manual && customValue.isEmpty))
    }

    // MARK: - Actions

    private func resolveConflict() async {
        isResolving = true
        HapticService.shared.prepare(for: .success)

        do {
            // Simulate resolution with potential failure
            try await Task.sleep(nanoseconds: 500_000_000)

            // Success animation
            HapticService.success()

            // Post notification
            NotificationCenter.default.post(name: .conflictResolved, object: nil)

            dismiss()
            onDismiss()
        } catch {
            isResolving = false
            HapticService.error()
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ConflictGroupResolutionSheet_Previews: PreviewProvider {
    static var previews: some View {
        ConflictGroupResolutionSheet(
            conflict: ConflictGroup(
                eventIds: [UUID(), UUID()],
                conflictType: .valueDiscrepancy,
                description: "HRV reading differs between Apple Health (62ms) and WHOOP (58ms)",
                timestamp: Date()
            ),
            onDismiss: {}
        )
    }
}
#endif
