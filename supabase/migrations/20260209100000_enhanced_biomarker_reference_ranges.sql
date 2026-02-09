-- ============================================================================
-- ENHANCED BIOMARKER REFERENCE RANGES MIGRATION
-- ============================================================================
-- Adds sex-specific, age-specific, and athlete-specific reference ranges
-- Creates biomarker_supplement_effects table
-- Adds educational content for biomarkers
--
-- Date: 2026-02-09
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. ADD NEW COLUMNS TO biomarker_reference_ranges TABLE
-- ============================================================================

-- Add sex column (NULL = applies to both sexes)
ALTER TABLE biomarker_reference_ranges
    ADD COLUMN IF NOT EXISTS sex TEXT CHECK (sex IN ('male', 'female') OR sex IS NULL);

COMMENT ON COLUMN biomarker_reference_ranges.sex IS 'Sex-specific ranges: NULL = both sexes, male, female';

-- Add age range columns (NULL = no age restriction)
ALTER TABLE biomarker_reference_ranges
    ADD COLUMN IF NOT EXISTS age_min INTEGER CHECK (age_min IS NULL OR age_min >= 0),
    ADD COLUMN IF NOT EXISTS age_max INTEGER CHECK (age_max IS NULL OR age_max >= 0);

COMMENT ON COLUMN biomarker_reference_ranges.age_min IS 'Minimum age for this range (NULL = no minimum)';
COMMENT ON COLUMN biomarker_reference_ranges.age_max IS 'Maximum age for this range (NULL = no maximum)';

-- Add athlete type column (NULL = all types)
ALTER TABLE biomarker_reference_ranges
    ADD COLUMN IF NOT EXISTS athlete_type TEXT CHECK (
        athlete_type IN ('endurance', 'strength', 'power', 'general') OR athlete_type IS NULL
    );

COMMENT ON COLUMN biomarker_reference_ranges.athlete_type IS 'Athlete type specific ranges: NULL = all, endurance, strength, power, general';

-- Add detailed description column
ALTER TABLE biomarker_reference_ranges
    ADD COLUMN IF NOT EXISTS description_detailed TEXT;

COMMENT ON COLUMN biomarker_reference_ranges.description_detailed IS 'Extended educational description with clinical context';

-- Add clinical significance column
ALTER TABLE biomarker_reference_ranges
    ADD COLUMN IF NOT EXISTS clinical_significance TEXT;

COMMENT ON COLUMN biomarker_reference_ranges.clinical_significance IS 'What it means when this biomarker is out of range';

-- Add dietary sources column (array of foods)
ALTER TABLE biomarker_reference_ranges
    ADD COLUMN IF NOT EXISTS dietary_sources TEXT[];

COMMENT ON COLUMN biomarker_reference_ranges.dietary_sources IS 'Foods that can affect this biomarker';

-- Add lifestyle factors column (array of factors)
ALTER TABLE biomarker_reference_ranges
    ADD COLUMN IF NOT EXISTS lifestyle_factors TEXT[];

COMMENT ON COLUMN biomarker_reference_ranges.lifestyle_factors IS 'Lifestyle factors that affect this biomarker';

-- Create index for efficient queries on new columns
CREATE INDEX IF NOT EXISTS idx_biomarker_reference_ranges_sex
    ON biomarker_reference_ranges(sex) WHERE sex IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_biomarker_reference_ranges_age
    ON biomarker_reference_ranges(age_min, age_max) WHERE age_min IS NOT NULL OR age_max IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_biomarker_reference_ranges_athlete_type
    ON biomarker_reference_ranges(athlete_type) WHERE athlete_type IS NOT NULL;

-- Drop the unique constraint on biomarker_type to allow sex/age/athlete specific ranges
-- We need to check if the constraint exists first
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'biomarker_reference_ranges_biomarker_type_key'
        AND conrelid = 'biomarker_reference_ranges'::regclass
    ) THEN
        ALTER TABLE biomarker_reference_ranges DROP CONSTRAINT biomarker_reference_ranges_biomarker_type_key;
    END IF;
END $$;

-- Add a unique constraint on (biomarker_type, sex, age_min, age_max, athlete_type) for idempotency
-- Using a unique index with COALESCE to handle NULLs
CREATE UNIQUE INDEX IF NOT EXISTS idx_biomarker_reference_ranges_unique
    ON biomarker_reference_ranges(
        biomarker_type,
        COALESCE(sex, ''),
        COALESCE(age_min, -1),
        COALESCE(age_max, -1),
        COALESCE(athlete_type, '')
    );


-- ============================================================================
-- 2. CREATE biomarker_supplement_effects TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS biomarker_supplement_effects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    biomarker_name TEXT NOT NULL,
    supplement_name TEXT NOT NULL,
    effect_direction TEXT NOT NULL CHECK (effect_direction IN ('increase', 'decrease', 'modulate')),
    effect_strength TEXT NOT NULL CHECK (effect_strength IN ('strong', 'moderate', 'mild')),
    mechanism TEXT,
    evidence_level TEXT NOT NULL CHECK (evidence_level IN ('strong', 'moderate', 'emerging')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE biomarker_supplement_effects IS 'Relationship between supplements and their effects on biomarkers';
COMMENT ON COLUMN biomarker_supplement_effects.biomarker_name IS 'Name of the affected biomarker (matches biomarker_reference_ranges.name)';
COMMENT ON COLUMN biomarker_supplement_effects.supplement_name IS 'Name of the supplement';
COMMENT ON COLUMN biomarker_supplement_effects.effect_direction IS 'Direction of effect: increase, decrease, or modulate';
COMMENT ON COLUMN biomarker_supplement_effects.effect_strength IS 'Strength of the effect: strong, moderate, or mild';
COMMENT ON COLUMN biomarker_supplement_effects.mechanism IS 'How the supplement affects the biomarker';
COMMENT ON COLUMN biomarker_supplement_effects.evidence_level IS 'Quality of evidence: strong, moderate, or emerging';
COMMENT ON COLUMN biomarker_supplement_effects.notes IS 'Additional notes and considerations';

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_biomarker_supplement_effects_biomarker
    ON biomarker_supplement_effects(biomarker_name);
CREATE INDEX IF NOT EXISTS idx_biomarker_supplement_effects_supplement
    ON biomarker_supplement_effects(supplement_name);
CREATE INDEX IF NOT EXISTS idx_biomarker_supplement_effects_direction
    ON biomarker_supplement_effects(effect_direction);
CREATE INDEX IF NOT EXISTS idx_biomarker_supplement_effects_evidence
    ON biomarker_supplement_effects(evidence_level);

-- Create unique constraint for idempotency
CREATE UNIQUE INDEX IF NOT EXISTS idx_biomarker_supplement_effects_unique
    ON biomarker_supplement_effects(biomarker_name, supplement_name);

-- Create updated_at trigger
DROP TRIGGER IF EXISTS update_biomarker_supplement_effects_timestamp ON biomarker_supplement_effects;
CREATE TRIGGER update_biomarker_supplement_effects_timestamp
    BEFORE UPDATE ON biomarker_supplement_effects
    FOR EACH ROW
    EXECUTE FUNCTION update_health_intelligence_timestamp();


-- ============================================================================
-- 3. RLS POLICIES FOR biomarker_supplement_effects
-- ============================================================================

-- Enable RLS
ALTER TABLE biomarker_supplement_effects ENABLE ROW LEVEL SECURITY;

-- Public read access for authenticated users
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'biomarker_supplement_effects'
        AND policyname = 'Anyone can read biomarker supplement effects'
    ) THEN
        CREATE POLICY "Anyone can read biomarker supplement effects"
            ON biomarker_supplement_effects FOR SELECT
            TO authenticated
            USING (true);
    END IF;
END $$;

-- Service role can manage
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'biomarker_supplement_effects'
        AND policyname = 'Service role can manage biomarker supplement effects'
    ) THEN
        CREATE POLICY "Service role can manage biomarker supplement effects"
            ON biomarker_supplement_effects FOR ALL
            TO service_role
            USING (true)
            WITH CHECK (true);
    END IF;
END $$;

-- Grant permissions
GRANT SELECT ON biomarker_supplement_effects TO authenticated;
GRANT ALL ON biomarker_supplement_effects TO service_role;


-- ============================================================================
-- 4. INSERT SEX-SPECIFIC RANGES FOR KEY HORMONES
-- ============================================================================

-- Testosterone - Male ranges (by age)
INSERT INTO biomarker_reference_ranges (
    biomarker_type, name, category, optimal_low, optimal_high, normal_low, normal_high,
    unit, description, sex, age_min, age_max
) VALUES
    -- Male Testosterone by age
    ('testosterone_total', 'Total Testosterone', 'hormones', 600, 900, 400, 1000, 'ng/dL',
     'Primary male sex hormone', 'male', 18, 29),
    ('testosterone_total', 'Total Testosterone', 'hormones', 550, 850, 350, 950, 'ng/dL',
     'Primary male sex hormone', 'male', 30, 39),
    ('testosterone_total', 'Total Testosterone', 'hormones', 500, 800, 300, 900, 'ng/dL',
     'Primary male sex hormone', 'male', 40, 49),
    ('testosterone_total', 'Total Testosterone', 'hormones', 450, 750, 250, 850, 'ng/dL',
     'Primary male sex hormone', 'male', 50, 59),
    ('testosterone_total', 'Total Testosterone', 'hormones', 400, 700, 200, 800, 'ng/dL',
     'Primary male sex hormone', 'male', 60, NULL),

    -- Female Testosterone ranges
    ('testosterone_total', 'Total Testosterone', 'hormones', 20, 50, 8, 60, 'ng/dL',
     'Important for female energy, libido, and muscle maintenance', 'female', 18, 39),
    ('testosterone_total', 'Total Testosterone', 'hormones', 15, 45, 5, 55, 'ng/dL',
     'Important for female energy, libido, and muscle maintenance', 'female', 40, 54),
    ('testosterone_total', 'Total Testosterone', 'hormones', 10, 40, 3, 50, 'ng/dL',
     'Declines after menopause', 'female', 55, NULL)
ON CONFLICT (biomarker_type, COALESCE(sex, ''), COALESCE(age_min, -1), COALESCE(age_max, -1), COALESCE(athlete_type, '')) DO NOTHING;

-- Estradiol - Sex-specific ranges
INSERT INTO biomarker_reference_ranges (
    biomarker_type, name, category, optimal_low, optimal_high, normal_low, normal_high,
    unit, description, sex, age_min, age_max
) VALUES
    -- Male Estradiol
    ('estradiol', 'Estradiol (E2)', 'hormones', 20, 35, 10, 50, 'pg/mL',
     'Essential for male bone health and libido; too high causes issues', 'male', 18, NULL),

    -- Female Estradiol (premenopausal - varies by cycle phase, using mid-cycle average)
    ('estradiol', 'Estradiol (E2)', 'hormones', 100, 300, 30, 400, 'pg/mL',
     'Primary female sex hormone - varies with menstrual cycle', 'female', 18, 44),
    ('estradiol', 'Estradiol (E2)', 'hormones', 50, 200, 20, 350, 'pg/mL',
     'Begins declining in perimenopause', 'female', 45, 54),
    ('estradiol', 'Estradiol (E2)', 'hormones', 10, 50, 0, 100, 'pg/mL',
     'Significantly lower post-menopause', 'female', 55, NULL)
ON CONFLICT (biomarker_type, COALESCE(sex, ''), COALESCE(age_min, -1), COALESCE(age_max, -1), COALESCE(athlete_type, '')) DO NOTHING;

-- DHEA-S - Sex and age specific ranges
INSERT INTO biomarker_reference_ranges (
    biomarker_type, name, category, optimal_low, optimal_high, normal_low, normal_high,
    unit, description, sex, age_min, age_max
) VALUES
    -- Male DHEA-S
    ('dhea_s', 'DHEA-Sulfate', 'hormones', 350, 500, 200, 600, 'ug/dL',
     'Precursor hormone peaking in 20s', 'male', 18, 29),
    ('dhea_s', 'DHEA-Sulfate', 'hormones', 280, 450, 150, 550, 'ug/dL',
     'Gradual decline with age', 'male', 30, 39),
    ('dhea_s', 'DHEA-Sulfate', 'hormones', 220, 400, 100, 500, 'ug/dL',
     'Continues declining', 'male', 40, 49),
    ('dhea_s', 'DHEA-Sulfate', 'hormones', 150, 350, 70, 450, 'ug/dL',
     'Age-related decline continues', 'male', 50, 59),
    ('dhea_s', 'DHEA-Sulfate', 'hormones', 100, 300, 40, 400, 'ug/dL',
     'Lower baseline in older men', 'male', 60, NULL),

    -- Female DHEA-S
    ('dhea_s', 'DHEA-Sulfate', 'hormones', 200, 400, 100, 500, 'ug/dL',
     'Precursor hormone for testosterone and estrogen', 'female', 18, 29),
    ('dhea_s', 'DHEA-Sulfate', 'hormones', 150, 350, 75, 450, 'ug/dL',
     'Gradual decline with age', 'female', 30, 39),
    ('dhea_s', 'DHEA-Sulfate', 'hormones', 100, 300, 50, 400, 'ug/dL',
     'Continues declining through perimenopause', 'female', 40, 49),
    ('dhea_s', 'DHEA-Sulfate', 'hormones', 50, 250, 25, 350, 'ug/dL',
     'Lower baseline post-menopause', 'female', 50, NULL)
ON CONFLICT (biomarker_type, COALESCE(sex, ''), COALESCE(age_min, -1), COALESCE(age_max, -1), COALESCE(athlete_type, '')) DO NOTHING;

-- Free Testosterone - Sex specific
INSERT INTO biomarker_reference_ranges (
    biomarker_type, name, category, optimal_low, optimal_high, normal_low, normal_high,
    unit, description, sex, age_min, age_max
) VALUES
    ('testosterone_free', 'Free Testosterone', 'hormones', 15, 25, 9, 30, 'pg/mL',
     'Bioavailable testosterone - the active form', 'male', 18, 39),
    ('testosterone_free', 'Free Testosterone', 'hormones', 12, 22, 7, 26, 'pg/mL',
     'Declines with age as SHBG increases', 'male', 40, 59),
    ('testosterone_free', 'Free Testosterone', 'hormones', 8, 18, 5, 22, 'pg/mL',
     'Lower baseline in older men', 'male', 60, NULL),
    ('testosterone_free', 'Free Testosterone', 'hormones', 0.5, 3.0, 0.2, 5.0, 'pg/mL',
     'Bioavailable testosterone in women', 'female', 18, NULL)
ON CONFLICT (biomarker_type, COALESCE(sex, ''), COALESCE(age_min, -1), COALESCE(age_max, -1), COALESCE(athlete_type, '')) DO NOTHING;

-- Progesterone - Female specific
INSERT INTO biomarker_reference_ranges (
    biomarker_type, name, category, optimal_low, optimal_high, normal_low, normal_high,
    unit, description, sex, age_min, age_max
) VALUES
    ('progesterone', 'Progesterone', 'hormones', 5, 20, 1, 28, 'ng/mL',
     'Key female hormone - varies with menstrual cycle phase (luteal phase values)', 'female', 18, 44),
    ('progesterone', 'Progesterone', 'hormones', 2, 15, 0.5, 20, 'ng/mL',
     'Declining in perimenopause', 'female', 45, 54),
    ('progesterone', 'Progesterone', 'hormones', 0.1, 1.0, 0, 2.0, 'ng/mL',
     'Very low post-menopause', 'female', 55, NULL)
ON CONFLICT (biomarker_type, COALESCE(sex, ''), COALESCE(age_min, -1), COALESCE(age_max, -1), COALESCE(athlete_type, '')) DO NOTHING;

-- Hemoglobin - Sex specific
INSERT INTO biomarker_reference_ranges (
    biomarker_type, name, category, optimal_low, optimal_high, normal_low, normal_high,
    unit, description, sex
) VALUES
    ('hemoglobin', 'Hemoglobin', 'blood_count', 14.5, 16.5, 13.5, 17.5, 'g/dL',
     'Oxygen-carrying protein in red blood cells', 'male'),
    ('hemoglobin', 'Hemoglobin', 'blood_count', 12.5, 14.5, 12.0, 16.0, 'g/dL',
     'Oxygen-carrying protein - lower in women due to menstruation', 'female')
ON CONFLICT (biomarker_type, COALESCE(sex, ''), COALESCE(age_min, -1), COALESCE(age_max, -1), COALESCE(athlete_type, '')) DO NOTHING;

-- Ferritin - Sex specific
INSERT INTO biomarker_reference_ranges (
    biomarker_type, name, category, optimal_low, optimal_high, normal_low, normal_high,
    unit, description, sex
) VALUES
    ('ferritin', 'Ferritin', 'vitamins', 100, 200, 30, 400, 'ng/mL',
     'Iron storage protein - men can tolerate higher levels', 'male'),
    ('ferritin', 'Ferritin', 'vitamins', 50, 150, 15, 200, 'ng/mL',
     'Iron storage protein - often depleted in menstruating women', 'female')
ON CONFLICT (biomarker_type, COALESCE(sex, ''), COALESCE(age_min, -1), COALESCE(age_max, -1), COALESCE(athlete_type, '')) DO NOTHING;


-- ============================================================================
-- 5. INSERT ATHLETE-SPECIFIC RANGES FOR PERFORMANCE MARKERS
-- ============================================================================

-- Creatine Kinase - Athlete specific (higher baseline is normal)
INSERT INTO biomarker_reference_ranges (
    biomarker_type, name, category, optimal_low, optimal_high, normal_low, normal_high,
    unit, description, athlete_type
) VALUES
    ('ck_creatine_kinase', 'Creatine Kinase (CK)', 'muscle', 100, 400, 50, 800, 'U/L',
     'Elevated baseline normal in strength athletes from regular muscle damage', 'strength'),
    ('ck_creatine_kinase', 'Creatine Kinase (CK)', 'muscle', 80, 300, 40, 600, 'U/L',
     'Moderate elevation normal in endurance athletes', 'endurance'),
    ('ck_creatine_kinase', 'Creatine Kinase (CK)', 'muscle', 120, 450, 60, 900, 'U/L',
     'Higher baseline in power athletes due to explosive training', 'power'),
    ('ck_creatine_kinase', 'Creatine Kinase (CK)', 'muscle', 60, 250, 30, 500, 'U/L',
     'General fitness population ranges', 'general')
ON CONFLICT (biomarker_type, COALESCE(sex, ''), COALESCE(age_min, -1), COALESCE(age_max, -1), COALESCE(athlete_type, '')) DO NOTHING;

-- Ferritin - Athlete specific (endurance athletes need more)
INSERT INTO biomarker_reference_ranges (
    biomarker_type, name, category, optimal_low, optimal_high, normal_low, normal_high,
    unit, description, athlete_type
) VALUES
    ('ferritin', 'Ferritin', 'vitamins', 100, 200, 50, 300, 'ng/mL',
     'Endurance athletes need higher ferritin for optimal oxygen delivery', 'endurance'),
    ('ferritin', 'Ferritin', 'vitamins', 75, 175, 40, 280, 'ng/mL',
     'Moderate requirements for strength athletes', 'strength')
ON CONFLICT (biomarker_type, COALESCE(sex, ''), COALESCE(age_min, -1), COALESCE(age_max, -1), COALESCE(athlete_type, '')) DO NOTHING;

-- Hemoglobin - Endurance athlete specific
INSERT INTO biomarker_reference_ranges (
    biomarker_type, name, category, optimal_low, optimal_high, normal_low, normal_high,
    unit, description, athlete_type, sex
) VALUES
    ('hemoglobin', 'Hemoglobin', 'blood_count', 15.0, 17.0, 14.0, 18.0, 'g/dL',
     'Endurance athletes benefit from higher hemoglobin for oxygen delivery', 'endurance', 'male'),
    ('hemoglobin', 'Hemoglobin', 'blood_count', 13.0, 15.5, 12.5, 16.5, 'g/dL',
     'Female endurance athletes optimal range', 'endurance', 'female')
ON CONFLICT (biomarker_type, COALESCE(sex, ''), COALESCE(age_min, -1), COALESCE(age_max, -1), COALESCE(athlete_type, '')) DO NOTHING;

-- Cortisol - Athlete specific (overtraining detection)
INSERT INTO biomarker_reference_ranges (
    biomarker_type, name, category, optimal_low, optimal_high, normal_low, normal_high,
    unit, description, athlete_type
) VALUES
    ('cortisol_am', 'Cortisol (AM)', 'hormones', 12, 18, 8, 22, 'ug/dL',
     'Endurance athletes - monitor for overtraining if chronically elevated', 'endurance'),
    ('cortisol_am', 'Cortisol (AM)', 'hormones', 10, 16, 7, 20, 'ug/dL',
     'Strength athletes - acute elevation post-training is normal', 'strength')
ON CONFLICT (biomarker_type, COALESCE(sex, ''), COALESCE(age_min, -1), COALESCE(age_max, -1), COALESCE(athlete_type, '')) DO NOTHING;

-- Testosterone - Athlete specific
INSERT INTO biomarker_reference_ranges (
    biomarker_type, name, category, optimal_low, optimal_high, normal_low, normal_high,
    unit, description, athlete_type, sex
) VALUES
    ('testosterone_total', 'Total Testosterone', 'hormones', 550, 900, 400, 1000, 'ng/dL',
     'Strength athletes may see higher levels from training adaptations', 'strength', 'male'),
    ('testosterone_total', 'Total Testosterone', 'hormones', 450, 800, 300, 950, 'ng/dL',
     'Endurance athletes - monitor for suppression from high volume training', 'endurance', 'male')
ON CONFLICT (biomarker_type, COALESCE(sex, ''), COALESCE(age_min, -1), COALESCE(age_max, -1), COALESCE(athlete_type, '')) DO NOTHING;

-- Vitamin D - All athletes need higher
INSERT INTO biomarker_reference_ranges (
    biomarker_type, name, category, optimal_low, optimal_high, normal_low, normal_high,
    unit, description, athlete_type
) VALUES
    ('vitamin_d', 'Vitamin D (25-OH)', 'vitamins', 50, 80, 40, 100, 'ng/mL',
     'Athletes benefit from higher vitamin D for performance, recovery, and injury prevention', 'endurance'),
    ('vitamin_d', 'Vitamin D (25-OH)', 'vitamins', 50, 80, 40, 100, 'ng/mL',
     'Essential for muscle function and testosterone production', 'strength'),
    ('vitamin_d', 'Vitamin D (25-OH)', 'vitamins', 50, 80, 40, 100, 'ng/mL',
     'Supports explosive power and bone health', 'power')
ON CONFLICT (biomarker_type, COALESCE(sex, ''), COALESCE(age_min, -1), COALESCE(age_max, -1), COALESCE(athlete_type, '')) DO NOTHING;

-- Omega-3 Index - Athlete specific
INSERT INTO biomarker_reference_ranges (
    biomarker_type, name, category, optimal_low, optimal_high, normal_low, normal_high,
    unit, description, athlete_type
) VALUES
    ('omega3_index', 'Omega-3 Index', 'fatty_acids', 10, 14, 8, 16, '%',
     'Higher omega-3 levels support endurance performance and recovery', 'endurance'),
    ('omega3_index', 'Omega-3 Index', 'fatty_acids', 8, 12, 6, 14, '%',
     'Anti-inflammatory benefits support strength training recovery', 'strength')
ON CONFLICT (biomarker_type, COALESCE(sex, ''), COALESCE(age_min, -1), COALESCE(age_max, -1), COALESCE(athlete_type, '')) DO NOTHING;


-- ============================================================================
-- 6. UPDATE EDUCATIONAL DESCRIPTIONS FOR TOP 20 BIOMARKERS
-- ============================================================================

-- Vitamin D
UPDATE biomarker_reference_ranges
SET
    description_detailed = 'Vitamin D is a fat-soluble hormone that plays a crucial role in calcium absorption, bone health, immune function, muscle strength, and mood regulation. It is primarily synthesized in the skin upon exposure to UVB radiation from sunlight. Vitamin D deficiency is extremely common, affecting an estimated 40-75% of the global population, particularly those living at higher latitudes, working indoors, or with darker skin pigmentation. For athletes, optimal vitamin D levels are associated with improved muscle function, reduced injury risk, faster recovery, and enhanced testosterone production. The 25-hydroxyvitamin D test is the best indicator of vitamin D status, reflecting both dietary intake and sun exposure.',
    clinical_significance = 'LOW: Increased risk of bone fractures, muscle weakness, fatigue, depression, impaired immune function, and reduced testosterone. Severe deficiency can lead to rickets (children) or osteomalacia (adults). Athletes with low levels may experience more frequent injuries, slower recovery, and reduced performance. HIGH: Rare but possible with excessive supplementation. Can cause hypercalcemia leading to nausea, weakness, kidney problems, and calcification of soft tissues. Toxicity typically requires sustained intake >10,000 IU/day.',
    dietary_sources = ARRAY['Fatty fish (salmon, mackerel, sardines)', 'Cod liver oil', 'Egg yolks', 'Fortified milk and dairy', 'Fortified cereals', 'Mushrooms exposed to UV light', 'Beef liver'],
    lifestyle_factors = ARRAY['Sunlight exposure (UVB rays)', 'Geographic latitude', 'Skin pigmentation', 'Age (synthesis decreases with age)', 'Body fat percentage (vitamin D is sequestered in fat)', 'Sunscreen use', 'Time spent outdoors', 'Season of year']
WHERE biomarker_type = 'vitamin_d' AND sex IS NULL AND age_min IS NULL AND athlete_type IS NULL;

-- Total Testosterone
UPDATE biomarker_reference_ranges
SET
    description_detailed = 'Testosterone is the primary male sex hormone, though it is also important in females at lower levels. It plays essential roles in muscle mass and strength, bone density, fat distribution, red blood cell production, libido, mood, and cognitive function. In men, testosterone is primarily produced in the testes, while women produce smaller amounts in the ovaries and adrenal glands. Testosterone levels naturally decline with age (approximately 1-2% per year after age 30) and are influenced by numerous lifestyle factors. For athletes, optimal testosterone levels support muscle protein synthesis, recovery, motivation, and competitive drive.',
    clinical_significance = 'LOW: In men - reduced muscle mass and strength, increased body fat, low libido, erectile dysfunction, fatigue, depression, decreased bone density, and cognitive decline. In women - similar symptoms plus menstrual irregularities. Low testosterone in athletes may indicate overtraining syndrome, inadequate nutrition, or excessive stress. HIGH: In men - may indicate steroid use, tumors, or genetic conditions. Can cause acne, hair loss, aggression, and cardiovascular risks. In women - may indicate PCOS, adrenal tumors, or androgen excess, causing hirsutism, acne, and irregular periods.',
    dietary_sources = ARRAY['Zinc-rich foods (oysters, beef, pumpkin seeds)', 'Vitamin D sources', 'Saturated and monounsaturated fats', 'Eggs', 'Cruciferous vegetables (for estrogen metabolism)', 'Pomegranate', 'Garlic', 'Onions'],
    lifestyle_factors = ARRAY['Sleep quality and duration', 'Resistance training', 'Body fat percentage', 'Stress levels (cortisol)', 'Alcohol consumption', 'Endurance exercise volume', 'Caloric intake', 'Zinc and vitamin D status', 'Age']
WHERE biomarker_type = 'testosterone_total' AND sex IS NULL AND age_min IS NULL AND athlete_type IS NULL;

-- Ferritin
UPDATE biomarker_reference_ranges
SET
    description_detailed = 'Ferritin is the primary iron storage protein in the body, making serum ferritin levels the best single indicator of total body iron stores. Iron is essential for oxygen transport (via hemoglobin), energy production, DNA synthesis, and immune function. While iron deficiency is common (especially in women, vegetarians, and endurance athletes), iron overload can also be problematic. For athletes, iron status directly impacts performance through its role in oxygen delivery and aerobic capacity. Ferritin can be falsely elevated during inflammation or infection (its an acute phase reactant), so results should be interpreted alongside CRP and transferrin saturation.',
    clinical_significance = 'LOW: Iron deficiency progresses through stages - depleted stores (low ferritin) -> iron-deficient erythropoiesis -> iron deficiency anemia. Symptoms include fatigue, weakness, reduced exercise capacity, impaired cognitive function, restless legs, brittle nails, and cold intolerance. Athletes may notice decreased endurance, higher heart rates at given workloads, and longer recovery times. HIGH: May indicate hemochromatosis (iron overload disorder), liver disease, chronic inflammation, or excessive iron supplementation. Iron overload causes organ damage, joint pain, fatigue, and increased infection risk. Elevated ferritin with normal iron/TIBC often indicates inflammation.',
    dietary_sources = ARRAY['Red meat (most bioavailable heme iron)', 'Organ meats (liver)', 'Shellfish (oysters, clams)', 'Poultry', 'Fish', 'Beans and lentils', 'Spinach (with vitamin C for absorption)', 'Fortified cereals', 'Pumpkin seeds'],
    lifestyle_factors = ARRAY['Menstruation (major iron loss)', 'Endurance exercise (foot strike hemolysis, GI bleeding, sweat losses)', 'Vegetarian/vegan diet', 'Blood donation', 'GI conditions affecting absorption', 'Vitamin C intake (enhances absorption)', 'Calcium and tea/coffee (inhibit absorption)', 'Inflammation status']
WHERE biomarker_type = 'ferritin' AND sex IS NULL AND age_min IS NULL AND athlete_type IS NULL;

-- Hemoglobin A1c
UPDATE biomarker_reference_ranges
SET
    description_detailed = 'Hemoglobin A1c (HbA1c) reflects average blood glucose levels over the past 2-3 months by measuring the percentage of hemoglobin that has glucose attached (glycated). Unlike fasting glucose which captures a single point in time, HbA1c provides insight into long-term glucose control and metabolic health. It is the gold standard for diabetes diagnosis and monitoring but is also valuable for assessing metabolic health in non-diabetics. For athletes and health-conscious individuals, tracking HbA1c helps optimize metabolic flexibility, body composition, and long-term health outcomes.',
    clinical_significance = 'LOW (<4.0%): Rare, may indicate hemolytic anemia, recent blood loss, or conditions affecting red blood cell lifespan. ELEVATED (5.7-6.4%): Indicates prediabetes with increased risk of developing type 2 diabetes, cardiovascular disease, and other metabolic conditions. Lifestyle intervention at this stage is highly effective. HIGH (>6.5%): Diagnostic for diabetes mellitus. Associated with increased risk of microvascular complications (retinopathy, nephropathy, neuropathy) and macrovascular disease (heart disease, stroke). Every 1% reduction in HbA1c reduces complication risk significantly.',
    dietary_sources = ARRAY['(Foods that raise glucose): Refined carbohydrates', 'Sugar-sweetened beverages', 'White bread and pasta', 'Processed foods', '(Foods that stabilize glucose): Fiber-rich vegetables', 'Protein', 'Healthy fats', 'Legumes', 'Whole grains'],
    lifestyle_factors = ARRAY['Carbohydrate intake and type', 'Meal timing and frequency', 'Physical activity level', 'Sleep quality', 'Stress levels', 'Body composition', 'Genetic factors', 'Medications', 'Alcohol consumption']
WHERE biomarker_type = 'hba1c' AND sex IS NULL AND age_min IS NULL AND athlete_type IS NULL;

-- C-Reactive Protein (hs-CRP)
UPDATE biomarker_reference_ranges
SET
    description_detailed = 'High-sensitivity C-reactive protein (hs-CRP) is a marker of systemic inflammation produced by the liver in response to inflammatory cytokines (particularly IL-6). While standard CRP tests detect acute inflammation from infections or injuries, hs-CRP measures lower levels associated with chronic, low-grade inflammation that contributes to cardiovascular disease, metabolic dysfunction, and various chronic conditions. For athletes, hs-CRP can help monitor recovery status, detect overtraining, and assess overall inflammatory burden. Its important to note that hs-CRP can be transiently elevated for 24-72 hours after intense exercise.',
    clinical_significance = 'LOW (<1.0 mg/L): Indicates low cardiovascular risk and minimal systemic inflammation. This is the target range. MODERATE (1.0-3.0 mg/L): Intermediate cardiovascular risk. May indicate chronic low-grade inflammation from various sources. HIGH (>3.0 mg/L): High cardiovascular risk or acute inflammation. Investigate potential sources including infections, autoimmune conditions, obesity, periodontal disease, or chronic stress. VERY HIGH (>10 mg/L): Likely indicates acute infection or significant inflammatory condition requiring medical attention.',
    dietary_sources = ARRAY['(Anti-inflammatory): Fatty fish (omega-3s)', 'Olive oil', 'Leafy greens', 'Berries', 'Turmeric', 'Ginger', 'Green tea', '(Pro-inflammatory): Processed foods', 'Sugar', 'Refined oils', 'Trans fats', 'Excessive alcohol'],
    lifestyle_factors = ARRAY['Body fat percentage (especially visceral fat)', 'Sleep quality and duration', 'Chronic stress', 'Physical activity level', 'Smoking', 'Periodontal health', 'Gut health', 'Environmental toxins', 'Overtraining', 'Recent intense exercise (transient elevation)']
WHERE biomarker_type = 'crp' AND sex IS NULL AND age_min IS NULL AND athlete_type IS NULL;

-- TSH
UPDATE biomarker_reference_ranges
SET
    description_detailed = 'Thyroid Stimulating Hormone (TSH) is produced by the pituitary gland and regulates thyroid function through a negative feedback loop. When thyroid hormone levels are low, TSH increases to stimulate the thyroid; when thyroid hormones are adequate, TSH decreases. TSH is the most sensitive marker of thyroid dysfunction and is typically the first test ordered for thyroid assessment. The thyroid controls metabolism, energy production, body temperature, heart rate, and affects mood and cognitive function. Optimal thyroid function is essential for athletic performance, body composition, and recovery.',
    clinical_significance = 'HIGH TSH: Primary hypothyroidism - thyroid underproduction leads to compensatory TSH increase. Symptoms include fatigue, weight gain, cold intolerance, constipation, dry skin, hair loss, depression, and slow heart rate. Athletes may notice decreased performance, poor recovery, and difficulty losing body fat. LOW TSH: Primary hyperthyroidism - excess thyroid hormone suppresses TSH. Symptoms include weight loss, rapid heart rate, heat intolerance, anxiety, tremor, and diarrhea. Athletes may notice performance decline, muscle wasting, and increased injury risk. Very low TSH can also indicate pituitary dysfunction or over-replacement with thyroid medication.',
    dietary_sources = ARRAY['Iodine sources (seaweed, fish, dairy)', 'Selenium sources (Brazil nuts, fish)', 'Zinc sources', 'Tyrosine-rich foods (for T4 synthesis)', '(Goitrogens to moderate): Raw cruciferous vegetables', 'Soy products'],
    lifestyle_factors = ARRAY['Iodine intake', 'Selenium status', 'Chronic stress (affects T4 to T3 conversion)', 'Sleep quality', 'Extreme dieting or fasting', 'Endurance training volume', 'Environmental toxins', 'Medications (lithium, amiodarone)', 'Autoimmune conditions']
WHERE biomarker_type = 'thyroid_tsh' AND sex IS NULL AND age_min IS NULL AND athlete_type IS NULL;

-- LDL Cholesterol
UPDATE biomarker_reference_ranges
SET
    description_detailed = 'Low-density lipoprotein (LDL) cholesterol carries cholesterol from the liver to peripheral tissues. While often called "bad" cholesterol, LDL is essential for cell membrane integrity, hormone production, and vitamin D synthesis. The cardiovascular risk from LDL relates primarily to particle number, size (small dense LDL is more atherogenic), and oxidation status rather than simply the cholesterol content. Modern understanding recognizes that LDL-C is an imperfect marker - LDL particle number (LDL-P) and apolipoprotein B (ApoB) are more predictive of cardiovascular risk. Context matters: high LDL in the presence of low inflammation, good metabolic health, and large buoyant particles carries different risk than high LDL with metabolic syndrome.',
    clinical_significance = 'ELEVATED: Increased risk of atherosclerosis and cardiovascular disease, though risk depends heavily on context (particle size, oxidation, inflammation status, metabolic health). High LDL with low HDL, high triglycerides, and elevated inflammation markers indicates higher risk. High LDL with excellent metabolic markers may carry less risk. VERY HIGH (>190 mg/dL): May indicate familial hypercholesterolemia requiring medication. LOW (<50 mg/dL): Associated with increased risk of hemorrhagic stroke, hormonal dysfunction, and mood disorders in some studies. Cholesterol is essential for steroid hormone production.',
    dietary_sources = ARRAY['(May raise LDL): Saturated fat (context-dependent)', 'Trans fats (avoid)', 'Refined carbohydrates', '(May lower LDL): Soluble fiber', 'Plant sterols', 'Nuts', 'Olive oil', 'Fatty fish'],
    lifestyle_factors = ARRAY['Diet composition (saturated fat, carbs, fiber)', 'Body weight and composition', 'Physical activity', 'Thyroid function', 'Genetics', 'Stress', 'Sleep', 'Medications (statins, hormones)']
WHERE biomarker_type = 'ldl' AND sex IS NULL AND age_min IS NULL AND athlete_type IS NULL;

-- HDL Cholesterol
UPDATE biomarker_reference_ranges
SET
    description_detailed = 'High-density lipoprotein (HDL) cholesterol performs reverse cholesterol transport, carrying cholesterol from peripheral tissues back to the liver for excretion. This protective function has led to HDL being called "good" cholesterol. However, recent research suggests HDL function (cholesterol efflux capacity) may be more important than HDL levels alone. HDL also has anti-inflammatory, antioxidant, and antiplatelet properties. For athletes, HDL typically increases with regular aerobic exercise and is associated with better cardiovascular health. Very high HDL (>100 mg/dL) doesnt necessarily provide additional protection and may indicate genetic variants.',
    clinical_significance = 'LOW (<40 mg/dL men, <50 mg/dL women): Independent cardiovascular risk factor regardless of LDL levels. Often seen with metabolic syndrome, insulin resistance, obesity, and sedentary lifestyle. Associated with increased inflammation and reduced antioxidant capacity. OPTIMAL (60+ mg/dL): Associated with reduced cardiovascular risk, better metabolic health, and longevity. VERY HIGH (>100 mg/dL): May indicate genetic variants (CETP deficiency). Research on whether very high HDL provides additional protection is mixed.',
    dietary_sources = ARRAY['Fatty fish (omega-3s raise HDL)', 'Olive oil', 'Nuts (especially almonds, walnuts)', 'Avocados', 'Coconut oil (raises HDL but also LDL)', 'Eggs', 'Purple/red produce (anthocyanins)'],
    lifestyle_factors = ARRAY['Aerobic exercise (strongest lifestyle factor)', 'Body composition', 'Smoking cessation (smoking lowers HDL)', 'Moderate alcohol (raises HDL but not recommended)', 'Trans fat avoidance', 'Weight loss', 'Sleep quality', 'Genetic factors']
WHERE biomarker_type = 'hdl' AND sex IS NULL AND age_min IS NULL AND athlete_type IS NULL;

-- Fasting Glucose
UPDATE biomarker_reference_ranges
SET
    description_detailed = 'Fasting blood glucose measures the concentration of glucose in the blood after an overnight fast (typically 8-12 hours). It reflects how well the body maintains blood sugar homeostasis through insulin and glucagon regulation. Glucose is the primary fuel source for the brain and red blood cells and an important fuel for muscles during exercise. Chronic elevation of fasting glucose indicates developing insulin resistance and metabolic dysfunction. For athletes, blood glucose regulation affects energy availability, performance, recovery, and body composition.',
    clinical_significance = 'LOW (<65 mg/dL): Hypoglycemia - may cause shakiness, sweating, confusion, and in severe cases, unconsciousness. Can indicate excessive insulin production, adrenal insufficiency, or medication effects. OPTIMAL (70-90 mg/dL): Indicates excellent glucose regulation and metabolic health. ELEVATED (100-125 mg/dL): Prediabetes - indicates developing insulin resistance. Increased risk of type 2 diabetes and cardiovascular disease. Highly responsive to lifestyle intervention. HIGH (>126 mg/dL): Diagnostic for diabetes mellitus when confirmed on repeat testing. Requires medical management and aggressive lifestyle intervention.',
    dietary_sources = ARRAY['(Raise glucose): Simple carbohydrates', 'Refined grains', 'Sugary beverages', 'Processed foods', '(Stabilize glucose): Protein', 'Fiber', 'Healthy fats', 'Complex carbohydrates', 'Vinegar (may reduce post-meal glucose spike)'],
    lifestyle_factors = ARRAY['Carbohydrate intake and timing', 'Sleep quality and duration', 'Physical activity', 'Stress levels (cortisol raises glucose)', 'Body composition', 'Meal timing', 'Fasting protocols', 'Genetics']
WHERE biomarker_type = 'glucose_fasting' AND sex IS NULL AND age_min IS NULL AND athlete_type IS NULL;

-- Vitamin B12
UPDATE biomarker_reference_ranges
SET
    description_detailed = 'Vitamin B12 (cobalamin) is essential for DNA synthesis, red blood cell formation, neurological function, and energy metabolism. It is only found naturally in animal products, making deficiency common in vegetarians and vegans. B12 absorption requires intrinsic factor produced by stomach cells, so deficiency can occur even with adequate intake in people with low stomach acid, pernicious anemia, or certain medications (metformin, PPIs). B12 deficiency can cause irreversible neurological damage if untreated, so early detection is important. For athletes, adequate B12 is crucial for energy production, red blood cell formation, and nerve function.',
    clinical_significance = 'LOW (<200 pg/mL): B12 deficiency can cause megaloblastic anemia (fatigue, weakness, shortness of breath), neurological symptoms (numbness, tingling, balance problems, cognitive decline), and psychiatric symptoms (depression, memory issues). Neurological damage can be permanent if deficiency is prolonged. Suboptimal levels (200-400 pg/mL) may cause subtle symptoms and warrant supplementation. HIGH: Generally not concerning as B12 is water-soluble and excess is excreted. Very high levels without supplementation may indicate liver disease, kidney disease, or certain blood cancers.',
    dietary_sources = ARRAY['Liver and organ meats (highest)', 'Shellfish (clams, oysters)', 'Fish (salmon, trout, tuna)', 'Beef', 'Dairy products', 'Eggs', 'Fortified nutritional yeast', 'Fortified plant milks'],
    lifestyle_factors = ARRAY['Dietary pattern (animal product intake)', 'Age (absorption decreases with age)', 'Stomach acid production', 'Medications (metformin, PPIs)', 'Intestinal conditions (Crohns, celiac)', 'Alcohol consumption', 'Nitrous oxide exposure']
WHERE biomarker_type = 'vitamin_b12' AND sex IS NULL AND age_min IS NULL AND athlete_type IS NULL;

-- Fasting Insulin
UPDATE biomarker_reference_ranges
SET
    description_detailed = 'Fasting insulin measures the amount of insulin circulating in the blood after an overnight fast. Insulin is the hormone responsible for shuttling glucose into cells and regulating blood sugar. Elevated fasting insulin (hyperinsulinemia) often precedes high blood glucose by years and is an early marker of insulin resistance and metabolic dysfunction. For athletes and health-optimizers, fasting insulin is one of the most important metabolic markers to track as it reflects metabolic flexibility and disease risk. HOMA-IR (calculated from fasting glucose and insulin) provides additional insight into insulin resistance.',
    clinical_significance = 'LOW (<3 uIU/mL): Indicates excellent insulin sensitivity and metabolic flexibility. May be seen in very lean, active individuals and those practicing carbohydrate restriction or fasting. OPTIMAL (2-6 uIU/mL): Healthy insulin sensitivity with good metabolic function. ELEVATED (>8 uIU/mL): Indicates developing insulin resistance even if fasting glucose is normal. The pancreas is producing more insulin to maintain normal glucose - a compensated state that precedes diabetes. Associated with difficulty losing weight, inflammation, and increased disease risk. HIGH (>15 uIU/mL): Significant insulin resistance requiring intervention.',
    dietary_sources = ARRAY['(Raise insulin): Refined carbohydrates', 'Sugar', 'Frequent eating', '(Lower insulin): Protein (modest effect)', 'Fat (minimal effect)', 'Fiber', 'Time-restricted eating', 'Vinegar'],
    lifestyle_factors = ARRAY['Carbohydrate intake and type', 'Meal frequency', 'Fasting protocols', 'Physical activity (exercise improves insulin sensitivity)', 'Sleep quality', 'Stress levels', 'Body composition (especially visceral fat)', 'Genetics']
WHERE biomarker_type = 'insulin_fasting' AND sex IS NULL AND age_min IS NULL AND athlete_type IS NULL;

-- Triglycerides
UPDATE biomarker_reference_ranges
SET
    description_detailed = 'Triglycerides are the main form of fat storage in the body and a source of energy. Serum triglycerides reflect dietary fat intake (especially saturated fat), carbohydrate metabolism (excess carbs are converted to triglycerides), and metabolic health. Elevated triglycerides are a key component of metabolic syndrome and are associated with increased cardiovascular risk, particularly when combined with low HDL (atherogenic dyslipidemia). Triglycerides respond dramatically to dietary changes, especially carbohydrate and alcohol reduction. For athletes, moderate triglycerides indicate good metabolic flexibility and fat utilization.',
    clinical_significance = 'OPTIMAL (<100 mg/dL): Indicates excellent metabolic health and efficient fat metabolism. Often seen with low-carbohydrate diets, regular exercise, and lean body composition. NORMAL (100-150 mg/dL): Acceptable range with low cardiovascular risk. ELEVATED (150-499 mg/dL): Increased cardiovascular risk, especially with low HDL. Often indicates insulin resistance, excessive carbohydrate intake, or alcohol consumption. VERY HIGH (>500 mg/dL): Risk of acute pancreatitis. Requires medical intervention and aggressive dietary modification.',
    dietary_sources = ARRAY['(Raise triglycerides): Refined carbohydrates', 'Sugar and fructose', 'Alcohol', 'Excessive saturated fat', '(Lower triglycerides): Omega-3 fatty acids', 'Fiber', 'Reducing carbohydrates', 'Avoiding alcohol'],
    lifestyle_factors = ARRAY['Carbohydrate intake (especially refined/sugary)', 'Alcohol consumption', 'Body weight', 'Physical activity', 'Meal timing', 'Fasting state', 'Genetic factors', 'Medications (some raise triglycerides)']
WHERE biomarker_type = 'triglycerides' AND sex IS NULL AND age_min IS NULL AND athlete_type IS NULL;

-- Magnesium
UPDATE biomarker_reference_ranges
SET
    description_detailed = 'Magnesium is an essential mineral involved in over 300 enzymatic reactions including energy production, protein synthesis, muscle and nerve function, blood glucose control, and blood pressure regulation. Despite its importance, magnesium deficiency is common due to depleted soil, processed food consumption, and increased requirements from stress and exercise. Serum magnesium is a poor marker of total body magnesium since less than 1% of magnesium is in the blood (most is in bone and soft tissue). RBC magnesium is a better indicator but still imperfect. For athletes, magnesium is crucial for energy production, muscle function, sleep quality, and recovery.',
    clinical_significance = 'LOW (<1.8 mg/dL serum): Deficiency causes muscle cramps, tremors, weakness, fatigue, anxiety, insomnia, arrhythmias, and can worsen insulin resistance. Severe deficiency can cause seizures and cardiac arrhythmias. Athletes with low magnesium may experience more cramping, poorer sleep, and impaired performance. Note: serum levels only drop when deficiency is significant. OPTIMAL (2.0-2.4 mg/dL): Supports optimal muscle function, energy production, and sleep. HIGH (>2.5 mg/dL): Usually only seen with kidney dysfunction or excessive supplementation. Can cause muscle weakness, low blood pressure, and respiratory depression.',
    dietary_sources = ARRAY['Dark leafy greens (spinach, Swiss chard)', 'Nuts (almonds, cashews)', 'Seeds (pumpkin, chia)', 'Dark chocolate', 'Avocados', 'Legumes', 'Whole grains', 'Fish', 'Bananas'],
    lifestyle_factors = ARRAY['Soil depletion in food supply', 'Processed food consumption', 'Stress (depletes magnesium)', 'Intense exercise (lost in sweat)', 'Alcohol consumption', 'Caffeine intake', 'Medications (diuretics, PPIs)', 'Gut health and absorption', 'Diabetes (increased excretion)']
WHERE biomarker_type = 'magnesium' AND sex IS NULL AND age_min IS NULL AND athlete_type IS NULL;

-- ALT
UPDATE biomarker_reference_ranges
SET
    description_detailed = 'Alanine aminotransferase (ALT) is an enzyme primarily found in the liver, making it a relatively specific marker of liver health. When liver cells are damaged or inflamed, ALT is released into the bloodstream. ALT is commonly used to screen for liver disease and monitor the effects of medications, alcohol, and metabolic conditions on liver function. Non-alcoholic fatty liver disease (NAFLD) is now the most common cause of elevated ALT and is strongly associated with insulin resistance and metabolic syndrome. For athletes, elevated ALT can indicate overtraining, supplement toxicity, or underlying metabolic issues.',
    clinical_significance = 'OPTIMAL (<25 U/L): Indicates healthy liver function with minimal cellular damage. Some research suggests lower ALT (10-25 U/L) is associated with better longevity outcomes. ELEVATED (25-50 U/L): Mild elevation may indicate fatty liver, metabolic stress, or recent intense exercise (transient). Worth investigating with follow-up testing. HIGH (>50 U/L): Significant elevation suggests liver inflammation or damage. Potential causes include fatty liver disease, hepatitis, alcohol abuse, medication toxicity, or autoimmune conditions. Requires medical evaluation. VERY HIGH (>200 U/L): Indicates acute liver injury requiring urgent evaluation.',
    dietary_sources = ARRAY['(Liver-protective): Coffee', 'Green tea', 'Leafy greens', 'Berries', 'Olive oil', 'Turmeric', '(Liver-stressing): Alcohol', 'Excessive sugar/fructose', 'Trans fats', 'Processed foods'],
    lifestyle_factors = ARRAY['Alcohol consumption', 'Body weight (especially visceral fat)', 'Medication use', 'Supplement use (some are hepatotoxic)', 'Viral infections', 'Insulin resistance', 'Recent intense exercise (transient elevation)', 'Fasting state']
WHERE biomarker_type = 'alt' AND sex IS NULL AND age_min IS NULL AND athlete_type IS NULL;

-- Creatinine
UPDATE biomarker_reference_ranges
SET
    description_detailed = 'Creatinine is a waste product produced from normal muscle metabolism (breakdown of creatine phosphate). It is filtered by the kidneys and excreted in urine, making serum creatinine a standard marker of kidney function. Creatinine levels are influenced by muscle mass, dietary protein and creatine intake, and kidney function. eGFR (estimated glomerular filtration rate) is calculated from creatinine and provides a more accurate assessment of kidney function, accounting for age, sex, and race. For athletes, creatinine may be higher due to greater muscle mass and creatine supplementation, which should be considered when interpreting results.',
    clinical_significance = 'LOW (<0.7 mg/dL): May indicate low muscle mass, malnutrition, or pregnancy. Not typically concerning unless very low. OPTIMAL (0.8-1.1 mg/dL): Indicates healthy kidney function and normal muscle mass. Athletes with high muscle mass may have slightly higher baseline. ELEVATED (1.2-1.5 mg/dL): May indicate reduced kidney function or could be normal for muscular individuals or those taking creatine. Check eGFR for context. HIGH (>1.5 mg/dL): Suggests impaired kidney function requiring evaluation. Acute elevation may indicate dehydration, medication effects, or acute kidney injury.',
    dietary_sources = ARRAY['Creatine supplements (will raise creatinine)', 'Cooked red meat (cooking converts creatine to creatinine)', 'Fish', 'High protein diets (modest effect)'],
    lifestyle_factors = ARRAY['Muscle mass', 'Creatine supplementation', 'Hydration status', 'Protein intake', 'Intense exercise (transient elevation)', 'Medications (some affect creatinine)', 'Age (kidney function declines)', 'Underlying kidney disease']
WHERE biomarker_type = 'creatinine' AND sex IS NULL AND age_min IS NULL AND athlete_type IS NULL;

-- Homocysteine
UPDATE biomarker_reference_ranges
SET
    description_detailed = 'Homocysteine is an amino acid produced during methionine metabolism. It is recycled back to methionine through a process requiring B vitamins (folate, B12, B6). Elevated homocysteine is an independent risk factor for cardiovascular disease, stroke, blood clots, and cognitive decline. It damages blood vessel walls, promotes inflammation, and impairs methylation processes. High homocysteine often indicates B vitamin deficiency (especially folate and B12), MTHFR gene variants affecting methylation, or kidney dysfunction. For athletes, optimal homocysteine supports cardiovascular health and cognitive function.',
    clinical_significance = 'OPTIMAL (5-9 umol/L): Indicates efficient methylation, adequate B vitamin status, and lower cardiovascular risk. ELEVATED (10-15 umol/L): Increased cardiovascular risk. Often responds well to B vitamin supplementation (folate, B12, B6). Check B vitamin status and consider MTHFR testing. HIGH (>15 umol/L): Significantly elevated cardiovascular and stroke risk. May indicate severe B vitamin deficiency, kidney dysfunction, or homocystinuria. Requires investigation and treatment. VERY HIGH (>30 umol/L): Severe elevation requiring medical evaluation for genetic conditions or extreme deficiency.',
    dietary_sources = ARRAY['(Lower homocysteine): Folate-rich foods (leafy greens, legumes)', 'B12 sources (animal products)', 'B6 sources (poultry, fish, potatoes)', 'Betaine sources (beets, spinach, quinoa)', '(May raise): Excessive methionine (rare)'],
    lifestyle_factors = ARRAY['B vitamin status (folate, B12, B6)', 'MTHFR gene variants', 'Kidney function', 'Age', 'Medications (methotrexate, antiepileptics)', 'Coffee consumption (may elevate)', 'Smoking', 'Alcohol consumption']
WHERE biomarker_type = 'homocysteine' AND sex IS NULL AND age_min IS NULL AND athlete_type IS NULL;

-- Cortisol
UPDATE biomarker_reference_ranges
SET
    description_detailed = 'Cortisol is the primary stress hormone produced by the adrenal glands. It follows a diurnal rhythm, peaking in the early morning to promote wakefulness and declining throughout the day. Cortisol mobilizes energy, suppresses inflammation, and helps the body respond to stress. Chronic elevation from prolonged stress leads to muscle breakdown, immune suppression, fat storage (especially visceral), sleep disruption, and accelerated aging. Chronic suppression may indicate HPA axis dysfunction or adrenal fatigue. For athletes, cortisol patterns help assess training stress, recovery status, and risk of overtraining.',
    clinical_significance = 'LOW AM CORTISOL (<6 ug/dL): May indicate adrenal insufficiency (Addisons disease), HPA axis suppression from chronic stress, or overtraining syndrome. Symptoms include fatigue, weakness, low blood pressure, and poor stress tolerance. OPTIMAL AM CORTISOL (10-18 ug/dL): Healthy cortisol awakening response supporting energy and alertness. HIGH AM CORTISOL (>23 ug/dL): May indicate Cushings syndrome, acute stress, or medication effects. Chronic elevation causes muscle wasting, fat gain, immune suppression, and sleep issues. FLAT DIURNAL RHYTHM: Cortisol that doesnt decline appropriately through the day indicates HPA axis dysfunction and is associated with poor health outcomes.',
    dietary_sources = ARRAY['(Modulate cortisol): Omega-3 fatty acids', 'Dark chocolate', 'Green tea (L-theanine)', 'Probiotics', '(May raise cortisol): Caffeine (acutely)', 'Alcohol', 'High glycemic foods'],
    lifestyle_factors = ARRAY['Sleep quality and duration', 'Training load and recovery', 'Psychological stress', 'Caffeine timing', 'Meditation and relaxation practices', 'Light exposure patterns', 'Social connection', 'Overtraining', 'Caloric restriction']
WHERE biomarker_type = 'cortisol_am' AND sex IS NULL AND age_min IS NULL AND athlete_type IS NULL;

-- IGF-1
UPDATE biomarker_reference_ranges
SET
    description_detailed = 'Insulin-like Growth Factor 1 (IGF-1) is produced primarily by the liver in response to growth hormone (GH). It mediates many of GHs anabolic effects including muscle growth, tissue repair, and bone health. IGF-1 is a useful marker of GH status and overall anabolic/catabolic balance. Levels are influenced by protein intake, sleep quality, exercise, and metabolic health. For athletes, optimal IGF-1 supports muscle development, recovery, and tissue repair. However, chronically elevated IGF-1 may be associated with increased cancer risk, so extreme levels are not desirable.',
    clinical_significance = 'LOW (<100 ng/mL): May indicate GH deficiency, malnutrition, liver disease, or catabolic states. Symptoms include poor muscle development, fatigue, and impaired recovery. In athletes, low IGF-1 may indicate inadequate nutrition, overtraining, or poor sleep. OPTIMAL (150-250 ng/mL): Supports anabolic processes, muscle development, and recovery while maintaining healthy balance. HIGH (>350 ng/mL): May indicate acromegaly (excess GH), or response to GH therapy. Very high IGF-1 has been associated with increased cancer risk in some studies. Balance is key.',
    dietary_sources = ARRAY['Protein intake (stimulates IGF-1)', 'Dairy products (contain IGF-1 and stimulate production)', 'Amino acids (especially leucine)', 'Adequate calories', '(May lower): Caloric restriction', 'Fasting', 'Very low protein diets'],
    lifestyle_factors = ARRAY['Sleep quality (GH release during deep sleep)', 'Protein intake', 'Resistance training', 'Age (declines with age)', 'Body composition', 'Fasting and caloric restriction', 'Chronic disease', 'Liver health']
WHERE biomarker_type = 'igf1' AND sex IS NULL AND age_min IS NULL AND athlete_type IS NULL;

-- Omega-3 Index
UPDATE biomarker_reference_ranges
SET
    description_detailed = 'The Omega-3 Index measures the percentage of EPA and DHA (the most important omega-3 fatty acids) in red blood cell membranes. Unlike plasma levels that fluctuate with recent intake, the Omega-3 Index reflects long-term omega-3 status over the past 3 months. It is a validated marker of cardiovascular risk, with low levels strongly associated with sudden cardiac death, heart disease, depression, and cognitive decline. For athletes, adequate omega-3 status supports recovery, reduces inflammation, improves body composition, and may enhance performance. The target of 8%+ is difficult to achieve without regular fatty fish consumption or supplementation.',
    clinical_significance = 'LOW (<4%): High risk category associated with significantly elevated risk of sudden cardiac death, heart disease, depression, and cognitive issues. Indicates very low omega-3 intake or poor absorption. MODERATE (4-8%): Intermediate risk. Most Westerners fall in this range due to low fish consumption. Supplementation recommended to reach optimal range. OPTIMAL (8-12%): Associated with lowest cardiovascular risk, better mental health, reduced inflammation, and improved athletic recovery. This range requires intentional intake of fatty fish or supplements. HIGH (>12%): Generally safe; some populations (Japanese) naturally achieve these levels. May slightly increase bleeding risk at very high levels (>14%).',
    dietary_sources = ARRAY['Fatty fish (salmon, mackerel, sardines, anchovies)', 'Fish roe/caviar', 'Fish oil supplements', 'Krill oil', 'Algae-based omega-3 (vegan DHA)', 'Grass-fed beef (small amounts)', 'Pasture-raised eggs (small amounts)'],
    lifestyle_factors = ARRAY['Fatty fish consumption frequency', 'Fish oil supplementation', 'Omega-6 intake (competes for incorporation)', 'Cooking method (some omega-3 loss with high heat)', 'Gut health and absorption', 'Genetic variations in omega-3 metabolism', 'Vegetarian/vegan diet (limits EPA/DHA sources)']
WHERE biomarker_type = 'omega3_index' AND sex IS NULL AND age_min IS NULL AND athlete_type IS NULL;


-- ============================================================================
-- 7. INSERT SUPPLEMENT EFFECTS DATA
-- ============================================================================

INSERT INTO biomarker_supplement_effects (
    biomarker_name, supplement_name, effect_direction, effect_strength, mechanism, evidence_level, notes
) VALUES
    -- Vitamin D Effects
    ('Vitamin D (25-OH)', 'Vitamin D3', 'increase', 'strong', 'Direct supplementation of the vitamin being measured', 'strong', 'Dose response varies; 1000 IU typically raises levels by 10 ng/mL. Test and adjust.'),
    ('Total Testosterone', 'Vitamin D3', 'increase', 'moderate', 'Vitamin D receptors in Leydig cells influence testosterone synthesis', 'moderate', 'Effect strongest in those who are deficient. Target 50-80 ng/mL for optimal effect.'),
    ('Hemoglobin A1c', 'Vitamin D3', 'decrease', 'mild', 'Improves insulin sensitivity and beta cell function', 'moderate', 'More pronounced effect in those with deficiency and prediabetes.'),

    -- Magnesium Effects
    ('Magnesium', 'Magnesium Glycinate', 'increase', 'strong', 'Direct supplementation; glycinate form has good absorption and calming effects', 'strong', 'RBC magnesium is better marker than serum. 300-400mg elemental magnesium daily.'),
    ('Fasting Glucose', 'Magnesium Glycinate', 'decrease', 'moderate', 'Magnesium is cofactor for insulin signaling and glucose metabolism', 'strong', 'Especially beneficial in those with deficiency or insulin resistance.'),
    ('C-Reactive Protein (hs-CRP)', 'Magnesium Glycinate', 'decrease', 'mild', 'Anti-inflammatory effects through multiple pathways', 'moderate', 'Effect most notable in those with elevated CRP and magnesium deficiency.'),
    ('Cortisol (AM)', 'Magnesium Glycinate', 'modulate', 'mild', 'Regulates HPA axis activity; glycine component adds calming effect', 'moderate', 'May help normalize elevated cortisol; take in evening for sleep benefits.'),
    ('Hemoglobin A1c', 'Magnesium Glycinate', 'decrease', 'mild', 'Improves insulin sensitivity and glucose handling', 'moderate', 'Studies show 0.1-0.3% reduction in HbA1c with adequate magnesium.'),

    -- Omega-3 Effects
    ('Omega-3 Index', 'Fish Oil (EPA/DHA)', 'increase', 'strong', 'Direct supplementation of EPA and DHA fatty acids', 'strong', '2-4g combined EPA/DHA daily can increase index by 4-5% over 3 months.'),
    ('Triglycerides', 'Fish Oil (EPA/DHA)', 'decrease', 'strong', 'Reduces hepatic VLDL production and enhances triglyceride clearance', 'strong', 'Dose dependent; 2-4g daily can reduce triglycerides 15-30%.'),
    ('C-Reactive Protein (hs-CRP)', 'Fish Oil (EPA/DHA)', 'decrease', 'moderate', 'Anti-inflammatory effects via resolution of inflammation pathways', 'strong', 'EPA may be more effective than DHA for inflammation.'),
    ('Cortisol (AM)', 'Fish Oil (EPA/DHA)', 'decrease', 'mild', 'May attenuate cortisol response to mental stress', 'moderate', 'Effect more pronounced under chronic stress conditions.'),
    ('LDL Cholesterol', 'Fish Oil (EPA/DHA)', 'modulate', 'mild', 'May slightly increase LDL while improving particle size', 'strong', 'Some studies show 5-10% LDL increase; usually shifts to larger, less atherogenic particles.'),

    -- Zinc Effects
    ('Total Testosterone', 'Zinc', 'increase', 'moderate', 'Essential cofactor for testosterone synthesis; aromatase inhibitor', 'strong', 'Most effective in those with zinc deficiency. 30mg daily is typical dose.'),
    ('Free Testosterone', 'Zinc', 'increase', 'moderate', 'May reduce SHBG slightly and inhibit aromatase conversion', 'moderate', 'Zinc competes with copper - consider copper supplementation with high zinc doses.'),
    ('TSH', 'Zinc', 'modulate', 'mild', 'Required for T4 to T3 conversion and thyroid hormone action', 'moderate', 'Deficiency impairs thyroid function; supplementation normalizes in deficient individuals.'),
    ('Fasting Glucose', 'Zinc', 'decrease', 'mild', 'Involved in insulin storage, secretion, and signaling', 'moderate', 'Beneficial effect mainly in those with deficiency.'),

    -- Vitamin B12 Effects
    ('Vitamin B12', 'Methylcobalamin', 'increase', 'strong', 'Direct supplementation in active methylated form', 'strong', 'Methylcobalamin preferred for those with MTHFR variants. Sublingual improves absorption.'),
    ('Homocysteine', 'Methylcobalamin', 'decrease', 'strong', 'Essential cofactor for homocysteine remethylation to methionine', 'strong', 'Combine with folate and B6 for maximum homocysteine reduction.'),
    ('Hemoglobin', 'Methylcobalamin', 'increase', 'moderate', 'Required for red blood cell formation and DNA synthesis', 'strong', 'Effective in B12 deficiency anemia; less effect if B12 is adequate.'),

    -- Curcumin Effects
    ('C-Reactive Protein (hs-CRP)', 'Curcumin', 'decrease', 'moderate', 'Inhibits NF-kB and multiple inflammatory pathways', 'strong', 'Use enhanced absorption formulas. 500-1000mg curcuminoids daily.'),
    ('ALT (SGPT)', 'Curcumin', 'decrease', 'moderate', 'Hepatoprotective effects and reduces liver inflammation', 'moderate', 'May be particularly beneficial for fatty liver disease.'),
    ('Hemoglobin A1c', 'Curcumin', 'decrease', 'mild', 'Improves insulin sensitivity and reduces inflammation in metabolic syndrome', 'moderate', 'Studies show 0.1-0.2% reduction in HbA1c.'),
    ('Triglycerides', 'Curcumin', 'decrease', 'mild', 'Reduces hepatic lipogenesis and improves lipid metabolism', 'moderate', 'Effect modest but consistent across studies.'),

    -- Ashwagandha Effects
    ('Total Testosterone', 'Ashwagandha (KSM-66)', 'increase', 'moderate', 'Reduces cortisol, may support LH production and testicular function', 'strong', 'Studies show 10-20% increase in testosterone. Take 300-600mg daily.'),
    ('Cortisol (AM)', 'Ashwagandha (KSM-66)', 'decrease', 'strong', 'Adaptogenic effects modulate HPA axis and reduce cortisol', 'strong', 'Studies show 20-30% reduction in cortisol. Consistent use required.'),
    ('TSH', 'Ashwagandha (KSM-66)', 'modulate', 'moderate', 'May stimulate thyroid hormone production, normalize thyroid function', 'moderate', 'Can raise thyroid hormones - use caution if hyperthyroid or on thyroid medication.'),
    ('Fasting Glucose', 'Ashwagandha (KSM-66)', 'decrease', 'mild', 'Improves insulin sensitivity and reduces stress-related glucose elevation', 'moderate', 'Modest effect; benefits may be mediated through cortisol reduction.'),

    -- Berberine Effects
    ('Hemoglobin A1c', 'Berberine', 'decrease', 'strong', 'Activates AMPK, improves insulin sensitivity, reduces hepatic glucose production', 'strong', 'Comparable to metformin in some studies. 500mg 2-3x daily with meals.'),
    ('Fasting Glucose', 'Berberine', 'decrease', 'strong', 'Multiple mechanisms including AMPK activation and improved insulin signaling', 'strong', 'Can reduce fasting glucose by 20-30 mg/dL in diabetics.'),
    ('Fasting Insulin', 'Berberine', 'decrease', 'moderate', 'Improves insulin sensitivity, reducing compensatory insulin secretion', 'strong', 'Reduces both fasting insulin and HOMA-IR.'),
    ('Triglycerides', 'Berberine', 'decrease', 'moderate', 'Reduces hepatic lipogenesis and improves lipid clearance', 'strong', 'Can reduce triglycerides by 15-25%.'),
    ('LDL Cholesterol', 'Berberine', 'decrease', 'moderate', 'Upregulates LDL receptors in liver, enhancing LDL clearance', 'strong', 'Can reduce LDL by 20-25 mg/dL.'),
    ('C-Reactive Protein (hs-CRP)', 'Berberine', 'decrease', 'moderate', 'Anti-inflammatory effects via AMPK and NF-kB pathways', 'moderate', 'Reduces systemic inflammation markers.'),

    -- Creatine Effects
    ('Creatinine', 'Creatine Monohydrate', 'increase', 'moderate', 'Creatine is converted to creatinine; supplementation raises baseline', 'strong', 'Elevated creatinine from creatine use is benign and expected. Inform doctors of use.'),
    ('Creatine Kinase (CK)', 'Creatine Monohydrate', 'modulate', 'mild', 'May reduce exercise-induced CK elevation through improved muscle energy', 'moderate', 'Some studies show reduced muscle damage markers with creatine supplementation.'),
    ('IGF-1', 'Creatine Monohydrate', 'increase', 'mild', 'May enhance local muscle IGF-1 expression with resistance training', 'moderate', 'Effect on systemic IGF-1 is modest; local muscle effects more pronounced.'),

    -- Vitamin C Effects
    ('Cortisol (AM)', 'Vitamin C', 'decrease', 'mild', 'High concentrations in adrenal glands; may modulate cortisol response', 'moderate', '1-3g daily may help attenuate cortisol response to stress and exercise.'),
    ('C-Reactive Protein (hs-CRP)', 'Vitamin C', 'decrease', 'mild', 'Antioxidant and anti-inflammatory properties', 'moderate', 'Effect modest; more pronounced in those with elevated CRP.'),
    ('Hemoglobin', 'Vitamin C', 'increase', 'mild', 'Enhances iron absorption from plant sources', 'strong', 'Take with iron-rich meals or supplements to improve iron status and hemoglobin.'),

    -- Folate Effects
    ('Homocysteine', 'Methylfolate (5-MTHF)', 'decrease', 'strong', 'Essential cofactor for homocysteine remethylation', 'strong', 'Methylfolate preferred for MTHFR variants. Combine with B12 and B6.'),
    ('Vitamin B12', 'Methylfolate (5-MTHF)', 'modulate', 'mild', 'High folate can mask B12 deficiency symptoms', 'strong', 'Always supplement B12 when taking high-dose folate.'),

    -- CoQ10 Effects
    ('LDL Cholesterol', 'CoQ10 (Ubiquinol)', 'modulate', 'mild', 'Protects LDL from oxidation; may slightly reduce LDL levels', 'moderate', 'Primary benefit is LDL particle protection, not necessarily level reduction.'),
    ('C-Reactive Protein (hs-CRP)', 'CoQ10 (Ubiquinol)', 'decrease', 'mild', 'Antioxidant and anti-inflammatory properties', 'moderate', 'Effect modest but consistent. 100-300mg daily.'),
    ('Fasting Glucose', 'CoQ10 (Ubiquinol)', 'decrease', 'mild', 'May improve mitochondrial function and insulin sensitivity', 'moderate', 'Beneficial particularly in those on statins (which deplete CoQ10).'),
    ('Creatine Kinase (CK)', 'CoQ10 (Ubiquinol)', 'decrease', 'mild', 'May reduce exercise-induced muscle damage through antioxidant effects', 'moderate', 'Especially beneficial for those on statins experiencing muscle symptoms.'),

    -- NAC Effects
    ('C-Reactive Protein (hs-CRP)', 'NAC (N-Acetyl Cysteine)', 'decrease', 'moderate', 'Precursor to glutathione; powerful antioxidant and anti-inflammatory', 'moderate', '600-1800mg daily. May cause GI upset in some.'),
    ('Homocysteine', 'NAC (N-Acetyl Cysteine)', 'decrease', 'moderate', 'Provides cysteine for homocysteine metabolism pathways', 'moderate', 'Useful adjunct to B vitamins for homocysteine reduction.'),
    ('ALT (SGPT)', 'NAC (N-Acetyl Cysteine)', 'decrease', 'moderate', 'Hepatoprotective through glutathione restoration', 'moderate', 'Well-established for liver protection; used clinically for acetaminophen toxicity.'),
    ('Fasting Insulin', 'NAC (N-Acetyl Cysteine)', 'decrease', 'mild', 'May improve insulin sensitivity through oxidative stress reduction', 'moderate', 'Studied in PCOS and insulin resistance conditions.'),

    -- Alpha-Lipoic Acid Effects
    ('Fasting Glucose', 'Alpha-Lipoic Acid', 'decrease', 'moderate', 'Enhances glucose uptake into cells, regenerates other antioxidants', 'strong', '300-600mg daily. R-form may be more effective.'),
    ('Hemoglobin A1c', 'Alpha-Lipoic Acid', 'decrease', 'mild', 'Long-term glucose lowering through improved insulin sensitivity', 'moderate', 'Studies show modest HbA1c reduction, especially in diabetics.'),
    ('C-Reactive Protein (hs-CRP)', 'Alpha-Lipoic Acid', 'decrease', 'mild', 'Powerful antioxidant with anti-inflammatory properties', 'moderate', 'Universal antioxidant; works in both water and fat-soluble environments.'),

    -- Tart Cherry Effects
    ('C-Reactive Protein (hs-CRP)', 'Tart Cherry Extract', 'decrease', 'moderate', 'Rich in anthocyanins with potent anti-inflammatory properties', 'moderate', 'Studies show reduced CRP and improved recovery markers post-exercise.'),
    ('Creatine Kinase (CK)', 'Tart Cherry Extract', 'decrease', 'moderate', 'Reduces exercise-induced muscle damage and inflammation', 'moderate', 'Take before and after intense training. Also improves sleep via natural melatonin.'),

    -- Melatonin Effects
    ('Cortisol (AM)', 'Melatonin', 'modulate', 'mild', 'Improves sleep quality which helps normalize cortisol rhythm', 'moderate', 'Low dose (0.3-1mg) may be more effective than high doses for sleep.'),
    ('C-Reactive Protein (hs-CRP)', 'Melatonin', 'decrease', 'mild', 'Antioxidant properties and improved sleep reduces inflammation', 'moderate', 'Effect mediated largely through improved sleep quality.'),

    -- Tongkat Ali Effects
    ('Total Testosterone', 'Tongkat Ali', 'increase', 'moderate', 'May support LH release and reduce SHBG', 'moderate', '200-400mg standardized extract daily. Studies show 10-15% testosterone increase.'),
    ('Free Testosterone', 'Tongkat Ali', 'increase', 'moderate', 'May reduce SHBG, increasing free testosterone availability', 'moderate', 'Effect on free testosterone may be more pronounced than total testosterone.'),
    ('Cortisol (AM)', 'Tongkat Ali', 'decrease', 'mild', 'Adaptogenic properties may help reduce stress-related cortisol', 'moderate', 'Studies show improved testosterone:cortisol ratio.')

ON CONFLICT (biomarker_name, supplement_name) DO NOTHING;


COMMIT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_new_columns_count integer;
    v_supplement_effects_count integer;
    v_sex_specific_count integer;
    v_athlete_specific_count integer;
    v_detailed_descriptions_count integer;
BEGIN
    -- Count new columns (check if description_detailed exists)
    SELECT COUNT(*) INTO v_new_columns_count
    FROM information_schema.columns
    WHERE table_name = 'biomarker_reference_ranges'
    AND column_name IN ('sex', 'age_min', 'age_max', 'athlete_type', 'description_detailed', 'clinical_significance', 'dietary_sources', 'lifestyle_factors');

    -- Count supplement effects
    SELECT COUNT(*) INTO v_supplement_effects_count FROM biomarker_supplement_effects;

    -- Count sex-specific ranges
    SELECT COUNT(*) INTO v_sex_specific_count FROM biomarker_reference_ranges WHERE sex IS NOT NULL;

    -- Count athlete-specific ranges
    SELECT COUNT(*) INTO v_athlete_specific_count FROM biomarker_reference_ranges WHERE athlete_type IS NOT NULL;

    -- Count detailed descriptions
    SELECT COUNT(*) INTO v_detailed_descriptions_count FROM biomarker_reference_ranges WHERE description_detailed IS NOT NULL;

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'ENHANCED BIOMARKER REFERENCE RANGES MIGRATION COMPLETE';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Schema Changes:';
    RAISE NOTICE '  - Added % new columns to biomarker_reference_ranges', v_new_columns_count;
    RAISE NOTICE '    - sex (male/female/NULL)';
    RAISE NOTICE '    - age_min, age_max (age range support)';
    RAISE NOTICE '    - athlete_type (endurance/strength/power/general/NULL)';
    RAISE NOTICE '    - description_detailed (educational content)';
    RAISE NOTICE '    - clinical_significance (what out-of-range means)';
    RAISE NOTICE '    - dietary_sources (TEXT array)';
    RAISE NOTICE '    - lifestyle_factors (TEXT array)';
    RAISE NOTICE '';
    RAISE NOTICE 'New Table Created:';
    RAISE NOTICE '  - biomarker_supplement_effects (% records)', v_supplement_effects_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Seed Data:';
    RAISE NOTICE '  - Sex-specific ranges: % records', v_sex_specific_count;
    RAISE NOTICE '  - Athlete-specific ranges: % records', v_athlete_specific_count;
    RAISE NOTICE '  - Detailed descriptions: % biomarkers', v_detailed_descriptions_count;
    RAISE NOTICE '';
    RAISE NOTICE 'RLS Policies:';
    RAISE NOTICE '  - Public read access for authenticated users';
    RAISE NOTICE '  - Service role full management access';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
END $$;
