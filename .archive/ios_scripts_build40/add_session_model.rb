#!/usr/bin/env ruby
require 'xcodeproj'

project_path = '/Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the Models group
models_group = project.main_group['PTPerformance']['Models']
unless models_group
  puts "❌ Models group not found"
  exit 1
end

# Add Session.swift if not already added
session_file = models_group.files.find { |f| f.path == 'Session.swift' }
unless session_file
  file_ref = models_group.new_file('Session.swift')

  # Add to target
  target = project.targets.first
  target.add_file_references([file_ref])

  puts "✅ Added Session.swift to project"
else
  puts "✅ Session.swift already in project"
end

project.save
puts "✅ Project saved"
