/**
 * Seed English Alphabet Educational Games into Database
 */
const { pool } = require('../config/db');

async function seedGames() {
  const games = [
    {
      id: 'game_candy_1',
      game_type: 'candy',
      title: 'Alphabet Candy Match',
      prompt: 'Match 3 colorful letter candies in a row to burst them!',
      clue: 'Match-3 Sweet Alphabet Candy Game',
      clue_image: 'assets/images/games/candy_match_cover.png',
      correct_index: 0,
      options_json: JSON.stringify(['A', 'B', 'C', 'D']),
      success_praise: 'Candy Burst! Super combo! 🍬⭐',
      stars_reward: 5,
      display_order: 1,
      is_active: 1,
    },
    {
      id: 'game_runner_1',
      game_type: 'runner',
      title: 'Alphabet Runner',
      prompt: 'Run, jump, and collect English letters along the jungle trail!',
      clue: '2D Endless Alphabet Platform Runner',
      clue_image: 'assets/images/games/runner_cover.png',
      correct_index: 0,
      options_json: JSON.stringify(['A', 'B', 'C', 'D']),
      success_praise: 'Awesome! All letters collected! 🏃‍♂️🚀',
      stars_reward: 5,
      display_order: 2,
      is_active: 1,
    },
    {
      id: 'game_balloon_1',
      game_type: 'balloon',
      title: 'Balloon Word Pop',
      prompt: 'Tap and pop the floating balloons that have the target letter or word!',
      clue: 'Floating Balloon Pop Game in Fairytale Sky',
      clue_image: 'assets/images/games/balloon_pop_cover.png',
      correct_index: 0,
      options_json: JSON.stringify(['A', 'E', 'I', 'O', 'U']),
      success_praise: 'POP! Perfect letter pop! 🎈🎉',
      stars_reward: 5,
      display_order: 3,
      is_active: 1,
    },
    {
      id: 'game_flappy_1',
      game_type: 'flappy',
      title: 'Flappy Word',
      prompt: 'Flap your wings and fly through the correct cloud letter gates!',
      clue: 'Fly through cloud gates with target letters',
      clue_image: 'assets/images/games/flappy_word_cover.png',
      correct_index: 0,
      options_json: JSON.stringify(['A', 'B', 'C', 'D']),
      success_praise: 'Gate Cleared! Great flying! 🕊️⭐',
      stars_reward: 5,
      display_order: 4,
      is_active: 1,
    },
    {
      id: 'game_ninja_1',
      game_type: 'ninja',
      title: 'Word Ninja',
      prompt: 'Swipe your katana to slice the flying letter fruits in half!',
      clue: 'Fruit & Word Slicing Ninja Challenge',
      clue_image: 'assets/images/games/word_ninja_cover.png',
      correct_index: 0,
      options_json: JSON.stringify(['A', 'E', 'I', 'O', 'U']),
      success_praise: 'Ninja Slash! Direct hit! 🥷🍉💥',
      stars_reward: 5,
      display_order: 5,
      is_active: 1,
    },
    {
      id: 'game_racing_1',
      game_type: 'racing',
      title: 'Car Racing (Vowels)',
      prompt: 'Listen to the sound and steer your race car through the correct vowel!',
      clue: 'Highway Car Racing Challenge',
      clue_image: 'assets/images/games/car_racing_cover.png',
      correct_index: 0,
      options_json: JSON.stringify(['A', 'E', 'I', 'O', 'U']),
      success_praise: 'Speed Champion! Clean lap! 🚗🏆',
      stars_reward: 5,
      display_order: 6,
      is_active: 1,
    },
    {
      id: 'game_fishing_1',
      game_type: 'fishing',
      title: 'Letter Fishing',
      prompt: 'Tap and catch the swimming fish carrying the target letter!',
      clue: 'Deep Sea Alphabet Fishing',
      clue_image: 'assets/images/games/fishing_cover.png',
      correct_index: 0,
      options_json: JSON.stringify(['A', 'B', 'C', 'D']),
      success_praise: 'Fish Caught! Splendid angling! 🎣🐟',
      stars_reward: 5,
      display_order: 7,
      is_active: 1,
    },
    {
      id: 'game_basket_1',
      game_type: 'basket',
      title: 'Letter Basket (Vowels)',
      prompt: 'Catch the falling vowel letters into your basket!',
      clue: 'Catch Falling Vowels A, E, I, O, U',
      clue_image: 'assets/images/games/basket_vowels_cover.png',
      correct_index: 0,
      options_json: JSON.stringify(['A', 'E', 'I', 'O', 'U']),
      success_praise: 'Basket Full! Perfect catch! 🧺🍎',
      stars_reward: 5,
      display_order: 8,
      is_active: 1,
    },
    {
      id: 'game_basket_2',
      game_type: 'basket',
      title: 'Letter Basket (Consonants)',
      prompt: 'Catch the falling consonant letters into your magical basket!',
      clue: 'Catch Falling Consonants in Enchanted Forest',
      clue_image: 'assets/images/games/basket_consonants_cover.png',
      correct_index: 0,
      options_json: JSON.stringify(['B', 'C', 'D', 'F', 'G']),
      success_praise: 'Super catch! You got it! 🧺🌟',
      stars_reward: 5,
      display_order: 9,
      is_active: 1,
    },
    {
      id: 'game_puzzle_1',
      game_type: 'puzzle',
      title: 'Word Puzzle',
      prompt: 'Select the missing starting letter to complete the word!',
      clue: 'Interactive Alphabet Word Puzzle',
      clue_image: 'assets/images/welcome.png',
      correct_index: 0,
      options_json: JSON.stringify(['A', 'B', 'C', 'D']),
      success_praise: 'Brilliant! Word completed! 🧩✨',
      stars_reward: 5,
      display_order: 10,
      is_active: 1,
    },
  ];

  console.log('Seeding English Alphabet games into database...');
  for (const g of games) {
    await pool.query(
      `INSERT INTO games (id, game_type, title, prompt, clue, clue_image, correct_index, options_json, success_praise, stars_reward, display_order, is_active)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE 
         game_type = VALUES(game_type),
         title = VALUES(title),
         prompt = VALUES(prompt),
         clue = VALUES(clue),
         clue_image = VALUES(clue_image),
         correct_index = VALUES(correct_index),
         options_json = VALUES(options_json),
         success_praise = VALUES(success_praise),
         stars_reward = VALUES(stars_reward),
         display_order = VALUES(display_order),
         is_active = VALUES(is_active)`,
      [
        g.id,
        g.game_type,
        g.title,
        g.prompt,
        g.clue,
        g.clue_image,
        g.correct_index,
        g.options_json,
        g.success_praise,
        g.stars_reward,
        g.display_order,
        g.is_active,
      ]
    );
  }

  const [rows] = await pool.query('SELECT id, game_type, title, is_active, display_order FROM games ORDER BY display_order');
  console.log(`✅ ${rows.length} Games now in database:`);
  console.table(rows);
  process.exit(0);
}

seedGames().catch((err) => {
  console.error('Failed to seed games:', err);
  process.exit(1);
});
