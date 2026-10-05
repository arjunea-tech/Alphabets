const { pool } = require('../config/db');

async function updateCategories() {
  try {
    const uyirLetters = ['அ', 'ஆ', 'இ', 'ஈ', 'உ', 'ஊ', 'எ', 'ஏ', 'ஐ', 'ஒ', 'ஓ', 'ஔ'];
    for (let i = 0; i < uyirLetters.length; i++) {
      const letter = uyirLetters[i];
      await pool.query(
        'UPDATE videos SET category = ?, display_order = ? WHERE title = ? OR title LIKE ?',
        ['உயிர் எழுத்துகள்', i + 1, letter, `${letter} - %`]
      );
    }
    const [updated] = await pool.query('SELECT id, title, category, display_order FROM videos ORDER BY display_order ASC');
    console.log('UPDATED VIDEOS SUCCESS:');
    console.table(updated);
    process.exit(0);
  } catch (err) {
    console.error('Error updating videos:', err);
    process.exit(1);
  }
}

updateCategories();
