#!/usr/bin/env ruby
require 'xcodeproj'

# Open the Xcode project
project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Find the root group
root_group = project.main_group

# Add SentryConfig.swift to the project
file_path = 'PTPerformance/SentryConfig.swift'
file_ref = root_group.new_reference(file_path)

# Add to the compile sources build phase
target.source_build_phase.add_file_reference(file_ref)

# Save the project
project.save

puts "✅ Added SentryConfig.swift to PTPerformance target"
