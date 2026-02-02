#!/usr/bin/env ruby
#
# Script to add Siri Shortcuts files (ACP-826) to PTPerformance Xcode project
#
# Files added:
#   - Intents/StartWorkoutIntent.swift
#   - Intents/LogExerciseIntent.swift
#   - Intents/CheckReadinessIntent.swift
#   - Intents/PTPerformanceShortcuts.swift
#   - Services/SiriIntentService.swift
#   - Views/Settings/SiriTipsView.swift
#
# Usage: ruby add_siri_shortcuts_files.rb
#

require 'xcodeproj'

# Open the project
project_path = 'PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "Opened project: #{project_path}"

# Get the main target
target = project.targets.find { |t| t.name == 'PTPerformance' }

unless target
  puts "ERROR: Could not find PTPerformance target"
  exit 1
end

puts "Found target: #{target.name}"

# Find or create the PTPerformance group
pt_group = project.main_group.find_subpath('PTPerformance', true)

unless pt_group
  puts "ERROR: Could not find PTPerformance group"
  exit 1
end

puts "Found PTPerformance group"

# Helper function to add a file to a group and build phase
def add_file_to_project(project, target, parent_group, relative_path, file_name)
  # Check if file already exists in project
  existing = parent_group.files.find { |f| f.path == file_name }

  if existing
    puts "  File already in project: #{file_name}"
    return false
  end

  # Add the file reference
  file_ref = parent_group.new_reference(file_name)
  file_ref.last_known_file_type = 'sourcecode.swift'

  # Add to build phase
  target.source_build_phase.add_file_reference(file_ref)

  puts "  Added: #{file_name}"
  return true
end

added_count = 0

# ============================================
# Add Intents Group and Files
# ============================================
puts "\nCreating Intents group..."

intents_group = pt_group.find_subpath('Intents', false)
if intents_group.nil?
  intents_group = pt_group.new_group('Intents', 'Intents')
  puts "  Created Intents group"
else
  puts "  Intents group already exists"
end

intents_files = [
  'StartWorkoutIntent.swift',
  'LogExerciseIntent.swift',
  'CheckReadinessIntent.swift',
  'PTPerformanceShortcuts.swift'
]

puts "Adding Intents files..."
intents_files.each do |file_name|
  if add_file_to_project(project, target, intents_group, 'Intents', file_name)
    added_count += 1
  end
end

# ============================================
# Add SiriIntentService to Services Group
# ============================================
puts "\nAdding to Services group..."

services_group = pt_group.find_subpath('Services', false)
if services_group.nil?
  services_group = pt_group.new_group('Services', 'Services')
  puts "  Created Services group"
end

if add_file_to_project(project, target, services_group, 'Services', 'SiriIntentService.swift')
  added_count += 1
end

# ============================================
# Add SiriTipsView to Views/Settings Group
# ============================================
puts "\nAdding to Views/Settings group..."

views_group = pt_group.find_subpath('Views', false)
if views_group.nil?
  views_group = pt_group.new_group('Views', 'Views')
  puts "  Created Views group"
end

settings_group = views_group.find_subpath('Settings', false)
if settings_group.nil?
  settings_group = views_group.new_group('Settings', 'Settings')
  puts "  Created Settings group"
end

if add_file_to_project(project, target, settings_group, 'Views/Settings', 'SiriTipsView.swift')
  added_count += 1
end

# ============================================
# Save the Project
# ============================================
project.save

puts ""
puts "=" * 50
puts "ACP-826: Siri Shortcuts Integration Complete"
puts "=" * 50
puts "Successfully added #{added_count} file(s) to Xcode project"
puts ""
puts "Files added:"
puts "  - Intents/StartWorkoutIntent.swift"
puts "  - Intents/LogExerciseIntent.swift"
puts "  - Intents/CheckReadinessIntent.swift"
puts "  - Intents/PTPerformanceShortcuts.swift"
puts "  - Services/SiriIntentService.swift"
puts "  - Views/Settings/SiriTipsView.swift"
puts ""
puts "Next steps:"
puts "  1. Open Xcode and build the project"
puts "  2. Test Siri commands: 'Hey Siri, start my workout in PT Performance'"
puts "  3. Add Siri button to Settings view for discoverability"
puts ""
