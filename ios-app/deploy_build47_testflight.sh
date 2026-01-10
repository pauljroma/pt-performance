#!/bin/bash
set -e

echo "🚀 PTPerformance Build 47 - TestFlight Deployment"
echo "=================================================="

cd /Users/expo/Code/expo/ios-app/PTPerformance

# Step 1: Add Swift files to Xcode project
echo "📝 Adding Swift files to Xcode project..."

cat > add_files_build47.rb << 'RUBY'
#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'PTPerformance' }

puts "Target: #{target.name}"

# Services
services_group = project.main_group.find_subpath('Services', true)
services_files = ['ErrorLogger.swift', 'PerformanceMonitor.swift']
services_files.each do |file|
  if services_group.files.any? { |f| f.path == file }
    puts "  ✓ #{file} already in project"
    next
  end
  file_ref = services_group.new_reference(file)
  target.add_file_references([file_ref])
  puts "  ✅ Added #{file} to Services"
end

# Models
models_group = project.main_group.find_subpath('Models', true)
models_files = ['ChartData.swift']
models_files.each do |file|
  if models_group.files.any? { |f| f.path == file }
    puts "  ✓ #{file} already in project"
    next
  end
  file_ref = models_group.new_reference(file)
  target.add_file_references([file_ref])
  puts "  ✅ Added #{file} to Models"
end

# Fix SessionSummaryView.swift - remove from UITests target
ui_tests_target = project.targets.find { |t| t.name == 'PTPerformanceUITests' }
if ui_tests_target
  views_group = project.main_group.find_subpath('Views/Patient', true)
  session_summary_file = views_group.files.find { |f| f.path == 'SessionSummaryView.swift' }

  if session_summary_file
    # Remove from UITests target
    build_file = ui_tests_target.source_build_phase.files.find { |bf| bf.file_ref == session_summary_file }
    if build_file
      ui_tests_target.source_build_phase.files.delete(build_file)
      puts "  ✅ Removed SessionSummaryView.swift from UITests target"
    else
      puts "  ✓ SessionSummaryView.swift not in UITests target"
    end
  end
end

project.save
puts "✅ Xcode project updated"
RUBY

# Check if xcodeproj gem is installed
if ! gem list xcodeproj -i > /dev/null 2>&1; then
  echo "Installing xcodeproj gem..."
  gem install xcodeproj
fi

ruby add_files_build47.rb
rm add_files_build47.rb

# Step 2: Uncomment ErrorLogger and PerformanceMonitor code
echo ""
echo "📝 Uncommenting ErrorLogger and PerformanceMonitor code..."

# PTPerformanceApp.swift - uncomment 3 sections
python3 << 'PYTHON'
import re

file_path = 'PTPerformanceApp.swift'
with open(file_path, 'r') as f:
    content = f.read()

# Section 1: App init (lines 50-65)
content = re.sub(
    r'// TODO: Uncomment once ErrorLogger\.swift and PerformanceMonitor\.swift are added to Xcode project\n\s*/\*\n\s+// Track app launch performance.*?\*/',
    '''// Track app launch performance
        PerformanceMonitor.shared.trackAppLaunch()

        // Log app startup
        ErrorLogger.shared.logUserAction(
            action: "app_launched",
            properties: [
                "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                "build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
                "device": UIDevice.current.model,
                "os_version": UIDevice.current.systemVersion
            ]
        )''',
    content,
    flags=re.DOTALL
)

# Section 2: finishAppLaunch (lines 73-74)
content = re.sub(
    r'// TODO: Uncomment once PerformanceMonitor\.swift is added to Xcode project\n\s+// PerformanceMonitor\.shared\.finishAppLaunch\(\)',
    'PerformanceMonitor.shared.finishAppLaunch()',
    content
)

# Section 3: updateUserContext (lines 99-120)
content = re.sub(
    r'// TODO: Uncomment once ErrorLogger\.swift is added to Xcode project\n\s+/\*\n\s+if isAuthenticated.*?\*/\n\s+}',
    '''if isAuthenticated, let userId = userId {
            // Set user context for error tracking
            ErrorLogger.shared.setUser(
                userId: userId,
                email: nil, // Don't track email for privacy
                userType: userRole?.rawValue ?? "unknown"
            )

            // Log authentication event
            ErrorLogger.shared.logUserAction(
                action: "user_authenticated",
                properties: [
                    "user_role": userRole?.rawValue ?? "unknown"
                ]
            )
        } else {
            // Clear user context on logout
            ErrorLogger.shared.clearUser()
        }
    }''',
    content,
    flags=re.DOTALL
)

with open(file_path, 'w') as f:
    f.write(content)

print("  ✅ PTPerformanceApp.swift uncommented")
PYTHON

# AnalyticsService.swift - uncomment ErrorLogger and Build 46 analytics
python3 << 'PYTHON'
import re

file_path = 'Services/AnalyticsService.swift'
with open(file_path, 'r') as f:
    content = f.read()

# Uncomment ErrorLogger
content = re.sub(
    r'// TODO: Uncomment once ErrorLogger\.swift is added to Xcode project target\n\s+// private let errorLogger = ErrorLogger\.shared',
    'private let errorLogger = ErrorLogger.shared',
    content
)

# Uncomment Build 46 analytics methods (lines 153-381)
content = re.sub(
    r'// TODO: Add ChartData\.swift to Xcode project target to enable these methods\n\s+/\*\n\s+/// Calculate volume data.*?return longestStreak\n\s+}\n\s+\*/',
    '''/// Calculate volume data for a time period
    func calculateVolumeData(
        for patientId: String,
        period: TimePeriod
    ) async throws -> VolumeChartData {
        let startDate = period.startDate
        let logs = try await fetchExerciseLogs(
            patientId: patientId,
            startDate: startDate
        )

        // Group logs by week
        let dataPoints = groupByWeek(logs: logs)
            .map { weekLogs -> VolumeDataPoint in
                let totalVolume = weekLogs.reduce(0.0) { total, log in
                    let weight = log.weight ?? 0
                    let reps = log.reps ?? 0
                    let sets = log.sets ?? 1
                    return total + (weight * Double(reps) * Double(sets))
                }

                let sessionDates = Set(weekLogs.map { Calendar.current.startOfDay(for: $0.createdAt) })

                return VolumeDataPoint(
                    date: weekLogs.first?.createdAt ?? Date(),
                    totalVolume: totalVolume,
                    sessionCount: sessionDates.count
                )
            }
            .sorted { $0.date < $1.date }

        let totalVolume = dataPoints.reduce(0.0) { $0 + $1.totalVolume }
        let averageVolume = dataPoints.isEmpty ? 0 : totalVolume / Double(dataPoints.count)
        let peakVolume = dataPoints.max(by: { $0.totalVolume < $1.totalVolume })

        return VolumeChartData(
            dataPoints: dataPoints,
            period: period,
            totalVolume: totalVolume,
            averageVolume: averageVolume,
            peakVolume: peakVolume?.totalVolume ?? 0,
            peakDate: peakVolume?.date
        )
    }

    /// Calculate strength progression for a specific exercise
    func calculateStrengthData(
        for patientId: String,
        exerciseId: String,
        period: TimePeriod
    ) async throws -> StrengthChartData {
        let startDate = period.startDate
        let logs = try await fetchExerciseLogs(
            patientId: patientId,
            exerciseId: exerciseId,
            startDate: startDate
        )

        guard let exerciseName = logs.first?.exercise?.name ?? logs.first?.exerciseId else {
            throw AnalyticsError.noData
        }

        let dataPoints = logs.compactMap { log -> StrengthDataPoint? in
            guard let weight = log.weight, let reps = log.reps else { return nil }
            let estimatedMax = calculateOneRepMax(weight: weight, reps: reps)

            return StrengthDataPoint(
                date: log.createdAt,
                exerciseName: exerciseName,
                weight: weight,
                reps: reps,
                estimatedOneRepMax: estimatedMax
            )
        }
        .sorted { $0.date < $1.date }

        guard !dataPoints.isEmpty else {
            throw AnalyticsError.noData
        }

        let currentMax = dataPoints.last?.estimatedOneRepMax ?? 0
        let startingMax = dataPoints.first?.estimatedOneRepMax ?? 0
        let improvement = startingMax > 0 ? (currentMax - startingMax) / startingMax : 0

        return StrengthChartData(
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            dataPoints: dataPoints,
            period: period,
            currentMax: currentMax,
            startingMax: startingMax,
            improvement: improvement
        )
    }

    /// Calculate workout consistency over time
    func calculateConsistencyData(
        for patientId: String,
        period: TimePeriod
    ) async throws -> ConsistencyChartData {
        let startDate = period.startDate

        // Fetch scheduled sessions
        let scheduledSessions: [ScheduledSession] = try await supabase.client
            .from("scheduled_sessions")
            .select()
            .eq("patient_id", value: patientId)
            .gte("scheduled_date", value: startDate.iso8601String)
            .execute()
            .value

        // Group by week
        var weeklyData: [Date: (scheduled: Int, completed: Int)] = [:]

        for session in scheduledSessions {
            let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: session.scheduledDate)?.start ?? session.scheduledDate

            var data = weeklyData[weekStart] ?? (scheduled: 0, completed: 0)
            data.scheduled += 1
            if session.status == .completed {
                data.completed += 1
            }
            weeklyData[weekStart] = data
        }

        let dataPoints = weeklyData.map { weekStart, data -> ConsistencyDataPoint in
            let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
            let rate = data.scheduled > 0 ? Double(data.completed) / Double(data.scheduled) : 0

            return ConsistencyDataPoint(
                weekStart: weekStart,
                weekEnd: weekEnd,
                scheduledSessions: data.scheduled,
                completedSessions: data.completed,
                completionRate: rate
            )
        }
        .sorted { $0.weekStart < $1.weekStart }

        let totalScheduled = dataPoints.reduce(0) { $0 + $1.scheduledSessions }
        let totalCompleted = dataPoints.reduce(0) { $0 + $1.completedSessions }
        let overallRate = totalScheduled > 0 ? Double(totalCompleted) / Double(totalScheduled) : 0

        let currentStreak = calculateCurrentStreak(from: dataPoints)
        let longestStreak = calculateLongestStreak(from: dataPoints)

        return ConsistencyChartData(
            dataPoints: dataPoints,
            period: period,
            totalScheduled: totalScheduled,
            totalCompleted: totalCompleted,
            overallCompletionRate: overallRate,
            currentStreak: currentStreak,
            longestStreak: longestStreak
        )
    }

    private func calculateCurrentStreak(from dataPoints: [ConsistencyDataPoint]) -> Int {
        var streak = 0
        for dataPoint in dataPoints.reversed() {
            if dataPoint.completionRate >= 0.8 {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    private func calculateLongestStreak(from dataPoints: [ConsistencyDataPoint]) -> Int {
        var longestStreak = 0
        var currentStreak = 0

        for dataPoint in dataPoints {
            if dataPoint.completionRate >= 0.8 {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }

        return longestStreak
    }''',
    content,
    flags=re.DOTALL
)

with open(file_path, 'w') as f:
    f.write(content)

print("  ✅ AnalyticsService.swift uncommented")
PYTHON

echo "✅ Code uncommented"

# Step 3: Build and verify
echo ""
echo "🔨 Building project to verify..."
xcodebuild -scheme PTPerformance -sdk iphonesimulator -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' build | tail -5

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
else
    echo "❌ Build failed - check errors above"
    exit 1
fi

# Step 4: Create export options
echo ""
echo "📄 Creating export options..."

cat > exportOptions.plist << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
PLIST

# Step 5: Check prerequisites
echo ""
echo "🔍 Checking prerequisites..."

# Find scheme name
SCHEME=$(xcodebuild -list -project PTPerformance.xcodeproj | grep -A 1 "Schemes:" | tail -1 | xargs)
echo "   Scheme: $SCHEME"

# Get team ID
TEAM_ID=$(security find-identity -v -p codesigning | grep "Apple Development" | head -1 | grep -o '([A-Z0-9]\{10\})' | tr -d '()')
if [ -z "$TEAM_ID" ]; then
    echo "⚠️  No code signing identity found. Building without code signing..."
    TEAM_ID="UNSIGNED"
fi
echo "   Team ID: $TEAM_ID"

# Update exportOptions with real team ID
if [ "$TEAM_ID" != "UNSIGNED" ]; then
    sed -i '' "s/YOUR_TEAM_ID/$TEAM_ID/g" exportOptions.plist
fi

# Step 6: Clean and build
echo ""
echo "🧹 Cleaning build folder..."
rm -rf build/
mkdir -p build/

echo "🔨 Building archive..."
xcodebuild clean archive \
  -project PTPerformance.xcodeproj \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath build/PTPerformance.xcarchive \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | tail -20

echo "✅ Archive created: build/PTPerformance.xcarchive"

# Step 7: Export IPA
echo ""
echo "📦 Exporting IPA..."
xcodebuild -exportArchive \
  -archivePath build/PTPerformance.xcarchive \
  -exportPath build/ \
  -exportOptionsPlist exportOptions.plist \
  2>&1 | tail -10

if [ -f "build/PTPerformance.ipa" ]; then
    echo "✅ IPA created: build/PTPerformance.ipa"
    ls -lh build/PTPerformance.ipa
else
    echo "⚠️  IPA not found - archive may need code signing"
fi

# Step 8: Instructions for TestFlight upload
echo ""
echo "=========================================="
echo "✅ Build 47 Complete!"
echo "=========================================="
echo ""
echo "📱 Next steps for TestFlight:"
echo ""
echo "1. Code sign the archive in Xcode:"
echo "   - Open Xcode → Window → Organizer"
echo "   - Select PTPerformance.xcarchive"
echo "   - Click 'Distribute App'"
echo "   - Select 'App Store Connect'"
echo ""
echo "2. Or use command line (requires credentials):"
echo "   xcrun altool --upload-app \\"
echo "     --type ios \\"
echo "     --file build/PTPerformance.ipa \\"
echo "     --username your-apple-id@email.com \\"
echo "     --password your-app-specific-password"
echo ""
echo "=========================================="
