#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'PTPerformance' }

# Remove ALL references to WorkloadFlagsView
target.source_build_phase.files.to_a.each do |build_file|
  if build_file.file_ref && build_file.file_ref.path&.include?('WorkloadFlagsView')
    puts "Removing: #{build_file.file_ref.real_path}"
    target.source_build_phase.files.delete(build_file)
  end
end

# Remove from file references too
project.files.each do |file_ref|
  if file_ref.path&.include?('WorkloadFlagsView')
    puts "Removing file ref: #{file_ref.path}"
    file_ref.remove_from_project
  end
end

# Now add it properly
ptperf_group = project.main_group['PTPerformance']
views_group = ptperf_group['Views']

# Find or create Therapist group
therapist_group = views_group.groups.find { |g| g.name == 'Therapist' }
unless therapist_group
  therapist_group = views_group.new_group('Therapist')
  therapist_group.set_source_tree('<group>')
  therapist_group.set_path('Therapist')
  puts "Created Therapist group"
end

# Add the file
file_ref = therapist_group.new_reference('WorkloadFlagsView.swift')
file_ref.set_source_tree('<group>')
target.source_build_phase.add_file_reference(file_ref)

puts "✅ Added WorkloadFlagsView.swift properly"

project.save
puts "✅ Project saved"
