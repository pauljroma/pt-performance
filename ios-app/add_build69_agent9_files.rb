#!/usr/bin/env ruby

# add_build69_agent9_files.rb
# Build 69 - Agent 9: Safety - Notifications & QA
# Adds notification service files and tests to Xcode project

require 'xcodeproj'

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'PTPerformance' }
test_target = project.targets.find { |t| t.name == 'PTPerformanceTests' }

# Find main groups
main_group = project.main_group
services_group = main_group['PTPerformance']&.groups&.find { |g| g.name == 'Services' }
tests_group = main_group['PTPerformanceTests'] || main_group.new_group('PTPerformanceTests')
integration_tests_group = tests_group['Integration'] || tests_group.new_group('Integration')

puts "📦 Adding Build 69 Agent 9 files to Xcode project..."

# Files to add
files_to_add = [
  {
    path: 'PTPerformance/Services/PushNotificationService.swift',
    group: services_group,
    target: target
  },
  {
    path: 'PTPerformance/Tests/Integration/WorkloadFlagTests.swift',
    group: integration_tests_group,
    target: test_target
  },
  {
    path: 'PTPerformance/Tests/Integration/NotificationDeliveryTests.swift',
    group: integration_tests_group,
    target: test_target
  }
]

added_count = 0
skipped_count = 0

files_to_add.each do |file_info|
  file_path = file_info[:path]
  group = file_info[:group]
  target = file_info[:target]

  # Check if file exists
  unless File.exist?(file_path)
    puts "⚠️  File not found: #{file_path}"
    next
  end

  # Check if already in project
  existing_ref = group&.files&.find { |f| f.path == File.basename(file_path) }

  if existing_ref
    puts "⏭️  Already exists: #{File.basename(file_path)}"
    skipped_count += 1
    next
  end

  # Add file reference
  if group && target
    file_ref = group.new_file(File.absolute_path(file_path))
    target.add_file_references([file_ref])
    puts "✅ Added: #{File.basename(file_path)}"
    added_count += 1
  else
    puts "❌ Failed to add: #{File.basename(file_path)} (group or target not found)"
  end
end

# Save the project
project.save

puts "\n" + "="*50
puts "📊 Summary:"
puts "  ✅ Added: #{added_count} files"
puts "  ⏭️  Skipped: #{skipped_count} files"
puts "  🎯 Total processed: #{files_to_add.length} files"
puts "="*50
puts "\n✨ Xcode project updated successfully!"
