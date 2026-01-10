#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

def print_group_structure(group, indent = 0)
  prefix = "  " * indent
  puts "#{prefix}📁 #{group.name || group.path || '(root)'} [path: '#{group.path}', sourceTree: '#{group.source_tree}']"

  group.children.each do |child|
    if child.is_a?(Xcodeproj::Project::Object::PBXGroup)
      print_group_structure(child, indent + 1)
    end
  end
end

main_group = project.main_group['PTPerformance']

if main_group
  puts "PTPerformance Group Structure:"
  puts "=" * 70
  print_group_structure(main_group)
else
  puts "PTPerformance group not found"
end
