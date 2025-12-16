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
services_group = project.main_group['Services'] || project.main_group.new_group('Services')
onboarding_group = get_or_create_group(views_group, 'Onboarding')

# Files to add for Build 61: Onboarding Flow
new_files = [
  # Agent 1: Onboarding Flow
  { path: 'Services/OnboardingCoordinator.swift', group: services_group, target: target },
  { path: 'Views/Onboarding/OnboardingPage.swift', group: onboarding_group, target: target },
  { path: 'Views/Onboarding/OnboardingView.swift', group: onboarding_group, target: target }
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
puts "BUILD 61 FILES INTEGRATION COMPLETE"
puts "="*60
puts "Files added: #{files_added}"
puts "Files skipped: #{files_skipped}"
puts "Total files processed: #{files_added + files_skipped}"
puts "="*60
