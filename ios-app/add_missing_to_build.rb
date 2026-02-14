#!/usr/bin/env ruby
require 'xcodeproj'

puts "Adding Existing File References to Build Phase"
puts "=" * 70

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main app target
target = project.targets.find { |t| t.name == 'PTPerformance' && t.product_type == 'com.apple.product-type.application' }

if target.nil?
  puts "ERROR: Could not find main PTPerformance app target"
  exit 1
end

# List of file names that we know exist but aren't in the build
missing_file_names = [
  'SmartSchedulingSuggestionCard.swift',
  'AR60ReadinessScore.swift',
  'JournalEntry.swift',
  'HRVInsightsViewModel.swift',
  'ProtocolBuilderViewModel.swift',
  'ReadinessScoreViewModel.swift',
  'SleepInsightsViewModel.swift',
  'WorkoutSummaryDataAdapter.swift',
  'AudioRecordingService.swift',
  'ReadinessScoreService.swift',
  'SmartSchedulingService.swift',
  'HealthDataGapDetector.swift',
  'HealthKitConflictResolver.swift',
  'AchievementRecommendations.swift',
  'AchievementShowcaseView.swift',
  'UpNextAchievementsSection.swift',
  'EnhancedWorkoutSummaryView.swift',
  'EvidenceDetailSheet.swift',
  'HRVInsightsView.swift',
  'SleepInsightsView.swift',
  'AudioHealthJournalView.swift',
  'JournalEntryDetailView.swift',
  'JournalEntryRecordingView.swift',
  'CalorieSurplusDeficitIndicator.swift',
  'MealTimeline.swift',
  'ProteinTimingChart.swift',
  'AthletePlanView.swift',
  'ProtocolBuilderView.swift',
  'ProtocolTemplateCard.swift',
  'TaskCustomizationSheet.swift',
  'UnifiedSettingsView.swift',
  'TemplateLibraryView.swift',
  'SafetyIncidentDetailSheet.swift',
  'SmartSchedulingHomeCard.swift',
  'PTPerformanceWidgets.swift',
  'MiniTrendChart.swift',
  'ReadinessBadge.swift',
  'WidgetColors.swift',
  'DailySummaryProvider.swift',
  'ReadinessProvider.swift',
  'RecoveryDashboardProvider.swift',
  'StreakProvider.swift',
  'TodayWorkoutProvider.swift',
  'WeekOverviewProvider.swift',
  'DailySummaryWidget.swift',
  'ReadinessWidget.swift',
  'RecoveryDashboardWidget.swift',
  'StreakWidget.swift',
  'TodayWorkoutWidget.swift',
  'WeekOverviewWidget.swift',
]

added_count = 0
skipped_count = 0
not_found_count = 0

puts "\nSearching for file references and adding to build phase..."
puts "-" * 70

missing_file_names.each do |file_name|
  # Find the file reference anywhere in the project
  file_ref = project.files.find { |f| f.path&.end_with?(file_name) }

  if file_ref.nil?
    puts "⚠️  File reference not found in project: #{file_name}"
    not_found_count += 1
    next
  end

  # Check if already in build phase
  in_build = target.source_build_phase.files.any? { |bf| bf.file_ref == file_ref }

  if in_build
    puts "⊘ Already in build: #{file_name}"
    skipped_count += 1
  else
    # Only add non-widget files to main target
    if file_ref.path.include?('PTPerformanceWidgets')
      puts "⊘ Skipping widget file: #{file_name}"
      skipped_count += 1
    else
      target.source_build_phase.add_file_reference(file_ref)
      puts "✓ Added to build: #{file_name}"
      added_count += 1
    end
  end
end

# Save the project
if added_count > 0
  puts "\nSaving project..."
  begin
    project.save
    puts "✓ Project saved successfully"
  rescue => e
    puts "✗ Error saving project: #{e.message}"
    exit 1
  end
end

puts "=" * 70
puts "Xcode Project Update Complete"
puts "=" * 70
puts "Files added to build: #{added_count}"
puts "Files skipped: #{skipped_count}"
puts "Files not found: #{not_found_count}"
puts "=" * 70

if not_found_count > 0
  puts "\n⚠️  #{not_found_count} files need to be added to the project first"
  puts "These files exist on disk but don't have file references in the Xcode project"
  exit 0
elsif added_count == 0 && skipped_count > 0
  puts "\n✅ All files are already in the build phase!"
  exit 0
else
  puts "\n✅ Successfully added #{added_count} files to the build phase!"
  exit 0
end
