#!/usr/bin/env ruby
#
# Script to fix double path references (Services/Services/) in Xcode project
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

puts "Services group path: #{services_group.path.inspect}"

# Fix files that have wrong paths inside Services group
fixed_count = 0

services_group.files.each do |file_ref|
  next unless file_ref.is_a?(Xcodeproj::Project::Object::PBXFileReference)

  current_path = file_ref.path.to_s
  file_name = File.basename(current_path)

  # If path starts with Services/ when already inside Services group, fix it
  if current_path.start_with?('Services/')
    correct_path = file_name
    puts "Fixing double path: #{current_path} -> #{correct_path}"
    file_ref.path = correct_path
    file_ref.name = file_name if file_ref.name && file_ref.name != file_name
    fixed_count += 1
  end
end

# Save the project
project.save

puts "\n--- Complete ---"
puts "Fixed #{fixed_count} file reference(s)"
puts "Project saved successfully"
