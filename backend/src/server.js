import { createApp } from './app.js';

const port = Number(process.env.PORT) || 8080;

const server = createApp().listen(port, () => {
  console.log(`wanderlust-backend ${process.env.APP_VERSION || 'dev'} listening on port ${port}`);
});

// Kubernetes sends SIGTERM before stopping a pod during a rolling update.
// Closing the server cleanly lets in-flight requests finish.
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down');
  server.close(() => process.exit(0));
});
