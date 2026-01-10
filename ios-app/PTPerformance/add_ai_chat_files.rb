#!/usr/bin/env ruby
require 'securerandom'

# Files to add
files = [
  { path: "Views/AI/AIChatView.swift", name: "AIChatView.swift" },
  { path: "Views/AI/AISafetyAlert.swift", name: "AISafetyAlert.swift" },
  { path: "Views/AI/AISubstitutionSheet.swift", name: "AISubstitutionSheet.swift" },
  { path: "Services/AIChatService.swift", name: "AIChatService.swift" }
]

# Generate UUIDs (Xcode uses 24-char hex IDs)
def generate_id
  SecureRandom.hex(12).upcase
end

# Print the entries needed
puts "=== PBXBuildFile section ==="
files.each do |file|
  build_file_id = generate_id
  file_ref_id = generate_id
  file[:build_file_id] = build_file_id
  file[:file_ref_id] = file_ref_id
  puts "\t\t#{build_file_id} /* #{file[:name]} in Sources */ = {isa = PBXBuildFile; fileRef = #{file_ref_id} /* #{file[:name]} */; };"
end

puts "\n=== PBXFileReference section ==="
files.each do |file|
  puts "\t\t#{file[:file_ref_id]} /* #{file[:name]} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = #{file[:name]}; sourceTree = \"<group>\"; };"
end

puts "\n=== Add to PBXSourcesBuildPhase (find the section and add these IDs) ==="
files.each do |file|
  puts "\t\t\t\t#{file[:build_file_id]} /* #{file[:name]} in Sources */,"
end

puts "\n=== Add to PBXGroup for Views/AI ==="
files[0..2].each do |file|
  puts "\t\t\t\t#{file[:file_ref_id]} /* #{file[:name]} */,"
end

puts "\n=== Add to PBXGroup for Services ==="
  puts "\t\t\t\t#{files[3][:file_ref_id]} /* #{files[3][:name]} */,"
