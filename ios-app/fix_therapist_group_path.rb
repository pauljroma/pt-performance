#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the Views group
ptperf_group = project.main_group['PTPerformance']
views_group = ptperf_group['Views']

# Find Therapist group
therapist_group = views_group.groups.find { |g| g.display_name == 'Therapist' }

if therapist_group
  puts "Found Therapist group: #{therapist_group.display_name}"
  puts "Current path: #{therapist_group.path.inspect}"
  puts "Current source tree: #{therapist_group.source_tree}"

  # Set the path for the Therapist group
  therapist_group.path = 'Therapist'
  therapist_group.source_tree = '<group>'

  puts "Updated path to: #{therapist_group.path}"

  project.save
  puts "✅ Project saved"
else
  puts "❌ Therapist group not found"
end
