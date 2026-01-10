#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'PTPerformance' }

# Find the ViewModels group
ptperf_group = project.main_group['PTPerformance']
viewmodels_group = ptperf_group['ViewModels']

unless viewmodels_group
  viewmodels_group = ptperf_group.new_group('ViewModels')
  viewmodels_group.path = 'ViewModels'
  viewmodels_group.source_tree = '<group>'
end

# Add WorkloadFlagsViewModel.swift
file_ref = viewmodels_group.new_reference('WorkloadFlagsViewModel.swift')
file_ref.set_source_tree('<group>')
target.source_build_phase.add_file_reference(file_ref)

puts "✅ Added WorkloadFlagsViewModel.swift to project"

project.save
puts "✅ Project saved"
