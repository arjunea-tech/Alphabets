/**
 * Replace the placeholder image on seeded games with each game's real cover.
 *
 * Safe to re-run: only rows still using the placeholder change, so any cover
 * set from the admin panel is kept.
 */
const { pool } = require('../config/db');

const PLACEHOLDER = 'assets/images/welcome.png';

const covers = {
  runner: 'assets/images/games/runner_cover.png',
  candy: 'assets/images/games/candy_match_cover.png',
  racing: 'assets/images/games/car_racing_cover.png',
  fishing: 'assets/images/games/fishing_cover.png',
  basket: 'assets/images/games/basket_vowels_cover.png',
  puzzle: 'assets/images/games/word_puzzle_cover.png',
  balloon: 'assets/images/games/balloon_pop_cover.png',
};

async function setGameCovers() {
  for (const [gameType, cover] of Object.entries(covers)) {
    const [, meta] = await pool.query(
      'UPDATE games SET clue_image = ? WHERE game_type = ? AND clue_image = ?',
      [cover, gameType, PLACEHOLDER]
    );
    console.log(`${gameType}: ${meta.affectedRows} updated`);
  }

  const [rows] = await pool.query('SELECT id, game_type, clue_image FROM games ORDER BY display_order');
  console.table(rows);
  process.exit(0);
}

setGameCovers().catch((err) => {
  console.error('Failed to set game covers:', err);
  process.exit(1);
});
