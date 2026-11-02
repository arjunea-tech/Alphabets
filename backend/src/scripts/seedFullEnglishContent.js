/**
 * Full English Content Seeder
 * Removes all Tamil content and seeds 26 English Alphabets (A-Z),
 * English lessons, quizzes, reading stories, videos, and games.
 */
const mysql = require('mysql2/promise');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const DB_CONFIG = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT, 10) || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'root',
  database: process.env.DB_NAME || 'alphabets',
};

const ENGLISH_26_LETTERS = [
  { id: 'eng_a', letter: 'A', type: 'vowel', group_id: 'group_english_vowels', word: 'Apple', meaning: 'Sweet red fruit', phonetic: '/ˈæp.əl/', icon: '🍎', image: 'assets/images/alphabets/apple.png', exp: 'A is for Apple. Sweet and crunchy!' },
  { id: 'eng_b', letter: 'B', type: 'consonant', group_id: 'group_english_consonants', word: 'Ball', meaning: 'Round toy for games', phonetic: '/bɔːl/', icon: '⚽', image: 'assets/images/alphabets/ball.png', exp: 'B is for Ball. Bounce and play!' },
  { id: 'eng_c', letter: 'C', type: 'consonant', group_id: 'group_english_consonants', word: 'Camel', meaning: 'Desert animal', phonetic: '/ˈkæm.əl/', icon: '🐪', image: 'assets/images/alphabets/camel.png', exp: 'C is for Camel. Walking through the desert sand.' },
  { id: 'eng_d', letter: 'D', type: 'consonant', group_id: 'group_english_consonants', word: 'Dog', meaning: 'Loyal and friendly pet', phonetic: '/dɒɡ/', icon: '🐶', image: 'assets/images/alphabets/dog.png', exp: 'D is for Dog. Wagging its happy tail!' },
  { id: 'eng_e', letter: 'E', type: 'vowel', group_id: 'group_english_vowels', word: 'Eye', meaning: 'Organ of sight', phonetic: '/aɪ/', icon: '👁️', image: 'assets/images/alphabets/eye.png', exp: 'E is for Eye. We see the world with our eyes.' },
  { id: 'eng_f', letter: 'F', type: 'consonant', group_id: 'group_english_consonants', word: 'Fish', meaning: 'Water creature', phonetic: '/fɪʃ/', icon: '🐟', image: 'assets/images/alphabets/fish.png', exp: 'F is for Fish. Swimming smoothly in the sea.' },
  { id: 'eng_g', letter: 'G', type: 'consonant', group_id: 'group_english_consonants', word: 'Grapes', meaning: 'Juicy green or purple fruit', phonetic: '/ɡreɪps/', icon: '🍇', image: 'assets/images/alphabets/grapes.png', exp: 'G is for Grapes. Growing in tasty bunches.' },
  { id: 'eng_h', letter: 'H', type: 'consonant', group_id: 'group_english_consonants', word: 'Hen', meaning: 'Bird that lays eggs', phonetic: '/hɛn/', icon: '🐔', image: 'assets/images/alphabets/hen.png', exp: 'H is for Hen. Cluck, cluck, cluck!' },
  { id: 'eng_i', letter: 'I', type: 'vowel', group_id: 'group_english_vowels', word: 'Ice Cream', meaning: 'Sweet frozen dessert', phonetic: '/ˈaɪs ˌkriːm/', icon: '🍦', image: 'assets/images/alphabets/ice_cream.png', exp: 'I is for Ice Cream. Cool and delicious on a warm day!' },
  { id: 'eng_j', letter: 'J', type: 'consonant', group_id: 'group_english_consonants', word: 'Jug', meaning: 'Container for liquids', phonetic: '/dʒʌɡ/', icon: '🏺', image: 'assets/images/alphabets/jug.png', exp: 'J is for Jug. Pouring cool fresh water.' },
  { id: 'eng_k', letter: 'K', type: 'consonant', group_id: 'group_english_consonants', word: 'Kite', meaning: 'Toy flying high in the sky', phonetic: '/kaɪt/', icon: '🪁', image: 'assets/images/alphabets/kite.png', exp: 'K is for Kite. Soaring high in the windy sky!' },
  { id: 'eng_l', letter: 'L', type: 'consonant', group_id: 'group_english_consonants', word: 'Leaf', meaning: 'Green part of a plant', phonetic: '/liːf/', icon: '🍃', image: 'assets/images/alphabets/leaf.png', exp: 'L is for Leaf. Fluttering gently from the tall tree.' },
  { id: 'eng_m', letter: 'M', type: 'consonant', group_id: 'group_english_consonants', word: 'Mat', meaning: 'Floor rug', phonetic: '/mæt/', icon: '🧘', image: 'assets/images/alphabets/mat.png', exp: 'M is for Mat. Let us sit together on the mat.' },
  { id: 'eng_n', letter: 'N', type: 'consonant', group_id: 'group_english_consonants', word: 'Number', meaning: 'Counting digits', phonetic: '/ˈnʌm.bər/', icon: '🔢', image: 'assets/images/alphabets/number.png', exp: 'N is for Number. 1, 2, 3, let us count!' },
  { id: 'eng_o', letter: 'O', type: 'vowel', group_id: 'group_english_vowels', word: 'Orange', meaning: 'Round citrus fruit', phonetic: '/ˈɒr.ɪndʒ/', icon: '🍊', image: 'assets/images/alphabets/orange.png', exp: 'O is for Orange. Bright, round, and rich in Vitamin C.' },
  { id: 'eng_p', letter: 'P', type: 'consonant', group_id: 'group_english_consonants', word: 'Parrot', meaning: 'Colorful talking bird', phonetic: '/ˈpær.ət/', icon: '🦜', image: 'assets/images/alphabets/parrot.png', exp: 'P is for Parrot. Chirping with bright green feathers.' },
  { id: 'eng_q', letter: 'Q', type: 'consonant', group_id: 'group_english_consonants', word: 'Queen', meaning: 'Royal kingdom ruler', phonetic: '/kwiːn/', icon: '👑', image: 'assets/images/alphabets/queen.png', exp: 'Q is for Queen. Wearing a sparkling crown.' },
  { id: 'eng_r', letter: 'R', type: 'consonant', group_id: 'group_english_consonants', word: 'Rabbit', meaning: 'Cute hopping animal', phonetic: '/ˈræb.ɪt/', icon: '🐰', image: 'assets/images/alphabets/rabbit.png', exp: 'R is for Rabbit. Hop, hop, hop across the meadow!' },
  { id: 'eng_s', letter: 'S', type: 'consonant', group_id: 'group_english_consonants', word: 'Ship', meaning: 'Large boat on sea', phonetic: '/ʃɪp/', icon: '🚢', image: 'assets/images/alphabets/ship.png', exp: 'S is for Ship. Sailing across the vast blue ocean.' },
  { id: 'eng_t', letter: 'T', type: 'consonant', group_id: 'group_english_consonants', word: 'Tree', meaning: 'Tall woody plant with leaves', phonetic: '/triː/', icon: '🌳', image: 'assets/images/alphabets/tree.png', exp: 'T is for Tree. Giving us fresh air and cooling shade.' },
  { id: 'eng_u', letter: 'U', type: 'vowel', group_id: 'group_english_vowels', word: 'Umbrella', meaning: 'Protection from rain', phonetic: '/ʌmˈbrel.ə/', icon: '☂️', image: 'assets/images/alphabets/umbrella.png', exp: 'U is for Umbrella. Opening up when the rain pours down.' },
  { id: 'eng_v', letter: 'V', type: 'consonant', group_id: 'group_english_consonants', word: 'Van', meaning: 'Vehicle for transport', phonetic: '/væn/', icon: '🚐', image: 'assets/images/alphabets/van.png', exp: 'V is for Van. Beep beep, let us ride together!' },
  { id: 'eng_w', letter: 'W', type: 'consonant', group_id: 'group_english_consonants', word: 'Wheel', meaning: 'Round rolling ring', phonetic: '/wiːl/', icon: '🛞', image: 'assets/images/alphabets/wheel.png', exp: 'W is for Wheel. The wheels on the bus go round and round.' },
  { id: 'eng_x', letter: 'X', type: 'consonant', group_id: 'group_english_consonants', word: 'Xylophone', meaning: 'Colorful musical instrument', phonetic: '/ˈzaɪ.lə.fəʊn/', icon: '🎼', image: 'assets/images/alphabets/xylophone.png', exp: 'X is for Xylophone. Tap the colorful bars for music!' },
  { id: 'eng_y', letter: 'Y', type: 'consonant', group_id: 'group_english_consonants', word: 'Yo-yo', meaning: 'Spinning string toy', phonetic: '/ˈjəʊ.jəʊ/', icon: '🪀', image: 'assets/images/alphabets/yoyo.png', exp: 'Y is for Yo-yo. Roll it down and bring it right back up!' },
  { id: 'eng_z', letter: 'Z', type: 'consonant', group_id: 'group_english_consonants', word: 'Zebra', meaning: 'Striped wild animal', phonetic: '/ˈzeb.rə/', icon: '🦓', image: 'assets/images/alphabets/zebra.png', exp: 'Z is for Zebra. Running free with black and white stripes.' },
];

async function seedFullEnglish() {
  console.log('===========================================================');
  console.log(`🚀 Connecting to MySQL Database '${DB_CONFIG.database}'...`);
  console.log('===========================================================');

  const conn = await mysql.createConnection(DB_CONFIG);

  try {
    await conn.query('SET FOREIGN_KEY_CHECKS = 0;');

    // 1. Clean out all Tamil content from all tables
    console.log('🧹 Purging all old Tamil content...');
    await conn.query('DELETE FROM letters;');
    await conn.query('DELETE FROM letter_groups;');
    await conn.query('DELETE FROM lessons;');
    await conn.query('DELETE FROM reading_story_pages;');
    await conn.query('DELETE FROM reading_stories;');
    await conn.query('DELETE FROM quiz_options;');
    await conn.query('DELETE FROM quiz_questions;');
    await conn.query('DELETE FROM quizzes;');
    await conn.query('DELETE FROM games;');
    await conn.query('DELETE FROM videos;');
    await conn.query("UPDATE users SET child_name = 'Kid Learner' WHERE child_name = 'குழந்தை' OR child_name = '';");

    // 2. Letter Groups
    console.log('📁 Seeding English Letter Groups...');
    await conn.query(`
      INSERT INTO letter_groups (id, name, display_title, letter_type, description, display_order)
      VALUES
        ('group_english_all', 'All Alphabets', 'English Alphabets (A - Z)', 'english', 'Complete 26 English Alphabets', 1),
        ('group_english_vowels', 'English Vowels', 'Vowels (A, E, I, O, U)', 'vowel', '5 English Vowel Letters', 2),
        ('group_english_consonants', 'English Consonants', 'Consonants (21 Letters)', 'consonant', '21 English Consonants', 3);
    `);

    // 3. Letters (26 Letters)
    console.log('🔤 Seeding exactly 26 English Alphabet letters (A to Z)...');
    for (let i = 0; i < ENGLISH_26_LETTERS.length; i++) {
      const item = ENGLISH_26_LETTERS[i];
      await conn.query(`
        INSERT INTO letters (id, letter, type, group_id, word, meaning, phonetic, icon_emoji, image_path, explanation, display_order, is_active)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, TRUE);
      `, [item.id, item.letter, item.type, item.group_id, item.word, item.meaning, item.phonetic, item.icon, item.image, item.exp, i + 1]);
    }

    // 4. Lessons
    console.log('📖 Seeding English Lessons...');
    await conn.query(`
      INSERT INTO lessons (id, category_key, title, subtitle, count_text, button_text, icon_emoji, gradient_colors, route_name, display_order, is_active)
      VALUES
        ('lesson_alphabets', 'alphabets', 'English Alphabets', 'Learn 26 Letters from A to Z with Fun', '26 Letters', 'Start Learning', '🔤', '["#4E65FF", "#92EFFD"]', '/alphabets', 1, TRUE),
        ('lesson_vowels', 'vowels', 'Vowels', 'A, E, I, O, U - The Foundation of English Words', '5 Vowels', 'Learn Vowels', '🍎', '["#FF6B8B", "#FF8E53"]', '/vowels', 2, TRUE),
        ('lesson_consonants', 'consonants', 'Consonants', '21 Consonant Letters with Examples & Sounds', '21 Consonants', 'Learn Consonants', '🎡', '["#11998E", "#38EF7D"]', '/consonants', 3, TRUE),
        ('lesson_reading', 'reading', 'Reading Stories', 'Fun illustrated short stories for beginners', 'Story Books', 'Read Now', '📚', '["#FF8008", "#FFC837"]', '/reading', 4, TRUE);
    `);

    // 5. Reading Stories
    console.log('📚 Seeding English Reading Stories...');
    await conn.query(`
      INSERT INTO reading_stories (id, title, subtitle, cover_emoji, cover_image, moral, display_order, is_published)
      VALUES
        ('story_hare_tortoise', 'The Hare and the Tortoise', 'A classic fable of speed and patience', '🐰🐢', 'assets/images/story_friends.jpg', 'Slow and steady wins the race!', 1, TRUE),
        ('story_lion_mouse', 'The Lion and the Mouse', 'A tiny act of kindness can save a life', '🦁🐭', 'assets/images/story_victory.jpg', 'Even the smallest friend can be of great help!', 2, TRUE);
    `);

    // Reading Story Pages
    await conn.query(`
      INSERT INTO reading_story_pages (story_id, page_number, text, emoji_illustration, character_name, image_path, interactive_words)
      VALUES
        ('story_hare_tortoise', 1, 'Once upon a time in a sunny forest, a Hare and a Tortoise lived as neighbors.', '🌲🐰 🐢🌿', 'Forest Friends', 'assets/images/story_forest.jpg', '[{"word":"forest","displayLabel":"Forest","emoji":"🌲","meaning":"A place with many green trees"},{"word":"Hare","displayLabel":"Hare","emoji":"🐰","meaning":"A swift rabbit"},{"word":"Tortoise","displayLabel":"Tortoise","emoji":"🐢","meaning":"A gentle friend who moves steadily"}]'),
        ('story_hare_tortoise', 2, 'The Hare loved to boast: "I am the fastest animal in the whole forest!" The Tortoise just smiled.', '🐰💨 🐢🐾', 'The Boastful Hare', 'assets/images/story_friends.jpg', NULL),
        ('story_hare_tortoise', 3, 'They decided to hold a great running race to the tall oak tree!', '🏁🐰💨 ... 🐢', 'The Great Race', 'assets/images/story_race.jpg', NULL),
        ('story_hare_tortoise', 4, 'The Hare ran super fast, looked back, and thought: "I have plenty of time. Let me take a quick nap!"', '🌳😴🐰💤  🐢🐾', 'Sleeping Hare', 'assets/images/story_sleeping_rabbit.jpg', NULL),
        ('story_hare_tortoise', 5, 'The Tortoise never stopped. Step by step, walking forward with determination.', '🎉🏆🐢✨ 😲🐰', 'Steady Walking', 'assets/images/story_victory.jpg', NULL),
        ('story_hare_tortoise', 6, 'The Tortoise crossed the finish line first! Slow and steady wins the race!', '🌟🤝🐰🐢💖', 'Victory & Moral', 'assets/images/story_friends.jpg', NULL);
    `);

    // 6. Quizzes
    console.log('❓ Seeding English Quizzes...');
    await conn.query(`
      INSERT INTO quizzes (id, title, subtitle, icon_emoji, category, question_count, pass_marks, stars_reward, is_active, display_order)
      VALUES
        ('quiz_alphabet_basics', 'Alphabet Basics Quiz', 'Test your knowledge on letters A through Z', '🔤', 'alphabets', 5, 3, 5, TRUE, 1),
        ('quiz_vowels_fun', 'Vowels Challenge', 'Identify the 5 Vowels: A, E, I, O, U', '🍎', 'vowels', 3, 2, 5, TRUE, 2);
    `);

    // Questions
    await conn.query(`
      INSERT INTO quiz_questions (id, quiz_id, question_text, visual_hint, explanation, marks, display_order, is_active)
      VALUES
        ('q_alpha_1', 'quiz_alphabet_basics', 'Which letter comes immediately after letter "A"?', '🔤', 'B comes right after A.', 1, 1, TRUE),
        ('q_alpha_2', 'quiz_alphabet_basics', 'What is the starting letter of the word "Apple"?', '🍎', 'Apple starts with the letter A.', 1, 2, TRUE),
        ('q_alpha_3', 'quiz_alphabet_basics', 'Which of the following letters is a VOWEL?', '⭐', 'E is one of the five vowels (A, E, I, O, U).', 1, 3, TRUE),
        ('q_alpha_4', 'quiz_alphabet_basics', 'What is the last letter of the English Alphabet?', '🏁', 'Z is the 26th and final letter of the alphabet.', 1, 4, TRUE),
        ('q_alpha_5', 'quiz_alphabet_basics', 'How many letters are in the English Alphabet?', '🔢', 'There are exactly 26 letters in the English Alphabet.', 1, 5, TRUE),
        ('q_vowel_1', 'quiz_vowels_fun', 'Which letter is NOT a vowel?', '❓', 'B is a consonant, not a vowel.', 1, 1, TRUE),
        ('q_vowel_2', 'quiz_vowels_fun', 'Which word starts with the vowel letter "O"?', '🍊', 'Orange starts with the vowel O.', 1, 2, TRUE),
        ('q_vowel_3', 'quiz_vowels_fun', 'How many vowels are in the English language?', '🖐️', 'There are 5 vowels: A, E, I, O, and U.', 1, 3, TRUE);
    `);

    // Options
    await conn.query(`
      INSERT INTO quiz_options (question_id, option_text, is_correct, display_order)
      VALUES
        ('q_alpha_1', 'B', TRUE, 1),
        ('q_alpha_1', 'C', FALSE, 2),
        ('q_alpha_1', 'D', FALSE, 3),
        ('q_alpha_1', 'Z', FALSE, 4),

        ('q_alpha_2', 'A', TRUE, 1),
        ('q_alpha_2', 'P', FALSE, 2),
        ('q_alpha_2', 'L', FALSE, 3),
        ('q_alpha_2', 'E', FALSE, 4),

        ('q_alpha_3', 'E', TRUE, 1),
        ('q_alpha_3', 'B', FALSE, 2),
        ('q_alpha_3', 'K', FALSE, 3),
        ('q_alpha_3', 'M', FALSE, 4),

        ('q_alpha_4', 'Z', TRUE, 1),
        ('q_alpha_4', 'X', FALSE, 2),
        ('q_alpha_4', 'Y', FALSE, 3),
        ('q_alpha_4', 'W', FALSE, 4),

        ('q_alpha_5', '26', TRUE, 1),
        ('q_alpha_5', '20', FALSE, 2),
        ('q_alpha_5', '24', FALSE, 3),
        ('q_alpha_5', '30', FALSE, 4),

        ('q_vowel_1', 'B', TRUE, 1),
        ('q_vowel_1', 'A', FALSE, 2),
        ('q_vowel_1', 'E', FALSE, 3),
        ('q_vowel_1', 'I', FALSE, 4),

        ('q_vowel_2', 'Orange', TRUE, 1),
        ('q_vowel_2', 'Banana', FALSE, 2),
        ('q_vowel_2', 'Mango', FALSE, 3),
        ('q_vowel_2', 'Grape', FALSE, 4),

        ('q_vowel_3', '5', TRUE, 1),
        ('q_vowel_3', '3', FALSE, 2),
        ('q_vowel_3', '7', FALSE, 3),
        ('q_vowel_3', '10', FALSE, 4);
    `);

    // 7. Games
    console.log('🎮 Seeding English Educational Games...');
    await conn.query(`
      INSERT INTO games (id, game_type, title, prompt, clue, clue_image, correct_index, options_json, success_praise, stars_reward, is_active, display_order)
      VALUES
        ('game_runner_1', 'runner', 'Alphabet Runner (2D Runner)', 'Run and jump to collect the correct letters!', 'Collect letter A', 'assets/images/welcome.png', 0, '["A", "B", "C", "D"]', 'Awesome! Goal reached! 🏃⭐', 3, TRUE, 1),
        ('game_candy_1', 'candy', 'Alphabet Candy Match (Match-3)', 'Match 3 colorful letter candies together!', 'Match 3 Letter Candies', 'assets/images/welcome.png', 0, '["A", "B", "C", "D"]', 'Candy burst! Super! 🍬✨', 3, TRUE, 2),
        ('game_racing_1', 'racing', 'Alphabet Car Racing', 'Steer your car and drive through the correct letter!', 'Car Racing - Letter A', 'assets/images/welcome.png', 0, '["A", "B", "C", "D"]', 'Speed champion! Great driving! 🚗🏁', 3, TRUE, 3),
        ('game_fishing_1', 'fishing', 'Letter Fishing', 'Catch the swimming fish with the letter B!', 'Letter Fishing', 'assets/images/welcome.png', 1, '["A", "B", "C", "D"]', 'You caught the fish! Splendid! 🎣🐟', 3, TRUE, 4),
        ('game_basket_1', 'basket', 'Letter Basket', 'Catch the falling letter C into your basket!', 'Basket Game', 'assets/images/welcome.png', 2, '["A", "B", "C", "D"]', 'Caught right in the basket! 🧺🍎', 3, TRUE, 5),
        ('game_puzzle_1', 'puzzle', 'Word Puzzle', 'Touch the starting letter of the word Apple!', 'A - pple', 'assets/images/welcome.png', 0, '["A", "B", "C", "D"]', 'Brilliant! A is for Apple! ⭐', 3, TRUE, 6),
        ('game_balloon_1', 'balloon', 'Balloon Pop', 'Pop the balloon that has the letter D!', 'Dog', 'assets/images/welcome.png', 3, '["A", "B", "C", "D"]', 'POP! Wonderful job! 🎈', 3, TRUE, 7);
    `);

    // 8. Videos
    console.log('🎬 Seeding English Educational Videos...');
    await conn.query(`
      INSERT INTO videos (id, title, description, category, duration, thumbnail_emoji, video_url, display_order, is_published)
      VALUES
        ('vid_abc_song', 'ABC Phonics Song (A to Z)', 'Sing along with the 26 English letters and phonics sounds', 'Alphabet Song', '03:15', '🎵', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4', 1, TRUE),
        ('vid_vowels_song', 'The Five Vowels (A, E, I, O, U)', 'Learn all about English vowels with upbeat melodies', 'Phonics & Rhymes', '02:45', '🍎', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4', 2, TRUE),
        ('vid_phonics_fun', 'Letter Sounds and Words for Kids', 'Phonics practice for children with cartoon animations', 'Stories & Phonics', '04:10', '🎬', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4', 3, TRUE);
    `);

    await conn.query('SET FOREIGN_KEY_CHECKS = 1;');

    const [letterCount] = await conn.query('SELECT COUNT(*) as count FROM letters');
    console.log('===========================================================');
    console.log(`✅ Success! Database now has exactly ${letterCount[0].count} English letters.`);
    console.log('🌟 All Tamil content has been removed completely.');
    console.log('===========================================================');
  } finally {
    await conn.end();
  }
}

if (require.main === module) {
  seedFullEnglish().catch(console.error);
}

module.exports = seedFullEnglish;

