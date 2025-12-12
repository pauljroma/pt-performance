# Quick Upload Guide

## One Command Build & Upload

```bash
./build_and_upload.sh 14
```

This will:
1. Set build number to 14
2. Build archive
3. Open Xcode Organizer
4. You click "Distribute App" → "Upload"

## Current Build Status

**Build 13** - Ready to upload
- ✅ Archive built at `./build/PTPerformance.xcarchive`
- ✅ Xcode Organizer is open
- 🎯 Click "Distribute App" to upload

## What Was Fixed in Build 13

### Critical Bug:
- **Notes creation failure** - was sending `"therapist-user-id"` string instead of UUID
- Now fetches real therapist ID from auth session

### Database Schema (8 columns added):
1. `sessions.session_number`
2. `exercise_templates.exercise_name`
3. `session_exercises.prescribed_sets/reps/load`
4. `session_exercises.load_unit/rest_period_seconds/order_index`

All backend tests pass ✅

## Full Documentation

See `BUILD_AND_UPLOAD.md` for complete guide including:
- Troubleshooting
- Credential setup
- Alternative upload methods
- Common mistakes to avoid

## Just Built? Need to Upload NOW?

```bash
# Archive is ready - just open Organizer
open -a Xcode ./build/PTPerformance.xcarchive

# Then: Distribute App → Upload
```

That's it!
