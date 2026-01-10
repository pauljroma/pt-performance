#!/usr/bin/env ruby
require 'xcodeproj'

puts "BUILD 96 - Phase 4 - Agent 11: Add New Files to Xcode Project"
puts "=" * 70

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first
main_group = project.main_group['PTPerformance'] || project.main_group.new_group('PTPerformance')

# Get or create top-level groups
services_group = main_group['Services'] || main_group.new_group('Services')
services_group.path = 'Services'

viewmodels_group = main_group['ViewModels'] || main_group.new_group('ViewModels')
viewmodels_group.path = 'ViewModels'

views_group = main_group['Views'] || main_group.new_group('Views')
views_group.path = 'Views'

# Create subgroups under Views
patient_group = views_group['Patient'] || views_group.new_group('Patient')
patient_group.path = 'Patient'

shared_group = views_group['Shared'] || views_group.new_group('Shared')
shared_group.path = 'Shared'

# Define all BUILD 96 new files
files_to_add = [
  # Phase 2 - Agent 4: Patient Profile
  { group: patient_group, file: 'PatientProfileView.swift', path: 'PTPerformance/Views/Patient/PatientProfileView.swift' },
  { group: viewmodels_group, file: 'PatientProfileViewModel.swift', path: 'PTPerformance/ViewModels/PatientProfileViewModel.swift' },

  # Phase 2 - Agent 5: Export Functionality
  { group: services_group, file: 'ExportService.swift', path: 'PTPerformance/Services/ExportService.swift' },

  # Phase 2 - Agent 6: Collaborative Workout Grid
  { group: shared_group, file: 'WorkoutGridView.swift', path: 'PTPerformance/Views/Shared/WorkoutGridView.swift' },
  { group: viewmodels_group, file: 'WorkoutGridViewModel.swift', path: 'PTPerformance/ViewModels/WorkoutGridViewModel.swift' },
]

added_count = 0
skipped_count = 0
error_count = 0

puts "\nAdding BUILD 96 Swift source files to build phase..."
puts "-" * 70

files_to_add.each do |file_info|
  file_name = file_info[:file]
  full_path = file_info[:path]

  # Check if file exists on disk
  unless File.exist?(full_path)
    puts "✗ File not found on disk: #{full_path}"
    error_count += 1
    next
  end

  # Check if file reference already exists in the group
  existing_ref = file_info[:group].files.find { |f| f.path == file_name }

  if existing_ref
    # Check if it's in the build phase
    in_build = target.source_build_phase.files.any? { |bf| bf.file_ref == existing_ref }

    if in_build
      puts "⊘ Already in project and build: #{file_name}"
      skipped_count += 1
    else
      # Add to build phase
      target.source_build_phase.add_file_reference(existing_ref)
      puts "✓ Added to build phase: #{file_name}"
      added_count += 1
    end
  else
    # Create new file reference
    begin
      file_ref = file_info[:group].new_file(file_name)

      # Add to build phase
      target.source_build_phase.add_file_reference(file_ref)

      puts "✓ Added new file: #{file_name}"
      added_count += 1
    rescue => e
      puts "✗ Error adding #{file_name}: #{e.message}"
      error_count += 1
    end
  end
end

# Save the project
if added_count > 0
  puts "\nSaving project..."
  project.save
  puts "✓ Project saved successfully"
end

puts "=" * 70
puts "BUILD 96 - Xcode Project Update Complete"
puts "=" * 70
puts "Files added: #{added_count}"
puts "Files skipped: #{skipped_count}"
puts "Errors: #{error_count}"
puts "=" * 70

if error_count == 0
  puts "\n✅ All BUILD 96 files successfully added to Xcode project!"
  puts "\nNew files integrated:"
  puts "  - PatientProfileView.swift (Views/Patient)"
  puts "  - PatientProfileViewModel.swift (ViewModels)"
  puts "  - ExportService.swift (Services)"
  puts "  - WorkoutGridView.swift (Views/Shared)"
  puts "  - WorkoutGridViewModel.swift (ViewModels)"
  puts "\nTotal: 5 new Swift files"
  puts "\n✅ Ready for Phase 4 - Agent 12: Comprehensive Testing"
  exit 0
else
  puts "\n⚠️  Some errors occurred. Please review above."
  exit 1
end
