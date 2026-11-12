/**
 * CORS Configuration
 */
const config = require('./env');

// `flutter run -d chrome` and the admin panel's dev server pick a new port on
// each run, so local origins are allowed on any port.
const LOCAL_ORIGIN = /^https?:\/\/(localhost|127\.0\.0\.1|\[::1\])(:\d+)?$/;

const allowedOrigins = config.cors.origin
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

function isAllowedOrigin(origin) {
  // Mobile apps, curl and Postman send no Origin header.
  if (!origin) return true;
  if (allowedOrigins.includes('*') || allowedOrigins.includes(origin)) return true;
  return LOCAL_ORIGIN.test(origin);
}

const corsOptions = {
  // Passing `false` (instead of an Error) leaves out the CORS headers so the
  // browser blocks the request, without turning it into a 500 server error.
  origin: (origin, callback) => callback(null, isAllowedOrigin(origin)),
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  credentials: true,
};

module.exports = corsOptions;
