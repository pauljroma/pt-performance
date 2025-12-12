#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first
puts "Target: #{target.name}"

# Get the main group
main_group = project.main_group

# Add Config.swift if not already present
config_ref = main_group.files.find { |f| f.path == 'Config.swift' }
unless config_ref
  config_ref = main_group.new_reference('Config.swift')
  config_ref.last_known_file_type = 'sourcecode.swift'

  # Add to target sources
  target.source_build_phase.add_file_reference(config_ref)
  puts "Added Config.swift to project"
else
  puts "Config.swift already in project"
end

# Save the project
project.save
puts "\nProject saved successfully!"
