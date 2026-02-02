#!/usr/bin/env ruby
#
# Script to fix remaining service file paths
#

require 'xcodeproj'

# Open the project
project_path = 'PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "Opened project: #{project_path}"

# Find all file references with Services/Services or Services/ prefix
# that are inside a Services group with path = Services
fixed_count = 0

project.files.each do |file_ref|
  next unless file_ref.is_a?(Xcodeproj::Project::Object::PBXFileReference)

  current_path = file_ref.path.to_s

  # Fix files that have Services/ prefix
  if current_path.start_with?('Services/')
    file_name = current_path.sub('Services/', '')

    # Check if the file exists in the Services directory
    full_path = File.join(Dir.pwd, 'Services', file_name)

    if File.exist?(full_path)
      puts "Fixing: #{current_path} -> #{file_name}"
      file_ref.path = file_name
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
