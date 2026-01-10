#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'PTPerformance' }

# Find PTPerformance group (might be at root or nested)
pt_group = project.main_group.groups.find { |g| g.path == 'PTPerformance' } || project.main_group

# Find or create ViewModels group
viewmodels_group = pt_group.groups.find { |g| g.path == 'ViewModels' || g.display_name == 'ViewModels' }
unless viewmodels_group
  viewmodels_group = pt_group.new_group('ViewModels')
end

# Find or create Views group
views_group = pt_group.groups.find { |g| g.path == 'Views' || g.display_name == 'Views' }
unless views_group
  views_group = pt_group.new_group('Views')
end

# Find or create Analytics group under Views
analytics_group = views_group.groups.find { |g| g.path == 'Analytics' || g.display_name == 'Analytics' }
unless analytics_group
  analytics_group = views_group.new_group('Analytics')
end

# Add AnalyticsViewModel.swift
analytics_vm_file = viewmodels_group.new_file('ViewModels/AnalyticsViewModel.swift')
target.add_file_references([analytics_vm_file])

# Add chart view files
['VolumeChartView.swift', 'StrengthChartView.swift', 'ConsistencyChartView.swift'].each do |filename|
  chart_file = analytics_group.new_file("Views/Analytics/#{filename}")
  target.add_file_references([chart_file])
end

# Save the project
project.save

puts "✅ Added Build 49 files to Xcode project:"
puts "  - ViewModels/AnalyticsViewModel.swift"
puts "  - Views/Analytics/VolumeChartView.swift"
puts "  - Views/Analytics/StrengthChartView.swift"
puts "  - Views/Analytics/ConsistencyChartView.swift"
