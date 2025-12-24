# Build 76 Integration Testing Plan

**Build:** 76 - WHOOP Integration
**Date:** 2025-12-24
**Scope:** Integration testing (iOS + Supabase Edge Functions)

---

## Testing Strategy

### Test Levels
1. **Unit Tests** - Individual component testing
2. **Integration Tests** - Cross-component testing
3. **End-to-End Tests** - Full user flow testing
4. **Performance Tests** - Load and response time testing

---

## 1. Supabase Edge Function Tests

### Edge Function Tests

**File:** `supabase/functions/whoop-sync-recovery/test.ts`

```python
import pytest
from zones.z09_integration.whoop.whoop_client import WHOOPClient
from zones.z09_integration.whoop.whoop_mapper import WHOOPMapper, ReadinessBand


class TestWHOOPClient:
    """Test WHOOP API client"""

    def test_get_recovery_success(self, mock_whoop_api):
        """Test successful recovery data fetch"""
        client = WHOOPClient(access_token="test_token")
        recovery = client.get_recovery()

        assert recovery is not None
        assert 'recovery_score' in recovery
        assert 0 <= recovery['recovery_score'] <= 100

    def test_get_recovery_api_error(self, mock_whoop_api_error):
        """Test recovery fetch with API error"""
        client = WHOOPClient(access_token="test_token")

        with pytest.raises(Exception):
            client.get_recovery()


class TestWHOOPMapper:
    """Test WHOOP → PT Performance mapping"""

    def test_recovery_to_readiness_green(self):
        """Test green band mapping (67-100%)"""
        band = WHOOPMapper.recovery_to_readiness_band(85.0)
        assert band == ReadinessBand.GREEN

    def test_recovery_to_readiness_yellow(self):
        """Test yellow band mapping (34-66%)"""
        band = WHOOPMapper.recovery_to_readiness_band(50.0)
        assert band == ReadinessBand.YELLOW

    def test_recovery_to_readiness_red(self):
        """Test red band mapping (0-33%)"""
        band = WHOOPMapper.recovery_to_readiness_band(20.0)
        assert band == ReadinessBand.RED

    def test_session_adjustment_green(self):
        """Test auto-adjustment for green recovery"""
        adjustment = WHOOPMapper.recovery_to_session_adjustment(85.0)

        assert adjustment['volume_multiplier'] == 1.0
        assert adjustment['intensity_recommendation'] == 'high'

    def test_session_adjustment_yellow(self):
        """Test auto-adjustment for yellow recovery"""
        adjustment = WHOOPMapper.recovery_to_session_adjustment(50.0)

        assert adjustment['volume_multiplier'] == 0.85
        assert adjustment['intensity_recommendation'] == 'moderate'

    def test_session_adjustment_red(self):
        """Test auto-adjustment for red recovery"""
        adjustment = WHOOPMapper.recovery_to_session_adjustment(20.0)

        assert adjustment['volume_multiplier'] == 0.65
        assert adjustment['intensity_recommendation'] == 'low'
```

---

## 2. Supabase Tests

### Database Tests

**Test:** Recovery Data Insert

```sql
-- Test: Insert WHOOP recovery data
INSERT INTO whoop_recovery (
    athlete_id,
    date,
    recovery_score,
    hrv_rmssd,
    resting_hr,
    readiness_band
) VALUES (
    'test-athlete-uuid',
    CURRENT_DATE,
    75.0,
    65.5,
    52,
    'green'
);

-- Verify: Check insert succeeded
SELECT * FROM whoop_recovery WHERE athlete_id = 'test-athlete-uuid';

-- Expected: 1 row returned with correct data
```

**Test:** Unique Constraint

```sql
-- Test: Duplicate athlete/date should fail
INSERT INTO whoop_recovery (athlete_id, date, recovery_score, readiness_band)
VALUES ('test-athlete-uuid', CURRENT_DATE, 80.0, 'green');

-- Expected: Error (unique constraint violation)
```

---

### Edge Function Tests

**File:** `supabase/functions/whoop-sync-recovery/test.ts`

```typescript
import { assertEquals, assertExists } from "https://deno.land/std/testing/asserts.ts";

Deno.test("WHOOP sync recovery - success", async () => {
  const response = await fetch("http://localhost:54321/functions/v1/whoop-sync-recovery", {
    method: "POST",
    headers: {
      "Authorization": "Bearer test_token",
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      athlete_id: "test-athlete-uuid"
    })
  });

  assertEquals(response.status, 200);

  const data = await response.json();
  assertExists(data.recovery_score);
  assertEquals(typeof data.recovery_score, "number");
});

Deno.test("WHOOP sync recovery - unauthorized", async () => {
  const response = await fetch("http://localhost:54321/functions/v1/whoop-sync-recovery", {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    }
  });

  assertEquals(response.status, 401);
});
```

---

## 3. iOS Tests

### Unit Tests

**File:** `ios-app/PTPerformance/Tests/Unit/WHOOPServiceTests.swift`

```swift
import XCTest
@testable import PTPerformance

class WHOOPServiceTests: XCTestCase {

    func testGetReadinessBandGreen() {
        let service = WHOOPService()
        let band = service.getReadinessBand(from: 85.0)

        XCTAssertEqual(band, .green)
    }

    func testGetReadinessBandYellow() {
        let service = WHOOPService()
        let band = service.getReadinessBand(from: 50.0)

        XCTAssertEqual(band, .yellow)
    }

    func testGetReadinessBandRed() {
        let service = WHOOPService()
        let band = service.getReadinessBand(from: 20.0)

        XCTAssertEqual(band, .red)
    }

    func testFetchCurrentRecovery() async {
        let service = WHOOPService()

        await service.fetchCurrentRecovery()

        XCTAssertNotNil(service.currentRecovery)
    }
}
```

---

### UI Tests

**File:** `ios-app/PTPerformance/Tests/Integration/WHOOPIntegrationTests.swift`

```swift
import XCTest

class WHOOPIntegrationTests: XCTestCase {

    func testWHOOPOnboardingFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to WHOOP settings
        app.tabBars.buttons["Settings"].tap()
        app.buttons["Connect WHOOP"].tap()

        // Verify onboarding screen appears
        XCTAssertTrue(app.staticTexts["Connect WHOOP"].exists)

        // Tap Connect button
        app.buttons["Connect WHOOP Account"].tap()

        // Should open OAuth flow (Safari)
        // Note: Can't fully test OAuth in UI tests
    }

    func testWHOOPRecoveryCardDisplay() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--whoop-connected", "--whoop-recovery-75"]
        app.launch()

        // Navigate to daily readiness
        app.buttons["Daily Check-In"].tap()

        // Verify WHOOP recovery card appears
        XCTAssertTrue(app.staticTexts["WHOOP Recovery"].exists)
        XCTAssertTrue(app.staticTexts["75%"].exists)
        XCTAssertTrue(app.staticTexts["High Recovery"].exists)
    }

    func testAutoAdjustmentBanner() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--whoop-connected", "--whoop-recovery-45"]
        app.launch()

        // Navigate to today's session
        app.buttons["Today's Session"].tap()

        // Verify auto-adjustment banner
        XCTAssertTrue(app.staticTexts["WHOOP Auto-Adjustment"].exists)
        XCTAssertTrue(app.staticTexts["85%"].exists)  // Volume reduction

        // Test accepting adjustment
        app.buttons["Apply Adjustment"].tap()

        // Verify adjustment applied
        // (check that exercises show reduced volume)
    }
}
```

---

## 4. End-to-End Integration Tests

### Test Case 1: New User WHOOP Onboarding

**Steps:**
1. New user signs up for PT Performance
2. Navigates to Settings
3. Clicks "Connect WHOOP"
4. Completes OAuth flow
5. Returns to app
6. Views WHOOP recovery data

**Expected:**
- ✅ OAuth completes successfully
- ✅ Recovery data syncs from WHOOP
- ✅ Recovery score appears in app
- ✅ Readiness band is correct (green/yellow/red)

**Test Script:**
```bash
# Setup
cd ios-app/PTPerformance
xcodebuild -scheme PTPerformance -destination 'platform=iOS Simulator,name=iPhone 15' test -only-testing:PTPerformanceTests/WHOOPIntegrationTests/testWHOOPOnboardingFlow
```

---

### Test Case 2: Daily Recovery Sync

**Steps:**
1. User with WHOOP connected opens app
2. Navigates to Daily Readiness
3. WHOOP data auto-syncs
4. Recovery score displays

**Expected:**
- ✅ Sync completes in < 3 seconds
- ✅ Latest recovery data appears
- ✅ HRV, RHR, sleep data all present
- ✅ Readiness band matches score

**Test Script:**
```python
# Backend test
pytest quiver_platform/zones/z09_integration/whoop/tests/test_integration.py::test_daily_sync
```

---

### Test Case 3: Auto-Adjustment Applied

**Steps:**
1. User with WHOOP (recovery = 45%) opens app
2. Navigates to Today's Session
3. Auto-adjustment banner appears
4. User clicks "Apply Adjustment"
5. Session exercises update

**Expected:**
- ✅ Banner shows 85% volume reduction
- ✅ Intensity recommendation = "moderate"
- ✅ Accepting applies changes
- ✅ Exercise volumes reduce correctly
- ✅ Notes show adjustment reason

---

### Test Case 4: WHOOP Disconnect

**Steps:**
1. User navigates to WHOOP settings
2. Clicks "Disconnect WHOOP"
3. Confirms disconnect
4. WHOOP data removed from app

**Expected:**
- ✅ Credentials removed from database
- ✅ Recovery card disappears
- ✅ Auto-adjustment disabled
- ✅ User can reconnect later

---

## 5. Performance Tests

### Load Testing

**Test:** 100 Concurrent Recovery Syncs

```python
import asyncio
from locust import HttpUser, task, between

class WHOOPUser(HttpUser):
    wait_time = between(1, 3)

    @task
    def sync_recovery(self):
        self.client.post("/functions/v1/whoop-sync-recovery",
                         headers={"Authorization": f"Bearer {self.auth_token}"})

# Run: locust -f whoop_load_test.py --users 100 --spawn-rate 10
```

**Expected:**
- ✅ All 100 requests complete successfully
- ✅ Average response time < 2 seconds
- ✅ No rate limit errors from WHOOP API
- ✅ No database connection errors

---

### Response Time Tests

**Test:** Recovery Data Fetch

```python
import time

def test_recovery_fetch_performance():
    start = time.time()

    # Fetch recovery data
    response = supabase.from_('whoop_recovery') \
        .select('*') \
        .eq('athlete_id', 'test-athlete-uuid') \
        .limit(1) \
        .execute()

    duration = time.time() - start

    assert duration < 0.5  # < 500ms
    assert response.data is not None
```

**Expected:**
- ✅ Database query < 500ms
- ✅ Edge Function invocation < 2 seconds
- ✅ Full sync (WHOOP API → DB → iOS) < 5 seconds

---

## 6. Security Tests

### OAuth Security

**Test:** Invalid Access Token

```python
def test_invalid_access_token():
    client = WHOOPClient(access_token="invalid_token")

    with pytest.raises(UnauthorizedError):
        client.get_recovery()
```

**Test:** Token Expiration

```python
def test_expired_token_refresh():
    # Simulate expired token
    credentials = WHOOPCredentials(
        access_token="expired",
        refresh_token="valid_refresh",
        expires_at=datetime.now() - timedelta(hours=1)
    )

    # Should auto-refresh
    client = WHOOPClient.from_credentials(credentials)
    recovery = client.get_recovery()

    assert recovery is not None
    assert credentials.access_token != "expired"  # Token refreshed
```

---

## 7. Test Data

### Mock WHOOP Recovery Data

```json
{
  "recovery_score": 75.0,
  "hrv_rmssd": 65.5,
  "resting_hr": 52,
  "hrv_baseline": 60.0,
  "sleep_performance": 85.0,
  "date": "2025-12-24"
}
```

### Test Athletes

```sql
-- High recovery athlete
INSERT INTO whoop_recovery VALUES (
    'athlete-green-uuid', CURRENT_DATE, 85.0, 70.0, 48, 'green'
);

-- Moderate recovery athlete
INSERT INTO whoop_recovery VALUES (
    'athlete-yellow-uuid', CURRENT_DATE, 50.0, 55.0, 58, 'yellow'
);

-- Low recovery athlete
INSERT INTO whoop_recovery VALUES (
    'athlete-red-uuid', CURRENT_DATE, 25.0, 45.0, 65, 'red'
);
```

---

## Test Execution Plan

### Phase 1: Unit Tests (Day 1)
```bash
# Quiver tests
cd quiver_platform
pytest zones/z09_integration/whoop/tests/ -v

# iOS tests
cd ios-app/PTPerformance
xcodebuild test -scheme PTPerformance -only-testing:WHOOPServiceTests
```

### Phase 2: Integration Tests (Day 2)
```bash
# Supabase Edge Function tests
cd supabase/functions
deno test whoop-sync-recovery/test.ts

# iOS integration tests
xcodebuild test -scheme PTPerformance -only-testing:WHOOPIntegrationTests
```

### Phase 3: E2E Tests (Day 3)
```bash
# Full flow testing with TestFlight build
# Manual testing on physical devices
# QA team verification
```

---

## Success Criteria

- ✅ All unit tests passing (100%)
- ✅ All integration tests passing (100%)
- ✅ E2E flows complete successfully
- ✅ Performance tests meet SLAs
- ✅ No security vulnerabilities
- ✅ Manual QA approval

---

## Rollback Plan

If critical issues found:
1. Disable WHOOP features via feature flag
2. Revert database migrations
3. Roll back to Build 75
4. Fix issues in development
5. Re-test completely
6. Re-deploy as Build 76.1

---

**Test Coverage Goal:** 90%+
**Timeline:** 3 days parallel with development
**Responsible:** QA Team + Engineering
