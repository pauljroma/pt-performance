#!/bin/bash

# Build 79: AI Helper Edge Functions Local Test Script
# Agent 2: OpenAI Integration
# Tests ai-chat-completion and ai-exercise-substitution locally

set -e

echo "=================================================="
echo "Build 79: AI Helper Edge Functions Local Testing"
echo "=================================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -d "supabase/functions" ]; then
    echo -e "${RED}Error: Must run from project root${NC}"
    exit 1
fi

# Check for OpenAI API key
if [ -z "$OPENAI_API_KEY" ]; then
    echo -e "${RED}Error: OPENAI_API_KEY not set${NC}"
    echo "Export your OpenAI API key:"
    echo "  export OPENAI_API_KEY=sk-your-key-here"
    exit 1
fi

# Create .env.local if it doesn't exist
if [ ! -f "supabase/.env.local" ]; then
    echo -e "${YELLOW}Creating supabase/.env.local${NC}"
    echo "OPENAI_API_KEY=$OPENAI_API_KEY" > supabase/.env.local
fi

# Check if Supabase is running
echo -e "${YELLOW}Checking if Supabase is running...${NC}"
if ! supabase status &> /dev/null; then
    echo -e "${RED}Supabase is not running${NC}"
    echo "Start Supabase with: supabase start"
    exit 1
fi

echo -e "${GREEN}✓ Supabase is running${NC}"
echo ""

# Get Supabase local URL
SUPABASE_URL=$(supabase status --output json 2>/dev/null | grep -o '"API URL":"[^"]*"' | cut -d'"' -f4 || echo "http://localhost:54321")

# Function to test ai-chat-completion
test_chat_completion() {
    echo -e "${BLUE}Test 1: AI Chat Completion${NC}"
    echo "----------------------------------------------------"

    # Test with sample athlete ID (use test UUID)
    TEST_ATHLETE_ID="00000000-0000-0000-0000-000000000001"

    echo "Sending test message..."

    RESPONSE=$(curl -s -X POST "$SUPABASE_URL/functions/v1/ai-chat-completion" \
        -H "Content-Type: application/json" \
        -d "{
            \"athlete_id\": \"$TEST_ATHLETE_ID\",
            \"message\": \"What's a good warm-up routine before strength training?\"
        }")

    echo "Response:"
    echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
    echo ""

    # Check if response contains expected fields
    if echo "$RESPONSE" | grep -q "\"success\":true"; then
        echo -e "${GREEN}✓ Chat completion test passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Chat completion test failed${NC}"
        return 1
    fi
}

# Function to test ai-exercise-substitution
test_exercise_substitution() {
    echo -e "${BLUE}Test 2: AI Exercise Substitution${NC}"
    echo "----------------------------------------------------"

    TEST_ATHLETE_ID="00000000-0000-0000-0000-000000000001"
    TEST_EXERCISE_ID="00000000-0000-0000-0000-000000000002"

    echo "Requesting exercise substitution..."

    RESPONSE=$(curl -s -X POST "$SUPABASE_URL/functions/v1/ai-exercise-substitution" \
        -H "Content-Type: application/json" \
        -d "{
            \"athlete_id\": \"$TEST_ATHLETE_ID\",
            \"exercise_id\": \"$TEST_EXERCISE_ID\",
            \"reason\": \"No barbell available, only dumbbells\"
        }")

    echo "Response:"
    echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
    echo ""

    # Check if response contains expected fields (success or low confidence)
    if echo "$RESPONSE" | grep -q "\"success\":true\|\"error\":\"Low confidence\""; then
        echo -e "${GREEN}✓ Exercise substitution test passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Exercise substitution test failed${NC}"
        return 1
    fi
}

# Function to test validation
test_validation() {
    echo -e "${BLUE}Test 3: Request Validation${NC}"
    echo "----------------------------------------------------"

    echo "Testing with missing required field..."

    RESPONSE=$(curl -s -X POST "$SUPABASE_URL/functions/v1/ai-chat-completion" \
        -H "Content-Type: application/json" \
        -d "{
            \"message\": \"Hello\"
        }")

    echo "Response:"
    echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
    echo ""

    # Should get validation error
    if echo "$RESPONSE" | grep -q "\"error\":\"Validation failed\""; then
        echo -e "${GREEN}✓ Validation test passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Validation test failed${NC}"
        return 1
    fi
}

# Function to test error handling
test_error_handling() {
    echo -e "${BLUE}Test 4: Error Handling${NC}"
    echo "----------------------------------------------------"

    echo "Testing with invalid JSON..."

    RESPONSE=$(curl -s -X POST "$SUPABASE_URL/functions/v1/ai-chat-completion" \
        -H "Content-Type: application/json" \
        -d "invalid json")

    echo "Response:"
    echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
    echo ""

    # Should get error response
    if echo "$RESPONSE" | grep -q "error"; then
        echo -e "${GREEN}✓ Error handling test passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Error handling test failed${NC}"
        return 1
    fi
}

# Start function servers in background
echo -e "${YELLOW}Starting Edge Function servers...${NC}"

# Kill any existing function processes
pkill -f "supabase functions serve" || true
sleep 2

# Start ai-chat-completion
echo "Starting ai-chat-completion..."
supabase functions serve ai-chat-completion --env-file supabase/.env.local > /tmp/ai-chat-completion.log 2>&1 &
CHAT_PID=$!

sleep 3

# Start ai-exercise-substitution
echo "Starting ai-exercise-substitution..."
supabase functions serve ai-exercise-substitution --env-file supabase/.env.local > /tmp/ai-exercise-substitution.log 2>&1 &
SUB_PID=$!

sleep 3

echo -e "${GREEN}✓ Function servers started${NC}"
echo ""

# Run tests
TESTS_PASSED=0
TESTS_FAILED=0

# Note: These tests require actual database setup, so they may fail in isolated environment
echo -e "${YELLOW}Note: These tests require Supabase database to be running with proper schema${NC}"
echo ""

test_validation && ((TESTS_PASSED++)) || ((TESTS_FAILED++))
echo ""

test_error_handling && ((TESTS_PASSED++)) || ((TESTS_FAILED++))
echo ""

echo -e "${YELLOW}Note: Full integration tests require database with patient and exercise data${NC}"
echo "To test with real data:"
echo "1. Insert test patient: INSERT INTO patients (id, name) VALUES ('00000000-0000-0000-0000-000000000001', 'Test Athlete');"
echo "2. Insert test exercise: INSERT INTO exercise_templates (id, name, muscle_groups) VALUES ('00000000-0000-0000-0000-000000000002', 'Barbell Bench Press', ARRAY['Chest', 'Triceps']);"
echo "3. Run full tests with: test_chat_completion && test_exercise_substitution"
echo ""

# Cleanup
echo -e "${YELLOW}Cleaning up...${NC}"
kill $CHAT_PID $SUB_PID 2>/dev/null || true

echo ""
echo "=================================================="
echo "Test Results"
echo "=================================================="
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

TESTS_SKIPPED=2  # chat_completion and exercise_substitution not run above

if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}FAILED: $TESTS_FAILED test(s) failed. Check logs:${NC}"
    echo "  /tmp/ai-chat-completion.log"
    echo "  /tmp/ai-exercise-substitution.log"
    exit 1
elif [ $TESTS_SKIPPED -gt 0 ]; then
    echo -e "${YELLOW}PARTIAL: $TESTS_PASSED passed, $TESTS_SKIPPED skipped (integration tests need seeded DB)${NC}"
    echo ""
    echo "To run full integration tests:"
    echo "1. Seed test data (patients + exercise_templates)"
    echo "2. Add test_chat_completion and test_exercise_substitution calls above"
    exit 2  # Exit 2 = partial, distinguishable from success (0) and failure (1)
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
