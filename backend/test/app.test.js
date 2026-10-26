import { after, before, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { createApp } from '../src/app.js';

// Starts the app on a random free port; no database or other service needed.
let server;
let baseUrl;

before(async () => {
  server = createApp().listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(() => server.close());

describe('wanderlust-backend API', () => {
  it('GET /api/health returns ok', async () => {
    const res = await fetch(`${baseUrl}/api/health`);
    assert.equal(res.status, 200);
    assert.deepEqual(await res.json(), { status: 'ok' });
  });

  it('GET /api/info reports the version from APP_VERSION', async () => {
    const res = await fetch(`${baseUrl}/api/info`);
    const body = await res.json();
    assert.equal(res.status, 200);
    assert.equal(body.service, 'wanderlust-backend');
    assert.equal(body.version, process.env.APP_VERSION || 'dev');
    assert.ok(body.hostname);
  });

  it('GET /api/destinations returns a non-empty list', async () => {
    const res = await fetch(`${baseUrl}/api/destinations`);
    const body = await res.json();
    assert.equal(res.status, 200);
    assert.ok(Array.isArray(body) && body.length > 0);
  });

  it('unknown routes return 404', async () => {
    const res = await fetch(`${baseUrl}/api/does-not-exist`);
    assert.equal(res.status, 404);
  });
});
