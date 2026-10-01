/**
 * CORS Configuration
 */
const config = require('./env');

const corsOptions = {
  origin: (origin, callback) => {
    // Allow mobile apps, curl, Postman (no origin) or configured origin
    if (!origin || config.cors.origin === '*' || config.cors.origin.split(',').includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Blocked by CORS policy'));
    }
  },
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  credentials: true,
};

module.exports = corsOptions;
