#!/usr/bin/env ruby
# Widget Integration Script for PTPerformance
# Adds all widget-related files to the Xcode project

require 'xcodeproj'

PROJECT_PATH = '/Users/expo/pt-performance/ios-app/PTPerformance/PTPerformance.xcodeproj'
PROJECT_DIR = '/Users/expo/pt-performance/ios-app/PTPerformance'

puts "Opening Xcode project..."
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find the main app target
main_target = project.targets.find { |t| t.name == 'PTPerformance' }
unless main_target
  puts "ERROR: Could not find PTPerformance target"
  exit 1
end
puts "Found main target: #{main_target.name}"

# Check if widget extension target exists
widget_target = project.targets.find { |t| t.name == 'PTPerformanceWidgets' }

unless widget_target
  puts "\nCreating PTPerformanceWidgets extension target..."

  # Create the widget extension target
  widget_target = project.new_target(:app_extension, 'PTPerformanceWidgets', :ios, '16.0')
  widget_target.product_name = 'PTPerformanceWidgetsExtension'

  # Set build settings for widget extension
  widget_target.build_configurations.each do |config|
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.ptperformance.app.widgets'
    config.build_settings['INFOPLIST_FILE'] = 'PTPerformanceWidgets/Info.plist'
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'PTPerformanceWidgets/PTPerformanceWidgets.entitlements'
    config.build_settings['ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME'] = 'WidgetBackground'
    config.build_settings['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
    config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
    config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
    config.build_settings['SKIP_INSTALL'] = 'YES'
    config.build_settings['SWIFT_VERSION'] = '5.0'
  end

  # Add widget extension as dependency of main app
  main_target.add_dependency(widget_target)

  # Embed widget extension in main app
  embed_phase = main_target.build_phases.find { |p| p.is_a?(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase) && p.name == 'Embed App Extensions' }
  unless embed_phase
    embed_phase = main_target.new_copy_files_build_phase('Embed App Extensions')
    embed_phase.dst_subfolder_spec = '13' # PlugIns folder
  end
  embed_phase.add_file_reference(widget_target.product_reference)

  puts "Created widget extension target"
end

# Helper to find or create a group
def find_or_create_group(project, path_components)
  current_group = project.main_group
  path_components.each do |component|
    next_group = current_group.children.find { |g| g.respond_to?(:name) && g.name == component }
    unless next_group
      next_group = current_group.new_group(component)
    end
    current_group = next_group
  end
  current_group
end

# Helper to check if file is already in project
def file_in_project?(group, filename)
  group.files.any? { |f| f.path == filename || f.name == filename }
end

# Files to add to MAIN TARGET (Shared code accessible from main app)
shared_files_main = [
  { path: 'Shared/Models/WidgetWorkout.swift', group: ['PTPerformance', 'Shared', 'Models'] },
  { path: 'Shared/Models/WidgetReadiness.swift', group: ['PTPerformance', 'Shared', 'Models'] },
  { path: 'Shared/Models/WidgetAdherence.swift', group: ['PTPerformance', 'Shared', 'Models'] },
  { path: 'Shared/Models/WidgetStreak.swift', group: ['PTPerformance', 'Shared', 'Models'] },
  { path: 'Shared/DataStore/SharedDataStore.swift', group: ['PTPerformance', 'Shared', 'DataStore'] },
  { path: 'Services/WidgetBridgeService.swift', group: ['PTPerformance', 'Services'] },
]

# Files for WIDGET TARGET ONLY
widget_files = [
  { path: 'PTPerformanceWidgets/PTPerformanceWidgets.swift', group: ['PTPerformanceWidgets'] },
  { path: 'PTPerformanceWidgets/Components/MiniTrendChart.swift', group: ['PTPerformanceWidgets', 'Components'] },
  { path: 'PTPerformanceWidgets/Components/ReadinessBadge.swift', group: ['PTPerformanceWidgets', 'Components'] },
  { path: 'PTPerformanceWidgets/Components/WidgetColors.swift', group: ['PTPerformanceWidgets', 'Components'] },
  { path: 'PTPerformanceWidgets/Providers/DailySummaryProvider.swift', group: ['PTPerformanceWidgets', 'Providers'] },
  { path: 'PTPerformanceWidgets/Providers/ReadinessProvider.swift', group: ['PTPerformanceWidgets', 'Providers'] },
  { path: 'PTPerformanceWidgets/Providers/RecoveryDashboardProvider.swift', group: ['PTPerformanceWidgets', 'Providers'] },
  { path: 'PTPerformanceWidgets/Providers/StreakProvider.swift', group: ['PTPerformanceWidgets', 'Providers'] },
  { path: 'PTPerformanceWidgets/Providers/TodayWorkoutProvider.swift', group: ['PTPerformanceWidgets', 'Providers'] },
  { path: 'PTPerformanceWidgets/Providers/WeekOverviewProvider.swift', group: ['PTPerformanceWidgets', 'Providers'] },
  { path: 'PTPerformanceWidgets/Views/DailySummaryWidget.swift', group: ['PTPerformanceWidgets', 'Views'] },
  { path: 'PTPerformanceWidgets/Views/ReadinessWidget.swift', group: ['PTPerformanceWidgets', 'Views'] },
  { path: 'PTPerformanceWidgets/Views/RecoveryDashboardWidget.swift', group: ['PTPerformanceWidgets', 'Views'] },
  { path: 'PTPerformanceWidgets/Views/StreakWidget.swift', group: ['PTPerformanceWidgets', 'Views'] },
  { path: 'PTPerformanceWidgets/Views/TodayWorkoutWidget.swift', group: ['PTPerformanceWidgets', 'Views'] },
  { path: 'PTPerformanceWidgets/Views/WeekOverviewWidget.swift', group: ['PTPerformanceWidgets', 'Views'] },
]

# Shared files that need to be in BOTH targets
shared_files_both = [
  { path: 'Shared/Models/WidgetWorkout.swift', group: ['PTPerformanceWidgets', 'Shared', 'Models'] },
  { path: 'Shared/Models/WidgetReadiness.swift', group: ['PTPerformanceWidgets', 'Shared', 'Models'] },
  { path: 'Shared/Models/WidgetAdherence.swift', group: ['PTPerformanceWidgets', 'Shared', 'Models'] },
  { path: 'Shared/Models/WidgetStreak.swift', group: ['PTPerformanceWidgets', 'Shared', 'Models'] },
  { path: 'Shared/DataStore/SharedDataStore.swift', group: ['PTPerformanceWidgets', 'Shared', 'DataStore'] },
]

added_main = 0
added_widget = 0
skipped = 0

puts "\n--- Adding files to Main Target (PTPerformance) ---"

shared_files_main.each do |file_info|
  full_path = File.join(PROJECT_DIR, file_info[:path])
  unless File.exist?(full_path)
    puts "WARNING: File not found: #{file_info[:path]}"
    next
  end

  group = find_or_create_group(project, file_info[:group])
  filename = File.basename(file_info[:path])

  if file_in_project?(group, filename)
    puts "SKIP: #{file_info[:path]} (already in project)"
    skipped += 1
    next
  end

  file_ref = group.new_reference(full_path)
  file_ref.name = filename
  main_target.add_file_references([file_ref])
  puts "ADDED: #{file_info[:path]} -> Main Target"
  added_main += 1
end

puts "\n--- Adding files to Widget Target (PTPerformanceWidgets) ---"

widget_files.each do |file_info|
  full_path = File.join(PROJECT_DIR, file_info[:path])
  unless File.exist?(full_path)
    puts "WARNING: File not found: #{file_info[:path]}"
    next
  end

  group = find_or_create_group(project, file_info[:group])
  filename = File.basename(file_info[:path])

  if file_in_project?(group, filename)
    puts "SKIP: #{file_info[:path]} (already in project)"
    skipped += 1
    next
  end

  file_ref = group.new_reference(full_path)
  file_ref.name = filename
  widget_target.add_file_references([file_ref])
  puts "ADDED: #{file_info[:path]} -> Widget Target"
  added_widget += 1
end

puts "\n--- Adding shared files to Widget Target ---"

shared_files_both.each do |file_info|
  full_path = File.join(PROJECT_DIR, file_info[:path])
  unless File.exist?(full_path)
    puts "WARNING: File not found: #{file_info[:path]}"
    next
  end

  group = find_or_create_group(project, file_info[:group])
  filename = File.basename(file_info[:path])

  if file_in_project?(group, filename)
    puts "SKIP: #{file_info[:path]} (already in widget project)"
    skipped += 1
    next
  end

  file_ref = group.new_reference(full_path)
  file_ref.name = filename
  widget_target.add_file_references([file_ref])
  puts "ADDED: #{file_info[:path]} -> Widget Target (shared)"
  added_widget += 1
end

# Add Info.plist and entitlements to widget group (not to build phase)
widget_group = find_or_create_group(project, ['PTPerformanceWidgets'])

info_plist_path = File.join(PROJECT_DIR, 'PTPerformanceWidgets/Info.plist')
if File.exist?(info_plist_path) && !file_in_project?(widget_group, 'Info.plist')
  file_ref = widget_group.new_reference(info_plist_path)
  file_ref.name = 'Info.plist'
  puts "ADDED: PTPerformanceWidgets/Info.plist (resource)"
end

entitlements_path = File.join(PROJECT_DIR, 'PTPerformanceWidgets/PTPerformanceWidgets.entitlements')
if File.exist?(entitlements_path) && !file_in_project?(widget_group, 'PTPerformanceWidgets.entitlements')
  file_ref = widget_group.new_reference(entitlements_path)
  file_ref.name = 'PTPerformanceWidgets.entitlements'
  puts "ADDED: PTPerformanceWidgets/PTPerformanceWidgets.entitlements (resource)"
end

puts "\nSaving project..."
project.save

puts "\n=========================================="
puts "INTEGRATION COMPLETE"
puts "=========================================="
puts "Files added to Main Target: #{added_main}"
puts "Files added to Widget Target: #{added_widget}"
puts "Files skipped (already present): #{skipped}"
puts ""
puts "Next steps:"
puts "1. Increment build number"
puts "2. Build and archive the app"
puts "3. Upload to TestFlight"
