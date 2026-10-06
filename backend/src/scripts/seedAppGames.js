/**
 * Seed all mobile app games into the database
 */
const { pool } = require('../config/db');

async function seedGames() {
  const games = [
    {
      id: 'game_runner_1',
      game_type: 'runner',
      title: 'அகரம் ஓட்டம்',
      prompt: 'ஓடி விளையாடி தமிழ் எழுத்துகளை சேகரிக்கவும்!',
      clue: '2D ஓட்டப் பந்தய விளையாட்டு',
      clue_image: 'https://res.cloudinary.com/dyt5hqqzp/image/upload/v1772691653/agaram_media/images/game.png',
      correct_index: 0,
      options_json: JSON.stringify(['அ', 'ஆ', 'இ', 'ஈ']),
      success_praise: 'அருமை! எழுத்துகளை சரியாக சேகரித்தீர்கள்! 🚀',
      stars_reward: 3,
      display_order: 1,
      is_active: 1,
    },
    {
      id: 'game_candy_1',
      game_type: 'candy',
      title: 'தமிழ் எழுத்து மிட்டாய்',
      prompt: 'எழுத்துகளை 3 வரிசையில் இணைத்து மதிப்பெண் பெறவும்!',
      clue: 'Match-3 வண்ண மிட்டாய் விளையாட்டு',
      clue_image: 'https://res.cloudinary.com/dyt5hqqzp/image/upload/v1772691653/agaram_media/images/game.png',
      correct_index: 0,
      options_json: JSON.stringify(['உயிர் எழுத்துகள்', 'மெய் எழுத்துகள்', 'சொற்கள்']),
      success_praise: 'சூப்பர் காம்போ! ⭐',
      stars_reward: 3,
      display_order: 2,
      is_active: 1,
    },
    {
      id: 'game_fishing_1',
      game_type: 'fishing',
      title: 'எழுத்து மீன்பிடி',
      prompt: 'சரியான எழுத்துள்ள மீனைத் தொட்டு தூண்டிலில் பிடிக்கவும்!',
      clue: 'கடல் மீன்பிடி விளையாட்டு',
      clue_image: 'https://res.cloudinary.com/dyt5hqqzp/image/upload/v1772691653/agaram_media/images/fish.jpg',
      correct_index: 0,
      options_json: JSON.stringify(['அ', 'ஆ', 'இ', 'ஈ']),
      success_praise: 'மீன் பிடித்தாச்சு! அருமை! 🐟',
      stars_reward: 3,
      display_order: 3,
      is_active: 1,
    },
    {
      id: 'game_basket_1',
      game_type: 'basket',
      title: 'எழுத்துக் கூடை',
      prompt: 'விழும் சரியான எழுத்துகளைக் கூடையில் பிடிக்கவும்!',
      clue: 'கூடையில் எழுத்து பிடிக்கும் விளையாட்டு',
      clue_image: 'https://res.cloudinary.com/dyt5hqqzp/image/upload/v1772691653/agaram_media/images/game.png',
      correct_index: 0,
      options_json: JSON.stringify(['அ', 'ஆ', 'இ', 'ஈ']),
      success_praise: 'கூடையில் பிடித்தாச்சு! ⭐',
      stars_reward: 3,
      display_order: 4,
      is_active: 1,
    },
    {
      id: 'game_racing_1',
      game_type: 'racing',
      title: 'சொல் கார் பந்தயம்',
      prompt: 'ஒலியைக் கேட்டு காரை ஓட்டி சரியான எழுத்தை சேகரிக்கவும்!',
      clue: 'ஹைவே கார் பந்தய விளையாட்டு',
      clue_image: 'https://res.cloudinary.com/dyt5hqqzp/image/upload/v1772691653/agaram_media/images/game.png',
      correct_index: 0,
      options_json: JSON.stringify(['அ', 'ஆ', 'இ', 'ஈ']),
      success_praise: 'பந்தயத்தில் வெற்றி! 🚗',
      stars_reward: 3,
      display_order: 5,
      is_active: 1,
    },
    {
      id: 'game_puzzle_1',
      game_type: 'puzzle',
      title: 'சொல் புதிர்',
      prompt: 'எழுத்துகளை ஒழுங்குபடுத்தி சரியான சொல்லை உருவாக்கவும்!',
      clue: 'சொல் புதிர் பலகை விளையாட்டு',
      clue_image: 'https://res.cloudinary.com/dyt5hqqzp/image/upload/v1772691653/agaram_media/images/welcome.png',
      correct_index: 0,
      options_json: JSON.stringify(['அ', 'ம்மா', 'அம்மா']),
      success_praise: 'அற்புதம்! சொல் உருவானது! ⭐',
      stars_reward: 3,
      display_order: 6,
      is_active: 1,
    },
    {
      id: 'game_balloon_1',
      game_type: 'balloon',
      title: 'பலூன் வெடிப்பு',
      prompt: 'ஆ எழுத்துள்ள பலூனைத் தொட்டு வெடிக்க வைக்கவும்!',
      clue: 'பலூன் விளையாட்டு',
      clue_image: 'https://res.cloudinary.com/dyt5hqqzp/image/upload/v1772691653/agaram_media/images/welcome.png',
      correct_index: 1,
      options_json: JSON.stringify(['அ', 'ஆ', 'இ', 'ஈ']),
      success_praise: 'அருமை! பலூன் வெடித்தது! 🎈',
      stars_reward: 3,
      display_order: 7,
      is_active: 1,
    },
  ];

  console.log('Inserting/updating games into database...');
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

  const [rows] = await pool.query('SELECT id, game_type, title, display_order FROM games ORDER BY display_order');
  console.log(`✅ ${rows.length} Games now in database:`);
  console.table(rows);
  process.exit(0);
}

seedGames().catch((err) => {
  console.error('Failed to seed games:', err);
  process.exit(1);
});
