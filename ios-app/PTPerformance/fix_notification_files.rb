#!/usr/bin/env ruby
#
# Script to fix SmartNotificationService.swift and NotificationSettingsView.swift
# paths in the PTPerformance Xcode project
#
# ACP-841: Smart Notification Timing Feature
#

require 'xcodeproj'

# Open the project
project_path = 'PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "Opened project: #{project_path}"

# Get the main target
target = project.targets.find { |t| t.name == 'PTPerformance' }

unless target
  puts "ERROR: Could not find PTPerformance target"
  exit 1
end

puts "Found target: #{target.name}"

# Find PTPerformance group first
pt_group = project.main_group.find_subpath('PTPerformance', true)

unless pt_group
  puts "ERROR: Could not find PTPerformance group"
  exit 1
end

# Find Services group
services_group = pt_group.find_subpath('Services', true)

unless services_group
  puts "ERROR: Could not find Services group"
  exit 1
end

puts "Found Services group"

# Find Views/Settings group
views_group = pt_group.find_subpath('Views', true)
settings_group = views_group ? views_group.find_subpath('Settings', true) : nil

unless settings_group
  puts "ERROR: Could not find Views/Settings group"
  exit 1
end

puts "Found Views/Settings group"

# Remove any incorrectly added references
puts "Cleaning up any existing incorrect references..."
target.source_build_phase.files.dup.each do |build_file|
  next unless build_file.file_ref
  file_path = build_file.file_ref.path
  if file_path && (file_path.include?('SmartNotificationService.swift') || file_path.include?('NotificationSettingsView.swift'))
    # Check if it has an incorrect path (not inside Services or Views/Settings)
    full_path = build_file.file_ref.real_path.to_s rescue nil
    if full_path && !full_path.include?('Services/') && !full_path.include?('Views/Settings/')
      puts "Removing incorrect build reference: #{file_path}"
      build_file.remove_from_project
    end
  end
end

# Add SmartNotificationService.swift
service_file_name = 'SmartNotificationService.swift'
existing_service = services_group.files.find { |f| f.path == service_file_name }

unless existing_service
  puts "Adding #{service_file_name} to Services group..."
  file_ref = services_group.new_file(service_file_name)
  target.source_build_phase.add_file_reference(file_ref)
  puts "Added #{service_file_name}"
else
  puts "#{service_file_name} already exists in Services group"
  # Make sure it's in the build phase
  in_build = target.source_build_phase.files.any? { |bf| bf.file_ref == existing_service }
  unless in_build
    target.source_build_phase.add_file_reference(existing_service)
    puts "Added existing #{service_file_name} to build phase"
  end
end

# Add NotificationSettingsView.swift
view_file_name = 'NotificationSettingsView.swift'
existing_view = settings_group.files.find { |f| f.path == view_file_name }

unless existing_view
  puts "Adding #{view_file_name} to Views/Settings group..."
  file_ref = settings_group.new_file(view_file_name)
  target.source_build_phase.add_file_reference(file_ref)
  puts "Added #{view_file_name}"
else
  puts "#{view_file_name} already exists in Views/Settings group"
  # Make sure it's in the build phase
  in_build = target.source_build_phase.files.any? { |bf| bf.file_ref == existing_view }
  unless in_build
    target.source_build_phase.add_file_reference(existing_view)
    puts "Added existing #{view_file_name} to build phase"
  end
end

# Save the project
project.save

puts ""
puts "Successfully configured file references in Xcode project"
