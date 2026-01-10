#!/bin/bash

# Validation script for ai-meal-parser Edge Function
# BUILD 138 - Agent 5

set -e

echo "================================"
echo "AI Meal Parser - Validation"
echo "================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

validation_passed=true

check() {
    local check_name="$1"
    local command="$2"

    echo -n "Checking: $check_name ... "

    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        validation_passed=false
    fi
}

echo "File Structure Validation"
echo "-------------------------"

check "index.ts exists" "test -f index.ts"
check "types.ts exists" "test -f types.ts"
check "README.md exists" "test -f README.md"
check "test_meal_parser.sh exists" "test -f test_meal_parser.sh"
check "test script is executable" "test -x test_meal_parser.sh"

echo ""
echo "TypeScript Validation"
echo "--------------------"

check "TypeScript compiles" "deno check index.ts"
check "No syntax errors in types.ts" "deno check --remote types.ts"

echo ""
echo "Implementation Requirements"
echo "---------------------------"

check "MealParserRequest interface defined" "grep -q 'interface MealParserRequest' index.ts"
check "ParsedMeal interface defined" "grep -q 'interface ParsedMeal' index.ts"
check "CORS headers configured" "grep -q 'Access-Control-Allow-Origin' index.ts"
check "OpenAI API integration" "grep -q 'https://api.openai.com/v1/chat/completions' index.ts"
check "Image URL support" "grep -q 'image_url' index.ts"
check "Model selection logic" "grep -q 'gpt-4-vision-preview' index.ts && grep -q 'gpt-4o-mini' index.ts"
check "Confidence scoring" "grep -q 'ai_confidence' index.ts"
check "Macro validation" "grep -q 'typeof.*protein.*number' index.ts"
check "Error handling" "grep -q 'catch.*error' index.ts"

echo ""
echo "Type Definition Validation"
echo "-------------------------"

check "MealType defined" "grep -q \"type MealType =\" types.ts"
check "ConfidenceLevel defined" "grep -q \"type ConfidenceLevel =\" types.ts"
check "ParsedMeal export" "grep -q 'export interface ParsedMeal' types.ts"
check "Type guards defined" "grep -q 'isMealParserSuccess' types.ts"

echo ""
echo "Documentation Validation"
echo "------------------------"

check "README has usage examples" "grep -q 'Usage Examples' README.md"
check "README has iOS integration" "grep -q 'iOS Integration' README.md"
check "README has cost analysis" "grep -q 'Cost Considerations' README.md"
check "README has deployment instructions" "grep -q 'Deployment' README.md"

echo ""
echo "Line Count Verification"
echo "----------------------"

index_lines=$(wc -l < index.ts)
types_lines=$(wc -l < types.ts)
readme_lines=$(wc -l < README.md)

echo "index.ts: $index_lines lines"
echo "types.ts: $types_lines lines"
echo "README.md: $readme_lines lines"

if [ "$index_lines" -gt 200 ]; then
    echo -e "${GREEN}✓ index.ts has substantial implementation${NC}"
else
    echo -e "${RED}✗ index.ts seems incomplete${NC}"
    validation_passed=false
fi

if [ "$types_lines" -gt 50 ]; then
    echo -e "${GREEN}✓ types.ts has comprehensive type definitions${NC}"
else
    echo -e "${RED}✗ types.ts seems incomplete${NC}"
    validation_passed=false
fi

echo ""
echo "================================"

if [ "$validation_passed" = true ]; then
    echo -e "${GREEN}All validations passed! ✓${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Deploy: supabase functions deploy ai-meal-parser"
    echo "2. Set secret: supabase secrets set OPENAI_API_KEY=sk-..."
    echo "3. Test: ./test_meal_parser.sh"
    exit 0
else
    echo -e "${RED}Some validations failed. See above for details.${NC}"
    exit 1
fi
