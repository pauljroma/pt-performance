#!/usr/bin/env ruby
# ACP-836: Add Streak Tracking files to Xcode project

require 'xcodeproj'

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'PTPerformance' }
raise "Target 'PTPerformance' not found" unless target

# Find the PTPerformance group
main_group = project.main_group.find_subpath('PTPerformance', false)
raise "PTPerformance group not found" unless main_group

# Helper method to find or create a group
def find_or_create_group(parent, name)
  group = parent.groups.find { |g| g.name == name || g.path == name }
  unless group
    group = parent.new_group(name, name)
    puts "Created group: #{name}"
  end
  group
end

# Helper method to add file to group
def add_file_to_group(group, file_path, target)
  file_name = File.basename(file_path)

  # Check if file already exists in group
  existing = group.files.find { |f| f.path == file_name || f.name == file_name }
  if existing
    puts "File already exists: #{file_name}"
    return existing
  end

  # Add file reference
  file_ref = group.new_reference(file_name)
  file_ref.last_known_file_type = 'sourcecode.swift'

  # Add to target's compile sources
  target.source_build_phase.add_file_reference(file_ref)

  puts "Added: #{file_name}"
  file_ref
end

# Add Model file
puts "\n=== Adding Model Files ==="
models_group = find_or_create_group(main_group, 'Models')
add_file_to_group(models_group, 'Models/StreakRecord.swift', target)

# Add Service file
puts "\n=== Adding Service Files ==="
services_group = find_or_create_group(main_group, 'Services')
add_file_to_group(services_group, 'Services/StreakTrackingService.swift', target)

# Add View files
puts "\n=== Adding View Files ==="
views_group = find_or_create_group(main_group, 'Views')
streaks_group = find_or_create_group(views_group, 'Streaks')

streak_views = [
  'Views/Streaks/StreakDashboardView.swift',
  'Views/Streaks/StreakCalendarView.swift',
  'Views/Streaks/StreakDetailView.swift',
  'Views/Streaks/StreakCardView.swift'
]

streak_views.each do |view_path|
  add_file_to_group(streaks_group, view_path, target)
end

# Save project
project.save
puts "\n=== Project saved successfully ==="
puts "ACP-836: Streak Tracking files added to Xcode project"
