#!/usr/bin/env ruby
#
# Script to add SmartNotificationService.swift and NotificationSettingsView.swift
# to the PTPerformance Xcode project
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

# Find or create Services group
services_group = project.main_group.find_subpath('PTPerformance/Services', true)

unless services_group
  puts "ERROR: Could not find Services group"
  exit 1
end

puts "Found Services group"

# Find or create Views/Settings group
settings_group = project.main_group.find_subpath('PTPerformance/Views/Settings', true)

unless settings_group
  puts "ERROR: Could not find Views/Settings group"
  exit 1
end

puts "Found Views/Settings group"

# Track added files
added_count = 0

# Add SmartNotificationService.swift to Services group
service_file = 'SmartNotificationService.swift'
existing_service = services_group.files.find { |f| f.path == service_file }

if existing_service
  puts "File already in project: #{service_file}"
else
  file_ref = services_group.new_reference(service_file)
  file_ref.last_known_file_type = 'sourcecode.swift'
  target.source_build_phase.add_file_reference(file_ref)
  puts "Added to project: #{service_file}"
  added_count += 1
end

# Add NotificationSettingsView.swift to Views/Settings group
view_file = 'NotificationSettingsView.swift'
existing_view = settings_group.files.find { |f| f.path == view_file }

if existing_view
  puts "File already in project: #{view_file}"
else
  file_ref = settings_group.new_reference(view_file)
  file_ref.last_known_file_type = 'sourcecode.swift'
  target.source_build_phase.add_file_reference(file_ref)
  puts "Added to project: #{view_file}"
  added_count += 1
end

# Save the project
project.save

puts ""
puts "Successfully added #{added_count} file(s) to Xcode project"
puts "- SmartNotificationService.swift -> Services group"
puts "- NotificationSettingsView.swift -> Views/Settings group"
