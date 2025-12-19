#!/bin/bash
# Apply Build 46 database migrations
# Run this script after authenticating with Supabase

set -e

echo "Applying Build 46 migrations..."

# Method 1: Using Supabase CLI (recommended)
echo "Option 1: supabase db push"
echo "  Run: supabase db push"
echo ""

# Method 2: Using psql directly
echo "Option 2: Apply with psql"
echo "  psql \$DATABASE_URL -f supabase/migrations/20251215120000_create_scheduled_sessions.sql"
echo "  psql \$DATABASE_URL -f supabase/migrations/20251215130000_create_workout_templates.sql"
echo "  psql \$DATABASE_URL -f supabase/migrations/20251215140000_add_exercise_videos.sql"
echo "  psql \$DATABASE_URL -f supabase/migrations/20251215150000_create_nutrition_tracking.sql"
echo ""

echo "Migrations ready at:"
ls -lh supabase/migrations/202512151*

echo ""
echo "Total: 4 migrations, ~31KB"
