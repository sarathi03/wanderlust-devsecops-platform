import express from 'express';
import os from 'node:os';

// Static sample data, so the app has something to show without a database.
const destinations = [
  { id: 1, name: 'Munnar', country: 'India', tip: 'Tea gardens and misty hills' },
  { id: 2, name: 'Kyoto', country: 'Japan', tip: 'Temples and autumn colours' },
  { id: 3, name: 'Lisbon', country: 'Portugal', tip: 'Trams, tiles and sunsets' },
];

export function createApp() {
  const app = express();
  const startedAt = new Date().toISOString();

  // Used by Kubernetes readiness/liveness probes.
  app.get('/api/health', (req, res) => {
    res.json({ status: 'ok' });
  });

  // Shows WHICH build is running and WHICH pod answered.
  // APP_VERSION is baked into the image by the CI pipeline (the image tag).
  app.get('/api/info', (req, res) => {
    res.json({
      service: 'wanderlust-backend',
      version: process.env.APP_VERSION || 'dev',
      hostname: os.hostname(),
      startedAt,
    });
  });

  app.get('/api/destinations', (req, res) => {
    res.json(destinations);
  });

  return app;
}
