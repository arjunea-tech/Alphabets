/**
 * =====================================================================
 * ALPHABETS - English Alphabet Educational Platform Backend API
 * Node.js + Express.js + MySQL REST API
 * =====================================================================
 */
const path = require('path');
const express = require('express');
const helmet = require('helmet');
const morgan = require('morgan');
const cors = require('cors');

const config = require('./src/config/env');
const corsOptions = require('./src/config/cors');
const { testConnection } = require('./src/config/db');
const { applySchemaPatches } = require('./src/config/schemaPatches');
const apiV1Router = require('./src/routes');
const { notFoundHandler, globalErrorHandler } = require('./src/middleware/errorMiddleware');
const { successResponse } = require('./src/utils/apiResponse');
const logger = require('./src/utils/logger');

const app = express();

// Security Headers
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' }, // Allows mobile apps & web admin to load uploaded media
}));

// CORS Configuration
app.use(cors(corsOptions));

// HTTP Request Logger
if (config.env !== 'test') {
  app.use(morgan('dev'));
}

// Body Parsers
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Static Media Serving for Uploaded Images, Audio, and Video files, plus default assets
// maxAge lets phones/browsers keep media locally instead of re-downloading it on every screen.
const staticCache = { maxAge: '7d', etag: true };
app.use('/uploads', express.static(path.join(__dirname, 'uploads'), staticCache));
app.use('/assets', express.static(path.join(__dirname, '../frontend/assets'), staticCache));
app.use('/assets', express.static(path.join(__dirname, '../assets'), staticCache));

// ---------------------------------------------------------------------
// Health Check Endpoint
// ---------------------------------------------------------------------
app.get('/api/health', (req, res) => {
  return successResponse(res, 'ALPHABETS API is healthy', {
    service: 'alphabets-backend',
    version: '1.0.0',
    uptime: `${Math.floor(process.uptime())}s`,
    timestamp: new Date().toISOString(),
  });
});

// Root friendly welcome endpoint
app.get('/', (req, res) => {
  return successResponse(res, 'Welcome to ALPHABETS Tamil Educational Platform API', {
    healthCheck: '/api/health',
    apiDocs: '/api/v1',
  });
});

// ---------------------------------------------------------------------
// API Routes (Version 1: /api/v1)
// ---------------------------------------------------------------------
app.use(config.apiPrefix, apiV1Router);

// ---------------------------------------------------------------------
// Error Handling
// ---------------------------------------------------------------------
app.use(notFoundHandler);
app.use(globalErrorHandler);

// ---------------------------------------------------------------------
// Server Initialization
// ---------------------------------------------------------------------
const PORT = config.port;

async function startServer() {
  // Test database connection, then add any columns older databases are missing
  if (await testConnection()) {
    await applySchemaPatches();
  }

  const server = app.listen(PORT, () => {
    logger.info(`====================================================`);
    logger.info(`🌟 Backend Server running on port ${PORT}`);
    logger.info(`🌐 Environment: ${config.env}`);
    logger.info(`🩺 Health check: http://localhost:${PORT}/api/health`);
    logger.info(`📚 API Base: http://localhost:${PORT}${config.apiPrefix}`);
    logger.info(`====================================================`);
  });

  // Graceful Shutdown
  const shutdown = () => {
    logger.info('🛑 Shutting down ALPHABETS server gracefully...');
    server.close(() => {
      logger.info('💤 Server closed.');
      process.exit(0);
    });
  };

  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);

  return server;
}

if (require.main === module) {
  startServer();
}

module.exports = { app, startServer };
