#!/usr/bin/env ruby
#
# Script to remove all broken file references from Xcode project
# Only removes references where the actual file does not exist on disk
#

require 'xcodeproj'

# Open the project
project_path = 'PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "Opened project: #{project_path}"

# Get the main target
target = project.targets.find { |t| t.name == 'PTPerformance' }

unless target
  puts "ERROR: Could not find PTPerformance target"
  exit 1
end

puts "Found target: #{target.name}"

removed_count = 0
base_path = Dir.pwd

puts "\n--- Checking for broken build phase references ---"

# Remove broken build phase entries
target.source_build_phase.files.dup.each do |build_file|
  next unless build_file.file_ref
  next unless build_file.file_ref.is_a?(Xcodeproj::Project::Object::PBXFileReference)

  begin
    real_path = build_file.file_ref.real_path.to_s

    unless File.exist?(real_path)
      puts "Removing broken build reference: #{build_file.file_ref.path}"
      puts "  -> Path was: #{real_path}"
      build_file.remove_from_project
      removed_count += 1
    end
  rescue => e
    puts "Removing problematic reference (error: #{e.message}): #{build_file.file_ref.path rescue 'unknown'}"
    build_file.remove_from_project
    removed_count += 1
  end
end

puts "\n--- Checking for broken file references in groups ---"

# Find all file references that point to non-existent files
def cleanup_group(group, base_path, removed_count_ref, target)
  group.children.dup.each do |child|
    if child.is_a?(Xcodeproj::Project::Object::PBXGroup)
      removed_count_ref[0] = cleanup_group(child, base_path, removed_count_ref, target)
    elsif child.is_a?(Xcodeproj::Project::Object::PBXFileReference)
      begin
        real_path = child.real_path.to_s

        unless File.exist?(real_path)
          puts "Removing broken file reference: #{child.path}"
          puts "  -> Path was: #{real_path}"
          child.remove_from_project
          removed_count_ref[0] += 1
        end
      rescue => e
        puts "Removing problematic file reference (error: #{e.message}): #{child.path rescue 'unknown'}"
        child.remove_from_project
        removed_count_ref[0] += 1
      end
    end
  end
  removed_count_ref[0]
end

removed_count_ref = [removed_count]
cleanup_group(project.main_group, base_path, removed_count_ref, target)
removed_count = removed_count_ref[0]

# Save the project
project.save

puts "\n--- Complete ---"
puts "Removed #{removed_count} broken reference(s)"
puts "Project saved successfully"
