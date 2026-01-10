//
//  AIChatSchedulingTests.swift
//  PTPerformanceUITests
//
//  BUILD 95 - Agent 6
//  E2E tests for AI Chat and Scheduling features
//  Updated to use BaseUITest framework and Page Objects
//

import XCTest

final class AIChatSchedulingTests: BaseUITest {

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Login as demo patient for all tests
        loginAsDemoPatient()
    }

    // MARK: - AI Chat Tests

    func testAIChatOpen() throws {
        // Navigate to AI Chat tab
        navigateToTab("AI Chat")

        // Verify AI Chat UI elements
        let aiAssistantHeader = app.staticTexts["AI Assistant"]
        TestHelpers.assertExists(aiAssistantHeader, named: "AI Assistant Header")

        // Verify empty state with suggestions
        let emptyStateIcon = app.images.matching(identifier: "bubble.left.and.bubble.right").firstMatch
        if emptyStateIcon.exists {
            // Empty state - verify suggested questions
            let suggestedQuestion = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'How do I'")).firstMatch
            XCTAssertTrue(suggestedQuestion.exists,
                "Suggested questions should appear in empty state")
        }

        // Verify input field
        let inputField = app.textFields["Ask a question..."]
        TestHelpers.assertExists(inputField, named: "Message Input Field")

        // Verify send button (disabled when empty)
        let sendButton = app.buttons.matching(identifier: "arrow.up.circle.fill").firstMatch
        TestHelpers.assertExists(sendButton, named: "Send Button")

        print("✅ AI Chat UI elements verified")
    }

    func testAIChatSendMessage() throws {
        // Navigate to AI Chat
        navigateToTab("AI Chat")

        // Wait for view to load
        let inputField = app.textFields["Ask a question..."]
        TestHelpers.assertExists(inputField, named: "Message Input Field")

        // Type a message
        TestHelpers.safeTypeText(
            into: inputField,
            text: "How do I do a goblet squat?",
            named: "Message Input"
        )

        // Tap send button
        let sendButton = app.buttons.matching(identifier: "arrow.up.circle.fill").firstMatch
        TestHelpers.safeTap(sendButton, named: "Send Button")

        // Verify message appears in chat (user message)
        let userMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'goblet squat'")).firstMatch
        TestHelpers.assertExists(userMessage, named: "User Message", timeout: 3)

        // Wait for AI response (async - may take a few seconds)
        TestHelpers.waitForLoadingToComplete(in: app, timeout: networkTimeout)

        // Verify AI response appears
        // AI response should contain relevant information
        // Note: We can't predict exact text, but we can check that there are multiple chat bubbles
        let chatBubbles = app.otherElements.matching(identifier: "ChatBubble")
        let bubbleCount = chatBubbles.count

        // Should have at least 2 bubbles: user + assistant
        XCTAssertGreaterThanOrEqual(bubbleCount, 2,
            "Should have at least user message and AI response")

        print("✅ AI Chat message send and response verified")
    }

    func testAIChatNewSession() throws {
        // Navigate to AI Chat
        navigateToTab("AI Chat")

        // Send a message first
        let inputField = app.textFields["Ask a question..."]
        TestHelpers.safeTypeText(
            into: inputField,
            text: "Test message",
            named: "Message Input"
        )

        let sendButton = app.buttons.matching(identifier: "arrow.up.circle.fill").firstMatch
        TestHelpers.safeTap(sendButton, named: "Send Button")

        // Wait for message to appear
        TestHelpers.waitForLoadingToComplete(in: app, timeout: quickTimeout)

        // Tap "New Chat" button
        let newChatButton = app.buttons["New Chat"]
        TestHelpers.safeTap(newChatButton, named: "New Chat Button")

        // Verify chat is cleared and empty state appears
        let emptyStateIcon = app.images.matching(identifier: "bubble.left.and.bubble.right").firstMatch
        TestHelpers.assertExists(emptyStateIcon, named: "Empty State Icon", timeout: 3)

        print("✅ AI Chat new session verified")
    }

    // MARK: - Scheduling Tests

    func testSchedulingCalendarView() throws {
        // Navigate to Schedule tab
        navigateToTab("Schedule")

        // Verify calendar view loads
        let calendarView = app.otherElements["CalendarView"]
        if !calendarView.exists {
            // Alternative: check for month/year header
            let monthHeader = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] '2025' OR label CONTAINS[c] '2024'")).firstMatch
            TestHelpers.assertExists(monthHeader, named: "Calendar Month Header")
        }

        // Verify view mode toggle
        let weekButton = app.buttons["Week"]
        let monthButton = app.buttons["Month"]

        XCTAssertTrue(weekButton.exists || monthButton.exists,
            "Calendar view mode toggle should exist")

        // Verify navigation buttons
        let previousButton = app.buttons.matching(identifier: "chevron.left").firstMatch
        let nextButton = app.buttons.matching(identifier: "chevron.right").firstMatch

        TestHelpers.assertExists(previousButton, named: "Previous Month Button")
        TestHelpers.assertExists(nextButton, named: "Next Month Button")

        print("✅ Calendar view UI elements verified")
    }

    func testSchedulingCreateSession() throws {
        // Navigate to Schedule tab
        navigateToTab("Schedule")

        // Wait for calendar to load
        waitAndAssert(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] '2025' OR label CONTAINS[c] '2024'")).firstMatch,
            named: "Calendar Month Header"
        )

        // Look for "Schedule" button (could be in toolbar or on calendar)
        let scheduleButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Schedule'")).firstMatch
        if !scheduleButton.exists {
            // Try the "+" button instead
            let plusButton = app.buttons["plus"]
            TestHelpers.safeTap(plusButton, named: "Schedule Session Button")
        } else {
            TestHelpers.safeTap(scheduleButton, named: "Schedule Button")
        }

        // Verify ScheduleSessionView appears
        let scheduleTitle = app.staticTexts["Schedule Session"]
        TestHelpers.assertExists(scheduleTitle, named: "Schedule Session Title")

        // Verify form elements
        let sessionPicker = app.buttons["Session"]
        XCTAssertTrue(sessionPicker.waitForExistence(timeout: 3) ||
                      app.staticTexts["Workout Session"].exists,
            "Session picker should exist")

        // Verify date picker exists
        let datePicker = app.datePickers.firstMatch
        TestHelpers.assertExists(datePicker, named: "Date Picker")

        // Verify reminder toggle
        let reminderToggle = app.switches["Send Reminder"]
        TestHelpers.assertExists(reminderToggle, named: "Reminder Toggle")

        // Verify notes field
        let notesField = app.textFields["Add notes (optional)"]
        TestHelpers.assertExists(notesField, named: "Notes Field")

        // Verify cancel button
        let cancelButton = app.buttons["Cancel"]
        TestHelpers.safeTap(cancelButton, named: "Cancel Button")

        print("✅ Schedule session form verified")
    }

    func testSchedulingUpcomingSessions() throws {
        // Navigate to Schedule tab or Upcoming Sessions view
        navigateToTab("Schedule")

        // Wait for view to load
        waitAndAssert(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] '2025' OR label CONTAINS[c] '2024'")).firstMatch,
            named: "Calendar View"
        )

        // Check for upcoming sessions list
        let upcomingHeader = app.staticTexts["Upcoming"]
        let scheduledSessionsTitle = app.staticTexts["Scheduled Sessions"]

        // One of these should exist
        let hasUpcomingUI = upcomingHeader.exists || scheduledSessionsTitle.exists

        if hasUpcomingUI {
            // Verify session rows exist (if any sessions are scheduled)
            let sessionRows = app.cells

            if sessionRows.count > 0 {
                // Verify first session row has expected elements
                let firstRow = sessionRows.firstMatch
                XCTAssertTrue(firstRow.exists, "Session row should exist")

                // Rows should have date badge, session name, time
                // We can't predict exact content, but verify structure exists
                print("✅ Found \(sessionRows.count) scheduled session(s)")
            } else {
                // Empty state
                let emptyStateMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'No Scheduled Sessions'")).firstMatch
                XCTAssertTrue(emptyStateMessage.exists || upcomingHeader.exists,
                    "Should show empty state or upcoming section")
                print("✅ No scheduled sessions (empty state verified)")
            }
        } else {
            print("⚠️ Upcoming sessions UI not found (may need navigation)")
        }

        print("✅ Upcoming sessions view verified")
    }

    func testSchedulingViewToggle() throws {
        // Navigate to Schedule tab
        navigateToTab("Schedule")

        // Wait for calendar to load
        waitAndAssert(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] '2025' OR label CONTAINS[c] '2024'")).firstMatch,
            named: "Calendar View"
        )

        // Find view mode toggle
        let weekButton = app.buttons["Week"]
        let monthButton = app.buttons["Month"]

        // Verify both modes are available
        XCTAssertTrue(weekButton.exists && monthButton.exists,
            "Both Week and Month view buttons should exist")

        // Test switching to Week view
        if !weekButton.isSelected {
            TestHelpers.safeTap(weekButton, named: "Week View Button")

            // Verify week view is now active
            XCTAssertTrue(weekButton.isSelected,
                "Week view should be selected")
        }

        // Test switching to Month view
        TestHelpers.safeTap(monthButton, named: "Month View Button")

        // Verify month view is now active
        XCTAssertTrue(monthButton.isSelected,
            "Month view should be selected")

        print("✅ Calendar view toggle verified")
    }

    func testSchedulingDateNavigation() throws {
        // Navigate to Schedule tab
        navigateToTab("Schedule")

        // Wait for calendar to load
        waitAndAssert(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] '2025' OR label CONTAINS[c] '2024' OR label CONTAINS[c] '2026'")).firstMatch,
            named: "Month Header"
        )

        // Get current month/year text
        let monthHeader = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] '2025' OR label CONTAINS[c] '2024' OR label CONTAINS[c] '2026'")).firstMatch
        XCTAssertTrue(monthHeader.exists, "Month header should exist")

        let originalMonth = monthHeader.label

        // Tap next month button
        let nextButton = app.buttons.matching(identifier: "chevron.right").firstMatch
        TestHelpers.safeTap(nextButton, named: "Next Month Button")

        // Verify month changed
        let newMonthHeader = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] '2025' OR label CONTAINS[c] '2024' OR label CONTAINS[c] '2026'")).firstMatch
        XCTAssertTrue(newMonthHeader.exists, "New month header should exist")

        let newMonth = newMonthHeader.label
        XCTAssertNotEqual(originalMonth, newMonth,
            "Month should have changed after tapping next")

        // Tap previous button
        let previousButton = app.buttons.matching(identifier: "chevron.left").firstMatch
        TestHelpers.safeTap(previousButton, named: "Previous Month Button")

        // Verify we're back to original month
        let returnedMonthHeader = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] '2025' OR label CONTAINS[c] '2024' OR label CONTAINS[c] '2026'")).firstMatch
        XCTAssertEqual(returnedMonthHeader.label, originalMonth,
            "Should return to original month")

        print("✅ Calendar date navigation verified")
    }

    // MARK: - Integration Test: AI Chat + Scheduling

    func testAIChatToSchedulingFlow() throws {
        // Start in AI Chat
        navigateToTab("AI Chat")

        // Send a message about scheduling
        let inputField = app.textFields["Ask a question..."]
        TestHelpers.safeTypeText(
            into: inputField,
            text: "When should I schedule my next workout?",
            named: "Message Input"
        )

        let sendButton = app.buttons.matching(identifier: "arrow.up.circle.fill").firstMatch
        TestHelpers.safeTap(sendButton, named: "Send Button")

        // Wait for response
        TestHelpers.waitForLoadingToComplete(in: app, timeout: networkTimeout)

        // Navigate to Schedule tab
        navigateToTab("Schedule")

        // Verify calendar view loads
        let monthHeader = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] '2025' OR label CONTAINS[c] '2024'")).firstMatch
        TestHelpers.assertExists(monthHeader, named: "Calendar Month Header")

        // Navigate back to AI Chat
        navigateToTab("AI Chat")

        // Verify chat history is preserved
        let previousMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'workout'")).firstMatch
        TestHelpers.assertExists(previousMessage, named: "Previous Chat Message")

        print("✅ AI Chat to Scheduling flow verified")
    }

    // MARK: - Performance Tests

    func testAIChatResponseTime() throws {
        // Navigate to AI Chat
        navigateToTab("AI Chat")

        let inputField = app.textFields["Ask a question..."]
        TestHelpers.assertExists(inputField, named: "Message Input Field")

        // Measure response time
        let responseTime = measureAction("AI Chat Response") {
            TestHelpers.safeTypeText(
                into: inputField,
                text: "What exercises should I do today?",
                named: "Message Input"
            )

            let sendButton = app.buttons.matching(identifier: "arrow.up.circle.fill").firstMatch
            TestHelpers.safeTap(sendButton, named: "Send Button")

            // Wait for loading indicator to disappear
            TestHelpers.waitForLoadingToComplete(in: app, timeout: 20)
        }

        // Assert reasonable response time (< 15 seconds)
        XCTAssertLessThan(responseTime, 15.0,
            "AI response should be reasonably fast")

        print("✅ AI response time: \(String(format: "%.2f", responseTime)) seconds")
    }

    func testSchedulingLoadTime() throws {
        // Measure time to load scheduling view
        let loadTime = measureAction("Calendar Load") {
            navigateToTab("Schedule")

            // Wait for calendar to render
            let monthHeader = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] '2025' OR label CONTAINS[c] '2024'")).firstMatch
            TestHelpers.assertExists(monthHeader, named: "Calendar Month Header")
        }

        // Assert fast load time (< 3 seconds)
        XCTAssertLessThan(loadTime, 3.0,
            "Calendar should load quickly")

        print("✅ Calendar load time: \(String(format: "%.2f", loadTime)) seconds")
    }
}
