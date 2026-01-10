#!/usr/bin/env ruby

require 'xcodeproj'

project_path = '/Users/expo/Code/expo/ios-app/PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

# Get or create groups
def get_or_create_group(parent, name)
  parent[name] || parent.new_group(name)
end

# Get or create Views group
views_group = project.main_group['Views']
unless views_group
  views_group = project.main_group.new_group('Views')
end

# Get or create Components group
components_group = project.main_group['Components']
unless components_group
  components_group = project.main_group.new_group('Components')
end

# Create Exercise group under Views
exercise_group = get_or_create_group(views_group, 'Exercise')

# Add ExerciseTechniqueView.swift
technique_view = exercise_group.new_file('Views/Exercise/ExerciseTechniqueView.swift')
target.add_file_references([technique_view])

# Add VideoPlayerView.swift to Components
video_player = components_group.new_file('Components/VideoPlayerView.swift')
target.add_file_references([video_player])

# Add ExerciseCuesCard.swift to Components
cues_card = components_group.new_file('Components/ExerciseCuesCard.swift')
target.add_file_references([cues_card])

project.save

puts "✅ Successfully added Build 61 files to Xcode project"
puts "   - ExerciseTechniqueView.swift (Views/Exercise/)"
puts "   - VideoPlayerView.swift (Components/)"
puts "   - ExerciseCuesCard.swift (Components/)"
puts ""
puts "📝 Note: Database migration file created at:"
puts "   supabase/migrations/20251217000000_add_exercise_technique_fields.sql"
