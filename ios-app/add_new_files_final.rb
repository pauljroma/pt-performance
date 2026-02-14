#!/usr/bin/env ruby
require 'xcodeproj'

puts "Adding Missing Swift Files to Xcode Project - FINAL VERSION"
puts "=" * 70

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main app target
target = project.targets.find { |t| t.name == 'PTPerformance' && t.product_type == 'com.apple.product-type.application' }

if target.nil?
  puts "ERROR: Could not find main PTPerformance app target"
  exit 1
end

main_group = project.main_group['PTPerformance'] || project.main_group.new_group('PTPerformance')

# Helper to get or create nested groups
def get_or_create_group(parent, path_components)
  current_group = parent
  path_components.each do |component|
    existing = current_group[component]
    if existing
      current_group = existing
    else
      new_group = current_group.new_group(component)
      current_group = new_group
    end
  end
  current_group
end

# Define all missing files with their full relative paths from PTPerformance/
files_to_add = [
  'Components/SmartSchedulingSuggestionCard.swift',
  'Models/AR60ReadinessScore.swift',
  'Models/JournalEntry.swift',
  'ViewModels/HRVInsightsViewModel.swift',
  'ViewModels/ProtocolBuilderViewModel.swift',
  'ViewModels/ReadinessScoreViewModel.swift',
  'ViewModels/SleepInsightsViewModel.swift',
  'ViewModels/WorkoutSummaryDataAdapter.swift',
  'Services/AudioRecordingService.swift',
  'Services/ReadinessScoreService.swift',
  'Services/SmartSchedulingService.swift',
  'Services/HealthKit/HealthDataGapDetector.swift',
  'Services/HealthKit/HealthKitConflictResolver.swift',
  'Views/Achievements/AchievementRecommendations.swift',
  'Views/Achievements/AchievementShowcaseView.swift',
  'Views/Achievements/UpNextAchievementsSection.swift',
  'Views/Celebrations/EnhancedWorkoutSummaryView.swift',
  'Views/Evidence/EvidenceDetailSheet.swift',
  'Views/Health/HRVInsightsView.swift',
  'Views/Health/SleepInsightsView.swift',
  'Views/Journal/AudioHealthJournalView.swift',
  'Views/Journal/JournalEntryDetailView.swift',
  'Views/Journal/JournalEntryRecordingView.swift',
  'Views/Nutrition/Components/CalorieSurplusDeficitIndicator.swift',
  'Views/Nutrition/Components/MealTimeline.swift',
  'Views/Nutrition/Components/ProteinTimingChart.swift',
  'Views/Protocol/AthletePlanView.swift',
  'Views/Protocol/ProtocolBuilderView.swift',
  'Views/Protocol/ProtocolTemplateCard.swift',
  'Views/Protocol/TaskCustomizationSheet.swift',
  'Views/Settings/UnifiedSettingsView.swift',
  'Views/Therapist/SafetyIncidentDetailSheet.swift',
  'Views/Today/SmartSchedulingHomeCard.swift',
  'PTPerformanceWidgets/PTPerformanceWidgets.swift',
  'PTPerformanceWidgets/Components/MiniTrendChart.swift',
  'PTPerformanceWidgets/Components/ReadinessBadge.swift',
  'PTPerformanceWidgets/Components/WidgetColors.swift',
  'PTPerformanceWidgets/Providers/DailySummaryProvider.swift',
  'PTPerformanceWidgets/Providers/ReadinessProvider.swift',
  'PTPerformanceWidgets/Providers/RecoveryDashboardProvider.swift',
  'PTPerformanceWidgets/Providers/StreakProvider.swift',
  'PTPerformanceWidgets/Providers/TodayWorkoutProvider.swift',
  'PTPerformanceWidgets/Providers/WeekOverviewProvider.swift',
  'PTPerformanceWidgets/Views/DailySummaryWidget.swift',
  'PTPerformanceWidgets/Views/ReadinessWidget.swift',
  'PTPerformanceWidgets/Views/RecoveryDashboardWidget.swift',
  'PTPerformanceWidgets/Views/StreakWidget.swift',
  'PTPerformanceWidgets/Views/TodayWorkoutWidget.swift',
  'PTPerformanceWidgets/Views/WeekOverviewWidget.swift',
]

added_count = 0
skipped_count = 0
error_count = 0

puts "\nAdding missing Swift source files to project..."
puts "-" * 70

files_to_add.each do |relative_path|
  file_name = File.basename(relative_path)
  full_disk_path = "PTPerformance/#{relative_path}"

  # Check if file exists on disk
  unless File.exist?(full_disk_path)
    puts "✗ File not found on disk: #{full_disk_path}"
    error_count += 1
    next
  end

  begin
    # Get or create the appropriate group
    dir_path = File.dirname(relative_path)
    path_components = dir_path == '.' ? [] : dir_path.split('/')
    target_group = path_components.empty? ? main_group : get_or_create_group(main_group, path_components)

    # Check if file reference already exists
    existing_ref = target_group.files.find { |f| f.display_name == file_name }

    if existing_ref
      # Check if it's in the build phase
      in_build = target.source_build_phase.files.any? { |bf| bf.file_ref == existing_ref }

      if in_build
        puts "⊘ Already in project and build: #{relative_path}"
        skipped_count += 1
      else
        # Add to build phase
        target.source_build_phase.add_file_reference(existing_ref)
        puts "✓ Added to build phase: #{relative_path}"
        added_count += 1
      end
    else
      # Create new file reference with full path
      file_ref = target_group.new_reference(relative_path)
      file_ref.name = file_name
      file_ref.source_tree = '<group>'

      # Set the path correctly - relative to the project root
      file_ref.path = relative_path

      # Add to build phase (skip widgets as they have their own target)
      unless relative_path.start_with?('PTPerformanceWidgets')
        target.source_build_phase.add_file_reference(file_ref)
      end

      puts "✓ Added new file: #{relative_path}"
      added_count += 1
    end
  rescue => e
    puts "✗ Error adding #{file_name}: #{e.message}"
    puts "  #{e.backtrace[0..2].join("\n  ")}"
    error_count += 1
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
    error_count += 1
  end
end

puts "=" * 70
puts "Xcode Project Update Complete"
puts "=" * 70
puts "Files added: #{added_count}"
puts "Files skipped: #{skipped_count}"
puts "Errors: #{error_count}"
puts "=" * 70

if error_count == 0
  puts "\n✅ All missing files successfully added to Xcode project!"
  puts "\nTotal: #{files_to_add.length} files processed"
  exit 0
else
  puts "\n⚠️  Some errors occurred. Please review above."
  exit 1
end
