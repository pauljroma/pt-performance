require 'xcodeproj'

project_path = 'PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'PTPerformance' }

def find_or_create_group(project, path_components)
  current_group = project.main_group
  path_components.each do |component|
    next_group = current_group.children.find { |g| g.is_a?(Xcodeproj::Project::Object::PBXGroup) && g.name == component }
    if next_group.nil?
      next_group = current_group.new_group(component)
    end
    current_group = next_group
  end
  current_group
end

files_to_add = [
  # Fasting Models & Services
  { path: 'Models/FastingModels.swift', group: ['Models'] },
  { path: 'Services/FastingService.swift', group: ['Services'] },

  # Supplement Models & Services
  { path: 'Models/SupplementModels.swift', group: ['Models'] },
  { path: 'Services/SupplementService.swift', group: ['Services'] },
  { path: 'ViewModels/SupplementViewModel.swift', group: ['ViewModels'] },

  # Supplement Views
  { path: 'Views/Health/SupplementDashboardView.swift', group: ['Views', 'Health'] },
  { path: 'Views/Health/SupplementLogView.swift', group: ['Views', 'Health'] },
  { path: 'Views/Health/SupplementCatalogView.swift', group: ['Views', 'Health'] },
  { path: 'Views/Health/SupplementDetailView.swift', group: ['Views', 'Health'] },
  { path: 'Views/Health/SupplementStacksView.swift', group: ['Views', 'Health'] },
  { path: 'Views/Health/MySupplementRoutineView.swift', group: ['Views', 'Health'] },
  { path: 'Views/Health/SupplementHistoryView.swift', group: ['Views', 'Health'] },
]

added = 0
skipped = 0

# Get list of existing file paths
existing_paths = project.files.map { |f| f.path }.compact

files_to_add.each do |file_info|
  file_path = file_info[:path]
  full_path = File.join(Dir.pwd, file_path)

  unless File.exist?(full_path)
    puts "⚠️  File not found: #{file_path}"
    next
  end

  # Check if already in project by path
  if existing_paths.include?(file_path) || existing_paths.include?(full_path)
    puts "⏭️  Already in project: #{file_path}"
    skipped += 1
    next
  end

  group = find_or_create_group(project, file_info[:group])
  file_ref = group.new_file(full_path)
  target.source_build_phase.add_file_reference(file_ref)
  puts "✅ Added: #{file_path}"
  added += 1
end

project.save
puts "\n📊 Summary: Added #{added} files, skipped #{skipped} existing"
