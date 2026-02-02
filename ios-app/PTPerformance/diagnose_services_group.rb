#!/usr/bin/env ruby
#
# Script to diagnose Services group structure in Xcode project
#

require 'xcodeproj'

# Open the project
project_path = 'PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "Opened project: #{project_path}"

# Find all Services groups
def find_all_services_groups(group, path = "", results = [])
  group.children.each do |child|
    if child.is_a?(Xcodeproj::Project::Object::PBXGroup)
      child_name = child.name || child.path
      child_path = "#{path}/#{child_name}"

      if child_name == 'Services'
        results << {
          path: child_path,
          group_path: child.path,
          source_tree: child.source_tree,
          uuid: child.uuid,
          files_count: child.files.count
        }
      end

      find_all_services_groups(child, child_path, results)
    end
  end
  results
end

puts "\n--- All Services Groups ---"
services_groups = find_all_services_groups(project.main_group)

services_groups.each_with_index do |sg, idx|
  puts "\nServices Group ##{idx + 1}:"
  puts "  Hierarchy: #{sg[:path]}"
  puts "  Group path attr: #{sg[:group_path].inspect}"
  puts "  Source tree: #{sg[:source_tree]}"
  puts "  UUID: #{sg[:uuid]}"
  puts "  Files count: #{sg[:files_count]}"
end

# Find PTPerformance group's Services subgroup
pt_group = project.main_group.find_subpath('PTPerformance', true)
if pt_group
  services_in_pt = pt_group.children.find { |c| (c.name || c.path) == 'Services' }
  if services_in_pt
    puts "\n--- Services in PTPerformance ---"
    puts "UUID: #{services_in_pt.uuid}"
    puts "path attribute: #{services_in_pt.path.inspect}"
    puts "name attribute: #{services_in_pt.name.inspect}"
    puts "source_tree: #{services_in_pt.source_tree}"
    puts "\nFiles in this group:"
    services_in_pt.files.each do |f|
      puts "  - #{f.path.inspect} (name: #{f.name.inspect})"
    end
  end
end
