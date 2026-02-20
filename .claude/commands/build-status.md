# Show current build status

Displays build number, version, and project health.

## Gather Info

Run all these commands and present results in the summary format below.

```bash
# Build number and version
grep CURRENT_PROJECT_VERSION /Users/expo/pt-performance/ios-app/PTPerformance/PTPerformance.xcodeproj/project.pbxproj | head -1
grep MARKETING_VERSION /Users/expo/pt-performance/ios-app/PTPerformance/PTPerformance.xcodeproj/project.pbxproj | head -1

# Build check
cd /Users/expo/pt-performance/ios-app/PTPerformance && xcodebuild -scheme PTPerformance -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -3

# Latest migration
ls /Users/expo/pt-performance/supabase/migrations/ | grep -v '_' | tail -1

# Source counts
find /Users/expo/pt-performance/ios-app/PTPerformance/Models -name "*.swift" | wc -l
find /Users/expo/pt-performance/ios-app/PTPerformance/ViewModels -name "*.swift" | wc -l
find /Users/expo/pt-performance/ios-app/PTPerformance/Services -name "*.swift" | wc -l
```

## Output Format

```
Modus iOS Build Status
======================
Build:    <number>  |  Version: <version>
Scheme:   PTPerformance  |  Bundle: com.ptperformance.app
Build:    PASS / FAIL

Source: <n> Models, <n> ViewModels, <n> Services
Latest Migration: <filename>
```
