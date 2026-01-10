#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'PTPerformance' }

# Find PTPerformance group
pt_group = project.main_group.groups.find { |g| g.path == 'PTPerformance' } || project.main_group

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

# Add ProgressChartsView.swift
progress_charts_file = analytics_group.new_file('Views/Analytics/ProgressChartsView.swift')
target.add_file_references([progress_charts_file])

# Save the project
project.save

puts "✅ Added ProgressChartsView.swift to Xcode project"
