import { AppError, createAppError, normalizeError } from '../src/errors/api-error.js';

describe('API error helpers', () => {
  test('createAppError builds stable code and status', () => {
    const err = createAppError('bad_request', 400, 'Invalid payload');

    expect(err).toBeInstanceOf(AppError);
    expect(err.code).toBe('bad_request');
    expect(err.statusCode).toBe(400);
    expect(err.message).toBe('Invalid payload');
  });

  test('normalizeError wraps non-AppError values', () => {
    const err = normalizeError(new Error('boom'));

    expect(err).toBeInstanceOf(AppError);
    expect(err.code).toBe('internal_server_error');
    expect(err.statusCode).toBe(500);
    expect(err.message).toBe('boom');
  });
});
