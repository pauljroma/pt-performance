#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Remove the incorrectly added SentryConfig reference
target.source_build_phase.files.each do |build_file|
  if build_file.file_ref && build_file.file_ref.path&.include?('SentryConfig')
    build_file.remove_from_project
  end
end

# Remove from main group
project.main_group.recursive_children.each do |item|
  if item.is_a?(Xcodeproj::Project::Object::PBXFileReference) && item.path&.include?('SentryConfig')
    item.remove_from_project
  end
end

# Add it correctly - SentryConfig.swift is in the root, not in a PTPerformance/ subdirectory
file_ref = project.main_group.new_reference('SentryConfig.swift')
target.source_build_phase.add_file_reference(file_ref)

project.save
puts "✅ Fixed SentryConfig.swift path"
