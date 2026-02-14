#!/usr/bin/env ruby
require 'xcodeproj'

# Open the Xcode project
project_path = 'PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Find or create groups
models_group = project.main_group['Models'] || project.main_group.new_group('Models')
services_group = project.main_group['Services'] || project.main_group.new_group('Services')
views_group = project.main_group['Views'] || project.main_group.new_group('Views')
journal_group = views_group['Journal'] || views_group.new_group('Journal')

# Add files to project
files_to_add = [
  {
    group: models_group,
    path: 'Models/JournalEntry.swift'
  },
  {
    group: services_group,
    path: 'Services/AudioRecordingService.swift'
  },
  {
    group: journal_group,
    path: 'Views/Journal/AudioHealthJournalView.swift'
  },
  {
    group: journal_group,
    path: 'Views/Journal/JournalEntryRecordingView.swift'
  },
  {
    group: journal_group,
    path: 'Views/Journal/JournalEntryDetailView.swift'
  }
]

files_to_add.each do |file_info|
  file_path = file_info[:path]
  group = file_info[:group]

  # Check if file already exists in project
  existing_file = group.files.find { |f| f.path == File.basename(file_path) }

  unless existing_file
    # Add file reference to group
    file_ref = group.new_file(file_path)

    # Add to compile sources build phase
    target.source_build_phase.add_file_reference(file_ref)

    puts "Added #{file_path}"
  else
    puts "File #{file_path} already exists in project"
  end
end

# Save the project
project.save

puts "\nSuccessfully added journal files to Xcode project!"
