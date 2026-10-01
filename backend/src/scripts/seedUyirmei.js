/**
 * AGARAM - Seed Uyirmei Letters Script
 * Populates all 18 letter_groups and 216 Uyirmei letters into MySQL
 */
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });
const { pool } = require('../config/db');

const meiGroups = [
  { mei: 'க்', slug: 'ka', name: 'Ka Varisai', title: 'க வரிசை (12)', desc: 'க் + உயிர் எழுத்துகள்', order: 4 },
  { mei: 'ங்', slug: 'nga', name: 'Nga Varisai', title: 'ங வரிசை (12)', desc: 'ங் + உயிர் எழுத்துகள்', order: 5 },
  { mei: 'ச்', slug: 'sa', name: 'Sa Varisai', title: 'ச வரிசை (12)', desc: 'ச் + உயிர் எழுத்துகள்', order: 6 },
  { mei: 'ஞ்', slug: 'nya', name: 'Nya Varisai', title: 'ஞ வரிசை (12)', desc: 'ஞ் + உயிர் எழுத்துகள்', order: 7 },
  { mei: 'ட்', slug: 'ta', name: 'Ta Varisai', title: 'ட வரிசை (12)', desc: 'ட் + உயிர் எழுத்துகள்', order: 8 },
  { mei: 'ண்', slug: 'nna', name: 'Nna Varisai', title: 'ண வரிசை (12)', desc: 'ண் + உயிர் எழுத்துகள்', order: 9 },
  { mei: 'த்', slug: 'tha', name: 'Tha Varisai', title: 'த வரிசை (12)', desc: 'த் + உயிர் எழுத்துகள்', order: 10 },
  { mei: 'ந்', slug: 'na', name: 'Na Varisai', title: 'ந வரிசை (12)', desc: 'ந் + உயிர் எழுத்துகள்', order: 11 },
  { mei: 'ப்', slug: 'pa', name: 'Pa Varisai', title: 'ப வரிசை (12)', desc: 'ப் + உயிர் எழுத்துகள்', order: 12 },
  { mei: 'ம்', slug: 'ma', name: 'Ma Varisai', title: 'ம வரிசை (12)', desc: 'ம் + உயிர் எழுத்துகள்', order: 13 },
  { mei: 'ய்', slug: 'ya', name: 'Ya Varisai', title: 'ய வரிசை (12)', desc: 'ய் + உயிர் எழுத்துகள்', order: 14 },
  { mei: 'ர்', slug: 'ra', name: 'Ra Varisai', title: 'ர வரிசை (12)', desc: 'ர் + உயிர் எழுத்துகள்', order: 15 },
  { mei: 'ல்', slug: 'la', name: 'La Varisai', title: 'ல வரிசை (12)', desc: 'ல் + உயிர் எழுத்துகள்', order: 16 },
  { mei: 'வ்', slug: 'va', name: 'Va Varisai', title: 'வ வரிசை (12)', desc: 'வ் + உயிர் எழுத்துகள்', order: 17 },
  { mei: 'ழ்', slug: 'zha', name: 'Zha Varisai', title: 'ழ வரிசை (12)', desc: 'ழ் + உயிர் எழுத்துகள்', order: 18 },
  { mei: 'ள்', slug: 'lla', name: 'Lla Varisai', title: 'ள வரிசை (12)', desc: 'ள் + உயிர் எழுத்துகள்', order: 19 },
  { mei: 'ற்', slug: 'rra', name: 'Rra Varisai', title: 'ற வரிசை (12)', desc: 'ற் + உயிர் எழுத்துகள்', order: 20 },
  { mei: 'ன்', slug: 'nna2', name: 'Nna2 Varisai', title: 'ன வரிசை (12)', desc: 'ன் + உயிர் எழுத்துகள்', order: 21 },
];

const uyirVowels = ['அ', 'ஆ', 'இ', 'ஈ', 'உ', 'ஊ', 'எ', 'ஏ', 'ஐ', 'ஒ', 'ஓ', 'ஔ'];

const uyirmeiMatrix = {
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

const sampleWords = {
  'க': 'கண் 👁️',
  'கா': 'காக்கை 🦅',
  'கி': 'கிளி 🦜',
  'கீ': 'கீரை 🥬',
  'கு': 'குடை ☂️',
  'கூ': 'கூடு 🪺',
  'கெ': 'கெண்டை 🐟',
  'கே': 'கேடயம் 🛡️',
  'கை': 'கை ✋',
  'கொ': 'கொக்கு 🦩',
  'கோ': 'கோழி 🐔',
  'கௌ': 'கௌதாரி 🐦',
  'ச': 'சட்டை 👕',
  'சா': 'சாவி 🗝️',
  'சி': 'சிங்கம் 🦁',
  'சீ': 'சீப்பு 🪮',
  'சு': 'சுண்டல் 🍲',
  'சூ': 'சூரியன் ☀️',
  'செ': 'செருப்பு 🩴',
  'சே': 'சேவல் 🐓',
  'சை': 'சைக்கிள் 🚲',
  'சொ': 'சொட்டு நீர் 💧',
  'சோ': 'சோளம் 🌽',
  'சௌ': 'சௌகரியம் ✨',
  'ட': 'டமாரம் 🥁',
  'டா': 'டாடா 👋',
  'டி': 'டிபன் 🍱',
  'டீ': 'டீச்சர் 👩‍🏫',
  'த': 'தவளை 🐸',
  'தா': 'தாமரை 🪷',
  'தி': 'திமிங்கலம் 🐋',
  'தீ': 'தீபம் 🪔',
  'து': 'துப்பாக்கி 🔫',
  'தூ': 'தூண்டில் 🎣',
  'தெ': 'தென்னை 🌴',
  'தே': 'தேனீ 🐝',
  'தை': 'தையல் 🪡',
  'தொ': 'தொப்பி 🧢',
  'தோ': 'தோசை 🥞',
  'தௌ': 'தௌலத் 💎',
  'ந': 'நரி 🦊',
  'நா': 'நாய் 🐕',
  'நி': 'நிலா 🌙',
  'நீ': 'நீச்சல் 🏊',
  'நு': 'நுங்கு 🥥',
  'நூ': 'நூல் 🧵',
  'நெ': 'நெல் 🌾',
  'நே': 'நேரம் ⏰',
  'நை': 'நைந்து ✨',
  'நொ': 'நொண்டி 🤾',
  'நோ': 'நோட்டு 📓',
  'ப': 'பந்து ⚽',
  'பா': 'பால் 🥛',
  'பி': 'பிள்ளை 👶',
  'பீ': 'பீர்க்கு 🥒',
  'பு': 'புலி 🐯',
  'பூ': 'பூனை 🐱',
  'பெ': 'பென்சில் ✏️',
  'பே': 'பேருந்து 🚌',
  'பை': 'பை 👜',
  'பொ': 'பொம்மை 🧸',
  'போ': 'போர்வ 🛌',
  'பௌ': 'பௌர்ணமி 🌕',
  'ம': 'மயில் 🦚',
  'மா': 'மாம்பழம் 🥭',
  'மி': 'மிளகாய் 🌶️',
  'மீ': 'மீன் 🐟',
  'மு': 'முயல் 🐰',
  'மூ': 'மூக்கு 👃',
  'மெ': 'மெழுகுவர்த்தி 🕯️',
  'மே': 'மேகம் ☁️',
  'மை': 'மை 🖋️',
  'மொ': 'மொட்டு 🌷',
  'மோ': 'மோர் 🥛',
  'மௌ': 'மௌனம் 🤫',
  'வ': 'வண்டு 🪲',
  'வா': 'வாத்து 🦆',
  'வி': 'வில் 🏹',
  'வீ': 'வீடு 🏠',
};

const sampleImages = {
  'க': 'assets/images/eye.jpg',
  'ப': 'assets/images/ball.jpg',
  'மீ': 'assets/images/fish.jpg',
  'கோ': 'assets/images/hen.jpg',
};

async function seedUyirmei() {
  console.log('====================================================');
  console.log('🌱 Starting Seeding: 18 Letter Groups & 216 Uyirmei Letters');
  console.log('====================================================');

  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    // 1. Seed 18 letter groups
    console.log('📁 Inserting/Updating 18 Uyirmei Letter Groups...');
    for (const g of meiGroups) {
      const groupId = `group_uyirmei_${g.slug}`;
      await connection.query(
        `INSERT INTO letter_groups (id, name, display_title, letter_type, description, display_order)
         VALUES (?, ?, ?, 'uyirmei', ?, ?)
         ON DUPLICATE KEY UPDATE 
           name = VALUES(name),
           display_title = VALUES(display_title),
           description = VALUES(description),
           display_order = VALUES(display_order)`,
        [groupId, g.name, g.title, g.desc, g.order]
      );
    }
    console.log('✅ 18 Uyirmei letter groups verified.');

    // 2. Seed 216 letters
    console.log('🔤 Inserting/Updating 216 Uyirmei Letters...');
    let orderCounter = 1;

    for (const g of meiGroups) {
      const mei = g.mei;
      const groupId = `group_uyirmei_${g.slug}`;
      const letters = uyirmeiMatrix[mei];

      for (let i = 0; i < letters.length; i++) {
        const letter = letters[i];
        const uyir = uyirVowels[i];
        const letterId = `uyirmei_${mei}_${i}`;
        const word = sampleWords[letter] || `${mei} + ${uyir} = ${letter}`;
        const meaning = `${mei} + ${uyir} = ${letter}`;
        const phonetic = `${mei} + ${uyir}`;
        const iconEmoji = '✨';
        const imagePath = sampleImages[letter] || null;
        const explanation = `மெய் எழுத்து (${mei}) உடன் உயிர் எழுத்து (${uyir}) இணையும் போது உயிர்மெய் எழுத்து "${letter}" உருவாகிறது.`;

        await connection.query(
          `INSERT INTO letters 
            (id, letter, type, group_id, word, meaning, phonetic, icon_emoji, 
             image_path, audio_path, video_url, explanation, mei_base, uyir_base, display_order, is_active)
           VALUES (?, ?, 'uyirmei', ?, ?, ?, ?, ?, ?, NULL, NULL, ?, ?, ?, ?, TRUE)
           ON DUPLICATE KEY UPDATE 
             letter = VALUES(letter),
             type = 'uyirmei',
             group_id = VALUES(group_id),
             word = IF(letters.image_path IS NOT NULL AND letters.word != '', letters.word, VALUES(word)),
             meaning = VALUES(meaning),
             phonetic = VALUES(phonetic),
             explanation = VALUES(explanation),
             mei_base = VALUES(mei_base),
             uyir_base = VALUES(uyir_base),
             display_order = VALUES(display_order),
             is_active = TRUE`,
          [
            letterId,
            letter,
            groupId,
            word,
            meaning,
            phonetic,
            iconEmoji,
            imagePath,
            explanation,
            mei,
            uyir,
            orderCounter,
          ]
        );

        orderCounter++;
      }
    }

    await connection.commit();
    console.log(`✅ Successfully seeded all ${orderCounter - 1} Uyirmei letters into MySQL!`);

    // Verify counts
    const [groupCount] = await pool.query("SELECT COUNT(*) as count FROM letter_groups WHERE letter_type = 'uyirmei'");
    const [uyirmeiCount] = await pool.query("SELECT COUNT(*) as count FROM letters WHERE type = 'uyirmei'");
    const [totalLetters] = await pool.query("SELECT COUNT(*) as count FROM letters");

    console.log('----------------------------------------------------');
    console.log(`📊 Uyirmei Groups: ${groupCount[0].count} / 18`);
    console.log(`📊 Uyirmei Letters: ${uyirmeiCount[0].count} / 216`);
    console.log(`📊 Total Letters in Database: ${totalLetters[0].count} (12 Uyir + 18 Mei + 1 Aytham + 216 Uyirmei)`);
    console.log('====================================================');
  } catch (error) {
    await connection.rollback();
    console.error('❌ Seeding failed:', error);
    process.exitCode = 1;
  } finally {
    connection.release();
    process.exit(0);
  }
}

seedUyirmei();
