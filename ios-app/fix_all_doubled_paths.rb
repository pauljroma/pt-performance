#!/usr/bin/env ruby
require 'xcodeproj'

puts "BUILD 96 - Comprehensive Path Fix Script"
puts "=" * 70
puts "Fixing 12 files with doubled paths from previous builds"
puts "=" * 70

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first
main_group = project.main_group['PTPerformance'] || project.main_group.new_group('PTPerformance')

# Define all files that need fixing
files_to_fix = [
  # Learning content files (BUILD 88)
  {
    file: 'LearningContentLoader.swift',
    correct_path: 'PTPerformance/Services/LearningContentLoader.swift',
    group_path: ['Services']
  },
  {
    file: 'LearningView.swift',
    correct_path: 'PTPerformance/Views/Learning/LearningView.swift',
    group_path: ['Views', 'Learning']
  },
  {
    file: 'LearningCategoryView.swift',
    correct_path: 'PTPerformance/Views/Learning/LearningCategoryView.swift',
    group_path: ['Views', 'Learning']
  },
  {
    file: 'LearningArticleView.swift',
    correct_path: 'PTPerformance/Views/Learning/LearningArticleView.swift',
    group_path: ['Views', 'Learning']
  },

  # AI Chat files (BUILD 88)
  {
    file: 'AIChatView.swift',
    correct_path: 'PTPerformance/Views/AI/AIChatView.swift',
    group_path: ['Views', 'AI']
  },
  {
    file: 'AIChatService.swift',
    correct_path: 'PTPerformance/Services/AIChatService.swift',
    group_path: ['Services']
  },

  # Analytics files (BUILD 95)
  {
    file: 'AnalyticsViewModel.swift',
    correct_path: 'PTPerformance/ViewModels/AnalyticsViewModel.swift',
    group_path: ['ViewModels']
  },
  {
    file: 'VolumeChartView.swift',
    correct_path: 'PTPerformance/Views/Analytics/VolumeChartView.swift',
    group_path: ['Views', 'Analytics']
  },
  {
    file: 'ConsistencyChartView.swift',
    correct_path: 'PTPerformance/Views/Analytics/ConsistencyChartView.swift',
    group_path: ['Views', 'Analytics']
  },
  {
    file: 'StrengthChartView.swift',
    correct_path: 'PTPerformance/Views/Analytics/StrengthChartView.swift',
    group_path: ['Views', 'Analytics']
  },
  {
    file: 'StrengthEmptyState.swift',
    correct_path: 'PTPerformance/Views/Analytics/StrengthEmptyState.swift',
    group_path: ['Views', 'Analytics']
  },

  # Exercise files
  {
    file: 'IntervalBlockView.swift',
    correct_path: 'PTPerformance/Views/Exercise/IntervalBlockView.swift',
    group_path: ['Views', 'Exercise']
  }
]

removed_count = 0
added_count = 0
skipped_count = 0
error_count = 0

puts "\nPhase 1: Removing old file references with incorrect paths..."
puts "-" * 70

files_to_fix.each do |file_info|
  file_name = file_info[:file]

  # Find and remove all references to this file in the project
  found_refs = []

  # Search through all groups recursively
  def find_file_refs(group, file_name, refs = [])
    group.files.each do |file_ref|
      if file_ref.path == file_name || file_ref.path.to_s.end_with?(file_name)
        refs << { group: group, ref: file_ref }
      end
    end

    group.groups.each do |subgroup|
      find_file_refs(subgroup, file_name, refs)
    end

    refs
  end

  found_refs = find_file_refs(main_group, file_name)

  if found_refs.empty?
    puts "⊘ #{file_name} - no existing references found"
    skipped_count += 1
  else
    found_refs.each do |ref_info|
      # Remove from build phase first
      target.source_build_phase.files.delete_if { |bf| bf.file_ref == ref_info[:ref] }

      # Remove from group
      ref_info[:group].files.delete(ref_info[:ref])

      removed_count += 1
    end
    puts "✓ Removed #{found_refs.count} reference(s) for #{file_name}"
  end
end

puts "\nPhase 2: Creating proper group structure..."
puts "-" * 70

# Ensure all required groups exist
def get_or_create_group_path(main_group, path_array)
  current_group = main_group

  path_array.each do |group_name|
    subgroup = current_group[group_name]

    if subgroup.nil?
      subgroup = current_group.new_group(group_name)
      # Don't set path property to avoid doubling
      puts "  ✓ Created group: #{group_name}"
    end

    current_group = subgroup
  end

  current_group
end

# Create all required groups
required_groups = files_to_fix.map { |f| f[:group_path] }.uniq
required_groups.each do |group_path|
  get_or_create_group_path(main_group, group_path)
end

puts "\nPhase 3: Re-adding files with correct paths..."
puts "-" * 70

files_to_fix.each do |file_info|
  file_name = file_info[:file]
  full_path = file_info[:correct_path]

  # Check if file exists on disk
  unless File.exist?(full_path)
    puts "✗ #{file_name} - file not found at #{full_path}"
    error_count += 1
    next
  end

  # Get the target group
  target_group = get_or_create_group_path(main_group, file_info[:group_path])

  # Check if already exists in this group (shouldn't, but check anyway)
  existing = target_group.files.find { |f| f.path == file_name }

  if existing
    puts "⊘ #{file_name} - already exists in correct location"
    skipped_count += 1
  else
    begin
      # Add file reference (just the filename, no path prefix)
      file_ref = target_group.new_file(file_name)

      # Add to build phase
      target.source_build_phase.add_file_reference(file_ref)

      puts "✓ Added #{file_name} to #{file_info[:group_path].join('/')}"
      added_count += 1
    rescue => e
      puts "✗ Error adding #{file_name}: #{e.message}"
      error_count += 1
    end
  end
end

puts "\nPhase 4: Verifying and saving..."
puts "-" * 70

# Verify all files are now correct
verification_passed = true
files_to_fix.each do |file_info|
  full_path = file_info[:correct_path]
  next unless File.exist?(full_path)

  file_name = file_info[:file]
  target_group = get_or_create_group_path(main_group, file_info[:group_path])

  file_ref = target_group.files.find { |f| f.path == file_name }
  if file_ref.nil?
    puts "✗ Verification failed for #{file_name}"
    verification_passed = false
  else
    in_build = target.source_build_phase.files.any? { |bf| bf.file_ref == file_ref }
    if in_build
      puts "✓ Verified #{file_name} (in group and build phase)"
    else
      puts "⚠ #{file_name} in group but not in build phase"
      verification_passed = false
    end
  end
end

# Save the project
if removed_count > 0 || added_count > 0
  puts "\nSaving project..."
  project.save
  puts "✓ Project saved successfully"
end

puts "=" * 70
puts "BUILD 96 - Path Fix Complete"
puts "=" * 70
puts "Files removed: #{removed_count}"
puts "Files added: #{added_count}"
puts "Files skipped: #{skipped_count}"
puts "Errors: #{error_count}"
puts "Verification: #{verification_passed ? '✓ PASSED' : '✗ FAILED'}"
puts "=" * 70

if error_count == 0 && verification_passed
  puts "\n✅ All path issues fixed successfully!"
  puts "\nNext steps:"
  puts "1. Clean derived data: rm -rf ~/Library/Developer/Xcode/DerivedData/PTPerformance-*"
  puts "2. Rebuild project: xcodebuild clean build ..."
  puts "3. Proceed to Agent 12: Comprehensive Testing"
  exit 0
else
  puts "\n⚠️  Some issues occurred. Please review above."
  exit 1
end
