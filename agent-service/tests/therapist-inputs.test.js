import { parseBearerToken } from '../src/middleware/auth.js';
import { parseOptionalNumber, parseFilters, parsePositiveInteger } from '../src/routes/therapist.js';

describe('therapist auth helper logic', () => {
  test('parseBearerToken extracts token for valid Bearer header', () => {
    expect(parseBearerToken('Bearer abc123')).toBe('abc123');
  });

  test('parseBearerToken returns null for invalid header', () => {
    expect(parseBearerToken('Token abc123')).toBeNull();
    expect(parseBearerToken(undefined)).toBeNull();
  });
});

describe('therapist filter parsing', () => {
  test('parseOptionalNumber parses valid number', () => {
    expect(parseOptionalNumber('42.5', 'minAdherence')).toBe(42.5);
    expect(parseOptionalNumber('', 'minAdherence')).toBeNull();
  });

  test('parsePositiveInteger validates pagination fields', () => {
    expect(parsePositiveInteger('20', 'limit', 50, 200)).toBe(20);
    expect(parsePositiveInteger('', 'limit', 50, 200)).toBe(50);
    expect(() => parsePositiveInteger('-1', 'offset', 0)).toThrow('offset must be a non-negative integer');
    expect(() => parsePositiveInteger('500', 'limit', 50, 200)).toThrow('limit cannot exceed 200');
  });

  test('parseFilters validates enums, ranges, and pagination', () => {
    const parsed = parseFilters(
      { flagSeverity: 'HIGH', hasFlags: 'true', minAdherence: '10', maxAdherence: '80', limit: '25', offset: '10' },
      'ther-1'
    );

    expect(parsed.flagSeverity).toBe('HIGH');
    expect(parsed.hasFlags).toBe(true);
    expect(parsed.minAdherence).toBe(10);
    expect(parsed.maxAdherence).toBe(80);
    expect(parsed.limit).toBe(25);
    expect(parsed.offset).toBe(10);

    expect(() => parseFilters({ flagSeverity: 'CRITICAL' }, 'ther-1')).toThrow('flagSeverity must be one of HIGH, MEDIUM, LOW');
    expect(() => parseFilters({ hasFlags: 'maybe' }, 'ther-1')).toThrow('hasFlags must be true or false');
    expect(() => parseFilters({ minAdherence: '90', maxAdherence: '30' }, 'ther-1')).toThrow('minAdherence cannot be greater than maxAdherence');
  });
});
