/**
 * Script to sync all 30 Cloudinary letter videos into production PostgreSQL / live API server
 */
const https = require('https');

const API_BASE = 'https://eluthukkal-api.macvelsoftware.com/api/v1';

const UYIR_LETTERS = [
  { letter: 'அ', word: 'அம்மா' },
  { letter: 'ஆ', word: 'ஆடு' },
  { letter: 'இ', word: 'இலை' },
  { letter: 'ஈ', word: 'ஈ' },
  { letter: 'உ', word: 'உரல்' },
  { letter: 'ஊ', word: 'ஊஞ்சல்' },
  { letter: 'எ', word: 'எலி' },
  { letter: 'ஏ', word: 'ஏணி' },
  { letter: 'ஐ', word: 'ஐந்து' },
  { letter: 'ஒ', word: 'ஒட்டகம்' },
  { letter: 'ஓ', word: 'ஓடம்' },
  { letter: 'ஔ', word: 'ஔவையார்' },
];

const MEI_LETTERS = [
  { letter: 'க்', word: 'சக்கரம்' },
  { letter: 'ங்', word: 'சங்கு' },
  { letter: 'ச்', word: 'தச்சர்' },
  { letter: 'ஞ்', word: 'ஊஞ்சல்' },
  { letter: 'ட்', word: 'பட்டம்' },
  { letter: 'ண்', word: 'கண்' },
  { letter: 'த்', word: 'நத்தை' },
  { letter: 'ந்', word: 'பந்து' },
  { letter: 'ப்', word: 'கப்பல்' },
  { letter: 'ம்', word: 'மரம்' },
  { letter: 'ய்', word: 'பாய்' },
  { letter: 'ர்', word: 'ஏர்' },
  { letter: 'ல்', word: 'சேவல்' },
  { letter: 'வ்', word: 'செவ்வந்தி' },
  { letter: 'ழ்', word: 'யாழ்' },
  { letter: 'ள்', word: 'வாள்' },
  { letter: 'ற்', word: 'புற்று' },
  { letter: 'ன்', word: 'மீன்' },
];

const CLOUDINARY_VIDEOS = [
  // 12 Uyir
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790841742/agaram_media/videos/lyai8f00wea5mpvknty5.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849387/agaram_media/videos/yileko0mif4cuduhy3ty.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849484/agaram_media/videos/pskdcrc7xqmdsqbgh9no.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849525/agaram_media/videos/lhylws8eq0iijt9azfhp.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849570/agaram_media/videos/srteaw6jwtppkt0e6esl.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849604/agaram_media/videos/mvtffw845vapnhrhokcu.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849714/agaram_media/videos/losz1xmdpogdsyb3kfkb.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849774/agaram_media/videos/ctcqwju9p8xcdppwxogk.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849825/agaram_media/videos/abyi5xu4ffymff9ioosy.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790854598/agaram_media/videos/ranfb0lwkaspm4mffrqp.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790854646/agaram_media/videos/gv3wggfnpbus8n2fol4c.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790855080/agaram_media/videos/btefhsc3k9n0kgfhmcrn.mp4',

  // 18 Mei
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791006753/agaram_media/videos/fg18xjxo2q4p9wsyfvpo.mp4', // க்
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791007508/agaram_media/videos/zjmzubpswzwhlkvl5ojn.mp4', // ங்
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791007812/agaram_media/videos/fsagxkudps6vh6lybuno.mp4', // ச்
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791007916/agaram_media/videos/ykprwmafp4al32alrsa6.mp4', // ஞ்
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791008045/agaram_media/videos/sd0kk4jfqz572vowz63j.mp4', // ட்
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791011858/agaram_media/videos/mrj9929eyumtpsvwvk49.mp4', // ண்
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791012537/agaram_media/videos/xayiuz964o3qwkbtpjkr.mp4', // த்
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791012754/agaram_media/videos/jb0av76qcjimjylof1oh.mp4', // ந்
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791013206/agaram_media/videos/hgdp4p7sjj4zuemigges.mp4', // ப்
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791178025/agaram_media/videos/rvu5tcop5a4inyy2myty.mp4', // ம்
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791178322/agaram_media/videos/pzjgq9yxjcf3xcyaxbbh.mp4', // ய்
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791178852/agaram_media/videos/k4tqtli6kuwysaqx7muw.mp4', // ர்
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791179035/agaram_media/videos/p8fcozkulcpzcpvdcsgd.mp4', // ல்
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791179306/agaram_media/videos/jkhfxzw7ksobhb7hawpv.mp4', // வ்
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791179352/agaram_media/videos/iinovuxh3dnlsajorpsp.mp4', // ழ்
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791179466/agaram_media/videos/ibjoez182v1nsagtyedb.mp4', // ள்
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791179595/agaram_media/videos/umbutwkkjznope99qwnw.mp4', // ற்
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791179910/agaram_media/videos/asrp5x7m9ynstmklzx40.mp4', // ன்
];

function request(url, options, bodyData) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const opts = {
      hostname: u.hostname,
      port: u.port || 443,
      path: u.pathname + u.search,
      method: options.method || 'GET',
      headers: options.headers || {},
    };

    const req = https.request(opts, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          resolve({ status: res.statusCode, data: parsed });
        } catch (_) {
          resolve({ status: res.statusCode, raw: body });
        }
      });
    });

    req.on('error', reject);
    if (bodyData) {
      req.write(typeof bodyData === 'string' ? bodyData : JSON.stringify(bodyData));
    }
    req.end();
  });
}

async function run() {
  console.log('🔐 Logging in to remote production server...');
  const loginRes = await request(`${API_BASE}/auth/admin/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
  }, {
    username: 'admin@gmail.com',
    password: 'Admin@123',
  });

  if (loginRes.status !== 200 || !loginRes.data?.data?.token) {
    throw new Error('Failed to login: ' + JSON.stringify(loginRes));
  }

  const token = loginRes.data.data.token;
  console.log('✅ Logged in successfully!');

  // Check current videos
  console.log('📹 Fetching existing videos on production server...');
  const existingRes = await request(`${API_BASE}/videos?all=true`, {});
  const existingList = existingRes.data?.data || [];
  console.log(`Found ${existingList.length} videos currently.`);

  // Clean up dummy videos if present
  for (const v of existingList) {
    if (v.id.startsWith('vid_uyir_song') || v.id.startsWith('vid_mei_rhyme') || v.id.startsWith('vid_tamil_intro')) {
      console.log(`🗑️ Deleting dummy video: ${v.id} (${v.title})...`);
      await request(`${API_BASE}/videos/${v.id}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` },
      });
    }
  }

  // 1. Sync 12 Uyir Videos
  console.log('✨ Syncing 12 Uyir videos...');
  for (let i = 0; i < UYIR_LETTERS.length; i++) {
    const item = UYIR_LETTERS[i];
    const videoUrl = CLOUDINARY_VIDEOS[i];
    const id = `vid_uyir_${i + 1}`;
    const title = item.letter;
    const description = `உயிர் எழுத்து ${item.letter}`;
    const category = 'உயிர் எழுத்துகள்';
    const displayOrder = i + 1;

    // Check if exists
    const exists = existingList.some((x) => x.id === id);
    if (exists) {
      console.log(`  Updating ${id} (${title})...`);
      await request(`${API_BASE}/videos/${id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
      }, {
        title,
        description,
        category,
        duration: '00:15',
        thumbnail_emoji: `🎬${item.letter}`,
        video_url: videoUrl,
        display_order: displayOrder,
        is_published: true,
      });
    } else {
      console.log(`  Creating ${id} (${title})...`);
      const createRes = await request(`${API_BASE}/videos`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
      }, {
        id,
        title,
        description,
        category,
        duration: '00:15',
        thumbnail_emoji: `🎬${item.letter}`,
        video_url: videoUrl,
        display_order: displayOrder,
        is_published: true,
      });
      if (createRes.status >= 300) {
        console.error(`  ❌ Failed to create ${id}:`, createRes);
      }
    }
  }

  // 2. Sync 18 Mei Videos
  console.log('✨ Syncing 18 Mei videos...');
  for (let i = 0; i < MEI_LETTERS.length; i++) {
    const item = MEI_LETTERS[i];
    const videoUrl = CLOUDINARY_VIDEOS[12 + i];
    const id = `vid_mei_${i + 1}`;
    const title = item.letter;
    const description = `மெய் எழுத்து ${item.letter}`;
    const category = 'மெய் எழுத்துகள்';
    const displayOrder = i + 1;

    const exists = existingList.some((x) => x.id === id);
    if (exists) {
      console.log(`  Updating ${id} (${title})...`);
      await request(`${API_BASE}/videos/${id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
      }, {
        title,
        description,
        category,
        duration: '00:15',
        thumbnail_emoji: `✍️${item.letter}`,
        video_url: videoUrl,
        display_order: displayOrder,
        is_published: true,
      });
    } else {
      console.log(`  Creating ${id} (${title})...`);
      const createRes = await request(`${API_BASE}/videos`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
      }, {
        id,
        title,
        description,
        category,
        duration: '00:15',
        thumbnail_emoji: `✍️${item.letter}`,
        video_url: videoUrl,
        display_order: displayOrder,
        is_published: true,
      });
      if (createRes.status >= 300) {
        console.error(`  ❌ Failed to create ${id}:`, createRes);
      }
    }
  }

  console.log('🎉 Done syncing videos! Fetching count...');
  const afterRes = await request(`${API_BASE}/videos?all=true`, {});
  console.log(`Total videos now on production server: ${afterRes.data?.data?.length}`);
}

run().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
