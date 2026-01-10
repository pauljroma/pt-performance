#!/bin/bash
# deploy_ai_functions.sh
# Deploys AI Edge Functions to Supabase for Build 79

set -e

echo "=============================================="
echo "Deploying AI Edge Functions to Supabase"
echo "Build 79 - AI Helper MVP"
echo "=============================================="
echo ""

cd "$(dirname "$0")/functions"

# Check if supabase CLI is available
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Please install: https://supabase.com/docs/guides/cli"
    exit 1
fi

echo "📦 Deploying ai-chat-completion..."
if supabase functions deploy ai-chat-completion --no-verify-jwt; then
    echo "✅ ai-chat-completion deployed successfully"
else
    echo "❌ Failed to deploy ai-chat-completion"
    exit 1
fi

echo ""
echo "📦 Deploying ai-exercise-substitution..."
if supabase functions deploy ai-exercise-substitution --no-verify-jwt; then
    echo "✅ ai-exercise-substitution deployed successfully"
else
    echo "❌ Failed to deploy ai-exercise-substitution"
    exit 1
fi

echo ""
echo "📦 Deploying ai-safety-check..."
if supabase functions deploy ai-safety-check --no-verify-jwt; then
    echo "✅ ai-safety-check deployed successfully"
else
    echo "❌ Failed to deploy ai-safety-check"
    exit 1
fi

echo ""
echo "=============================================="
echo "✅ All AI Edge Functions deployed successfully!"
echo "=============================================="
echo ""
echo "Deployed functions:"
echo "  - ai-chat-completion"
echo "  - ai-exercise-substitution"
echo "  - ai-safety-check"
echo ""
echo "Next steps:"
echo "1. Set environment variables in Supabase Dashboard:"
echo "   - OPENAI_API_KEY"
echo "   - ANTHROPIC_API_KEY"
echo "2. Test functions using the iOS app"
echo "3. Monitor function logs: supabase functions logs"
echo ""
