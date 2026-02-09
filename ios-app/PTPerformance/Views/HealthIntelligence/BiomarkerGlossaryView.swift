//
//  BiomarkerGlossaryView.swift
//  PTPerformance
//
//  Biomarker Glossary - Educational reference for biomarkers
//  Lists biomarkers grouped by category with search functionality
//  Provides detailed information about what each biomarker means
//

import SwiftUI

// MARK: - Biomarker Glossary View

/// Main glossary view showing all biomarkers grouped by category
struct BiomarkerGlossaryView: View {
    @StateObject private var viewModel = BiomarkerGlossaryViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.filteredEducation.isEmpty && !viewModel.searchText.isEmpty {
                    searchEmptyState
                } else {
                    glossaryContent
                }
            }
            .navigationTitle("Biomarker Glossary")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $viewModel.searchText, prompt: "Search biomarkers")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .tint(.modusCyan)
    }

    // MARK: - Glossary Content

    private var glossaryContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Category Filter
                categoryFilter

                // Biomarker List
                biomarkerList
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                GlossaryCategoryChip(
                    title: "All",
                    isSelected: viewModel.selectedCategory == nil,
                    count: viewModel.allEducation.count
                ) {
                    withAnimation {
                        viewModel.selectedCategory = nil
                    }
                }

                ForEach(viewModel.categoriesWithContent) { category in
                    let count = viewModel.educationByCategory[category.rawValue]?.count ?? 0
                    GlossaryCategoryChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: viewModel.selectedCategory == category,
                        count: count
                    ) {
                        withAnimation {
                            viewModel.selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Biomarker List

    private var biomarkerList: some View {
        LazyVStack(spacing: Spacing.md, pinnedViews: [.sectionHeaders]) {
            ForEach(viewModel.categoriesWithFilteredContent) { category in
                if let biomarkers = viewModel.filteredEducationByCategory[category.rawValue], !biomarkers.isEmpty {
                    Section {
                        ForEach(biomarkers) { education in
                            NavigationLink {
                                BiomarkerEducationDetailView(education: education)
                            } label: {
                                BiomarkerGlossaryRow(education: education)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        GlossarySectionHeader(category: category, count: biomarkers.count)
                    }
                }
            }
        }
    }

    // MARK: - Search Empty State

    private var searchEmptyState: some View {
        ContentUnavailableView.search(text: viewModel.searchText)
    }
}

// MARK: - Glossary View Model

@MainActor
final class BiomarkerGlossaryViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedCategory: BiomarkerEducationCategory?

    var allEducation: [BiomarkerEducation] {
        BiomarkerEducation.allEducation
    }

    var educationByCategory: [String: [BiomarkerEducation]] {
        Dictionary(grouping: allEducation, by: { $0.category })
    }

    var categoriesWithContent: [BiomarkerEducationCategory] {
        let categoryStrings = Set(allEducation.map { $0.category })
        return BiomarkerEducationCategory.allCases.filter { categoryStrings.contains($0.rawValue) }
    }

    var filteredEducation: [BiomarkerEducation] {
        var result = allEducation

        if let category = selectedCategory {
            result = result.filter { $0.category == category.rawValue }
        }

        if !searchText.isEmpty {
            result = result.filter { $0.matches(searchText: searchText) }
        }

        return result.sorted { $0.displayName < $1.displayName }
    }

    var filteredEducationByCategory: [String: [BiomarkerEducation]] {
        Dictionary(grouping: filteredEducation, by: { $0.category })
    }

    var categoriesWithFilteredContent: [BiomarkerEducationCategory] {
        let categoryStrings = Set(filteredEducation.map { $0.category })
        return BiomarkerEducationCategory.allCases.filter { categoryStrings.contains($0.rawValue) }
    }
}

// MARK: - Glossary Category Chip

private struct GlossaryCategoryChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                Text("\(count)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.modusCyan : Color(.secondarySystemGroupedBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .accessibilityLabel("\(title), \(count) biomarkers")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Glossary Section Header

private struct GlossarySectionHeader: View {
    let category: BiomarkerEducationCategory
    let count: Int

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: category.icon)
                .font(.subheadline)
                .foregroundColor(.modusCyan)

            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.modusDeepTeal)

            Spacer()

            Text("\(count)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(8)
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, 4)
        .background(Color(.systemGroupedBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.rawValue), \(count) biomarkers")
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Glossary Row

private struct BiomarkerGlossaryRow: View {
    let education: BiomarkerEducation

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: categoryIcon)
                    .font(.title3)
                    .foregroundColor(categoryColor)
            }
            .accessibilityHidden(true)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(education.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.modusDeepTeal)

                Text(education.shortDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(education.displayName), \(education.shortDescription)")
        .accessibilityHint("Tap to learn more")
    }

    private var categoryColor: Color {
        switch BiomarkerEducationCategory.from(string: education.category) {
        case .inflammation: return .red
        case .hormones: return .blue
        case .metabolic: return .orange
        case .vitamins: return .green
        case .minerals: return .purple
        case .lipids: return .pink
        case .thyroid: return .indigo
        case .cbc: return .cyan
        case .liver: return .yellow
        case .kidney: return .teal
        case .other: return .gray
        }
    }

    private var categoryIcon: String {
        BiomarkerEducationCategory.from(string: education.category).icon
    }
}

// MARK: - Biomarker Education Detail View

struct BiomarkerEducationDetailView: View {
    let education: BiomarkerEducation
    @State private var selectedSex: Sex = .male

    enum Sex: String, CaseIterable {
        case male = "Male"
        case female = "Female"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Header Card
                headerCard

                // Description Section
                descriptionSection

                // Clinical Significance
                clinicalSignificanceSection

                // Reference Ranges
                referenceRangesSection

                // Dietary Sources
                dietarySourcesSection

                // Lifestyle Factors
                lifestyleFactorsSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(education.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(spacing: Spacing.md) {
            // Category badge
            HStack {
                Image(systemName: categoryIcon)
                    .font(.caption)
                    .foregroundColor(categoryColor)

                Text(education.category)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(categoryColor)

                Spacer()

                Text(education.unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(6)
            }

            // Biomarker name
            HStack {
                Text(education.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.modusDeepTeal)

                Spacer()
            }

            // Short description
            Text(education.shortDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "What is it?", icon: "info.circle.fill")

            Text(education.detailedDescription)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Clinical Significance Section

    private var clinicalSignificanceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "Why it matters", icon: "heart.text.square.fill")

            Text(education.clinicalSignificance)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Reference Ranges Section

    private var referenceRangesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "Optimal ranges", icon: "chart.bar.fill")

            // Sex Picker
            Picker("Sex", selection: $selectedSex) {
                ForEach(Sex.allCases, id: \.self) { sex in
                    Text(sex.rawValue).tag(sex)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, Spacing.xs)

            // Range Display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Optimal Range")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(selectedSex == .male ? (education.optimalRangeMale ?? "Not specified") : (education.optimalRangeFemale ?? "Not specified"))
                        .font(.headline)
                        .foregroundColor(.modusTealAccent)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Unit")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(education.unit)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color.modusTealAccent.opacity(0.1))
            .cornerRadius(CornerRadius.md)

            // Note about ranges
            HStack(alignment: .top, spacing: Spacing.xs) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Optimal ranges may differ from standard lab reference ranges. These values represent optimal health rather than just absence of disease.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, Spacing.xs)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Dietary Sources Section

    private var dietarySourcesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "Foods that affect it", icon: "leaf.fill")

            VStack(spacing: Spacing.xs) {
                ForEach(education.dietarySources, id: \.self) { source in
                    DietarySourceRow(source: source)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Lifestyle Factors Section

    private var lifestyleFactorsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "Lifestyle factors", icon: "figure.run")

            VStack(spacing: Spacing.xs) {
                ForEach(education.lifestyleFactors, id: \.self) { factor in
                    LifestyleFactorRow(factor: factor)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Helpers

    private var categoryColor: Color {
        switch BiomarkerEducationCategory.from(string: education.category) {
        case .inflammation: return .red
        case .hormones: return .blue
        case .metabolic: return .orange
        case .vitamins: return .green
        case .minerals: return .purple
        case .lipids: return .pink
        case .thyroid: return .indigo
        case .cbc: return .cyan
        case .liver: return .yellow
        case .kidney: return .teal
        case .other: return .gray
        }
    }

    private var categoryIcon: String {
        BiomarkerEducationCategory.from(string: education.category).icon
    }
}

// MARK: - Section Header View

private struct SectionHeaderView: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.modusCyan)

            Text(title)
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            Spacer()
        }
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Dietary Source Row

private struct DietarySourceRow: View {
    let source: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: isPositive ? "plus.circle.fill" : "minus.circle.fill")
                .font(.caption)
                .foregroundColor(isPositive ? .modusTealAccent : .orange)
                .frame(width: 16)

            Text(displayText)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var isPositive: Bool {
        !source.lowercased().hasPrefix("avoid") && !source.lowercased().hasPrefix("limit")
    }

    private var displayText: String {
        // Remove prefixes like "Anti-inflammatory: " or "Avoid: "
        if let colonIndex = source.firstIndex(of: ":") {
            return String(source[source.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
        }
        return source
    }
}

// MARK: - Lifestyle Factor Row

private struct LifestyleFactorRow: View {
    let factor: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.modusCyan)
                .frame(width: 16)

            Text(factor)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#if DEBUG
struct BiomarkerGlossaryView_Previews: PreviewProvider {
    static var previews: some View {
        BiomarkerGlossaryView()
    }
}

struct BiomarkerEducationDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BiomarkerEducationDetailView(
                education: BiomarkerEducation.allEducation.first!
            )
        }
    }
}
#endif
