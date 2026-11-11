/**
 * Add Flappy Word, Word Ninja and Letter Matching to an existing database.
 *
 * Safe to re-run: other games are never touched, and a game type that already
 * has a row is only switched to active, keeping any edits made in the admin panel.
 */
const { pool } = require('../config/db');
const GameModel = require('../models/gameModel');

const games = [
  {
    id: 'game_flappy_1',
    gameType: 'flappy',
    title: 'Flappy Word',
    prompt: 'Flap your wings and fly through the correct cloud letter gates!',
    clue: 'Fly through cloud gates with target letters',
    clueImage: 'assets/images/games/flappy_word_cover.png',
    options: ['A', 'B', 'C', 'D'],
    successPraise: 'Gate Cleared! Great flying! 🕊️⭐',
    starsReward: 5,
    displayOrder: 8,
  },
  {
    id: 'game_ninja_1',
    gameType: 'ninja',
    title: 'Word Ninja',
    prompt: 'Swipe your katana to slice the flying letter fruits in half!',
    clue: 'Fruit & Word Slicing Ninja Challenge',
    clueImage: 'assets/images/games/word_ninja_cover.png',
    options: ['A', 'E', 'I', 'O', 'U'],
    successPraise: 'Ninja Slash! Direct hit! 🥷🍉💥',
    starsReward: 5,
    displayOrder: 9,
  },
  {
    id: 'game_matching_1',
    gameType: 'matching',
    title: 'Letter Matching',
    prompt: 'Flip the cards and match each big letter with its small letter!',
    clue: 'Big and Small Letter Memory Match',
    clueImage: 'assets/images/games/letter_matching_cover.png',
    options: ['A', 'B', 'C', 'D'],
    successPraise: 'Perfect Match! Great memory! 🔄⭐',
    starsReward: 5,
    displayOrder: 10,
  },
];

async function addMissingGames() {
  for (const game of games) {
    const [existing] = await pool.query('SELECT id FROM games WHERE game_type = ?', [game.gameType]);

    if (existing.length > 0) {
      await pool.query('UPDATE games SET is_active = TRUE WHERE game_type = ?', [game.gameType]);
      console.log(`Activated existing ${game.gameType} game`);
    } else {
      await GameModel.create({ ...game, isActive: true });
      console.log(`Added ${game.gameType} game`);
    }
  }

  const [rows] = await pool.query(
    'SELECT id, game_type, title, is_active, display_order FROM games ORDER BY display_order'
  );
  console.table(rows);
  process.exit(0);
}

addMissingGames().catch((err) => {
  console.error('Failed to add games:', err);
  process.exit(1);
});
