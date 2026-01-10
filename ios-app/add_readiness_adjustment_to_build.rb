#!/usr/bin/env ruby
require 'xcodeproj'

puts "Adding ReadinessAdjustment.swift to Build Phase"
puts "=" * 70

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

# Find the ReadinessAdjustment.swift file reference
file_ref = project.files.find { |f| f.path == 'Models/ReadinessAdjustment.swift' }

if file_ref.nil?
  puts "ERROR: Could not find ReadinessAdjustment.swift file reference"
  exit 1
end

# Check if it's already in the build phase
already_in_build = target.source_build_phase.files.any? { |bf| bf.file_ref == file_ref }

if already_in_build
  puts "✓ ReadinessAdjustment.swift is already in build phase"
else
  puts "Adding ReadinessAdjustment.swift to build phase..."
  target.source_build_phase.add_file_reference(file_ref)
  project.save
  puts "✓ Added successfully!"
end

puts "=" * 70
