//
//  BiomarkerEducation.swift
//  PTPerformance
//
//  Educational content for biomarkers
//  Provides detailed information about what each biomarker means,
//  dietary sources, lifestyle factors, and reference ranges
//

import Foundation

/// Educational content for a biomarker
struct BiomarkerEducation: Codable, Identifiable, Hashable {
    let id: UUID
    let biomarkerName: String
    let displayName: String
    let category: String
    let shortDescription: String
    let detailedDescription: String
    let clinicalSignificance: String
    let dietarySources: [String]
    let lifestyleFactors: [String]
    let optimalRangeMale: String?
    let optimalRangeFemale: String?
    let unit: String

    enum CodingKeys: String, CodingKey {
        case id
        case biomarkerName = "biomarker_name"
        case displayName = "display_name"
        case category
        case shortDescription = "short_description"
        case detailedDescription = "detailed_description"
        case clinicalSignificance = "clinical_significance"
        case dietarySources = "dietary_sources"
        case lifestyleFactors = "lifestyle_factors"
        case optimalRangeMale = "optimal_range_male"
        case optimalRangeFemale = "optimal_range_female"
        case unit
    }

    init(
        id: UUID = UUID(),
        biomarkerName: String,
        displayName: String,
        category: String,
        shortDescription: String,
        detailedDescription: String,
        clinicalSignificance: String,
        dietarySources: [String],
        lifestyleFactors: [String],
        optimalRangeMale: String? = nil,
        optimalRangeFemale: String? = nil,
        unit: String
    ) {
        self.id = id
        self.biomarkerName = biomarkerName
        self.displayName = displayName
        self.category = category
        self.shortDescription = shortDescription
        self.detailedDescription = detailedDescription
        self.clinicalSignificance = clinicalSignificance
        self.dietarySources = dietarySources
        self.lifestyleFactors = lifestyleFactors
        self.optimalRangeMale = optimalRangeMale
        self.optimalRangeFemale = optimalRangeFemale
        self.unit = unit
    }

    /// Check if this biomarker matches a search query
    func matches(searchText: String) -> Bool {
        if searchText.isEmpty { return true }

        let lowercased = searchText.lowercased()
        return biomarkerName.lowercased().contains(lowercased) ||
               displayName.lowercased().contains(lowercased) ||
               category.lowercased().contains(lowercased) ||
               shortDescription.lowercased().contains(lowercased)
    }

    /// Map category string to BiomarkerCategory enum
    var categoryEnum: BiomarkerCategory {
        BiomarkerCategory.category(for: biomarkerName)
    }
}

// MARK: - Educational Category

/// Category for educational content grouping
enum BiomarkerEducationCategory: String, CaseIterable, Identifiable {
    case inflammation = "Inflammation"
    case hormones = "Hormones"
    case metabolic = "Metabolic"
    case vitamins = "Vitamins"
    case minerals = "Minerals"
    case lipids = "Lipids"
    case thyroid = "Thyroid"
    case cbc = "Blood Cells"
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
        case .lipids: return "heart.fill"
        case .thyroid: return "thermometer.medium"
        case .cbc: return "drop.fill"
        case .liver: return "cross.case.fill"
        case .kidney: return "water.waves"
        case .other: return "chart.bar.fill"
        }
    }

    var description: String {
        switch self {
        case .inflammation:
            return "Markers that indicate inflammation levels in the body"
        case .hormones:
            return "Chemical messengers that regulate body functions"
        case .metabolic:
            return "Indicators of how your body processes energy"
        case .vitamins:
            return "Essential nutrients for optimal health"
        case .minerals:
            return "Elements critical for bodily functions"
        case .lipids:
            return "Fats and cholesterol in the blood"
        case .thyroid:
            return "Hormones that regulate metabolism"
        case .cbc:
            return "Components of your blood"
        case .liver:
            return "Markers of liver health and function"
        case .kidney:
            return "Indicators of kidney function"
        case .other:
            return "Other health markers"
        }
    }

    /// Map from category string to enum
    static func from(string: String) -> BiomarkerEducationCategory {
        let normalized = string.lowercased()
        switch normalized {
        case "inflammation": return .inflammation
        case "hormones": return .hormones
        case "metabolic": return .metabolic
        case "vitamins": return .vitamins
        case "minerals": return .minerals
        case "lipids", "lipid panel": return .lipids
        case "thyroid": return .thyroid
        case "cbc", "blood cells": return .cbc
        case "liver": return .liver
        case "kidney": return .kidney
        default: return .other
        }
    }
}

// MARK: - High/Low Interpretation

/// What it means when a biomarker is high or low
struct BiomarkerInterpretation: Codable, Hashable {
    let whenHigh: String
    let whenLow: String
    let trainingImpact: String?

    enum CodingKeys: String, CodingKey {
        case whenHigh = "when_high"
        case whenLow = "when_low"
        case trainingImpact = "training_impact"
    }
}

// MARK: - Static Education Data

extension BiomarkerEducation {
    /// Pre-populated educational content for common biomarkers
    static let allEducation: [BiomarkerEducation] = [
        // MARK: - Inflammation
        BiomarkerEducation(
            biomarkerName: "crp",
            displayName: "C-Reactive Protein (CRP)",
            category: "Inflammation",
            shortDescription: "A key marker of inflammation in the body",
            detailedDescription: "C-Reactive Protein is produced by the liver in response to inflammation. It's one of the most reliable markers for detecting systemic inflammation, which can be caused by infection, injury, or chronic conditions.",
            clinicalSignificance: "High CRP levels are associated with increased cardiovascular risk, chronic inflammatory conditions, and slower recovery from training. For athletes, elevated CRP may indicate overtraining or inadequate recovery.",
            dietarySources: [
                "Anti-inflammatory: Fatty fish (salmon, mackerel)",
                "Anti-inflammatory: Leafy greens",
                "Anti-inflammatory: Berries and cherries",
                "Anti-inflammatory: Nuts (walnuts, almonds)",
                "Anti-inflammatory: Olive oil",
                "Avoid: Processed foods and refined sugars"
            ],
            lifestyleFactors: [
                "Regular moderate exercise reduces CRP",
                "Adequate sleep (7-9 hours) is crucial",
                "Stress management through meditation or yoga",
                "Maintaining healthy body weight",
                "Avoiding smoking and excessive alcohol"
            ],
            optimalRangeMale: "< 1.0 mg/L",
            optimalRangeFemale: "< 1.0 mg/L",
            unit: "mg/L"
        ),

        // MARK: - Hormones
        BiomarkerEducation(
            biomarkerName: "testosterone",
            displayName: "Testosterone",
            category: "Hormones",
            shortDescription: "Primary male sex hormone important for muscle and energy",
            detailedDescription: "Testosterone is the primary androgenic hormone responsible for muscle growth, bone density, energy levels, and mood. While higher in men, it plays important roles in women's health as well.",
            clinicalSignificance: "Optimal testosterone levels support muscle protein synthesis, fat metabolism, bone health, and cognitive function. Low levels can lead to fatigue, muscle loss, decreased libido, and mood changes.",
            dietarySources: [
                "Zinc-rich foods: Oysters, beef, pumpkin seeds",
                "Vitamin D sources: Fatty fish, egg yolks",
                "Healthy fats: Avocados, olive oil, nuts",
                "Cruciferous vegetables for estrogen balance",
                "Quality protein sources"
            ],
            lifestyleFactors: [
                "Resistance training and HIIT",
                "7-9 hours of quality sleep",
                "Stress management (cortisol competes with testosterone)",
                "Maintain healthy body fat percentage",
                "Limit alcohol consumption",
                "Avoid endocrine disruptors in plastics"
            ],
            optimalRangeMale: "500-900 ng/dL",
            optimalRangeFemale: "15-70 ng/dL",
            unit: "ng/dL"
        ),

        BiomarkerEducation(
            biomarkerName: "cortisol",
            displayName: "Cortisol",
            category: "Hormones",
            shortDescription: "The body's primary stress hormone",
            detailedDescription: "Cortisol is produced by the adrenal glands in response to stress. While essential for the body's fight-or-flight response, chronically elevated cortisol can have negative effects on health and performance.",
            clinicalSignificance: "Chronic high cortisol can lead to muscle breakdown, fat accumulation (especially abdominal), impaired immune function, and poor recovery. Low cortisol may indicate adrenal fatigue or HPA axis dysfunction.",
            dietarySources: [
                "Cortisol-lowering: Dark chocolate (in moderation)",
                "Cortisol-lowering: Green tea",
                "Cortisol-lowering: Bananas (potassium)",
                "Cortisol-lowering: Probiotics/fermented foods",
                "Avoid: Caffeine late in the day",
                "Avoid: High-sugar foods"
            ],
            lifestyleFactors: [
                "Consistent sleep schedule",
                "Meditation and deep breathing",
                "Moderate exercise (avoid overtraining)",
                "Time in nature",
                "Social connections and laughter",
                "Limit screen time before bed"
            ],
            optimalRangeMale: "6-23 mcg/dL (morning)",
            optimalRangeFemale: "6-23 mcg/dL (morning)",
            unit: "mcg/dL"
        ),

        // MARK: - Vitamins
        BiomarkerEducation(
            biomarkerName: "vitamin_d",
            displayName: "Vitamin D",
            category: "Vitamins",
            shortDescription: "Essential for bone health, immunity, and muscle function",
            detailedDescription: "Vitamin D is a fat-soluble vitamin that acts more like a hormone in the body. It's crucial for calcium absorption, bone health, immune function, and muscle performance. Most people are deficient, especially in northern latitudes.",
            clinicalSignificance: "Adequate vitamin D is essential for bone mineralization, immune defense, muscle strength, and mood regulation. Deficiency is linked to increased injury risk, poor recovery, and compromised immune function.",
            dietarySources: [
                "Fatty fish: Salmon, mackerel, sardines",
                "Cod liver oil",
                "Egg yolks",
                "Fortified foods: Milk, orange juice",
                "Mushrooms exposed to UV light"
            ],
            lifestyleFactors: [
                "15-30 minutes of midday sun exposure",
                "Supplement with D3 (2000-5000 IU daily)",
                "Take with fat for better absorption",
                "Test levels 2-3 times per year",
                "Consider higher doses in winter months"
            ],
            optimalRangeMale: "50-70 ng/mL",
            optimalRangeFemale: "50-70 ng/mL",
            unit: "ng/mL"
        ),

        BiomarkerEducation(
            biomarkerName: "vitamin_b12",
            displayName: "Vitamin B12",
            category: "Vitamins",
            shortDescription: "Critical for energy, nerves, and red blood cell production",
            detailedDescription: "Vitamin B12 is essential for neurological function, DNA synthesis, and red blood cell formation. It's found primarily in animal products, making deficiency common in vegetarians and vegans.",
            clinicalSignificance: "B12 deficiency can cause fatigue, weakness, neurological symptoms, and anemia. Athletes need adequate B12 for energy metabolism and oxygen transport to muscles.",
            dietarySources: [
                "Animal proteins: Beef, liver, chicken",
                "Fish: Salmon, tuna, trout",
                "Shellfish: Clams, mussels",
                "Dairy products",
                "Eggs",
                "Fortified cereals and nutritional yeast"
            ],
            lifestyleFactors: [
                "Regular consumption of animal products",
                "Supplementation for vegetarians/vegans",
                "Check for absorption issues (intrinsic factor)",
                "Avoid excessive alcohol",
                "Consider sublingual or injection forms if deficient"
            ],
            optimalRangeMale: "500-1000 pg/mL",
            optimalRangeFemale: "500-1000 pg/mL",
            unit: "pg/mL"
        ),

        // MARK: - Minerals
        BiomarkerEducation(
            biomarkerName: "ferritin",
            displayName: "Ferritin",
            category: "Minerals",
            shortDescription: "The body's iron storage protein",
            detailedDescription: "Ferritin is a protein that stores iron and releases it in a controlled fashion. It's the best indicator of total body iron stores and is essential for oxygen transport, energy production, and immune function.",
            clinicalSignificance: "Low ferritin causes fatigue, weakness, and decreased athletic performance due to reduced oxygen-carrying capacity. Athletes, especially endurance athletes and women, are at higher risk for iron deficiency.",
            dietarySources: [
                "Heme iron (best absorbed): Red meat, liver",
                "Heme iron: Poultry, fish",
                "Non-heme iron: Spinach, lentils, beans",
                "Non-heme iron: Fortified cereals",
                "Pair with vitamin C for better absorption",
                "Avoid calcium with iron-rich meals"
            ],
            lifestyleFactors: [
                "Regular blood testing, especially for athletes",
                "Avoid tea/coffee with iron-rich meals",
                "Consider cast iron cookware",
                "Supplement only if deficient",
                "Address any underlying causes of iron loss"
            ],
            optimalRangeMale: "100-300 ng/mL",
            optimalRangeFemale: "50-150 ng/mL",
            unit: "ng/mL"
        ),

        BiomarkerEducation(
            biomarkerName: "magnesium",
            displayName: "Magnesium",
            category: "Minerals",
            shortDescription: "Essential mineral for over 300 enzymatic reactions",
            detailedDescription: "Magnesium is involved in muscle contraction, nerve function, blood sugar control, and protein synthesis. Despite its importance, many people have suboptimal levels due to depleted soil and processed food diets.",
            clinicalSignificance: "Magnesium deficiency can cause muscle cramps, poor sleep, anxiety, and decreased exercise performance. Athletes may need more due to losses through sweat.",
            dietarySources: [
                "Dark leafy greens: Spinach, swiss chard",
                "Nuts and seeds: Pumpkin seeds, almonds",
                "Dark chocolate (85%+)",
                "Avocados",
                "Legumes: Black beans, chickpeas",
                "Whole grains"
            ],
            lifestyleFactors: [
                "Supplement with magnesium glycinate for sleep",
                "Epsom salt baths for transdermal absorption",
                "Reduce stress (depletes magnesium)",
                "Limit alcohol and caffeine",
                "Consider higher intake during intense training"
            ],
            optimalRangeMale: "2.0-2.4 mg/dL",
            optimalRangeFemale: "2.0-2.4 mg/dL",
            unit: "mg/dL"
        ),

        // MARK: - Metabolic
        BiomarkerEducation(
            biomarkerName: "glucose",
            displayName: "Fasting Glucose",
            category: "Metabolic",
            shortDescription: "Blood sugar level after fasting",
            detailedDescription: "Fasting glucose measures the amount of sugar in your blood after not eating for at least 8 hours. It's a key indicator of how well your body regulates blood sugar and metabolic health.",
            clinicalSignificance: "Elevated fasting glucose indicates insulin resistance or diabetes risk. Optimal glucose control is essential for sustained energy, body composition, and long-term health.",
            dietarySources: [
                "Blood sugar stabilizing: Fiber-rich vegetables",
                "Blood sugar stabilizing: Lean proteins",
                "Blood sugar stabilizing: Healthy fats",
                "Blood sugar stabilizing: Complex carbohydrates",
                "Limit: Refined sugars and processed carbs",
                "Limit: Sugary beverages"
            ],
            lifestyleFactors: [
                "Regular exercise improves insulin sensitivity",
                "Adequate sleep (poor sleep raises glucose)",
                "Stress management",
                "Post-meal walks",
                "Consistent meal timing",
                "Monitor carbohydrate quality and quantity"
            ],
            optimalRangeMale: "70-85 mg/dL",
            optimalRangeFemale: "70-85 mg/dL",
            unit: "mg/dL"
        ),

        BiomarkerEducation(
            biomarkerName: "hba1c",
            displayName: "Hemoglobin A1c",
            category: "Metabolic",
            shortDescription: "Average blood sugar over 2-3 months",
            detailedDescription: "HbA1c measures the percentage of hemoglobin that has glucose attached to it, reflecting average blood sugar levels over the past 2-3 months. It's a better indicator of long-term glucose control than fasting glucose alone.",
            clinicalSignificance: "Elevated HbA1c indicates chronic high blood sugar and increased diabetes risk. Optimal levels support sustained energy, better body composition, and reduced risk of metabolic disease.",
            dietarySources: [
                "Low glycemic foods: Non-starchy vegetables",
                "Low glycemic foods: Legumes",
                "Low glycemic foods: Whole grains",
                "Adequate protein with each meal",
                "Healthy fats to slow glucose absorption",
                "Berries and citrus fruits"
            ],
            lifestyleFactors: [
                "Consistent exercise routine",
                "Weight management",
                "Quality sleep",
                "Limit alcohol consumption",
                "Regular monitoring if elevated",
                "Consider continuous glucose monitoring"
            ],
            optimalRangeMale: "4.5-5.2%",
            optimalRangeFemale: "4.5-5.2%",
            unit: "%"
        ),

        // MARK: - Lipids
        BiomarkerEducation(
            biomarkerName: "hdl",
            displayName: "HDL Cholesterol",
            category: "Lipids",
            shortDescription: "The 'good' cholesterol that protects heart health",
            detailedDescription: "HDL (High-Density Lipoprotein) helps remove other forms of cholesterol from the bloodstream. Higher levels of HDL cholesterol are associated with lower risk of heart disease.",
            clinicalSignificance: "Higher HDL is cardioprotective. Low HDL is a cardiovascular risk factor independent of LDL levels. Exercise and diet significantly influence HDL levels.",
            dietarySources: [
                "HDL-raising: Fatty fish (omega-3s)",
                "HDL-raising: Olive oil",
                "HDL-raising: Nuts, especially almonds and walnuts",
                "HDL-raising: Avocados",
                "HDL-raising: Whole grains",
                "Avoid: Trans fats (lower HDL)"
            ],
            lifestyleFactors: [
                "Regular aerobic exercise (biggest impact)",
                "Maintain healthy weight",
                "Don't smoke",
                "Moderate alcohol (red wine) may help",
                "Reduce refined carbohydrate intake"
            ],
            optimalRangeMale: "> 50 mg/dL",
            optimalRangeFemale: "> 60 mg/dL",
            unit: "mg/dL"
        ),

        BiomarkerEducation(
            biomarkerName: "ldl",
            displayName: "LDL Cholesterol",
            category: "Lipids",
            shortDescription: "Cholesterol that can build up in arteries",
            detailedDescription: "LDL (Low-Density Lipoprotein) carries cholesterol to cells throughout the body. When LDL levels are too high, cholesterol can build up in artery walls, increasing cardiovascular disease risk.",
            clinicalSignificance: "Elevated LDL, especially small dense LDL particles, is a major cardiovascular risk factor. However, particle size and number may be more important than total LDL.",
            dietarySources: [
                "LDL-lowering: Soluble fiber (oats, beans)",
                "LDL-lowering: Plant sterols",
                "LDL-lowering: Soy protein",
                "LDL-lowering: Nuts",
                "Limit: Saturated fats",
                "Avoid: Trans fats completely"
            ],
            lifestyleFactors: [
                "Regular physical activity",
                "Maintain healthy body weight",
                "Don't smoke",
                "Manage stress",
                "Consider advanced lipid testing (particle size)"
            ],
            optimalRangeMale: "< 100 mg/dL",
            optimalRangeFemale: "< 100 mg/dL",
            unit: "mg/dL"
        ),

        // MARK: - Thyroid
        BiomarkerEducation(
            biomarkerName: "tsh",
            displayName: "TSH (Thyroid Stimulating Hormone)",
            category: "Thyroid",
            shortDescription: "Controls thyroid hormone production",
            detailedDescription: "TSH is produced by the pituitary gland and signals the thyroid to produce hormones T3 and T4. TSH levels inversely reflect thyroid function - high TSH indicates low thyroid function and vice versa.",
            clinicalSignificance: "Thyroid hormones regulate metabolism, energy, body temperature, and weight. Both high and low TSH can significantly impact athletic performance, recovery, and body composition.",
            dietarySources: [
                "Thyroid-supporting: Iodine (seaweed, seafood)",
                "Thyroid-supporting: Selenium (Brazil nuts)",
                "Thyroid-supporting: Zinc (oysters, beef)",
                "Thyroid-supporting: Tyrosine (protein foods)",
                "Limit: Goitrogens if hypothyroid (raw cruciferous)"
            ],
            lifestyleFactors: [
                "Avoid extreme calorie restriction",
                "Manage stress (affects thyroid)",
                "Adequate sleep",
                "Avoid overtraining",
                "Limit environmental toxins",
                "Regular testing if symptomatic"
            ],
            optimalRangeMale: "1.0-2.0 mIU/L",
            optimalRangeFemale: "1.0-2.0 mIU/L",
            unit: "mIU/L"
        ),

        // MARK: - CBC
        BiomarkerEducation(
            biomarkerName: "hemoglobin",
            displayName: "Hemoglobin",
            category: "Blood Cells",
            shortDescription: "Protein in red blood cells that carries oxygen",
            detailedDescription: "Hemoglobin is the iron-containing protein in red blood cells responsible for transporting oxygen from the lungs to tissues throughout the body. It's crucial for aerobic performance and energy production.",
            clinicalSignificance: "Low hemoglobin (anemia) causes fatigue, weakness, and severely impairs endurance performance. Athletes may have lower hemoglobin due to hemodilution but should ensure adequate iron stores.",
            dietarySources: [
                "Iron-rich: Red meat, liver",
                "Iron-rich: Shellfish",
                "Iron-rich: Spinach, legumes",
                "B12 sources: Animal products",
                "Folate sources: Leafy greens, beans",
                "Vitamin C to enhance iron absorption"
            ],
            lifestyleFactors: [
                "Regular blood testing",
                "Address any iron deficiency",
                "Ensure adequate B12 and folate",
                "Train at appropriate intensity",
                "Consider altitude training effects",
                "Stay well hydrated"
            ],
            optimalRangeMale: "14-17 g/dL",
            optimalRangeFemale: "12-15 g/dL",
            unit: "g/dL"
        )
    ]

    /// Get education content for a specific biomarker by name
    static func education(for biomarkerName: String) -> BiomarkerEducation? {
        let normalized = biomarkerName.lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")

        return allEducation.first { education in
            education.biomarkerName.lowercased() == normalized ||
            education.displayName.lowercased().contains(normalized)
        }
    }

    /// Get all education content for a specific category
    static func education(forCategory category: String) -> [BiomarkerEducation] {
        allEducation.filter { $0.category.lowercased() == category.lowercased() }
    }

    /// Group all education content by category
    static var groupedByCategory: [String: [BiomarkerEducation]] {
        allEducation.safeGrouped(by: { $0.category })
    }
}
