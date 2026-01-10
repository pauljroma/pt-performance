#!/usr/bin/env ruby
require 'xcodeproj'

# Open the project
project_path = 'PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'PTPerformance' }

# Find or create Components group
components_group = project.main_group.find_subpath('PTPerformance/Components', true)

# Add the new file
file_path = 'Components/ExerciseCompactRow.swift'
file_ref = components_group.new_reference(file_path)

# Add to build phase
target.source_build_phase.add_file_reference(file_ref)

# Save the project
project.save

puts "✅ Successfully added ExerciseCompactRow.swift to Xcode project"
