#!/usr/bin/env ruby
#
# Script to add missing service files back to Xcode project
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

# Find PTPerformance group
pt_group = project.main_group.find_subpath('PTPerformance', true)

unless pt_group
  puts "ERROR: Could not find PTPerformance group"
  exit 1
end

# Find Services group
services_group = pt_group.find_subpath('Services', true)

unless services_group
  puts "ERROR: Could not find Services group"
  exit 1
end

puts "Found Services group"

# Files to add with their paths
files_to_add = [
  'HealthSyncManager.swift',
  'HealthSyncConfig.swift',
  'SiriIntentService.swift',
  'StreakTrackingService.swift',
  'StreakAlertService.swift',
]

added_count = 0

files_to_add.each do |file_name|
  full_path = File.join(Dir.pwd, 'Services', file_name)

  unless File.exist?(full_path)
    puts "WARNING: File does not exist: #{full_path}"
    next
  end

  # Check if already in project
  existing = services_group.files.find { |f| f.path&.include?(file_name) }

  if existing
    puts "File already exists in project: #{file_name}"
    # Make sure it's in build phase
    in_build = target.source_build_phase.files.any? { |bf| bf.file_ref == existing }
    unless in_build
      target.source_build_phase.add_file_reference(existing)
      puts "  -> Added to build phase"
      added_count += 1
    end
  else
    puts "Adding file: #{file_name}"
    file_ref = services_group.new_file(file_name)
    file_ref.path = "Services/#{file_name}"
    file_ref.name = file_name
    target.source_build_phase.add_file_reference(file_ref)
    puts "  -> Added to group and build phase"
    added_count += 1
  end
end

# Save the project
project.save

puts "\n--- Complete ---"
puts "Added #{added_count} file(s)"
puts "Project saved successfully"
