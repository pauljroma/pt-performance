//
//  ProtocolBuilderView.swift
//  PTPerformance
//
//  Protocol Plan Builder for X2Index - PT workflow for assigning recovery/performance plans
//  Target: Apply/edit protocol templates and assign personalized tasks in <60s
//

import SwiftUI

struct ProtocolBuilderView: View {
    let athleteId: UUID
    let athleteName: String

    @StateObject private var viewModel: ProtocolBuilderViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: ProtocolTemplate.ProtocolCategory?
    @State private var showingCustomizationSheet = false
    @State private var showingConfirmation = false
    @State private var searchText = ""

    init(athleteId: UUID, athleteName: String) {
        self.athleteId = athleteId
        self.athleteName = athleteName
        _viewModel = StateObject(wrappedValue: ProtocolBuilderViewModel(athleteId: athleteId))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Timer indicator for <60s KPI
                assignmentTimerView

                // Category filter
                categoryFilterView

                // Template grid
                templateGridView

                // Bottom action bar
                if viewModel.selectedTemplate != nil {
                    bottomActionBar
                }
            }
            .navigationTitle("Assign Protocol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search protocols")
            .sheet(isPresented: $showingCustomizationSheet) {
                if let template = viewModel.selectedTemplate {
                    TaskCustomizationSheet(
                        template: template,
                        customization: $viewModel.customization,
                        onConfirm: {
                            showingCustomizationSheet = false
                            showingConfirmation = true
                        }
                    )
                }
            }
            .confirmationDialog(
                "Assign Protocol",
                isPresented: $showingConfirmation,
                titleVisibility: .visible
            ) {
                Button("Assign to \(athleteName)") {
                    Task {
                        await assignProtocol()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let template = viewModel.selectedTemplate {
                    Text("Assign \"\(template.name)\" with \(viewModel.customization.includedTaskCount) tasks?")
                }
            }
            .alert("Protocol Assigned", isPresented: $viewModel.showingSuccess) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Protocol successfully assigned to \(athleteName). Assignment time: \(viewModel.formattedAssignmentTime)")
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .task {
                await viewModel.loadTemplates()
            }
        }
    }

    // MARK: - Subviews

    private var assignmentTimerView: some View {
        HStack {
            Image(systemName: "timer")
                .foregroundColor(viewModel.elapsedSeconds < 45 ? .green : (viewModel.elapsedSeconds < 60 ? .yellow : .red))

            Text("Time: \(viewModel.formattedElapsedTime)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(viewModel.elapsedSeconds < 45 ? .green : (viewModel.elapsedSeconds < 60 ? .yellow : .red))

            Spacer()

            Text("Target: <60s")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }

    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ProtocolFilterChip(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )

                ForEach(ProtocolTemplate.ProtocolCategory.allCases, id: \.self) { category in
                    ProtocolFilterChip(
                        title: category.displayName,
                        iconName: category.iconName,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }

    private var templateGridView: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, 50)
            } else if filteredTemplates.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(filteredTemplates) { template in
                        ProtocolTemplateCard(
                            template: template,
                            isSelected: viewModel.selectedTemplate?.id == template.id,
                            onSelect: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.selectTemplate(template)
                                }
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No protocols found")
                .font(.headline)

            Text("Try adjusting your search or filter")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 50)
    }

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()

            VStack(spacing: 12) {
                if let template = viewModel.selectedTemplate {
                    // Template preview
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name)
                                .font(.headline)

                            Text("\(template.taskCount) tasks | \(template.estimatedDuration)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button {
                            showingCustomizationSheet = true
                        } label: {
                            Label("Customize", systemImage: "slider.horizontal.3")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }

                    // Quick assign button
                    Button {
                        showingConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Quick Assign")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isAssigning)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }

    // MARK: - Helpers

    private var filteredTemplates: [ProtocolTemplate] {
        var templates = viewModel.templates

        // Filter by category
        if let category = selectedCategory {
            templates = templates.filter { $0.category == category }
        }

        // Filter by search text
        if !searchText.isEmpty {
            templates = templates.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return templates
    }

    private func assignProtocol() async {
        guard let template = viewModel.selectedTemplate else { return }

        await viewModel.createPlan(
            athleteId: athleteId,
            template: template,
            customizations: viewModel.customization
        )
    }
}

// MARK: - Filter Chip

private struct ProtocolFilterChip: View {
    let title: String
    var iconName: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.modusCyan : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(CornerRadius.xl)
        }
    }
}

// MARK: - Preview

#Preview {
    ProtocolBuilderView(
        athleteId: UUID(),
        athleteName: "John Smith"
    )
}
