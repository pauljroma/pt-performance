#!/usr/bin/env ruby
#
# Script to add ExerciseExplanationService.swift and ArmCareEducationService.swift
# to the PTPerformance Xcode project
#
# Created by Content & Polish Sprint Agent 4
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

# Find or create Services group
services_group = project.main_group.find_subpath('PTPerformance/Services', true)

unless services_group
  puts "ERROR: Could not find Services group"
  exit 1
end

puts "Found Services group"

# Files to add
files_to_add = [
  'Services/ExerciseExplanationService.swift',
  'Services/ArmCareEducationService.swift'
]

added_count = 0

files_to_add.each do |file_path|
  file_name = File.basename(file_path)

  # Check if file already exists in project
  existing = services_group.files.find { |f| f.path == file_name }

  if existing
    puts "File already in project: #{file_name}"
    next
  end

  # Add the file reference
  file_ref = services_group.new_reference(file_name)
  file_ref.last_known_file_type = 'sourcecode.swift'

  # Add to build phase
  target.source_build_phase.add_file_reference(file_ref)

  puts "Added to project: #{file_name}"
  added_count += 1
end

# Save the project
project.save

puts ""
puts "Successfully added #{added_count} file(s) to Xcode project"
puts "Files are now in the Services group and build phase"
