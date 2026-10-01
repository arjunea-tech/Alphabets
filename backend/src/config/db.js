/**
 * MySQL Database Connection Pool
 */
const mysql = require('mysql2/promise');
const config = require('./env');
const logger = require('../utils/logger');

const pool = mysql.createPool({
  host: config.db.host,
  port: config.db.port,
  user: config.db.user,
  password: config.db.password,
  database: config.db.name,
  waitForConnections: true,
  connectionLimit: config.db.connectionLimit,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0,
});

async function testConnection() {
  try {
    const connection = await pool.getConnection();
    logger.info(`✅ Connected to MySQL database '${config.db.name}' successfully.`);
    connection.release();
    return true;
  } catch (error) {
    logger.error('❌ Database connection failed:', error.message);
    if (error.code === 'ER_BAD_DB_ERROR') {
      logger.warn(`💡 Database '${config.db.name}' does not exist yet. Run 'npm run db:init' to create and seed it.`);
    } else if (error.code === 'ECONNREFUSED') {
      logger.warn(`💡 Ensure MySQL is running on ${config.db.host}:${config.db.port}.`);
    } else if (error.code === 'ER_ACCESS_DENIED_ERROR') {
      logger.warn(`💡 Check your DB_USER / DB_PASSWORD credentials in backend/.env.`);
    }
    return false;
  }
}

module.exports = {
  pool,
  testConnection,
};
