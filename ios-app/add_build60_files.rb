#!/usr/bin/env ruby
require 'xcodeproj'

project_path = '/Users/expo/Code/expo/ios-app/PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'PTPerformance' }

# Helper to get or create groups
def get_or_create_group(parent, name)
  parent[name] || parent.new_group(name)
end

# Navigate to groups (PTPerformance is the main group in this project)
views_group = project.main_group['Views']
therapist_group = get_or_create_group(views_group, 'Therapist')
program_editor_group = get_or_create_group(therapist_group, 'ProgramEditor')
utils_group = project.main_group['Utils'] || project.main_group.new_group('Utils')
viewmodels_group = project.main_group['ViewModels']
tests_group = project.main_group['Tests']
integration_tests_group = get_or_create_group(tests_group, 'Integration')

# Files to add (relative to Views, Utils, ViewModels, Tests groups)
new_files = [
  # Agent 3: ProgramEditor Views
  { path: 'Views/Therapist/ProgramEditor/ProgramEditorView.swift', group: program_editor_group, target: target },
  { path: 'Views/Therapist/ProgramEditor/EditPhaseView.swift', group: program_editor_group, target: target },
  { path: 'Views/Therapist/ProgramEditor/EditSessionView.swift', group: program_editor_group, target: target },
  { path: 'Views/Therapist/ProgramEditor/ExerciseEditorView.swift', group: program_editor_group, target: target },
  { path: 'Views/Therapist/ProgramEditor/ExercisePickerView.swift', group: program_editor_group, target: target },

  # Agent 4: Utility Views
  { path: 'Utils/LoadingStateView.swift', group: utils_group, target: target },
  { path: 'Utils/ErrorStateView.swift', group: utils_group, target: target },

  # Agent 4: ViewModel
  { path: 'ViewModels/SessionSummaryViewModel.swift', group: viewmodels_group, target: target },

  # Agent 2: Tests
  { path: 'Tests/Integration/ProgramCreationTests.swift', group: integration_tests_group, target: nil }
]

files_added = 0
files_skipped = 0

new_files.each do |file_info|
  file_path = file_info[:path]
  group = file_info[:group]
  target = file_info[:target]
  basename = File.basename(file_path)

  # Check if file already exists in project
  existing_file = group.files.find { |f| f.path == basename }

  if existing_file
    puts "⏭️  Skipped (already exists): #{basename}"
    files_skipped += 1
  else
    # Add file reference
    file_ref = group.new_file(file_path)

    # Add to target if specified
    if target
      target.add_file_references([file_ref])
    end

    puts "✅ Added: #{basename}"
    files_added += 1
  end
end

# Save the project
project.save

puts "\n" + "="*60
puts "BUILD 60 FILES INTEGRATION COMPLETE"
puts "="*60
puts "Files added: #{files_added}"
puts "Files skipped: #{files_skipped}"
puts "Total files processed: #{files_added + files_skipped}"
puts "="*60
