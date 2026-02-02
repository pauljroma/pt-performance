#!/usr/bin/env ruby
#
# Script to fix all service file path references in Xcode project
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

# Find all Swift files that should be in Services/ but have incorrect paths
fixed_count = 0

project.files.each do |file_ref|
  next unless file_ref.is_a?(Xcodeproj::Project::Object::PBXFileReference)

  file_name = file_ref.path.to_s
  next unless file_name.end_with?('.swift')
  next if file_name.include?('/')

  # Check if the actual file exists in Services/
  full_path = File.join(Dir.pwd, 'Services', file_name)

  if File.exist?(full_path)
    puts "Fixing path for #{file_name}:"
    puts "  Current: #{file_ref.path}"
    puts "  New:     Services/#{file_name}"

    file_ref.path = "Services/#{file_name}"
    file_ref.name = file_name

    fixed_count += 1
  end
end

# Save the project
project.save

puts "\n--- Complete ---"
puts "Fixed #{fixed_count} file reference(s)"
puts "Project saved successfully"
