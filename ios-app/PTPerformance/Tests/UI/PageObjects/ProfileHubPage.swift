//
//  ProfileHubPage.swift
//  PTPerformanceUITests
//
//  Page Object Model for Profile Hub tab
//  BUILD 318: Tab Consolidation - Hub UI Tests
//

import XCTest

/// Page Object representing the Profile Hub tab
struct ProfileHubPage {

    // MARK: - Properties

    private let app: XCUIApplication

    // MARK: - Initialization

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Tab Bar Elements

    var profileTab: XCUIElement {
        app.tabBars.buttons["Profile"]
    }

    // MARK: - Navigation Elements

    var navigationTitle: XCUIElement {
        app.navigationBars.staticTexts["Profile"]
    }

    var profileList: XCUIElement {
        app.tables.firstMatch
    }

    // MARK: - Health & Wellness Section

    var healthSectionHeader: XCUIElement {
        app.staticTexts["Health & Wellness"]
    }

    var nutritionRow: XCUIElement {
        app.buttons["Nutrition"]
    }

    var readinessRow: XCUIElement {
        app.buttons["Readiness"]
    }

    // MARK: - Tools & Tracking Section

    var toolsSectionHeader: XCUIElement {
        app.staticTexts["Tools & Tracking"]
    }

    var bodyCompositionRow: XCUIElement {
        app.buttons["Body Composition"]
    }

    var bodyCompGoalsRow: XCUIElement {
        app.buttons["Body Comp Goals"]
    }

    var calculatorsRow: XCUIElement {
        app.buttons["Calculators"]
    }

    var myGoalsRow: XCUIElement {
        app.buttons["My Goals"]
    }

    // MARK: - Training Mode Section

    var trainingModeSectionHeader: XCUIElement {
        app.staticTexts["Training Mode"]
    }

    // MARK: - Therapist Section

    var therapistSectionHeader: XCUIElement {
        app.staticTexts["Therapist"]
    }

    var therapistLinkingRow: XCUIElement {
        app.buttons["Therapist Linking"]
    }

    // MARK: - Support Section

    var supportSectionHeader: XCUIElement {
        app.staticTexts["Support & Learning"]
    }

    var aiAssistantRow: XCUIElement {
        app.buttons["AI Assistant"]
    }

    var learnRow: XCUIElement {
        app.buttons["Learn"]
    }

    var tutorialRow: XCUIElement {
        app.buttons["View Tutorial"]
    }

    var privacyNoticeRow: XCUIElement {
        app.buttons["Privacy Notice"]
    }

    // MARK: - Subscription Section

    var subscriptionSectionHeader: XCUIElement {
        app.staticTexts["Subscription"]
    }

    var manageSubscriptionRow: XCUIElement {
        app.buttons["Manage Subscription"]
    }

    // MARK: - Account Section

    var accountSectionHeader: XCUIElement {
        app.staticTexts["Account"]
    }

    var logOutRow: XCUIElement {
        app.buttons["Log Out"]
    }

    var deleteAccountRow: XCUIElement {
        app.buttons["Delete Account"]
    }

    // MARK: - Debug Section

    var debugSectionHeader: XCUIElement {
        app.staticTexts["Debug"]
    }

    var premiumFeaturesToggle: XCUIElement {
        app.switches["Premium Features"]
    }

    // MARK: - Interactions

    /// Tap the Profile tab
    @discardableResult
    func tapProfileTab() -> Self {
        TestHelpers.safeTap(profileTab, named: "Profile Tab")
        return self
    }

    /// Scroll down in profile list
    @discardableResult
    func scrollDown() -> Self {
        profileList.swipeUp()
        return self
    }

    /// Scroll up in profile list
    @discardableResult
    func scrollUp() -> Self {
        profileList.swipeDown()
        return self
    }

    /// Tap Nutrition row
    @discardableResult
    func tapNutrition() -> Self {
        TestHelpers.safeTap(nutritionRow, named: "Nutrition Row")
        return self
    }

    /// Tap Body Composition row
    @discardableResult
    func tapBodyComposition() -> Self {
        TestHelpers.safeTap(bodyCompositionRow, named: "Body Composition Row")
        return self
    }

    /// Tap Therapist Linking row
    @discardableResult
    func tapTherapistLinking() -> Self {
        scrollToElementIfNeeded(therapistLinkingRow)
        TestHelpers.safeTap(therapistLinkingRow, named: "Therapist Linking Row")
        return self
    }

    /// Tap Manage Subscription row
    @discardableResult
    func tapManageSubscription() -> Self {
        scrollToElementIfNeeded(manageSubscriptionRow)
        TestHelpers.safeTap(manageSubscriptionRow, named: "Manage Subscription Row")
        return self
    }

    /// Tap Log Out button
    @discardableResult
    func tapLogOut() -> Self {
        scrollToElementIfNeeded(logOutRow)
        TestHelpers.safeTap(logOutRow, named: "Log Out Button")
        return self
    }

    /// Tap View Tutorial button
    @discardableResult
    func tapViewTutorial() -> Self {
        scrollToElementIfNeeded(tutorialRow)
        TestHelpers.safeTap(tutorialRow, named: "View Tutorial Button")
        return self
    }

    /// Toggle premium features (debug)
    @discardableResult
    func togglePremiumFeatures() -> Self {
        scrollToElementIfNeeded(premiumFeaturesToggle)
        premiumFeaturesToggle.tap()
        return self
    }

    // MARK: - Helper Methods

    private func scrollToElementIfNeeded(_ element: XCUIElement) {
        var attempts = 0
        while !element.isHittable && attempts < 5 {
            profileList.swipeUp()
            attempts += 1
        }
    }

    // MARK: - Assertions

    /// Assert Profile Hub is displayed
    func assertIsDisplayed() {
        TestHelpers.assertExists(profileTab, named: "Profile Tab")
        XCTAssertTrue(profileTab.isSelected, "Profile tab should be selected")
    }

    /// Assert Profile tab is selected
    func assertIsSelected() {
        XCTAssertTrue(
            profileTab.isSelected,
            "Profile tab should be selected"
        )
    }

    /// Assert Health & Wellness section exists
    func assertHealthSectionExists() {
        TestHelpers.assertExists(
            healthSectionHeader,
            named: "Health & Wellness Section"
        )
    }

    /// Assert Tools & Tracking section exists
    func assertToolsSectionExists() {
        TestHelpers.assertExists(
            toolsSectionHeader,
            named: "Tools & Tracking Section"
        )
    }

    /// Assert Training Mode section exists
    func assertTrainingModeSectionExists() {
        scrollToElementIfNeeded(trainingModeSectionHeader)
        TestHelpers.assertExists(
            trainingModeSectionHeader,
            named: "Training Mode Section"
        )
    }

    /// Assert Therapist section exists
    func assertTherapistSectionExists() {
        scrollToElementIfNeeded(therapistSectionHeader)
        TestHelpers.assertExists(
            therapistSectionHeader,
            named: "Therapist Section"
        )
    }

    /// Assert Support section exists
    func assertSupportSectionExists() {
        scrollToElementIfNeeded(supportSectionHeader)
        TestHelpers.assertExists(
            supportSectionHeader,
            named: "Support & Learning Section"
        )
    }

    /// Assert Subscription section exists
    func assertSubscriptionSectionExists() {
        scrollToElementIfNeeded(subscriptionSectionHeader)
        TestHelpers.assertExists(
            subscriptionSectionHeader,
            named: "Subscription Section"
        )
    }

    /// Assert Account section exists
    func assertAccountSectionExists() {
        scrollToElementIfNeeded(accountSectionHeader)
        TestHelpers.assertExists(
            accountSectionHeader,
            named: "Account Section"
        )
    }

    /// Assert all major sections exist
    func assertAllSectionsExist() {
        assertHealthSectionExists()
        assertToolsSectionExists()
        assertTrainingModeSectionExists()
        assertTherapistSectionExists()
        assertSupportSectionExists()
        assertSubscriptionSectionExists()
        assertAccountSectionExists()
    }

    /// Assert logout and delete account options exist
    func assertAccountOptionsExist() {
        scrollToElementIfNeeded(logOutRow)
        TestHelpers.assertExists(logOutRow, named: "Log Out Button")
        TestHelpers.assertExists(deleteAccountRow, named: "Delete Account Button")
    }

    // MARK: - Accessibility

    /// Assert profile tab has accessibility label
    func assertProfileTabAccessible() {
        XCTAssertTrue(
            profileTab.exists,
            "Profile tab should exist"
        )
        XCTAssertTrue(
            profileTab.isHittable,
            "Profile tab should be hittable"
        )
    }

    /// Assert log out button is accessible
    func assertLogOutAccessible() {
        scrollToElementIfNeeded(logOutRow)
        XCTAssertTrue(
            logOutRow.isHittable,
            "Log Out button should be hittable"
        )
    }

    /// Assert tutorial button is accessible
    func assertTutorialAccessible() {
        scrollToElementIfNeeded(tutorialRow)
        XCTAssertTrue(
            tutorialRow.isHittable,
            "View Tutorial button should be hittable"
        )
    }
}
