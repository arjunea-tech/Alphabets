/**
 * Seed game levels (missions / target letters & words) into the `games` table.
 *
 * This moves the content that used to be hardcoded inside the Flutter game
 * screens into the database, so the admin panel is the single source of truth.
 *
 * Safe to re-run: a game that already has levels is left untouched
 * (admin edits win). Pass --force to overwrite existing levels.
 *
 *   node src/scripts/seedGameLevels.js
 *   node src/scripts/seedGameLevels.js --force
 */
const { pool } = require('../config/db');
const GameModel = require('../models/gameModel');

const AZ = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
const VOWELS = ['A', 'E', 'I', 'O', 'U'];
const CONSONANTS = AZ.filter((l) => !VOWELS.includes(l));

const lvl = (title, prompt, targets, distractors = []) => ({ title, prompt, targets, distractors });

const GAMES = [
  {
    id: 'game_candy_1',
    game_type: 'candy',
    title: 'Alphabet Candy Match',
    prompt: 'Match 3 colorful letter candies in a row to burst them!',
    clue_image: 'assets/images/games/candy_match_cover.png',
    display_order: 1,
    levels: [
      lvl('Vowel Candies', 'Match 3 or more vowel candies to pop them!', ['A', 'B', 'C', 'D', 'E', 'F']),
      lvl('Consonant Candies', 'Match consonant candies to create tasty candy blasts!', ['G', 'H', 'I', 'J', 'K', 'L']),
      lvl('All Alphabets', 'Match letters from A to Z for higher scores!', ['M', 'N', 'O', 'P', 'Q', 'R']),
      lvl('Mixed Candies', 'A colorful mix of vowel and consonant candies!', ['A', 'B', 'F', 'G', 'E', 'H']),
      lvl('Speed Challenge (60s)', 'Score 2500 points before time runs out to win!', ['A', 'B', 'C', 'F', 'H', 'I']),
    ],
  },
  {
    id: 'game_runner_1',
    game_type: 'runner',
    title: 'Alphabet Runner',
    prompt: 'Run, jump, and collect English letters along the jungle trail!',
    clue_image: 'assets/images/games/runner_cover.png',
    display_order: 2,
    levels: [
      lvl('Sunny Meadow Run', 'Dash, jump, and collect English letters to cross the Finish Line!', AZ.slice(0, 11)),
    ],
  },
  {
    id: 'game_balloon_1',
    game_type: 'balloon',
    title: 'Balloon Word Pop',
    prompt: 'Tap and pop the floating balloons that have the target letter or word!',
    clue_image: 'assets/images/games/balloon_pop_cover.png',
    display_order: 3,
    levels: [
      lvl('VOWELS CHALLENGE', 'POP ONLY VOWEL LETTERS: A, E, I, O, U', VOWELS,
        ['B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'P', 'R', 'S', 'T']),
      lvl('LETTERS A TO F', 'POP LETTERS FROM A TO F: A, B, C, D, E, F', ['A', 'B', 'C', 'D', 'E', 'F'],
        ['M', 'N', 'P', 'Q', 'R', 'S', 'T', 'W', 'X', 'Y', 'Z']),
      lvl('ANIMAL EXPLORER', 'POP ANIMAL WORDS: CAT, DOG, FOX, COW, PIG', ['Cat', 'Dog', 'Fox', 'Cow', 'Pig', 'Bat'],
        ['Car', 'Pen', 'Cup', 'Hat', 'Sun', 'Bag', 'Bed', 'Box']),
      lvl('CONSONANTS CHALLENGE', 'POP CONSONANTS: B, D, G, M, P, S, T', ['B', 'D', 'G', 'M', 'P', 'S', 'T'], VOWELS),
      lvl('RAINBOW COLOR WORDS', 'POP COLOR WORDS: RED, BLUE, PINK, GOLD', ['Red', 'Blue', 'Pink', 'Gold', 'Cyan'],
        ['Run', 'Hop', 'Top', 'Key', 'Pot', 'Fan', 'Net', 'Pan']),
    ],
  },
  {
    id: 'game_flappy_1',
    game_type: 'flappy',
    title: 'Flappy Word',
    prompt: 'Flap your wings and fly through the correct cloud letter gates!',
    clue_image: 'assets/images/games/flappy_word_cover.png',
    display_order: 4,
    levels: [
      lvl('Vowel Gate', 'Fly to the VOWEL Letter:', ['E'], ['K']),
      lvl('Letter Order', 'Fly to the LETTER AFTER "B":', ['C'], ['D']),
      lvl('Animal Gate', 'Fly to the ANIMAL Word:', ['Cat'], ['Cup']),
      lvl('Vowel Gate 2', 'Fly to the VOWEL Letter:', ['O'], ['T']),
      lvl('Short Words', 'Fly to the 3-LETTER Word:', ['Sun'], ['Star']),
    ],
  },
  {
    id: 'game_ninja_1',
    game_type: 'ninja',
    title: 'Word Ninja',
    prompt: 'Slice the flying letter fruits with your katana sword!',
    clue_image: 'assets/images/games/word_ninja_cover.png',
    display_order: 5,
    levels: [
      lvl('VOWEL LETTERS', 'Slice only VOWEL letters (A, E, I, O, U)!', VOWELS,
        ['B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'M']),
      lvl('LETTERS A TO G', 'Slice only letters from A to G!', ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
        ['P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'Z']),
      lvl('ANIMAL WORDS', 'Slice only ANIMAL Words!', ['Lion', 'Cat', 'Dog', 'Bear', 'Fox', 'Duck'],
        ['Cup', 'Car', 'Pen', 'Hat', 'Sun', 'Box']),
      lvl('CONSONANT LETTERS', 'Slice only CONSONANT letters!', ['B', 'D', 'M', 'N', 'P', 'R', 'S', 'T', 'W'], VOWELS),
      lvl('FRUIT & FOOD WORDS', 'Slice only FOOD Words!', ['Apple', 'Mango', 'Bread', 'Cake', 'Egg', 'Milk'],
        ['Moon', 'Star', 'Bell', 'Desk', 'Road', 'Rock']),
    ],
  },
  {
    id: 'game_racing_1',
    game_type: 'racing',
    title: 'Car Racing',
    prompt: 'Steer your car and drive through the target letter!',
    clue_image: 'assets/images/games/car_racing_cover.png',
    display_order: 6,
    levels: [lvl('Alphabet Race', 'Drive through the target letter!', AZ)],
  },
  {
    id: 'game_fishing_1',
    game_type: 'fishing',
    title: 'Letter Fishing',
    prompt: 'Catch the swimming fish carrying the target letter!',
    clue_image: 'assets/images/games/fishing_cover.png',
    display_order: 7,
    levels: [lvl('Alphabet Pond', 'Catch the fish with the target letter!', AZ)],
  },
  {
    id: 'game_basket_1',
    game_type: 'basket',
    title: 'Letter Basket (Vowels)',
    prompt: 'Catch the falling vowel letters into your basket!',
    clue_image: 'assets/images/games/basket_vowels_cover.png',
    display_order: 8,
    levels: [lvl('Vowel Basket', 'Catch the target vowel!', VOWELS, CONSONANTS)],
  },
  {
    id: 'game_basket_2',
    game_type: 'basket',
    title: 'Letter Basket (Consonants)',
    prompt: 'Catch the falling consonant letters into your magical basket!',
    clue_image: 'assets/images/games/basket_consonants_cover.png',
    display_order: 9,
    levels: [lvl('Consonant Basket', 'Catch the target consonant!', CONSONANTS, VOWELS)],
  },
  {
    id: 'game_puzzle_1',
    game_type: 'puzzle',
    title: 'Word Puzzle',
    prompt: 'Tap the letters in order to spell the word!',
    clue_image: 'assets/images/welcome.png',
    display_order: 10,
    levels: [
      lvl('3-Letter Words', 'Spell the word!', ['CAT', 'DOG', 'SUN', 'HAT', 'CAR', 'FOX']),
      lvl('4-Letter Words', 'Spell the word!', ['BALL', 'FISH', 'BIRD', 'STAR', 'LION', 'TREE']),
      lvl('5-Letter Words', 'Spell the word!', ['APPLE', 'ZEBRA', 'TIGER', 'TRAIN']),
    ],
  },
];

async function run() {
  const force = process.argv.includes('--force');
  let created = 0;
  let updated = 0;
  let skipped = 0;

  for (const game of GAMES) {
    const existing = await GameModel.getById(game.id);
    if (!existing) {
      await GameModel.create({
        ...game,
        options: game.levels[0].targets,
        success_praise: 'Awesome! ⭐',
        stars_reward: 5,
        is_active: true,
      });
      created++;
      console.log(`➕ Created ${game.id} with ${game.levels.length} level(s)`);
    } else if (force || !existing.levels || existing.levels.length === 0) {
      await GameModel.update(game.id, { levels: game.levels });
      updated++;
      console.log(`✏️  Set ${game.levels.length} level(s) on ${game.id}`);
    } else {
      skipped++;
      console.log(`⏭️  ${game.id} already has ${existing.levels.length} admin level(s) — kept`);
    }
  }

  console.log(`\nDone. created=${created} updated=${updated} kept=${skipped}`);
}

run()
  .catch((err) => {
    console.error('❌ Seeding game levels failed:', err.message);
    process.exitCode = 1;
  })
  .finally(async () => {
    try {
      if (pool.end) await pool.end();
    } catch (_) {}
  });
