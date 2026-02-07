//
//  TherapistSnapshotTests.swift
//  PTPerformanceTests
//
//  Snapshot/Preview verification tests for Therapist views.
//  Tests PatientListView, PatientDetailView, ClinicalAssessmentView,
//  SOAPNoteView, and RTSDashboardView components across different states.
//

import XCTest
import SwiftUI
@testable import PTPerformance

final class TherapistSnapshotTests: SnapshotTestCase {

    // MARK: - Sample Data Helpers

    private static var samplePatient: Patient {
        Patient(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            therapistId: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
            firstName: "John",
            lastName: "Brebbia",
            email: "john@example.com",
            sport: "Baseball",
            position: "Pitcher",
            injuryType: "Elbow UCL",
            targetLevel: "MLB",
            profileImageUrl: nil,
            createdAt: Date(),
            flagCount: 2,
            highSeverityFlagCount: 1,
            adherencePercentage: 85.5,
            lastSessionDate: Date()
        )
    }

    private static var patientWithAlerts: Patient {
        Patient(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            therapistId: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
            firstName: "Michael",
            lastName: "Smith",
            email: "michael@example.com",
            sport: "Football",
            position: "Quarterback",
            injuryType: "Shoulder Impingement",
            targetLevel: "College",
            profileImageUrl: nil,
            createdAt: Date(),
            flagCount: 5,
            highSeverityFlagCount: 3,
            adherencePercentage: 45.0,
            lastSessionDate: Date().addingTimeInterval(-86400 * 3)
        )
    }

    private static var patientNoFlags: Patient {
        Patient(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            therapistId: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
            firstName: "Sarah",
            lastName: "Johnson",
            email: "sarah@example.com",
            sport: "Soccer",
            position: "Forward",
            injuryType: "ACL Recovery",
            targetLevel: "Professional",
            profileImageUrl: nil,
            createdAt: Date(),
            flagCount: 0,
            highSeverityFlagCount: 0,
            adherencePercentage: 95.0,
            lastSessionDate: Date()
        )
    }

    // MARK: - PatientRowCard Tests

    func testPatientRowCard_Standard_LightMode() {
        let view = PatientRowCard(patient: Self.samplePatient)
            .frame(width: 350)
            .lightModeTest()
            .padding()

        verifyViewRenders(view, named: "PatientRowCard_Standard_Light")
    }

    func testPatientRowCard_Standard_DarkMode() {
        let view = PatientRowCard(patient: Self.samplePatient)
            .frame(width: 350)
            .darkModeTest()
            .padding()

        verifyViewRenders(view, named: "PatientRowCard_Standard_Dark")
    }

    func testPatientRowCard_WithAlerts() {
        let view = PatientRowCard(
            patient: Self.patientWithAlerts,
            coachingAlertCount: 3
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "PatientRowCard_WithAlerts")
    }

    func testPatientRowCard_NoFlags() {
        let view = PatientRowCard(patient: Self.patientNoFlags)
            .frame(width: 350)
            .padding()

        verifyViewRenders(view, named: "PatientRowCard_NoFlags")
    }

    func testPatientRowCard_BothColorSchemes() {
        let view = PatientRowCard(patient: Self.samplePatient)
            .frame(width: 350)
            .padding()

        verifyViewInBothColorSchemes(view, named: "PatientRowCard")
    }

    func testPatientRowCard_AccessibilityTextSizes() {
        let view = PatientRowCard(patient: Self.samplePatient)
            .frame(width: 350)
            .padding()

        verifyViewAcrossDynamicTypeSizes(view, named: "PatientRowCard")
    }

    // MARK: - PatientHeaderCard Tests

    func testPatientHeaderCard_LightMode() {
        let view = PatientHeaderCard(patient: Self.samplePatient)
            .frame(width: 350)
            .lightModeTest()
            .padding()

        verifyViewRenders(view, named: "PatientHeaderCard_Light")
    }

    func testPatientHeaderCard_DarkMode() {
        let view = PatientHeaderCard(patient: Self.samplePatient)
            .frame(width: 350)
            .darkModeTest()
            .padding()

        verifyViewRenders(view, named: "PatientHeaderCard_Dark")
    }

    func testPatientHeaderCard_BothColorSchemes() {
        let view = PatientHeaderCard(patient: Self.samplePatient)
            .frame(width: 350)
            .padding()

        verifyViewInBothColorSchemes(view, named: "PatientHeaderCard")
    }

    // MARK: - HighSeverityAlert Tests

    func testHighSeverityAlert_LightMode() {
        let view = HighSeverityAlert()
            .frame(width: 350)
            .lightModeTest()
            .padding()

        verifyViewRenders(view, named: "HighSeverityAlert_Light")
    }

    func testHighSeverityAlert_DarkMode() {
        let view = HighSeverityAlert()
            .frame(width: 350)
            .darkModeTest()
            .padding()

        verifyViewRenders(view, named: "HighSeverityAlert_Dark")
    }

    func testHighSeverityAlert_BothColorSchemes() {
        let view = HighSeverityAlert()
            .frame(width: 350)
            .padding()

        verifyViewInBothColorSchemes(view, named: "HighSeverityAlert")
    }

    // MARK: - QuickActionsCard Tests

    func testQuickActionsCard_LightMode() {
        let view = QuickActionsCard(
            onViewProgram: {},
            onAddNote: {},
            onPrescribeWorkout: {},
            onGenerateReport: {},
            onNewAssessment: {},
            onNewSOAPNote: {}
        )
        .frame(width: 350)
        .lightModeTest()
        .padding()

        verifyViewRenders(view, named: "QuickActionsCard_Light")
    }

    func testQuickActionsCard_DarkMode() {
        let view = QuickActionsCard(
            onViewProgram: {},
            onAddNote: {},
            onPrescribeWorkout: {},
            onGenerateReport: {},
            onNewAssessment: {},
            onNewSOAPNote: {}
        )
        .frame(width: 350)
        .darkModeTest()
        .padding()

        verifyViewRenders(view, named: "QuickActionsCard_Dark")
    }

    func testQuickActionsCard_MinimalActions() {
        let view = QuickActionsCard(
            onViewProgram: {},
            onAddNote: {},
            onPrescribeWorkout: {}
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "QuickActionsCard_Minimal")
    }

    func testQuickActionsCard_BothColorSchemes() {
        let view = QuickActionsCard(
            onViewProgram: {},
            onAddNote: {},
            onPrescribeWorkout: {},
            onGenerateReport: {}
        )
        .frame(width: 350)
        .padding()

        verifyViewInBothColorSchemes(view, named: "QuickActionsCard")
    }

    // MARK: - ActionButton Tests

    func testActionButton_Blue() {
        let view = ActionButton(
            title: "View Program",
            icon: "doc.text.fill",
            color: .blue,
            action: {}
        )
        .padding()

        verifyViewRenders(view, named: "ActionButton_Blue")
    }

    func testActionButton_Green() {
        let view = ActionButton(
            title: "Add Note",
            icon: "note.text.badge.plus",
            color: .green,
            action: {}
        )
        .padding()

        verifyViewRenders(view, named: "ActionButton_Green")
    }

    func testActionButton_Orange() {
        let view = ActionButton(
            title: "Prescribe Workout",
            icon: "dumbbell.fill",
            color: .orange,
            action: {}
        )
        .padding()

        verifyViewRenders(view, named: "ActionButton_Orange")
    }

    func testActionButton_Purple() {
        let view = ActionButton(
            title: "Generate Report",
            icon: "doc.richtext",
            color: .purple,
            action: {}
        )
        .padding()

        verifyViewRenders(view, named: "ActionButton_Purple")
    }

    func testActionButton_BothColorSchemes() {
        let view = ActionButton(
            title: "View Program",
            icon: "doc.text.fill",
            color: .blue,
            action: {}
        )
        .padding()

        verifyViewInBothColorSchemes(view, named: "ActionButton")
    }

    // MARK: - SectionErrorBanner Tests

    func testSectionErrorBanner_LightMode() {
        let view = SectionErrorBanner(message: "Failed to load flags data. Pull to refresh.")
            .frame(width: 350)
            .lightModeTest()
            .padding()

        verifyViewRenders(view, named: "SectionErrorBanner_Light")
    }

    func testSectionErrorBanner_DarkMode() {
        let view = SectionErrorBanner(message: "Pain trend data unavailable")
            .frame(width: 350)
            .darkModeTest()
            .padding()

        verifyViewRenders(view, named: "SectionErrorBanner_Dark")
    }

    func testSectionErrorBanner_BothColorSchemes() {
        let view = SectionErrorBanner(message: "Connection error")
            .frame(width: 350)
            .padding()

        verifyViewInBothColorSchemes(view, named: "SectionErrorBanner")
    }

    // MARK: - SelectablePatientRow Tests

    func testSelectablePatientRow_Selected() {
        let view = SelectablePatientRow(
            patient: Self.samplePatient,
            isSelected: true,
            onToggle: {}
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "SelectablePatientRow_Selected")
    }

    func testSelectablePatientRow_NotSelected() {
        let view = SelectablePatientRow(
            patient: Self.samplePatient,
            isSelected: false,
            onToggle: {}
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "SelectablePatientRow_NotSelected")
    }

    func testSelectablePatientRow_BothColorSchemes() {
        let view = SelectablePatientRow(
            patient: Self.samplePatient,
            isSelected: true,
            onToggle: {}
        )
        .frame(width: 350)
        .padding()

        verifyViewInBothColorSchemes(view, named: "SelectablePatientRow")
    }

    // MARK: - BulkActionBar Tests

    func testBulkActionBar_SingleSelection() {
        let view = BulkActionBar(
            selectedCount: 1,
            onAssignProgram: {},
            onExportSummary: {},
            onClearSelection: {}
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "BulkActionBar_SingleSelection")
    }

    func testBulkActionBar_MultipleSelection() {
        let view = BulkActionBar(
            selectedCount: 5,
            onAssignProgram: {},
            onExportSummary: {},
            onClearSelection: {}
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "BulkActionBar_MultipleSelection")
    }

    func testBulkActionBar_BothColorSchemes() {
        let view = BulkActionBar(
            selectedCount: 3,
            onAssignProgram: {},
            onExportSummary: {},
            onClearSelection: {}
        )
        .frame(width: 350)
        .padding()

        verifyViewInBothColorSchemes(view, named: "BulkActionBar")
    }

    // MARK: - SOAPSectionEditor Tests

    func testSOAPSectionEditor_Subjective_LightMode() {
        let view = StatefulTestWrapper("Patient reports moderate shoulder pain...") { text in
            SOAPSectionEditor(
                title: "Subjective",
                icon: "person.wave.2",
                iconColor: .blue,
                placeholder: "Patient's reported symptoms...",
                text: text,
                isLocked: false
            )
        }
        .frame(width: 350)
        .lightModeTest()
        .padding()

        verifyViewRenders(view, named: "SOAPSectionEditor_Subjective_Light")
    }

    func testSOAPSectionEditor_Objective_DarkMode() {
        let view = StatefulTestWrapper("ROM: Flexion 120 degrees...") { text in
            SOAPSectionEditor(
                title: "Objective",
                icon: "ruler",
                iconColor: .green,
                placeholder: "Measurable findings...",
                text: text,
                isLocked: false
            )
        }
        .frame(width: 350)
        .darkModeTest()
        .padding()

        verifyViewRenders(view, named: "SOAPSectionEditor_Objective_Dark")
    }

    func testSOAPSectionEditor_Locked() {
        let view = StatefulTestWrapper("Assessment content here...") { text in
            SOAPSectionEditor(
                title: "Assessment",
                icon: "stethoscope",
                iconColor: .purple,
                placeholder: "Clinical impression...",
                text: text,
                isLocked: true
            )
        }
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "SOAPSectionEditor_Locked")
    }

    func testSOAPSectionEditor_Empty() {
        let view = StatefulTestWrapper("") { text in
            SOAPSectionEditor(
                title: "Plan",
                icon: "list.clipboard",
                iconColor: .orange,
                placeholder: "Treatment plan, goals, next steps...",
                text: text,
                isLocked: false
            )
        }
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "SOAPSectionEditor_Empty")
    }

    func testSOAPSectionEditor_BothColorSchemes() {
        let view = StatefulTestWrapper("Sample content") { text in
            SOAPSectionEditor(
                title: "Subjective",
                icon: "person.wave.2",
                iconColor: .blue,
                placeholder: "Placeholder text",
                text: text,
                isLocked: false
            )
        }
        .frame(width: 350)
        .padding()

        verifyViewInBothColorSchemes(view, named: "SOAPSectionEditor")
    }

    // MARK: - RTSTrafficLightBadge Tests

    func testRTSTrafficLightBadge_Green_Small() {
        let view = RTSTrafficLightBadge(level: .green, size: .small)
            .padding()

        verifyViewRenders(view, named: "RTSTrafficLightBadge_Green_Small")
    }

    func testRTSTrafficLightBadge_Green_Medium() {
        let view = RTSTrafficLightBadge(level: .green, size: .medium)
            .padding()

        verifyViewRenders(view, named: "RTSTrafficLightBadge_Green_Medium")
    }

    func testRTSTrafficLightBadge_Green_Large() {
        let view = RTSTrafficLightBadge(level: .green, size: .large)
            .padding()

        verifyViewRenders(view, named: "RTSTrafficLightBadge_Green_Large")
    }

    func testRTSTrafficLightBadge_Yellow_Medium() {
        let view = RTSTrafficLightBadge(level: .yellow, size: .medium)
            .padding()

        verifyViewRenders(view, named: "RTSTrafficLightBadge_Yellow_Medium")
    }

    func testRTSTrafficLightBadge_Red_Medium() {
        let view = RTSTrafficLightBadge(level: .red, size: .medium)
            .padding()

        verifyViewRenders(view, named: "RTSTrafficLightBadge_Red_Medium")
    }

    func testRTSTrafficLightBadge_AllLevels() {
        let view = HStack(spacing: 24) {
            VStack {
                RTSTrafficLightBadge(level: .green, size: .large)
                Text("Cleared")
                    .font(.caption)
            }
            VStack {
                RTSTrafficLightBadge(level: .yellow, size: .large)
                Text("Caution")
                    .font(.caption)
            }
            VStack {
                RTSTrafficLightBadge(level: .red, size: .large)
                Text("Restricted")
                    .font(.caption)
            }
        }
        .padding()

        verifyViewRenders(view, named: "RTSTrafficLightBadge_AllLevels")
    }

    func testRTSTrafficLightBadge_BothColorSchemes() {
        let view = HStack(spacing: 16) {
            RTSTrafficLightBadge(level: .green, size: .large)
            RTSTrafficLightBadge(level: .yellow, size: .large)
            RTSTrafficLightBadge(level: .red, size: .large)
        }
        .padding()

        verifyViewInBothColorSchemes(view, named: "RTSTrafficLightBadge")
    }

    // MARK: - MetricCard Tests

    func testMetricCard_Volume() {
        let view = MetricCard(
            title: "Total Volume",
            value: "12.5k lbs",
            icon: "scalemass.fill",
            color: .blue
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "MetricCard_Volume")
    }

    func testMetricCard_WithSubtitle() {
        let view = MetricCard(
            title: "Average RPE",
            value: "7.5",
            subtitle: "out of 10",
            icon: "bolt.fill",
            color: .orange
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "MetricCard_WithSubtitle")
    }

    func testMetricCard_BothColorSchemes() {
        let view = MetricCard(
            title: "Duration",
            value: "45 min",
            icon: "clock.fill",
            color: .purple
        )
        .frame(width: 350)
        .padding()

        verifyViewInBothColorSchemes(view, named: "MetricCard")
    }

    // MARK: - Comprehensive Gallery Tests

    func testTherapistComponentsGallery_LightMode() {
        let view = ScrollView {
            VStack(spacing: 16) {
                PatientHeaderCard(patient: Self.samplePatient)
                HighSeverityAlert()
                QuickActionsCard(
                    onViewProgram: {},
                    onAddNote: {},
                    onPrescribeWorkout: {}
                )
                SectionErrorBanner(message: "Sample error message")
            }
            .frame(width: 350)
            .padding()
        }
        .lightModeTest()

        verifyViewRenders(view, named: "TherapistComponentsGallery_Light")
    }

    func testTherapistComponentsGallery_DarkMode() {
        let view = ScrollView {
            VStack(spacing: 16) {
                PatientHeaderCard(patient: Self.samplePatient)
                HighSeverityAlert()
                QuickActionsCard(
                    onViewProgram: {},
                    onAddNote: {},
                    onPrescribeWorkout: {}
                )
                SectionErrorBanner(message: "Sample error message")
            }
            .frame(width: 350)
            .padding()
        }
        .darkModeTest()

        verifyViewRenders(view, named: "TherapistComponentsGallery_Dark")
    }

    func testTherapistComponents_iPhoneAndIPad() {
        let view = VStack(spacing: 16) {
            PatientHeaderCard(patient: Self.samplePatient)
            QuickActionsCard(
                onViewProgram: {},
                onAddNote: {},
                onPrescribeWorkout: {}
            )
        }
        .padding()

        verifyViewAcrossDevices(
            view,
            named: "TherapistComponents",
            devices: [.iPhone15Pro, .iPadPro]
        )
    }
}
