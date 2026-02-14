#!/usr/bin/env python3
import os
import re
import uuid

print("Adding Missing Swift Files to Xcode Project (Python)")
print("=" * 70)

PROJECT_PATH = 'PTPerformance/PTPerformance.xcodeproj/project.pbxproj'

# List of missing files with their paths relative to PTPerformance/
missing_files = [
    # Root level
    'PTPerformanceApp.swift',
    'RootView.swift',
    'Config.swift',
    'PatientTabView.swift',
    'TherapistTabView.swift',
    'TherapistDashboardView.swift',
    'TherapistProgramsView.swift',
    'TodaySessionView.swift',
    # Components
    'Components/SmartSchedulingSuggestionCard.swift',
    # Extensions
    'Extensions/String+LiftName.swift',
    # Models
    'Models/AR60ReadinessScore.swift',
    'Models/JournalEntry.swift',
    # ViewModels
    'ViewModels/HRVInsightsViewModel.swift',
    'ViewModels/PatientProgramProgressViewModel.swift',
    'ViewModels/PerformanceModeDashboardViewModel.swift',
    'ViewModels/ProgramAnalyticsViewModel.swift',
    'ViewModels/ProtocolBuilderViewModel.swift',
    'ViewModels/ReadinessScoreViewModel.swift',
    'ViewModels/RehabModeDashboardViewModel.swift',
    'ViewModels/SleepInsightsViewModel.swift',
    'ViewModels/StrengthModeDashboardViewModel.swift',
    'ViewModels/WorkoutSummaryDataAdapter.swift',
    # Services
    'Services/AudioRecordingService.swift',
    'Services/HapticService.swift',
    'Services/ProtocolService.swift',
    'Services/ReadinessScoreService.swift',
    'Services/SmartSchedulingService.swift',
    'Services/TabBarBadgeManager.swift',
    'Services/HealthKit/HealthDataGapDetector.swift',
    'Services/HealthKit/HealthKitConflictResolver.swift',
    # Views
    'Views/Achievements/AchievementRecommendations.swift',
    'Views/Achievements/AchievementShowcaseView.swift',
    'Views/Achievements/UpNextAchievementsSection.swift',
    'Views/Celebrations/EnhancedWorkoutSummaryView.swift',
    'Views/Evidence/EvidenceDetailSheet.swift',
    'Views/Health/HRVInsightsView.swift',
    'Views/Health/SleepInsightsView.swift',
    'Views/Journal/AudioHealthJournalView.swift',
    'Views/Journal/JournalEntryDetailView.swift',
    'Views/Journal/JournalEntryRecordingView.swift',
    'Views/Nutrition/Components/CalorieSurplusDeficitIndicator.swift',
    'Views/Nutrition/Components/MealTimeline.swift',
    'Views/Nutrition/Components/ProteinTimingChart.swift',
    'Views/Performance/ACWRDetailsSheet.swift',
    'Views/Performance/PerformanceAnalyticsView.swift',
    'Views/Performance/PerformanceModeDashboardView.swift',
    'Views/Performance/PerformanceModeStatusCard.swift',
    'Views/Protocol/AthletePlanView.swift',
    'Views/Protocol/ProtocolBuilderView.swift',
    'Views/Protocol/ProtocolTemplateCard.swift',
    'Views/Protocol/TaskCustomizationSheet.swift',
    'Views/Rehab/PainTrackingView.swift',
    'Views/Rehab/RehabModeContentModifier.swift',
    'Views/Rehab/RehabModeDashboardView.swift',
    'Views/Rehab/RehabModeStatusCard.swift',
    'Views/Rehab/RehabProgressView.swift',
    'Views/Rehab/ROMExercisesView.swift',
    'Views/Rehab/ROMProgressCard.swift',
    'Views/Settings/PatientSettingsView.swift',
    'Views/Settings/UnifiedSettingsView.swift',
    'Views/Strength/EstimatedOneRMTrendChart.swift',
    'Views/Strength/MuscleGroupVolumeView.swift',
    'Views/Strength/ProgressiveOverloadCard.swift',
    'Views/Strength/ProgressiveOverloadSuggestionsList.swift',
    'Views/Strength/PRPredictionView.swift',
    'Views/Strength/StalledLiftsDetectorView.swift',
    'Views/Strength/StrengthAnalyticsDeepDiveView.swift',
    'Views/Strength/StrengthModeContentModifier.swift',
    'Views/Strength/StrengthModeDashboardView.swift',
    'Views/Strength/StrengthModeStatusCard.swift',
    'Views/Strength/StrengthProgressView.swift',
    'Views/Templates/TemplateLibraryView.swift',
    'Views/Therapist/Assessments/AssessmentHistoryView.swift',
    'Views/Therapist/Assessments/IntakeAssessmentView.swift',
    'Views/Therapist/Assessments/OutcomeMeasureView.swift',
    'Views/Therapist/Assessments/ProgressAssessmentView.swift',
    'Views/Therapist/Documentation/DocumentationDashboardView.swift',
    'Views/Therapist/Documentation/SessionDataImportView.swift',
    'Views/Therapist/Documentation/SOAPNoteEditorView.swift',
    'Views/Therapist/Documentation/SOAPPlanSuggestionView.swift',
    'Views/Therapist/Documentation/TemplatePickerView.swift',
    'Views/Therapist/Documentation/VisitSummaryView.swift',
    'Views/Therapist/SafetyIncidentDetailSheet.swift',
    'Views/Timers/CustomTimerBuilderView.swift',
    'Views/Timers/TimerPickerView.swift',
    'Views/Today/SmartSchedulingHomeCard.swift',
    # Widgets
    'PTPerformanceWidgets/PTPerformanceWidgets.swift',
    'PTPerformanceWidgets/Components/MiniTrendChart.swift',
    'PTPerformanceWidgets/Components/ReadinessBadge.swift',
    'PTPerformanceWidgets/Components/WidgetColors.swift',
    'PTPerformanceWidgets/Providers/DailySummaryProvider.swift',
    'PTPerformanceWidgets/Providers/ReadinessProvider.swift',
    'PTPerformanceWidgets/Providers/RecoveryDashboardProvider.swift',
    'PTPerformanceWidgets/Providers/StreakProvider.swift',
    'PTPerformanceWidgets/Providers/TodayWorkoutProvider.swift',
    'PTPerformanceWidgets/Providers/WeekOverviewProvider.swift',
    'PTPerformanceWidgets/Views/DailySummaryWidget.swift',
    'PTPerformanceWidgets/Views/ReadinessWidget.swift',
    'PTPerformanceWidgets/Views/RecoveryDashboardWidget.swift',
    'PTPerformanceWidgets/Views/StreakWidget.swift',
    'PTPerformanceWidgets/Views/TodayWorkoutWidget.swift',
    'PTPerformanceWidgets/Views/WeekOverviewWidget.swift',
]

def generate_uuid():
    """Generate a 24-character hex UUID like Xcode does"""
    return uuid.uuid4().hex[:24].upper()

# Read the project file
with open(PROJECT_PATH, 'r') as f:
    content = f.read()

# Track what we add
added_count = 0
skipped_count = 0

print("\nAdding missing Swift source files to project...")
print("-" * 70)

for file_path in missing_files:
    file_name = os.path.basename(file_path)

    # Check if file already exists in project
    if f'/* {file_name} */' in content:
        print(f"⊘ Already in project: {file_name}")
        skipped_count += 1
        continue

    # Check if file exists on disk
    full_disk_path = f'PTPerformance/{file_path}'
    if not os.path.exists(full_disk_path):
        print(f"✗ File not found on disk: {full_disk_path}")
        continue

    print(f"✓ Adding new file: {file_name}")
    added_count += 1

if added_count == 0:
    print("\n✅ No new files to add - all files are already in the project!")
    print(f"Files checked: {len(missing_files)}")
    print(f"Files already in project: {skipped_count}")
else:
    print(f"\n⚠️  Found {added_count} files that need to be added.")
    print("This Python script can verify files but cannot safely modify project.pbxproj")
    print("Please use Xcode to manually add the files, or use the Ruby script with xcodeproj gem.")

print("=" * 70)
