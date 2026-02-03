# PTPerformance Tests

This directory contains unit tests for the PTPerformance iOS app. Follow these guidelines when writing new tests.

## Directory Structure

```
PTPerformanceTests/
  Helpers/           # Test utilities and factories
    TestHelpers.swift
  Models/            # Tests for data models and enums
  Services/          # Tests for service classes
  Utilities/         # Tests for utility classes (calculators, validators)
  ViewModels/        # Tests for view models
```

## Running Tests

### From Xcode
- Press `Cmd + U` to run all tests
- Use the Test Navigator (`Cmd + 6`) to run individual tests or test classes
- Right-click a test method and select "Run" to run a single test

### From Command Line
```bash
xcodebuild test -scheme PTPerformance -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Test Naming Conventions

Follow these naming patterns for test methods:

```swift
// Pattern: test[UnitOfWork]_[StateUnderTest]_[ExpectedBehavior]

func testFatigueScore_WhenFatigueSummaryIsNil_ReturnsZero()
func testDeloadRecommended_WithUrgencyAndPrescription_ReturnsTrue()
func testDecoding_WithStringNumericValues_ParsesCorrectly()
```

### Naming Guidelines

1. **Start with `test`** - Required by XCTest
2. **Unit of Work** - The method, property, or behavior being tested
3. **State Under Test** - The condition or input (use `When`, `With`, `Without`)
4. **Expected Behavior** - What should happen (`Returns`, `Throws`, `Sets`, `Is`)

## Creating a New Test File

1. **Choose the correct directory** based on what you're testing:
   - Model tests go in `Models/`
   - Service tests go in `Services/`
   - ViewModel tests go in `ViewModels/`
   - Utility tests go in `Utilities/`

2. **Follow the file naming pattern**: `[ClassUnderTest]Tests.swift`

3. **Use this template**:

```swift
//
//  [ClassName]Tests.swift
//  PTPerformanceTests
//
//  Unit tests for [ClassName]
//  [Brief description of what's being tested]
//

import XCTest
@testable import PTPerformance

final class [ClassName]Tests: XCTestCase {

    // MARK: - Properties

    var sut: [ClassUnderTest]!  // System Under Test

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        sut = [ClassUnderTest]()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - [Category] Tests

    func test[Method]_[Condition]_[ExpectedResult]() {
        // Given
        // ... setup

        // When
        // ... action

        // Then
        // ... assertions
    }
}
```

## Common Patterns

### Using Test Helpers

Import and use the shared test utilities:

```swift
import XCTest
@testable import PTPerformance

final class MyTests: XCTestCase {

    func testWithMockData() {
        // Use stable UUIDs
        let patientId = TestUUIDs.patient

        // Use consistent dates
        let date = TestDates.reference

        // Create mock data with factories
        let fatigue = TestDataFactory.fatigueAccumulation(
            patientId: patientId,
            calculationDate: date,
            fatigueScore: 75.0,
            fatigueBand: .high
        )

        // Use assertion helpers
        assertApproximatelyEqual(fatigue.fatigueScore, 75.0)
    }
}
```

### Testing Codable Models

```swift
func testDecoding_FullResponse() throws {
    let json = """
    {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "fatigue_score": 72.5,
        "fatigue_band": "high"
    }
    """.data(using: .utf8)!

    let decoder = JSONDecoder()
    let result = try decoder.decode(FatigueAccumulation.self, from: json)

    XCTAssertEqual(result.fatigueScore, 72.5)
    XCTAssertEqual(result.fatigueBand, .high)
}

func testEncodingDecodingRoundTrip() throws {
    let original = TestDataFactory.fatigueAccumulation()
    let roundTripped = try JSONTestHelpers.roundTrip(original)

    XCTAssertEqual(roundTripped.id, original.id)
    XCTAssertEqual(roundTripped.fatigueScore, original.fatigueScore)
}
```

### Testing ViewModels with Mocks

```swift
// 1. Create mock services by subclassing
class MockFatigueService: FatigueTrackingService {
    var shouldFail = false
    var mockData: FatigueAccumulation?

    override func fetchFatigue(patientId: UUID) async throws -> FatigueAccumulation {
        if shouldFail {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }
        return mockData ?? FatigueAccumulation.sample
    }
}

// 2. Inject mocks in tests
@MainActor
final class MyViewModelTests: XCTestCase {
    var viewModel: MyViewModel!
    var mockService: MockFatigueService!

    override func setUp() async throws {
        try await super.setUp()
        mockService = MockFatigueService()
        viewModel = MyViewModel(fatigueService: mockService)
    }

    func testLoadData_Success() async {
        mockService.mockData = TestDataFactory.fatigueAccumulation(fatigueScore: 80.0)

        await viewModel.loadData()

        XCTAssertEqual(viewModel.fatigueScore, 80.0)
        XCTAssertFalse(viewModel.showError)
    }

    func testLoadData_Failure() async {
        mockService.shouldFail = true

        await viewModel.loadData()

        XCTAssertTrue(viewModel.showError)
        XCTAssertFalse(viewModel.errorMessage.isEmpty)
    }
}
```

### Testing Enum Properties

```swift
func testEnum_AllCasesHaveRequiredProperties() {
    for urgency in DeloadUrgency.allCases {
        XCTAssertFalse(urgency.title.isEmpty, "\(urgency) should have a title")
        XCTAssertFalse(urgency.subtitle.isEmpty, "\(urgency) should have a subtitle")
        XCTAssertFalse(urgency.icon.isEmpty, "\(urgency) should have an icon")
    }
}

func testEnum_SpecificValues() {
    XCTAssertEqual(DeloadUrgency.none.title, "No Deload Needed")
    XCTAssertEqual(DeloadUrgency.required.color, .red)
}
```

### Testing Edge Cases

```swift
// Test boundary conditions
func testMatchScoreColor_BoundaryAt80() {
    let greenItem = TestDataFactory.workoutRecommendationItem(matchScore: 80)
    let orangeItem = TestDataFactory.workoutRecommendationItem(matchScore: 79)

    XCTAssertEqual(AIWorkoutRecommendation(from: greenItem).matchScoreColor, "green")
    XCTAssertEqual(AIWorkoutRecommendation(from: orangeItem).matchScoreColor, "orange")
}

// Test nil/empty cases
func testDurationText_NilDuration() {
    let item = TestDataFactory.workoutRecommendationItem(durationMinutes: nil)
    let recommendation = AIWorkoutRecommendation(from: item)

    XCTAssertEqual(recommendation.durationText, "")
}

// Test extreme values
func testFatigueScore_ExtremeValues() {
    let zeroFatigue = TestDataFactory.fatigueAccumulation(fatigueScore: 0)
    let maxFatigue = TestDataFactory.fatigueAccumulation(fatigueScore: 100)

    XCTAssertEqual(zeroFatigue.fatigueScore, 0)
    XCTAssertEqual(maxFatigue.fatigueScore, 100)
}
```

## Test Organization with MARK Comments

Organize test methods using MARK comments:

```swift
final class FatigueTrackingServiceTests: XCTestCase {

    // MARK: - Properties

    var service: FatigueTrackingService!

    // MARK: - Setup & Teardown

    override func setUp() async throws { ... }
    override func tearDown() async throws { ... }

    // MARK: - Initialization Tests

    func testService_Initialization() { ... }

    // MARK: - Computed Property Tests

    func testFatigueScore_WhenSummaryExists_ReturnsValue() { ... }

    // MARK: - Loading Tests

    func testLoadData_Success() async { ... }
    func testLoadData_Failure() async { ... }

    // MARK: - Edge Cases

    func testZeroValues() { ... }
    func testExtremeValues() { ... }
}
```

## Best Practices

1. **One assertion concept per test** - Test one thing at a time
2. **Use Given-When-Then** - Structure tests clearly
3. **Test behavior, not implementation** - Focus on what, not how
4. **Keep tests independent** - No test should depend on another
5. **Use meaningful test data** - Factory methods help with this
6. **Clean up in tearDown** - Reset state to avoid test pollution
7. **Mark async tests with @MainActor** - When testing UI-related code

## Test Helpers Reference

### TestUUIDs
Stable UUIDs for consistent test data:
- `TestUUIDs.patient` - For patient-related tests
- `TestUUIDs.exerciseTemplate` - For exercise tests
- `TestUUIDs.workoutTemplate` - For workout tests
- `TestUUIDs.sequence(count:)` - Generate multiple UUIDs

### TestDates
Date utilities:
- `TestDates.reference` - January 15, 2024 at 12:00 PM
- `TestDates.daysFromReference(_:)` - Relative to reference
- `TestDates.daysFromNow(_:)` - Relative to current date
- `TestDates.dateString(_:)` - Format as yyyy-MM-dd

### TestDataFactory
Factory methods for mock data:
- `TestDataFactory.fatigueSummary(...)`
- `TestDataFactory.fatigueAccumulation(...)`
- `TestDataFactory.fatigueTrend(days:...)`
- `TestDataFactory.deloadPrescription(...)`
- `TestDataFactory.deloadRecommendation(...)`
- `TestDataFactory.workoutRecommendationItem(...)`
- `TestDataFactory.exerciseSubstitution(...)`

### JSONTestHelpers
JSON utilities:
- `JSONTestHelpers.standardDecoder` - Configured decoder
- `JSONTestHelpers.standardEncoder` - Configured encoder
- `JSONTestHelpers.roundTrip(_:)` - Encode/decode cycle
- `JSONTestHelpers.jsonData(_:)` - String to Data

### XCTestCase Extensions
Custom assertions:
- `assertApproximatelyEqual(_:_:accuracy:)` - Double comparison
- `assertInRange(_:min:max:)` - Range validation
- `assertContainsAll(_:expected:)` - Collection contents
- `assertSorted(_:by:)` - Collection ordering
- `assertThrowsAsync(_:expectedError:)` - Async error testing

### TestConstants
Common values:
- `TestConstants.floatAccuracy` - 0.01
- `TestConstants.asyncTimeout` - 5.0 seconds
- `TestConstants.shortTimeout` - 1.0 second
- `TestConstants.longTimeout` - 10.0 seconds
