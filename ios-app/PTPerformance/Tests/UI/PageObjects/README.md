# Page Objects

## Overview

This directory contains Page Object Model (POM) implementations for PTPerformance UI tests. The Page Object pattern improves test maintainability by:

1. **Encapsulating UI elements** - All selectors for a screen are in one place
2. **Providing reusable methods** - Common interactions are wrapped in methods
3. **Making tests readable** - Tests read like user stories
4. **Simplifying maintenance** - UI changes only require updating one file

## Structure

```
PageObjects/
├── LoginPage.swift              # Login screen
├── PatientDashboardPage.swift   # Patient dashboard (Today's Session)
├── TherapistDashboardPage.swift # (To be created by other agents)
├── ExerciseDetailPage.swift     # (To be created by other agents)
└── README.md                    # This file
```

## Usage Example

### Without Page Objects (Not Recommended)

```swift
func testLogin() {
    let patientButton = app.buttons["Patient Login"]
    patientButton.tap()

    let emailField = app.textFields["Email"]
    emailField.tap()
    emailField.typeText("demo@example.com")

    let passwordField = app.secureTextFields["Password"]
    passwordField.tap()
    passwordField.typeText("password")

    let loginButton = app.buttons["Log In"]
    loginButton.tap()
}
```

### With Page Objects (Recommended)

```swift
func testLogin() {
    let loginPage = LoginPage(app: app)
    loginPage.loginAsDemoPatient()

    let dashboard = PatientDashboardPage(app: app)
    dashboard.assertIsDisplayed()
}
```

## Creating New Page Objects

### Template

```swift
//
//  YourPage.swift
//  PTPerformanceUITests
//
//  Page Object Model for [Screen Name]
//  BUILD 95 - Agent X: [Task Name]
//

import XCTest

struct YourPage {
    // MARK: - Properties
    private let app: XCUIApplication

    // MARK: - Elements
    var someButton: XCUIElement {
        app.buttons["Button Identifier"]
    }

    // MARK: - Initialization
    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Interactions
    @discardableResult
    func tapSomeButton() -> Self {
        TestHelpers.safeTap(someButton, named: "Some Button")
        return self
    }

    // MARK: - Assertions
    func assertIsDisplayed() {
        TestHelpers.assertExists(someButton, named: "Some Button")
    }
}
```

## Best Practices

### 1. Use Structs
- Page Objects should be structs (value types)
- Passed the XCUIApplication instance in init

### 2. Computed Properties for Elements
- Use computed properties for UI elements
- This ensures fresh queries each time
- Avoids stale element references

### 3. Fluent Interface
- Return `Self` from interaction methods
- Allows method chaining: `page.tapButton().enterText("foo")`

### 4. Separate Interactions from Assertions
- Interaction methods: `tapButton()`, `enterText()`
- Assertion methods: `assertIsDisplayed()`, `assertNoError()`

### 5. Use TestHelpers
- Always use `TestHelpers.safeTap()` instead of direct `.tap()`
- Use `TestHelpers.assertExists()` for better error messages

### 6. Create Workflow Methods
- Combine common sequences: `loginAsDemoPatient()`
- Makes tests more readable
- Reduces duplication

### 7. Naming Conventions
- Page Objects: `[Screen]Page` (e.g., `LoginPage`)
- Elements: descriptive names (`emailField`, not `field1`)
- Methods: verb-noun (`tapLoginButton`, not `login`)
- Assertions: start with `assert` (`assertIsDisplayed`)

## Example Test Using Page Objects

```swift
import XCTest

final class PatientLoginTests: BaseUITest {

    func testPatientCanLogin() {
        // Arrange
        let loginPage = LoginPage(app: app)

        // Act
        loginPage.loginAsDemoPatient()

        // Assert
        let dashboard = PatientDashboardPage(app: app)
        dashboard.waitForLoad()
        dashboard.assertIsDisplayed()
        dashboard.assertDataLoaded()
        dashboard.assertNoError()
    }

    func testPatientCanViewExercise() {
        // Arrange
        let loginPage = LoginPage(app: app)
        loginPage.loginAsDemoPatient()

        let dashboard = PatientDashboardPage(app: app)
        dashboard.waitForLoad()

        // Act
        dashboard.tapFirstExercise()

        // Assert
        let exerciseDetail = ExerciseDetailPage(app: app)
        exerciseDetail.assertIsDisplayed()
    }
}
```

## Benefits

### For Test Writers
- Tests are easier to write
- Tests are more readable
- Less code duplication

### For Maintainers
- UI changes only affect Page Objects
- Tests remain stable through UI refactoring
- Easy to find and update element selectors

### For Reviewers
- Tests clearly express user intent
- Easy to verify test coverage
- Clear separation of concerns

## Future Enhancements

Agents creating new Page Objects should consider:

1. **Navigation helpers** - Methods to navigate to the page
2. **State verification** - Methods to check page state
3. **Error handling** - Specific error assertions
4. **Data extraction** - Methods to get data from the page
5. **Waiting strategies** - Smart waits for async operations

## Related Files

- `Tests/UI/Base/BaseUITest.swift` - Base test class
- `Tests/UI/Helpers/TestHelpers.swift` - Common utilities
- `Tests/UI/Helpers/MockData.swift` - Test data

## BUILD 95 Notes

This Page Object infrastructure was created by Agent 1 as part of the XCUITest framework setup. Other agents should:

1. Create Page Objects for their test areas
2. Follow the patterns established here
3. Update this README with new Page Objects
4. Keep Page Objects focused and cohesive
