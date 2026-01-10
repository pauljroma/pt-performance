#!/usr/bin/env ruby
require 'xcodeproj'

# Build 62: Add messaging files to Xcode project
project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get main target
target = project.targets.first

# Files to add with their group paths
files_to_add = [
  # Models
  { path: 'PTPerformance/Models/MessageThread.swift', group: 'Models' },
  { path: 'PTPerformance/Models/Message.swift', group: 'Models' },

  # Services
  { path: 'PTPerformance/Services/MessagingService.swift', group: 'Services' },

  # Views
  { path: 'PTPerformance/Views/Messaging/MessageThreadView.swift', group: 'Views/Messaging' },
  { path: 'PTPerformance/Views/Messaging/ChatView.swift', group: 'Views/Messaging' },
  { path: 'PTPerformance/Views/Messaging/VideoRecorderView.swift', group: 'Views/Messaging' },
  { path: 'PTPerformance/Views/Messaging/FormCheckAnnotationView.swift', group: 'Views/Messaging' }
]

def find_or_create_group(project, path)
  parts = path.split('/')
  current = project.main_group

  parts.each do |part|
    next_group = current.children.find { |child| child.display_name == part && child.is_a?(Xcodeproj::Project::Object::PBXGroup) }

    unless next_group
      next_group = current.new_group(part)
      puts "Created group: #{part}"
    end

    current = next_group
  end

  current
end

# Add each file
files_to_add.each do |file_info|
  file_path = file_info[:path]
  group_path = file_info[:group]

  # Check if file exists
  unless File.exist?(file_path)
    puts "Warning: File not found: #{file_path}"
    next
  end

  # Get or create the group
  group = find_or_create_group(project, group_path)

  # Check if file is already in project
  file_name = File.basename(file_path)
  existing_file = group.children.find { |child| child.display_name == file_name }

  if existing_file
    puts "File already exists in project: #{file_name}"
    next
  end

  # Add file reference
  file_ref = group.new_file(file_path)

  # Add to build phase
  target.source_build_phase.add_file_reference(file_ref)

  puts "Added file: #{file_name} to group: #{group_path}"
end

# Save project
project.save

puts "\n✅ Build 62 messaging files added to Xcode project successfully!"
puts "\nFiles added:"
files_to_add.each do |file_info|
  puts "  - #{file_info[:path]}"
end
