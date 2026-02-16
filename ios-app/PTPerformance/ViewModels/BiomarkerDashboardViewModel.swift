//
//  BiomarkerDashboardViewModel.swift
//  PTPerformance
//
//  ViewModel for the Biomarker Dashboard
//  Fetches, groups, and calculates trends for biomarker data
//  Includes training impact insights and recommendations
//

import SwiftUI
import Foundation

// MARK: - Training Impact Models

/// Training impact insight based on biomarker values
struct TrainingImpact: Identifiable, Equatable {
    let id: UUID
    let biomarkerName: String
    let insight: String
    let recommendations: [String]
    let severity: TrainingImpactSeverity
    let actionButtonTitle: String?

    init(
        id: UUID = UUID(),
        biomarkerName: String,
        insight: String,
        recommendations: [String],
        severity: TrainingImpactSeverity,
        actionButtonTitle: String? = nil
    ) {
        self.id = id
        self.biomarkerName = biomarkerName
        self.insight = insight
        self.recommendations = recommendations
        self.severity = severity
        self.actionButtonTitle = actionButtonTitle
    }
}

/// Severity level for training impacts
enum TrainingImpactSeverity: String, CaseIterable {
    case info = "info"
    case moderate = "moderate"
    case significant = "significant"

    var color: Color {
        switch self {
        case .info: return .modusCyan
        case .moderate: return .orange
        case .significant: return .red
        }
    }

    var icon: String {
        switch self {
        case .info: return "lightbulb.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .significant: return "exclamationmark.octagon.fill"
        }
    }
}

/// System status summary for a biomarker category
struct CategorySystemStatus: Identifiable, Equatable {
    let id: UUID
    let category: BiomarkerCategory
    let status: SystemStatusLevel
    let optimalCount: Int
    let attentionCount: Int
    let criticalCount: Int
    let totalCount: Int

    init(
        id: UUID = UUID(),
        category: BiomarkerCategory,
        status: SystemStatusLevel,
        optimalCount: Int,
        attentionCount: Int,
        criticalCount: Int,
        totalCount: Int
    ) {
        self.id = id
        self.category = category
        self.status = status
        self.optimalCount = optimalCount
        self.attentionCount = attentionCount
        self.criticalCount = criticalCount
        self.totalCount = totalCount
    }
}

/// System status level for categories
enum SystemStatusLevel: String, CaseIterable {
    case optimal = "optimal"
    case attention = "attention"
    case critical = "critical"

    var emoji: String {
        switch self {
        case .optimal: return "checkmark.circle.fill"
        case .attention: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .optimal: return .modusTealAccent
        case .attention: return .orange
        case .critical: return .red
        }
    }

    var displayText: String {
        switch self {
        case .optimal: return "Optimal"
        case .attention: return "Attention"
        case .critical: return "Critical"
        }
    }
}

// MARK: - Biomarker Category

/// Biomarker category for grouping related markers
enum BiomarkerCategory: String, CaseIterable, Identifiable {
    case inflammation = "Inflammation"
    case hormones = "Hormones"
    case metabolic = "Metabolic"
    case vitamins = "Vitamins"
    case minerals = "Minerals"
    case lipidPanel = "Lipids"
    case thyroid = "Thyroid"
    case cbc = "CBC"
    case liver = "Liver"
    case kidney = "Kidney"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .inflammation: return "flame.fill"
        case .hormones: return "waveform.path.ecg"
        case .metabolic: return "bolt.fill"
        case .vitamins: return "pill.fill"
        case .minerals: return "atom"
        case .lipidPanel: return "heart.fill"
        case .thyroid: return "thermometer.medium"
        case .cbc: return "drop.fill"
        case .liver: return "cross.case.fill"
        case .kidney: return "water.waves"
        case .other: return "chart.bar.fill"
        }
    }

    var color: Color {
        switch self {
        case .inflammation: return .red
        case .hormones: return .blue
        case .metabolic: return .orange
        case .vitamins: return .green
        case .minerals: return .purple
        case .lipidPanel: return .pink
        case .thyroid: return .indigo
        case .cbc: return .cyan
        case .liver: return .yellow
        case .kidney: return .teal
        case .other: return .gray
        }
    }

    /// Training-relevant explanation for this category
    var trainingExplanation: String {
        switch self {
        case .inflammation:
            return "Inflammation markers affect recovery time and training capacity"
        case .hormones:
            return "Hormones drive muscle growth, energy, and recovery"
        case .metabolic:
            return "Metabolic markers indicate energy availability and glucose control"
        case .vitamins:
            return "Vitamins support immune function, energy production, and tissue repair"
        case .minerals:
            return "Minerals are critical for muscle contraction and nerve function"
        case .lipidPanel:
            return "Lipids affect cardiovascular health and energy metabolism"
        case .thyroid:
            return "Thyroid hormones regulate metabolism and energy expenditure"
        case .cbc:
            return "Blood cells carry oxygen and fight infection during training"
        case .liver:
            return "Liver function affects protein synthesis and toxin clearance"
        case .kidney:
            return "Kidney function impacts hydration and waste removal"
        case .other:
            return "Various markers that may affect overall health"
        }
    }

    /// Map common biomarker names to categories
    static func category(for biomarkerName: String) -> BiomarkerCategory {
        let name = biomarkerName.lowercased()

        // Inflammation
        if name.contains("crp") || name.contains("c-reactive") || name.contains("sed rate") ||
           name.contains("esr") || name.contains("homocysteine") || name.contains("fibrinogen") ||
           name.contains("interleukin") || name.contains("tnf") {
            return .inflammation
        }

        // Hormones
        if name.contains("testosterone") || name.contains("estrogen") || name.contains("estradiol") ||
           name.contains("cortisol") || name.contains("dhea") || name.contains("progesterone") ||
           name.contains("shbg") || name.contains("fsh") || name.contains("lh") ||
           name.contains("prolactin") || name.contains("igf") || name.contains("growth hormone") {
            return .hormones
        }

        // Metabolic
        if name.contains("glucose") || name.contains("insulin") || name.contains("a1c") ||
           name.contains("hemoglobin a1c") || name.contains("hba1c") || name.contains("fasting glucose") {
            return .metabolic
        }

        // Vitamins
        if name.contains("vitamin") || name.contains("b12") || name.contains("folate") ||
           name.contains("d,") || name.contains("d3") || name.contains("d 25") ||
           name.contains("thiamine") || name.contains("riboflavin") || name.contains("niacin") {
            return .vitamins
        }

        // Minerals
        if name.contains("iron") || name.contains("ferritin") || name.contains("tibc") ||
           name.contains("zinc") || name.contains("magnesium") || name.contains("calcium") ||
           name.contains("potassium") || name.contains("sodium") || name.contains("phosphorus") ||
           name.contains("copper") || name.contains("selenium") {
            return .minerals
        }

        // Lipid Panel
        if name.contains("cholesterol") || name.contains("ldl") || name.contains("hdl") ||
           name.contains("triglyceride") || name.contains("vldl") || name.contains("lipid") ||
           name.contains("apolipoprotein") {
            return .lipidPanel
        }

        // Thyroid
        if name.contains("tsh") || name.contains("t3") || name.contains("t4") ||
           name.contains("thyroid") || name.contains("thyroxine") {
            return .thyroid
        }

        // CBC
        if name.contains("rbc") || name.contains("wbc") || name.contains("hemoglobin") ||
           name.contains("hematocrit") || name.contains("platelet") || name.contains("mcv") ||
           name.contains("mch") || name.contains("mchc") || name.contains("rdw") ||
           name.contains("neutrophil") || name.contains("lymphocyte") || name.contains("monocyte") ||
           name.contains("eosinophil") || name.contains("basophil") {
            return .cbc
        }

        // Liver
        if name.contains("alt") || name.contains("ast") || name.contains("alp") ||
           name.contains("bilirubin") || name.contains("albumin") || name.contains("ggt") ||
           name.contains("liver") {
            return .liver
        }

        // Kidney
        if name.contains("creatinine") || name.contains("bun") || name.contains("urea") ||
           name.contains("egfr") || name.contains("uric acid") || name.contains("kidney") {
            return .kidney
        }

        return .other
    }
}

/// Trend direction for a biomarker
enum BiomarkerTrend: String {
    case increasing = "increasing"
    case decreasing = "decreasing"
    case stable = "stable"
    case unknown = "unknown"

    var icon: String {
        switch self {
        case .increasing: return "arrow.up"
        case .decreasing: return "arrow.down"
        case .stable: return "arrow.forward"
        case .unknown: return "minus"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .increasing: return "trending up"
        case .decreasing: return "trending down"
        case .stable: return "stable"
        case .unknown: return "trend unknown"
        }
    }
}

/// Summary of a biomarker for dashboard display
struct BiomarkerSummary: Identifiable, Equatable {
    let id: UUID
    let name: String
    let displayName: String
    let category: BiomarkerCategory
    let currentValue: Double
    let unit: String
    let status: BiomarkerStatus
    let trend: BiomarkerTrend
    let lastUpdated: Date
    let historyCount: Int
    let optimalLow: Double?
    let optimalHigh: Double?
    let normalLow: Double?
    let normalHigh: Double?
    let trainingRelevance: String?

    init(
        id: UUID = UUID(),
        name: String,
        displayName: String? = nil,
        category: BiomarkerCategory,
        currentValue: Double,
        unit: String,
        status: BiomarkerStatus,
        trend: BiomarkerTrend = .unknown,
        lastUpdated: Date,
        historyCount: Int = 1,
        optimalLow: Double? = nil,
        optimalHigh: Double? = nil,
        normalLow: Double? = nil,
        normalHigh: Double? = nil,
        trainingRelevance: String? = nil
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName ?? name
        self.category = category
        self.currentValue = currentValue
        self.unit = unit
        self.status = status
        self.trend = trend
        self.lastUpdated = lastUpdated
        self.historyCount = historyCount
        self.optimalLow = optimalLow
        self.optimalHigh = optimalHigh
        self.normalLow = normalLow
        self.normalHigh = normalHigh
        self.trainingRelevance = trainingRelevance
    }

    /// Formatted value string
    var formattedValue: String {
        if currentValue >= 1000 {
            return String(format: "%.0f", currentValue)
        } else if currentValue >= 100 {
            return String(format: "%.1f", currentValue)
        } else if currentValue >= 10 {
            return String(format: "%.1f", currentValue)
        } else {
            return String(format: "%.2f", currentValue)
        }
    }

    static func == (lhs: BiomarkerSummary, rhs: BiomarkerSummary) -> Bool {
        lhs.id == rhs.id
    }
}

/// ViewModel for the Biomarker Dashboard
@MainActor
final class BiomarkerDashboardViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var biomarkerSummaries: [BiomarkerSummary] = [] {
        didSet {
            // Invalidate caches when data changes
            cachedFilteredBiomarkers = nil
            cachedGroupedBiomarkers = nil
        }
    }
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedCategory: BiomarkerCategory? {
        didSet {
            // Invalidate cached filtered results when category changes
            cachedFilteredBiomarkers = nil
            cachedGroupedBiomarkers = nil
        }
    }
    @Published var searchText = "" {
        didSet {
            // Invalidate cached filtered results when search text changes
            cachedFilteredBiomarkers = nil
            cachedGroupedBiomarkers = nil
        }
    }

    // Training Impact State
    @Published var trainingImpacts: [TrainingImpact] = []
    @Published var categoryStatuses: [CategorySystemStatus] = []

    // Detail View State
    @Published var selectedBiomarker: BiomarkerSummary?
    @Published var biomarkerHistory: [BiomarkerTrendPoint] = []
    @Published var isLoadingHistory = false

    // MARK: - Private Properties

    private let labService = LabResultService.shared
    private var hasLoadedInitialData = false

    // Performance: Cache expensive computed properties
    private var cachedFilteredBiomarkers: [BiomarkerSummary]?
    private var cachedGroupedBiomarkers: [BiomarkerCategory: [BiomarkerSummary]]?

    // MARK: - Computed Properties

    /// Biomarkers grouped by category
    /// Uses caching to avoid redundant grouping operations
    var groupedBiomarkers: [BiomarkerCategory: [BiomarkerSummary]] {
        if let cached = cachedGroupedBiomarkers {
            return cached
        }

        let grouped = Dictionary(grouping: filteredBiomarkers, by: { $0.category })
        cachedGroupedBiomarkers = grouped
        return grouped
    }

    /// Categories with biomarkers, sorted
    var categoriesWithBiomarkers: [BiomarkerCategory] {
        let categories = Set(filteredBiomarkers.map { $0.category })
        return BiomarkerCategory.allCases.filter { categories.contains($0) }
    }

    /// Filtered biomarkers based on search and category
    /// Uses caching to avoid redundant filtering operations
    var filteredBiomarkers: [BiomarkerSummary] {
        if let cached = cachedFilteredBiomarkers {
            return cached
        }

        var result = biomarkerSummaries

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(lowercasedSearch) ||
                $0.displayName.lowercased().contains(lowercasedSearch)
            }
        }

        cachedFilteredBiomarkers = result
        return result
    }

    /// Count of biomarkers by status
    var statusCounts: (optimal: Int, normal: Int, concern: Int) {
        let optimal = biomarkerSummaries.filter { $0.status == .optimal }.count
        let normal = biomarkerSummaries.filter { $0.status == .normal }.count
        let concern = biomarkerSummaries.filter { $0.status == .low || $0.status == .high || $0.status == .critical }.count
        return (optimal, normal, concern)
    }

    /// Biomarkers that need attention
    var concerningBiomarkers: [BiomarkerSummary] {
        biomarkerSummaries.filter { $0.status == .low || $0.status == .high || $0.status == .critical }
    }

    /// Most recent lab result date
    var lastLabDate: Date? {
        biomarkerSummaries.map { $0.lastUpdated }.max()
    }

    /// Days since last lab update
    var daysSinceLastLab: Int? {
        guard let lastDate = lastLabDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day
    }

    /// Status summary text for display
    var statusSummaryText: String {
        let counts = statusCounts
        var parts: [String] = []

        if counts.concern > 0 {
            parts.append("\(counts.concern) marker\(counts.concern == 1 ? "" : "s") need\(counts.concern == 1 ? "s" : "") attention")
        }
        if counts.optimal > 0 {
            parts.append("\(counts.optimal) marker\(counts.optimal == 1 ? "" : "s") optimal")
        }

        return parts.joined(separator: " | ")
    }

    /// Primary training insight to display (most significant)
    var primaryTrainingImpact: TrainingImpact? {
        // Return the most significant impact first
        trainingImpacts.first { $0.severity == .significant } ??
        trainingImpacts.first { $0.severity == .moderate } ??
        trainingImpacts.first
    }

    /// Whether there are any training impacts to show
    var hasTrainingImpacts: Bool {
        !trainingImpacts.isEmpty
    }

    // MARK: - Public Methods

    /// Load biomarker dashboard data
    func loadDashboard() async {
        guard !hasLoadedInitialData else { return }

        isLoading = true
        defer { isLoading = false }
        error = nil
        hasLoadedInitialData = true

        // Fetch lab results from service
        await labService.fetchLabResults()

        if let serviceError = labService.error {
            error = serviceError.localizedDescription
            return
        }

        // Process lab results into biomarker summaries
        await processBiomarkers()

        // Generate training impacts based on biomarker values
        generateTrainingImpacts()

        // Calculate category statuses
        calculateCategoryStatuses()
    }

    /// Force refresh the dashboard
    func refreshDashboard() async {
        hasLoadedInitialData = false
        await loadDashboard()
    }

    /// Load history for a specific biomarker
    func loadBiomarkerHistory(for biomarker: BiomarkerSummary) async {
        selectedBiomarker = biomarker
        isLoadingHistory = true

        do {
            biomarkerHistory = try await labService.fetchBiomarkerHistory(
                biomarkerType: biomarker.name,
                limit: 20
            )
        } catch {
            DebugLogger.shared.error("BiomarkerDashboardViewModel", "Failed to load history: \(error)")
            biomarkerHistory = []
        }

        isLoadingHistory = false
    }

    /// Clear selected biomarker state
    func clearSelection() {
        selectedBiomarker = nil
        biomarkerHistory = []
    }

    /// Dismiss a training impact
    func dismissTrainingImpact(_ impact: TrainingImpact) {
        trainingImpacts.removeAll { $0.id == impact.id }
    }

    /// Get system status for a specific category
    func systemStatus(for category: BiomarkerCategory) -> CategorySystemStatus? {
        categoryStatuses.first { $0.category == category }
    }

    // MARK: - Private Methods

    /// Process lab results into biomarker summaries
    private func processBiomarkers() async {
        var summaries: [String: BiomarkerSummary] = [:]

        // Get all lab results sorted by date (newest first)
        let sortedResults = labService.labResults.sorted { ($0.testDate ?? Date.distantPast) > ($1.testDate ?? Date.distantPast) }

        // Process each result
        for labResult in sortedResults {
            for marker in labResult.resultsList {
                // Only add if we haven't seen this biomarker yet (newest first)
                if summaries[marker.name] == nil {
                    let category = BiomarkerCategory.category(for: marker.name)
                    let status = mapMarkerStatus(marker.status)
                    let trainingRelevance = generateTrainingRelevance(for: marker.name, status: status, value: marker.value)

                    summaries[marker.name] = BiomarkerSummary(
                        id: marker.id,
                        name: marker.name,
                        displayName: formatBiomarkerName(marker.name),
                        category: category,
                        currentValue: marker.value,
                        unit: marker.unit,
                        status: status,
                        trend: .unknown,
                        lastUpdated: labResult.testDate ?? Date(),
                        historyCount: 1,
                        optimalLow: nil,
                        optimalHigh: nil,
                        normalLow: marker.referenceMin,
                        normalHigh: marker.referenceMax,
                        trainingRelevance: trainingRelevance
                    )
                } else {
                    // Update history count for existing biomarker
                    if let existing = summaries[marker.name] {
                        summaries[marker.name] = BiomarkerSummary(
                            id: existing.id,
                            name: existing.name,
                            displayName: existing.displayName,
                            category: existing.category,
                            currentValue: existing.currentValue,
                            unit: existing.unit,
                            status: existing.status,
                            trend: calculateTrend(current: existing.currentValue, previous: marker.value),
                            lastUpdated: existing.lastUpdated,
                            historyCount: existing.historyCount + 1,
                            optimalLow: existing.optimalLow,
                            optimalHigh: existing.optimalHigh,
                            normalLow: existing.normalLow ?? marker.referenceMin,
                            normalHigh: existing.normalHigh ?? marker.referenceMax,
                            trainingRelevance: existing.trainingRelevance
                        )
                    }
                }
            }
        }

        // Sort by category and then by name
        biomarkerSummaries = summaries.values.sorted {
            if $0.category == $1.category {
                return $0.displayName < $1.displayName
            }
            return $0.category.rawValue < $1.category.rawValue
        }
    }

    /// Generate training-relevant explanation for a biomarker
    private func generateTrainingRelevance(for name: String, status: BiomarkerStatus, value: Double) -> String? {
        let lowercaseName = name.lowercased()

        // CRP / Inflammation
        if lowercaseName.contains("crp") || lowercaseName.contains("c-reactive") {
            switch status {
            case .high, .critical:
                return "Elevated inflammation may slow recovery and increase injury risk"
            case .optimal:
                return "Low inflammation supports faster recovery between sessions"
            default:
                return "Inflammation levels affect recovery capacity"
            }
        }

        // Testosterone
        if lowercaseName.contains("testosterone") {
            switch status {
            case .low:
                return "Low testosterone may reduce muscle building capacity and recovery"
            case .optimal:
                return "Optimal testosterone supports muscle growth and training adaptation"
            default:
                return "Testosterone influences strength gains and recovery"
            }
        }

        // Cortisol
        if lowercaseName.contains("cortisol") {
            switch status {
            case .high:
                return "Elevated cortisol indicates stress; consider deload or extra recovery"
            case .low:
                return "Low cortisol may indicate adrenal fatigue from overtraining"
            default:
                return "Cortisol balance affects recovery and muscle preservation"
            }
        }

        // Vitamin D
        if lowercaseName.contains("vitamin d") || lowercaseName.contains("d3") || lowercaseName.contains("d 25") {
            switch status {
            case .low:
                return "Low vitamin D may impair muscle function and bone health"
            case .optimal:
                return "Adequate vitamin D supports muscle strength and immune function"
            default:
                return "Vitamin D is essential for muscle and bone health"
            }
        }

        // Ferritin / Iron
        if lowercaseName.contains("ferritin") || lowercaseName.contains("iron") {
            switch status {
            case .low:
                return "Low iron stores may reduce endurance and cause fatigue"
            case .optimal:
                return "Good iron stores support oxygen delivery during exercise"
            default:
                return "Iron is critical for oxygen transport during training"
            }
        }

        // B12
        if lowercaseName.contains("b12") {
            switch status {
            case .low:
                return "Low B12 may cause fatigue and reduced energy production"
            case .optimal:
                return "Adequate B12 supports energy metabolism and nerve function"
            default:
                return "B12 is essential for energy production"
            }
        }

        // Glucose / HbA1c
        if lowercaseName.contains("glucose") || lowercaseName.contains("a1c") {
            switch status {
            case .high:
                return "Elevated glucose may indicate metabolic stress affecting performance"
            case .optimal:
                return "Well-controlled glucose supports consistent energy during training"
            default:
                return "Blood sugar control affects energy availability"
            }
        }

        // Hemoglobin
        if lowercaseName.contains("hemoglobin") && !lowercaseName.contains("a1c") {
            switch status {
            case .low:
                return "Low hemoglobin reduces oxygen-carrying capacity for endurance"
            case .optimal:
                return "Good hemoglobin levels support aerobic performance"
            default:
                return "Hemoglobin determines oxygen delivery to muscles"
            }
        }

        // Creatinine
        if lowercaseName.contains("creatinine") {
            switch status {
            case .high:
                return "Elevated creatinine may indicate dehydration or kidney stress"
            default:
                return "Creatinine reflects muscle mass and kidney function"
            }
        }

        // TSH
        if lowercaseName.contains("tsh") {
            switch status {
            case .high:
                return "Elevated TSH may indicate low thyroid function affecting metabolism"
            case .low:
                return "Low TSH may indicate overactive thyroid affecting recovery"
            default:
                return "Thyroid function regulates metabolism and energy"
            }
        }

        return nil
    }

    /// Generate training impacts based on concerning biomarkers
    private func generateTrainingImpacts() {
        var impacts: [TrainingImpact] = []

        for biomarker in concerningBiomarkers {
            if let impact = generateTrainingImpact(for: biomarker) {
                impacts.append(impact)
            }
        }

        // Sort by severity (most significant first)
        trainingImpacts = impacts.sorted { first, second in
            let severityOrder: [TrainingImpactSeverity] = [.significant, .moderate, .info]
            let firstIndex = severityOrder.firstIndex(of: first.severity) ?? 0
            let secondIndex = severityOrder.firstIndex(of: second.severity) ?? 0
            return firstIndex < secondIndex
        }
    }

    /// Generate a training impact for a specific biomarker
    private func generateTrainingImpact(for biomarker: BiomarkerSummary) -> TrainingImpact? {
        let name = biomarker.name.lowercased()

        // CRP / C-Reactive Protein
        if name.contains("crp") || name.contains("c-reactive") {
            if biomarker.status == .high || biomarker.status == .critical {
                return TrainingImpact(
                    biomarkerName: biomarker.displayName,
                    insight: "Your elevated \(biomarker.displayName) suggests inflammation. Consider:",
                    recommendations: [
                        "Extra rest day this week",
                        "Reduce training volume 20%",
                        "Add omega-3 supplementation",
                        "Focus on sleep quality"
                    ],
                    severity: biomarker.status == .critical ? .significant : .moderate,
                    actionButtonTitle: "Adjust My Program"
                )
            }
        }

        // Testosterone
        if name.contains("testosterone") {
            if biomarker.status == .low {
                return TrainingImpact(
                    biomarkerName: biomarker.displayName,
                    insight: "Low testosterone may affect your training capacity. Consider:",
                    recommendations: [
                        "Prioritize compound movements",
                        "Ensure 7-9 hours of sleep",
                        "Include healthy fats in diet",
                        "Avoid overtraining"
                    ],
                    severity: .moderate,
                    actionButtonTitle: "Optimize Training"
                )
            }
        }

        // Cortisol
        if name.contains("cortisol") {
            if biomarker.status == .high {
                return TrainingImpact(
                    biomarkerName: biomarker.displayName,
                    insight: "Elevated cortisol indicates stress. Your body needs recovery:",
                    recommendations: [
                        "Take a deload week",
                        "Reduce high-intensity sessions",
                        "Practice stress management",
                        "Consider adaptogens like ashwagandha"
                    ],
                    severity: .significant,
                    actionButtonTitle: "Start Deload"
                )
            }
        }

        // Vitamin D
        if name.contains("vitamin d") || name.contains("d3") || name.contains("d 25") {
            if biomarker.status == .low {
                return TrainingImpact(
                    biomarkerName: biomarker.displayName,
                    insight: "Low vitamin D can impair muscle function. Recommendations:",
                    recommendations: [
                        "Take 2000-5000 IU vitamin D3 daily",
                        "Get 15-20 min sunlight exposure",
                        "Include fatty fish in diet",
                        "Retest in 3 months"
                    ],
                    severity: .moderate,
                    actionButtonTitle: "Add Supplement"
                )
            }
        }

        // Ferritin
        if name.contains("ferritin") {
            if biomarker.status == .low {
                return TrainingImpact(
                    biomarkerName: biomarker.displayName,
                    insight: "Low iron stores may be causing fatigue. Consider:",
                    recommendations: [
                        "Increase iron-rich foods (red meat, spinach)",
                        "Take iron with vitamin C",
                        "Avoid coffee/tea with meals",
                        "Consider iron supplementation"
                    ],
                    severity: .moderate,
                    actionButtonTitle: "View Nutrition Tips"
                )
            }
        }

        // B12
        if name.contains("b12") {
            if biomarker.status == .low {
                return TrainingImpact(
                    biomarkerName: biomarker.displayName,
                    insight: "Low B12 affects energy production. Recommendations:",
                    recommendations: [
                        "Take B12 supplement (methylcobalamin)",
                        "Include more animal products",
                        "Consider B-complex vitamin",
                        "Check for absorption issues"
                    ],
                    severity: .info,
                    actionButtonTitle: nil
                )
            }
        }

        // Glucose / HbA1c
        if name.contains("glucose") || name.contains("a1c") {
            if biomarker.status == .high {
                return TrainingImpact(
                    biomarkerName: biomarker.displayName,
                    insight: "Elevated blood sugar affects performance. Consider:",
                    recommendations: [
                        "Increase aerobic training",
                        "Reduce refined carbohydrates",
                        "Add post-meal walks",
                        "Monitor carb timing around workouts"
                    ],
                    severity: .moderate,
                    actionButtonTitle: "Adjust Nutrition"
                )
            }
        }

        // Hemoglobin
        if name.contains("hemoglobin") && !name.contains("a1c") {
            if biomarker.status == .low {
                return TrainingImpact(
                    biomarkerName: biomarker.displayName,
                    insight: "Low hemoglobin reduces oxygen delivery. Recommendations:",
                    recommendations: [
                        "Check iron and B12 levels",
                        "Increase iron-rich foods",
                        "Reduce endurance training temporarily",
                        "Stay well hydrated"
                    ],
                    severity: .moderate,
                    actionButtonTitle: nil
                )
            }
        }

        // TSH
        if name.contains("tsh") {
            if biomarker.status == .high || biomarker.status == .low {
                return TrainingImpact(
                    biomarkerName: biomarker.displayName,
                    insight: "Thyroid imbalance affects metabolism and energy. Consider:",
                    recommendations: [
                        "Consult with your physician",
                        "Monitor energy levels closely",
                        "Adjust training intensity as needed",
                        "Ensure adequate iodine and selenium"
                    ],
                    severity: .significant,
                    actionButtonTitle: nil
                )
            }
        }

        return nil
    }

    /// Calculate system status for each category
    private func calculateCategoryStatuses() {
        var statuses: [CategorySystemStatus] = []

        for category in categoriesWithBiomarkers {
            guard let biomarkers = groupedBiomarkers[category] else { continue }

            let optimalCount = biomarkers.filter { $0.status == .optimal }.count
            let criticalCount = biomarkers.filter { $0.status == .critical }.count
            let attentionCount = biomarkers.filter { $0.status == .low || $0.status == .high }.count

            let status: SystemStatusLevel
            if criticalCount > 0 {
                status = .critical
            } else if attentionCount > 0 {
                status = .attention
            } else {
                status = .optimal
            }

            statuses.append(CategorySystemStatus(
                category: category,
                status: status,
                optimalCount: optimalCount,
                attentionCount: attentionCount,
                criticalCount: criticalCount,
                totalCount: biomarkers.count
            ))
        }

        categoryStatuses = statuses
    }

    /// Map MarkerStatus to BiomarkerStatus
    private func mapMarkerStatus(_ status: MarkerStatus) -> BiomarkerStatus {
        switch status {
        case .normal: return .normal
        case .low: return .low
        case .high: return .high
        case .critical: return .critical
        }
    }

    /// Calculate trend direction
    private func calculateTrend(current: Double, previous: Double) -> BiomarkerTrend {
        let percentChange = ((current - previous) / previous) * 100

        if abs(percentChange) < 5 {
            return .stable
        } else if percentChange > 0 {
            return .increasing
        } else {
            return .decreasing
        }
    }

    /// Format biomarker name for display
    private func formatBiomarkerName(_ name: String) -> String {
        // Handle common abbreviations
        let abbreviations: [String: String] = [
            "ldl": "LDL Cholesterol",
            "hdl": "HDL Cholesterol",
            "vldl": "VLDL",
            "tsh": "TSH",
            "t3": "T3",
            "t4": "T4",
            "hba1c": "HbA1c",
            "a1c": "A1c",
            "rbc": "RBC",
            "wbc": "WBC",
            "mcv": "MCV",
            "mch": "MCH",
            "mchc": "MCHC",
            "rdw": "RDW",
            "crp": "CRP",
            "esr": "ESR",
            "alt": "ALT",
            "ast": "AST",
            "alp": "ALP",
            "ggt": "GGT",
            "bun": "BUN",
            "egfr": "eGFR",
            "tibc": "TIBC",
            "dhea": "DHEA-S",
            "shbg": "SHBG",
            "fsh": "FSH",
            "lh": "LH",
            "igf": "IGF-1"
        ]

        let lowercased = name.lowercased()

        for (abbrev, fullName) in abbreviations {
            if lowercased == abbrev || lowercased.hasPrefix(abbrev + " ") {
                return fullName
            }
        }

        // Title case the name
        return name.capitalized
    }
}
