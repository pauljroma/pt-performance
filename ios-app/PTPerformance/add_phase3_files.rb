#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'PTPerformance' }
main_group = project.main_group.groups.find { |g| g.display_name == 'PTPerformance' }

phase3_files = %w[
  Models/EvidenceCitation.swift
  Models/RiskEscalation.swift
  Models/DataConflict.swift
  Models/WeeklyReport.swift
  Models/TrendAnalysis.swift
  Services/CitationService.swift
  Services/RiskEscalationService.swift
  Services/ConflictResolutionService.swift
  Services/WeeklyReportService.swift
  Services/ReportPDFGenerator.swift
  Services/TrendAnalysisService.swift
  ViewModels/EvidenceCitationViewModel.swift
  ViewModels/EscalationQueueViewModel.swift
  ViewModels/ConflictResolutionViewModel.swift
  ViewModels/WeeklyReportViewModel.swift
  ViewModels/TrendAnalysisViewModel.swift
  ViewModels/X2CommandCenterViewModel.swift
  Views/Evidence/EvidenceCitationView.swift
  Views/Evidence/CitationSourceCard.swift
  Views/Therapist/SafetyAlertCard.swift
  Views/Therapist/EscalationQueueView.swift
  Views/Therapist/WeeklyReportView.swift
  Views/Therapist/ReportHistoryView.swift
  Views/Therapist/GenerateWeeklyReportSheet.swift
  Views/Conflicts/ConflictCard.swift
  Views/Conflicts/ConflictResolutionView.swift
  Views/Conflicts/ConflictHistoryView.swift
  Views/Conflicts/ConflictsListView.swift
  Views/Analytics/TrendAnalysisView.swift
  Views/Analytics/MetricTrendCard.swift
  Views/Analytics/ComparePeriodView.swift
  Views/Analytics/TrendInsightsView.swift
  Views/X2Index/X2CommandCenterView.swift
  Views/X2Index/ConflictResolutionSheet.swift
  Views/X2Index/WeeklyReportGeneratorSheet.swift
  Views/X2Index/HistoricalTrendsView.swift
  Components/RiskBadge.swift
  Components/ReportMetricCard.swift
]

added = 0
phase3_files.each do |file_path|
  next unless File.exist?(file_path)
  file_name = File.basename(file_path)
  next if project.files.any? { |f| f.display_name == file_name }

  parts = file_path.split('/')
  current_group = main_group
  parts[0..-2].each do |part|
    existing = current_group.groups.find { |g| g.display_name == part || g.name == part }
    current_group = existing || current_group.new_group(part)
  end

  file_ref = current_group.new_file(file_path)
  target.source_build_phase.add_file_reference(file_ref)
  puts "✅ #{file_path}"
  added += 1
end

project.save
puts "\n✅ Added #{added} files"
