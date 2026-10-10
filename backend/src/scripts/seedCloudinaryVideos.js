/**
 * Seed all 31 Cloudinary uploaded videos into MySQL database
 * - 12 Uyir letters (அ முதல் ஔ)
 * - 18 Mei letters (க் முதல் ன்)
 * - 1 Aytham letter (ஃ)
 * - Plus existing sample videos (பாடல்கள் & கதைகள்)
 */
const { pool } = require('../config/db');

const UYIR_LETTERS = [
  { letter: 'அ', word: 'அம்மா', meaning: 'Mother' },
  { letter: 'ஆ', word: 'ஆடு', meaning: 'Goat' },
  { letter: 'இ', word: 'இலை', meaning: 'Leaf' },
  { letter: 'ஈ', word: 'ஈ', meaning: 'Housefly' },
  { letter: 'உ', word: 'உரல்', meaning: 'Mortar' },
  { letter: 'ஊ', word: 'ஊஞ்சல்', meaning: 'Swing' },
  { letter: 'எ', word: 'எலி', meaning: 'Rat' },
  { letter: 'ஏ', word: 'ஏணி', meaning: 'Ladder' },
  { letter: 'ஐ', word: 'ஐந்து', meaning: 'Five' },
  { letter: 'ஒ', word: 'ஒட்டகம்', meaning: 'Camel' },
  { letter: 'ஓ', word: 'ஓடம்', meaning: 'Boat' },
  { letter: 'ஔ', word: 'ஔவையார்', meaning: 'Avvaiyar' },
];

const MEI_LETTERS = [
  { letter: 'க்', word: 'சக்கரம்', meaning: 'Wheel' },
  { letter: 'ங்', word: 'சங்கு', meaning: 'Conch' },
  { letter: 'ச்', word: 'தச்சர்', meaning: 'Carpenter' },
  { letter: 'ஞ்', word: 'ஊஞ்சல்', meaning: 'Swing' },
  { letter: 'ட்', word: 'பட்டம்', meaning: 'Kite' },
  { letter: 'ண்', word: 'கண்', meaning: 'Eye' },
  { letter: 'த்', word: 'நத்தை', meaning: 'Snail' },
  { letter: 'ந்', word: 'பந்து', meaning: 'Ball' },
  { letter: 'ப்', word: 'கப்பல்', meaning: 'Ship' },
  { letter: 'ம்', word: 'மரம்', meaning: 'Tree' },
  { letter: 'ய்', word: 'பாய்', meaning: 'Mat' },
  { letter: 'ர்', word: 'ஏர்', meaning: 'Plough' },
  { letter: 'ல்', word: 'சேவல்', meaning: 'Rooster' },
  { letter: 'வ்', word: 'செவ்வந்தி', meaning: 'Chrysanthemum' },
  { letter: 'ழ்', word: 'யாழ்', meaning: 'Harp' },
  { letter: 'ள்', word: 'வாள்', meaning: 'Sword' },
  { letter: 'ற்', word: 'புற்று', meaning: 'Ant-hill' },
  { letter: 'ன்', word: 'மீன்', meaning: 'Fish' },
];

// Chronological 31 videos from Cloudinary (agaram_media/videos)
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
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791006753/agaram_media/videos/fg18xjxo2q4p9wsyfvpo.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791007508/agaram_media/videos/zjmzubpswzwhlkvl5ojn.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791007812/agaram_media/videos/fsagxkudps6vh6lybuno.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791007916/agaram_media/videos/ykprwmafp4al32alrsa6.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791008045/agaram_media/videos/sd0kk4jfqz572vowz63j.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791011858/agaram_media/videos/mrj9929eyumtpsvwvk49.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791012537/agaram_media/videos/xayiuz964o3qwkbtpjkr.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791012754/agaram_media/videos/jb0av76qcjimjylof1oh.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791013206/agaram_media/videos/hgdp4p7sjj4zuemigges.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791178025/agaram_media/videos/rvu5tcop5a4inyy2myty.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791178069/agaram_media/videos/zm4plb84tszsg6bty9vr.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791178322/agaram_media/videos/pzjgq9yxjcf3xcyaxbbh.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791178852/agaram_media/videos/k4tqtli6kuwysaqx7muw.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791179035/agaram_media/videos/p8fcozkulcpzcpvdcsgd.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791179306/agaram_media/videos/jkhfxzw7ksobhb7hawpv.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791179352/agaram_media/videos/iinovuxh3dnlsajorpsp.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791179466/agaram_media/videos/ibjoez182v1nsagtyedb.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791179595/agaram_media/videos/umbutwkkjznope99qwnw.mp4',

  // 1 Aytham
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791179910/agaram_media/videos/asrp5x7m9ynstmklzx40.mp4',
];

async function seedVideos() {
  console.log('🎬 Seeding Cloudinary videos into MySQL database...');

  // 1. Seed 12 Uyir Videos
  for (let i = 0; i < UYIR_LETTERS.length; i++) {
    const item = UYIR_LETTERS[i];
    const videoUrl = CLOUDINARY_VIDEOS[i];
    const id = `vid_uyir_${i + 1}`;
    const title = item.letter;
    const description = `உயிர் எழுத்து ${item.letter} - ${item.word}`;
    const category = 'உயிர் எழுத்துகள்';
    const displayOrder = i + 1;

    await pool.query(
      `INSERT INTO videos (id, title, description, category, duration, thumbnail_emoji, video_url, display_order, is_published)
       VALUES (?, ?, ?, ?, '00:15', ?, ?, ?, TRUE)
       ON DUPLICATE KEY UPDATE 
         title = VALUES(title), 
         description = VALUES(description), 
         category = VALUES(category), 
         video_url = VALUES(video_url),
         display_order = VALUES(display_order),
         is_published = TRUE`,
      [id, title, description, category, `🎬${item.letter}`, videoUrl, displayOrder]
    );
  }
  console.log('✅ 12 Uyir videos seeded.');

  // 2. Seed 18 Mei Videos
  for (let i = 0; i < MEI_LETTERS.length; i++) {
    const item = MEI_LETTERS[i];
    const videoUrl = CLOUDINARY_VIDEOS[12 + i];
    const id = `vid_mei_${i + 1}`;
    const title = item.letter;
    const description = `மெய் எழுத்து ${item.letter} - ${item.word}`;
    const category = 'மெய் எழுத்துகள்';
    const displayOrder = i + 1;

    await pool.query(
      `INSERT INTO videos (id, title, description, category, duration, thumbnail_emoji, video_url, display_order, is_published)
       VALUES (?, ?, ?, ?, '00:15', ?, ?, ?, TRUE)
       ON DUPLICATE KEY UPDATE 
         title = VALUES(title), 
         description = VALUES(description), 
         category = VALUES(category), 
         video_url = VALUES(video_url),
         display_order = VALUES(display_order),
         is_published = TRUE`,
      [id, title, description, category, `✍️${item.letter}`, videoUrl, displayOrder]
    );
  }
  console.log('✅ 18 Mei videos seeded.');

  // 3. Seed 1 Aytham Video
  const aythamVideoUrl = CLOUDINARY_VIDEOS[30];
  await pool.query(
    `INSERT INTO videos (id, title, description, category, duration, thumbnail_emoji, video_url, display_order, is_published)
     VALUES (?, 'ஃ', 'ஆய்த எழுத்து ஃ - எஃகு', 'பாடம்', '00:15', '🛡️', ?, 19, TRUE)
     ON DUPLICATE KEY UPDATE video_url = VALUES(video_url), is_published = TRUE`,
    ['vid_aytham_1', aythamVideoUrl]
  );
  console.log('✅ Aytham video seeded.');

  const [count] = await pool.query('SELECT COUNT(*) as total FROM videos');
  console.log(`🎉 Total videos in MySQL database: ${count[0].total}`);
  process.exit(0);
}

seedVideos().catch((err) => {
  console.error('❌ Error seeding videos:', err);
  process.exit(1);
});
