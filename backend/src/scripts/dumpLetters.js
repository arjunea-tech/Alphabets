const { pool } = require('../config/db');

async function dump() {
  try {
    const [rows] = await pool.query('SELECT id, letter, type, word, meaning, image_path, audio_path FROM letters ORDER BY id');
    console.log(JSON.stringify(rows, null, 2));
  } catch (e) {
    console.error('DB Error:', e.message);
  }
  process.exit(0);
}

dump();
