#!/usr/bin/env ruby
require 'xcodeproj'

puts "Adding Missing Swift Files to Xcode Project"
puts "=" * 70

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main app target (not test or widget targets)
target = project.targets.find { |t| t.name == 'PTPerformance' && t.product_type == 'com.apple.product-type.application' }

if target.nil?
  puts "ERROR: Could not find main PTPerformance app target"
  exit 1
end

main_group = project.main_group['PTPerformance'] || project.main_group.new_group('PTPerformance')

# Helper to get or create nested groups with proper path setup
def get_or_create_group(parent, path_components)
  current_group = parent
  path_components.each do |component|
    existing = current_group[component]
    if existing
      current_group = existing
    else
      current_group = current_group.new_group(component)
      current_group.path = component
    end
  end
  current_group
end

# Define all missing files with their relative paths from PTPerformance/
files_to_add = [
  # Components
  { file: 'SmartSchedulingSuggestionCard.swift', path: 'Components' },

  # Models
  { file: 'AR60ReadinessScore.swift', path: 'Models' },
  { file: 'JournalEntry.swift', path: 'Models' },

  # ViewModels
  { file: 'HRVInsightsViewModel.swift', path: 'ViewModels' },
  { file: 'ProtocolBuilderViewModel.swift', path: 'ViewModels' },
  { file: 'ReadinessScoreViewModel.swift', path: 'ViewModels' },
  { file: 'SleepInsightsViewModel.swift', path: 'ViewModels' },
  { file: 'WorkoutSummaryDataAdapter.swift', path: 'ViewModels' },

  # Services
  { file: 'AudioRecordingService.swift', path: 'Services' },
  { file: 'ReadinessScoreService.swift', path: 'Services' },
  { file: 'SmartSchedulingService.swift', path: 'Services' },
  { file: 'HealthDataGapDetector.swift', path: 'Services/HealthKit' },
  { file: 'HealthKitConflictResolver.swift', path: 'Services/HealthKit' },

  # Views - Achievements
  { file: 'AchievementRecommendations.swift', path: 'Views/Achievements' },
  { file: 'AchievementShowcaseView.swift', path: 'Views/Achievements' },
  { file: 'UpNextAchievementsSection.swift', path: 'Views/Achievements' },

  # Views - Celebrations
  { file: 'EnhancedWorkoutSummaryView.swift', path: 'Views/Celebrations' },

  # Views - Evidence
  { file: 'EvidenceDetailSheet.swift', path: 'Views/Evidence' },

  # Views - Health
  { file: 'HRVInsightsView.swift', path: 'Views/Health' },
  { file: 'SleepInsightsView.swift', path: 'Views/Health' },

  # Views - Journal
  { file: 'AudioHealthJournalView.swift', path: 'Views/Journal' },
  { file: 'JournalEntryDetailView.swift', path: 'Views/Journal' },
  { file: 'JournalEntryRecordingView.swift', path: 'Views/Journal' },

  # Views - Nutrition/Components
  { file: 'CalorieSurplusDeficitIndicator.swift', path: 'Views/Nutrition/Components' },
  { file: 'MealTimeline.swift', path: 'Views/Nutrition/Components' },
  { file: 'ProteinTimingChart.swift', path: 'Views/Nutrition/Components' },

  # Views - Protocol
  { file: 'AthletePlanView.swift', path: 'Views/Protocol' },
  { file: 'ProtocolBuilderView.swift', path: 'Views/Protocol' },
  { file: 'ProtocolTemplateCard.swift', path: 'Views/Protocol' },
  { file: 'TaskCustomizationSheet.swift', path: 'Views/Protocol' },

  # Views - Settings
  { file: 'UnifiedSettingsView.swift', path: 'Views/Settings' },

  # Views - Templates
  { file: 'TemplateLibraryView.swift', path: 'Views/Templates' },

  # Views - Therapist
  { file: 'SafetyIncidentDetailSheet.swift', path: 'Views/Therapist' },

  # Views - Today
  { file: 'SmartSchedulingHomeCard.swift', path: 'Views/Today' },

  # PTPerformanceWidgets
  { file: 'PTPerformanceWidgets.swift', path: 'PTPerformanceWidgets' },
  { file: 'MiniTrendChart.swift', path: 'PTPerformanceWidgets/Components' },
  { file: 'ReadinessBadge.swift', path: 'PTPerformanceWidgets/Components' },
  { file: 'WidgetColors.swift', path: 'PTPerformanceWidgets/Components' },
  { file: 'DailySummaryProvider.swift', path: 'PTPerformanceWidgets/Providers' },
  { file: 'ReadinessProvider.swift', path: 'PTPerformanceWidgets/Providers' },
  { file: 'RecoveryDashboardProvider.swift', path: 'PTPerformanceWidgets/Providers' },
  { file: 'StreakProvider.swift', path: 'PTPerformanceWidgets/Providers' },
  { file: 'TodayWorkoutProvider.swift', path: 'PTPerformanceWidgets/Providers' },
  { file: 'WeekOverviewProvider.swift', path: 'PTPerformanceWidgets/Providers' },
  { file: 'DailySummaryWidget.swift', path: 'PTPerformanceWidgets/Views' },
  { file: 'ReadinessWidget.swift', path: 'PTPerformanceWidgets/Views' },
  { file: 'RecoveryDashboardWidget.swift', path: 'PTPerformanceWidgets/Views' },
  { file: 'StreakWidget.swift', path: 'PTPerformanceWidgets/Views' },
  { file: 'TodayWorkoutWidget.swift', path: 'PTPerformanceWidgets/Views' },
  { file: 'WeekOverviewWidget.swift', path: 'PTPerformanceWidgets/Views' },
]

added_count = 0
skipped_count = 0
error_count = 0

puts "\nAdding missing Swift source files to project..."
puts "-" * 70

files_to_add.each do |file_info|
  file_name = file_info[:file]
  relative_path = file_info[:path]
  full_disk_path = "PTPerformance/#{relative_path}/#{file_name}"

  # Check if file exists on disk
  unless File.exist?(full_disk_path)
    puts "✗ File not found on disk: #{full_disk_path}"
    error_count += 1
    next
  end

  begin
    # Get or create the appropriate group
    path_components = relative_path.split('/')
    target_group = get_or_create_group(main_group, path_components)

    # Check if file reference already exists in the group
    existing_ref = target_group.files.find { |f| f.path == file_name }

    if existing_ref
      # Check if it's in the build phase
      in_build = target.source_build_phase.files.any? { |bf| bf.file_ref == existing_ref }

      if in_build
        puts "⊘ Already in project and build: #{file_name}"
        skipped_count += 1
      else
        # Add to build phase
        target.source_build_phase.add_file_reference(existing_ref)
        puts "✓ Added to build phase: #{file_name}"
        added_count += 1
      end
    else
      # Create new file reference - use new_reference to set path properly
      file_ref = target_group.new_reference(file_name)
      file_ref.source_tree = '<group>'

      # Add to build phase (skip widgets as they have their own target)
      unless relative_path.start_with?('PTPerformanceWidgets')
        target.source_build_phase.add_file_reference(file_ref)
      end

      puts "✓ Added new file: #{relative_path}/#{file_name}"
      added_count += 1
    end
  rescue => e
    puts "✗ Error adding #{file_name}: #{e.message}"
    puts "  #{e.backtrace.first}"
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
    puts "  The files were added to the in-memory project but couldn't be saved."
    puts "  This is likely due to a pre-existing consistency issue in the Xcode project."
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
