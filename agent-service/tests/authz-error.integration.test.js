import express from 'express';
import { createServer } from 'http';
import { globalErrorMiddleware } from '../src/errors/api-error.js';
import { requireTherapistOwnership } from '../src/middleware/auth.js';

function createTestApp() {
  const app = express();

  app.use((req, res, next) => {
    req.authorizedTherapistIds = new Set(['ther-123']);
    next();
  });

  app.get('/therapist/:therapistId/secure', requireTherapistOwnership, (req, res) => {
    res.json({ ok: true });
  });

  app.get('/boom', (req, res, next) => {
    next(new Error('database stacktrace'));
  });

  app.use(globalErrorMiddleware);
  return app;
}

describe('authz + global error middleware integration', () => {
  let server;
  let baseUrl;

  beforeAll(async () => {
    const app = createTestApp();
    server = createServer(app);

    await new Promise((resolve) => {
      server.listen(0, resolve);
    });

    const { port } = server.address();
    baseUrl = `http://127.0.0.1:${port}`;
  });

  afterAll(async () => {
    if (!server) return;
    await new Promise((resolve) => server.close(resolve));
  });

  test('allows request for owned therapist scope', async () => {
    const response = await fetch(`${baseUrl}/therapist/ther-123/secure`);
    expect(response.status).toBe(200);

    const body = await response.json();
    expect(body.ok).toBe(true);
  });

  test('returns stable forbidden payload for unauthorized therapist scope', async () => {
    const response = await fetch(`${baseUrl}/therapist/ther-999/secure`);
    expect(response.status).toBe(403);

    const body = await response.json();
    expect(body.error).toBe('forbidden');
  });

  test('hides internal messages from unknown errors in production', async () => {
    const previousNodeEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'production';

    const response = await fetch(`${baseUrl}/boom`);
    expect(response.status).toBe(500);

    const body = await response.json();
    expect(body.error).toBe('internal_server_error');
    expect(body.message).toBe('Unexpected server error');

    process.env.NODE_ENV = previousNodeEnv;
  });
});
