#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "=== Fixing Build 71 File Paths in Xcode Project ==="

# Files that were added with wrong paths
files_to_fix = [
  'CalendarDayCell.swift',
  'EnhancedSessionCalendarView.swift',
  'SessionQuickLogView.swift',
  'ReminderService.swift',
  'CalendarViewTests.swift',
  'ReminderTests.swift',
  'ReminderServiceTests.swift'
]

fixed_count = 0

# Recursively find file references
def find_file_refs(group, filename)
  refs = []
  group.children.each do |child|
    if child.is_a?(Xcodeproj::Project::Object::PBXFileReference) && child.path == filename
      refs << child
    elsif child.is_a?(Xcodeproj::Project::Object::PBXGroup)
      refs.concat(find_file_refs(child, filename))
    end
  end
  refs
end

files_to_fix.each do |filename|
  file_refs = find_file_refs(project.main_group, filename)

  file_refs.each do |file_ref|
    old_path = file_ref.real_path.to_s
    puts "Found: #{filename}"
    puts "  Old path: #{old_path}"

    # Determine correct relative path based on filename
    if filename.include?('Tests')
      if filename.include?('Integration')
        correct_path = "Tests/Integration/#{filename}"
      else
        correct_path = "Tests/Unit/#{filename}"
      end
    elsif filename == 'ReminderService.swift'
      correct_path = "Services/#{filename}"
    else
      correct_path = "Views/Scheduling/#{filename}"
    end

    # Update the path
    file_ref.path = correct_path
    puts "  New path: #{correct_path}"
    fixed_count += 1
  end
end

# Save project
project.save

puts "\n=== Summary ==="
puts "File references fixed: #{fixed_count}"
puts "Project saved: #{project_path}"
puts "\n✅ Build 71 file paths fixed"
