#!/usr/bin/env ruby
#
# Script to fix Services group path in Xcode project
#

require 'xcodeproj'

# Open the project
project_path = 'PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "Opened project: #{project_path}"

# Find PTPerformance group
pt_group = project.main_group.find_subpath('PTPerformance', true)

unless pt_group
  puts "ERROR: Could not find PTPerformance group"
  exit 1
end

puts "Found PTPerformance group"

# Find Services group inside PTPerformance
services_group = pt_group.children.find { |c| (c.name || c.path) == 'Services' && c.is_a?(Xcodeproj::Project::Object::PBXGroup) }

unless services_group
  puts "ERROR: Could not find Services group in PTPerformance"
  exit 1
end

puts "Found Services group (UUID: #{services_group.uuid})"
puts "Current path: #{services_group.path.inspect}"
puts "Current name: #{services_group.name.inspect}"

# Set the path to Services so files can be just their filename
services_group.path = 'Services'
puts "Set Services group path to 'Services'"

# Save the project
project.save

puts "\n--- Complete ---"
puts "Project saved successfully"
