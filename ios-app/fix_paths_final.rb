#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "=== Fixing File Reference Paths ==="

# Files to fix
files_to_fix = {
  'CalendarDayCell.swift' => 'Views/Scheduling/CalendarDayCell.swift',
  'EnhancedSessionCalendarView.swift' => 'Views/Scheduling/EnhancedSessionCalendarView.swift',
  'SessionQuickLogView.swift' => 'Views/Scheduling/SessionQuickLogView.swift',
  'ReminderService.swift' => 'Services/ReminderService.swift',
  'CalendarViewTests.swift' => 'Tests/Integration/CalendarViewTests.swift',
  'ReminderTests.swift' => 'Tests/Integration/ReminderTests.swift',
  'ReminderServiceTests.swift' => 'Tests/Unit/ReminderServiceTests.swift'
}

fixed_count = 0

files_to_fix.each do |filename, correct_path|
  # Find all references to this file
  ref = project.files.find { |f| f.path&.end_with?(filename) }

  if ref
    old_path = ref.path
    puts "Found: #{filename}"
    puts "  Current path: #{old_path}"
    puts "  Correct path: #{correct_path}"

    # Update the path
    ref.path = correct_path
    fixed_count += 1
  else
    puts "Not found: #{filename}"
  end
end

# Save project
project.save

puts "\n=== Summary ==="
puts "Paths fixed: #{fixed_count}"
puts "Project saved: #{project_path}"
puts "\n✅ All paths corrected"
