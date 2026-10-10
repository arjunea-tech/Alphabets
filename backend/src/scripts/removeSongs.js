const { pool } = require('../config/db');

async function removeSongs() {
  const [res] = await pool.query(
    "DELETE FROM videos WHERE id IN ('vid_tamil_intro', 'vid_uyir_song', 'vid_mei_rhyme') OR category IN ('பாடல்', 'கதை')"
  );
  console.log('✅ Deleted songs/stories count:', res.affectedRows);
  
  // Also update Aytham category to 'ஆய்த எழுத்து'
  await pool.query(
    "UPDATE videos SET category = 'ஆய்த எழுத்து' WHERE id = 'vid_aytham_1'"
  );
  console.log('✅ Aytham category updated to ஆய்த எழுத்து');
  
  const [remaining] = await pool.query('SELECT id, title, category FROM videos ORDER BY display_order');
  console.log('Remaining videos in DB:', remaining.length);
  process.exit(0);
}

removeSongs().catch(err => {
  console.error(err);
  process.exit(1);
});
