#!/bin/bash

# Test AI Meal Parser Edge Function
# BUILD 138 - Nutrition Tracking

set -e

SUPABASE_URL="${SUPABASE_URL:-http://localhost:54321}"
FUNCTION_URL="${SUPABASE_URL}/functions/v1/ai-meal-parser"

echo "================================"
echo "AI Meal Parser - Test Suite"
echo "================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_count=0
pass_count=0
fail_count=0

run_test() {
    local test_name="$1"
    local payload="$2"
    local expect_success="${3:-true}"

    test_count=$((test_count + 1))
    echo -e "${YELLOW}Test ${test_count}: ${test_name}${NC}"

    response=$(curl -s -X POST "$FUNCTION_URL" \
        -H "Content-Type: application/json" \
        -d "$payload")

    success=$(echo "$response" | jq -r '.success // false')

    if [ "$success" = "$expect_success" ]; then
        echo -e "${GREEN}✓ PASS${NC}"
        pass_count=$((pass_count + 1))

        if [ "$expect_success" = "true" ]; then
            echo "Response:"
            echo "$response" | jq '.'
        fi
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo "Expected success=$expect_success, got success=$success"
        echo "Response: $response"
        fail_count=$((fail_count + 1))
    fi

    echo ""
}

echo "Starting tests..."
echo ""

# Test 1: Basic text-only meal description (high confidence)
run_test "High Confidence - Specific portions" '{
    "description": "8oz grilled chicken breast, 1 cup brown rice, 1 cup steamed broccoli"
}' true

# Test 2: Medium confidence - no portions
run_test "Medium Confidence - No portions" '{
    "description": "chicken breast with rice and vegetables"
}' true

# Test 3: Low confidence - vague description
run_test "Low Confidence - Vague description" '{
    "description": "had lunch"
}' true

# Test 4: Breakfast meal
run_test "Breakfast Classification" '{
    "description": "2 scrambled eggs, 2 slices whole wheat toast with butter, orange juice"
}' true

# Test 5: Snack meal
run_test "Snack Classification" '{
    "description": "protein shake with banana"
}' true

# Test 6: Complex meal
run_test "Complex Meal - Multiple items" '{
    "description": "Large Greek salad with grilled chicken, feta cheese, olives, cucumbers, tomatoes, red onion, and olive oil dressing. Side of pita bread."
}' true

# Test 7: Missing description (should fail)
run_test "Missing Description - Should Fail" '{
}' false

# Test 8: Empty description (should fail)
run_test "Empty Description - Should Fail" '{
    "description": ""
}' false

# Test 9: With image URL (text-only, but valid)
run_test "With Image URL" '{
    "description": "grilled salmon with asparagus",
    "image_url": "https://example.com/meal.jpg"
}' true

# Test 10: Fast food meal
run_test "Fast Food - High Calorie" '{
    "description": "Big Mac, large fries, large Coke"
}' true

# Test 11: Healthy dinner
run_test "Healthy Dinner" '{
    "description": "6oz baked cod, 1 cup quinoa, roasted Brussels sprouts with olive oil"
}' true

# Test 12: Dessert/snack
run_test "Dessert Snack" '{
    "description": "slice of chocolate cake"
}' true

echo "================================"
echo "Test Summary"
echo "================================"
echo "Total tests: $test_count"
echo -e "${GREEN}Passed: $pass_count${NC}"
if [ $fail_count -gt 0 ]; then
    echo -e "${RED}Failed: $fail_count${NC}"
else
    echo -e "${GREEN}Failed: $fail_count${NC}"
fi
echo ""

if [ $fail_count -eq 0 ]; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. See above for details.${NC}"
    exit 1
fi
