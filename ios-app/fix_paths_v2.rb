#!/usr/bin/env ruby
require 'xcodeproj'

puts "BUILD 96 - Path Fix V2 (with group paths)"
puts "=" * 70

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first
main_group = project.main_group['PTPerformance']

# Remove all problematic file references first
puts "\n1. Cleaning up file references..."
puts "-" * 70

files_to_remove = [
  'LearningContentLoader.swift',
  'LearningView.swift',
  'LearningCategoryView.swift',
  'LearningArticleView.swift',
  'AIChatView.swift',
  'AIChatService.swift',
  'AnalyticsViewModel.swift',
  'VolumeChartView.swift',
  'ConsistencyChartView.swift',
  'StrengthChartView.swift',
  'StrengthEmptyState.swift',
  'IntervalBlockView.swift'
]

def remove_file_from_project(project, target, main_group, filename)
  removed = 0

  def scan_and_remove(group, target, filename)
    count = 0
    group.files.select { |f| f.path == filename || f.path.to_s.end_with?(filename) }.each do |file_ref|
      target.source_build_phase.files.delete_if { |bf| bf.file_ref == file_ref }
      group.files.delete(file_ref)
      count += 1
    end

    group.groups.each { |sg| count += scan_and_remove(sg, target, filename) }
    count
  end

  scan_and_remove(main_group, target, filename)
end

files_to_remove.each do |file|
  count = remove_file_from_project(project, target, main_group, file)
  puts "✓ Removed #{file} (#{count} refs)"
end

# Set up proper group structure
puts "\n2. Setting up group structure with correct paths..."
puts "-" * 70

services_group = main_group['Services'] || main_group.new_group('Services')
services_group.path = 'Services'

viewmodels_group = main_group['ViewModels'] || main_group.new_group('ViewModels')
viewmodels_group.path = 'ViewModels'

views_group = main_group['Views'] || main_group.new_group('Views')
views_group.path = 'Views'

# Create subgroups under Views
learning_group = views_group['Learning'] || views_group.new_group('Learning')
learning_group.path = 'Learning'

ai_group = views_group['AI'] || views_group.new_group('AI')
ai_group.path = 'AI'

analytics_group = views_group['Analytics'] || views_group.new_group('Analytics')
analytics_group.path = 'Analytics'

exercise_group = views_group['Exercise'] || views_group.new_group('Exercise')
exercise_group.path = 'Exercise'

puts "✓ Group structure created"

# Add files with correct paths
puts "\n3. Adding files back with correct paths..."
puts "-" * 70

files_to_add = [
  { file: 'LearningContentLoader.swift', group: services_group, path: 'PTPerformance/Services/LearningContentLoader.swift' },
  { file: 'AIChatService.swift', group: services_group, path: 'PTPerformance/Services/AIChatService.swift' },

  { file: 'AnalyticsViewModel.swift', group: viewmodels_group, path: 'PTPerformance/ViewModels/AnalyticsViewModel.swift' },

  { file: 'LearningView.swift', group: learning_group, path: 'PTPerformance/Views/Learning/LearningView.swift' },
  { file: 'LearningCategoryView.swift', group: learning_group, path: 'PTPerformance/Views/Learning/LearningCategoryView.swift' },
  { file: 'LearningArticleView.swift', group: learning_group, path: 'PTPerformance/Views/Learning/LearningArticleView.swift' },

  { file: 'AIChatView.swift', group: ai_group, path: 'PTPerformance/Views/AI/AIChatView.swift' },

  { file: 'VolumeChartView.swift', group: analytics_group, path: 'PTPerformance/Views/Analytics/VolumeChartView.swift' },
  { file: 'ConsistencyChartView.swift', group: analytics_group, path: 'PTPerformance/Views/Analytics/ConsistencyChartView.swift' },
  { file: 'StrengthChartView.swift', group: analytics_group, path: 'PTPerformance/Views/Analytics/StrengthChartView.swift' },
  { file: 'StrengthEmptyState.swift', group: analytics_group, path: 'PTPerformance/Views/Analytics/StrengthEmptyState.swift' },

  { file: 'IntervalBlockView.swift', group: exercise_group, path: 'PTPerformance/Views/Exercise/IntervalBlockView.swift' }
]

added_count = 0
files_to_add.each do |file_info|
  unless File.exist?(file_info[:path])
    puts "✗ File not found: #{file_info[:path]}"
    next
  end

  file_ref = file_info[:group].new_file(file_info[:file])
  target.source_build_phase.add_file_reference(file_ref)
  puts "✓ Added #{file_info[:file]}"
  added_count += 1
end

puts "\n4. Saving project..."
project.save
puts "✓ Project saved"

puts "=" * 70
puts "Files added: #{added_count}/12"
puts "=" * 70

if added_count == 12
  puts "\n✅ All files fixed!"
  puts "\nClean derived data and rebuild"
  exit 0
else
  puts "\n⚠️  Some files missing"
  exit 1
end
