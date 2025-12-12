#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Find or create the Views/Patient group
views_group = project.main_group.find_subpath('Views', true)
patient_group = views_group.find_subpath('Patient', true) ||  views_group.new_group('Patient')

# Check if file already exists
file_path = 'Views/Patient/SessionSummaryView.swift'
existing_file = patient_group.files.find { |f| f.path == 'SessionSummaryView.swift' }

if existing_file
  puts "✅ SessionSummaryView.swift already in project"
else
  # Add the file reference
  file_ref = patient_group.new_reference(file_path)

  # Add to target's sources build phase
  target.source_build_phase.add_file_reference(file_ref)

  # Save the project
  project.save

  puts "✅ Added SessionSummaryView.swift to Xcode project using xcodeproj gem"
  puts "   Target: #{target.name}"
  puts "   Group: Views/Patient"
end
