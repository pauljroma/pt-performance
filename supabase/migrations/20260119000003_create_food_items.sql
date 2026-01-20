-- Migration: Create food_items table
-- Description: System food database for quick lookup with nutritional information
-- Created: 2026-01-19

-- System food database for quick lookup
CREATE TABLE food_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    brand TEXT,
    serving_size TEXT NOT NULL, -- e.g., "1 cup", "100g", "1 medium"
    serving_grams DOUBLE PRECISION, -- standardized to grams
    calories INT NOT NULL,
    protein_g DOUBLE PRECISION NOT NULL DEFAULT 0,
    carbs_g DOUBLE PRECISION NOT NULL DEFAULT 0,
    fat_g DOUBLE PRECISION NOT NULL DEFAULT 0,
    fiber_g DOUBLE PRECISION DEFAULT 0,
    sugar_g DOUBLE PRECISION DEFAULT 0,
    sodium_mg DOUBLE PRECISION DEFAULT 0,
    category TEXT, -- 'protein', 'vegetable', 'fruit', 'grain', 'dairy', 'fat', 'supplement'
    subcategory TEXT, -- more specific: 'chicken', 'beef', 'leafy_green', etc.
    barcode TEXT, -- UPC for scanning
    is_verified BOOLEAN DEFAULT FALSE, -- admin verified
    is_system BOOLEAN DEFAULT TRUE, -- system vs user-created
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add table comment
COMMENT ON TABLE food_items IS 'System food database for quick nutritional lookup';

-- Add column comments
COMMENT ON COLUMN food_items.serving_size IS 'Human-readable serving size (e.g., "1 cup", "100g", "1 medium")';
COMMENT ON COLUMN food_items.serving_grams IS 'Serving size standardized to grams for calculations';
COMMENT ON COLUMN food_items.category IS 'Food category: protein, vegetable, fruit, grain, dairy, fat, supplement';
COMMENT ON COLUMN food_items.subcategory IS 'More specific category: chicken, beef, leafy_green, etc.';
COMMENT ON COLUMN food_items.barcode IS 'UPC barcode for scanning';
COMMENT ON COLUMN food_items.is_verified IS 'Whether the food item has been admin verified';
COMMENT ON COLUMN food_items.is_system IS 'System food items (TRUE) vs user-created custom items (FALSE)';

-- Create indexes for fast search
CREATE INDEX idx_food_items_name ON food_items USING gin(to_tsvector('english', name));
CREATE INDEX idx_food_items_category ON food_items(category);
CREATE INDEX idx_food_items_barcode ON food_items(barcode) WHERE barcode IS NOT NULL;
CREATE INDEX idx_food_items_is_system ON food_items(is_system) WHERE is_system = TRUE;

-- Enable RLS
ALTER TABLE food_items ENABLE ROW LEVEL SECURITY;

-- Everyone can read system food items
CREATE POLICY "Anyone can view system food items"
    ON food_items FOR SELECT
    USING (is_system = TRUE);

-- Users can view their own custom food items
CREATE POLICY "Users can view their own food items"
    ON food_items FOR SELECT
    USING (created_by = auth.uid());

-- Users can create custom food items
CREATE POLICY "Users can create custom food items"
    ON food_items FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL AND is_system = FALSE);

-- Users can update their own custom food items
CREATE POLICY "Users can update their own food items"
    ON food_items FOR UPDATE
    USING (created_by = auth.uid() AND is_system = FALSE);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON food_items TO authenticated;
