#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get main target and test targets
main_target = project.targets.find { |t| t.name == 'PTPerformance' }
test_target = project.targets.find { |t| t.name == 'PTPerformanceTests' }

# Find or create groups
def find_or_create_group(project, path_components)
  group = project.main_group
  path_components.each do |component|
    group = group.children.find { |g| g.display_name == component } || group.new_group(component)
  end
  group
end

# Get groups
views_group = find_or_create_group(project, ['PTPerformance', 'Views'])
scheduling_group = views_group.children.find { |g| g.display_name == 'Scheduling' } || views_group.new_group('Scheduling')
services_group = find_or_create_group(project, ['PTPerformance', 'Services'])
tests_group = find_or_create_group(project, ['PTPerformance', 'Tests'])
integration_tests_group = tests_group.children.find { |g| g.display_name == 'Integration' } || tests_group.new_group('Integration')
unit_tests_group = tests_group.children.find { |g| g.display_name == 'Unit' } || tests_group.new_group('Unit')

puts "=== Adding Build 71 Files to Xcode Project ==="

# Files to add
files_to_add = [
  # Views/Scheduling
  {
    path: 'PTPerformance/Views/Scheduling/CalendarDayCell.swift',
    group: scheduling_group,
    target: main_target
  },
  {
    path: 'PTPerformance/Views/Scheduling/EnhancedSessionCalendarView.swift',
    group: scheduling_group,
    target: main_target
  },
  {
    path: 'PTPerformance/Views/Scheduling/SessionQuickLogView.swift',
    group: scheduling_group,
    target: main_target
  },
  # Services
  {
    path: 'PTPerformance/Services/ReminderService.swift',
    group: services_group,
    target: main_target
  },
  # Tests/Integration
  {
    path: 'PTPerformance/Tests/Integration/CalendarViewTests.swift',
    group: integration_tests_group,
    target: test_target
  },
  {
    path: 'PTPerformance/Tests/Integration/ReminderTests.swift',
    group: integration_tests_group,
    target: test_target
  },
  # Tests/Unit
  {
    path: 'PTPerformance/Tests/Unit/ReminderServiceTests.swift',
    group: unit_tests_group,
    target: test_target
  }
]

added_count = 0
skipped_count = 0

files_to_add.each do |file_info|
  file_path = file_info[:path]
  group = file_info[:group]
  target = file_info[:target]

  # Check if file already exists in project
  existing_file = group.children.find { |f| f.path == File.basename(file_path) }

  if existing_file
    puts "⏭️  Skipped (already exists): #{file_path}"
    skipped_count += 1
    next
  end

  # Check if file exists on disk
  unless File.exist?(file_path)
    puts "⚠️  Warning: File not found on disk: #{file_path}"
    next
  end

  # Add file reference to group
  file_ref = group.new_file(file_path)

  # Add to build phase (sources or test sources)
  if target
    target.source_build_phase.add_file_reference(file_ref)
    puts "✅ Added: #{file_path} → #{target.name}"
    added_count += 1
  else
    puts "⚠️  Warning: No target specified for #{file_path}"
  end
end

# Save project
project.save

puts "\n=== Summary ==="
puts "Files added: #{added_count}"
puts "Files skipped: #{skipped_count}"
puts "Project saved: #{project_path}"
puts "\n✅ Build 71 files successfully added to Xcode project"
