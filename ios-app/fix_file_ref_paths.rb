#!/usr/bin/env ruby
require 'xcodeproj'

puts "Fixing File Reference Paths"
puts "=" * 70

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

# Get all file references
file_refs = project.files

fixed_count = 0

# Check each file for duplicate path components
file_refs.each do |file_ref|
  next unless file_ref.path

  # Check if the path has duplicate components
  if file_ref.path.include?('/Views/') || file_ref.path.include?('/Models/') ||
     file_ref.path.include?('/Services/') || file_ref.path.include?('/ViewModels/')

    # Get the parent group
    parent = file_ref.parent

    # Calculate what the full path would be based on group hierarchy
    group_path_components = []
    current = parent
    while current && current != project.main_group
      if current.path && !current.path.empty?
        group_path_components.unshift(current.path)
      end
      current = current.parent
    end

    group_path = group_path_components.join('/')
    file_name = File.basename(file_ref.path)

    # Check if file_ref.path already includes the group path
    if file_ref.path.include?(group_path) && group_path != ''
      puts "\nFound problematic file reference:"
      puts "  File: #{file_name}"
      puts "  Current path: #{file_ref.path}"
      puts "  Group path: #{group_path}"
      puts "  Fixing to: #{file_name}"

      # Fix: Set path to just the filename
      file_ref.path = file_name
      fixed_count += 1
    end
  end
end

# Save if we made changes
if fixed_count > 0
  puts "\nSaving project..."
  project.save
  puts "=" * 70
  puts "✅ Fixed #{fixed_count} file reference paths!"
  puts "=" * 70
else
  puts "\n=" * 70
  puts "No problematic file references found."
  puts "=" * 70
end
