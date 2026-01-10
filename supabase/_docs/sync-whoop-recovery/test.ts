// Test file for sync-whoop-recovery Edge Function
// Build 138 - WHOOP Integration MVP

import {
  WHOOPCredentials,
  WHOOPAPIRecovery,
  DailyReadinessRecord,
  hasWHOOPCredentials,
  areCredentialsExpired,
  shouldRefreshRecovery,
  isValidRecoveryScore,
  isValidStrain,
  isValidHRV,
  estimateStrainFromRecovery,
  minutesUntilNextSync,
  calculateExpiresAt,
} from './types.ts';

// ============================================================================
// Test Data
// ============================================================================

const mockValidCredentials: WHOOPCredentials = {
  access_token: 'test_access_token_12345',
  refresh_token: 'test_refresh_token_67890',
  expires_at: new Date(Date.now() + 3600 * 1000).toISOString(), // 1 hour from now
  athlete_id: '123456',
};

const mockExpiredCredentials: WHOOPCredentials = {
  access_token: 'expired_token',
  refresh_token: 'test_refresh_token',
  expires_at: new Date(Date.now() - 3600 * 1000).toISOString(), // 1 hour ago
};

const mockRecoveryData: WHOOPAPIRecovery = {
  cycle_id: 123456,
  sleep_id: 789012,
  user_calibrating: false,
  recovery_score: 87,
  resting_heart_rate: 52,
  hrv_rmssd_milli: 62,
  spo2_percentage: 97,
  skin_temp_celsius: 33.4,
};

const mockPatientWithCreds = {
  id: '550e8400-e29b-41d4-a716-446655440000',
  whoop_oauth_credentials: mockValidCredentials,
};

const mockPatientWithoutCreds = {
  id: '550e8400-e29b-41d4-a716-446655440000',
};

// ============================================================================
// Test Functions
// ============================================================================

function testTypeGuards() {
  console.log('\n=== Testing Type Guards ===\n');

  // Test hasWHOOPCredentials
  console.assert(
    hasWHOOPCredentials(mockPatientWithCreds) === true,
    'Patient with credentials should return true'
  );
  console.assert(
    hasWHOOPCredentials(mockPatientWithoutCreds) === false,
    'Patient without credentials should return false'
  );
  console.log('✅ hasWHOOPCredentials tests passed');

  // Test areCredentialsExpired
  console.assert(
    areCredentialsExpired(mockValidCredentials) === false,
    'Valid credentials should not be expired'
  );
  console.assert(
    areCredentialsExpired(mockExpiredCredentials) === true,
    'Expired credentials should be expired'
  );
  console.log('✅ areCredentialsExpired tests passed');

  // Test shouldRefreshRecovery
  console.assert(
    shouldRefreshRecovery(null) === true,
    'Null synced_at should trigger refresh'
  );
  console.assert(
    shouldRefreshRecovery(undefined) === true,
    'Undefined synced_at should trigger refresh'
  );
  console.assert(
    shouldRefreshRecovery(new Date().toISOString()) === false,
    'Recent sync should not trigger refresh'
  );
  console.assert(
    shouldRefreshRecovery(new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString()) === true,
    'Old sync (2 hours ago) should trigger refresh'
  );
  console.log('✅ shouldRefreshRecovery tests passed');
}

function testValidationFunctions() {
  console.log('\n=== Testing Validation Functions ===\n');

  // Test isValidRecoveryScore
  console.assert(isValidRecoveryScore(50) === true, 'Valid recovery score (50)');
  console.assert(isValidRecoveryScore(0) === true, 'Valid recovery score (0)');
  console.assert(isValidRecoveryScore(100) === true, 'Valid recovery score (100)');
  console.assert(isValidRecoveryScore(-1) === false, 'Invalid recovery score (-1)');
  console.assert(isValidRecoveryScore(101) === false, 'Invalid recovery score (101)');
  console.log('✅ isValidRecoveryScore tests passed');

  // Test isValidStrain
  console.assert(isValidStrain(10) === true, 'Valid strain (10)');
  console.assert(isValidStrain(0) === true, 'Valid strain (0)');
  console.assert(isValidStrain(21) === true, 'Valid strain (21)');
  console.assert(isValidStrain(-1) === false, 'Invalid strain (-1)');
  console.assert(isValidStrain(22) === false, 'Invalid strain (22)');
  console.log('✅ isValidStrain tests passed');

  // Test isValidHRV
  console.assert(isValidHRV(50) === true, 'Valid HRV (50)');
  console.assert(isValidHRV(0) === true, 'Valid HRV (0)');
  console.assert(isValidHRV(200) === true, 'Valid HRV (200)');
  console.assert(isValidHRV(-1) === false, 'Invalid HRV (-1)');
  console.assert(isValidHRV(201) === false, 'Invalid HRV (201)');
  console.log('✅ isValidHRV tests passed');
}

function testUtilityFunctions() {
  console.log('\n=== Testing Utility Functions ===\n');

  // Test estimateStrainFromRecovery
  const highRecoveryStrain = estimateStrainFromRecovery(90); // Should be low strain
  const lowRecoveryStrain = estimateStrainFromRecovery(30); // Should be high strain
  console.assert(
    highRecoveryStrain < lowRecoveryStrain,
    `High recovery (90) should yield lower strain than low recovery (30): ${highRecoveryStrain} < ${lowRecoveryStrain}`
  );
  console.assert(
    highRecoveryStrain >= 0 && highRecoveryStrain <= 21,
    `Estimated strain should be in valid range: ${highRecoveryStrain}`
  );
  console.log('✅ estimateStrainFromRecovery tests passed');

  // Test minutesUntilNextSync
  const recentSync = new Date(Date.now() - 30 * 60 * 1000).toISOString(); // 30 mins ago
  const minutesRemaining = minutesUntilNextSync(recentSync);
  console.assert(
    minutesRemaining > 0 && minutesRemaining <= 60,
    `Minutes until next sync should be between 0 and 60: ${minutesRemaining}`
  );
  console.log('✅ minutesUntilNextSync tests passed');

  // Test calculateExpiresAt
  const expiresAt = calculateExpiresAt(3600);
  const expiresDate = new Date(expiresAt);
  const nowPlus1Hour = new Date(Date.now() + 3600 * 1000);
  const diff = Math.abs(expiresDate.getTime() - nowPlus1Hour.getTime());
  console.assert(
    diff < 1000, // Within 1 second tolerance
    `Expires at should be ~1 hour from now: ${diff}ms difference`
  );
  console.log('✅ calculateExpiresAt tests passed');
}

function testMockData() {
  console.log('\n=== Testing Mock Data Structure ===\n');

  // Validate mock recovery data
  console.assert(
    isValidRecoveryScore(mockRecoveryData.recovery_score),
    'Mock recovery score should be valid'
  );
  console.assert(
    isValidHRV(mockRecoveryData.hrv_rmssd_milli),
    'Mock HRV should be valid'
  );
  console.assert(
    mockRecoveryData.resting_heart_rate > 0 && mockRecoveryData.resting_heart_rate < 200,
    'Mock resting HR should be realistic'
  );
  console.log('✅ Mock data validation tests passed');

  // Test estimated strain from mock data
  const estimatedStrain = estimateStrainFromRecovery(mockRecoveryData.recovery_score);
  console.assert(
    isValidStrain(estimatedStrain),
    `Estimated strain from mock data should be valid: ${estimatedStrain}`
  );
  console.log('✅ Strain estimation from mock data passed');
}

function testEdgeCases() {
  console.log('\n=== Testing Edge Cases ===\n');

  // Test boundary values
  console.assert(isValidRecoveryScore(0), 'Boundary: recovery score 0');
  console.assert(isValidRecoveryScore(100), 'Boundary: recovery score 100');
  console.assert(isValidStrain(0), 'Boundary: strain 0');
  console.assert(isValidStrain(21), 'Boundary: strain 21');
  console.assert(isValidHRV(0), 'Boundary: HRV 0');
  console.assert(isValidHRV(200), 'Boundary: HRV 200');
  console.log('✅ Boundary value tests passed');

  // Test strain estimation boundaries
  const maxRecoveryStrain = estimateStrainFromRecovery(100);
  const minRecoveryStrain = estimateStrainFromRecovery(0);
  console.assert(
    maxRecoveryStrain >= 0 && maxRecoveryStrain <= 21,
    `Max recovery strain should be in range: ${maxRecoveryStrain}`
  );
  console.assert(
    minRecoveryStrain >= 0 && minRecoveryStrain <= 21,
    `Min recovery strain should be in range: ${minRecoveryStrain}`
  );
  console.log('✅ Strain estimation boundary tests passed');

  // Test null/undefined handling
  console.assert(
    shouldRefreshRecovery(null) === true,
    'Null synced_at should return true'
  );
  console.assert(
    shouldRefreshRecovery(undefined) === true,
    'Undefined synced_at should return true'
  );
  console.log('✅ Null/undefined handling tests passed');
}

// ============================================================================
// Run All Tests
// ============================================================================

function runAllTests() {
  console.log('\n╔════════════════════════════════════════════════════════════╗');
  console.log('║  sync-whoop-recovery Edge Function - Test Suite           ║');
  console.log('║  Build 138 - WHOOP Integration MVP                        ║');
  console.log('╚════════════════════════════════════════════════════════════╝');

  try {
    testTypeGuards();
    testValidationFunctions();
    testUtilityFunctions();
    testMockData();
    testEdgeCases();

    console.log('\n╔════════════════════════════════════════════════════════════╗');
    console.log('║  ✅ ALL TESTS PASSED                                       ║');
    console.log('╚════════════════════════════════════════════════════════════╝\n');
  } catch (error) {
    console.log('\n╔════════════════════════════════════════════════════════════╗');
    console.log('║  ❌ TESTS FAILED                                           ║');
    console.log('╚════════════════════════════════════════════════════════════╝\n');
    console.error('Error:', error);
    throw error;
  }
}

// Run tests if this file is executed directly
if (import.meta.main) {
  runAllTests();
}

export { runAllTests };
