#!/usr/bin/env ruby

# Script to add Build 62 AI Assistant files to Xcode project
# Build 62: AI Exercise Assistant
# Agent: 3

require 'xcodeproj'

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

puts "Adding Build 62 files to #{target.name}..."

# =====================================================
# Models
# =====================================================

models_group = project.main_group['PTPerformance']['Models'] ||
               project.main_group['PTPerformance'].new_group('Models')

# AssistantMessage.swift
assistant_message_file = models_group.new_file('Models/AssistantMessage.swift')
target.add_file_references([assistant_message_file])
puts "✅ Added AssistantMessage.swift to Models group"

# ExerciseContext.swift
exercise_context_file = models_group.new_file('Models/ExerciseContext.swift')
target.add_file_references([exercise_context_file])
puts "✅ Added ExerciseContext.swift to Models group"

# =====================================================
# Services
# =====================================================

services_group = project.main_group['PTPerformance']['Services'] ||
                 project.main_group['PTPerformance'].new_group('Services')

# AIAssistantService.swift
ai_service_file = services_group.new_file('Services/AIAssistantService.swift')
target.add_file_references([ai_service_file])
puts "✅ Added AIAssistantService.swift to Services group"

# =====================================================
# Views/AIAssistant
# =====================================================

views_group = project.main_group['PTPerformance']['Views'] ||
              project.main_group['PTPerformance'].new_group('Views')

ai_assistant_group = views_group['AIAssistant'] ||
                     views_group.new_group('AIAssistant')

# AIAssistantView.swift
ai_assistant_view_file = ai_assistant_group.new_file('Views/AIAssistant/AIAssistantView.swift')
target.add_file_references([ai_assistant_view_file])
puts "✅ Added AIAssistantView.swift to Views/AIAssistant group"

# QuickPromptsView.swift
quick_prompts_file = ai_assistant_group.new_file('Views/AIAssistant/QuickPromptsView.swift')
target.add_file_references([quick_prompts_file])
puts "✅ Added QuickPromptsView.swift to Views/AIAssistant group"

# ExerciseCardEmbed.swift
exercise_card_file = ai_assistant_group.new_file('Views/AIAssistant/ExerciseCardEmbed.swift')
target.add_file_references([exercise_card_file])
puts "✅ Added ExerciseCardEmbed.swift to Views/AIAssistant group"

# =====================================================
# Save project
# =====================================================

project.save

puts ""
puts "✨ Build 62 files successfully added to Xcode project!"
puts ""
puts "Files added:"
puts "  Models:"
puts "    - AssistantMessage.swift"
puts "    - ExerciseContext.swift"
puts "  Services:"
puts "    - AIAssistantService.swift"
puts "  Views/AIAssistant:"
puts "    - AIAssistantView.swift"
puts "    - QuickPromptsView.swift"
puts "    - ExerciseCardEmbed.swift"
puts ""
puts "Next steps:"
puts "  1. Open PTPerformance.xcodeproj in Xcode"
puts "  2. Add ANTHROPIC_API_KEY to .env file"
puts "  3. Build and test the AI Assistant"
puts "  4. Apply database migration: supabase migration up"
