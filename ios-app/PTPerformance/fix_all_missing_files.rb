#!/usr/bin/env ruby
#
# Script to fix all missing file references in PTPerformance Xcode project
# Removes invalid references and re-adds them with correct paths
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

# List of files with incorrect paths that need to be fixed
# Format: [incorrect_path_pattern, correct_relative_path, group_path]
files_to_fix = [
  # Smart Notification files
  ['SmartNotificationService.swift', 'Services/SmartNotificationService.swift', 'PTPerformance/Services'],
  ['NotificationSettingsView.swift', 'Views/Settings/NotificationSettingsView.swift', 'PTPerformance/Views/Settings'],
]

# Helper to find a group by path
def find_group(project, path)
  parts = path.split('/')
  group = project.main_group
  parts.each do |part|
    group = group.children.find { |g| g.respond_to?(:name) && (g.name == part || g.path == part) }
    return nil unless group
  end
  group
end

puts "\n--- Removing invalid file references ---"

# Remove invalid build phase entries
target.source_build_phase.files.dup.each do |build_file|
  next unless build_file.file_ref

  file_path = build_file.file_ref.path
  next unless file_path

  # Check if this is one of the files we need to fix
  files_to_fix.each do |pattern, correct_path, group_path|
    if file_path.include?(pattern)
      # Try to get the real path
      begin
        real_path = build_file.file_ref.real_path.to_s
        # If the real path doesn't exist, remove the reference
        unless File.exist?(real_path)
          puts "Removing invalid build reference: #{file_path}"
          build_file.remove_from_project
        end
      rescue
        puts "Removing problematic build reference: #{file_path}"
        build_file.remove_from_project
      end
    end
  end
end

# Also look for and remove references at wrong level in the group hierarchy
project.main_group.recursive_children.each do |child|
  next unless child.is_a?(Xcodeproj::Project::Object::PBXFileReference)

  path = child.path
  next unless path

  files_to_fix.each do |pattern, correct_path, group_path|
    if path == pattern && child.parent
      parent_path = []
      parent = child.parent
      while parent && parent != project.main_group
        parent_path.unshift(parent.name || parent.path)
        parent = parent.parent
      end
      actual_parent = parent_path.join('/')

      # If file is not in the correct group, remove it
      if actual_parent != group_path
        puts "Removing misplaced file reference: #{path} (in #{actual_parent}, should be in #{group_path})"
        child.remove_from_project
      end
    end
  end
end

puts "\n--- Adding correct file references ---"

# Now add the files with correct paths
files_to_fix.each do |pattern, correct_path, group_path|
  full_path = File.join(Dir.pwd, correct_path)

  unless File.exist?(full_path)
    puts "WARNING: File does not exist: #{full_path}"
    next
  end

  # Find the target group
  group = find_group(project, group_path)

  unless group
    puts "WARNING: Could not find group: #{group_path}"
    next
  end

  file_name = File.basename(correct_path)

  # Check if already exists correctly
  existing = group.files.find { |f| f.path == file_name }

  if existing
    puts "File already exists in correct location: #{file_name} in #{group_path}"
    # Make sure it's in build phase
    in_build = target.source_build_phase.files.any? { |bf| bf.file_ref == existing }
    unless in_build
      target.source_build_phase.add_file_reference(existing)
      puts "  -> Added to build phase"
    end
  else
    puts "Adding file: #{file_name} to #{group_path}"
    file_ref = group.new_file(file_name)
    target.source_build_phase.add_file_reference(file_ref)
    puts "  -> Added to group and build phase"
  end
end

# Save the project
project.save

puts "\n--- Complete ---"
puts "Project saved successfully"
