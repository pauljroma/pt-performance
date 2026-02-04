// ============================================================================
// Supplement Recommendations Edge Function
// Health Intelligence Platform - Personalized Supplement Suggestions
// ============================================================================
// Analyzes patient goals, current supplements, lab results, and budget to
// provide prioritized supplement recommendations.
//
// Date: 2026-02-03
// Ticket: ACP-437
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

interface CurrentSupplement {
  name: string
  dosage?: string
}

interface LabResult {
  biomarker: string
  value: number
  unit: string
  reference_low?: number
  reference_high?: number
  flag?: 'normal' | 'low' | 'high' | 'critical'
}

interface RecommendationsRequest {
  patient_id?: string
  goals: string[]
  current_supplements?: CurrentSupplement[]
  lab_results?: LabResult[]
  budget?: 'low' | 'medium' | 'high' | 'unlimited'
  dietary_restrictions?: string[]
  age?: number
  sex?: 'male' | 'female'
}

interface SupplementRecommendation {
  name: string
  priority: 'essential' | 'highly_recommended' | 'beneficial' | 'optional'
  dosage: string
  form?: string
  reasoning: string
  goal_alignment: string[]
  lab_based: boolean
  estimated_monthly_cost?: string
  notes?: string[]
  contraindications?: string[]
}

interface RecommendationsResponse {
  success: boolean
  patient_id?: string
  recommendations: SupplementRecommendation[]
  already_taking: string[]
  summary: string
  total_estimated_cost?: string
  general_notes: string[]
  error?: string
}

// ============================================================================
// SUPPLEMENT RECOMMENDATION DATABASE
// ============================================================================

interface SupplementProfile {
  name: string
  common_dosage: string
  forms: string[]
  goals: string[]
  lab_triggers?: { biomarker: string; condition: 'low' | 'high'; threshold?: number }[]
  benefits: string[]
  monthly_cost_range: { low: number; medium: number; high: number }
  contraindications?: string[]
  synergies?: string[]
  notes?: string[]
}

const SUPPLEMENT_DATABASE: SupplementProfile[] = [
  // Vitamin & Mineral Essentials
  {
    name: 'Vitamin D3',
    common_dosage: '2000-5000 IU daily',
    forms: ['softgel', 'liquid', 'tablet'],
    goals: ['general_health', 'immune_support', 'bone_health', 'mood', 'muscle_function'],
    lab_triggers: [
      { biomarker: 'vitamin_d', condition: 'low', threshold: 30 },
      { biomarker: '25-hydroxy vitamin d', condition: 'low', threshold: 30 }
    ],
    benefits: ['Immune function', 'Bone health', 'Mood regulation', 'Muscle function'],
    monthly_cost_range: { low: 8, medium: 15, high: 25 },
    synergies: ['vitamin k2', 'magnesium'],
    notes: ['Take with fat-containing meal', 'Test levels every 3-6 months']
  },
  {
    name: 'Vitamin K2 (MK-7)',
    common_dosage: '100-200 mcg daily',
    forms: ['softgel', 'capsule'],
    goals: ['bone_health', 'cardiovascular_health', 'general_health'],
    benefits: ['Directs calcium to bones', 'Supports arterial health', 'Enhances Vitamin D benefits'],
    monthly_cost_range: { low: 10, medium: 18, high: 30 },
    synergies: ['vitamin d3', 'calcium'],
    contraindications: ['warfarin/blood thinners (consult physician)'],
    notes: ['Essential companion to Vitamin D supplementation']
  },
  {
    name: 'Magnesium Glycinate',
    common_dosage: '300-400 mg daily',
    forms: ['capsule', 'powder', 'tablet'],
    goals: ['sleep', 'stress_management', 'muscle_recovery', 'general_health', 'athletic_performance'],
    lab_triggers: [
      { biomarker: 'magnesium', condition: 'low', threshold: 1.8 }
    ],
    benefits: ['Sleep quality', 'Muscle relaxation', 'Stress reduction', '300+ enzymatic reactions'],
    monthly_cost_range: { low: 12, medium: 22, high: 35 },
    synergies: ['vitamin d3', 'vitamin b6'],
    notes: ['Glycinate form is gentle on stomach', 'Take before bed for sleep benefits']
  },
  {
    name: 'Omega-3 Fish Oil',
    common_dosage: '2-3g EPA+DHA daily',
    forms: ['softgel', 'liquid'],
    goals: ['cardiovascular_health', 'brain_health', 'inflammation', 'joint_health', 'general_health'],
    lab_triggers: [
      { biomarker: 'triglycerides', condition: 'high', threshold: 150 },
      { biomarker: 'omega3_index', condition: 'low', threshold: 8 }
    ],
    benefits: ['Heart health', 'Brain function', 'Reduces inflammation', 'Joint comfort'],
    monthly_cost_range: { low: 15, medium: 30, high: 50 },
    notes: ['Look for products tested for heavy metals', 'Take with fatty meal']
  },
  {
    name: 'Vitamin B12 (Methylcobalamin)',
    common_dosage: '1000-2000 mcg daily',
    forms: ['sublingual', 'capsule', 'liquid'],
    goals: ['energy', 'brain_health', 'mood', 'general_health'],
    lab_triggers: [
      { biomarker: 'vitamin_b12', condition: 'low', threshold: 400 },
      { biomarker: 'b12', condition: 'low', threshold: 400 }
    ],
    benefits: ['Energy production', 'Nerve health', 'Red blood cell formation', 'Mood support'],
    monthly_cost_range: { low: 8, medium: 15, high: 25 },
    synergies: ['folate', 'b complex'],
    notes: ['Methylcobalamin is active form', 'Essential for vegans/vegetarians']
  },

  // Performance & Muscle Building
  {
    name: 'Creatine Monohydrate',
    common_dosage: '5g daily',
    forms: ['powder', 'capsule'],
    goals: ['muscle_gain', 'strength', 'athletic_performance', 'brain_health'],
    benefits: ['Increased strength', 'Muscle mass', 'Power output', 'Cognitive benefits'],
    monthly_cost_range: { low: 10, medium: 18, high: 30 },
    notes: ['Most researched supplement', 'No loading phase necessary', 'Take daily for consistency']
  },
  {
    name: 'Protein Powder (Whey/Plant)',
    common_dosage: '25-50g daily',
    forms: ['powder'],
    goals: ['muscle_gain', 'weight_loss', 'athletic_performance', 'recovery'],
    benefits: ['Muscle protein synthesis', 'Convenient protein source', 'Recovery support'],
    monthly_cost_range: { low: 30, medium: 50, high: 80 },
    notes: ['Whey is fast-absorbing', 'Plant-based for dairy-free needs']
  },
  {
    name: 'Collagen Peptides',
    common_dosage: '10-20g daily',
    forms: ['powder', 'capsule'],
    goals: ['joint_health', 'skin_health', 'gut_health', 'recovery'],
    benefits: ['Joint support', 'Skin elasticity', 'Gut lining support', 'Connective tissue'],
    monthly_cost_range: { low: 20, medium: 35, high: 55 },
    notes: ['Types I, II, III for comprehensive benefits', 'Take on empty stomach']
  },
  {
    name: 'Beta-Alanine',
    common_dosage: '3-6g daily',
    forms: ['powder', 'capsule'],
    goals: ['endurance', 'athletic_performance'],
    benefits: ['Increased endurance', 'Reduced fatigue', 'Enhanced high-intensity performance'],
    monthly_cost_range: { low: 12, medium: 20, high: 35 },
    notes: ['May cause tingling (paresthesia) - harmless', 'Split dose throughout day']
  },

  // Sleep & Stress
  {
    name: 'Ashwagandha (KSM-66)',
    common_dosage: '300-600 mg daily',
    forms: ['capsule', 'powder'],
    goals: ['stress_management', 'sleep', 'athletic_performance', 'hormones'],
    lab_triggers: [
      { biomarker: 'cortisol', condition: 'high' }
    ],
    benefits: ['Stress reduction', 'Sleep quality', 'May support testosterone', 'Adaptogenic'],
    monthly_cost_range: { low: 15, medium: 25, high: 40 },
    contraindications: ['thyroid conditions (consult physician)', 'pregnancy'],
    notes: ['KSM-66 is well-researched extract', 'Takes 4-8 weeks for full benefits']
  },
  {
    name: 'L-Theanine',
    common_dosage: '100-200 mg daily',
    forms: ['capsule', 'powder'],
    goals: ['stress_management', 'focus', 'sleep'],
    benefits: ['Calm focus', 'Reduced anxiety', 'Sleep quality', 'Pairs well with caffeine'],
    monthly_cost_range: { low: 10, medium: 18, high: 28 },
    synergies: ['caffeine', 'magnesium'],
    notes: ['Can take morning for focus or evening for sleep']
  },
  {
    name: 'Melatonin',
    common_dosage: '0.5-3 mg before bed',
    forms: ['tablet', 'gummy', 'liquid'],
    goals: ['sleep'],
    benefits: ['Sleep onset', 'Circadian rhythm support', 'Jet lag recovery'],
    monthly_cost_range: { low: 5, medium: 10, high: 20 },
    notes: ['Start with lowest effective dose', 'Not for long-term daily use']
  },
  {
    name: 'Glycine',
    common_dosage: '3g before bed',
    forms: ['powder', 'capsule'],
    goals: ['sleep', 'recovery', 'gut_health'],
    benefits: ['Sleep quality', 'Collagen synthesis', 'Neurotransmitter support'],
    monthly_cost_range: { low: 10, medium: 18, high: 28 },
    synergies: ['magnesium', 'collagen'],
    notes: ['Sweet taste - easy to take in water']
  },

  // Cognitive & Brain Health
  {
    name: 'Lions Mane Mushroom',
    common_dosage: '500-1000 mg daily',
    forms: ['capsule', 'powder'],
    goals: ['brain_health', 'focus', 'mood'],
    benefits: ['Nerve growth factor support', 'Cognitive function', 'Neuroprotection'],
    monthly_cost_range: { low: 20, medium: 35, high: 55 },
    notes: ['Look for fruiting body extract', 'Takes 4+ weeks for noticeable effects']
  },
  {
    name: 'Alpha-GPC',
    common_dosage: '300-600 mg daily',
    forms: ['capsule', 'powder'],
    goals: ['brain_health', 'focus', 'athletic_performance'],
    benefits: ['Choline source', 'Cognitive enhancement', 'Power output'],
    monthly_cost_range: { low: 18, medium: 30, high: 45 },
    notes: ['Take in morning', 'May enhance mind-muscle connection']
  },

  // Immune Support
  {
    name: 'Vitamin C',
    common_dosage: '500-1000 mg daily',
    forms: ['tablet', 'powder', 'capsule'],
    goals: ['immune_support', 'skin_health', 'general_health'],
    benefits: ['Immune function', 'Antioxidant', 'Collagen synthesis', 'Iron absorption'],
    monthly_cost_range: { low: 6, medium: 12, high: 25 },
    synergies: ['iron', 'vitamin e'],
    notes: ['Split doses for better absorption', 'Liposomal form has higher absorption']
  },
  {
    name: 'Zinc',
    common_dosage: '15-30 mg daily',
    forms: ['capsule', 'tablet', 'lozenge'],
    goals: ['immune_support', 'hormones', 'skin_health', 'general_health'],
    lab_triggers: [
      { biomarker: 'zinc', condition: 'low', threshold: 70 }
    ],
    benefits: ['Immune function', 'Testosterone support', 'Wound healing', 'Enzyme function'],
    monthly_cost_range: { low: 6, medium: 12, high: 22 },
    contraindications: ['high doses long-term can deplete copper'],
    synergies: ['copper'],
    notes: ['Take with food to prevent nausea', 'Balance with copper (10:1 ratio)']
  },
  {
    name: 'Elderberry',
    common_dosage: '500-1000 mg daily',
    forms: ['syrup', 'gummy', 'capsule'],
    goals: ['immune_support'],
    benefits: ['Immune support', 'Antioxidant', 'May reduce cold duration'],
    monthly_cost_range: { low: 12, medium: 22, high: 35 },
    contraindications: ['autoimmune conditions (consult physician)'],
    notes: ['Most beneficial during cold/flu season']
  },

  // Gut Health
  {
    name: 'Probiotic (Multi-Strain)',
    common_dosage: '10-50 billion CFU daily',
    forms: ['capsule', 'powder'],
    goals: ['gut_health', 'immune_support', 'mood'],
    benefits: ['Gut microbiome balance', 'Digestive health', 'Immune function', 'Mood via gut-brain axis'],
    monthly_cost_range: { low: 15, medium: 30, high: 50 },
    notes: ['Look for multiple strains', 'Take on empty stomach', 'Refrigerated often better quality']
  },
  {
    name: 'Digestive Enzymes',
    common_dosage: 'With meals',
    forms: ['capsule'],
    goals: ['gut_health', 'general_health'],
    benefits: ['Improved digestion', 'Nutrient absorption', 'Reduced bloating'],
    monthly_cost_range: { low: 12, medium: 25, high: 40 },
    notes: ['Take at beginning of meals', 'Helpful for those with digestive issues']
  },
  {
    name: 'L-Glutamine',
    common_dosage: '5-10g daily',
    forms: ['powder', 'capsule'],
    goals: ['gut_health', 'recovery', 'immune_support'],
    benefits: ['Gut lining repair', 'Muscle recovery', 'Immune cell fuel'],
    monthly_cost_range: { low: 15, medium: 25, high: 40 },
    notes: ['Most abundant amino acid', 'Split into multiple doses']
  },

  // Hormonal Support
  {
    name: 'DHEA',
    common_dosage: '25-50 mg daily',
    forms: ['capsule', 'tablet'],
    goals: ['hormones', 'energy', 'mood'],
    lab_triggers: [
      { biomarker: 'dhea_s', condition: 'low' },
      { biomarker: 'dhea sulfate', condition: 'low' }
    ],
    benefits: ['Hormone precursor', 'Energy', 'Mood support'],
    monthly_cost_range: { low: 8, medium: 15, high: 25 },
    contraindications: ['hormone-sensitive conditions', 'under 30 years old without testing'],
    notes: ['Only supplement if lab-confirmed low', 'Monitor levels']
  },
  {
    name: 'DIM (Diindolylmethane)',
    common_dosage: '100-200 mg daily',
    forms: ['capsule'],
    goals: ['hormones', 'general_health'],
    benefits: ['Estrogen metabolism', 'Hormone balance'],
    monthly_cost_range: { low: 15, medium: 25, high: 40 },
    notes: ['Derived from cruciferous vegetables', 'May affect estrogen levels']
  },

  // Inflammation & Joint
  {
    name: 'Curcumin (with Piperine)',
    common_dosage: '500-1000 mg daily',
    forms: ['capsule', 'softgel'],
    goals: ['inflammation', 'joint_health', 'brain_health'],
    lab_triggers: [
      { biomarker: 'hscrp', condition: 'high', threshold: 1 },
      { biomarker: 'crp', condition: 'high', threshold: 3 }
    ],
    benefits: ['Anti-inflammatory', 'Antioxidant', 'Joint comfort', 'Brain health'],
    monthly_cost_range: { low: 15, medium: 28, high: 45 },
    contraindications: ['gallbladder issues', 'blood thinners (consult physician)'],
    notes: ['Piperine increases absorption 2000%', 'Take with fat-containing meal']
  },
  {
    name: 'Glucosamine + Chondroitin',
    common_dosage: '1500mg/1200mg daily',
    forms: ['capsule', 'tablet'],
    goals: ['joint_health'],
    benefits: ['Joint cushioning', 'Cartilage support', 'Joint comfort'],
    monthly_cost_range: { low: 15, medium: 28, high: 45 },
    contraindications: ['shellfish allergy (for glucosamine sulfate)'],
    notes: ['Takes 4-8 weeks for benefits', 'Often combined with MSM']
  },
  {
    name: 'Boswellia',
    common_dosage: '300-500 mg daily',
    forms: ['capsule'],
    goals: ['inflammation', 'joint_health'],
    benefits: ['Anti-inflammatory', 'Joint comfort', 'Gut health'],
    monthly_cost_range: { low: 12, medium: 22, high: 35 },
    notes: ['Traditional Ayurvedic herb', 'Synergistic with curcumin']
  },

  // Cardiovascular
  {
    name: 'CoQ10 (Ubiquinol)',
    common_dosage: '100-200 mg daily',
    forms: ['softgel', 'capsule'],
    goals: ['cardiovascular_health', 'energy', 'general_health'],
    benefits: ['Cellular energy', 'Heart health', 'Antioxidant', 'Statin support'],
    monthly_cost_range: { low: 20, medium: 35, high: 55 },
    notes: ['Ubiquinol is active form', 'Essential if taking statins', 'Take with fat']
  },
  {
    name: 'Berberine',
    common_dosage: '500 mg 2-3x daily',
    forms: ['capsule'],
    goals: ['metabolic_health', 'cardiovascular_health'],
    lab_triggers: [
      { biomarker: 'glucose', condition: 'high', threshold: 100 },
      { biomarker: 'hba1c', condition: 'high', threshold: 5.7 }
    ],
    benefits: ['Blood sugar support', 'Lipid profile', 'Gut health'],
    monthly_cost_range: { low: 18, medium: 30, high: 45 },
    contraindications: ['diabetes medications (consult physician)', 'pregnancy'],
    notes: ['Comparable to metformin in studies', 'Take with meals']
  },

  // Iron (when deficient)
  {
    name: 'Iron (Bisglycinate)',
    common_dosage: '18-45 mg daily',
    forms: ['capsule', 'tablet'],
    goals: ['energy', 'general_health'],
    lab_triggers: [
      { biomarker: 'ferritin', condition: 'low', threshold: 30 },
      { biomarker: 'iron', condition: 'low' },
      { biomarker: 'hemoglobin', condition: 'low' }
    ],
    benefits: ['Energy', 'Oxygen transport', 'Cognitive function'],
    monthly_cost_range: { low: 8, medium: 15, high: 25 },
    contraindications: ['hemochromatosis', 'iron overload'],
    synergies: ['vitamin c'],
    notes: ['Only supplement if deficient', 'Bisglycinate is gentle on stomach', 'Take with Vitamin C']
  }
]

// ============================================================================
// GOAL MAPPINGS
// ============================================================================

const GOAL_ALIASES: Record<string, string[]> = {
  'muscle_gain': ['muscle', 'mass', 'hypertrophy', 'build muscle', 'gain muscle', 'bulk'],
  'weight_loss': ['fat loss', 'lose weight', 'cut', 'lean', 'body composition'],
  'strength': ['power', 'get stronger', 'powerlifting'],
  'endurance': ['cardio', 'stamina', 'running', 'cycling', 'marathon'],
  'athletic_performance': ['performance', 'sports', 'training', 'exercise'],
  'sleep': ['insomnia', 'better sleep', 'sleep quality', 'rest'],
  'stress_management': ['stress', 'anxiety', 'relaxation', 'calm'],
  'energy': ['fatigue', 'tired', 'more energy', 'vitality'],
  'focus': ['concentration', 'mental clarity', 'cognitive', 'brain fog'],
  'brain_health': ['cognitive', 'memory', 'neuroprotection', 'mental'],
  'immune_support': ['immunity', 'immune system', 'sick less', 'cold prevention'],
  'gut_health': ['digestion', 'bloating', 'microbiome', 'ibs'],
  'joint_health': ['joints', 'arthritis', 'mobility', 'flexibility'],
  'cardiovascular_health': ['heart health', 'heart', 'blood pressure', 'cholesterol'],
  'bone_health': ['bones', 'osteoporosis', 'bone density'],
  'skin_health': ['skin', 'acne', 'aging', 'collagen'],
  'hormones': ['hormone balance', 'testosterone', 'estrogen', 'hormonal'],
  'inflammation': ['anti-inflammatory', 'chronic inflammation', 'pain'],
  'recovery': ['muscle recovery', 'soreness', 'doms', 'healing'],
  'mood': ['depression', 'mental health', 'happiness', 'wellbeing'],
  'general_health': ['overall health', 'longevity', 'wellness', 'preventive'],
  'metabolic_health': ['metabolism', 'blood sugar', 'insulin', 'diabetes prevention']
}

function normalizeGoals(goals: string[]): string[] {
  const normalized: Set<string> = new Set()

  for (const goal of goals) {
    const lowerGoal = goal.toLowerCase().trim()

    // Direct match
    if (GOAL_ALIASES[lowerGoal]) {
      normalized.add(lowerGoal)
      continue
    }

    // Check aliases
    for (const [mainGoal, aliases] of Object.entries(GOAL_ALIASES)) {
      if (aliases.some(alias => lowerGoal.includes(alias) || alias.includes(lowerGoal))) {
        normalized.add(mainGoal)
        break
      }
    }

    // If no match, add as-is
    if (!Array.from(normalized).some(g => g === lowerGoal)) {
      normalized.add(lowerGoal)
    }
  }

  return Array.from(normalized)
}

// ============================================================================
// LAB RESULT ANALYSIS
// ============================================================================

function normalizeBiomarker(name: string): string {
  return name.toLowerCase()
    .replace(/[^a-z0-9]/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_|_$/g, '')
}

function checkLabTriggers(supplement: SupplementProfile, labResults: LabResult[]): { triggered: boolean; reason?: string } {
  if (!supplement.lab_triggers || supplement.lab_triggers.length === 0) {
    return { triggered: false }
  }

  for (const trigger of supplement.lab_triggers) {
    const normalizedTrigger = normalizeBiomarker(trigger.biomarker)

    for (const lab of labResults) {
      const normalizedLab = normalizeBiomarker(lab.biomarker)

      if (normalizedLab.includes(normalizedTrigger) || normalizedTrigger.includes(normalizedLab)) {
        // Check if condition matches
        if (trigger.condition === 'low') {
          const threshold = trigger.threshold || lab.reference_low
          if (threshold && lab.value < threshold) {
            return {
              triggered: true,
              reason: `${lab.biomarker} is low (${lab.value} ${lab.unit}, optimal > ${threshold})`
            }
          }
          if (lab.flag === 'low') {
            return {
              triggered: true,
              reason: `${lab.biomarker} flagged as low (${lab.value} ${lab.unit})`
            }
          }
        } else if (trigger.condition === 'high') {
          const threshold = trigger.threshold || lab.reference_high
          if (threshold && lab.value > threshold) {
            return {
              triggered: true,
              reason: `${lab.biomarker} is elevated (${lab.value} ${lab.unit}, optimal < ${threshold})`
            }
          }
          if (lab.flag === 'high' || lab.flag === 'critical') {
            return {
              triggered: true,
              reason: `${lab.biomarker} flagged as high (${lab.value} ${lab.unit})`
            }
          }
        }
      }
    }
  }

  return { triggered: false }
}

// ============================================================================
// RECOMMENDATION LOGIC
// ============================================================================

function generateRecommendations(request: RecommendationsRequest): RecommendationsResponse {
  const {
    patient_id,
    goals,
    current_supplements = [],
    lab_results = [],
    budget = 'medium',
    dietary_restrictions = [],
    age,
    sex
  } = request

  const normalizedGoals = normalizeGoals(goals)
  const recommendations: SupplementRecommendation[] = []
  const alreadyTaking: string[] = []

  // Normalize current supplements for comparison
  const currentSupplementNames = current_supplements.map(s =>
    s.name.toLowerCase().replace(/[^a-z0-9]/g, '')
  )

  // Score and filter supplements
  const scoredSupplements: { supplement: SupplementProfile; score: number; labTriggered: boolean; labReason?: string }[] = []

  for (const supplement of SUPPLEMENT_DATABASE) {
    // Check if already taking
    const supplementNameNormalized = supplement.name.toLowerCase().replace(/[^a-z0-9]/g, '')
    const isAlreadyTaking = currentSupplementNames.some(name =>
      name.includes(supplementNameNormalized) || supplementNameNormalized.includes(name)
    )

    if (isAlreadyTaking) {
      alreadyTaking.push(supplement.name)
      continue
    }

    // Check dietary restrictions
    if (dietary_restrictions.length > 0) {
      const hasConflict = dietary_restrictions.some(restriction => {
        const lowerRestriction = restriction.toLowerCase()
        if (lowerRestriction.includes('vegan') || lowerRestriction.includes('vegetarian')) {
          return supplement.name.toLowerCase().includes('fish') ||
                 supplement.name.toLowerCase().includes('collagen') ||
                 supplement.name.toLowerCase().includes('whey')
        }
        if (lowerRestriction.includes('shellfish')) {
          return supplement.name.toLowerCase().includes('glucosamine')
        }
        return false
      })
      if (hasConflict) continue
    }

    // Calculate goal alignment score
    let goalScore = 0
    const alignedGoals: string[] = []

    for (const goal of normalizedGoals) {
      if (supplement.goals.includes(goal)) {
        goalScore += 2
        alignedGoals.push(goal)
      }
      // Partial matches
      for (const suppGoal of supplement.goals) {
        if (goal.includes(suppGoal) || suppGoal.includes(goal)) {
          goalScore += 1
          if (!alignedGoals.includes(suppGoal)) alignedGoals.push(suppGoal)
        }
      }
    }

    if (goalScore === 0 && lab_results.length === 0) continue

    // Check lab triggers
    const labCheck = checkLabTriggers(supplement, lab_results)
    if (labCheck.triggered) {
      goalScore += 5 // Lab-based recommendations get high priority
    }

    if (goalScore > 0 || labCheck.triggered) {
      scoredSupplements.push({
        supplement,
        score: goalScore,
        labTriggered: labCheck.triggered,
        labReason: labCheck.reason
      })
    }
  }

  // Sort by score (descending)
  scoredSupplements.sort((a, b) => b.score - a.score)

  // Determine budget multiplier for filtering
  const budgetMultiplier = {
    low: 1,
    medium: 1.5,
    high: 2,
    unlimited: 999
  }[budget]

  let totalEstimatedCost = 0
  const maxMonthlyCost = budget === 'unlimited' ? Infinity : budgetMultiplier * 100

  // Generate recommendations
  for (const { supplement, score, labTriggered, labReason } of scoredSupplements) {
    const monthlyCost = supplement.monthly_cost_range[budget === 'unlimited' ? 'high' : budget]

    // Skip if over budget (unless lab-triggered)
    if (!labTriggered && totalEstimatedCost + monthlyCost > maxMonthlyCost) {
      continue
    }

    // Determine priority
    let priority: SupplementRecommendation['priority']
    if (labTriggered) {
      priority = 'essential'
    } else if (score >= 4) {
      priority = 'highly_recommended'
    } else if (score >= 2) {
      priority = 'beneficial'
    } else {
      priority = 'optional'
    }

    // Build reasoning
    let reasoning = ''
    if (labTriggered && labReason) {
      reasoning = `Lab-based recommendation: ${labReason}. `
    }
    reasoning += supplement.benefits.slice(0, 3).join(', ') + '.'

    // Aligned goals for this recommendation
    const goalAlignment = supplement.goals.filter(g =>
      normalizedGoals.includes(g) || normalizedGoals.some(ng => ng.includes(g) || g.includes(ng))
    )

    const recommendation: SupplementRecommendation = {
      name: supplement.name,
      priority,
      dosage: supplement.common_dosage,
      form: supplement.forms[0],
      reasoning,
      goal_alignment: goalAlignment,
      lab_based: labTriggered,
      estimated_monthly_cost: `$${monthlyCost}`,
      notes: supplement.notes,
      contraindications: supplement.contraindications
    }

    recommendations.push(recommendation)
    totalEstimatedCost += monthlyCost

    // Limit recommendations based on budget
    if (budget === 'low' && recommendations.length >= 5) break
    if (budget === 'medium' && recommendations.length >= 8) break
    if (budget === 'high' && recommendations.length >= 12) break
  }

  // Sort final recommendations by priority
  const priorityOrder = { essential: 0, highly_recommended: 1, beneficial: 2, optional: 3 }
  recommendations.sort((a, b) => priorityOrder[a.priority] - priorityOrder[b.priority])

  // Generate summary
  const essentialCount = recommendations.filter(r => r.priority === 'essential').length
  const highlyRecCount = recommendations.filter(r => r.priority === 'highly_recommended').length

  let summary = `Based on your goals (${goals.join(', ')})`
  if (lab_results.length > 0) {
    summary += ` and lab results`
  }
  summary += `, we recommend ${recommendations.length} supplements. `

  if (essentialCount > 0) {
    summary += `${essentialCount} are essential based on your lab values. `
  }
  if (highlyRecCount > 0) {
    summary += `${highlyRecCount} are highly recommended for your goals.`
  }

  // General notes
  const generalNotes: string[] = [
    'Start with essential and highly recommended supplements first.',
    'Introduce new supplements one at a time to monitor for reactions.',
    'Quality matters - look for third-party tested products (NSF, USP, Informed Sport).'
  ]

  if (recommendations.some(r => r.contraindications && r.contraindications.length > 0)) {
    generalNotes.push('Some recommendations have contraindications - review notes carefully.')
  }

  if (current_supplements.length > 0) {
    generalNotes.push(`You are already taking ${alreadyTaking.length} of the recommended supplements - good foundation!`)
  }

  return {
    success: true,
    patient_id,
    recommendations,
    already_taking: alreadyTaking,
    summary,
    total_estimated_cost: `$${totalEstimatedCost}/month`,
    general_notes: generalNotes
  }
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log(`[supplement-recommendations] Request method: ${req.method}`)

    // Parse request body
    let requestBody: RecommendationsRequest
    try {
      requestBody = await req.json() as RecommendationsRequest
    } catch (parseError) {
      console.error(`[supplement-recommendations] JSON parse error:`, parseError)
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Failed to parse request body',
          recommendations: [],
          already_taking: [],
          summary: '',
          general_notes: []
        } as RecommendationsResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate required fields
    if (!requestBody.goals || !Array.isArray(requestBody.goals) || requestBody.goals.length === 0) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'goals array is required and must not be empty',
          recommendations: [],
          already_taking: [],
          summary: '',
          general_notes: []
        } as RecommendationsResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[supplement-recommendations] Processing for goals: ${requestBody.goals.join(', ')}`)
    if (requestBody.lab_results) {
      console.log(`[supplement-recommendations] Lab results provided: ${requestBody.lab_results.length} biomarkers`)
    }

    // Generate recommendations
    const response = generateRecommendations(requestBody)

    console.log(`[supplement-recommendations] Generated ${response.recommendations.length} recommendations`)

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[supplement-recommendations] Error:', error)

    const errorMessage = error instanceof Error ? error.message : 'Internal server error'

    return new Response(
      JSON.stringify({
        success: false,
        error: errorMessage,
        recommendations: [],
        already_taking: [],
        summary: '',
        general_notes: []
      } as RecommendationsResponse),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
