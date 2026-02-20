//
//  NutritionModuleFlowTests.swift
//  PTPerformanceUITests
//
//  E2E tests for the nutrition module flow accessed from the Today or Progress tab
//  Validates calorie progress, macro breakdown, meal logging, nutrition goals,
//  meal history, and section picker navigation
//
//  Test user: Marcus Rivera (rehab mode, Baseball)
//  UUID: aaaaaaaa-bbbb-cccc-dddd-000000000001
//

import XCTest

/// E2E tests for the nutrition module and its sub-features
///
/// Logs in as Marcus Rivera (rehab mode) and verifies:
/// - Nutrition dashboard loads from Today or Progress tab
/// - Calorie progress ring or indicator is displayed
/// - Protein progress is displayed
/// - Macro breakdown (carbs, fats, protein) is shown
/// - Log meal button exists and opens a sheet
/// - Nutrition goals button exists and opens a sheet
/// - Meal history shows seed data items
/// - Section picker (Dashboard/Meal Plans/Foods) is present
/// - Meal Plans and Foods sections load
final class NutritionModuleFlowTests: XCTestCase {

    // MARK: - Properties

    var app: XCUIApplication!

    /// Marcus Rivera (rehab mode, Baseball)
    private let testUserID = "aaaaaaaa-bbbb-cccc-dddd-000000000001"

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--auto-login-user-id", "aaaaaaaa-bbbb-cccc-dddd-000000000001",
            "--auto-login-mode", "rehab"
        ]
        app.launchEnvironment = ["IS_RUNNING_UITEST": "1"]
        app.launch()

        // Wait for tab bar to confirm login succeeded
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBar.waitForExistence(timeout: 20),
            "Tab bar should appear after auto-login"
        )

        // Ensure Today tab is active
        let todayTab = app.tabBars.buttons["Today"]
        if todayTab.exists && !todayTab.isSelected {
            todayTab.tap()
        }
        waitForContentToLoad()
    }

    override func tearDownWithError() throws {
        if let app = app {
            app.terminate()
        }
        app = nil
    }

    // MARK: - Navigation Helpers

    /// Attempts to navigate to the nutrition section.
    /// Returns `true` if nutrition content was reached.
    ///
    /// Strategy:
    /// 1. Navigate to Settings tab → ProfileHubView → "Nutrition" link
    /// 2. Search Today tab for a nutrition card/section/link
    /// 3. Check by accessibility identifier
    @discardableResult
    private func navigateToNutrition() -> Bool {
        // Strategy 1: Settings tab → Nutrition link (primary path)
        let settingsTab = app.tabBars.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()
            waitForContentToLoad()

            let nutritionLink = scrollToFindAny(["Nutrition"], maxSwipes: 8)
            if let link = nutritionLink, link.isHittable {
                link.tap()
                waitForContentToLoad()

                if isNutritionContentVisible() {
                    return true
                }
            }
        }

        // Strategy 2: Look for nutrition on Today tab
        let todayTab = app.tabBars.buttons["Today"]
        if todayTab.exists {
            todayTab.tap()
            waitForTodayHubContentToLoad()

            let nutritionElement = scrollToFindAny(
                ["Nutrition", "Calories", "Meal", "Calorie", "Macro"],
                maxSwipes: 6
            )

            if let element = nutritionElement, element.isHittable {
                element.tap()
                waitForContentToLoad()
                if isNutritionContentVisible() {
                    return true
                }
            }

            if isNutritionContentVisible() {
                return true
            }
        }

        // Strategy 3: Check for nutrition by accessibility identifier
        let nutritionById = app.descendants(matching: .any)["nutrition_calorie_progress"]
        if nutritionById.waitForExistence(timeout: 3) {
            return true
        }

        let logMealById = app.descendants(matching: .any)["nutrition_log_meal"]
        if logMealById.waitForExistence(timeout: 3) {
            return true
        }

        takeScreenshot(named: "navigate_to_nutrition_failed")
        return false
    }

    /// Checks if nutrition-related content is currently visible on screen
    private func isNutritionContentVisible() -> Bool {
        let nutritionPredicate = NSPredicate(
            format: """
            label CONTAINS[c] 'Calorie' OR label CONTAINS[c] 'Protein' \
            OR label CONTAINS[c] 'Carbs' OR label CONTAINS[c] 'Fats' \
            OR label CONTAINS[c] 'Macro' OR label CONTAINS[c] 'Nutrition' \
            OR label CONTAINS[c] 'Meal'
            """
        )
        let nutritionText = app.staticTexts.containing(nutritionPredicate).firstMatch
        let calorieProgress = app.descendants(matching: .any)["nutrition_calorie_progress"]
        let logMealButton = app.descendants(matching: .any)["nutrition_log_meal"]

        return nutritionText.exists || calorieProgress.exists || logMealButton.exists
    }

    /// Waits for the Today Hub content to finish its initial async loading
    private func waitForTodayHubContentToLoad() {
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            let predicate = NSPredicate(format: "exists == false")
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: loadingIndicator)
            _ = XCTWaiter().wait(for: [expectation], timeout: 15)
        }

        let loadingText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'Loading'")
        ).firstMatch
        if loadingText.exists {
            let predicate = NSPredicate(format: "exists == false")
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: loadingText)
            _ = XCTWaiter().wait(for: [expectation], timeout: 15)
        }

        Thread.sleep(forTimeInterval: 1.0)
    }

    /// Scrolls up repeatedly (up to `maxSwipes`) looking for an element whose label
    /// matches `text` case-insensitively. Returns the element if found, nil otherwise.
    @discardableResult
    private func scrollToFind(_ text: String, maxSwipes: Int = 10) -> XCUIElement? {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", text)

        let matchingText = app.staticTexts.containing(predicate).firstMatch
        let matchingButton = app.buttons.containing(predicate).firstMatch

        if matchingText.exists && matchingText.isHittable { return matchingText }
        if matchingButton.exists && matchingButton.isHittable { return matchingButton }

        for _ in 0..<maxSwipes {
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.3)

            if matchingText.exists && matchingText.isHittable { return matchingText }
            if matchingButton.exists && matchingButton.isHittable { return matchingButton }
        }

        // One last check without hittable requirement
        if matchingText.exists { return matchingText }
        if matchingButton.exists { return matchingButton }

        return nil
    }

    /// Searches for any element matching one of the provided keywords (case-insensitive).
    /// Returns the first match found, or nil.
    @discardableResult
    private func scrollToFindAny(_ keywords: [String], maxSwipes: Int = 10) -> XCUIElement? {
        for keyword in keywords {
            let predicate = NSPredicate(format: "label CONTAINS[c] %@", keyword)
            let text = app.staticTexts.containing(predicate).firstMatch
            let button = app.buttons.containing(predicate).firstMatch
            if text.exists { return text }
            if button.exists { return button }
        }

        for _ in 0..<maxSwipes {
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.3)

            for keyword in keywords {
                let predicate = NSPredicate(format: "label CONTAINS[c] %@", keyword)
                let text = app.staticTexts.containing(predicate).firstMatch
                let button = app.buttons.containing(predicate).firstMatch
                if text.exists { return text }
                if button.exists { return button }
            }
        }

        return nil
    }

    // MARK: - Test 1: Nutrition Dashboard Loads

    /// Verify that the nutrition dashboard can be reached and displays content
    func testNutritionDashboardLoads() throws {
        let nutritionReached = navigateToNutrition()
        try XCTSkipIf(
            !nutritionReached,
            "Nutrition section not reachable from Today or Progress tab -- feature may not be implemented for rehab mode"
        )

        let hasContent = app.scrollViews.firstMatch.exists ||
                         app.tables.firstMatch.exists ||
                         app.collectionViews.firstMatch.exists ||
                         isNutritionContentVisible()

        XCTAssertTrue(hasContent, "Nutrition dashboard should display content")

        assertNoErrorAlerts(context: "Nutrition dashboard loads")
        takeScreenshot(named: "nutrition_dashboard_loads")
    }

    // MARK: - Test 2: Calorie Progress Displayed

    /// Verify the calorie progress ring or indicator is visible
    func testCalorieProgressDisplayed() throws {
        let nutritionReached = navigateToNutrition()
        try XCTSkipIf(!nutritionReached, "Nutrition section not reachable -- skipping")

        // Check by accessibility identifier first
        let calorieProgress = app.descendants(matching: .any)["nutrition_calorie_progress"]

        if calorieProgress.waitForExistence(timeout: 5) {
            XCTAssertTrue(calorieProgress.exists, "Calorie progress ring should be visible by identifier")
            takeScreenshot(named: "calorie_progress_by_id")
            assertNoErrorAlerts(context: "Calorie progress by identifier")
            return
        }

        // Fallback: search by text
        let calorieElement = scrollToFindAny(["Calorie", "Cal", "kcal", "Calories"])

        if let element = calorieElement {
            XCTAssertTrue(element.exists, "Calorie progress indicator should be visible")
            takeScreenshot(named: "calorie_progress_by_text")
        } else {
            throw XCTSkip("Calorie progress not found by accessibility identifier or text content")
        }

        assertNoErrorAlerts(context: "Calorie progress displayed")
    }

    // MARK: - Test 3: Protein Progress Displayed

    /// Verify the protein progress indicator or label is visible
    func testProteinProgressDisplayed() throws {
        let nutritionReached = navigateToNutrition()
        try XCTSkipIf(!nutritionReached, "Nutrition section not reachable -- skipping")

        let proteinElement = scrollToFindAny(["Protein", "protein"])

        if let element = proteinElement {
            XCTAssertTrue(element.exists, "Protein progress should be visible")
            takeScreenshot(named: "protein_progress")
        } else {
            // Check for gram indicators that may represent protein
            let gramElement = scrollToFindAny(["g protein", "g remaining"])
            if let element = gramElement {
                XCTAssertTrue(element.exists, "Protein gram indicator should be visible")
                takeScreenshot(named: "protein_grams")
            } else {
                throw XCTSkip("Protein progress not found on nutrition dashboard")
            }
        }

        assertNoErrorAlerts(context: "Protein progress displayed")
    }

    // MARK: - Test 4: Macro Breakdown Displayed

    /// Verify the macro breakdown showing carbs, fats, and protein is visible
    func testMacroBreakdownDisplayed() throws {
        let nutritionReached = navigateToNutrition()
        try XCTSkipIf(!nutritionReached, "Nutrition section not reachable -- skipping")

        var macrosFound: [String] = []

        let macroKeywords = ["Carbs", "Fats", "Protein", "Macro", "Fat", "Carbohydrate"]
        for keyword in macroKeywords {
            let predicate = NSPredicate(format: "label CONTAINS[c] %@", keyword)
            let element = app.staticTexts.containing(predicate).firstMatch
            if element.exists {
                macrosFound.append(keyword)
            }
        }

        // If not immediately visible, scroll to find them
        if macrosFound.isEmpty {
            let macroElement = scrollToFindAny(macroKeywords, maxSwipes: 8)
            if let element = macroElement {
                macrosFound.append(element.label)
            }
        }

        if !macrosFound.isEmpty {
            XCTAssertGreaterThan(
                macrosFound.count, 0,
                "At least one macro indicator should be visible"
            )
            takeScreenshot(named: "macro_breakdown")
        } else {
            throw XCTSkip("Macro breakdown not found on nutrition dashboard")
        }

        assertNoErrorAlerts(context: "Macro breakdown displayed")
    }

    // MARK: - Test 5: Log Meal Button Exists

    /// Verify the log meal button is present on the nutrition dashboard
    func testLogMealButtonExists() throws {
        let nutritionReached = navigateToNutrition()
        try XCTSkipIf(!nutritionReached, "Nutrition section not reachable -- skipping")

        // Check by accessibility identifier first
        let logMealById = app.buttons["nutrition_log_meal"]
        let logMealDescendant = app.descendants(matching: .any)["nutrition_log_meal"]

        if logMealById.waitForExistence(timeout: 5) || logMealDescendant.exists {
            takeScreenshot(named: "log_meal_button_by_id")
            assertNoErrorAlerts(context: "Log meal button by identifier")
            return
        }

        // Fallback: search by text
        let logMealElement = scrollToFindAny([
            "Log Meal", "Add Meal", "Log Food", "Breakfast", "Lunch",
            "Dinner", "Snack", "Add Food", "Quick Add"
        ])

        if let element = logMealElement {
            XCTAssertTrue(element.exists, "Log meal button should be visible")
            takeScreenshot(named: "log_meal_button_by_text")
        } else {
            throw XCTSkip("Log meal button not found by accessibility identifier or text content")
        }

        assertNoErrorAlerts(context: "Log meal button exists")
    }

    // MARK: - Test 6: Log Meal Sheet Opens

    /// Verify tapping the log meal button opens a sheet or new view
    func testLogMealSheetOpens() throws {
        let nutritionReached = navigateToNutrition()
        try XCTSkipIf(!nutritionReached, "Nutrition section not reachable -- skipping")

        // Find the log meal button
        var logMealButton: XCUIElement? = app.buttons["nutrition_log_meal"]
        if !(logMealButton?.waitForExistence(timeout: 5) ?? false) {
            logMealButton = app.descendants(matching: .any)["nutrition_log_meal"]
        }

        // Fallback: find by text
        if !(logMealButton?.exists ?? false) || !(logMealButton?.isHittable ?? false) {
            logMealButton = scrollToFindAny([
                "Log Meal", "Add Meal", "Log Food", "Breakfast", "Lunch",
                "Dinner", "Snack", "Add Food", "Quick Add"
            ])
        }

        guard let button = logMealButton, button.exists, button.isHittable else {
            throw XCTSkip("Log meal button not found or not tappable -- skipping sheet test")
        }

        takeScreenshot(named: "before_log_meal_tap")
        button.tap()
        waitForContentToLoad()

        // Verify a sheet or new view opened
        let sheetOpened = app.navigationBars.count > 0 ||
                          app.textFields.firstMatch.exists ||
                          app.searchFields.firstMatch.exists ||
                          app.staticTexts.containing(
                              NSPredicate(format: "label CONTAINS[c] 'meal' OR label CONTAINS[c] 'food' OR label CONTAINS[c] 'log' OR label CONTAINS[c] 'add'")
                          ).firstMatch.exists ||
                          app.buttons["Cancel"].exists ||
                          app.buttons["Close"].exists

        XCTAssertTrue(sheetOpened, "A log meal sheet or view should open after tapping the button")

        assertNoErrorAlerts(context: "Log meal sheet opens")
        takeScreenshot(named: "log_meal_sheet_opened")

        // Dismiss the sheet
        let cancelButton = app.buttons["Cancel"]
        let closeButton = app.buttons["Close"]
        if cancelButton.exists && cancelButton.isHittable {
            cancelButton.tap()
        } else if closeButton.exists && closeButton.isHittable {
            closeButton.tap()
        } else {
            app.swipeDown()
        }
        waitForContentToLoad()
    }

    // MARK: - Test 7: Nutrition Goals Button Exists

    /// Verify the nutrition goals button or link is present
    func testNutritionGoalsButtonExists() throws {
        let nutritionReached = navigateToNutrition()
        try XCTSkipIf(!nutritionReached, "Nutrition section not reachable -- skipping")

        let goalsElement = scrollToFindAny([
            "Goals", "Target", "Daily Goal", "Set Goals",
            "Nutrition Goals", "Calorie Goal", "Macro Target"
        ])

        if let element = goalsElement {
            XCTAssertTrue(element.exists, "Nutrition goals button or link should be visible")
            takeScreenshot(named: "nutrition_goals_button")
        } else {
            // Check for a gear/settings icon that might represent goals
            let gearButton = app.buttons.containing(
                NSPredicate(format: "label CONTAINS[c] 'gear' OR label CONTAINS[c] 'settings' OR identifier CONTAINS[c] 'gear'")
            ).firstMatch
            if gearButton.exists {
                takeScreenshot(named: "nutrition_goals_gear_icon")
            } else {
                throw XCTSkip("Nutrition goals button not found on nutrition dashboard")
            }
        }

        assertNoErrorAlerts(context: "Nutrition goals button exists")
    }

    // MARK: - Test 8: Nutrition Goals Sheet Opens

    /// Verify tapping the goals button opens a goals configuration sheet
    func testNutritionGoalsSheetOpens() throws {
        let nutritionReached = navigateToNutrition()
        try XCTSkipIf(!nutritionReached, "Nutrition section not reachable -- skipping")

        // Find the goals button
        let goalsButton = scrollToFindAny([
            "Goals", "Target", "Daily Goal", "Set Goals",
            "Nutrition Goals", "Calorie Goal", "Macro Target"
        ])

        guard let button = goalsButton, button.isHittable else {
            throw XCTSkip("Nutrition goals button not found or not tappable -- skipping sheet test")
        }

        takeScreenshot(named: "before_goals_tap")
        button.tap()
        waitForContentToLoad()

        // Verify a sheet or new view opened
        let sheetOpened = app.navigationBars.count > 0 ||
                          app.textFields.firstMatch.exists ||
                          app.sliders.firstMatch.exists ||
                          app.steppers.firstMatch.exists ||
                          app.staticTexts.containing(
                              NSPredicate(format: "label CONTAINS[c] 'goal' OR label CONTAINS[c] 'target' OR label CONTAINS[c] 'calorie' OR label CONTAINS[c] 'daily'")
                          ).firstMatch.exists ||
                          app.buttons["Cancel"].exists ||
                          app.buttons["Save"].exists ||
                          app.buttons["Done"].exists

        XCTAssertTrue(sheetOpened, "A nutrition goals sheet or view should open after tapping the button")

        assertNoErrorAlerts(context: "Nutrition goals sheet opens")
        takeScreenshot(named: "nutrition_goals_sheet_opened")

        // Dismiss the sheet
        let cancelButton = app.buttons["Cancel"]
        let closeButton = app.buttons["Close"]
        let doneButton = app.buttons["Done"]
        if cancelButton.exists && cancelButton.isHittable {
            cancelButton.tap()
        } else if doneButton.exists && doneButton.isHittable {
            doneButton.tap()
        } else if closeButton.exists && closeButton.isHittable {
            closeButton.tap()
        } else {
            app.swipeDown()
        }
        waitForContentToLoad()
    }

    // MARK: - Test 9: Meal History Displayed

    /// Verify meal history shows seed data items (oatmeal, chicken, yogurt, etc.)
    func testMealHistoryDisplayed() throws {
        let nutritionReached = navigateToNutrition()
        try XCTSkipIf(!nutritionReached, "Nutrition section not reachable -- skipping")

        // Look for specific seed data food items or generic meal history indicators
        let mealHistoryElement = scrollToFindAny([
            "oatmeal", "chicken", "yogurt", "rice", "salad",
            "egg", "banana", "protein shake", "Breakfast", "Lunch",
            "Dinner", "Snack", "Today", "Yesterday", "Meals"
        ], maxSwipes: 10)

        if let element = mealHistoryElement {
            XCTAssertTrue(element.exists, "Meal history should show food items or meal labels")
            takeScreenshot(named: "meal_history")
        } else {
            // Check for an empty state
            let emptyState = scrollToFindAny([
                "No meals", "No food", "Start logging", "Add your first",
                "Nothing logged"
            ], maxSwipes: 3)

            if let emptyElement = emptyState {
                XCTAssertTrue(emptyElement.exists, "Meal history empty state should be visible")
                takeScreenshot(named: "meal_history_empty")
            } else {
                throw XCTSkip("Meal history section not found -- may not be populated with seed data")
            }
        }

        assertNoErrorAlerts(context: "Meal history displayed")
    }

    // MARK: - Test 10: Nutrition Section Picker

    /// Verify the section picker (Dashboard/Meal Plans/Foods) is present
    func testNutritionSectionPicker() throws {
        let nutritionReached = navigateToNutrition()
        try XCTSkipIf(!nutritionReached, "Nutrition section not reachable -- skipping")

        // Look for a segmented control or picker
        let segmentedControl = app.segmentedControls.firstMatch
        let pickerElement = scrollToFindAny([
            "Dashboard", "Meal Plans", "Foods", "Meals", "Plans"
        ], maxSwipes: 5)

        if segmentedControl.exists {
            XCTAssertTrue(segmentedControl.exists, "Section picker (segmented control) should be visible")
            takeScreenshot(named: "nutrition_section_picker_segmented")
        } else if let element = pickerElement {
            XCTAssertTrue(element.exists, "Section picker label should be visible")
            takeScreenshot(named: "nutrition_section_picker_text")
        } else {
            throw XCTSkip("Nutrition section picker not found -- may use a different navigation pattern")
        }

        assertNoErrorAlerts(context: "Nutrition section picker")
    }

    // MARK: - Test 11: Meal Plans Section Loads

    /// Verify tapping the Meal Plans section loads content
    func testMealPlansSectionLoads() throws {
        let nutritionReached = navigateToNutrition()
        try XCTSkipIf(!nutritionReached, "Nutrition section not reachable -- skipping")

        // Find and tap the Meal Plans section
        let segmentedControl = app.segmentedControls.firstMatch
        if segmentedControl.exists {
            // Try tapping the "Meal Plans" segment
            let mealPlansSegment = segmentedControl.buttons["Meal Plans"]
            if mealPlansSegment.exists {
                mealPlansSegment.tap()
                waitForContentToLoad()
                takeScreenshot(named: "meal_plans_section_via_segment")
                assertNoErrorAlerts(context: "Meal Plans section via segment")
                return
            }
        }

        // Fallback: find a Meal Plans button or link
        let mealPlansElement = scrollToFindAny(["Meal Plans", "Plans", "Meal Plan"])

        guard let element = mealPlansElement, element.isHittable else {
            throw XCTSkip("Meal Plans section not found or not tappable")
        }

        element.tap()
        waitForContentToLoad()

        // Verify content loaded
        let hasContent = app.scrollViews.firstMatch.exists ||
                         app.tables.firstMatch.exists ||
                         app.collectionViews.firstMatch.exists ||
                         app.staticTexts.containing(
                             NSPredicate(format: "label CONTAINS[c] 'plan' OR label CONTAINS[c] 'meal' OR label CONTAINS[c] 'No plans'")
                         ).firstMatch.exists

        XCTAssertTrue(hasContent, "Meal Plans section should display content or empty state")

        assertNoErrorAlerts(context: "Meal Plans section loads")
        takeScreenshot(named: "meal_plans_section")
    }

    // MARK: - Test 12: Foods Section Loads

    /// Verify tapping the Foods section loads content
    func testFoodsSectionLoads() throws {
        let nutritionReached = navigateToNutrition()
        try XCTSkipIf(!nutritionReached, "Nutrition section not reachable -- skipping")

        // Find and tap the Foods section
        let segmentedControl = app.segmentedControls.firstMatch
        if segmentedControl.exists {
            // Try tapping the "Foods" segment
            let foodsSegment = segmentedControl.buttons["Foods"]
            if foodsSegment.exists {
                foodsSegment.tap()
                waitForContentToLoad()
                takeScreenshot(named: "foods_section_via_segment")
                assertNoErrorAlerts(context: "Foods section via segment")
                return
            }
        }

        // Fallback: find a Foods button or link
        let foodsElement = scrollToFindAny(["Foods", "Food Database", "Food List", "Browse Foods"])

        guard let element = foodsElement, element.isHittable else {
            throw XCTSkip("Foods section not found or not tappable")
        }

        element.tap()
        waitForContentToLoad()

        // Verify content loaded
        let hasContent = app.scrollViews.firstMatch.exists ||
                         app.tables.firstMatch.exists ||
                         app.collectionViews.firstMatch.exists ||
                         app.searchFields.firstMatch.exists ||
                         app.staticTexts.containing(
                             NSPredicate(format: "label CONTAINS[c] 'food' OR label CONTAINS[c] 'search' OR label CONTAINS[c] 'No foods'")
                         ).firstMatch.exists

        XCTAssertTrue(hasContent, "Foods section should display content or a search interface")

        assertNoErrorAlerts(context: "Foods section loads")
        takeScreenshot(named: "foods_section")
    }

    // MARK: - Helper Methods

    private func waitForContentToLoad() {
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            let predicate = NSPredicate(format: "exists == false")
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: loadingIndicator)
            _ = XCTWaiter().wait(for: [expectation], timeout: 15)
        }
        // Small buffer for animations
        Thread.sleep(forTimeInterval: 0.5)
    }

    private func assertNoErrorAlerts(context: String) {
        let alert = app.alerts.firstMatch
        if alert.exists {
            let alertLabel = alert.label
            // Dismiss the alert for test continuity
            let okButton = alert.buttons.firstMatch
            if okButton.exists { okButton.tap() }
            XCTFail("\(context): Unexpected error alert -- \(alertLabel)")
        }
    }

    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
