#!/usr/bin/env ruby
#
# Script to fix file path references in Xcode project
# Ensures files have correct path= attributes
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

# Files to fix with their correct paths
files_to_fix = {
  'SmartNotificationService.swift' => 'Services/SmartNotificationService.swift',
  'NotificationSettingsView.swift' => 'Views/Settings/NotificationSettingsView.swift'
}

# Find and fix file references
fixed_count = 0

project.files.each do |file_ref|
  next unless file_ref.is_a?(Xcodeproj::Project::Object::PBXFileReference)

  file_name = File.basename(file_ref.path.to_s)

  if files_to_fix.key?(file_name)
    correct_path = files_to_fix[file_name]
    current_path = file_ref.path.to_s

    # Check if the path needs to be fixed
    if current_path != correct_path && current_path == file_name
      puts "Fixing path for #{file_name}:"
      puts "  Current: #{current_path}"
      puts "  New:     #{correct_path}"

      # Update the file reference
      file_ref.path = correct_path
      file_ref.name = file_name

      fixed_count += 1
    end
  end
end

# Save the project
project.save

puts "\n--- Complete ---"
puts "Fixed #{fixed_count} file reference(s)"
puts "Project saved successfully"
