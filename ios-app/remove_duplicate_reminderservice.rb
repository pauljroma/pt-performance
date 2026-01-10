#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "=== Removing Duplicate ReminderService.swift References ==="

# Get main target
main_target = project.targets.find { |t| t.name == 'PTPerformance' }

# Find all references to ReminderService.swift in the build phase
reminder_service_refs = main_target.source_build_phase.files.select do |build_file|
  build_file.file_ref && build_file.file_ref.path&.include?('ReminderService.swift')
end

puts "Found #{reminder_service_refs.count} references to ReminderService.swift"

# Remove duplicates (keep only the first one)
if reminder_service_refs.count > 1
  reminder_service_refs[1..-1].each do |duplicate|
    puts "Removing duplicate: #{duplicate.file_ref.path}"
    main_target.source_build_phase.remove_file_reference(duplicate.file_ref)
  end
end

# Save project
project.save

puts "✅ Duplicate references removed"
puts "Project saved: #{project_path}"
