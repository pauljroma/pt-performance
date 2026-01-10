#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get main target and test targets
main_target = project.targets.find { |t| t.name == 'PTPerformance' }
test_target = project.targets.find { |t| t.name == 'PTPerformanceTests' }

puts "=== Removing and Re-adding Build 71 Files ==="

# Helper to recursively find file reference
def find_and_remove_file_ref(group, filename)
  group.children.each do |child|
    if child.is_a?(Xcodeproj::Project::Object::PBXFileReference) && child.path&.end_with?(filename)
      puts "Removing old reference: #{child.path}"
      child.remove_from_project
      return true
    elsif child.is_a?(Xcodeproj::Project::Object::PBXGroup)
      return true if find_and_remove_file_ref(child, filename)
    end
  end
  false
end

# Helper to find or create group
def find_or_create_group(parent_group, group_name, path = nil)
  existing = parent_group.children.find { |g| g.is_a?(Xcodeproj::Project::Object::PBXGroup) && g.display_name == group_name }
  return existing if existing

  group = parent_group.new_group(group_name)
  group.path = path if path
  group
end

# Find PTPerformance group (main source group)
pt_group = project.main_group.children.find { |g| g.display_name == 'PTPerformance' }
unless pt_group
  puts "ERROR: Could not find PTPerformance group"
  exit 1
end

# Find or create subgroups
views_group = find_or_create_group(pt_group, 'Views', 'Views')
scheduling_group = find_or_create_group(views_group, 'Scheduling', 'Scheduling')
services_group = find_or_create_group(pt_group, 'Services', 'Services')

tests_group = find_or_create_group(pt_group, 'Tests', 'Tests')
integration_group = find_or_create_group(tests_group, 'Integration', 'Integration')
unit_group = find_or_create_group(tests_group, 'Unit', 'Unit')

# Files to add with correct paths
files_config = [
  {
    filename: 'CalendarDayCell.swift',
    path: 'Views/Scheduling/CalendarDayCell.swift',
    group: scheduling_group,
    target: main_target
  },
  {
    filename: 'EnhancedSessionCalendarView.swift',
    path: 'Views/Scheduling/EnhancedSessionCalendarView.swift',
    group: scheduling_group,
    target: main_target
  },
  {
    filename: 'SessionQuickLogView.swift',
    path: 'Views/Scheduling/SessionQuickLogView.swift',
    group: scheduling_group,
    target: main_target
  },
  {
    filename: 'ReminderService.swift',
    path: 'Services/ReminderService.swift',
    group: services_group,
    target: main_target
  },
  {
    filename: 'CalendarViewTests.swift',
    path: 'Tests/Integration/CalendarViewTests.swift',
    group: integration_group,
    target: test_target
  },
  {
    filename: 'ReminderTests.swift',
    path: 'Tests/Integration/ReminderTests.swift',
    group: integration_group,
    target: test_target
  },
  {
    filename: 'ReminderServiceTests.swift',
    path: 'Tests/Unit/ReminderServiceTests.swift',
    group: unit_group,
    target: test_target
  }
]

added_count = 0
removed_count = 0

files_config.each do |config|
  # Remove old reference if exists
  if find_and_remove_file_ref(project.main_group, config[:filename])
    removed_count += 1
  end

  # Check if file exists on disk
  full_path = File.join('PTPerformance', config[:path])
  unless File.exist?(full_path)
    puts "⚠️  Warning: File not found: #{full_path}"
    next
  end

  # Add new reference with correct path
  file_ref = config[:group].new_reference(config[:path])
  file_ref.name = config[:filename]

  # Add to build phase
  if config[:target]
    config[:target].source_build_phase.add_file_reference(file_ref)
    puts "✅ Added: #{config[:path]} → #{config[:target].name}"
    added_count += 1
  end
end

# Save project
project.save

puts "\n=== Summary ==="
puts "File references removed: #{removed_count}"
puts "File references added: #{added_count}"
puts "Project saved: #{project_path}"
puts "\n✅ Build 71 files correctly integrated"
