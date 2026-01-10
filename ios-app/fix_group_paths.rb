#!/usr/bin/env ruby
require 'xcodeproj'

puts "Fixing Group Paths in Xcode Project"
puts "=" * 70

# Open the Xcode project
project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main group
main_group = project.main_group['PTPerformance']

if main_group.nil?
  puts "ERROR: Could not find PTPerformance group"
  exit 1
end

def fix_group_paths(group, parent_path = "")
  return if group.nil?

  # Check if this group has a path set
  if group.path && !group.path.empty?
    # If parent path already includes this path, clear it
    if parent_path.end_with?(group.path)
      puts "Clearing duplicate path: #{group.path} (parent: #{parent_path})"
      group.path = nil
      group.source_tree = '<group>'
    elsif parent_path.include?(group.path)
      puts "Clearing nested duplicate path: #{group.path} (parent: #{parent_path})"
      group.path = nil
      group.source_tree = '<group>'
    end
  end

  # Calculate the current full path for children
  current_full_path = if group.path && !group.path.empty?
    parent_path.empty? ? group.path : "#{parent_path}/#{group.path}"
  else
    parent_path
  end

  # Recursively fix children
  group.children.each do |child|
    if child.is_a?(Xcodeproj::Project::Object::PBXGroup)
      fix_group_paths(child, current_full_path)
    end
  end
end

puts "\nScanning and fixing group paths..."
puts "Starting from: #{main_group.name || 'PTPerformance'}"

# Fix paths starting from main group
fix_group_paths(main_group, "")

# Save the project
puts "\nSaving project..."
project.save

puts "=" * 70
puts "✅ Group Paths Fixed!"
puts "=" * 70
puts "Next: Clean build and try again"
puts "=" * 70
