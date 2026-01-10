#!/usr/bin/env ruby
require 'xcodeproj'

project_path = '/Users/expo/Code/expo/ios-app/PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first
main_group = project.main_group.find_subpath('PTPerformance', true)

# Find or create groups
models_group = main_group.find_subpath('Models', true)
viewmodels_group = main_group.find_subpath('ViewModels', true)
views_group = main_group.find_subpath('Views', true)
readiness_group = views_group.find_subpath('Readiness', true)

# Add files
files_to_add = [
  {
    group: models_group,
    path: '/Users/expo/Code/expo/ios-app/PTPerformance/Models/ReadinessAdjustment.swift'
  },
  {
    group: viewmodels_group,
    path: '/Users/expo/Code/expo/ios-app/PTPerformance/ViewModels/ReadinessAdjustmentViewModel.swift'
  },
  {
    group: readiness_group,
    path: '/Users/expo/Code/expo/ios-app/PTPerformance/Views/Readiness/ReadinessAdjustmentView.swift'
  },
  {
    group: readiness_group,
    path: '/Users/expo/Code/expo/ios-app/PTPerformance/Views/Readiness/AdjustmentHistoryView.swift'
  }
]

files_to_add.each do |file_info|
  file_path = file_info[:path]
  group = file_info[:group]
  
  if File.exist?(file_path)
    # Check if file already exists in project
    existing_ref = group.files.find { |f| f.path == File.basename(file_path) }
    
    unless existing_ref
      file_ref = group.new_reference(file_path)
      target.add_file_references([file_ref])
      puts "Added: #{File.basename(file_path)}"
    else
      puts "Already exists: #{File.basename(file_path)}"
    end
  else
    puts "File not found: #{file_path}"
  end
end

project.save
puts "Project updated successfully!"
