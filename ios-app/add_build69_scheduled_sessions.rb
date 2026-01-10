#!/usr/bin/env ruby
# Build 69 Agent 10: Add Scheduled Sessions calendar feature to Xcode project

require 'xcodeproj'

# Open the Xcode project
project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first
puts "Target: #{target.name}"

# Get the main group (PTPerformance)
main_group = project.main_group.find_subpath('PTPerformance', true)

# Find or create ViewModels group
viewmodels_group = main_group['ViewModels'] || main_group.new_group('ViewModels')

# Find or create Views group and Patient subgroup
views_group = main_group['Views'] || main_group.new_group('Views')
patient_views_group = views_group['Patient'] || views_group.new_group('Patient')

# Add ScheduledSessionsViewModel.swift
viewmodel_file = 'PTPerformance/ViewModels/ScheduledSessionsViewModel.swift'
if File.exist?(viewmodel_file)
  viewmodel_ref = viewmodels_group.new_file(viewmodel_file)
  target.add_file_references([viewmodel_ref])
  puts "Added: #{viewmodel_file}"
else
  puts "WARNING: File not found: #{viewmodel_file}"
end

# Add ScheduledSessionsView.swift
view_file = 'PTPerformance/Views/Patient/ScheduledSessionsView.swift'
if File.exist?(view_file)
  view_ref = patient_views_group.new_file(view_file)
  target.add_file_references([view_ref])
  puts "Added: #{view_file}"
else
  puts "WARNING: File not found: #{view_file}"
end

# Save the project
project.save

puts "\n✅ Build 69 Agent 10 files added successfully!"
puts "\nFiles added:"
puts "  - ViewModels/ScheduledSessionsViewModel.swift"
puts "  - Views/Patient/ScheduledSessionsView.swift"
puts "\nIntegration complete. You can now build and run the app."
