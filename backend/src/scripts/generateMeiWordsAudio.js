const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');
const { execSync } = require('child_process');

let ffmpegPath;
try {
  ffmpegPath = require('ffmpeg-static');
} catch (e) {
  console.error('ffmpeg-static not found');
}

const WORDS_DIR = path.join(__dirname, '../../../frontend/assets/audio/tamil/words');
if (!fs.existsSync(WORDS_DIR)) {
  fs.mkdirSync(WORDS_DIR, { recursive: true });
}

const ALL_WORDS = [
  // Database active Mei words
  { letter: 'க்', word: 'சக்கரம்', slug: 'word_sakkaram' },
  { letter: 'ங்', word: 'சங்கு', slug: 'word_sangu' },
  { letter: 'ச்', word: 'எலுமிச்சை', slug: 'word_elumichai' },
  { letter: 'ச்', word: 'தச்சர்', slug: 'word_thacchar' },
  { letter: 'ஞ்', word: 'ஊஞ்சல்', slug: 'word_oonjal' },
  { letter: 'ட்', word: 'பட்டம்', slug: 'word_pattam' },
  { letter: 'ண்', word: 'கண்', slug: 'word_kann' },
  { letter: 'த்', word: 'நத்தை', slug: 'word_nathai' },
  { letter: 'ந்', word: 'பந்து', slug: 'word_panthu' },
  { letter: 'ப்', word: 'கப்பல்', slug: 'word_kappal' },
  { letter: 'ம்', word: 'மரம்', slug: 'word_maram' },
  { letter: 'ய்', word: 'பாய்', slug: 'word_paai' },
  { letter: 'ர்', word: 'தேர்', slug: 'word_thear' },
  { letter: 'ர்', word: 'ஏர்', slug: 'word_ear' },
  { letter: 'ல்', word: 'சேவல்', slug: 'word_seval' },
  { letter: 'வ்', word: 'செவ்வானம்', slug: 'word_sevvaanam' },
  { letter: 'வ்', word: 'செவ்வந்தி', slug: 'word_sevvanthi' },
  { letter: 'ழ்', word: 'யாழ்', slug: 'word_yaazh' },
  { letter: 'ள்', word: 'வாள்', slug: 'word_vaal' },
  { letter: 'ற்', word: 'வெற்றிலை', slug: 'word_vetrilai' },
  { letter: 'ற்', word: 'புற்று', slug: 'word_putru' },
  { letter: 'ன்', word: 'மீன்', slug: 'word_meen' },
];

function downloadTts(url) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith('https') ? https : http;
    const req = client.get(
      url,
      {
        headers: {
          'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          Accept: 'audio/mpeg, audio/*; q=0.9, */*; q=0.8',
          Referer: 'https://translate.google.com/',
        },
      },
      (res) => {
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          return downloadTts(res.headers.location).then(resolve).catch(reject);
        }
        if (res.statusCode !== 200) {
          return reject(new Error(`Status ${res.statusCode}`));
        }
        const chunks = [];
        res.on('data', (chunk) => chunks.push(chunk));
        res.on('end', () => resolve(Buffer.concat(chunks)));
      }
    );
    req.on('error', reject);
    req.setTimeout(8000, () => {
      req.destroy();
      reject(new Error('Timeout'));
    });
  });
}

async function fetchAudioForWord(wordText) {
  const urls = [
    `https://translate.google.com/translate_tts?ie=UTF-8&q=${encodeURIComponent(wordText)}&tl=ta&client=tw-ob`,
    `https://translate.googleapis.com/translate_tts?ie=UTF-8&q=${encodeURIComponent(wordText)}&tl=ta&client=gtx`,
    `https://translate.google.com/translate_tts?ie=UTF-8&q=${encodeURIComponent(wordText)}&tl=ta&client=dict-chrome-ex`,
  ];

  for (const url of urls) {
    try {
      const buffer = await downloadTts(url);
      if (buffer && buffer.length > 500) {
        return buffer;
      }
    } catch (e) {
      // try next
    }
  }
  throw new Error(`Failed to fetch audio for "${wordText}"`);
}

async function run() {
  console.log('Generating and boosting audio for all Mei words...');

  for (const item of ALL_WORDS) {
    const rawPath = path.join(WORDS_DIR, `${item.slug}.raw.mp3`);
    const finalPath = path.join(WORDS_DIR, `${item.slug}.mp3`);

    // Also create hex filename alias
    const hex = Buffer.from(item.word, 'utf8').toString('hex');
    const hexPath = path.join(WORDS_DIR, `word_${hex}.mp3`);

    try {
      console.log(`Fetching audio for [${item.letter}] "${item.word}" -> ${item.slug}.mp3...`);
      const buffer = await fetchAudioForWord(item.word);
      fs.writeFileSync(rawPath, buffer);

      if (ffmpegPath && fs.existsSync(ffmpegPath)) {
        // Boost volume with 2.5x gain and save
        const cmd = `"${ffmpegPath}" -y -i "${rawPath}" -af "volume=2.5" -c:a libmp3lame -q:a 2 "${finalPath}"`;
        execSync(cmd, { stdio: 'pipe' });
        fs.unlinkSync(rawPath);
      } else {
        fs.renameSync(rawPath, finalPath);
      }

      // Copy to hex path as well for seamless resolution
      fs.copyFileSync(finalPath, hexPath);

      console.log(`✅ Saved & boosted: ${item.slug}.mp3 & word_${hex}.mp3 (${fs.statSync(finalPath).size} bytes)`);
    } catch (err) {
      console.error(`❌ Error for ${item.word}: ${err.message}`);
    }
  }

  console.log('\n🎉 Finished generating all words audio!');
}

run();
