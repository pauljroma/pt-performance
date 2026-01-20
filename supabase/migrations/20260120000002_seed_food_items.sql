-- Migration: Seed food_items with common foods
-- Created: 2026-01-20
-- Description: Populate food database with 100+ common foods for nutrition tracking

-- PROTEINS
INSERT INTO food_items (name, serving_size, serving_grams, calories, protein_g, carbs_g, fat_g, fiber_g, category, subcategory, is_system, is_verified) VALUES
-- Chicken
('Chicken Breast (grilled)', '4 oz', 113, 187, 35, 0, 4, 0, 'protein', 'chicken', TRUE, TRUE),
('Chicken Thigh (grilled)', '4 oz', 113, 232, 28, 0, 13, 0, 'protein', 'chicken', TRUE, TRUE),
('Rotisserie Chicken', '4 oz', 113, 190, 29, 0, 8, 0, 'protein', 'chicken', TRUE, TRUE),
('Chicken Wings', '4 wings', 100, 290, 27, 0, 19, 0, 'protein', 'chicken', TRUE, TRUE),

-- Beef
('Ground Beef (93% lean)', '4 oz', 113, 170, 23, 0, 8, 0, 'protein', 'beef', TRUE, TRUE),
('Ground Beef (80% lean)', '4 oz', 113, 287, 19, 0, 23, 0, 'protein', 'beef', TRUE, TRUE),
('Sirloin Steak', '6 oz', 170, 276, 46, 0, 9, 0, 'protein', 'beef', TRUE, TRUE),
('Ribeye Steak', '6 oz', 170, 466, 38, 0, 34, 0, 'protein', 'beef', TRUE, TRUE),
('Beef Jerky', '1 oz', 28, 116, 9, 3, 7, 0, 'protein', 'beef', TRUE, TRUE),

-- Fish & Seafood
('Salmon (wild)', '4 oz', 113, 207, 23, 0, 12, 0, 'protein', 'fish', TRUE, TRUE),
('Salmon (farmed)', '4 oz', 113, 234, 23, 0, 15, 0, 'protein', 'fish', TRUE, TRUE),
('Tuna (canned in water)', '4 oz', 113, 120, 27, 0, 1, 0, 'protein', 'fish', TRUE, TRUE),
('Tuna Steak', '4 oz', 113, 150, 33, 0, 1, 0, 'protein', 'fish', TRUE, TRUE),
('Shrimp', '4 oz', 113, 120, 23, 1, 2, 0, 'protein', 'seafood', TRUE, TRUE),
('Tilapia', '4 oz', 113, 110, 23, 0, 2, 0, 'protein', 'fish', TRUE, TRUE),
('Cod', '4 oz', 113, 93, 20, 0, 1, 0, 'protein', 'fish', TRUE, TRUE),

-- Pork
('Pork Tenderloin', '4 oz', 113, 136, 24, 0, 4, 0, 'protein', 'pork', TRUE, TRUE),
('Pork Chop', '4 oz', 113, 187, 26, 0, 8, 0, 'protein', 'pork', TRUE, TRUE),
('Bacon', '3 slices', 35, 161, 12, 0, 12, 0, 'protein', 'pork', TRUE, TRUE),
('Ham (deli)', '3 oz', 85, 90, 14, 2, 3, 0, 'protein', 'pork', TRUE, TRUE),

-- Turkey
('Turkey Breast (roasted)', '4 oz', 113, 153, 34, 0, 1, 0, 'protein', 'turkey', TRUE, TRUE),
('Ground Turkey (93% lean)', '4 oz', 113, 170, 21, 0, 9, 0, 'protein', 'turkey', TRUE, TRUE),
('Turkey Deli Meat', '3 oz', 85, 75, 15, 2, 1, 0, 'protein', 'turkey', TRUE, TRUE),

-- Eggs
('Whole Egg (large)', '1 egg', 50, 72, 6, 0, 5, 0, 'protein', 'eggs', TRUE, TRUE),
('Egg Whites', '3 whites', 99, 51, 11, 0, 0, 0, 'protein', 'eggs', TRUE, TRUE),
('Hard Boiled Egg', '1 egg', 50, 78, 6, 1, 5, 0, 'protein', 'eggs', TRUE, TRUE),

-- DAIRY
('Greek Yogurt (plain, nonfat)', '1 cup', 245, 130, 23, 8, 0, 0, 'dairy', 'yogurt', TRUE, TRUE),
('Greek Yogurt (plain, 2%)', '1 cup', 245, 170, 23, 8, 5, 0, 'dairy', 'yogurt', TRUE, TRUE),
('Cottage Cheese (low-fat)', '1 cup', 226, 163, 28, 6, 2, 0, 'dairy', 'cheese', TRUE, TRUE),
('Cottage Cheese (full-fat)', '1 cup', 226, 220, 25, 8, 10, 0, 'dairy', 'cheese', TRUE, TRUE),
('Milk (skim)', '1 cup', 245, 83, 8, 12, 0, 0, 'dairy', 'milk', TRUE, TRUE),
('Milk (2%)', '1 cup', 245, 122, 8, 12, 5, 0, 'dairy', 'milk', TRUE, TRUE),
('Milk (whole)', '1 cup', 245, 149, 8, 12, 8, 0, 'dairy', 'milk', TRUE, TRUE),
('Cheddar Cheese', '1 oz', 28, 113, 7, 0, 9, 0, 'dairy', 'cheese', TRUE, TRUE),
('Mozzarella Cheese', '1 oz', 28, 85, 6, 1, 6, 0, 'dairy', 'cheese', TRUE, TRUE),
('Parmesan Cheese', '1 tbsp', 5, 22, 2, 0, 1, 0, 'dairy', 'cheese', TRUE, TRUE),
('String Cheese', '1 stick', 28, 80, 7, 1, 5, 0, 'dairy', 'cheese', TRUE, TRUE),

-- GRAINS & CARBS
('White Rice (cooked)', '1 cup', 158, 205, 4, 45, 0, 1, 'grain', 'rice', TRUE, TRUE),
('Brown Rice (cooked)', '1 cup', 195, 216, 5, 45, 2, 4, 'grain', 'rice', TRUE, TRUE),
('Quinoa (cooked)', '1 cup', 185, 222, 8, 39, 4, 5, 'grain', 'quinoa', TRUE, TRUE),
('Oatmeal (cooked)', '1 cup', 234, 158, 6, 27, 3, 4, 'grain', 'oats', TRUE, TRUE),
('Pasta (cooked)', '1 cup', 140, 220, 8, 43, 1, 3, 'grain', 'pasta', TRUE, TRUE),
('Whole Wheat Bread', '1 slice', 43, 81, 4, 14, 1, 2, 'grain', 'bread', TRUE, TRUE),
('White Bread', '1 slice', 30, 79, 3, 15, 1, 1, 'grain', 'bread', TRUE, TRUE),
('Bagel (plain)', '1 medium', 98, 277, 10, 54, 2, 2, 'grain', 'bread', TRUE, TRUE),
('English Muffin', '1 muffin', 57, 134, 5, 26, 1, 2, 'grain', 'bread', TRUE, TRUE),
('Tortilla (flour)', '1 medium', 45, 140, 4, 24, 3, 1, 'grain', 'bread', TRUE, TRUE),
('Tortilla (corn)', '1 small', 26, 52, 1, 11, 1, 1, 'grain', 'bread', TRUE, TRUE),
('Sweet Potato', '1 medium', 130, 103, 2, 24, 0, 4, 'grain', 'potato', TRUE, TRUE),
('Russet Potato', '1 medium', 170, 161, 4, 37, 0, 4, 'grain', 'potato', TRUE, TRUE),

-- VEGETABLES
('Broccoli', '1 cup', 91, 31, 3, 6, 0, 2, 'vegetable', 'cruciferous', TRUE, TRUE),
('Spinach (raw)', '2 cups', 60, 14, 2, 2, 0, 1, 'vegetable', 'leafy_green', TRUE, TRUE),
('Spinach (cooked)', '1 cup', 180, 41, 5, 7, 0, 4, 'vegetable', 'leafy_green', TRUE, TRUE),
('Kale', '1 cup', 67, 33, 3, 6, 0, 1, 'vegetable', 'leafy_green', TRUE, TRUE),
('Mixed Greens', '2 cups', 85, 18, 2, 3, 0, 2, 'vegetable', 'leafy_green', TRUE, TRUE),
('Carrots', '1 medium', 61, 25, 1, 6, 0, 2, 'vegetable', 'root', TRUE, TRUE),
('Bell Pepper', '1 medium', 119, 24, 1, 6, 0, 2, 'vegetable', 'pepper', TRUE, TRUE),
('Tomato', '1 medium', 123, 22, 1, 5, 0, 1, 'vegetable', 'nightshade', TRUE, TRUE),
('Cherry Tomatoes', '1 cup', 149, 27, 1, 6, 0, 2, 'vegetable', 'nightshade', TRUE, TRUE),
('Cucumber', '1 cup sliced', 104, 16, 1, 4, 0, 1, 'vegetable', 'gourd', TRUE, TRUE),
('Zucchini', '1 cup', 124, 21, 2, 4, 0, 1, 'vegetable', 'squash', TRUE, TRUE),
('Asparagus', '6 spears', 90, 20, 2, 4, 0, 2, 'vegetable', 'stem', TRUE, TRUE),
('Green Beans', '1 cup', 110, 34, 2, 8, 0, 4, 'vegetable', 'legume', TRUE, TRUE),
('Cauliflower', '1 cup', 107, 27, 2, 5, 0, 2, 'vegetable', 'cruciferous', TRUE, TRUE),
('Brussels Sprouts', '1 cup', 88, 38, 3, 8, 0, 3, 'vegetable', 'cruciferous', TRUE, TRUE),
('Mushrooms', '1 cup', 70, 15, 2, 2, 0, 1, 'vegetable', 'fungi', TRUE, TRUE),
('Onion', '1 medium', 110, 44, 1, 10, 0, 2, 'vegetable', 'allium', TRUE, TRUE),
('Garlic', '1 clove', 3, 4, 0, 1, 0, 0, 'vegetable', 'allium', TRUE, TRUE),
('Avocado', '1 medium', 150, 240, 3, 12, 22, 10, 'vegetable', 'fruit', TRUE, TRUE),

-- FRUITS
('Banana', '1 medium', 118, 105, 1, 27, 0, 3, 'fruit', 'tropical', TRUE, TRUE),
('Apple', '1 medium', 182, 95, 0, 25, 0, 4, 'fruit', 'pome', TRUE, TRUE),
('Orange', '1 medium', 131, 62, 1, 15, 0, 3, 'fruit', 'citrus', TRUE, TRUE),
('Strawberries', '1 cup', 152, 49, 1, 12, 0, 3, 'fruit', 'berry', TRUE, TRUE),
('Blueberries', '1 cup', 148, 84, 1, 21, 0, 4, 'fruit', 'berry', TRUE, TRUE),
('Raspberries', '1 cup', 123, 64, 1, 15, 1, 8, 'fruit', 'berry', TRUE, TRUE),
('Grapes', '1 cup', 151, 104, 1, 27, 0, 1, 'fruit', 'vine', TRUE, TRUE),
('Watermelon', '1 cup', 152, 46, 1, 12, 0, 1, 'fruit', 'melon', TRUE, TRUE),
('Mango', '1 cup', 165, 99, 1, 25, 1, 3, 'fruit', 'tropical', TRUE, TRUE),
('Pineapple', '1 cup', 165, 82, 1, 22, 0, 2, 'fruit', 'tropical', TRUE, TRUE),
('Peach', '1 medium', 150, 59, 1, 14, 0, 2, 'fruit', 'stone', TRUE, TRUE),

-- FATS & NUTS
('Almonds', '1 oz (23 nuts)', 28, 164, 6, 6, 14, 4, 'fat', 'nuts', TRUE, TRUE),
('Peanuts', '1 oz', 28, 161, 7, 5, 14, 2, 'fat', 'nuts', TRUE, TRUE),
('Walnuts', '1 oz', 28, 185, 4, 4, 18, 2, 'fat', 'nuts', TRUE, TRUE),
('Cashews', '1 oz', 28, 157, 5, 9, 12, 1, 'fat', 'nuts', TRUE, TRUE),
('Peanut Butter', '2 tbsp', 32, 188, 8, 6, 16, 2, 'fat', 'nut_butter', TRUE, TRUE),
('Almond Butter', '2 tbsp', 32, 196, 7, 6, 18, 3, 'fat', 'nut_butter', TRUE, TRUE),
('Olive Oil', '1 tbsp', 14, 119, 0, 0, 14, 0, 'fat', 'oil', TRUE, TRUE),
('Coconut Oil', '1 tbsp', 14, 121, 0, 0, 13, 0, 'fat', 'oil', TRUE, TRUE),
('Butter', '1 tbsp', 14, 102, 0, 0, 12, 0, 'fat', 'dairy_fat', TRUE, TRUE),

-- LEGUMES
('Black Beans', '1 cup', 172, 227, 15, 41, 1, 15, 'protein', 'legume', TRUE, TRUE),
('Chickpeas', '1 cup', 164, 269, 15, 45, 4, 12, 'protein', 'legume', TRUE, TRUE),
('Lentils', '1 cup', 198, 230, 18, 40, 1, 16, 'protein', 'legume', TRUE, TRUE),
('Kidney Beans', '1 cup', 177, 225, 15, 40, 1, 11, 'protein', 'legume', TRUE, TRUE),
('Edamame', '1 cup', 155, 188, 18, 14, 8, 8, 'protein', 'legume', TRUE, TRUE),
('Hummus', '2 tbsp', 30, 70, 2, 6, 5, 1, 'fat', 'legume', TRUE, TRUE),

-- SUPPLEMENTS & DRINKS
('Whey Protein Powder', '1 scoop', 31, 120, 24, 3, 2, 0, 'supplement', 'protein_powder', TRUE, TRUE),
('Casein Protein Powder', '1 scoop', 33, 120, 24, 3, 1, 0, 'supplement', 'protein_powder', TRUE, TRUE),
('Plant Protein Powder', '1 scoop', 35, 120, 21, 6, 2, 2, 'supplement', 'protein_powder', TRUE, TRUE),
('Protein Bar (average)', '1 bar', 60, 200, 20, 22, 7, 3, 'supplement', 'protein_bar', TRUE, TRUE),
('Creatine Monohydrate', '5g', 5, 0, 0, 0, 0, 0, 'supplement', 'creatine', TRUE, TRUE),
('BCAA Powder', '1 scoop', 7, 0, 0, 0, 0, 0, 'supplement', 'amino_acid', TRUE, TRUE),

-- BEVERAGES
('Coffee (black)', '8 oz', 240, 2, 0, 0, 0, 0, 'beverage', 'coffee', TRUE, TRUE),
('Green Tea', '8 oz', 240, 0, 0, 0, 0, 0, 'beverage', 'tea', TRUE, TRUE),
('Orange Juice', '8 oz', 240, 112, 2, 26, 0, 0, 'beverage', 'juice', TRUE, TRUE),
('Almond Milk (unsweetened)', '1 cup', 240, 30, 1, 1, 3, 0, 'beverage', 'milk_alt', TRUE, TRUE),
('Oat Milk', '1 cup', 240, 120, 3, 16, 5, 2, 'beverage', 'milk_alt', TRUE, TRUE),
('Coconut Water', '1 cup', 240, 46, 2, 9, 0, 3, 'beverage', 'water', TRUE, TRUE),

-- CONDIMENTS & EXTRAS
('Honey', '1 tbsp', 21, 64, 0, 17, 0, 0, 'condiment', 'sweetener', TRUE, TRUE),
('Maple Syrup', '1 tbsp', 20, 52, 0, 13, 0, 0, 'condiment', 'sweetener', TRUE, TRUE),
('Salsa', '2 tbsp', 30, 10, 0, 2, 0, 1, 'condiment', 'sauce', TRUE, TRUE),
('Soy Sauce', '1 tbsp', 16, 9, 1, 1, 0, 0, 'condiment', 'sauce', TRUE, TRUE),
('Hot Sauce', '1 tsp', 5, 0, 0, 0, 0, 0, 'condiment', 'sauce', TRUE, TRUE),
('Mayonnaise', '1 tbsp', 13, 94, 0, 0, 10, 0, 'condiment', 'sauce', TRUE, TRUE),
('Mustard', '1 tsp', 5, 3, 0, 0, 0, 0, 'condiment', 'sauce', TRUE, TRUE),
('Ketchup', '1 tbsp', 17, 19, 0, 5, 0, 0, 'condiment', 'sauce', TRUE, TRUE);
