#!/bin/bash
# Linear Auto-Sync Hook
# Automatically fetches the latest Linear plan when Claude Code starts

echo "🔄 Fetching latest plan from Linear..."

python3 /Users/expo/Code/expo/clients/linear-bootstrap/linear_client.py export-md \
  --team "Agent-Control-Plane" \
  --project "MVP 1 — PT App & Agent Pilot" \
  --output /tmp/linear_plan_latest.md

if [ $? -eq 0 ]; then
  echo "✅ Linear plan synced to /tmp/linear_plan_latest.md"
  echo ""
  echo "📋 Current Plan Summary:"
  head -n 20 /tmp/linear_plan_latest.md
  echo ""
  echo "💡 Full plan available at: /tmp/linear_plan_latest.md"
  echo "   Use 'Read /tmp/linear_plan_latest.md' to see the complete plan"
else
  echo "⚠️  Failed to sync Linear plan"
fi
