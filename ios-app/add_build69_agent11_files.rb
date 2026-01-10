#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
main_target = project.targets.find { |t| t.name == 'PTPerformance' }

# Find groups
ptperformance_group = project.main_group['PTPerformance']
services_group = ptperformance_group['Services'] || ptperformance_group.new_group('Services')
viewmodels_group = ptperformance_group['ViewModels'] || ptperformance_group.new_group('ViewModels')
views_group = ptperformance_group['Views'] || ptperformance_group.new_group('Views')
scheduling_group = views_group['Scheduling'] || views_group.new_group('Scheduling')

# Files to add
files_to_add = [
  {
    path: 'PTPerformance/ViewModels/ScheduledSessionsViewModel.swift',
    group: viewmodels_group
  },
  {
    path: 'PTPerformance/Views/Scheduling/ScheduledSessionsView.swift',
    group: scheduling_group
  }
]

# NotificationService already exists from Agent 7, so we skip it

files_to_add.each do |file_info|
  file_path = file_info[:path]
  group = file_info[:group]

  # Check if file already exists in project
  existing_ref = group.files.find { |f| f.path == File.basename(file_path) }

  if existing_ref
    puts "⚠️  File already exists in project: #{file_path}"
  else
    # Add file reference
    file_ref = group.new_file(file_path)

    # Add to target
    main_target.add_file_references([file_ref])

    puts "✅ Added: #{file_path}"
  end
end

# Save project
project.save

puts "\n✅ Build 69 Agent 11 files added to Xcode project successfully!"
puts "\nAdded files:"
puts "- ViewModels/ScheduledSessionsViewModel.swift"
puts "- Views/Scheduling/ScheduledSessionsView.swift"
puts "\nNote: NotificationService.swift already exists (enhanced by Agent 7)"
