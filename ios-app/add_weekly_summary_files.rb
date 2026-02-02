#!/usr/bin/env ruby
# Add Weekly Summary feature files to Xcode project (ACP-843)

require 'xcodeproj'

PROJECT_PATH = 'PTPerformance/PTPerformance.xcodeproj'

# Files to add with their target group paths
FILES_TO_ADD = {
  'PTPerformance/Models/WeeklySummary.swift' => 'PTPerformance/Models',
  'PTPerformance/Services/WeeklySummaryService.swift' => 'PTPerformance/Services',
  'PTPerformance/ViewModels/WeeklySummaryViewModel.swift' => 'PTPerformance/ViewModels',
  'PTPerformance/Views/Analytics/WeeklySummaryView.swift' => 'PTPerformance/Views/Analytics',
  'PTPerformance/Views/Analytics/WeeklySummaryPreferencesView.swift' => 'PTPerformance/Views/Analytics',
  'PTPerformance/Views/Analytics/WeeklySummaryHistoryView.swift' => 'PTPerformance/Views/Analytics',
  'PTPerformance/Views/Components/WeeklySummaryCardView.swift' => 'PTPerformance/Views/Components',
}

def find_or_create_group(project, path)
  components = path.split('/')
  current_group = project.main_group

  components.each do |component|
    child = current_group.children.find { |c| c.respond_to?(:name) && c.name == component }
    child ||= current_group.children.find { |c| c.respond_to?(:path) && c.path == component }

    if child.nil?
      child = current_group.new_group(component)
      puts "  Created group: #{component}"
    end
    current_group = child
  end

  current_group
end

def file_already_added?(project, file_path)
  project.files.any? { |f| f.path&.end_with?(File.basename(file_path)) }
end

puts "Opening project: #{PROJECT_PATH}"
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find the main target
target = project.targets.find { |t| t.name == 'PTPerformance' }
unless target
  puts "ERROR: Could not find PTPerformance target"
  exit 1
end
puts "Found target: #{target.name}"

files_added = 0
files_skipped = 0

FILES_TO_ADD.each do |file_path, group_path|
  file_name = File.basename(file_path)

  if file_already_added?(project, file_path)
    puts "  Skipping (already exists): #{file_name}"
    files_skipped += 1
    next
  end

  # Find or create the target group
  group = find_or_create_group(project, group_path)

  # Add the file reference
  file_ref = group.new_file(file_path)

  # Add to target's source build phase
  target.source_build_phase.add_file_reference(file_ref)

  puts "  Added: #{file_name} to #{group_path}"
  files_added += 1
end

# Save the project
project.save
puts "\nProject saved!"
puts "Files added: #{files_added}"
puts "Files skipped: #{files_skipped}"
