#!/bin/bash

# Build 79: AI Helper Edge Functions Deployment Script
# Agent 2: OpenAI Integration
# Deploys ai-chat-completion and ai-exercise-substitution functions

set -e

echo "=================================================="
echo "Build 79: AI Helper Edge Functions Deployment"
echo "=================================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}Error: Supabase CLI not found${NC}"
    echo "Install with: npm install -g supabase"
    exit 1
fi

# Check if we're in the right directory
if [ ! -d "supabase/functions" ]; then
    echo -e "${RED}Error: Must run from project root (where supabase/ directory exists)${NC}"
    exit 1
fi

# Check for required environment variables
echo -e "${YELLOW}Checking environment variables...${NC}"

if [ -z "$OPENAI_API_KEY" ]; then
    echo -e "${RED}Warning: OPENAI_API_KEY not set in environment${NC}"
    echo "You'll need to set this in Supabase Dashboard after deployment:"
    echo "  Dashboard > Edge Functions > Secrets > Add Secret"
    echo "  Name: OPENAI_API_KEY"
    echo "  Value: sk-your-key-here"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}Step 1: Deploying ai-chat-completion function${NC}"
echo "----------------------------------------------------"

supabase functions deploy ai-chat-completion --no-verify-jwt

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ ai-chat-completion deployed successfully${NC}"
else
    echo -e "${RED}✗ Failed to deploy ai-chat-completion${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Step 2: Deploying ai-exercise-substitution function${NC}"
echo "----------------------------------------------------"

supabase functions deploy ai-exercise-substitution --no-verify-jwt

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ ai-exercise-substitution deployed successfully${NC}"
else
    echo -e "${RED}✗ Failed to deploy ai-exercise-substitution${NC}"
    exit 1
fi

echo ""
echo "=================================================="
echo -e "${GREEN}Deployment Complete!${NC}"
echo "=================================================="
echo ""

# Get project reference
PROJECT_REF=$(supabase status --output json 2>/dev/null | grep -o '"project_ref":"[^"]*"' | cut -d'"' -f4 || echo "your-project")

echo "Next Steps:"
echo ""
echo "1. Set OPENAI_API_KEY in Supabase Dashboard:"
echo "   https://supabase.com/dashboard/project/$PROJECT_REF/settings/functions"
echo ""
echo "2. Test the functions:"
echo "   ai-chat-completion:"
echo "   curl -X POST https://$PROJECT_REF.supabase.co/functions/v1/ai-chat-completion \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -H 'Authorization: Bearer YOUR_ANON_KEY' \\"
echo "     -d '{\"athlete_id\":\"uuid\",\"message\":\"Hello\"}'"
echo ""
echo "   ai-exercise-substitution:"
echo "   curl -X POST https://$PROJECT_REF.supabase.co/functions/v1/ai-exercise-substitution \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -H 'Authorization: Bearer YOUR_ANON_KEY' \\"
echo "     -d '{\"athlete_id\":\"uuid\",\"exercise_id\":\"uuid\",\"reason\":\"No equipment\"}'"
echo ""
echo "3. View function logs:"
echo "   https://supabase.com/dashboard/project/$PROJECT_REF/functions/ai-chat-completion/logs"
echo "   https://supabase.com/dashboard/project/$PROJECT_REF/functions/ai-exercise-substitution/logs"
echo ""
echo -e "${GREEN}Deployment successful!${NC}"
