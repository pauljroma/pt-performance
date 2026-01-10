# XCUITest Framework Setup Instructions

**BUILD 95 - Agent 1**
**Date:** 2025-12-27

---

## ✅ Framework Files Created

The following files have been created and need to be added to your Xcode project:

### Helpers (3 files)
- ✅ `Tests/UI/Helpers/TestHelpers.swift`
- ✅ `Tests/UI/Helpers/MockData.swift`
- ✅ `Tests/UI/Helpers/ScreenshotHelper.swift`

### Base (1 file)
- ✅ `Tests/UI/Base/BaseUITest.swift`

### Page Objects (2 files + 1 doc)
- ✅ `Tests/UI/PageObjects/LoginPage.swift`
- ✅ `Tests/UI/PageObjects/PatientDashboardPage.swift`
- ✅ `Tests/UI/PageObjects/README.md`

---

## 📝 Manual Steps Required

### Step 1: Open Xcode Project
```bash
cd /Users/expo/Code/expo/ios-app/PTPerformance
open PTPerformance.xcodeproj
```

### Step 2: Add Files to Project

#### Option A: Drag and Drop (Recommended)
1. In Finder, navigate to `Tests/UI/`
2. Drag the following folders into Xcode's Project Navigator:
   - `Helpers/` folder
   - `Base/` folder
   - `PageObjects/` folder
3. When prompted:
   - ✅ Check "Copy items if needed" (if not already in project)
   - ✅ Select "Create groups"
   - ✅ Add to target: `PTPerformanceUITests`

#### Option B: Add Files Menu
1. Right-click on `Tests/UI` group in Xcode
2. Select "Add Files to PTPerformance..."
3. Navigate to `Tests/UI/Helpers`
4. Select all `.swift` files
5. Click "Add"
6. Repeat for `Base/` and `PageObjects/`

### Step 3: Verify File Organization

Your Xcode project navigator should look like:
```
PTPerformance (project)
├── PTPerformance (app target)
└── Tests/
    ├── Unit/
    ├── Integration/
    └── UI/
        ├── Base/
        │   └── BaseUITest.swift
        ├── Helpers/
        │   ├── TestHelpers.swift
        │   ├── MockData.swift
        │   └── ScreenshotHelper.swift
        ├── PageObjects/
        │   ├── LoginPage.swift
        │   ├── PatientDashboardPage.swift
        │   └── README.md
        ├── PatientFlowUITests.swift
        ├── ProgramFlowTests.swift
        ├── ContentFlowTests.swift
        └── AIChatSchedulingTests.swift
```

### Step 4: Verify Target Membership

For each new Swift file:
1. Select the file in Project Navigator
2. Open File Inspector (⌘⌥1)
3. Check "Target Membership" section
4. Ensure `PTPerformanceUITests` is checked ✅
5. Ensure `PTPerformance` (app target) is NOT checked ❌

### Step 5: Build Tests
```bash
# Command line
xcodebuild test \
  -project PTPerformance.xcodeproj \
  -scheme PTPerformance \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:PTPerformanceUITests

# Or in Xcode: ⌘U
```

---

## 🧪 Verify Installation

### Test 1: Build Compiles
```bash
xcodebuild build-for-testing \
  -project PTPerformance.xcodeproj \
  -scheme PTPerformance \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Expected:** Build succeeds with no errors

### Test 2: Import Works
Create a simple test to verify imports:

```swift
import XCTest

final class FrameworkVerificationTest: BaseUITest {
    func testFrameworkImports() {
        // If this compiles, framework is set up correctly
        let _ = MockData.DemoPatient.email
        let _ = TestHelpers.standardTimeout
        let _ = ScreenshotHelper(testCase: self)
        let _ = LoginPage(app: app)

        XCTAssert(true, "Framework imports working!")
    }
}
```

### Test 3: Run Existing Test
Run the existing `PatientFlowUITests.swift` to ensure it still works.

---

## 🔧 Troubleshooting

### Issue: Build errors "Cannot find type 'BaseUITest'"
**Cause:** Files not added to UITests target
**Fix:**
1. Select the file
2. Check File Inspector
3. Enable `PTPerformanceUITests` target membership

### Issue: "No such module 'XCTest'"
**Cause:** Wrong target selected
**Fix:** Make sure you're building the test target, not the app target

### Issue: Tests can't find 'app' property
**Cause:** Not inheriting from BaseUITest
**Fix:** Change `XCTestCase` to `BaseUITest`
```swift
// Before
final class MyTests: XCTestCase { }

// After
final class MyTests: BaseUITest { }
```

### Issue: Existing tests break
**Cause:** Namespace collision or import issue
**Fix:**
1. Ensure old tests still inherit from `XCTestCase` if not migrated
2. Or migrate them to use `BaseUITest`

### Issue: Simulator doesn't launch
**Cause:** Simulator not selected
**Fix:**
1. In Xcode, select a simulator from the scheme dropdown
2. Or specify in command line with `-destination`

---

## 📚 Next Steps After Setup

### 1. Refactor Existing Tests (Optional)
Existing tests can optionally be migrated to use the new framework:

```swift
// Before
final class PatientFlowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }

    func testLogin() {
        let button = app.buttons["Patient Login"]
        button.tap()
        // ...
    }
}

// After
final class PatientFlowUITests: BaseUITest {
    // Setup handled by BaseUITest

    func testLogin() {
        let loginPage = LoginPage(app: app)
        loginPage.tapPatientLogin()
        // ...
    }
}
```

### 2. Create New Page Objects
For screens not yet covered:
- `ExerciseDetailPage.swift`
- `TherapistDashboardPage.swift`
- `ProgramBuilderPage.swift`
- etc.

### 3. Write New Tests
Using the framework:
```swift
final class MyNewTests: BaseUITest {
    func testMyFeature() {
        loginAsDemoPatient()

        let page = MyPage(app: app)
        page.performAction()
        page.assertResult()
    }
}
```

---

## 🎓 Learning Resources

### Documentation
- Full docs: `.outcomes/BUILD_95_AGENT_1_XCUITEST_FRAMEWORK_COMPLETE.md`
- Quick reference: `.outcomes/BUILD_95_AGENT_1_QUICK_REFERENCE.md`
- Page Objects guide: `Tests/UI/PageObjects/README.md`

### Example Code
- See `LoginPage.swift` for Page Object pattern
- See `BaseUITest.swift` for common setup
- See `TestHelpers.swift` for utility functions

### Apple Documentation
- [XCTest Framework](https://developer.apple.com/documentation/xctest)
- [XCUITest](https://developer.apple.com/documentation/xctest/user_interface_tests)
- [UI Testing in Xcode](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/09-ui_testing.html)

---

## ✅ Verification Checklist

Before proceeding, verify:

- [ ] All Swift files added to Xcode project
- [ ] Files are in correct groups (Helpers, Base, PageObjects)
- [ ] All files have target membership set to `PTPerformanceUITests`
- [ ] Project builds without errors
- [ ] Can run at least one UI test successfully
- [ ] Framework imports work (TestHelpers, MockData, etc.)
- [ ] BaseUITest can be subclassed
- [ ] Page Objects can be instantiated

---

## 🚀 You're Ready!

Once all files are added and verified, the framework is ready to use.

**Start writing tests by:**
1. Creating test files that inherit from `BaseUITest`
2. Creating Page Objects for your screens
3. Using TestHelpers for common operations
4. Using MockData for test data

**Example:**
```swift
import XCTest

final class MyFeatureTests: BaseUITest {
    func testFeature() {
        loginAsDemoPatient()

        let page = MyPage(app: app)
        page.doSomething()

        TestHelpers.assertExists(someElement, named: "Element")
    }
}
```

---

**Questions?** See full documentation in `.outcomes/BUILD_95_AGENT_1_*` files

**Status:** Framework created ✅ | Manual Xcode setup required ⏳
