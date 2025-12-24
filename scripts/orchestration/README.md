# Orchestration Scripts

**Purpose:** Multi-system coordination across repositories (iOS builds, migrations, deployments)

---

## Scripts

### trigger_ios_build.sh

**Purpose:** Coordinate iOS build from linear-bootstrap to ios-app

**Usage:**
```bash
scripts/orchestration/trigger_ios_build.sh 74
```

**What it does:**
1. Verifies iOS app directory exists (`../../../ios-app/PTPerformance`)
2. Checks build prerequisites (Xcode, fastlane)
3. Optionally syncs latest content
4. Triggers iOS archive via fastlane or manual Xcode

**Prerequisites:**
- Xcode installed
- fastlane installed (recommended)
- iOS app in expected location

**Environment:**
- `IOS_DIR` - Path to iOS app (default: `../../../ios-app/PTPerformance`)

---

### apply_migration.sh

**Purpose:** Coordinate database migration from linear-bootstrap to supabase/

**Usage:**
```bash
scripts/orchestration/apply_migration.sh 20251223000000_add_help_content.sql
scripts/orchestration/apply_migration.sh /path/to/migration.sql
```

**What it does:**
1. Verifies supabase directory exists (`../../../supabase`)
2. Loads environment variables (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
3. Locates migration file
4. Validates migration syntax
5. Applies migration via Supabase CLI, psql, or HTTP API

**Prerequisites:**
- `.env` configured with Supabase credentials
- Migration file exists
- Supabase CLI or psql (recommended)

**Environment:**
- `SUPABASE_DIR` - Path to supabase directory (default: `../../../supabase`)
- `SUPABASE_URL` - Supabase project URL (from .env)
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key (from .env)

---

### deploy_to_testflight.sh

**Purpose:** Coordinate TestFlight upload after iOS build

**Usage:**
```bash
scripts/orchestration/deploy_to_testflight.sh 74
```

**What it does:**
1. Verifies iOS app directory and build artifacts exist
2. Checks prerequisites (fastlane)
3. Loads App Store Connect credentials
4. Verifies IPA file
5. Uploads to TestFlight via fastlane pilot
6. Creates deployment record in `.outcomes/`

**Prerequisites:**
- iOS build already archived (run `trigger_ios_build.sh` first)
- fastlane installed and configured
- App Store Connect credentials configured

**Environment:**
- `FASTLANE_USER` - App Store Connect email
- `FASTLANE_PASSWORD` - App Store Connect password (app-specific)
- `FASTLANE_APP_ID` - App ID (e.g., com.expo.ptperformance)

---

## Typical Workflows

### Full iOS Release Workflow

```bash
# 1. Deploy latest content
tools/scripts/deploy.sh content

# 2. Trigger iOS build
scripts/orchestration/trigger_ios_build.sh 74

# 3. Wait for archive to complete (~5-10 minutes)

# 4. Deploy to TestFlight
scripts/orchestration/deploy_to_testflight.sh 74

# 5. Wait for App Store Connect processing (~10-15 minutes)

# 6. Distribute to testers via App Store Connect
```

### Database Migration Workflow

```bash
# 1. Create migration file in supabase/migrations/
# 2. Apply migration
scripts/orchestration/apply_migration.sh 20251223000000_my_migration.sql

# 3. Verify in Supabase dashboard
# 4. Test affected functionality
```

---

## Integration with Canonical Wrappers

These orchestration scripts are called by canonical wrappers:

```bash
# tools/scripts/deploy.sh ios
# → calls trigger_ios_build.sh

# tools/scripts/deploy.sh migration
# → calls apply_migration.sh

# tools/scripts/deploy.sh testflight
# → calls deploy_to_testflight.sh
```

See: [`docs/architecture/repo-map.md`](../../docs/architecture/repo-map.md)

---

## Directory Structure Assumptions

Orchestration scripts assume this repository layout:

```
expo/
├── clients/
│   └── linear-bootstrap/       # Current location
│       └── scripts/
│           └── orchestration/  # These scripts
├── ios-app/
│   └── PTPerformance/          # iOS app (Xcode project)
│       ├── PTPerformance.xcodeproj
│       ├── fastlane/
│       └── build_*/            # Build artifacts
└── supabase/
    └── migrations/             # Database migrations
```

**If your structure differs:**
- Set `IOS_DIR` environment variable
- Set `SUPABASE_DIR` environment variable
- Or edit the scripts directly

---

## Error Handling

### iOS Build Errors

**"iOS directory not found"**
```bash
# Check structure
ls -la ../../../ios-app/PTPerformance

# If different location, set IOS_DIR
export IOS_DIR=/path/to/ios-app/PTPerformance
scripts/orchestration/trigger_ios_build.sh 74
```

**"xcodebuild not found"**
```bash
# Install Xcode from App Store
# Or install Xcode Command Line Tools
xcode-select --install
```

**"fastlane not found"**
```bash
# Install fastlane
brew install fastlane
# or
sudo gem install fastlane
```

### Migration Errors

**"Migration file not found"**
```bash
# Check migration exists
ls supabase/migrations/

# Use full path
scripts/orchestration/apply_migration.sh /full/path/to/migration.sql
```

**"Supabase connection failed"**
```bash
# Verify credentials
tools/scripts/validate.sh env

# Check .env
cat .env | grep SUPABASE
```

### TestFlight Errors

**"Build directory not found"**
```bash
# Run build first
scripts/orchestration/trigger_ios_build.sh 74

# Wait for archive to complete
```

**"TestFlight upload failed"**
```bash
# Check credentials
echo $FASTLANE_USER
echo $FASTLANE_PASSWORD

# Verify app ID matches
# Check provisioning profile in Xcode
```

---

## Environment Setup

### iOS Build Credentials

Not required for build, but needed for TestFlight upload:

```bash
# Add to .env
FASTLANE_USER=your-email@example.com
FASTLANE_PASSWORD=your-app-specific-password
FASTLANE_APP_ID=com.expo.ptperformance
```

**Get app-specific password:**
1. Go to appleid.apple.com
2. Sign in
3. Security → App-Specific Passwords
4. Generate password

### Supabase Credentials

Required for migration:

```bash
# Add to .env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

**Get credentials:**
1. Go to supabase.com/dashboard
2. Select project
3. Settings → API
4. Copy URL and service_role key

---

## Safety Features

### Confirmation Prompts

All scripts prompt before destructive operations:

```bash
# Content sync prompt
Sync latest content before build? (y/N)

# Migration application prompt
Continue? (y/N)

# TestFlight upload prompt
Continue with TestFlight upload? (y/N)
```

### Validation

Scripts validate before executing:

- ✅ Directory structure exists
- ✅ Required tools installed
- ✅ Credentials configured
- ✅ Build artifacts present
- ✅ Migration syntax valid

### Deployment Records

TestFlight deployments create records in `.outcomes/`:

```
.outcomes/2025-12/TESTFLIGHT_BUILD_74_20251223_143022.md
```

Contains:
- Build number
- Deployment timestamp
- IPA details
- Next steps checklist

---

## Advanced Usage

### Custom iOS Directory

```bash
export IOS_DIR=/custom/path/to/ios-app
scripts/orchestration/trigger_ios_build.sh 74
```

### Custom Supabase Directory

```bash
export SUPABASE_DIR=/custom/path/to/supabase
scripts/orchestration/apply_migration.sh migration.sql
```

### Skip Content Sync

```bash
# When prompted "Sync latest content before build? (y/N)"
# Press N to skip
```

### Force Migration Without Confirmation

```bash
# Not recommended - use with caution
yes | scripts/orchestration/apply_migration.sh migration.sql
```

---

## See Also

- [Canonical Wrappers](../../tools/scripts/) - High-level deployment interface
- [Content Deployment](../content/) - Article deployment scripts
- [Linear Integration](../linear/) - Linear API scripts
- [Repo Map](../../docs/architecture/repo-map.md) - Where everything lives
