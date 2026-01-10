#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'PTPerformance' }

# Find or create the Views/Therapist group
views_group = project.main_group['PTPerformance']['Views']
therapist_group = views_group['Therapist'] || views_group.new_group('Therapist')

# Add WorkloadFlagsView.swift
file_path = 'Views/Therapist/WorkloadFlagsView.swift'
file_ref = therapist_group.new_file(file_path)
target.source_build_phase.add_file_reference(file_ref)

puts "✅ Added WorkloadFlagsView.swift to project"

project.save
puts "✅ Project saved"
