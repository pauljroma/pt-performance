//
//  TemplatePickerView.swift
//  PTPerformance
//
//  Template picker for selecting and applying documentation templates
//

import SwiftUI

/// Template picker view for browsing and selecting documentation templates
struct TemplatePickerView: View {
    let templateType: DocumentationTemplateType
    let onSelectTemplate: (DocumentationTemplate) -> Void

    @StateObject private var viewModel = TemplatePickerViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: DocumentationTemplate?
    @State private var showPreview = false

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading templates...")
                } else if viewModel.filteredTemplates.isEmpty && viewModel.searchQuery.isEmpty {
                    emptyStateView
                } else {
                    templateListContent
                }
            }
            .navigationTitle("Select Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $viewModel.searchQuery, prompt: "Search templates")
            .sheet(isPresented: $showPreview) {
                if let template = selectedTemplate {
                    TPTemplatePreviewSheet(template: template) {
                        onSelectTemplate(template)
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadTemplates(type: templateType)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Templates Available")
                .font(.headline)

            Text("Templates help you quickly populate documentation with common content.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Template List Content

    private var templateListContent: some View {
        ScrollView {
            LazyVStack(spacing: 20, pinnedViews: .sectionHeaders) {
                // System Templates Section
                if !viewModel.systemTemplates.isEmpty {
                    Section {
                        ForEach(viewModel.systemTemplates) { template in
                            TemplateCard(
                                template: template,
                                isSelected: selectedTemplate?.id == template.id,
                                onTap: { selectTemplate(template) },
                                onPreview: { previewTemplate(template) }
                            )
                        }
                    } header: {
                        TPSectionHeader(title: "System Templates", icon: "building.2")
                    }
                }

                // User Templates Section
                if !viewModel.userTemplates.isEmpty {
                    Section {
                        ForEach(viewModel.userTemplates) { template in
                            TemplateCard(
                                template: template,
                                isSelected: selectedTemplate?.id == template.id,
                                onTap: { selectTemplate(template) },
                                onPreview: { previewTemplate(template) }
                            )
                        }
                    } header: {
                        TPSectionHeader(title: "My Templates", icon: "person.circle")
                    }
                }

                // No results state
                if viewModel.filteredTemplates.isEmpty && !viewModel.searchQuery.isEmpty {
                    noResultsView
                }
            }
            .padding()
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.title)
                .foregroundColor(.secondary)

            Text("No templates found")
                .font(.headline)

            Text("Try adjusting your search terms")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Actions

    private func selectTemplate(_ template: DocumentationTemplate) {
        selectedTemplate = template
        showPreview = true
    }

    private func previewTemplate(_ template: DocumentationTemplate) {
        selectedTemplate = template
        showPreview = true
    }
}

// MARK: - Section Header

struct TPSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)

            Text(title)
                .font(.headline)

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color(.systemBackground))
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: DocumentationTemplate
    let isSelected: Bool
    let onTap: () -> Void
    let onPreview: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if let category = template.category {
                            Text(category)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }

                // Description
                if let description = template.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Content preview badges
                HStack(spacing: 8) {
                    if template.subjectiveTemplate != nil {
                        TemplateBadge(label: "S", color: .blue)
                    }
                    if template.objectiveTemplate != nil {
                        TemplateBadge(label: "O", color: .green)
                    }
                    if template.assessmentTemplate != nil {
                        TemplateBadge(label: "A", color: .purple)
                    }
                    if template.planTemplate != nil {
                        TemplateBadge(label: "P", color: .orange)
                    }

                    Spacer()

                    Button {
                        onPreview()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "eye")
                            Text("Preview")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }

                // Usage count
                if let usageCount = template.usageCount {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption2)
                        Text("Used \(usageCount) times")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Template Badge

struct TemplateBadge: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(width: 20, height: 20)
            .background(color)
            .clipShape(Circle())
    }
}

// MARK: - Template Preview Sheet

private struct TPTemplatePreviewSheet: View {
    let template: DocumentationTemplate
    let onApply: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Template Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(template.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        if let description = template.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    // Subjective Section
                    if let subjective = template.subjectiveTemplate {
                        PreviewSection(
                            title: "Subjective",
                            icon: "person.wave.2",
                            color: .blue,
                            content: subjective
                        )
                    }

                    // Objective Section
                    if let objective = template.objectiveTemplate {
                        PreviewSection(
                            title: "Objective",
                            icon: "ruler",
                            color: .green,
                            content: objective
                        )
                    }

                    // Assessment Section
                    if let assessment = template.assessmentTemplate {
                        PreviewSection(
                            title: "Assessment",
                            icon: "stethoscope",
                            color: .purple,
                            content: assessment
                        )
                    }

                    // Plan Section
                    if let plan = template.planTemplate {
                        PreviewSection(
                            title: "Plan",
                            icon: "list.clipboard",
                            color: .orange,
                            content: plan
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Template Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview Section

struct PreviewSection: View {
    let title: String
    let icon: String
    let color: Color
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }

            Text(content)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(8)
        }
    }
}

// MARK: - Template Picker ViewModel

@MainActor
class TemplatePickerViewModel: ObservableObject {
    @Published var templates: [DocumentationTemplate] = []
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    var filteredTemplates: [DocumentationTemplate] {
        if searchQuery.isEmpty {
            return templates
        }
        return templates.filter { template in
            template.name.localizedCaseInsensitiveContains(searchQuery) ||
            (template.description?.localizedCaseInsensitiveContains(searchQuery) ?? false) ||
            (template.category?.localizedCaseInsensitiveContains(searchQuery) ?? false)
        }
    }

    var systemTemplates: [DocumentationTemplate] {
        filteredTemplates.filter { $0.isSystem }
    }

    var userTemplates: [DocumentationTemplate] {
        filteredTemplates.filter { !$0.isSystem }
    }

    func loadTemplates(type: DocumentationTemplateType) async {
        isLoading = true
        errorMessage = nil

        do {
            let response: [TemplateResponse] = try await PTSupabaseClient.shared.client
                .from("documentation_templates")
                .select("*")
                .eq("template_type", value: type.rawValue)
                .eq("is_active", value: true)
                .order("is_system", ascending: false)
                .order("usage_count", ascending: false)
                .execute()
                .value

            templates = response.map { resp in
                DocumentationTemplate(
                    id: resp.id,
                    name: resp.name,
                    subjectiveTemplate: resp.subjectiveTemplate,
                    objectiveTemplate: resp.objectiveTemplate,
                    assessmentTemplate: resp.assessmentTemplate,
                    planTemplate: resp.planTemplate,
                    description: resp.description,
                    category: resp.category,
                    isSystem: resp.isSystem,
                    usageCount: resp.usageCount
                )
            }
        } catch {
            errorMessage = error.localizedDescription
            // Load sample templates for preview/development
            templates = DocumentationTemplate.sampleTemplates
        }

        isLoading = false
    }
}

// MARK: - Supporting Types

enum DocumentationTemplateType: String {
    case soapNote = "soap_note"
    case progressNote = "progress_note"
    case evaluationNote = "evaluation_note"
    case dischargeNote = "discharge_note"
}

struct TemplateResponse: Codable {
    let id: UUID
    let name: String
    let description: String?
    let category: String?
    let templateType: String
    let subjectiveTemplate: String?
    let objectiveTemplate: String?
    let assessmentTemplate: String?
    let planTemplate: String?
    let isSystem: Bool
    let isActive: Bool
    let usageCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, description, category
        case templateType = "template_type"
        case subjectiveTemplate = "subjective_template"
        case objectiveTemplate = "objective_template"
        case assessmentTemplate = "assessment_template"
        case planTemplate = "plan_template"
        case isSystem = "is_system"
        case isActive = "is_active"
        case usageCount = "usage_count"
    }
}

// Extension for DocumentationTemplate
extension DocumentationTemplate {
    var description: String? { nil }
    var category: String? { nil }
    var isSystem: Bool { true }
    var usageCount: Int? { nil }

    init(id: UUID, name: String, subjectiveTemplate: String?, objectiveTemplate: String?, assessmentTemplate: String?, planTemplate: String?, description: String? = nil, category: String? = nil, isSystem: Bool = false, usageCount: Int? = nil) {
        self.id = id
        self.name = name
        self.subjectiveTemplate = subjectiveTemplate
        self.objectiveTemplate = objectiveTemplate
        self.assessmentTemplate = assessmentTemplate
        self.planTemplate = planTemplate
    }

    static var sampleTemplates: [DocumentationTemplate] {
        [
            DocumentationTemplate(
                id: UUID(),
                name: "Initial Evaluation",
                subjectiveTemplate: "Patient presents with chief complaint of [CONDITION]. Onset: [TIMEFRAME]. Mechanism of injury: [MOI]. Pain level: [0-10]. Aggravating factors: [FACTORS]. Relieving factors: [FACTORS]. Prior treatment: [TREATMENTS].",
                objectiveTemplate: "Observation: [FINDINGS]\nPalpation: [FINDINGS]\nROM: [MEASUREMENTS]\nStrength: [MMT GRADES]\nSpecial tests: [TESTS AND RESULTS]\nPosture: [FINDINGS]",
                assessmentTemplate: "Patient presents with [DIAGNOSIS/IMPAIRMENTS]. Prognosis: [GOOD/FAIR/POOR]. Rehabilitation potential: [HIGH/MODERATE/LOW].",
                planTemplate: "Frequency: [X] times per week for [Y] weeks\nGoals:\n1. [SHORT TERM GOAL]\n2. [LONG TERM GOAL]\nInterventions:\n- Therapeutic exercise\n- Manual therapy\n- Patient education",
                isSystem: true,
                usageCount: 156
            ),
            DocumentationTemplate(
                id: UUID(),
                name: "Treatment Session",
                subjectiveTemplate: "Patient reports [SYMPTOMS]. Current pain level: [0-10]. Progress since last visit: [BETTER/SAME/WORSE]. Home exercise compliance: [%].",
                objectiveTemplate: "ROM: [MEASUREMENTS]\nStrength: [MMT GRADES]\nFunctional status: [FINDINGS]\nResponse to treatment: [RESPONSE]",
                assessmentTemplate: "Patient [PROGRESSING/NOT PROGRESSING] toward goals. Current functional limitations: [LIMITATIONS].",
                planTemplate: "Continue current plan of care.\nModifications: [IF ANY]\nHome exercise program: [UPDATED/UNCHANGED]\nNext visit: [DATE]",
                isSystem: true,
                usageCount: 342
            ),
            DocumentationTemplate(
                id: UUID(),
                name: "Shoulder Evaluation",
                subjectiveTemplate: "Patient presents with shoulder pain. Location: [ANTERIOR/POSTERIOR/LATERAL]. Onset: [DATE/TIMEFRAME]. Mechanism: [TRAUMA/OVERUSE/INSIDIOUS]. Night pain: [YES/NO]. Overhead activities: [PAINFUL/LIMITED].",
                objectiveTemplate: "Active ROM:\n- Flexion: ___/180\n- Abduction: ___/180\n- ER at 90: ___/90\n- IR at 90: ___/70\n\nStrength (MMT):\n- Supraspinatus: ___/5\n- Infraspinatus: ___/5\n- Subscapularis: ___/5\n\nSpecial Tests:\n- Neer: +/-\n- Hawkins-Kennedy: +/-\n- Empty can: +/-\n- O'Brien: +/-",
                assessmentTemplate: "Patient presents with [DIAGNOSIS]. Contributing factors include: [FACTORS]. Differential diagnosis: [DDX].",
                planTemplate: "Treatment frequency: 2x/week for 6 weeks\nShort-term goals (4 weeks):\n1. Reduce pain to 3/10\n2. Improve ROM to functional levels\n\nLong-term goals (8 weeks):\n1. Return to [ACTIVITY]\n2. Independent with HEP",
                isSystem: true,
                usageCount: 89
            )
        ]
    }
}

// MARK: - Preview

#if DEBUG
struct TemplatePickerView_Previews: PreviewProvider {
    static var previews: some View {
        TemplatePickerView(templateType: .soapNote) { _ in }
            .preferredColorScheme(.light)

        TemplatePickerView(templateType: .soapNote) { _ in }
            .preferredColorScheme(.dark)
    }
}
#endif
