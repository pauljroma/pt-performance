//
//  BiomarkerDashboardViewModel.swift
//  PTPerformance
//
//  ViewModel for the Biomarker Dashboard
//  Fetches, groups, and calculates trends for biomarker data
//

import SwiftUI
import Foundation

/// Biomarker category for grouping related markers
enum BiomarkerCategory: String, CaseIterable, Identifiable {
    case lipidPanel = "Lipid Panel"
    case metabolic = "Metabolic"
    case thyroid = "Thyroid"
    case hormones = "Hormones"
    case cbc = "CBC"
    case vitamins = "Vitamins"
    case inflammation = "Inflammation"
    case liver = "Liver"
    case kidney = "Kidney"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .lipidPanel: return "heart.fill"
        case .metabolic: return "bolt.fill"
        case .thyroid: return "thermometer.medium"
        case .hormones: return "waveform.path.ecg"
        case .cbc: return "drop.fill"
        case .vitamins: return "pill.fill"
        case .inflammation: return "flame.fill"
        case .liver: return "cross.case.fill"
        case .kidney: return "water.waves"
        case .other: return "chart.bar.fill"
        }
    }

    var color: Color {
        switch self {
        case .lipidPanel: return .red
        case .metabolic: return .orange
        case .thyroid: return .purple
        case .hormones: return .blue
        case .cbc: return .pink
        case .vitamins: return .green
        case .inflammation: return .red
        case .liver: return .yellow
        case .kidney: return .cyan
        case .other: return .gray
        }
    }

    /// Map common biomarker names to categories
    static func category(for biomarkerName: String) -> BiomarkerCategory {
        let name = biomarkerName.lowercased()

        // Lipid Panel
        if name.contains("cholesterol") || name.contains("ldl") || name.contains("hdl") ||
           name.contains("triglyceride") || name.contains("vldl") || name.contains("lipid") {
            return .lipidPanel
        }

        // Metabolic
        if name.contains("glucose") || name.contains("insulin") || name.contains("a1c") ||
           name.contains("hemoglobin a1c") || name.contains("hba1c") || name.contains("fasting glucose") {
            return .metabolic
        }

        // Thyroid
        if name.contains("tsh") || name.contains("t3") || name.contains("t4") ||
           name.contains("thyroid") || name.contains("thyroxine") {
            return .thyroid
        }

        // Hormones
        if name.contains("testosterone") || name.contains("estrogen") || name.contains("estradiol") ||
           name.contains("cortisol") || name.contains("dhea") || name.contains("progesterone") ||
           name.contains("shbg") || name.contains("fsh") || name.contains("lh") ||
           name.contains("prolactin") || name.contains("igf") {
            return .hormones
        }

        // CBC
        if name.contains("rbc") || name.contains("wbc") || name.contains("hemoglobin") ||
           name.contains("hematocrit") || name.contains("platelet") || name.contains("mcv") ||
           name.contains("mch") || name.contains("mchc") || name.contains("rdw") ||
           name.contains("neutrophil") || name.contains("lymphocyte") || name.contains("monocyte") ||
           name.contains("eosinophil") || name.contains("basophil") {
            return .cbc
        }

        // Vitamins
        if name.contains("vitamin") || name.contains("b12") || name.contains("folate") ||
           name.contains("iron") || name.contains("ferritin") || name.contains("tibc") ||
           name.contains("zinc") || name.contains("magnesium") || name.contains("calcium") ||
           name.contains("d,") || name.contains("d3") || name.contains("d 25") {
            return .vitamins
        }

        // Inflammation
        if name.contains("crp") || name.contains("c-reactive") || name.contains("sed rate") ||
           name.contains("esr") || name.contains("homocysteine") || name.contains("fibrinogen") {
            return .inflammation
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
        normalHigh: Double? = nil
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

    @Published var biomarkerSummaries: [BiomarkerSummary] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedCategory: BiomarkerCategory?
    @Published var searchText = ""

    // Detail View State
    @Published var selectedBiomarker: BiomarkerSummary?
    @Published var biomarkerHistory: [BiomarkerTrendPoint] = []
    @Published var isLoadingHistory = false

    // MARK: - Private Properties

    private let labService = LabResultService.shared
    private var hasLoadedInitialData = false

    // MARK: - Computed Properties

    /// Biomarkers grouped by category
    var groupedBiomarkers: [BiomarkerCategory: [BiomarkerSummary]] {
        Dictionary(grouping: filteredBiomarkers, by: { $0.category })
    }

    /// Categories with biomarkers, sorted
    var categoriesWithBiomarkers: [BiomarkerCategory] {
        let categories = Set(filteredBiomarkers.map { $0.category })
        return BiomarkerCategory.allCases.filter { categories.contains($0) }
    }

    /// Filtered biomarkers based on search and category
    var filteredBiomarkers: [BiomarkerSummary] {
        var result = biomarkerSummaries

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }

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

    // MARK: - Public Methods

    /// Load biomarker dashboard data
    func loadDashboard() async {
        guard !hasLoadedInitialData else { return }

        isLoading = true
        error = nil
        hasLoadedInitialData = true

        // Fetch lab results from service
        await labService.fetchLabResults()

        if let serviceError = labService.error {
            error = serviceError.localizedDescription
            isLoading = false
            return
        }

        // Process lab results into biomarker summaries
        await processBiomarkers()

        isLoading = false
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
                        normalHigh: marker.referenceMax
                    )
                } else {
                    // Update history count for existing biomarker
                    if var existing = summaries[marker.name] {
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
                            normalHigh: existing.normalHigh ?? marker.referenceMax
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
