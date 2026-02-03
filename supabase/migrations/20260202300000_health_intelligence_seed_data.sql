-- ============================================================================
-- HEALTH INTELLIGENCE EXPANDED SEED DATA MIGRATION
-- ============================================================================
-- Expands seed data for the Health Intelligence Platform with:
-- - 100+ supplements (Momentous products + common supplements)
-- - Additional athlete-specific biomarker reference ranges
-- - More recovery protocols (Wim Hof, post-game, travel, sleep, active recovery)
-- - Fasting protocol details with benefits and contraindications
--
-- Date: 2026-02-02
-- ============================================================================

BEGIN;

-- ============================================================================
-- ADD UNIQUE CONSTRAINTS FOR IDEMPOTENCY (IF NOT EXISTS)
-- ============================================================================

-- Add unique constraint on supplements.name if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'supplements_name_key'
        AND conrelid = 'supplements'::regclass
    ) THEN
        ALTER TABLE supplements ADD CONSTRAINT supplements_name_key UNIQUE (name);
    END IF;
EXCEPTION
    WHEN undefined_table THEN NULL;
END $$;

-- Add unique constraint on fasting_protocols.name if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fasting_protocols_name_key'
        AND conrelid = 'fasting_protocols'::regclass
    ) THEN
        ALTER TABLE fasting_protocols ADD CONSTRAINT fasting_protocols_name_key UNIQUE (name);
    END IF;
EXCEPTION
    WHEN undefined_table THEN NULL;
END $$;

-- Add unique constraint on recovery_protocols.name if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'recovery_protocols_name_key'
        AND conrelid = 'recovery_protocols'::regclass
    ) THEN
        ALTER TABLE recovery_protocols ADD CONSTRAINT recovery_protocols_name_key UNIQUE (name);
    END IF;
EXCEPTION
    WHEN undefined_table THEN NULL;
END $$;

-- ============================================================================
-- ADD NEW COLUMNS TO FASTING_PROTOCOLS FOR BENEFITS/CONTRAINDICATIONS
-- ============================================================================

ALTER TABLE fasting_protocols
    ADD COLUMN IF NOT EXISTS benefits JSONB DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS contraindications JSONB DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS training_adjustments TEXT;

COMMENT ON COLUMN fasting_protocols.benefits IS 'JSONB array of health benefits for this fasting protocol';
COMMENT ON COLUMN fasting_protocols.contraindications IS 'JSONB array of contraindications and warnings';
COMMENT ON COLUMN fasting_protocols.training_adjustments IS 'Recommended training adjustments during this protocol';

-- ============================================================================
-- SUPPLEMENTS CATALOG (100+ items)
-- ============================================================================

-- ============================================================================
-- PERFORMANCE SUPPLEMENTS
-- ============================================================================

INSERT INTO supplements (name, category, description, evidence_rating, dosage_info, timing_recommendation, interactions)
VALUES
    -- Creatine Products
    ('Momentous Creatine Monohydrate', 'performance', 'Pharmaceutical-grade creatine monohydrate. The most studied sports supplement with strong evidence for increasing strength, power, and lean mass. Supports ATP regeneration for high-intensity exercise.', 5, '5g daily (loading phase optional: 20g/day for 5-7 days)', 'Any time of day, consistency is key. Post-workout may slightly improve uptake.', '["May interact with nephrotoxic drugs", "Caffeine may reduce ergogenic effects", "NSAIDs may increase risk of kidney issues"]'::jsonb),
    ('Creatine HCL', 'performance', 'Hydrochloride form of creatine with improved solubility. May cause less bloating than monohydrate in some individuals.', 4, '1.5-2g daily', 'Pre or post-workout', '["Same interactions as creatine monohydrate"]'::jsonb),

    -- Beta-Alanine Products
    ('Momentous Beta-Alanine', 'performance', 'Precursor to carnosine, which buffers acid in muscles during high-intensity exercise. Improves performance in exercises lasting 1-4 minutes.', 5, '3.2-6.4g daily, split into smaller doses', 'Divided doses throughout the day to minimize tingling (paresthesia)', '["May cause harmless tingling sensation", "No significant drug interactions known"]'::jsonb),
    ('Beta-Alanine Sustained Release', 'performance', 'Slow-release formula to minimize paresthesia while maintaining carnosine elevation.', 4, '3.2g twice daily', 'Morning and evening with meals', '["May cause mild tingling", "Safe to combine with most supplements"]'::jsonb),

    -- Caffeine Products
    ('Momentous Caffeine', 'performance', 'Pharmaceutical-grade caffeine for enhanced focus, alertness, and exercise performance. Well-researched ergogenic aid.', 5, '100-400mg depending on tolerance', '30-60 minutes pre-workout. Avoid within 8-10 hours of bedtime.', '["May interact with stimulant medications", "Can increase heart rate and blood pressure", "May reduce effectiveness of sleep aids", "Interacts with MAOIs"]'::jsonb),
    ('Caffeine + L-Theanine', 'performance', 'Synergistic combination providing smooth energy without jitters. L-Theanine modulates caffeine''s stimulatory effects.', 5, '100mg caffeine + 200mg L-theanine', '30-60 minutes before activity requiring focus', '["Same caffeine interactions apply", "L-Theanine may enhance effects of blood pressure medications"]'::jsonb),

    -- Citrulline Products
    ('Momentous Citrulline Malate', 'performance', 'Enhances nitric oxide production for improved blood flow and exercise performance. Reduces fatigue and muscle soreness.', 4, '6-8g citrulline malate (or 3-4g L-citrulline)', '30-60 minutes pre-workout', '["May enhance effects of blood pressure medications", "May interact with nitrates", "PDE5 inhibitors interaction possible"]'::jsonb),
    ('L-Citrulline', 'performance', 'Pure L-citrulline for nitric oxide support. Converts to arginine in the kidneys more efficiently than arginine supplements.', 4, '3-6g daily', 'Pre-workout or divided doses', '["Same interactions as citrulline malate"]'::jsonb),

    -- BCAA/EAA Products
    ('Momentous Essential Amino Acids', 'performance', 'Complete EAA profile with optimal ratios for muscle protein synthesis. More effective than BCAAs alone.', 4, '10-15g per serving', 'During or immediately post-workout', '["May interfere with levodopa absorption", "Use caution with branched-chain ketoaciduria"]'::jsonb),
    ('BCAA 2:1:1', 'performance', 'Branched-chain amino acids (leucine, isoleucine, valine) for muscle preservation during training.', 3, '5-10g per serving', 'During prolonged exercise or fasted training', '["May interfere with blood sugar medications", "Caution with ALS medications"]'::jsonb),
    ('Leucine Isolate', 'performance', 'Pure leucine for maximizing mTOR activation and muscle protein synthesis.', 4, '2.5-5g per serving', 'Post-workout or between meals', '["Same interactions as BCAAs"]'::jsonb),

    -- Pre-Workout Compounds
    ('Momentous Pre-Workout', 'performance', 'Comprehensive pre-workout with caffeine, citrulline, beta-alanine, and focus enhancers.', 4, '1 scoop (follow label)', '20-30 minutes pre-workout', '["Contains caffeine - see caffeine interactions", "May cause tingling from beta-alanine"]'::jsonb),
    ('Nitric Oxide Booster', 'performance', 'Combination of citrulline, beet root extract, and arginine for enhanced blood flow and pumps.', 3, 'Follow label directions', '30-45 minutes pre-workout', '["May enhance blood pressure medication effects", "Avoid with nitrate medications"]'::jsonb),
    ('Betaine Anhydrous (TMG)', 'performance', 'Trimethylglycine for power output, body composition, and homocysteine metabolism.', 4, '2.5g daily', 'Pre-workout or with meals', '["May enhance effects of medications affecting homocysteine"]'::jsonb),
    ('Alpha-GPC', 'performance', 'Choline compound that crosses blood-brain barrier. Supports focus, mind-muscle connection, and growth hormone.', 4, '300-600mg', 'Pre-workout or morning for cognitive benefits', '["May enhance cholinergic medications", "Use caution with anticholinergic drugs"]'::jsonb),
    ('Taurine', 'performance', 'Amino acid supporting hydration, electrolyte balance, and exercise capacity. May reduce muscle cramping.', 4, '1-3g daily', 'Pre-workout or post-workout', '["Generally safe", "May have mild effects on blood pressure"]'::jsonb),

-- ============================================================================
-- RECOVERY SUPPLEMENTS
-- ============================================================================

    -- Omega-3 Products
    ('Momentous Omega-3', 'recovery', 'High-potency fish oil with optimal EPA:DHA ratio. Supports inflammation management, brain health, and cardiovascular function.', 5, '2-4g combined EPA/DHA daily', 'With meals containing fat for absorption', '["May enhance blood thinning medications", "Discontinue 2 weeks before surgery", "May interact with blood pressure medications"]'::jsonb),
    ('Momentous Omega-3 Elite', 'recovery', 'Ultra-concentrated omega-3 with 1500mg EPA + 1000mg DHA per serving. Premium triglyceride form.', 5, '1 serving daily', 'With largest meal of the day', '["Same interactions as standard fish oil", "Higher potency requires more caution with blood thinners"]'::jsonb),
    ('Krill Oil', 'recovery', 'Phospholipid-bound omega-3s with astaxanthin. May have superior absorption compared to fish oil.', 4, '1-2g daily', 'With meals', '["Same interactions as fish oil", "Shellfish allergy contraindication"]'::jsonb),
    ('Algae-Based Omega-3', 'recovery', 'Vegan DHA/EPA source from microalgae. Sustainable alternative to fish oil.', 4, '500-1000mg DHA daily', 'With meals', '["Same interactions as fish oil"]'::jsonb),

    -- Curcumin Products
    ('Momentous Curcumin', 'recovery', 'Highly bioavailable curcumin extract with enhanced absorption technology. Powerful anti-inflammatory and antioxidant.', 5, '500-1000mg curcumin (enhanced absorption formula)', 'With meals, especially those containing fat and black pepper', '["May interact with blood thinners", "May affect iron absorption", "Gallbladder issues - use caution", "May interact with diabetes medications"]'::jsonb),
    ('Turmeric + Black Pepper', 'recovery', 'Turmeric extract with piperine for enhanced curcumin absorption (up to 2000% improvement).', 4, '500mg turmeric extract + 5mg piperine', 'With meals', '["Black pepper may increase absorption of many drugs", "Same curcumin interactions apply"]'::jsonb),

    -- Tart Cherry Products
    ('Momentous Tart Cherry Extract', 'recovery', 'Concentrated Montmorency tart cherry for muscle recovery, sleep quality, and reducing exercise-induced inflammation.', 4, '480mg anthocyanins or equivalent', 'Post-workout and before bed', '["Generally very safe", "May have mild effects similar to NSAIDs"]'::jsonb),
    ('Tart Cherry Juice Concentrate', 'recovery', 'Liquid form providing natural melatonin and anthocyanins for recovery and sleep.', 4, '30ml concentrate or 240ml juice', 'Before bed or post-workout', '["Contains natural sugars", "May enhance sleep medication effects"]'::jsonb),

    -- Collagen Products
    ('Momentous Collagen Peptides', 'recovery', 'Hydrolyzed collagen peptides for joint, tendon, and ligament health. Supports connective tissue repair.', 4, '10-20g daily', 'With vitamin C for enhanced synthesis. Morning or post-workout.', '["Generally very safe", "Derived from animal sources"]'::jsonb),
    ('Collagen Type II', 'recovery', 'Undenatured type II collagen for joint health through immune modulation.', 4, '40mg UC-II daily', 'On empty stomach, away from other proteins', '["Different mechanism than hydrolyzed collagen", "May take 8-12 weeks for benefits"]'::jsonb),
    ('Marine Collagen', 'recovery', 'Fish-derived collagen peptides, primarily Type I. May have superior absorption.', 4, '10g daily', 'With vitamin C', '["Fish allergy contraindication", "Generally very safe"]'::jsonb),

    -- Glutamine Products
    ('Momentous L-Glutamine', 'recovery', 'Most abundant amino acid in the body. Supports gut health, immune function, and muscle recovery during intense training.', 4, '5-10g daily', 'Post-workout or before bed', '["Generally very safe", "May affect some seizure medications", "Use caution with liver disease"]'::jsonb),
    ('Glutamine Peptides', 'recovery', 'Peptide-bonded glutamine for enhanced stability and absorption.', 3, '5-10g daily', 'Post-workout', '["Same interactions as L-glutamine"]'::jsonb),

    -- Additional Recovery
    ('Bromelain', 'recovery', 'Pineapple enzyme with anti-inflammatory and digestive properties. Supports recovery from muscle damage.', 3, '500-2000 GDU daily', 'Between meals for anti-inflammatory effects, with meals for digestion', '["May enhance blood thinners", "May increase absorption of antibiotics"]'::jsonb),
    ('Serrapeptase', 'recovery', 'Proteolytic enzyme for inflammation and tissue repair support.', 3, '120,000 SPU daily', 'On empty stomach', '["May enhance blood thinners", "Discontinue before surgery"]'::jsonb),
    ('MSM (Methylsulfonylmethane)', 'recovery', 'Organic sulfur compound supporting joint health, recovery, and reducing oxidative stress.', 3, '1-3g daily', 'With meals', '["Generally very safe", "May enhance blood thinners slightly"]'::jsonb),
    ('Glucosamine Sulfate', 'recovery', 'Building block for cartilage. May slow joint degeneration and reduce pain.', 3, '1500mg daily', 'With meals, can be split into doses', '["Shellfish-derived versions may cause allergies", "May affect blood sugar", "May enhance warfarin"]'::jsonb),
    ('Chondroitin Sulfate', 'recovery', 'Often combined with glucosamine for joint support. Component of cartilage.', 3, '800-1200mg daily', 'With meals', '["May enhance blood thinners", "Often combined with glucosamine"]'::jsonb),

-- ============================================================================
-- SLEEP SUPPLEMENTS
-- ============================================================================

    -- Magnesium Products
    ('Momentous Magnesium Threonate', 'sleep', 'Magtein - the only magnesium form shown to cross the blood-brain barrier. Supports cognitive function and sleep quality.', 5, '144mg elemental magnesium (as 2g Magtein)', '30-60 minutes before bed', '["May enhance effects of blood pressure medications", "Space 2 hours from antibiotics", "May interact with bisphosphonates"]'::jsonb),
    ('Magnesium Glycinate', 'sleep', 'Highly absorbable, gentle magnesium form. Glycine component adds calming benefits.', 5, '300-400mg elemental magnesium', 'Before bed', '["Same general magnesium interactions", "Glycine may enhance some sleep medications"]'::jsonb),
    ('Magnesium Citrate', 'sleep', 'Well-absorbed magnesium form. May have mild laxative effect at higher doses.', 4, '200-400mg elemental magnesium', 'Before bed or with meals', '["Laxative effect possible", "Same magnesium interactions"]'::jsonb),
    ('Magnesium Malate', 'sleep', 'Magnesium bound to malic acid. May be beneficial for energy production and muscle pain.', 4, '300-400mg elemental magnesium', 'Morning or before bed', '["Same general magnesium interactions"]'::jsonb),
    ('Magnesium Taurate', 'sleep', 'Combination supporting cardiovascular health and calming effects.', 4, '300-400mg elemental magnesium', 'Before bed', '["Same general magnesium interactions", "Taurine adds cardiovascular support"]'::jsonb),

    -- Glycine Products
    ('Glycine', 'sleep', 'Amino acid that lowers core body temperature and acts as inhibitory neurotransmitter. Improves sleep quality without next-day grogginess.', 4, '3g before bed', '30-60 minutes before sleep', '["May enhance effects of antipsychotic medications", "Generally very safe"]'::jsonb),

    -- Apigenin Products
    ('Apigenin', 'sleep', 'Flavonoid found in chamomile with calming properties. Dr. Huberman sleep stack component.', 4, '50mg before bed', '30-60 minutes before sleep', '["May enhance sedative medications", "May interact with birth control pills"]'::jsonb),

    -- L-Theanine Products
    ('Momentous L-Theanine', 'sleep', 'Amino acid from tea that promotes relaxation without sedation. Increases alpha brain waves.', 5, '100-400mg', 'Before bed or during day for calm focus', '["May enhance blood pressure medications", "Very safe profile"]'::jsonb),

    -- Melatonin Products
    ('Momentous Melatonin', 'sleep', 'Sleep hormone for circadian rhythm regulation. Use lowest effective dose.', 4, '0.3-1mg (low dose recommended)', '30-60 minutes before desired sleep time', '["May interact with immunosuppressants", "May enhance sedatives", "May affect blood pressure medications", "Use caution with autoimmune conditions"]'::jsonb),
    ('Time-Release Melatonin', 'sleep', 'Extended-release formula for those who wake during the night.', 3, '0.5-2mg', '30-60 minutes before bed', '["Same interactions as regular melatonin"]'::jsonb),

    -- GABA Products
    ('GABA (Gamma-Aminobutyric Acid)', 'sleep', 'Primary inhibitory neurotransmitter. Promotes relaxation and may improve sleep quality.', 3, '250-750mg', 'Before bed', '["May enhance effects of anti-anxiety medications", "May interact with blood pressure medications"]'::jsonb),
    ('Pharma GABA', 'sleep', 'Naturally-produced GABA through fermentation. May cross blood-brain barrier better than synthetic.', 3, '100-200mg', 'Before bed or during stress', '["Same interactions as GABA"]'::jsonb),

    -- Additional Sleep Support
    ('Valerian Root Extract', 'sleep', 'Traditional herbal sleep aid. May increase GABA levels.', 3, '300-600mg', '30-60 minutes before bed', '["May enhance sedative medications", "May affect liver enzyme function", "Avoid with alcohol"]'::jsonb),
    ('Passionflower Extract', 'sleep', 'Herbal extract with calming properties. Often combined with other sleep herbs.', 3, '250-500mg', 'Before bed', '["May enhance sedatives", "Generally safe"]'::jsonb),
    ('Lemon Balm Extract', 'sleep', 'Calming herb from the mint family. Supports relaxation and sleep.', 3, '300-600mg', 'Before bed or during day for calm', '["May affect thyroid medications", "May enhance sedatives"]'::jsonb),
    ('Magnolia Bark Extract', 'sleep', 'Contains honokiol and magnolol for anxiety reduction and sleep support.', 3, '200-400mg', 'Before bed', '["May enhance sedatives", "May have hormonal effects"]'::jsonb),
    ('Phosphatidylserine', 'sleep', 'Phospholipid that may reduce cortisol levels, particularly when elevated from stress or overtraining.', 4, '100-300mg', 'Before bed or post-workout', '["May enhance blood thinners", "May interact with Alzheimer medications"]'::jsonb),

-- ============================================================================
-- HORMONE SUPPORT SUPPLEMENTS
-- ============================================================================

    -- Vitamin D Products
    ('Momentous Vitamin D3+K2', 'hormones', 'Synergistic combination of D3 for immune/hormone function and K2 for proper calcium utilization. Essential for testosterone and overall health.', 5, '5000 IU D3 + 100mcg K2 (MK-7) daily', 'With a meal containing fat', '["K2 may interact with blood thinners", "High doses of D may affect calcium levels", "Test blood levels periodically"]'::jsonb),
    ('Vitamin D3 5000 IU', 'hormones', 'High-potency vitamin D3 for those with deficiency or limited sun exposure.', 5, '5000 IU daily (adjust based on blood levels)', 'With meals containing fat', '["May affect calcium metabolism", "Test levels every 3-6 months"]'::jsonb),
    ('Vitamin D3 1000 IU', 'hormones', 'Maintenance dose vitamin D3 for those with adequate levels.', 4, '1000 IU daily', 'With meals', '["Lower dose, fewer interactions"]'::jsonb),

    -- Zinc Products
    ('Momentous Zinc', 'hormones', 'Essential mineral for testosterone production, immune function, and enzyme activity. Zinc picolinate for optimal absorption.', 5, '15-30mg elemental zinc', 'With meals to prevent nausea. Separate from calcium and iron.', '["May decrease copper absorption - consider copper supplement", "May affect antibiotic absorption", "Take 2 hours away from fluoroquinolones"]'::jsonb),
    ('Zinc Carnosine', 'hormones', 'Zinc form specifically beneficial for gut lining support alongside hormonal benefits.', 4, '75mg twice daily', 'Between meals', '["Same zinc interactions", "Specifically supports gut health"]'::jsonb),
    ('Zinc Picolinate', 'hormones', 'Highly bioavailable zinc form with picolinic acid.', 4, '15-30mg daily', 'With meals', '["Same zinc interactions"]'::jsonb),

    -- Ashwagandha Products
    ('Momentous Ashwagandha (KSM-66)', 'hormones', 'Full-spectrum ashwagandha root extract. Adaptogen supporting stress resilience, testosterone, and thyroid function.', 5, '300-600mg KSM-66 daily', 'Morning or evening (consistency matters)', '["May enhance effects of thyroid medications", "May increase testosterone", "May enhance sedatives", "Nightshade family - avoid if sensitive"]'::jsonb),
    ('Ashwagandha Sensoril', 'hormones', 'Root and leaf extract with higher withanolide content. May be more potent for stress reduction.', 4, '125-250mg daily', 'Morning or as needed for stress', '["Same interactions as KSM-66"]'::jsonb),

    -- Tongkat Ali Products
    ('Momentous Tongkat Ali', 'hormones', 'Malaysian ginseng (Eurycoma longifolia). Supports healthy testosterone levels and may improve body composition.', 4, '200-400mg standardized extract', 'Morning, cycling recommended (5 days on, 2 off)', '["May affect hormone levels", "Use caution with hormone-sensitive conditions", "May interact with diabetes medications"]'::jsonb),

    -- Fadogia Products
    ('Momentous Fadogia Agrestis', 'hormones', 'Nigerian herb traditionally used for vitality. May support LH and testosterone levels. Often stacked with Tongkat Ali.', 3, '300-600mg daily', 'Morning, cycle 8-12 weeks on, 2-4 weeks off', '["Limited long-term safety data", "May affect hormone levels", "Cycle on and off recommended"]'::jsonb),

    -- Additional Hormone Support
    ('Boron', 'hormones', 'Trace mineral that may increase free testosterone and support bone health.', 3, '6-10mg daily', 'With meals', '["Generally safe at recommended doses", "High doses may be toxic"]'::jsonb),
    ('DHEA', 'hormones', 'Precursor hormone that converts to testosterone and estrogen. Use under medical supervision.', 3, '25-50mg daily (start low)', 'Morning', '["May affect hormone levels significantly", "May interact with hormone therapies", "Banned in some sports", "Medical supervision recommended"]'::jsonb),
    ('DIM (Diindolylmethane)', 'hormones', 'Compound from cruciferous vegetables supporting healthy estrogen metabolism.', 3, '100-200mg daily', 'With meals', '["May affect estrogen metabolism", "Use caution with hormone-sensitive conditions"]'::jsonb),
    ('Fenugreek Extract', 'hormones', 'Traditional herb that may support testosterone and libido.', 3, '500-600mg standardized extract', 'With meals', '["May lower blood sugar", "May affect hormone levels", "May increase breast milk production"]'::jsonb),
    ('Maca Root', 'hormones', 'Peruvian adaptogen supporting energy, libido, and hormone balance.', 3, '1.5-3g daily', 'Morning with breakfast', '["May affect hormone levels", "Generally very safe", "Cruciferous vegetable - thyroid considerations"]'::jsonb),
    ('Shilajit', 'hormones', 'Himalayan mineral pitch containing fulvic acid. Traditional vitality tonic.', 3, '250-500mg purified extract', 'Morning', '["Ensure purified form to avoid heavy metals", "May affect iron absorption", "May enhance some medications"]'::jsonb),

-- ============================================================================
-- GENERAL HEALTH SUPPLEMENTS
-- ============================================================================

    -- Multivitamin Products
    ('Momentous Elite Multivitamin', 'general', 'Comprehensive multivitamin designed for athletes with methylated B-vitamins, chelated minerals, and no iron (for men).', 4, 'As directed on label', 'With meals, typically morning', '["May interact with blood thinners (vitamin K)", "Space from thyroid medications", "Iron-free version available for men"]'::jsonb),
    ('Multivitamin with Iron', 'general', 'Complete multivitamin for those with iron needs (premenopausal women, athletes with deficiency).', 4, 'As directed on label', 'With meals', '["Iron may cause GI upset", "Space from thyroid medications and calcium"]'::jsonb),
    ('Prenatal Multivitamin', 'general', 'Specialized formula with folate, iron, and nutrients for pregnancy and nursing.', 5, 'As directed on label', 'With meals', '["Essential during pregnancy", "Contains higher folate and iron"]'::jsonb),

    -- Probiotic Products
    ('Momentous Probiotic', 'general', 'Multi-strain probiotic for gut health, immune function, and nutrient absorption.', 4, '10-50 billion CFU daily', 'With or without food (strain dependent)', '["Generally safe", "May cause initial GI adjustment", "Use caution if immunocompromised"]'::jsonb),
    ('Saccharomyces Boulardii', 'general', 'Beneficial yeast probiotic supporting gut health, especially during antibiotic use.', 4, '250-500mg daily', 'Between meals', '["Safe with antibiotics", "Yeast-based - different from bacterial probiotics"]'::jsonb),
    ('Spore-Based Probiotic', 'general', 'Shelf-stable spore-forming bacteria with excellent survivability.', 4, 'As directed on label', 'With meals', '["Shelf-stable", "Survives stomach acid well"]'::jsonb),

    -- Vitamin C Products
    ('Momentous Vitamin C', 'general', 'High-potency vitamin C for immune support, collagen synthesis, and antioxidant protection.', 5, '500-2000mg daily', 'Divided doses throughout day for better absorption', '["High doses may cause GI upset", "May affect iron absorption", "May interact with some chemotherapy drugs"]'::jsonb),
    ('Liposomal Vitamin C', 'general', 'Phospholipid-encapsulated vitamin C for enhanced absorption and cellular delivery.', 4, '1000mg daily', 'With or without food', '["Better absorbed than regular vitamin C", "Same interactions apply"]'::jsonb),
    ('Vitamin C with Bioflavonoids', 'general', 'Vitamin C combined with citrus bioflavonoids for enhanced antioxidant effects.', 4, '500-1000mg daily', 'With meals', '["Bioflavonoids may enhance vitamin C benefits"]'::jsonb),

    -- B-Complex Products
    ('Momentous B-Complex', 'general', 'Complete B-vitamin complex with methylated forms (methylfolate, methylcobalamin) for optimal absorption.', 5, 'As directed on label', 'Morning with food (B vitamins can be energizing)', '["May cause bright yellow urine (riboflavin)", "Methylated forms better for MTHFR variants", "High B6 may cause nerve issues with chronic high doses"]'::jsonb),
    ('Vitamin B12 (Methylcobalamin)', 'general', 'Active form of B12 for energy, nerve function, and red blood cell production.', 5, '1000-5000mcg daily', 'Morning, sublingual for best absorption', '["Very safe", "Essential for vegans/vegetarians", "May be depleted by metformin"]'::jsonb),
    ('Folate (5-MTHF)', 'general', 'Active methylated folate, superior to folic acid especially for MTHFR variants.', 4, '400-800mcg daily', 'With meals', '["May mask B12 deficiency at high doses", "Preferred form for MTHFR variants"]'::jsonb),

    -- Additional General Supplements
    ('CoQ10 (Ubiquinol)', 'general', 'Reduced form of CoQ10 for cellular energy production and heart health. Essential if on statins.', 5, '100-300mg daily', 'With meals containing fat', '["May interact with blood thinners", "Essential supplement if taking statins", "May lower blood pressure"]'::jsonb),
    ('CoQ10 (Ubiquinone)', 'general', 'Oxidized form of CoQ10, more stable but requires conversion to ubiquinol.', 4, '100-200mg daily', 'With meals containing fat', '["Same interactions as ubiquinol", "Less bioavailable than ubiquinol over age 40"]'::jsonb),
    ('PQQ (Pyrroloquinoline Quinone)', 'general', 'Supports mitochondrial biogenesis and cognitive function. Often combined with CoQ10.', 3, '10-20mg daily', 'Morning with food', '["May enhance effects of other mitochondrial supplements", "Generally safe"]'::jsonb),
    ('NAC (N-Acetyl Cysteine)', 'general', 'Precursor to glutathione, the master antioxidant. Supports liver, lung, and immune health.', 4, '600-1800mg daily', 'On empty stomach or with meals', '["May interact with nitroglycerin", "May enhance blood thinners", "Charcoal smell is normal"]'::jsonb),
    ('Glutathione (Liposomal)', 'general', 'Direct supplementation of master antioxidant in highly absorbable form.', 3, '250-500mg daily', 'On empty stomach', '["Liposomal form necessary for absorption", "Very safe"]'::jsonb),
    ('Quercetin', 'general', 'Flavonoid with anti-inflammatory and antihistamine properties. May enhance zinc absorption.', 4, '500-1000mg daily', 'With meals', '["May interact with antibiotics", "May enhance other supplements absorption"]'::jsonb),
    ('Resveratrol', 'general', 'Polyphenol from grapes with potential longevity and cardiovascular benefits.', 3, '150-500mg daily', 'With meals', '["May enhance blood thinners", "May interact with medications metabolized by CYP enzymes"]'::jsonb),
    ('Alpha-Lipoic Acid', 'general', 'Universal antioxidant supporting blood sugar regulation and nerve health.', 4, '300-600mg daily', 'On empty stomach', '["May lower blood sugar", "May affect thyroid medications"]'::jsonb),
    ('Berberine', 'general', 'Plant alkaloid with powerful metabolic benefits comparable to metformin.', 4, '500mg 2-3 times daily', 'Before meals', '["Significant drug interactions", "May affect liver metabolism of many medications", "May lower blood sugar significantly"]'::jsonb),
    ('Acetyl-L-Carnitine', 'general', 'Acetylated form of carnitine supporting brain and nerve function alongside fat metabolism.', 4, '500-2000mg daily', 'Morning or pre-workout', '["May interact with thyroid medications", "May affect blood thinners"]'::jsonb),
    ('L-Carnitine', 'general', 'Amino acid derivative supporting fat metabolism and exercise performance.', 3, '2-3g daily', 'With carbs for better uptake, pre-workout', '["May cause fishy body odor at high doses", "Same interactions as ALCAR"]'::jsonb),

    -- Digestive Support
    ('Digestive Enzymes', 'general', 'Comprehensive enzyme blend for protein, fat, and carbohydrate digestion.', 4, '1-2 capsules with meals', 'At start of meals', '["Very safe", "May be contraindicated with certain GI conditions"]'::jsonb),
    ('Betaine HCL', 'general', 'Supports stomach acid production for protein digestion and mineral absorption.', 3, '650mg with protein meals', 'Middle of meals containing protein', '["Do not use with NSAID or if you have ulcers", "Discontinue if burning sensation"]'::jsonb),
    ('Ox Bile', 'general', 'Supports fat digestion especially for those without gallbladder.', 3, '125-500mg with fatty meals', 'With meals containing fat', '["Essential for those without gallbladder", "May cause loose stools initially"]'::jsonb),

    -- Fiber Products
    ('Psyllium Husk', 'general', 'Soluble fiber supporting digestive regularity and blood sugar control.', 4, '5-10g daily', 'With plenty of water, away from medications', '["Must take with adequate water", "Space 2 hours from medications"]'::jsonb),
    ('Acacia Fiber', 'general', 'Prebiotic fiber feeding beneficial gut bacteria. Gentle and well-tolerated.', 4, '5-15g daily', 'Mixed in beverages or food', '["Very gentle", "Prebiotic benefits"]'::jsonb),

-- ============================================================================
-- SPECIALTY/NOOTROPIC SUPPLEMENTS
-- ============================================================================

    ('Momentous Brain Drive', 'cognitive', 'Comprehensive nootropic stack for focus, memory, and cognitive performance.', 4, 'As directed on label', 'Morning or before mentally demanding tasks', '["Contains multiple active ingredients - check each for interactions", "May contain caffeine"]'::jsonb),
    ('Lions Mane Mushroom', 'cognitive', 'Medicinal mushroom supporting nerve growth factor (NGF) production and cognitive function.', 4, '500-3000mg daily', 'Morning or divided doses', '["May enhance immune function", "Generally very safe", "May have anticoagulant effects"]'::jsonb),
    ('Bacopa Monnieri', 'cognitive', 'Ayurvedic herb supporting memory and learning. Benefits increase over time.', 4, '300-450mg standardized extract', 'With meals, fat improves absorption', '["May take 8-12 weeks for full effects", "May have mild sedative effect", "May affect thyroid"]'::jsonb),
    ('Rhodiola Rosea', 'cognitive', 'Adaptogen supporting mental performance, fatigue reduction, and stress resilience.', 4, '200-600mg standardized extract', 'Morning on empty stomach', '["May be stimulating for some", "May interact with antidepressants", "Cycling recommended"]'::jsonb),
    ('Ginkgo Biloba', 'cognitive', 'Traditional herb supporting circulation and cognitive function.', 3, '120-240mg standardized extract', 'Morning with food', '["May enhance blood thinners", "Discontinue before surgery"]'::jsonb),
    ('Huperzine A', 'cognitive', 'Acetylcholinesterase inhibitor supporting memory and learning.', 3, '50-200mcg daily', 'Cycling recommended (2 weeks on, 1 week off)', '["Potent - cycling necessary", "May interact with cholinergic medications"]'::jsonb),
    ('CDP-Choline (Citicoline)', 'cognitive', 'Choline source and nootropic supporting brain energy and neuroprotection.', 4, '250-500mg daily', 'Morning or divided doses', '["May enhance effects of cholinergic drugs", "Very safe"]'::jsonb),
    ('Uridine Monophosphate', 'cognitive', 'Nucleotide supporting synapse formation and cognitive enhancement.', 3, '250mg daily', 'Morning, often stacked with choline and fish oil', '["Part of Mr. Happy Stack for mood", "Generally safe"]'::jsonb),

    -- Electrolytes
    ('Momentous Electrolyte Mix', 'general', 'Comprehensive electrolyte blend with sodium, potassium, magnesium for hydration and performance.', 4, '1-2 servings during/after exercise', 'During exercise or throughout day', '["Adjust sodium based on sweat rate", "May affect blood pressure medications"]'::jsonb),
    ('Sodium Bicarbonate', 'performance', 'Alkalinizing agent that may improve high-intensity exercise performance by buffering acid.', 4, '0.3g/kg body weight', '60-90 minutes pre-exercise', '["May cause GI distress", "May affect blood pH", "Use caution with kidney issues"]'::jsonb),
    ('Potassium Citrate', 'general', 'Bioavailable potassium for electrolyte balance and alkalinizing benefits.', 4, '99-600mg daily', 'With meals, divided doses', '["May interact with potassium-sparing diuretics", "Monitor if on ACE inhibitors"]'::jsonb),

    -- Additional Specialty
    ('Astragalus Root', 'general', 'Traditional Chinese herb supporting immune function and stress adaptation.', 3, '250-500mg extract daily', 'Morning with food', '["May affect immune system medications", "Avoid with autoimmune conditions"]'::jsonb),
    ('Reishi Mushroom', 'general', 'Medicinal mushroom supporting immune modulation, sleep, and stress adaptation.', 4, '1-3g daily', 'Evening or divided doses', '["May enhance immune function", "May enhance blood thinners", "May lower blood pressure"]'::jsonb),
    ('Cordyceps Mushroom', 'performance', 'Medicinal mushroom supporting endurance, oxygen utilization, and energy.', 4, '1-3g daily', 'Morning or pre-workout', '["May enhance immune function", "May have mild blood thinning effects"]'::jsonb),
    ('Turkey Tail Mushroom', 'general', 'Immune-supporting mushroom with significant research for gut health.', 4, '1-3g daily', 'With meals', '["Strong immune modulation", "May interact with immunosuppressants"]'::jsonb),
    ('Black Seed Oil (Nigella Sativa)', 'general', 'Traditional remedy with broad health benefits including immune and metabolic support.', 4, '1-3 teaspoons or 500mg capsules', 'With meals', '["May affect blood sugar", "May enhance blood thinners", "May affect blood pressure"]'::jsonb),
    ('Spirulina', 'general', 'Nutrient-dense blue-green algae with complete protein and antioxidants.', 4, '3-10g daily', 'With meals', '["May interact with immunosuppressants", "Source quality important"]'::jsonb),
    ('Chlorella', 'general', 'Green algae supporting detoxification and nutrient density.', 4, '3-10g daily', 'With meals', '["May affect warfarin", "High vitamin K content"]'::jsonb),
    ('Bee Pollen', 'general', 'Nutrient-dense superfood with proteins, vitamins, and enzymes.', 3, '1-2 teaspoons daily', 'Morning with food', '["Bee/pollen allergies contraindicated", "Start with small amounts"]'::jsonb),
    ('Royal Jelly', 'general', 'Bee secretion supporting energy and vitality.', 3, '500-3000mg daily', 'Morning', '["Bee allergies contraindicated", "May affect blood pressure"]'::jsonb)

ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- ADDITIONAL ATHLETE-SPECIFIC BIOMARKER REFERENCE RANGES
-- ============================================================================

INSERT INTO biomarker_reference_ranges (biomarker_type, name, category, optimal_low, optimal_high, normal_low, normal_high, unit, description)
VALUES
    -- Omega-3 & Fatty Acids
    ('omega3_index', 'Omega-3 Index', 'fatty_acids', 8.0, 12.0, 4.0, 12.0, '%', 'Percentage of EPA+DHA in red blood cell membranes. Target >8% for optimal cardiovascular and brain health.'),
    ('aa_epa_ratio', 'AA:EPA Ratio', 'fatty_acids', 1.5, 3.0, 1.0, 15.0, 'ratio', 'Arachidonic acid to EPA ratio. Lower is better for inflammation control. Target <3:1.'),

    -- Apolipoprotein Panel
    ('apolipoprotein_a1', 'Apolipoprotein A1', 'lipids', 140, 180, 110, 205, 'mg/dL', 'Main protein component of HDL. Higher levels associated with reduced cardiovascular risk.'),
    ('lipoprotein_a', 'Lipoprotein(a)', 'lipids', 0, 30, 0, 75, 'nmol/L', 'Genetically determined cardiovascular risk marker. Elevated levels significantly increase CVD risk.'),
    ('apoB_apoA1_ratio', 'ApoB/ApoA1 Ratio', 'lipids', 0.3, 0.6, 0.3, 0.9, 'ratio', 'Ratio of atherogenic to protective lipoproteins. Strong predictor of cardiovascular risk.'),
    ('ldl_particle_number', 'LDL Particle Number', 'lipids', 700, 1000, 400, 1600, 'nmol/L', 'Number of LDL particles. More predictive of CVD risk than LDL-C in some populations.'),
    ('small_dense_ldl', 'Small Dense LDL', 'lipids', 0, 200, 0, 600, 'nmol/L', 'Pattern B LDL particles. Elevated levels indicate increased atherogenic risk.'),
    ('oxidized_ldl', 'Oxidized LDL', 'lipids', 0, 60, 0, 90, 'U/L', 'Marker of LDL oxidation and vascular inflammation.'),

    -- Hormone Ratios (Athletes)
    ('shbg', 'Sex Hormone Binding Globulin (SHBG)', 'hormones', 20, 50, 10, 80, 'nmol/L', 'Protein that binds testosterone. Low SHBG means more free testosterone available.'),
    ('free_t3_t4_ratio', 'Free T3/T4 Ratio', 'hormones', 0.28, 0.38, 0.20, 0.45, 'ratio', 'Indicator of thyroid hormone conversion efficiency. Low ratio may suggest conversion issues.'),
    ('cortisol_dhea_ratio', 'Cortisol:DHEA Ratio', 'hormones', 3.0, 6.0, 2.0, 10.0, 'ratio', 'Balance of catabolic to anabolic hormones. Elevated ratio indicates stress/overtraining.'),
    ('testosterone_cortisol_ratio', 'Testosterone:Cortisol Ratio', 'hormones', 0.5, 2.0, 0.3, 3.0, 'ratio', 'Anabolic-catabolic balance indicator. Higher is better for recovery and adaptation.'),
    ('estradiol_testosterone_ratio', 'Estradiol:Testosterone Ratio', 'hormones', 0.01, 0.04, 0.01, 0.08, 'ratio', 'Balance for optimal male hormone function. Elevated may indicate excess aromatization.'),
    ('pregnenolone', 'Pregnenolone', 'hormones', 50, 150, 10, 230, 'ng/dL', 'Master hormone precursor. Low levels may indicate HPA axis dysfunction.'),
    ('prolactin', 'Prolactin', 'hormones', 2.0, 12.0, 2.0, 18.0, 'ng/mL', 'Elevated levels can suppress testosterone and cause symptoms.'),

    -- Thyroid Extended
    ('reverse_t3', 'Reverse T3', 'hormones', 10, 20, 8, 25, 'ng/dL', 'Inactive thyroid hormone. Elevated in stress, illness, and caloric restriction.'),
    ('thyroglobulin_antibody', 'Thyroglobulin Antibody', 'hormones', 0, 1, 0, 4, 'IU/mL', 'Marker of thyroid autoimmunity.'),
    ('tpo_antibody', 'TPO Antibody', 'hormones', 0, 9, 0, 35, 'IU/mL', 'Thyroid peroxidase antibody. Elevated in Hashimoto''s thyroiditis.'),

    -- Athlete Performance Markers
    ('ck_creatine_kinase', 'Creatine Kinase (CK)', 'muscle', 50, 200, 30, 500, 'U/L', 'Muscle damage marker. Athletes may have higher baseline. Significantly elevated post-exercise.'),
    ('ldh', 'Lactate Dehydrogenase (LDH)', 'muscle', 100, 180, 85, 250, 'U/L', 'Enzyme released with tissue damage. May be elevated with intense training.'),
    ('myoglobin', 'Myoglobin', 'muscle', 10, 50, 0, 90, 'ng/mL', 'Muscle protein released during damage. Elevated after intense exercise.'),

    -- Inflammation Extended
    ('il6', 'Interleukin-6 (IL-6)', 'inflammation', 0, 2.0, 0, 5.0, 'pg/mL', 'Inflammatory cytokine. Acutely elevated post-exercise, chronically elevated indicates inflammation.'),
    ('tnf_alpha', 'TNF-Alpha', 'inflammation', 0, 3.0, 0, 8.0, 'pg/mL', 'Pro-inflammatory cytokine. Elevated in chronic inflammation and overtraining.'),
    ('cortisol_awakening_response', 'Cortisol Awakening Response', 'hormones', 38, 75, 25, 100, '%', 'Percent increase in cortisol 30-45 min after waking. Blunted response indicates HPA dysfunction.'),

    -- Iron Extended
    ('tibc', 'Total Iron Binding Capacity', 'iron', 250, 350, 250, 425, 'ug/dL', 'Indirect measure of transferrin. High TIBC may indicate iron deficiency.'),
    ('transferrin_saturation', 'Transferrin Saturation', 'iron', 25, 45, 15, 55, '%', 'Percentage of transferrin bound to iron. Low indicates deficiency, high may indicate overload.'),
    ('soluble_transferrin_receptor', 'Soluble Transferrin Receptor', 'iron', 2.0, 5.0, 1.8, 5.5, 'mg/L', 'Elevated in iron deficiency. Not affected by inflammation like ferritin.'),
    ('hepcidin', 'Hepcidin', 'iron', 10, 50, 5, 100, 'ng/mL', 'Iron-regulating hormone. Elevated post-exercise - affects iron absorption timing.'),
    ('reticulocyte_count', 'Reticulocyte Count', 'blood_count', 0.5, 1.5, 0.4, 2.0, '%', 'Immature red blood cells. Elevated indicates increased RBC production.'),

    -- Metabolic Extended
    ('adiponectin', 'Adiponectin', 'metabolic', 8, 15, 4, 20, 'ug/mL', 'Hormone from fat cells. Higher levels associated with insulin sensitivity and metabolic health.'),
    ('leptin', 'Leptin', 'metabolic', 2, 8, 1, 25, 'ng/mL', 'Satiety hormone. Low levels may indicate LEA (low energy availability) in athletes.'),
    ('fasting_c_peptide', 'Fasting C-Peptide', 'metabolic', 0.8, 2.0, 0.5, 3.0, 'ng/mL', 'Marker of insulin production. More stable than insulin measurement.'),
    ('homa_ir', 'HOMA-IR', 'metabolic', 0.5, 1.5, 0.5, 2.5, 'score', 'Homeostatic Model Assessment of Insulin Resistance. Lower is better.'),
    ('lp_pla2', 'Lp-PLA2', 'inflammation', 100, 200, 0, 300, 'ng/mL', 'Lipoprotein-associated phospholipase A2. Marker of vascular inflammation.'),

    -- Micronutrients
    ('rbc_magnesium', 'RBC Magnesium', 'micronutrients', 5.0, 6.5, 4.0, 7.0, 'mg/dL', 'Intracellular magnesium. More accurate than serum magnesium.'),
    ('zinc_plasma', 'Plasma Zinc', 'micronutrients', 80, 120, 60, 150, 'ug/dL', 'Zinc status marker. May be depleted by intense exercise and sweating.'),
    ('copper_serum', 'Serum Copper', 'micronutrients', 80, 120, 70, 150, 'ug/dL', 'Essential mineral. Should be balanced with zinc intake.'),
    ('selenium', 'Selenium', 'micronutrients', 120, 180, 70, 200, 'ug/L', 'Essential for thyroid function and antioxidant enzymes.'),
    ('iodine_urine', 'Urine Iodine', 'micronutrients', 100, 200, 100, 300, 'ug/L', 'Marker of iodine status. Essential for thyroid hormone production.'),
    ('coq10_plasma', 'Plasma CoQ10', 'micronutrients', 1.0, 3.0, 0.4, 4.0, 'ug/mL', 'Antioxidant and mitochondrial cofactor. Depleted by statins.'),

    -- Cardiovascular Extended
    ('nt_probnp', 'NT-proBNP', 'cardiovascular', 0, 50, 0, 125, 'pg/mL', 'Brain natriuretic peptide. Elevated in heart strain. Athletes may have slightly elevated baseline.'),
    ('mpo', 'Myeloperoxidase (MPO)', 'cardiovascular', 100, 300, 0, 600, 'pmol/L', 'Marker of oxidative stress and cardiovascular risk.'),
    ('sdma', 'SDMA', 'cardiovascular', 0.3, 0.5, 0.2, 0.7, 'umol/L', 'Symmetric dimethylarginine. Marker of kidney function and cardiovascular risk.'),
    ('adma', 'ADMA', 'cardiovascular', 0.4, 0.6, 0.3, 0.9, 'umol/L', 'Asymmetric dimethylarginine. Elevated levels impair nitric oxide production.'),

    -- Genetic/Specialized
    ('apoe_genotype', 'ApoE Genotype', 'genetic', NULL, NULL, NULL, NULL, 'genotype', 'Genetic marker affecting lipid metabolism and Alzheimer''s risk. E4 carriers have different optimal targets.'),
    ('mthfr_status', 'MTHFR Status', 'genetic', NULL, NULL, NULL, NULL, 'status', 'Methylation gene variant. Affects folate metabolism and homocysteine levels.'),

    -- Recovery Markers
    ('glutamine_plasma', 'Plasma Glutamine', 'amino_acids', 500, 700, 400, 900, 'umol/L', 'Most abundant amino acid. Low levels associated with overtraining and immune suppression.'),
    ('glutamate_glutamine_ratio', 'Glutamate:Glutamine Ratio', 'amino_acids', 0.08, 0.15, 0.05, 0.25, 'ratio', 'Elevated ratio may indicate overtraining or excessive catabolic state.')

ON CONFLICT (biomarker_type) DO NOTHING;

-- ============================================================================
-- ADDITIONAL RECOVERY PROTOCOLS
-- ============================================================================

INSERT INTO recovery_protocols (name, description, phases, recommended_frequency, is_public)
VALUES
    (
        'Wim Hof Breathing + Cold Protocol',
        'Combines Wim Hof''s powerful breathing technique with cold exposure for enhanced stress resilience, improved mental clarity, and optimized autonomic nervous system function. The breathing technique temporarily increases blood pH and reduces CO2, allowing extended cold tolerance.',
        '[
            {"order": 1, "type": "breathing", "duration_minutes": 15, "notes": "30-40 deep breaths: inhale fully (belly then chest), let go (don''t force exhale). Repeat 3-4 rounds. On last exhale of each round, hold breath as long as comfortable. Recovery breath: inhale fully, hold 15 seconds."},
            {"order": 2, "type": "rest", "duration_minutes": 2, "notes": "Short rest, normalize breathing before cold exposure."},
            {"order": 3, "type": "cold_plunge", "duration_minutes": 2, "temperature_f": 50, "notes": "Enter cold water after breathing practice. Controlled breathing is key. Focus on relaxation despite cold stimulus."},
            {"order": 4, "type": "rest", "duration_minutes": 5, "notes": "Allow natural rewarming. Notice the ''warm glow'' effect from brown fat activation."},
            {"order": 5, "type": "cold_shower", "duration_minutes": 1, "temperature_f": 55, "notes": "Optional finishing cold shower to extend benefits."}
        ]'::jsonb,
        '3-4 times per week, ideally morning',
        true
    ),
    (
        'Post-Game Recovery Protocol (Athletes)',
        'Comprehensive recovery protocol for athletes following competition or intense training. Combines immediate refueling, contrast therapy, and sleep optimization to accelerate recovery and reduce next-day soreness.',
        '[
            {"order": 1, "type": "nutrition", "duration_minutes": 30, "notes": "Within 30 minutes: 20-40g protein + 0.5-0.8g/kg carbs. Rehydrate with electrolytes - target 150% of fluid lost."},
            {"order": 2, "type": "cold_plunge", "duration_minutes": 10, "temperature_f": 54, "notes": "Full body cold water immersion at 50-59°F to reduce inflammation and muscle damage markers."},
            {"order": 3, "type": "rest", "duration_minutes": 5, "notes": "Dry off and begin rewarming naturally."},
            {"order": 4, "type": "compression", "duration_minutes": 20, "notes": "Pneumatic compression boots or compression garments on legs to enhance lymphatic drainage."},
            {"order": 5, "type": "mobility", "duration_minutes": 15, "notes": "Gentle stretching and foam rolling. Focus on hip flexors, quads, hamstrings, calves."},
            {"order": 6, "type": "sleep_prep", "duration_minutes": 30, "notes": "Cool dark room, magnesium glycinate 400mg, tart cherry juice 8oz for natural melatonin."}
        ]'::jsonb,
        'After every competition or high-intensity session',
        true
    ),
    (
        'Travel Recovery Protocol',
        'Protocol for recovering from long-haul travel and jet lag. Combines light exposure timing, movement, and supplements to rapidly reset circadian rhythm and reduce travel fatigue.',
        '[
            {"order": 1, "type": "light_exposure", "duration_minutes": 30, "notes": "Upon arrival: Bright light exposure (sunlight or 10,000 lux light box) at destination morning time. Avoid light in destination evening if traveling east."},
            {"order": 2, "type": "movement", "duration_minutes": 20, "notes": "Light exercise - walk, dynamic stretching, or easy swim. Movement helps reset circadian clock and reduce stiffness from travel."},
            {"order": 3, "type": "cold_shower", "duration_minutes": 2, "temperature_f": 60, "notes": "Cold shower to increase alertness if arriving in morning. Skip if arriving in evening."},
            {"order": 4, "type": "nutrition", "duration_minutes": 0, "notes": "Eat meals at destination meal times regardless of hunger. Protein at breakfast helps set circadian rhythm."},
            {"order": 5, "type": "hydration", "duration_minutes": 0, "notes": "Aggressive hydration - aim for 3-4L on travel day. Add electrolytes. Minimize alcohol and caffeine."},
            {"order": 6, "type": "supplements", "duration_minutes": 0, "notes": "Melatonin 0.5-1mg at destination bedtime for 3-5 days. Magnesium glycinate 400mg before bed."},
            {"order": 7, "type": "grounding", "duration_minutes": 15, "notes": "Walk barefoot on grass or beach if possible. Earthing may help reset circadian rhythm."}
        ]'::jsonb,
        'During and for 3-5 days after long-haul travel',
        true
    ),
    (
        'Sleep Optimization Protocol',
        'Comprehensive sleep hygiene protocol based on latest research for maximizing sleep quality and duration. Addresses temperature, light, timing, and environment for optimal recovery.',
        '[
            {"order": 1, "type": "light_management", "duration_minutes": 0, "notes": "Morning: 10+ minutes bright light within 30 min of waking. Evening: Dim lights 2-3 hours before bed, use blue light blocking glasses after sunset."},
            {"order": 2, "type": "temperature", "duration_minutes": 0, "notes": "Keep bedroom 65-68°F (18-20°C). Body temperature drop is crucial sleep signal. Consider cooling mattress pad."},
            {"order": 3, "type": "timing", "duration_minutes": 0, "notes": "Consistent sleep/wake times within 30-minute window, even weekends. Target 7-9 hours opportunity."},
            {"order": 4, "type": "nutrition_timing", "duration_minutes": 0, "notes": "Finish eating 2-3 hours before bed. Avoid alcohol within 3 hours (fragments sleep architecture)."},
            {"order": 5, "type": "caffeine_cutoff", "duration_minutes": 0, "notes": "No caffeine within 8-10 hours of bedtime. Half-life is 5-6 hours but varies by genetics."},
            {"order": 6, "type": "wind_down", "duration_minutes": 30, "notes": "30-60 minute wind-down routine: dim lights, relaxing activities, no screens or work stress."},
            {"order": 7, "type": "supplements", "duration_minutes": 0, "notes": "Consider (in order of evidence): Magnesium threonate/glycinate 300-400mg, Glycine 3g, L-theanine 200mg, Apigenin 50mg"},
            {"order": 8, "type": "environment", "duration_minutes": 0, "notes": "Pitch black room (blackout curtains, cover LEDs), white noise if needed, remove electronics from bedroom."}
        ]'::jsonb,
        'Daily - consistency is key for circadian health',
        true
    ),
    (
        'Active Recovery Day Protocol',
        'Structured protocol for rest days that promotes recovery without adding training stress. Combines low-intensity movement, mobility work, and recovery modalities for optimal adaptation.',
        '[
            {"order": 1, "type": "mobility", "duration_minutes": 20, "notes": "Morning mobility routine: hip circles, cat-cow, thoracic rotation, shoulder CARs, ankle mobility. Keep intensity low."},
            {"order": 2, "type": "low_intensity_cardio", "duration_minutes": 30, "notes": "Zone 1-2 cardio: easy walk, bike, or swim. Heart rate should allow comfortable conversation. Nasal breathing only."},
            {"order": 3, "type": "sauna_infrared", "duration_minutes": 20, "temperature_f": 140, "notes": "Infrared sauna for passive heat exposure. Increases blood flow and may enhance muscle protein synthesis."},
            {"order": 4, "type": "cold_shower", "duration_minutes": 2, "temperature_f": 60, "notes": "Brief cold exposure for dopamine boost. End on cold to maintain alertness."},
            {"order": 5, "type": "foam_rolling", "duration_minutes": 15, "notes": "Self-myofascial release focusing on tight areas. 2 minutes per muscle group, moderate pressure."},
            {"order": 6, "type": "stretching", "duration_minutes": 15, "notes": "Static stretching and/or yoga. Hold stretches 60-90 seconds for tissue adaptation."},
            {"order": 7, "type": "breathing", "duration_minutes": 10, "notes": "Box breathing (4-4-4-4) or physiological sigh practice for parasympathetic activation."}
        ]'::jsonb,
        '1-2 times per week between training days',
        true
    ),
    (
        'Pre-Competition Activation Protocol',
        'Protocol for competition day to optimize physical and mental readiness. Balances activation with preserving energy for performance.',
        '[
            {"order": 1, "type": "wake_routine", "duration_minutes": 10, "notes": "Wake 3-4 hours before competition. Bright light exposure immediately. Cold water on face to increase alertness."},
            {"order": 2, "type": "pre_meal", "duration_minutes": 30, "notes": "Familiar, easily digestible meal 3-4 hours out. Focus on carbs with moderate protein, low fat/fiber."},
            {"order": 3, "type": "activation", "duration_minutes": 15, "notes": "Light movement: dynamic warm-up, muscle activation exercises. Nothing fatiguing."},
            {"order": 4, "type": "visualization", "duration_minutes": 10, "notes": "Mental rehearsal of key moments. Visualize success in detail - movements, feelings, outcomes."},
            {"order": 5, "type": "breathing", "duration_minutes": 5, "notes": "Box breathing to manage arousal levels. Adjust ratio for desired activation level."},
            {"order": 6, "type": "warm_up", "duration_minutes": 20, "notes": "Sport-specific warm-up 20-30 min before. Progressive intensity, include sport-specific movements."},
            {"order": 7, "type": "final_prep", "duration_minutes": 5, "notes": "Final mental cue words, power poses, or pre-competition routine. Enter competition zone."}
        ]'::jsonb,
        'Competition days',
        true
    ),
    (
        'Overtraining Recovery Protocol',
        'Extended recovery protocol for athletes experiencing overtraining syndrome symptoms. Prioritizes rest, nutrition, and stress reduction to restore HPA axis function.',
        '[
            {"order": 1, "type": "training_reduction", "duration_minutes": 0, "notes": "Reduce training volume by 50-70% for 1-2 weeks. Focus on Zone 1-2 only. No high-intensity work."},
            {"order": 2, "type": "sleep_extension", "duration_minutes": 0, "notes": "Extend sleep opportunity to 9-10 hours. Add 20-30 min nap if possible. Sleep is the primary recovery tool."},
            {"order": 3, "type": "nutrition_focus", "duration_minutes": 0, "notes": "Increase calories by 500-1000 above maintenance. Ensure adequate carbs (4-6g/kg), protein (2g/kg), and micronutrients."},
            {"order": 4, "type": "stress_reduction", "duration_minutes": 30, "notes": "Daily: meditation, nature walks, or other relaxation practices. Reduce life stressors where possible."},
            {"order": 5, "type": "sauna_infrared", "duration_minutes": 20, "temperature_f": 140, "notes": "Gentle infrared sauna 2-3x/week. Avoid extreme cold exposure which adds stress."},
            {"order": 6, "type": "supplements", "duration_minutes": 0, "notes": "Consider: Ashwagandha for HPA support, Magnesium for recovery, Omega-3 for inflammation, Vitamin D if low."},
            {"order": 7, "type": "monitoring", "duration_minutes": 5, "notes": "Track HRV, resting heart rate, sleep quality, mood daily. Resume normal training when metrics normalize."}
        ]'::jsonb,
        '1-4 weeks depending on severity',
        true
    ),
    (
        'Morning Cold Exposure Protocol',
        'Short, effective morning cold exposure protocol for dopamine, alertness, and metabolic benefits. Designed to fit into a busy schedule.',
        '[
            {"order": 1, "type": "warm_shower", "duration_minutes": 3, "notes": "Optional: start with normal warm shower to wash. Some prefer cold only."},
            {"order": 2, "type": "cold_shower", "duration_minutes": 2, "temperature_f": 55, "notes": "Turn to coldest setting. Focus on breathing control. Let water hit face, back of neck, and chest."},
            {"order": 3, "type": "rest", "duration_minutes": 5, "notes": "Dry off and allow natural rewarming. Feel the dopamine and adrenaline effects kick in."}
        ]'::jsonb,
        'Daily, first thing in morning',
        true
    )
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- UPDATE FASTING PROTOCOLS WITH BENEFITS AND CONTRAINDICATIONS
-- ============================================================================

-- Update 16:8 Intermittent Fasting
UPDATE fasting_protocols
SET
    benefits = '["Improved insulin sensitivity", "Enhanced fat oxidation", "Increased growth hormone", "Cellular autophagy activation", "Reduced inflammation markers", "Easier caloric control", "Mental clarity after adaptation", "Sustainable long-term"]'::jsonb,
    contraindications = '["Pregnancy or breastfeeding", "History of eating disorders", "Type 1 diabetes (requires medical supervision)", "Underweight individuals", "Children and adolescents", "Those on medications requiring food"]'::jsonb,
    training_adjustments = 'Schedule intense training sessions within eating window when possible. For fasted training: keep sessions under 60 minutes, prioritize carbs in first meal post-workout. BCAA/EAA supplementation optional for fasted training.'
WHERE name = '16:8 Intermittent Fasting';

-- Update 18:6 Intermittent Fasting
UPDATE fasting_protocols
SET
    benefits = '["Greater autophagy than 16:8", "Enhanced fat adaptation", "Improved metabolic flexibility", "Increased ketone production", "May improve body composition", "Deeper focus during fasted state"]'::jsonb,
    contraindications = '["Same as 16:8 plus:", "Athletes with high training volume", "Those struggling to meet caloric needs", "Individuals with blood sugar regulation issues"]'::jsonb,
    training_adjustments = 'Not recommended for high-volume training phases. If training fasted, limit to low-intensity or short duration sessions. Break fast with easily digestible protein and carbs 30-60 minutes post-workout.'
WHERE name = '18:6 Intermittent Fasting';

-- Update 20:4 Warrior Diet
UPDATE fasting_protocols
SET
    benefits = '["Significant autophagy activation", "Strong fat adaptation", "Improved insulin sensitivity", "Mental clarity and focus", "May boost growth hormone", "Simplified meal planning"]'::jsonb,
    contraindications = '["Not suitable for athletes in heavy training", "Difficult to meet protein needs", "May cause muscle loss if protein insufficient", "Risk of undereating", "May disrupt sleep if eating too close to bed"]'::jsonb,
    training_adjustments = 'Generally not recommended during intense training phases. If used, train early in eating window. Prioritize protein intake (may be difficult to consume 150g+ in 4 hours). Consider modified approach with small protein-only intake during day.'
WHERE name = '20:4 Warrior Diet';

-- Update OMAD
UPDATE fasting_protocols
SET
    benefits = '["Maximum autophagy activation", "Extreme simplicity", "Strong metabolic adaptation", "Potential longevity benefits", "Significant growth hormone boost", "Deep ketosis achieved daily"]'::jsonb,
    contraindications = '["Not suitable for most athletes", "Very difficult to meet nutritional needs", "High risk of muscle loss", "May cause GI distress from large meal", "Social challenges", "Risk of developing disordered eating patterns"]'::jsonb,
    training_adjustments = 'Not recommended for athletes or anyone with significant physical demands. If attempted: train immediately before meal, consume high-quality protein first, use digestive enzymes. Consider this protocol only for rest days or deload periods.'
WHERE name = 'OMAD (One Meal a Day)';

-- Update 5:2 Diet
UPDATE fasting_protocols
SET
    benefits = '["Flexible approach", "Significant weekly caloric reduction", "Improved insulin sensitivity", "Autophagy on fast days", "Easier social compliance", "Sustainable for many people"]'::jsonb,
    contraindications = '["May affect athletic performance on fast days", "Risk of overeating on non-fast days", "Not suitable during heavy training blocks", "Blood sugar management issues"]'::jsonb,
    training_adjustments = 'Schedule low-calorie days on rest or light training days only. Never combine with intense training. On fast days, prioritize protein in limited calories. Consider modified 600-800 calories rather than 500 for active individuals.'
WHERE name = '5:2 Diet';

-- Update 24-Hour Fast
UPDATE fasting_protocols
SET
    benefits = '["Significant autophagy activation", "Metabolic reset", "Improved insulin sensitivity", "Growth hormone increase", "Mental clarity", "Digestive system rest"]'::jsonb,
    contraindications = '["Not for diabetics without supervision", "May cause significant energy drop", "Hypoglycemia risk", "Not during competition phases", "Medication timing disruption"]'::jsonb,
    training_adjustments = 'Schedule on rest days only. Light walking or mobility work acceptable. No intense training during fast or within 12 hours of breaking fast. Break fast with easily digestible foods - avoid large fatty meals.'
WHERE name = '24-Hour Fast';

-- Update 36-Hour Fast
UPDATE fasting_protocols
SET
    benefits = '["Deep autophagy", "Significant fat oxidation", "Ketone body production", "Immune system reset", "Enhanced metabolic flexibility", "May improve certain biomarkers"]'::jsonb,
    contraindications = '["Not for regular use", "Requires prior fasting experience", "Avoid during training phases", "May cause significant muscle loss if done frequently", "Not suitable for underweight individuals", "Medical supervision recommended"]'::jsonb,
    training_adjustments = 'No training during fast. Rest day before, during, and ideally after. Resume training only after adequate refeeding (24-48 hours). Consider electrolyte supplementation during fast. Not recommended more than monthly.'
WHERE name = '36-Hour Fast';

-- Update 48-Hour Fast
UPDATE fasting_protocols
SET
    benefits = '["Profound autophagy", "Significant metabolic reset", "Potential stem cell regeneration", "Deep ketosis", "May reset immune system", "Spiritual/mental benefits reported"]'::jsonb,
    contraindications = '["Requires significant fasting experience", "Medical supervision strongly recommended", "Not during any training phases", "Risk of refeeding syndrome if broken incorrectly", "May cause electrolyte imbalances", "Not for athletes in-season"]'::jsonb,
    training_adjustments = 'Complete rest during fast. No training for 2-3 days after refeeding. Break fast very carefully with bone broth, then add light proteins. Avoid carbs and large meals when breaking. Electrolyte supplementation essential. Consider only during off-season.'
WHERE name = '48-Hour Fast';

-- Update 72-Hour Fast
UPDATE fasting_protocols
SET
    benefits = '["Maximum autophagy activation", "Significant immune system reset", "Potential cancer cell vulnerability", "Stem cell regeneration", "Deep metabolic reset", "May help reset chronic inflammation"]'::jsonb,
    contraindications = '["Medical supervision required", "Serious refeeding syndrome risk", "Not for diabetics", "Not during any athletic activities", "Significant electrolyte management needed", "May cause muscle loss", "Heart arrhythmia risk without proper electrolytes", "Only for experienced fasters"]'::jsonb,
    training_adjustments = 'Absolutely no training during fast or for 3-5 days after. This is a medical intervention, not a fitness strategy. Proper refeeding protocol essential: Day 1 post-fast: bone broth only. Day 2: add soft proteins. Day 3: gradually increase complexity. Resume light training only after full refeeding. Consider only annually in off-season under medical guidance.'
WHERE name = '72-Hour Fast';

COMMIT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_supplement_count integer;
    v_biomarker_count integer;
    v_recovery_protocol_count integer;
    v_fasting_protocol_count integer;
BEGIN
    SELECT COUNT(*) INTO v_supplement_count FROM supplements;
    SELECT COUNT(*) INTO v_biomarker_count FROM biomarker_reference_ranges;
    SELECT COUNT(*) INTO v_recovery_protocol_count FROM recovery_protocols;
    SELECT COUNT(*) INTO v_fasting_protocol_count FROM fasting_protocols;

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'HEALTH INTELLIGENCE SEED DATA MIGRATION COMPLETE';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Seed Data Summary:';
    RAISE NOTICE '  - Supplements catalog: % items', v_supplement_count;
    RAISE NOTICE '  - Biomarker reference ranges: % entries', v_biomarker_count;
    RAISE NOTICE '  - Recovery protocols: % protocols', v_recovery_protocol_count;
    RAISE NOTICE '  - Fasting protocols: % protocols (with benefits/contraindications)', v_fasting_protocol_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Supplement Categories:';
    RAISE NOTICE '  - Performance (Creatine, Beta-Alanine, Caffeine, Citrulline, BCAAs, etc.)';
    RAISE NOTICE '  - Recovery (Omega-3, Curcumin, Tart Cherry, Collagen, Glutamine, etc.)';
    RAISE NOTICE '  - Sleep (Magnesium varieties, Glycine, Apigenin, L-Theanine, Melatonin, etc.)';
    RAISE NOTICE '  - Hormones (D3+K2, Zinc, Ashwagandha, Tongkat Ali, Fadogia, etc.)';
    RAISE NOTICE '  - General (Multivitamins, Probiotics, Vitamin C, B-Complex, etc.)';
    RAISE NOTICE '  - Cognitive (Lions Mane, Bacopa, Rhodiola, Alpha-GPC, etc.)';
    RAISE NOTICE '';
    RAISE NOTICE 'New Biomarker Categories:';
    RAISE NOTICE '  - Omega-3 Index and fatty acid ratios';
    RAISE NOTICE '  - Apolipoprotein panel (ApoA1, Lp(a), LDL-P)';
    RAISE NOTICE '  - Hormone ratios (SHBG, Free T3/T4, Cortisol:DHEA, T:C ratio)';
    RAISE NOTICE '  - Athlete performance markers (CK, LDH, Myoglobin)';
    RAISE NOTICE '  - Extended inflammation markers (IL-6, TNF-alpha)';
    RAISE NOTICE '  - Iron panel (TIBC, Transferrin Sat, sTfR, Hepcidin)';
    RAISE NOTICE '  - Metabolic markers (Adiponectin, Leptin, HOMA-IR)';
    RAISE NOTICE '';
    RAISE NOTICE 'New Recovery Protocols:';
    RAISE NOTICE '  - Wim Hof Breathing + Cold Protocol';
    RAISE NOTICE '  - Post-Game Recovery Protocol (Athletes)';
    RAISE NOTICE '  - Travel Recovery Protocol';
    RAISE NOTICE '  - Sleep Optimization Protocol';
    RAISE NOTICE '  - Active Recovery Day Protocol';
    RAISE NOTICE '  - Pre-Competition Activation Protocol';
    RAISE NOTICE '  - Overtraining Recovery Protocol';
    RAISE NOTICE '  - Morning Cold Exposure Protocol';
    RAISE NOTICE '';
    RAISE NOTICE 'Fasting Protocol Enhancements:';
    RAISE NOTICE '  - Added benefits JSONB array to all protocols';
    RAISE NOTICE '  - Added contraindications JSONB array to all protocols';
    RAISE NOTICE '  - Added training_adjustments text to all protocols';
    RAISE NOTICE '';
    RAISE NOTICE 'All inserts use ON CONFLICT DO NOTHING for idempotency.';
    RAISE NOTICE '============================================================================';
END $$;
