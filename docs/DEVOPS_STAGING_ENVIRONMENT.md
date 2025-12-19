# Staging Environment Setup

## Overview
The staging environment is a complete replica of production for testing before deployment.

## Architecture

```
Production:  PTPerformance iOS → Supabase Production → PostgreSQL
Staging:     PTPerformance iOS → Supabase Staging → PostgreSQL
Development: PTPerformance iOS → Supabase Local → PostgreSQL
```

## Supabase Staging Project Setup

### 1. Create Staging Project

1. Go to https://supabase.com/dashboard
2. Create new project: `ptperformance-staging`
3. Region: Same as production (for consistency)
4. Database password: Store in 1Password/secrets manager

### 2. Configure Database

```sql
-- Run in Supabase SQL Editor (Staging)

-- Copy schema from production
-- Option A: Use Supabase CLI
supabase db dump --project-ref PROD_REF > production_schema.sql
supabase db push --project-ref STAGING_REF < production_schema.sql

-- Option B: Run migrations
-- Copy all migrations from production
\i /path/to/migrations/*.sql
```

### 3. Set Up RLS Policies

```bash
# Copy RLS policies from production
cd supabase/migrations
psql $STAGING_DATABASE_URL < 20241206000001_epic_enhancements.sql
psql $STAGING_DATABASE_URL < 20251210000011_fix_therapist_linkage.sql
# ... run all migration files
```

### 4. Seed Test Data

```bash
# Use staging test data (no real patient data)
psql $STAGING_DATABASE_URL < scripts/seed_test_data.sql
```

## Environment Configuration

### iOS App Configuration

#### Create Staging Configuration

1. Open Xcode
2. Project Settings → Configurations
3. Duplicate Release → Name: "Staging"
4. Create `Config-Staging.xcconfig`:

```
// Config-Staging.xcconfig
SUPABASE_URL = https://your-project.supabase.co
SUPABASE_ANON_KEY = your-staging-anon-key
APP_ENV = staging
APP_NAME = PTPerformance (Staging)
BUNDLE_ID_SUFFIX = .staging
```

#### Update Info.plist

```xml
<key>CFBundleDisplayName</key>
<string>$(APP_NAME)</string>
<key>CFBundleIdentifier</key>
<string>com.ptperformance$(BUNDLE_ID_SUFFIX)</string>
```

#### Update SupabaseClient.swift

```swift
import Foundation
import Supabase

class SupabaseClient {
    static let shared = SupabaseClient()

    let client: SupabaseClient

    private init() {
        #if STAGING
        let url = URL(string: "https://staging-project.supabase.co")!
        let key = "staging-anon-key"
        #elseif RELEASE
        let url = URL(string: "https://prod-project.supabase.co")!
        let key = "prod-anon-key"
        #else
        let url = URL(string: "http://localhost:54321")!
        let key = "local-anon-key"
        #endif

        self.client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    }
}
```

### GitHub Secrets for Staging

Add to GitHub repository secrets:

```
STAGING_SUPABASE_URL
STAGING_SUPABASE_ANON_KEY
STAGING_SUPABASE_SERVICE_KEY
STAGING_DATABASE_URL
STAGING_IOS_PROVISIONING_PROFILE_BASE64
STAGING_APP_STORE_CONNECT_KEY_ID
```

## CI/CD Integration

### Staging Deployment Workflow

Create `.github/workflows/deploy-staging.yml`:

```yaml
name: Deploy to Staging

on:
  push:
    branches:
      - develop
  workflow_dispatch:

jobs:
  deploy-staging:
    name: Deploy to Staging Environment
    runs-on: macos-14

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run Tests
        run: |
          cd ios-app/PTPerformance
          xcodebuild test \
            -project PTPerformance.xcodeproj \
            -scheme PTPerformance \
            -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2'

      - name: Build for Staging
        env:
          SUPABASE_URL: ${{ secrets.STAGING_SUPABASE_URL }}
          SUPABASE_ANON_KEY: ${{ secrets.STAGING_SUPABASE_ANON_KEY }}
        run: |
          cd ios-app/PTPerformance
          xcodebuild archive \
            -project PTPerformance.xcodeproj \
            -scheme PTPerformance \
            -configuration Staging \
            -archivePath PTPerformance-Staging.xcarchive

      - name: Upload to TestFlight (Staging Track)
        run: |
          # Upload to separate TestFlight group
          echo "Upload staging build to TestFlight"
```

## Database Migration Testing

### Test Migrations in Staging First

```bash
#!/bin/bash
# scripts/test_staging_migration.sh

set -e

echo "Testing migration in staging..."

# 1. Backup staging database
pg_dump $STAGING_DATABASE_URL > staging_backup_$(date +%Y%m%d_%H%M%S).sql

# 2. Run migration
psql $STAGING_DATABASE_URL < supabase/migrations/new_migration.sql

# 3. Verify migration
python3 scripts/validate_ios_schema.py --env staging

# 4. Run integration tests
cd ios-app/PTPerformance
xcodebuild test \
  -project PTPerformance.xcodeproj \
  -scheme PTPerformance \
  -configuration Staging \
  -only-testing:PTPerformanceTests/Integration

echo "✅ Staging migration successful!"
```

## Staging Environment Checklist

### Pre-Deployment
- [ ] All tests pass
- [ ] Schema validation passes
- [ ] RLS policies tested
- [ ] Performance benchmarks meet targets
- [ ] Sentry configured for staging
- [ ] Test data seeded

### Post-Deployment
- [ ] Smoke tests pass
- [ ] Authentication works
- [ ] CRUD operations work
- [ ] Real-time updates work
- [ ] Error tracking active
- [ ] Performance within targets

## Testing in Staging

### Manual Testing

1. **Authentication**
   - Login with test accounts
   - Verify RLS policies
   - Test role-based access

2. **Program Builder**
   - Create new program
   - Edit existing program
   - Delete program
   - Verify data persistence

3. **Session Logging**
   - Log exercise sets
   - Complete session
   - View session history

4. **Analytics**
   - View patient progress
   - Check volume charts
   - Verify readiness scores

### Automated Testing

```bash
# Run integration tests against staging
ENVIRONMENT=staging xcodebuild test \
  -project PTPerformance.xcodeproj \
  -scheme PTPerformance \
  -only-testing:PTPerformanceTests/Integration
```

## Data Management

### Staging Data Policy

- **NO REAL PATIENT DATA**: Use synthetic test data only
- **HIPAA Compliance**: Even in staging, treat as PHI-adjacent
- **Data Refresh**: Weekly refresh from test data seed
- **Data Retention**: 30 days maximum

### Reset Staging Database

```bash
#!/bin/bash
# scripts/reset_staging_db.sh

set -e

echo "⚠️  WARNING: This will delete all staging data!"
read -p "Continue? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Drop all tables
    psql $STAGING_DATABASE_URL -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

    # Recreate schema
    for migration in supabase/migrations/*.sql; do
        psql $STAGING_DATABASE_URL < $migration
    done

    # Seed test data
    psql $STAGING_DATABASE_URL < scripts/seed_test_data.sql

    echo "✅ Staging database reset complete!"
fi
```

## Monitoring

### Sentry Configuration

```swift
// In SentryConfig.swift
options.environment = "staging"
options.tracesSampleRate = 0.5 // Higher than production
```

### Staging Alerts

Configure separate Sentry alerts for staging:
- Less aggressive thresholds
- Different notification channels
- Staging-specific filters

## Access Control

### Staging TestFlight Access

1. Create TestFlight group: "Staging Testers"
2. Add internal team members
3. Enable automatic distribution
4. Set build expiration: 30 days

### Database Access

```bash
# Grant staging access to team
# Use Supabase dashboard or CLI

supabase teams create staging-access
supabase teams add-member staging-access user@example.com
```

## Troubleshooting

### Common Issues

**Issue**: Schema mismatch between staging and production
```bash
# Solution: Sync schemas
supabase db dump --project-ref PROD_REF > prod_schema.sql
supabase db reset --project-ref STAGING_REF
supabase db push --project-ref STAGING_REF < prod_schema.sql
```

**Issue**: RLS policies blocking test users
```bash
# Solution: Check policies
psql $STAGING_DATABASE_URL -c "SELECT * FROM pg_policies;"
```

**Issue**: Slow query performance
```bash
# Solution: Check indexes
psql $STAGING_DATABASE_URL -c "SELECT * FROM pg_indexes WHERE schemaname = 'public';"
```

## Promotion to Production

### Checklist

Before promoting staging to production:

- [ ] All staging tests pass for 24+ hours
- [ ] No critical errors in Sentry
- [ ] Performance metrics within targets
- [ ] Security scan passes
- [ ] Database backup created
- [ ] Rollback plan documented
- [ ] Team approval received

### Promotion Process

```bash
#!/bin/bash
# scripts/promote_to_production.sh

set -e

echo "Promoting staging to production..."

# 1. Run final tests
./scripts/test_staging_migration.sh

# 2. Create production backup
pg_dump $PRODUCTION_DATABASE_URL > prod_backup_$(date +%Y%m%d_%H%M%S).sql

# 3. Run production migrations
for migration in supabase/migrations/*.sql; do
    psql $PRODUCTION_DATABASE_URL < $migration
done

# 4. Deploy iOS app to production TestFlight
./scripts/deploy_to_testflight.sh --production

# 5. Verify production
./scripts/verify_production.sh

echo "✅ Production promotion complete!"
```

## Support

- DevOps Team: devops@example.com
- Staging Environment Status: https://status.staging.ptperformance.com
- Supabase Staging: https://staging-project.supabase.co
