#!/usr/bin/env ruby

require 'xcodeproj'

project_path = '/Users/expo/Code/expo/ios-app/PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

# Get or create groups
def get_or_create_group(parent, name)
  parent[name] || parent.new_group(name)
end

# Get or create ViewModels group
viewmodels_group = project.main_group['ViewModels']
unless viewmodels_group
  viewmodels_group = project.main_group.new_group('ViewModels')
end

# Get or create Views group
views_group = project.main_group['Views']
unless views_group
  views_group = project.main_group.new_group('Views')
end

# Therapist group
therapist_group = get_or_create_group(views_group, 'Therapist')

# ProgramBuilder group (under Therapist)
program_builder_group = get_or_create_group(therapist_group, 'ProgramBuilder')

# ProgramEditor group (under Therapist)
program_editor_group = get_or_create_group(therapist_group, 'ProgramEditor')

# Add ExerciseTemplateViewModel
exercise_template_vm = viewmodels_group.new_file('ViewModels/ExerciseTemplateViewModel.swift')
target.add_file_references([exercise_template_vm])

# Add ProgramBuilder files
['ExerciseTemplatePicker.swift', 'SessionBuilderSheet.swift', 'PhaseDetailView.swift'].each do |filename|
  file_ref = program_builder_group.new_file("Views/Therapist/ProgramBuilder/#{filename}")
  target.add_file_references([file_ref])
end

# Add ProgramEditor files
['ProgramStructureView.swift', 'SessionEditorView.swift', 'ProgramManagerView.swift'].each do |filename|
  file_ref = program_editor_group.new_file("Views/Therapist/ProgramEditor/#{filename}")
  target.add_file_references([file_ref])
end

project.save

puts "✅ Successfully added Build 50 files to Xcode project"
puts "   - ExerciseTemplateViewModel.swift"
puts "   - ExerciseTemplatePicker.swift"
puts "   - SessionBuilderSheet.swift"
puts "   - PhaseDetailView.swift"
puts "   - ProgramStructureView.swift"
puts "   - SessionEditorView.swift"
puts "   - ProgramManagerView.swift"
