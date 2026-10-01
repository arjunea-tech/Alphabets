/**
 * AGARAM Tamil Audio Generator (ElevenLabs)
 * Generates and caches MP3 audio files for all 247 Tamil letters:
 * - 12 Uyir
 * - 18 Mei
 * - 1 Aytham
 * - 216 Uyirmei (programmatically computed)
 * - Essential vocabulary words & test items
 *
 * Usage:
 *   node generateTamilAudio.js --test  (Generates only 'அ', 'ஆ', 'இ')
 *   node generateTamilAudio.js         (Generates all missing audio files)
 */
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });
const elevenLabsService = require('../services/elevenLabsService');

const PROJECT_ROOT = path.resolve(__dirname, '../../../');
const AUDIO_BASE_DIR = fs.existsSync(path.join(PROJECT_ROOT, 'frontend/assets/audio/tamil'))
  ? path.join(PROJECT_ROOT, 'frontend/assets/audio/tamil')
  : path.join(PROJECT_ROOT, 'assets/audio/tamil');
const MANIFEST_FILE = path.join(AUDIO_BASE_DIR, 'audio_manifest.json');

// Ensure all target subdirectories exist
const SUBDIRS = ['uyir', 'mei', 'aytham', 'uyirmei', 'words', 'sentences', 'stories', 'lessons'];
for (const sub of SUBDIRS) {
  const dir = path.join(AUDIO_BASE_DIR, sub);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

// -------------------------------------------------------------
// 1. 12 UYIR (Vowels)
// -------------------------------------------------------------
const UYIR_LETTERS = [
  { letter: 'அ', slug: 'uyir_01_a', sound: 'அ', category: 'uyir' },
  { letter: 'ஆ', slug: 'uyir_02_aa', sound: 'ஆ', category: 'uyir' },
  { letter: 'இ', slug: 'uyir_03_i', sound: 'இ', category: 'uyir' },
  { letter: 'ஈ', slug: 'uyir_04_ee', sound: 'ஈ', category: 'uyir' },
  { letter: 'உ', slug: 'uyir_05_u', sound: 'உ', category: 'uyir' },
  { letter: 'ஊ', slug: 'uyir_06_oo', sound: 'ஊ', category: 'uyir' },
  { letter: 'எ', slug: 'uyir_07_e', sound: 'எ', category: 'uyir' },
  { letter: 'ஏ', slug: 'uyir_08_ae', sound: 'ஏ', category: 'uyir' },
  { letter: 'ஐ', slug: 'uyir_09_ai', sound: 'ஐ', category: 'uyir' },
  { letter: 'ஒ', slug: 'uyir_10_o', sound: 'ஒ', category: 'uyir' },
  { letter: 'ஓ', slug: 'uyir_11_oo_long', sound: 'ஓ', category: 'uyir' },
  { letter: 'ஔ', slug: 'uyir_12_au', sound: 'ஔ', category: 'uyir' },
];

// -------------------------------------------------------------
// 2. 18 MEI (Consonants)
// -------------------------------------------------------------
const MEI_LETTERS = [
  { letter: 'க்', slug: 'mei_01_ik', sound: 'க்', category: 'mei', baseKey: 'k' },
  { letter: 'ங்', slug: 'mei_02_ing', sound: 'ங்', category: 'mei', baseKey: 'ng' },
  { letter: 'ச்', slug: 'mei_03_ich', sound: 'ச்', category: 'mei', baseKey: 'c' },
  { letter: 'ஞ்', slug: 'mei_04_inj', sound: 'ஞ்', category: 'mei', baseKey: 'nj' },
  { letter: 'ட்', slug: 'mei_05_it', sound: 'ட்', category: 'mei', baseKey: 't' },
  { letter: 'ண்', slug: 'mei_06_inn', sound: 'ண்', category: 'mei', baseKey: 'nn' },
  { letter: 'த்', slug: 'mei_07_ith', sound: 'த்', category: 'mei', baseKey: 'th' },
  { letter: 'ந்', slug: 'mei_08_inth', sound: 'ந்', category: 'mei', baseKey: 'nth' },
  { letter: 'ப்', slug: 'mei_09_ip', sound: 'ப்', category: 'mei', baseKey: 'p' },
  { letter: 'ம்', slug: 'mei_10_im', sound: 'ம்', category: 'mei', baseKey: 'm' },
  { letter: 'ய்', slug: 'mei_11_iy', sound: 'ய்', category: 'mei', baseKey: 'y' },
  { letter: 'ர்', slug: 'mei_12_ir', sound: 'ர்', category: 'mei', baseKey: 'r' },
  { letter: 'ல்', slug: 'mei_13_il', sound: 'ல்', category: 'mei', baseKey: 'l' },
  { letter: 'வ்', slug: 'mei_14_iv', sound: 'வ்', category: 'mei', baseKey: 'v' },
  { letter: 'ழ்', slug: 'mei_15_izh', sound: 'ழ்', category: 'mei', baseKey: 'zh' },
  { letter: 'ள்', slug: 'mei_16_ill', sound: 'ள்', category: 'mei', baseKey: 'll' },
  { letter: 'ற்', slug: 'mei_17_irr', sound: 'ற்', category: 'mei', baseKey: 'rr' },
  { letter: 'ன்', slug: 'mei_18_in', sound: 'ன்', category: 'mei', baseKey: 'n' },
];

// -------------------------------------------------------------
// 3. 1 AYTHAM
// -------------------------------------------------------------
const AYTHAM_LETTER = { letter: 'ஃ', slug: 'aytham_01_ak', sound: 'அக்கு', category: 'aytham' };

// -------------------------------------------------------------
// 4. 216 UYIRMEI MATRIX (18 Mei × 12 Uyir)
// -------------------------------------------------------------
const UYIRMEI_SERIES = {
  'க்': ['க', 'கா', 'கி', 'கீ', 'கு', 'கூ', 'கெ', 'கே', 'கை', 'கொ', 'கோ', 'கௌ'],
  'ங்': ['ங', 'ஙா', 'ஙி', 'ஙீ', 'ஙு', 'ஙூ', 'ஙெ', 'ஙே', 'ஙை', 'ஙொ', 'ஙோ', 'ஙௌ'],
  'ச்': ['ச', 'சா', 'சி', 'சீ', 'சு', 'சூ', 'செ', 'சே', 'சை', 'சொ', 'சோ', 'சௌ'],
  'ஞ்': ['ஞ', 'ஞா', 'ஞி', 'ஞீ', 'ஞு', 'ஞூ', 'ஞெ', 'ஞே', 'ஞை', 'ஞொ', 'ஞோ', 'ஞௌ'],
  'ட்': ['ட', 'டா', 'டி', 'டீ', 'டு', 'டூ', 'டெ', 'டே', 'டை', 'டொ', 'டோ', 'டௌ'],
  'ண்': ['ண', 'ணா', 'ணி', 'ணீ', 'ணு', 'ணூ', 'ணெ', 'ணே', 'ணை', 'ணொ', 'ணோ', 'ணௌ'],
  'த்': ['த', 'தா', 'தி', 'தீ', 'து', 'தூ', 'தெ', 'தே', 'தை', 'தொ', 'தோ', 'தௌ'],
  'ந்': ['ந', 'நா', 'நி', 'நீ', 'நு', 'நூ', 'நெ', 'நே', 'நை', 'நொ', 'நோ', 'நௌ'],
  'ப்': ['ப', 'பா', 'பி', 'பீ', 'பு', 'பூ', 'பெ', 'பே', 'பை', 'பொ', 'போ', 'பௌ'],
  'ம்': ['ம', 'மா', 'மி', 'மீ', 'மு', 'மூ', 'மெ', 'மே', 'மை', 'மொ', 'மோ', 'மௌ'],
  'ய்': ['ய', 'யா', 'யி', 'யீ', 'யு', 'யூ', 'யெ', 'யே', 'யை', 'யொ', 'யோ', 'யௌ'],
  'ர்': ['ர', 'ரா', 'ரி', 'ரீ', 'ரு', 'ரூ', 'ரெ', 'ரே', 'ரை', 'ரொ', 'ரோ', 'ரௌ'],
  'ல்': ['ல', 'லா', 'லி', 'லீ', 'லு', 'லூ', 'லெ', 'லே', 'லை', 'லொ', 'லோ', 'லௌ'],
  'வ்': ['வ', 'வா', 'வி', 'வீ', 'வு', 'வூ', 'வெ', 'வே', 'வை', 'வொ', 'வோ', 'வௌ'],
  'ழ்': ['ழ', 'ழா', 'ழி', 'ழீ', 'ழு', 'ழூ', 'ழெ', 'ழே', 'ழை', 'ழொ', 'ழோ', 'ழௌ'],
  'ள்': ['ள', 'ளா', 'ளி', 'ளீ', 'ளு', 'ளூ', 'ளெ', 'ளே', 'ளை', 'ளொ', 'ளோ', 'ளௌ'],
  'ற்': ['ற', 'றா', 'றி', 'றீ', 'று', 'றூ', 'றெ', 'றே', 'றை', 'றொ', 'றோ', 'றௌ'],
  'ன்': ['ன', 'னா', 'னி', 'னீ', 'னு', 'னூ', 'னெ', 'னே', 'னை', 'னொ', 'னோ', 'னௌ'],
};

const VOWEL_SUFFIXES = ['a', 'aa', 'i', 'ee', 'u', 'oo', 'e', 'ae', 'ai', 'o', 'oo_long', 'au'];

function generateUyirmeiList() {
  const list = [];
  let count = 0;
  for (const mei of MEI_LETTERS) {
    const combinations = UYIRMEI_SERIES[mei.letter];
    if (!combinations || combinations.length !== 12) {
      throw new Error(`Incomplete combinations for mei: ${mei.letter}`);
    }
    for (let i = 0; i < 12; i++) {
      count++;
      const letter = combinations[i];
      const indexStr = String(count).padStart(3, '0');
      const suffix = VOWEL_SUFFIXES[i];
      const slug = `uyirmei_${indexStr}_${mei.baseKey}_${suffix}`;
      list.push({
        letter,
        slug,
        sound: letter,
        category: 'uyirmei',
      });
    }
  }
  return list;
}

// -------------------------------------------------------------
// 5. ESSENTIAL VOCABULARY WORDS
// -------------------------------------------------------------
const ESSENTIAL_WORDS = [
  { letter: 'அம்மா', slug: 'word_amma', sound: 'அம்மா', category: 'words' },
  { letter: 'ஆடு', slug: 'word_aadu', sound: 'ஆடு', category: 'words' },
  { letter: 'இலை', slug: 'word_ilai', sound: 'இலை', category: 'words' },
  { letter: 'ஈ', slug: 'word_ee', sound: 'ஈ', category: 'words' },
  { letter: 'உரல்', slug: 'word_ural', sound: 'உரல்', category: 'words' },
  { letter: 'ஊஞ்சல்', slug: 'word_oonjal', sound: 'ஊஞ்சல்', category: 'words' },
  { letter: 'எலி', slug: 'word_eli', sound: 'எலி', category: 'words' },
  { letter: 'ஏணி', slug: 'word_eani', sound: 'ஏணி', category: 'words' },
  { letter: 'ஐந்து', slug: 'word_ainthu', sound: 'ஐந்து', category: 'words' },
  { letter: 'ஒட்டகம்', slug: 'word_ottagam', sound: 'ஒட்டகம்', category: 'words' },
  { letter: 'ஓடம்', slug: 'word_oodam', sound: 'ஓடம்', category: 'words' },
  { letter: 'ஔவையார்', slug: 'word_auvaiyar', sound: 'ஔவையார்', category: 'words' },
  { letter: 'தமிழ்', slug: 'word_thamizh', sound: 'தமிழ்', category: 'words' },
  { letter: 'எஃகு', slug: 'word_ehgu', sound: 'எஃகு', category: 'words' },
  { letter: 'மரம்', slug: 'word_maram', sound: 'மரம்', category: 'words' },
  { letter: 'பட்டம்', slug: 'word_pattam', sound: 'பட்டம்', category: 'words' },
  { letter: 'கண்', slug: 'word_kann', sound: 'கண்', category: 'words' },
  { letter: 'பந்து', slug: 'word_panthu', sound: 'பந்து', category: 'words' },
  { letter: 'வணக்கம்', slug: 'word_vanakkam', sound: 'வணக்கம்', category: 'words' },
  { letter: 'வணக்கம். இது அகரம் தமிழ் குரல் சோதனை.', slug: 'sentence_greeting_test', sound: 'வணக்கம். இது அகரம் தமிழ் குரல் சோதனை.', category: 'sentences' },
  { letter: 'அ ஆ இ ஈ உ ஊ', slug: 'sentence_alphabet_test', sound: 'அ ஆ இ ஈ உ ஊ', category: 'sentences' },
];

// Helper delay to respect rate limits
const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function main() {
  const isTestMode = process.argv.includes('--test');

  console.log('====================================================');
  console.log('🌟 AGARAM TAMIL AUDIO GENERATOR (ElevenLabs)');
  console.log(`📁 Target Directory: ${AUDIO_BASE_DIR}`);
  console.log(`🎯 Mode: ${isTestMode ? '🧪 TEST MODE (First 3 Uyir letters: அ, ஆ, இ)' : '🚀 FULL GENERATION (All 247 Letters + Core Words)'}`);
  console.log('====================================================');

  const uyirmeiList = generateUyirmeiList();

  // Validate exactly 247 unique Tamil letters
  const allLetters = [...UYIR_LETTERS, ...MEI_LETTERS, AYTHAM_LETTER, ...uyirmeiList];
  const uniqueLetterChars = new Set(allLetters.map((item) => item.letter));

  console.log(`📊 Total Letter Set Statistics:`);
  console.log(`   - 12 Uyir: ${UYIR_LETTERS.length}`);
  console.log(`   - 18 Mei: ${MEI_LETTERS.length}`);
  console.log(`   - 1 Aytham: 1`);
  console.log(`   - 216 Uyirmei: ${uyirmeiList.length}`);
  console.log(`   - Total Letters: ${allLetters.length}`);
  console.log(`   - Exactly 247 Unique Letters Verified: ${uniqueLetterChars.size === 247 ? '✅ YES (247/247)' : '❌ NO (' + uniqueLetterChars.size + ')'}`);
  console.log('----------------------------------------------------');

  let targetList;
  if (isTestMode) {
    // Only 'அ', 'ஆ', 'இ'
    targetList = UYIR_LETTERS.slice(0, 3);
  } else {
    targetList = [...allLetters, ...ESSENTIAL_WORDS];
  }

  // Load existing manifest if available
  let manifest = {
    generatedAt: new Date().toISOString(),
    totalEntries: 0,
    audio: {},
  };
  if (fs.existsSync(MANIFEST_FILE)) {
    try {
      manifest = JSON.parse(fs.readFileSync(MANIFEST_FILE, 'utf8'));
      manifest.audio = manifest.audio || {};
    } catch (_) {}
  }

  let generatedCount = 0;
  let skippedCount = 0;
  let failedCount = 0;

  for (let i = 0; i < targetList.length; i++) {
    const item = targetList[i];
    const fileName = `${item.slug}.mp3`;
    const relativeAssetPath = `assets/audio/tamil/${item.category}/${fileName}`;
    const fullFilePath = path.join(AUDIO_BASE_DIR, item.category, fileName);

    const progress = `[${i + 1}/${targetList.length}]`;

    try {
      // Check if file already exists
      if (fs.existsSync(fullFilePath) && fs.statSync(fullFilePath).size > 100) {
        manifest.audio[item.letter] = relativeAssetPath;
        skippedCount++;
        if (isTestMode || i % 25 === 0 || i === targetList.length - 1) {
          console.log(`⏩ ${progress} Skipped (already exists): '${item.letter}' -> ${relativeAssetPath}`);
        }
        continue;
      }

      console.log(`🔊 ${progress} Generating: '${item.letter}' (${item.sound}) -> ${relativeAssetPath}...`);

      const result = await elevenLabsService.synthesizeToFile(item.sound, fullFilePath);

      manifest.audio[item.letter] = relativeAssetPath;
      generatedCount++;

      console.log(`   ✅ Saved (${(result.sizeBytes / 1024).toFixed(1)} KB)`);

      // Gentle pause to stay comfortably within rate limits
      await delay(400);
    } catch (err) {
      failedCount++;
      console.error(`   ❌ Failed to generate audio for '${item.letter}':`, err.message);
      // Wait longer on error before next attempt
      await delay(1500);
    }
  }

  // Write updated manifest
  manifest.lastUpdated = new Date().toISOString();
  manifest.totalEntries = Object.keys(manifest.audio).length;
  fs.writeFileSync(MANIFEST_FILE, JSON.stringify(manifest, null, 2), 'utf8');

  console.log('====================================================');
  console.log('🎉 AUDIO GENERATION SUMMARY');
  console.log(`   - Newly Generated : ${generatedCount}`);
  console.log(`   - Cached / Skipped: ${skippedCount}`);
  console.log(`   - Failed          : ${failedCount}`);
  console.log(`   - Total Manifest  : ${manifest.totalEntries} entries`);
  console.log(`   - Manifest file   : ${MANIFEST_FILE}`);
  console.log('====================================================');

  if (isTestMode) {
    console.log('🧪 Verifying test files:');
    for (const testItem of targetList) {
      const p = path.join(AUDIO_BASE_DIR, testItem.category, `${testItem.slug}.mp3`);
      if (fs.existsSync(p) && fs.statSync(p).size > 100) {
        console.log(`   ✅ Playable file: ${testItem.letter} (${testItem.slug}.mp3, ${fs.statSync(p).size} bytes)`);
      } else {
        console.log(`   ❌ Missing file: ${testItem.letter} (${testItem.slug}.mp3)`);
      }
    }
  }
}

main().catch((err) => {
  console.error('Fatal Generator Error:', err);
  process.exit(1);
});
