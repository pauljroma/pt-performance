#!/usr/bin/env ruby

require 'xcodeproj'

project_path = '/Users/expo/Code/expo/ios-app/PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "Main group children:"
project.main_group.groups.each do |group|
  puts "  - #{group.name || group.path}"
end
