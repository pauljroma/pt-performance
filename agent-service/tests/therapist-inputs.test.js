import { parseBearerToken, getAuthorizedTherapistIds } from '../src/middleware/auth.js';
import { parseOptionalNumber, parseFilters } from '../src/routes/therapist.js';

describe('therapist auth helper logic', () => {
  test('parseBearerToken extracts token for valid Bearer header', () => {
    expect(parseBearerToken('Bearer abc123')).toBe('abc123');
  });

  test('parseBearerToken returns null for invalid header', () => {
    expect(parseBearerToken('Token abc123')).toBeNull();
    expect(parseBearerToken(undefined)).toBeNull();
  });

  test('getAuthorizedTherapistIds includes known id sources without duplicates', () => {
    const ids = getAuthorizedTherapistIds({
      id: 'user-1',
      app_metadata: { therapist_id: 'ther-1' },
      user_metadata: { therapist_id: 'ther-1' },
    });

    expect(ids.has('user-1')).toBe(true);
    expect(ids.has('ther-1')).toBe(true);
    expect(ids.size).toBe(2);
  });
});

describe('therapist filter parsing', () => {
  test('parseOptionalNumber parses valid number', () => {
    expect(parseOptionalNumber('42.5', 'minAdherence')).toBe(42.5);
    expect(parseOptionalNumber('', 'minAdherence')).toBeNull();
  });

  test('parseFilters validates enums and ranges', () => {
    const parsed = parseFilters({ flagSeverity: 'HIGH', hasFlags: 'true', minAdherence: '10', maxAdherence: '80' }, 'ther-1');
    expect(parsed.flagSeverity).toBe('HIGH');
    expect(parsed.hasFlags).toBe(true);
    expect(parsed.minAdherence).toBe(10);
    expect(parsed.maxAdherence).toBe(80);

    expect(() => parseFilters({ flagSeverity: 'CRITICAL' }, 'ther-1')).toThrow('flagSeverity must be one of HIGH, MEDIUM, LOW');
    expect(() => parseFilters({ hasFlags: 'maybe' }, 'ther-1')).toThrow('hasFlags must be true or false');
    expect(() => parseFilters({ minAdherence: '90', maxAdherence: '30' }, 'ther-1')).toThrow('minAdherence cannot be greater than maxAdherence');
  });
});
