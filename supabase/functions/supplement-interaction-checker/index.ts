// ============================================================================
// Supplement Interaction Checker Edge Function
// Health Intelligence Platform - Safety & Interaction Analysis
// ============================================================================
// Analyzes supplements and medications for potential interactions, safety
// concerns, and provides warnings for dangerous combinations.
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

interface Supplement {
  name: string
  dosage?: string
}

interface Medication {
  name: string
  dosage?: string
  category?: string
}

interface InteractionCheckerRequest {
  supplements: Supplement[]
  medications?: Medication[]
}

interface Interaction {
  item1: string
  item2: string
  severity: 'critical' | 'major' | 'moderate' | 'minor'
  type: 'absorption' | 'efficacy' | 'toxicity' | 'bleeding' | 'metabolic' | 'other'
  description: string
  recommendation: string
}

interface SafetyWarning {
  supplement: string
  warning_type: 'dosage' | 'duration' | 'condition' | 'general'
  description: string
  recommendation: string
}

interface InteractionCheckerResponse {
  success: boolean
  overall_safety: 'safe' | 'caution' | 'warning' | 'danger'
  interactions: Interaction[]
  safety_warnings: SafetyWarning[]
  timing_recommendations: string[]
  summary: string
  disclaimer: string
  error?: string
}

// ============================================================================
// INTERACTION DATABASE
// ============================================================================

interface InteractionRule {
  items: string[] // Items that interact (normalized names)
  severity: Interaction['severity']
  type: Interaction['type']
  description: string
  recommendation: string
}

const SUPPLEMENT_INTERACTIONS: InteractionRule[] = [
  // Mineral Absorption Conflicts
  {
    items: ['iron', 'calcium'],
    severity: 'moderate',
    type: 'absorption',
    description: 'Calcium significantly reduces iron absorption by up to 50%.',
    recommendation: 'Separate by at least 2 hours. Take iron in the morning, calcium in the evening.'
  },
  {
    items: ['iron', 'zinc'],
    severity: 'moderate',
    type: 'absorption',
    description: 'Iron and zinc compete for absorption pathways.',
    recommendation: 'Separate by at least 2 hours. Take at different meals.'
  },
  {
    items: ['zinc', 'copper'],
    severity: 'major',
    type: 'absorption',
    description: 'High zinc intake (>40mg/day) can cause copper deficiency over time.',
    recommendation: 'If taking zinc long-term, supplement with copper at 10:1 ratio (e.g., 30mg zinc : 3mg copper).'
  },
  {
    items: ['calcium', 'magnesium'],
    severity: 'moderate',
    type: 'absorption',
    description: 'High calcium doses can interfere with magnesium absorption.',
    recommendation: 'Separate by at least 2 hours, or take magnesium before bed and calcium earlier in the day.'
  },
  {
    items: ['zinc', 'calcium'],
    severity: 'moderate',
    type: 'absorption',
    description: 'Calcium may reduce zinc absorption.',
    recommendation: 'Separate by at least 2 hours for optimal absorption of both minerals.'
  },
  {
    items: ['iron', 'vitamin e'],
    severity: 'minor',
    type: 'absorption',
    description: 'Vitamin E may reduce iron absorption.',
    recommendation: 'Separate by 2 hours if taking therapeutic doses of either.'
  },

  // Vitamin Interactions
  {
    items: ['vitamin c', 'vitamin b12'],
    severity: 'minor',
    type: 'absorption',
    description: 'High doses of Vitamin C (>1000mg) may reduce B12 absorption.',
    recommendation: 'Separate high-dose Vitamin C from B12 by 2+ hours.'
  },
  {
    items: ['vitamin d', 'vitamin k2'],
    severity: 'minor',
    type: 'efficacy',
    description: 'These work synergistically - not a negative interaction.',
    recommendation: 'Take together for optimal calcium metabolism and bone health.'
  },
  {
    items: ['vitamin a', 'vitamin d'],
    severity: 'moderate',
    type: 'efficacy',
    description: 'High doses of Vitamin A can antagonize Vitamin D benefits.',
    recommendation: 'Avoid high-dose Vitamin A (>10,000 IU) when supplementing Vitamin D.'
  },

  // Herbal Interactions
  {
    items: ['ashwagandha', 'thyroid'],
    severity: 'major',
    type: 'efficacy',
    description: 'Ashwagandha may affect thyroid hormone levels.',
    recommendation: 'Monitor thyroid levels closely. Consult healthcare provider if on thyroid medication.'
  },
  {
    items: ['st johns wort', 'ssri'],
    severity: 'critical',
    type: 'toxicity',
    description: 'Can cause serotonin syndrome - a potentially life-threatening condition.',
    recommendation: 'DO NOT combine. Discuss alternatives with your healthcare provider.'
  },
  {
    items: ['ginkgo', 'blood thinner'],
    severity: 'major',
    type: 'bleeding',
    description: 'Ginkgo has antiplatelet effects that can increase bleeding risk.',
    recommendation: 'Avoid combination or monitor closely with physician supervision.'
  },
  {
    items: ['garlic', 'blood thinner'],
    severity: 'moderate',
    type: 'bleeding',
    description: 'Garlic supplements may enhance anticoagulant effects.',
    recommendation: 'Use caution and monitor for signs of increased bleeding.'
  },
  {
    items: ['turmeric', 'blood thinner'],
    severity: 'moderate',
    type: 'bleeding',
    description: 'Curcumin has mild antiplatelet effects.',
    recommendation: 'Use caution with high doses. Discuss with healthcare provider.'
  },
  {
    items: ['ginseng', 'blood thinner'],
    severity: 'moderate',
    type: 'bleeding',
    description: 'Ginseng may affect blood clotting.',
    recommendation: 'Monitor for bleeding. Consult healthcare provider.'
  },

  // Amino Acid Interactions
  {
    items: ['tyrosine', 'maoi'],
    severity: 'critical',
    type: 'toxicity',
    description: 'Can cause dangerous spikes in blood pressure (hypertensive crisis).',
    recommendation: 'DO NOT combine. This interaction can be life-threatening.'
  },
  {
    items: ['5-htp', 'ssri'],
    severity: 'critical',
    type: 'toxicity',
    description: 'Can cause serotonin syndrome - a potentially life-threatening condition.',
    recommendation: 'DO NOT combine. Discuss alternatives with your healthcare provider.'
  },
  {
    items: ['tryptophan', 'ssri'],
    severity: 'major',
    type: 'toxicity',
    description: 'May increase risk of serotonin syndrome.',
    recommendation: 'Avoid combination without medical supervision.'
  },

  // Stimulant Interactions
  {
    items: ['caffeine', 'ephedra'],
    severity: 'critical',
    type: 'toxicity',
    description: 'Dangerous cardiovascular stimulation. Can cause heart attack or stroke.',
    recommendation: 'DO NOT combine. This combination has caused deaths.'
  },
  {
    items: ['caffeine', 'stimulant'],
    severity: 'major',
    type: 'toxicity',
    description: 'Additive stimulant effects can cause anxiety, heart palpitations, and cardiovascular stress.',
    recommendation: 'Reduce caffeine intake when using stimulant medications.'
  },

  // Blood Sugar Interactions
  {
    items: ['berberine', 'metformin'],
    severity: 'major',
    type: 'metabolic',
    description: 'Both lower blood sugar - risk of hypoglycemia.',
    recommendation: 'Monitor blood sugar closely. May need medication dose adjustment.'
  },
  {
    items: ['chromium', 'diabetes medication'],
    severity: 'moderate',
    type: 'metabolic',
    description: 'May enhance blood sugar lowering effects.',
    recommendation: 'Monitor blood sugar and consult healthcare provider.'
  },
  {
    items: ['alpha lipoic acid', 'diabetes medication'],
    severity: 'moderate',
    type: 'metabolic',
    description: 'May enhance blood sugar lowering effects.',
    recommendation: 'Monitor blood sugar levels closely.'
  },

  // Thyroid Interactions
  {
    items: ['calcium', 'levothyroxine'],
    severity: 'major',
    type: 'absorption',
    description: 'Calcium significantly reduces thyroid medication absorption.',
    recommendation: 'Take thyroid medication 4 hours apart from calcium supplements.'
  },
  {
    items: ['iron', 'levothyroxine'],
    severity: 'major',
    type: 'absorption',
    description: 'Iron significantly reduces thyroid medication absorption.',
    recommendation: 'Take thyroid medication 4 hours apart from iron supplements.'
  },
  {
    items: ['magnesium', 'levothyroxine'],
    severity: 'moderate',
    type: 'absorption',
    description: 'Magnesium may reduce thyroid medication absorption.',
    recommendation: 'Separate by at least 4 hours.'
  },
  {
    items: ['soy', 'levothyroxine'],
    severity: 'moderate',
    type: 'absorption',
    description: 'Soy can interfere with thyroid medication absorption.',
    recommendation: 'Take thyroid medication 4 hours apart from soy products/supplements.'
  },

  // Blood Pressure Interactions
  {
    items: ['potassium', 'ace inhibitor'],
    severity: 'major',
    type: 'metabolic',
    description: 'ACE inhibitors increase potassium retention. Additional potassium can cause dangerous hyperkalemia.',
    recommendation: 'Avoid potassium supplements unless directed by physician. Monitor levels.'
  },
  {
    items: ['licorice', 'blood pressure medication'],
    severity: 'major',
    type: 'efficacy',
    description: 'Licorice root can raise blood pressure and counteract medication.',
    recommendation: 'Avoid licorice root supplements if on blood pressure medication.'
  },

  // Vitamin K and Blood Thinners
  {
    items: ['vitamin k', 'warfarin'],
    severity: 'critical',
    type: 'efficacy',
    description: 'Vitamin K directly counteracts warfarin anticoagulant effect.',
    recommendation: 'Maintain consistent Vitamin K intake. Any changes require INR monitoring and possible dose adjustment.'
  },
  {
    items: ['vitamin e', 'warfarin'],
    severity: 'major',
    type: 'bleeding',
    description: 'High-dose Vitamin E (>400 IU) may increase bleeding risk.',
    recommendation: 'Avoid high-dose Vitamin E. Monitor for bleeding signs.'
  },
  {
    items: ['fish oil', 'warfarin'],
    severity: 'moderate',
    type: 'bleeding',
    description: 'Fish oil has mild antiplatelet effects.',
    recommendation: 'Monitor INR more frequently. Therapeutic doses (2-4g) usually acceptable with monitoring.'
  },
  {
    items: ['fish oil', 'blood thinner'],
    severity: 'moderate',
    type: 'bleeding',
    description: 'Fish oil has mild blood-thinning properties.',
    recommendation: 'Use caution with high doses. Monitor for unusual bleeding.'
  },

  // CoQ10 Interactions
  {
    items: ['coq10', 'warfarin'],
    severity: 'moderate',
    type: 'efficacy',
    description: 'CoQ10 may reduce warfarin effectiveness.',
    recommendation: 'Monitor INR closely when starting or stopping CoQ10.'
  },
  {
    items: ['coq10', 'statin'],
    severity: 'minor',
    type: 'efficacy',
    description: 'Statins deplete CoQ10 - this is a beneficial interaction.',
    recommendation: 'CoQ10 supplementation is often recommended when taking statins.'
  },

  // Melatonin Interactions
  {
    items: ['melatonin', 'sedative'],
    severity: 'moderate',
    type: 'efficacy',
    description: 'Additive sedative effects may cause excessive drowsiness.',
    recommendation: 'Start with lower melatonin dose. Use caution with driving/machinery.'
  },
  {
    items: ['melatonin', 'blood thinner'],
    severity: 'minor',
    type: 'bleeding',
    description: 'Melatonin may have mild anticoagulant effects.',
    recommendation: 'Generally safe but monitor for unusual bleeding.'
  },

  // Magnesium and Medications
  {
    items: ['magnesium', 'antibiotic'],
    severity: 'major',
    type: 'absorption',
    description: 'Magnesium can bind to certain antibiotics (fluoroquinolones, tetracyclines) reducing their effectiveness.',
    recommendation: 'Take antibiotics 2 hours before or 6 hours after magnesium supplements.'
  },
  {
    items: ['magnesium', 'bisphosphonate'],
    severity: 'major',
    type: 'absorption',
    description: 'Magnesium reduces absorption of bisphosphonate medications for osteoporosis.',
    recommendation: 'Take bisphosphonates at least 2 hours before any supplements.'
  },

  // Green Tea Extract
  {
    items: ['green tea', 'stimulant'],
    severity: 'moderate',
    type: 'toxicity',
    description: 'Additive stimulant effects from caffeine content.',
    recommendation: 'Reduce caffeine/green tea intake if on stimulant medications.'
  },
  {
    items: ['green tea', 'blood thinner'],
    severity: 'moderate',
    type: 'efficacy',
    description: 'Green tea contains Vitamin K which may affect anticoagulation.',
    recommendation: 'Maintain consistent intake. Monitor INR if on warfarin.'
  },

  // DHEA Interactions
  {
    items: ['dhea', 'hormone'],
    severity: 'major',
    type: 'efficacy',
    description: 'DHEA is a hormone precursor and may affect hormone therapy.',
    recommendation: 'Discuss with healthcare provider before combining with any hormone medications.'
  },

  // Beneficial Synergies (noted as minor for reference)
  {
    items: ['vitamin c', 'iron'],
    severity: 'minor',
    type: 'absorption',
    description: 'Vitamin C enhances iron absorption - beneficial combination.',
    recommendation: 'Take together for improved iron absorption.'
  },
  {
    items: ['curcumin', 'piperine'],
    severity: 'minor',
    type: 'absorption',
    description: 'Piperine (black pepper) increases curcumin absorption by 2000%.',
    recommendation: 'Take curcumin with piperine/black pepper for best absorption.'
  }
]

// ============================================================================
// SAFETY WARNINGS DATABASE
// ============================================================================

interface SafetyRule {
  supplement: string
  warning_type: SafetyWarning['warning_type']
  description: string
  recommendation: string
}

const SAFETY_WARNINGS: SafetyRule[] = [
  // Fat-Soluble Vitamin Warnings
  {
    supplement: 'vitamin a',
    warning_type: 'dosage',
    description: 'Vitamin A is fat-soluble and can accumulate to toxic levels. Doses above 10,000 IU daily may cause toxicity.',
    recommendation: 'Do not exceed 10,000 IU daily unless under medical supervision. Beta-carotene is a safer alternative.'
  },
  {
    supplement: 'vitamin d',
    warning_type: 'dosage',
    description: 'Vitamin D toxicity can occur at very high doses (>50,000 IU daily for extended periods).',
    recommendation: 'Test blood levels every 3-6 months. Target 40-60 ng/mL. Most people need 2000-5000 IU daily.'
  },
  {
    supplement: 'vitamin e',
    warning_type: 'dosage',
    description: 'High-dose Vitamin E (>400 IU) may increase all-cause mortality in some studies.',
    recommendation: 'Keep doses under 400 IU daily. Natural mixed tocopherols preferred over synthetic.'
  },

  // Mineral Warnings
  {
    supplement: 'iron',
    warning_type: 'condition',
    description: 'Iron supplementation without deficiency can cause iron overload, oxidative stress, and organ damage.',
    recommendation: 'Only supplement if lab tests confirm deficiency. Test ferritin levels regularly.'
  },
  {
    supplement: 'selenium',
    warning_type: 'dosage',
    description: 'Selenium has a narrow therapeutic range. Toxicity can occur above 400 mcg daily.',
    recommendation: 'Do not exceed 200 mcg daily from supplements. Consider dietary sources.'
  },
  {
    supplement: 'zinc',
    warning_type: 'duration',
    description: 'Long-term zinc supplementation (>40mg daily) can cause copper deficiency.',
    recommendation: 'If taking zinc long-term, add copper at 10:1 ratio or take breaks.'
  },

  // Herbal Warnings
  {
    supplement: 'kava',
    warning_type: 'condition',
    description: 'Kava has been associated with severe liver damage in rare cases.',
    recommendation: 'Avoid if you have liver conditions. Limit use to 1-2 months. Avoid alcohol.'
  },
  {
    supplement: 'ephedra',
    warning_type: 'general',
    description: 'Ephedra is banned in many countries due to cardiovascular risks including heart attack and stroke.',
    recommendation: 'Avoid ephedra-containing products. They are dangerous.'
  },
  {
    supplement: 'comfrey',
    warning_type: 'general',
    description: 'Comfrey contains pyrrolizidine alkaloids that can cause liver damage.',
    recommendation: 'Avoid internal use. External use only for short periods.'
  },
  {
    supplement: 'aristolochia',
    warning_type: 'general',
    description: 'Aristolochia contains aristolochic acid, which causes kidney failure and cancer.',
    recommendation: 'Never use aristolochia products. They are extremely dangerous.'
  },

  // Amino Acid Warnings
  {
    supplement: '5-htp',
    warning_type: 'duration',
    description: '5-HTP may deplete dopamine with long-term use if used alone.',
    recommendation: 'Cycle use (8 weeks on, 4 weeks off) or combine with EGCG/green tea extract.'
  },
  {
    supplement: 'tryptophan',
    warning_type: 'condition',
    description: 'May worsen certain autoimmune conditions by activating the immune system.',
    recommendation: 'Consult healthcare provider if you have autoimmune conditions.'
  },

  // Stimulant Warnings
  {
    supplement: 'caffeine',
    warning_type: 'dosage',
    description: 'Caffeine doses above 400mg daily may cause anxiety, insomnia, and cardiovascular effects.',
    recommendation: 'Keep total daily caffeine under 400mg. Avoid within 8-10 hours of bedtime.'
  },
  {
    supplement: 'yohimbe',
    warning_type: 'condition',
    description: 'Yohimbe can cause dangerous spikes in blood pressure and heart rate.',
    recommendation: 'Avoid if you have heart conditions, anxiety, or high blood pressure.'
  },

  // Hormone Warnings
  {
    supplement: 'dhea',
    warning_type: 'condition',
    description: 'DHEA is a hormone that can affect testosterone and estrogen levels.',
    recommendation: 'Only use if lab tests show deficiency. Monitor hormone levels. Avoid if hormone-sensitive conditions.'
  },
  {
    supplement: 'pregnenolone',
    warning_type: 'condition',
    description: 'Pregnenolone is a hormone precursor that can affect multiple hormone pathways.',
    recommendation: 'Use only under medical supervision with hormone testing.'
  },
  {
    supplement: 'melatonin',
    warning_type: 'duration',
    description: 'Long-term high-dose melatonin may affect natural production.',
    recommendation: 'Use lowest effective dose (0.5-3mg). Consider cycling for long-term use.'
  },

  // Liver Concern Supplements
  {
    supplement: 'green tea extract',
    warning_type: 'dosage',
    description: 'High-dose green tea extract (EGCG >800mg) has been associated with liver damage.',
    recommendation: 'Keep EGCG doses under 800mg daily. Take with food. Avoid if liver issues.'
  },
  {
    supplement: 'niacin',
    warning_type: 'dosage',
    description: 'High-dose niacin (>500mg) can cause flushing and liver stress.',
    recommendation: 'Start low and increase slowly. Extended-release forms may have higher liver risk.'
  },

  // Blood Clotting Warnings
  {
    supplement: 'vitamin k',
    warning_type: 'condition',
    description: 'Vitamin K affects blood clotting and interacts with anticoagulant medications.',
    recommendation: 'Maintain consistent intake if on blood thinners. Inform your doctor about supplementation.'
  },

  // General Warnings
  {
    supplement: 'colloidal silver',
    warning_type: 'general',
    description: 'Colloidal silver has no proven benefits and can cause argyria (permanent skin discoloration).',
    recommendation: 'Avoid colloidal silver. It is not effective and can be harmful.'
  }
]

// ============================================================================
// MEDICATION CATEGORIES FOR MATCHING
// ============================================================================

const MEDICATION_CATEGORIES: Record<string, string[]> = {
  'blood thinner': ['warfarin', 'coumadin', 'heparin', 'eliquis', 'xarelto', 'pradaxa', 'aspirin', 'plavix', 'anticoagulant'],
  'ssri': ['prozac', 'zoloft', 'lexapro', 'celexa', 'paxil', 'fluoxetine', 'sertraline', 'escitalopram', 'citalopram', 'paroxetine', 'antidepressant'],
  'maoi': ['nardil', 'parnate', 'marplan', 'phenelzine', 'tranylcypromine', 'isocarboxazid'],
  'statin': ['lipitor', 'crestor', 'zocor', 'pravachol', 'atorvastatin', 'rosuvastatin', 'simvastatin', 'pravastatin'],
  'blood pressure medication': ['lisinopril', 'losartan', 'amlodipine', 'metoprolol', 'hydrochlorothiazide', 'atenolol', 'antihypertensive'],
  'ace inhibitor': ['lisinopril', 'enalapril', 'ramipril', 'benazepril', 'captopril'],
  'diabetes medication': ['metformin', 'glipizide', 'glyburide', 'insulin', 'januvia', 'farxiga', 'jardiance', 'ozempic'],
  'levothyroxine': ['synthroid', 'levothyroxine', 'levoxyl', 'tirosint', 'thyroid medication'],
  'thyroid': ['synthroid', 'levothyroxine', 'armour thyroid', 'cytomel', 'thyroid medication'],
  'sedative': ['ambien', 'lunesta', 'xanax', 'valium', 'ativan', 'klonopin', 'benzodiazepine', 'sleep medication'],
  'antibiotic': ['amoxicillin', 'ciprofloxacin', 'doxycycline', 'azithromycin', 'fluoroquinolone', 'tetracycline'],
  'bisphosphonate': ['fosamax', 'boniva', 'actonel', 'reclast', 'alendronate', 'ibandronate'],
  'stimulant': ['adderall', 'ritalin', 'vyvanse', 'concerta', 'amphetamine', 'methylphenidate'],
  'hormone': ['estrogen', 'progesterone', 'testosterone', 'birth control', 'hrt', 'hormone replacement']
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function normalizeItem(name: string): string {
  return name.toLowerCase()
    .replace(/[^a-z0-9\s]/g, '')
    .trim()
}

function getMedicationCategories(medication: Medication): string[] {
  const normalized = normalizeItem(medication.name)
  const categories: string[] = []

  // Check explicit category
  if (medication.category) {
    categories.push(normalizeItem(medication.category))
  }

  // Match against known categories
  for (const [category, keywords] of Object.entries(MEDICATION_CATEGORIES)) {
    if (keywords.some(keyword => normalized.includes(keyword) || keyword.includes(normalized))) {
      categories.push(category)
    }
  }

  return categories
}

function matchesItem(item1: string, item2: string): boolean {
  const norm1 = normalizeItem(item1)
  const norm2 = normalizeItem(item2)

  return norm1.includes(norm2) || norm2.includes(norm1) || norm1 === norm2
}

function findInteractions(supplements: Supplement[], medications: Medication[]): Interaction[] {
  const interactions: Interaction[] = []
  const allItems: { name: string; type: 'supplement' | 'medication'; categories?: string[] }[] = []

  // Add supplements
  for (const supp of supplements) {
    allItems.push({ name: supp.name, type: 'supplement' })
  }

  // Add medications with their categories
  for (const med of medications) {
    const categories = getMedicationCategories(med)
    allItems.push({ name: med.name, type: 'medication', categories })
  }

  // Check each interaction rule
  for (const rule of SUPPLEMENT_INTERACTIONS) {
    const [ruleItem1, ruleItem2] = rule.items

    // Find matches for rule items
    for (let i = 0; i < allItems.length; i++) {
      for (let j = i + 1; j < allItems.length; j++) {
        const item1 = allItems[i]
        const item2 = allItems[j]

        const item1Matches = matchesItem(item1.name, ruleItem1) ||
          (item1.categories?.some(cat => matchesItem(cat, ruleItem1)))

        const item2Matches = matchesItem(item2.name, ruleItem2) ||
          (item2.categories?.some(cat => matchesItem(cat, ruleItem2)))

        const item1MatchesReverse = matchesItem(item1.name, ruleItem2) ||
          (item1.categories?.some(cat => matchesItem(cat, ruleItem2)))

        const item2MatchesReverse = matchesItem(item2.name, ruleItem1) ||
          (item2.categories?.some(cat => matchesItem(cat, ruleItem1)))

        if ((item1Matches && item2Matches) || (item1MatchesReverse && item2MatchesReverse)) {
          // Check for duplicate
          const isDuplicate = interactions.some(int =>
            (int.item1 === item1.name && int.item2 === item2.name) ||
            (int.item1 === item2.name && int.item2 === item1.name)
          )

          if (!isDuplicate) {
            interactions.push({
              item1: item1.name,
              item2: item2.name,
              severity: rule.severity,
              type: rule.type,
              description: rule.description,
              recommendation: rule.recommendation
            })
          }
        }
      }
    }
  }

  // Sort by severity
  const severityOrder = { critical: 0, major: 1, moderate: 2, minor: 3 }
  interactions.sort((a, b) => severityOrder[a.severity] - severityOrder[b.severity])

  return interactions
}

function findSafetyWarnings(supplements: Supplement[]): SafetyWarning[] {
  const warnings: SafetyWarning[] = []

  for (const supplement of supplements) {
    const normalized = normalizeItem(supplement.name)

    for (const rule of SAFETY_WARNINGS) {
      if (matchesItem(normalized, rule.supplement)) {
        warnings.push({
          supplement: supplement.name,
          warning_type: rule.warning_type,
          description: rule.description,
          recommendation: rule.recommendation
        })
      }
    }
  }

  return warnings
}

function generateTimingRecommendations(interactions: Interaction[], supplements: Supplement[]): string[] {
  const recommendations: string[] = []
  const supplementNames = supplements.map(s => normalizeItem(s.name))

  // Check for absorption conflicts
  const absorptionConflicts = interactions.filter(i => i.type === 'absorption' && i.severity !== 'minor')

  if (absorptionConflicts.length > 0) {
    recommendations.push('Separate the following supplements by at least 2 hours for optimal absorption:')
    for (const conflict of absorptionConflicts) {
      recommendations.push(`  - ${conflict.item1} and ${conflict.item2}`)
    }
  }

  // Iron timing
  if (supplementNames.some(n => n.includes('iron'))) {
    recommendations.push('Take iron on an empty stomach with Vitamin C for best absorption. Separate from calcium, zinc, and coffee by 2+ hours.')
  }

  // Fat-soluble vitamins
  const fatSolubles = ['vitamin d', 'vitamin a', 'vitamin e', 'vitamin k', 'fish oil', 'omega']
  if (supplementNames.some(n => fatSolubles.some(f => n.includes(f)))) {
    recommendations.push('Take fat-soluble vitamins (D, A, E, K) and fish oil with meals containing healthy fats.')
  }

  // Magnesium/sleep supplements
  const sleepSupps = ['magnesium', 'melatonin', 'glycine', 'ashwagandha']
  if (supplementNames.some(n => sleepSupps.some(s => n.includes(s)))) {
    recommendations.push('Take sleep-supporting supplements (magnesium, melatonin, glycine, ashwagandha) 30-60 minutes before bed.')
  }

  // Probiotics
  if (supplementNames.some(n => n.includes('probiotic'))) {
    recommendations.push('Take probiotics on an empty stomach, ideally 30 minutes before breakfast.')
  }

  // B vitamins
  if (supplementNames.some(n => n.includes('b12') || n.includes('b complex') || n.includes('b vitamin'))) {
    recommendations.push('Take B vitamins in the morning as they may provide energy and interfere with sleep if taken late.')
  }

  // Caffeine
  if (supplementNames.some(n => n.includes('caffeine') || n.includes('green tea') || n.includes('pre workout'))) {
    recommendations.push('Avoid caffeine-containing supplements within 8-10 hours of bedtime.')
  }

  return recommendations
}

function determineOverallSafety(interactions: Interaction[], warnings: SafetyWarning[]): InteractionCheckerResponse['overall_safety'] {
  const hasCritical = interactions.some(i => i.severity === 'critical')
  const hasMajor = interactions.some(i => i.severity === 'major')
  const hasModerate = interactions.some(i => i.severity === 'moderate')

  if (hasCritical) return 'danger'
  if (hasMajor) return 'warning'
  if (hasModerate || warnings.length > 3) return 'caution'
  return 'safe'
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
    console.log(`[supplement-interaction-checker] Request method: ${req.method}`)

    // Parse request body
    let requestBody: InteractionCheckerRequest
    try {
      requestBody = await req.json() as InteractionCheckerRequest
    } catch (parseError) {
      console.error(`[supplement-interaction-checker] JSON parse error:`, parseError)
      return new Response(
        JSON.stringify({
          success: false,
          overall_safety: 'safe',
          interactions: [],
          safety_warnings: [],
          timing_recommendations: [],
          summary: '',
          disclaimer: '',
          error: 'Failed to parse request body'
        } as InteractionCheckerResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate required fields
    if (!requestBody.supplements || !Array.isArray(requestBody.supplements) || requestBody.supplements.length === 0) {
      return new Response(
        JSON.stringify({
          success: false,
          overall_safety: 'safe',
          interactions: [],
          safety_warnings: [],
          timing_recommendations: [],
          summary: '',
          disclaimer: '',
          error: 'supplements array is required and must not be empty'
        } as InteractionCheckerResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supplements = requestBody.supplements
    const medications = requestBody.medications || []

    console.log(`[supplement-interaction-checker] Checking ${supplements.length} supplements, ${medications.length} medications`)

    // Find interactions
    const interactions = findInteractions(supplements, medications)

    // Find safety warnings
    const safetyWarnings = findSafetyWarnings(supplements)

    // Generate timing recommendations
    const timingRecommendations = generateTimingRecommendations(interactions, supplements)

    // Determine overall safety
    const overallSafety = determineOverallSafety(interactions, safetyWarnings)

    // Generate summary
    let summary = ''
    const criticalCount = interactions.filter(i => i.severity === 'critical').length
    const majorCount = interactions.filter(i => i.severity === 'major').length
    const moderateCount = interactions.filter(i => i.severity === 'moderate').length

    if (criticalCount > 0) {
      summary = `CRITICAL: ${criticalCount} dangerous interaction(s) found that require immediate attention. `
    }
    if (majorCount > 0) {
      summary += `${majorCount} major interaction(s) require medical consultation. `
    }
    if (moderateCount > 0) {
      summary += `${moderateCount} moderate interaction(s) may need timing adjustments. `
    }
    if (interactions.length === 0 && safetyWarnings.length === 0) {
      summary = 'No significant interactions detected between your supplements'
      if (medications.length > 0) {
        summary += ' and medications'
      }
      summary += '. Follow general timing recommendations for optimal absorption.'
    }
    if (safetyWarnings.length > 0) {
      summary += `${safetyWarnings.length} general safety consideration(s) noted.`
    }

    const disclaimer = 'This information is for educational purposes only and is not a substitute for professional medical advice. Always consult with a healthcare provider before starting, stopping, or changing any supplement or medication regimen.'

    const response: InteractionCheckerResponse = {
      success: true,
      overall_safety: overallSafety,
      interactions,
      safety_warnings: safetyWarnings,
      timing_recommendations: timingRecommendations,
      summary,
      disclaimer
    }

    console.log(`[supplement-interaction-checker] Found ${interactions.length} interactions, ${safetyWarnings.length} warnings`)
    console.log(`[supplement-interaction-checker] Overall safety: ${overallSafety}`)

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[supplement-interaction-checker] Error:', error)

    const errorMessage = error instanceof Error ? error.message : 'Internal server error'

    return new Response(
      JSON.stringify({
        success: false,
        overall_safety: 'safe',
        interactions: [],
        safety_warnings: [],
        timing_recommendations: [],
        summary: '',
        disclaimer: 'This information is for educational purposes only and is not a substitute for professional medical advice.',
        error: errorMessage
      } as InteractionCheckerResponse),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
