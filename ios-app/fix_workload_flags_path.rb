#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'PTPerformance' }

# Remove the incorrectly added file
target.source_build_phase.files.each do |build_file|
  if build_file.file_ref && build_file.file_ref.path == 'Views/Therapist/WorkloadFlagsView.swift'
    target.source_build_phase.remove_file_reference(build_file.file_ref)
    puts "Removed old reference"
  end
end

# Find the Therapist group (it should already exist under PTPerformance/Views)
ptperf_group = project.main_group['PTPerformance']
views_group = ptperf_group['Views']
therapist_group = views_group['Therapist'] || views_group.new_group('Therapist', 'Views/Therapist')

# Add WorkloadFlagsView.swift with absolute path
file_ref = therapist_group.files.find { |f| f.path == 'WorkloadFlagsView.swift' }

unless file_ref
  file_ref = therapist_group.new_reference('WorkloadFlagsView.swift')
  file_ref.source_tree = '<group>'
  puts "Created new file reference"
end

# Add to build phase if not already there
unless target.source_build_phase.include?(file_ref)
  target.source_build_phase.add_file_reference(file_ref)
  puts "✅ Added WorkloadFlagsView.swift to build phase"
end

project.save
puts "✅ Project saved"
