#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first
puts "Target: #{target.name}"

# Find Utils group or create it
utils_group = project.main_group['Utils'] || project.main_group.new_group('Utils')

# Add DeviceHelper.swift to Utils group
device_helper_file = utils_group.new_file('Utils/DeviceHelper.swift')

# Add to build phase
target.source_build_phase.add_file_reference(device_helper_file)

# Save the project
project.save

puts "✅ Added DeviceHelper.swift to project"
