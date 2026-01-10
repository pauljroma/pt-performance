#!/usr/bin/env ruby
require 'xcodeproj'

puts "Fixing Absolute File Paths"
puts "=" * 70

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

files_to_fix = [
  { name: 'ScheduledSessionsView.swift', correct_path: 'Views/Scheduling/ScheduledSessionsView.swift' },
  { name: 'CalendarDayCell.swift', correct_path: 'Views/Scheduling/CalendarDayCell.swift' },
  { name: 'EnhancedSessionCalendarView.swift', correct_path: 'Views/Scheduling/EnhancedSessionCalendarView.swift' },
  { name: 'SessionQuickLogView.swift', correct_path: 'Views/Scheduling/SessionQuickLogView.swift' },
  { name: 'ReadinessAdjustmentView.swift', correct_path: 'Views/Readiness/ReadinessAdjustmentView.swift' },
  { name: 'PushNotificationService.swift', correct_path: 'Services/PushNotificationService.swift' },
]

fixed_count = 0

files_to_fix.each do |file_info|
  # Find the file reference
  file_refs = project.files.select { |f| f.path&.end_with?(file_info[:name]) }

  file_refs.each do |file_ref|
    puts "\nChecking: #{file_ref.path}"
    puts "  Current parent: #{file_ref.parent&.name}"

    # Get the group path
    group_path_components = []
    current = file_ref.parent
    while current && current != project.main_group
      if current.path && !current.path.empty?
        group_path_components.unshift(current.path)
      end
      current = current.parent
    end
    group_path = group_path_components.join('/')

    puts "  Group path: #{group_path}"

    # If the file_ref path includes the group path, we need to make it relative
    if file_ref.path.start_with?(group_path + '/') && !group_path.empty?
      relative_path = file_ref.path.sub("#{group_path}/", '')
      puts "  Changing to relative path: #{relative_path}"
      file_ref.path = relative_path
      fixed_count += 1
    elsif file_ref.path == file_info[:correct_path]
      # File has absolute path from PTPerformance root
      # We need to check if it's in the right group
      expected_group_path = File.dirname(file_info[:correct_path])
      if group_path != expected_group_path
        puts "  File has full path but is in wrong group"
        puts "  Expected group: #{expected_group_path}, actual: #{group_path}"

        # Make path relative to current group
        if file_ref.path.start_with?(group_path + '/')
          relative_path = file_ref.path.sub("#{group_path}/", '')
          puts "  Changing to: #{relative_path}"
          file_ref.path = relative_path
          fixed_count += 1
        elsif group_path.empty?
          # Group has no path, file path should be relative from PTPerformance
          # This is actually correct, leave it
          puts "  Group has no path, keeping absolute path from root"
        else
          # Need to fix
          file_name = File.basename(file_ref.path)
          puts "  Changing to filename only: #{file_name}"
          file_ref.path = file_name
          fixed_count += 1
        end
      end
    end
  end
end

if fixed_count > 0
  puts "\n\nSaving project..."
  project.save
  puts "=" * 70
  puts "✅ Fixed #{fixed_count} file paths!"
  puts "=" * 70
else
  puts "\n=" * 70
  puts "No files needed fixing"
  puts "=" * 70
end
