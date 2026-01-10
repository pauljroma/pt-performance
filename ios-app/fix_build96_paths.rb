#!/usr/bin/env ruby
require 'xcodeproj'

puts "BUILD 96 - Fix Duplicate Files and Incorrect Paths"
puts "=" * 70

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

fixed_count = 0
removed_count = 0

puts "\n1. Removing duplicate BUILD 96 files from build phase..."
puts "-" * 70

# Files that were added twice
duplicate_files = ['PatientProfileView.swift', 'PatientProfileViewModel.swift', 'ExportService.swift']

duplicate_files.each do |file_name|
  # Find all build file references for this file
  build_files = target.source_build_phase.files.select do |bf|
    bf.file_ref && bf.file_ref.path == file_name
  end

  if build_files.count > 1
    # Remove all but the first one
    build_files[1..-1].each do |bf|
      target.source_build_phase.files.delete(bf)
      removed_count += 1
    end
    puts "✓ Removed #{build_files.count - 1} duplicate(s) of #{file_name}"
  end
end

puts "\n2. Fixing incorrect file reference paths..."
puts "-" * 70

# Files with doubled paths that need fixing
path_fixes = {
  'Services/Services/LearningContentLoader.swift' => 'Services/LearningContentLoader.swift',
  'Views/Views/Learning/LearningView.swift' => 'Views/Learning/LearningView.swift',
  'Views/Views/Learning/LearningCategoryView.swift' => 'Views/Learning/LearningCategoryView.swift',
  'Views/Views/Learning/LearningArticleView.swift' => 'Views/Learning/LearningArticleView.swift',
  'Views/Views/AI/AIChatView.swift' => 'Views/AI/AIChatView.swift',
  'Services/Services/AIChatService.swift' => 'Services/AIChatService.swift',
  'ViewModels/ViewModels/AnalyticsViewModel.swift' => 'ViewModels/AnalyticsViewModel.swift',
  'Views/Views/Analytics/VolumeChartView.swift' => 'Views/Analytics/VolumeChartView.swift',
  'Views/Views/Analytics/ConsistencyChartView.swift' => 'Views/Analytics/ConsistencyChartView.swift',
  'Views/Views/Analytics/StrengthChartView.swift' => 'Views/Analytics/StrengthChartView.swift',
  'Views/Views/Analytics/StrengthEmptyState.swift' => 'Views/Analytics/StrengthEmptyState.swift',
  'Views/Views/Exercise/IntervalBlockView.swift' => 'Views/Exercise/IntervalBlockView.swift'
}

# Find all file references
project.files.each do |file_ref|
  next unless file_ref.path

  # Check if this file has an incorrect path
  path_fixes.each do |incorrect_path, correct_path|
    if file_ref.path.end_with?(incorrect_path) || file_ref.path == incorrect_path
      # Verify the correct file exists
      correct_full_path = "PTPerformance/#{correct_path}"
      if File.exist?(correct_full_path)
        file_ref.path = File.basename(correct_path)
        puts "✓ Fixed path: #{incorrect_path} → #{correct_path}"
        fixed_count += 1
      else
        puts "⚠ Skipped #{incorrect_path}: correct file not found at #{correct_full_path}"
      end
    end
  end
end

# Save the project
puts "\nSaving project..."
project.save

puts "=" * 70
puts "BUILD 96 - Path Fixes Complete"
puts "=" * 70
puts "Duplicates removed: #{removed_count}"
puts "Paths fixed: #{fixed_count}"
puts "=" * 70

if fixed_count > 0 || removed_count > 0
  puts "\n✅ Xcode project fixed successfully!"
  puts "\nNext step: Test build again"
  exit 0
else
  puts "\n⚠️  No changes were made."
  exit 1
end
