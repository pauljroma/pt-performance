#!/bin/bash

# BUILD 115: Change Patient Mode Edge Function Deployment
# Deploys change-patient-mode function to Supabase

set -e

echo "=================================================="
echo "BUILD 115: Change Patient Mode Function Deployment"
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
    echo -e "${RED}Error: Must run from project root${NC}"
    exit 1
fi

# Check if logged in to Supabase
echo -e "${YELLOW}Checking Supabase authentication...${NC}"

# Try to get status (will fail if not logged in)
if ! supabase functions list --project-ref rpbxeaxlaoyoqkohytlw &>/dev/null; then
    echo -e "${RED}Not logged in to Supabase CLI${NC}"
    echo ""
    echo "Please login using one of these methods:"
    echo ""
    echo "Method 1: Login with access token"
    echo "  1. Get token from: https://supabase.com/dashboard/account/tokens"
    echo "  2. Run: export SUPABASE_ACCESS_TOKEN='sbp_...'"
    echo "  3. Re-run this script"
    echo ""
    echo "Method 2: Interactive login"
    echo "  supabase login"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ Authenticated${NC}"
echo ""

# Deploy function
echo -e "${GREEN}Deploying change-patient-mode function...${NC}"
echo "----------------------------------------------------"

cd /Users/expo/Code/expo

supabase functions deploy change-patient-mode \
  --project-ref rpbxeaxlaoyoqkohytlw \
  --no-verify-jwt

if [ $? -eq 0 ]; then
    echo ""
    echo "=================================================="
    echo -e "${GREEN}✓ Deployment Complete!${NC}"
    echo "=================================================="
    echo ""
    echo "Function URL:"
    echo "  https://rpbxeaxlaoyoqkohytlw.supabase.co/functions/v1/change-patient-mode"
    echo ""
    echo "Test the function:"
    echo "  curl -X POST \\"
    echo "    'https://rpbxeaxlaoyoqkohytlw.supabase.co/functions/v1/change-patient-mode' \\"
    echo "    -H 'Authorization: Bearer YOUR_JWT_TOKEN' \\"
    echo "    -H 'Content-Type: application/json' \\"
    echo "    -d '{"
    echo "      \"patient_id\": \"<uuid>\","
    echo "      \"new_mode\": \"strength\","
    echo "      \"reason\": \"Cleared for strength training\""
    echo "    }'"
    echo ""
    echo "View logs:"
    echo "  https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/functions/change-patient-mode/logs"
    echo ""
else
    echo -e "${RED}✗ Deployment failed${NC}"
    exit 1
fi
