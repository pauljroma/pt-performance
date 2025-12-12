#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "🔍 Searching for Models group..."

# Find Models group by searching recursively
def find_group_by_name(group, name)
  return group if group.name == name || group.path == name

  group.groups.each do |subgroup|
    result = find_group_by_name(subgroup, name)
    return result if result
  end

  nil
end

models_group = find_group_by_name(project.main_group, 'Models')

if models_group
  puts "✅ Found Models group: #{models_group.hierarchy_path}"

  # Check if Session.swift already exists
  session_file = models_group.files.find { |f| f.path == 'Session.swift' }

  if session_file
    puts "✅ Session.swift already in project"
  else
    # Add the file
    file_ref = models_group.new_file('Session.swift')

    # Add to main target
    target = project.targets.first
    target.source_build_phase.add_file_reference(file_ref)

    puts "✅ Added Session.swift to project"
    puts "✅ Added to target: #{target.name}"
  end

  project.save
  puts "✅ Project saved successfully"
else
  puts "❌ Models group not found!"
  puts "\nAvailable groups:"
  project.main_group.recursive_children.select { |child| child.is_a?(Xcodeproj::Project::Object::PBXGroup) }.each do |g|
    puts "  - #{g.hierarchy_path}"
  end
end
