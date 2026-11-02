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

const ENGLISH_LETTERS = [
  { id: 'eng_a', letter: 'A', type: 'vowel', group_id: 'group_english_vowels', word: 'Apple', meaning: 'Sweet red fruit', phonetic: 'æp.əl', icon: '🍎', image: 'assets/images/alphabets/apple.png', exp: 'A is for Apple.' },
  { id: 'eng_b', letter: 'B', type: 'consonant', group_id: 'group_english_consonants', word: 'Ball', meaning: 'Round toy for games', phonetic: 'bɔːl', icon: '⚽', image: 'assets/images/alphabets/ball.png', exp: 'B is for Ball.' },
  { id: 'eng_c', letter: 'C', type: 'consonant', group_id: 'group_english_consonants', word: 'Camel', meaning: 'Desert animal', phonetic: 'kæm.əl', icon: '🐪', image: 'assets/images/alphabets/camel.png', exp: 'C is for Camel.' },
  { id: 'eng_d', letter: 'D', type: 'consonant', group_id: 'group_english_consonants', word: 'Dog', meaning: 'Friendly pet', phonetic: 'dɒɡ', icon: '🐶', image: 'assets/images/alphabets/dog.png', exp: 'D is for Dog.' },
  { id: 'eng_e', letter: 'E', type: 'vowel', group_id: 'group_english_vowels', word: 'Eye', meaning: 'Organ of sight', phonetic: 'aɪ', icon: '👁️', image: 'assets/images/alphabets/eye.png', exp: 'E is for Eye.' },
  { id: 'eng_f', letter: 'F', type: 'consonant', group_id: 'group_english_consonants', word: 'Fish', meaning: 'Water creature', phonetic: 'fɪʃ', icon: '🐟', image: 'assets/images/alphabets/fish.png', exp: 'F is for Fish.' },
  { id: 'eng_g', letter: 'G', type: 'consonant', group_id: 'group_english_consonants', word: 'Grapes', meaning: 'Bunch of sweet berries', phonetic: 'ɡreɪps', icon: '🍇', image: 'assets/images/alphabets/grapes.png', exp: 'G is for Grapes.' },
  { id: 'eng_h', letter: 'H', type: 'consonant', group_id: 'group_english_consonants', word: 'Hen', meaning: 'Bird that lays eggs', phonetic: 'hɛn', icon: '🐔', image: 'assets/images/alphabets/hen.png', exp: 'H is for Hen.' },
  { id: 'eng_i', letter: 'I', type: 'vowel', group_id: 'group_english_vowels', word: 'Ice Cream', meaning: 'Sweet frozen dessert', phonetic: 'aɪs kriːm', icon: '🍦', image: 'assets/images/alphabets/ice_cream.png', exp: 'I is for Ice Cream.' },
  { id: 'eng_j', letter: 'J', type: 'consonant', group_id: 'group_english_consonants', word: 'Jug', meaning: 'Water vessel', phonetic: 'dʒʌɡ', icon: '🏺', image: 'assets/images/alphabets/jug.png', exp: 'J is for Jug.' },
  { id: 'eng_k', letter: 'K', type: 'consonant', group_id: 'group_english_consonants', word: 'Kite', meaning: 'Flying toy in wind', phonetic: 'kaɪt', icon: '🪁', image: 'assets/images/alphabets/kite.png', exp: 'K is for Kite.' },
  { id: 'eng_l', letter: 'L', type: 'consonant', group_id: 'group_english_consonants', word: 'Leaf', meaning: 'Green part of tree', phonetic: 'liːf', icon: '🍃', image: 'assets/images/alphabets/leaf.png', exp: 'L is for Leaf.' },
  { id: 'eng_m', letter: 'M', type: 'consonant', group_id: 'group_english_consonants', word: 'Mat', meaning: 'Floor rug', phonetic: 'mæt', icon: '🧘', image: 'assets/images/alphabets/mat.png', exp: 'M is for Mat.' },
  { id: 'eng_n', letter: 'N', type: 'consonant', group_id: 'group_english_consonants', word: 'Number', meaning: 'Counting digits', phonetic: 'nʌm.bər', icon: '🔢', image: 'assets/images/alphabets/number.png', exp: 'N is for Number.' },
  { id: 'eng_o', letter: 'O', type: 'vowel', group_id: 'group_english_vowels', word: 'Orange', meaning: 'Citrus juicy fruit', phonetic: 'ɒr.ɪndʒ', icon: '🍊', image: 'assets/images/alphabets/orange.png', exp: 'O is for Orange.' },
  { id: 'eng_p', letter: 'P', type: 'consonant', group_id: 'group_english_consonants', word: 'Parrot', meaning: 'Colorful talking bird', phonetic: 'pær.ət', icon: '🦜', image: 'assets/images/alphabets/parrot.png', exp: 'P is for Parrot.' },
  { id: 'eng_q', letter: 'Q', type: 'consonant', group_id: 'group_english_consonants', word: 'Queen', meaning: 'Royal kingdom ruler', phonetic: 'kwiːn', icon: '👑', image: 'assets/images/alphabets/queen.png', exp: 'Q is for Queen.' },
  { id: 'eng_r', letter: 'R', type: 'consonant', group_id: 'group_english_consonants', word: 'Rabbit', meaning: 'Cute hopping animal', phonetic: 'ræb.ɪt', icon: '🐰', image: 'assets/images/alphabets/rabbit.png', exp: 'R is for Rabbit.' },
  { id: 'eng_s', letter: 'S', type: 'consonant', group_id: 'group_english_consonants', word: 'Ship', meaning: 'Large boat on sea', phonetic: 'ʃɪp', icon: '🚢', image: 'assets/images/alphabets/ship.png', exp: 'S is for Ship.' },
  { id: 'eng_t', letter: 'T', type: 'consonant', group_id: 'group_english_consonants', word: 'Tree', meaning: 'Tall leafy plant', phonetic: 'triː', icon: '🌳', image: 'assets/images/alphabets/tree.png', exp: 'T is for Tree.' },
  { id: 'eng_u', letter: 'U', type: 'vowel', group_id: 'group_english_vowels', word: 'Umbrella', meaning: 'Rain protector', phonetic: 'ʌmˈbrel.ə', icon: '☂️', image: 'assets/images/alphabets/umbrella.png', exp: 'U is for Umbrella.' },
  { id: 'eng_v', letter: 'V', type: 'consonant', group_id: 'group_english_consonants', word: 'Van', meaning: 'Vehicle for travel', phonetic: 'væn', icon: '🚐', image: 'assets/images/alphabets/van.png', exp: 'V is for Van.' },
  { id: 'eng_w', letter: 'W', type: 'consonant', group_id: 'group_english_consonants', word: 'Wheel', meaning: 'Round rolling ring', phonetic: 'wiːl', icon: '🛞', image: 'assets/images/alphabets/wheel.png', exp: 'W is for Wheel.' },
  { id: 'eng_x', letter: 'X', type: 'consonant', group_id: 'group_english_consonants', word: 'Xylophone', meaning: 'Musical instrument', phonetic: 'zaɪ.lə.fəʊn', icon: '🎼', image: 'assets/images/alphabets/xylophone.png', exp: 'X is for Xylophone.' },
  { id: 'eng_y', letter: 'Y', type: 'consonant', group_id: 'group_english_consonants', word: 'Yo-yo', meaning: 'Spinning string toy', phonetic: 'jəʊ.jəʊ', icon: '🪀', image: 'assets/images/alphabets/yoyo.png', exp: 'Y is for Yo-yo.' },
  { id: 'eng_z', letter: 'Z', type: 'consonant', group_id: 'group_english_consonants', word: 'Zebra', meaning: 'Striped wild horse', phonetic: 'zɛb.rə', icon: '🦓', image: 'assets/images/alphabets/zebra.png', exp: 'Z is for Zebra.' },
];

async function seedEnglish() {
  console.log(`Connecting to database '${DB_CONFIG.database}'...`);
  const conn = await mysql.createConnection(DB_CONFIG);

  try {
    // 1. Groups
    console.log('Seeding English Letter Groups...');
    await conn.query(`
      INSERT INTO letter_groups (id, name, display_title, letter_type, description, display_order)
      VALUES
        ('group_english_vowels', 'English Vowels', 'Vowels (A, E, I, O, U)', 'vowel', '5 English Vowel Letters', 1),
        ('group_english_consonants', 'English Consonants', 'Consonants (21 Letters)', 'consonant', '21 English Consonants', 2),
        ('group_english_all', 'All Alphabets', 'English Alphabets (A - Z)', 'english', 'Complete 26 English Alphabets', 3)
      ON DUPLICATE KEY UPDATE display_title = VALUES(display_title);
    `);

    // 2. Letters
    console.log('Seeding 26 English Alphabets (A to Z)...');
    for (let i = 0; i < ENGLISH_LETTERS.length; i++) {
      const item = ENGLISH_LETTERS[i];
      await conn.query(`
        INSERT INTO letters (id, letter, type, group_id, word, meaning, phonetic, icon_emoji, image_path, explanation, display_order)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          letter = VALUES(letter),
          type = VALUES(type),
          group_id = VALUES(group_id),
          word = VALUES(word),
          meaning = VALUES(meaning),
          phonetic = VALUES(phonetic),
          icon_emoji = VALUES(icon_emoji),
          image_path = VALUES(image_path),
          explanation = VALUES(explanation),
          display_order = VALUES(display_order);
      `, [item.id, item.letter, item.type, item.group_id, item.word, item.meaning, item.phonetic, item.icon, item.image, item.exp, i + 1]);
    }

    console.log('✅ Successfully seeded all 26 English letters into database!');
  } finally {
    await conn.end();
  }
}

if (require.main === module) {
  seedEnglish().catch(console.error);
}

module.exports = seedEnglish;

