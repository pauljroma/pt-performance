//
//  TaskCustomizationSheet.swift
//  PTPerformance
//
//  Sheet for customizing individual task times, skipping/adding tasks,
//  setting reminders, and adding instructions before protocol assignment
//

import SwiftUI

struct TaskCustomizationSheet: View {
    let template: ProtocolTemplate
    @Binding var customization: PlanCustomization
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTask: ProtocolTask?
    @State private var showingTaskDetail = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Date range section
                    dateRangeSection

                    // Tasks section
                    tasksSection

                    // Notes section
                    notesSection
                }
                .padding()
            }
            .navigationTitle("Customize Protocol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Confirm") {
                        onConfirm()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(item: $selectedTask) { task in
                TaskDetailEditor(
                    task: task,
                    customization: Binding(
                        get: { customization.taskCustomizations[task.id] ?? .init() },
                        set: { customization.taskCustomizations[task.id] = $0 }
                    )
                )
            }
        }
    }

    // MARK: - Date Range Section

    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Duration", icon: "calendar")

            VStack(spacing: 16) {
                DatePicker(
                    "Start Date",
                    selection: $customization.startDate,
                    in: Date()...,
                    displayedComponents: .date
                )

                DatePicker(
                    "End Date",
                    selection: $customization.endDate,
                    in: customization.startDate...,
                    displayedComponents: .date
                )

                // Duration summary
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text(durationSummary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(CornerRadius.md)
        }
    }

    private var durationSummary: String {
        let days = Calendar.current.dateComponents([.day], from: customization.startDate, to: customization.endDate).day ?? 0
        if days == 1 {
            return "1 day"
        } else if days < 7 {
            return "\(days) days"
        } else {
            let weeks = days / 7
            let remainingDays = days % 7
            if remainingDays == 0 {
                return "\(weeks) week\(weeks > 1 ? "s" : "")"
            } else {
                return "\(weeks) week\(weeks > 1 ? "s" : ""), \(remainingDays) day\(remainingDays > 1 ? "s" : "")"
            }
        }
    }

    // MARK: - Tasks Section

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Tasks", icon: "checklist")
                Spacer()
                Text("\(customization.includedTaskCount)/\(template.tasks.count) included")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                ForEach(template.tasks) { task in
                    TaskCustomizationRow(
                        task: task,
                        customization: Binding(
                            get: { customization.taskCustomizations[task.id] ?? .init() },
                            set: { customization.taskCustomizations[task.id] = $0 }
                        ),
                        onTapDetail: {
                            selectedTask = task
                        }
                    )
                }
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Notes for Athlete", icon: "note.text")

            TextField("Add personalized instructions...", text: Binding(
                get: { customization.notes ?? "" },
                set: { customization.notes = $0.isEmpty ? nil : $0 }
            ), axis: .vertical)
            .lineLimit(3...6)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(CornerRadius.md)
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.headline)
    }
}

// MARK: - Task Customization Row

struct TaskCustomizationRow: View {
    let task: ProtocolTask
    @Binding var customization: PlanCustomization.TaskCustomization
    let onTapDetail: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Include toggle
            Button {
                customization.isIncluded.toggle()
            } label: {
                Image(systemName: customization.isIncluded ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(customization.isIncluded ? .accentColor : .gray)
            }

            // Task info
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(customization.isIncluded ? .primary : .secondary)
                    .strikethrough(!customization.isIncluded)

                HStack(spacing: 8) {
                    // Task type
                    Label(task.taskType.displayName, systemImage: task.taskType.iconName)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    // Time
                    if let time = customization.customTime ?? task.defaultTime {
                        Text("|")
                            .foregroundColor(.secondary)
                        Label(time, systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Reminder indicator
                    if customization.reminderEnabled {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                            .foregroundColor(.accentColor)
                    }
                }
            }

            Spacer()

            // Detail button
            Button(action: onTapDetail) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .disabled(!customization.isIncluded)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(CornerRadius.md)
        .opacity(customization.isIncluded ? 1 : 0.6)
    }
}

// MARK: - Task Detail Editor

struct TaskDetailEditor: View {
    let task: ProtocolTask
    @Binding var customization: PlanCustomization.TaskCustomization
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTime: Date = Date()
    @State private var customInstructions: String = ""

    var body: some View {
        NavigationStack {
            Form {
                // Task info section
                Section {
                    HStack {
                        Image(systemName: task.taskType.iconName)
                            .foregroundColor(.accentColor)
                        Text(task.title)
                            .font(.headline)
                    }

                    if let description = task.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    LabeledContent("Frequency", value: task.frequency.displayName)

                    if let duration = task.durationMinutes {
                        LabeledContent("Duration", value: "\(duration) minutes")
                    }
                }

                // Time customization
                Section("Schedule") {
                    Toggle("Include in Plan", isOn: $customization.isIncluded)

                    if customization.isIncluded {
                        DatePicker(
                            "Time",
                            selection: $selectedTime,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: selectedTime) { _, newValue in
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm"
                            customization.customTime = formatter.string(from: newValue)
                        }

                        Toggle("Send Reminder", isOn: $customization.reminderEnabled)
                    }
                }

                // Instructions section
                if customization.isIncluded {
                    Section("Custom Instructions") {
                        if let defaultInstructions = task.instructions {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Default:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(defaultInstructions)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        TextField("Add custom instructions...", text: $customInstructions, axis: .vertical)
                            .lineLimit(3...6)
                            .onChange(of: customInstructions) { _, newValue in
                                customization.customInstructions = newValue.isEmpty ? nil : newValue
                            }
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                setupInitialValues()
            }
        }
    }

    private func setupInitialValues() {
        // Parse time string to Date
        if let timeString = customization.customTime ?? task.defaultTime {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            if let date = formatter.date(from: timeString) {
                selectedTime = date
            }
        }

        customInstructions = customization.customInstructions ?? ""
    }
}

// MARK: - Preview

#Preview {
    TaskCustomizationSheet(
        template: .postWorkoutRecovery,
        customization: .constant(PlanCustomization(template: .postWorkoutRecovery)),
        onConfirm: {}
    )
}
