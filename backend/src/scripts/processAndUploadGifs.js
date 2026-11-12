/**
 * Process GIFs directly from F:\gif using the exact BFS flood-fill and ffmpeg palettegen pipeline:
 * 1. Read original GIFs from F:\gif.
 * 2. Remove green screen background with BFS flood fill and despill green fringe.
 * 3. Crop tightly to character bounding box.
 * 4. Generate high quality transparent GIF using ffmpeg palettegen + paletteuse (dither=none).
 * 5. Save locally and upload to Cloudinary.
 * 6. Update cloudinary_image_map.json and cloudinary_media.dart.
 */
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const cloudinary = require('../config/cloudinary');

const ffmpeg = 'E:\\projects\\eluthukal\\backend\\node_modules\\ffmpeg-static\\ffmpeg.exe';
const SOURCE_DIR = 'F:\\gif';
const GIFS_DIR = path.join(__dirname, '../../uploads/gifs');
const FRONTEND_GIFS_DIR = path.join(__dirname, '../../../frontend/assets/gifs');
const FLUTTER_ASSETS_DIR = path.join(__dirname, '../../../frontend/build/flutter_assets/assets/gifs');
const MAP_PATH = path.join(__dirname, '../../database/cloudinary_image_map.json');
const FRONTEND_MAP_PATH = path.join(__dirname, '../../../frontend/assets/cloudinary_image_map.json');

const TEMP_FRAMES_DIR = path.join(__dirname, 'temp_raw_frames');
const TEMP_CROP_DIR = path.join(__dirname, 'temp_crop_frames');

const GIF_FILES = [
  'vanakam.gif',
  'reading.gif',
  'games.gif',
  'writing.gif',
  'video.gif',
  'question.gif',
];

function processSingleGif(inputPath, outGifPath) {
  [TEMP_FRAMES_DIR, TEMP_CROP_DIR].forEach(d => {
    if (fs.existsSync(d)) fs.rmSync(d, { recursive: true, force: true });
    fs.mkdirSync(d, { recursive: true });
  });

  // 1. Extract frames with ffmpeg
  spawnSync(ffmpeg, ['-y', '-i', inputPath, path.join(TEMP_FRAMES_DIR, 'frame_%04d.png')]);
  const frameFiles = fs.readdirSync(TEMP_FRAMES_DIR).filter(f => f.endsWith('.png')).sort();
  if (frameFiles.length === 0) {
    throw new Error('Failed to extract frames from ' + inputPath);
  }

  const width = 480;
  const height = 270;
  let minX = width, maxX = 0, minY = height, maxY = 0;
  const processedBuffers = [];

  for (let idx = 0; idx < frameFiles.length; idx++) {
    const fName = frameFiles[idx];
    const inFramePath = path.join(TEMP_FRAMES_DIR, fName);
    const rawIn = path.join(TEMP_FRAMES_DIR, 'raw_' + idx + '.raw');

    spawnSync(ffmpeg, ['-y', '-i', inFramePath, '-f', 'rawvideo', '-pix_fmt', 'rgba', rawIn]);
    const buf = fs.readFileSync(rawIn);
    fs.unlinkSync(rawIn);

    const visited = new Uint8Array(width * height);
    const queue = [];

    function isGreenPixel(x, y) {
      const i = (y * width + x) * 4;
      const r = buf[i], g = buf[i + 1], b = buf[i + 2];
      return (g > 65 && g > r * 1.15 && g > b * 1.15) || (g > 140 && g > r && g > b);
    }

    // Border seeds
    for (let x = 0; x < width; x++) {
      if (isGreenPixel(x, 0)) { queue.push(x, 0); visited[x] = 1; }
      if (isGreenPixel(x, height - 1)) { queue.push(x, height - 1); visited[(height - 1) * width + x] = 1; }
    }
    for (let y = 0; y < height; y++) {
      if (isGreenPixel(0, y)) { queue.push(0, y); visited[y * width] = 1; }
      if (isGreenPixel(width - 1, y)) { queue.push(width - 1, y); visited[y * width + width - 1] = 1; }
    }

    // BFS Flood Fill
    let head = 0;
    while (head < queue.length) {
      const cx = queue[head++];
      const cy = queue[head++];
      const neighbors = [[cx + 1, cy], [cx - 1, cy], [cx, cy + 1], [cx, cy - 1]];
      for (const [nx, ny] of neighbors) {
        if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
          const nIdx = ny * width + nx;
          if (!visited[nIdx] && isGreenPixel(nx, ny)) {
            visited[nIdx] = 1;
            queue.push(nx, ny);
          }
        }
      }
    }

    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        const pIdx = y * width + x;
        const i = pIdx * 4;
        if (visited[pIdx] || isGreenPixel(x, y)) {
          buf[i + 3] = 0;
        } else {
          const r = buf[i], g = buf[i + 1], b = buf[i + 2];
          if (g > r * 1.05 && g > b * 1.05) {
            buf[i + 1] = Math.max(r, b);
          }
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    processedBuffers.push(buf);
  }

  const pad = 6;
  const cropX = Math.max(0, minX - pad);
  const cropY = Math.max(0, minY - pad);
  const cropW = Math.min(width - cropX, maxX - minX + 1 + pad * 2);
  const cropH = Math.min(height - cropY, maxY - minY + 1 + pad * 2);

  console.log(`   Cropped box: ${cropW}x${cropH} (offset ${cropX},${cropY} from ${width}x${height})`);

  // Write cropped PNG frames
  for (let idx = 0; idx < processedBuffers.length; idx++) {
    const buf = processedBuffers[idx];
    const cropped = Buffer.alloc(cropW * cropH * 4);

    for (let cy = 0; cy < cropH; cy++) {
      for (let cx = 0; cx < cropW; cx++) {
        const srcIdx = ((cropY + cy) * width + (cropX + cx)) * 4;
        const dstIdx = (cy * cropW + cx) * 4;
        cropped[dstIdx] = buf[srcIdx];
        cropped[dstIdx + 1] = buf[srcIdx + 1];
        cropped[dstIdx + 2] = buf[srcIdx + 2];
        cropped[dstIdx + 3] = buf[srcIdx + 3];
      }
    }

    const rawOut = path.join(TEMP_CROP_DIR, 'raw_' + idx + '.raw');
    fs.writeFileSync(rawOut, cropped);
    const outPng = path.join(TEMP_CROP_DIR, 'frame_' + String(idx + 1).padStart(4, '0') + '.png');

    spawnSync(ffmpeg, [
      '-y', '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', `${cropW}x${cropH}`,
      '-i', rawOut, outPng
    ]);
    fs.unlinkSync(rawOut);
  }

  // Assemble into GIF with palettegen + paletteuse (dither=none)
  const filter = '[0:v] split [a][b]; [a] palettegen=reserve_transparent=on:transparency_color=00ff00 [p]; [b][p] paletteuse=alpha_threshold=128:dither=none';

  spawnSync(ffmpeg, [
    '-y', '-framerate', '16.67',
    '-i', path.join(TEMP_CROP_DIR, 'frame_%04d.png'),
    '-filter_complex', filter,
    outGifPath
  ]);

  [TEMP_FRAMES_DIR, TEMP_CROP_DIR].forEach(d => {
    if (fs.existsSync(d)) fs.rmSync(d, { recursive: true, force: true });
  });

  return fs.statSync(outGifPath).size;
}

async function uploadToCloudinary(filePath, publicId) {
  try {
    const res = await cloudinary.uploader.upload(filePath, {
      folder: 'agaram_media/gifs',
      public_id: publicId,
      resource_type: 'image',
      overwrite: true,
    });
    return res.secure_url;
  } catch (err) {
    console.error(`❌ Cloudinary upload failed for ${publicId}:`, err.message);
    return null;
  }
}

async function main() {
  console.log('🚀 Processing GIFs from F:\\gif with ffmpeg palettegen (dither=none)...');

  fs.mkdirSync(FRONTEND_GIFS_DIR, { recursive: true });
  fs.mkdirSync(GIFS_DIR, { recursive: true });
  if (fs.existsSync(path.dirname(FLUTTER_ASSETS_DIR))) {
    fs.mkdirSync(FLUTTER_ASSETS_DIR, { recursive: true });
  }

  const map = JSON.parse(fs.readFileSync(MAP_PATH, 'utf8'));

  for (const file of GIF_FILES) {
    console.log(`\n🎬 Processing ${file} from F:\\gif...`);
    const sourcePath = path.join(SOURCE_DIR, file);
    if (!fs.existsSync(sourcePath)) {
      console.warn(`⚠️ Source not found: ${sourcePath}`);
      continue;
    }

    const backendPath = path.join(GIFS_DIR, file);
    const frontendPath = path.join(FRONTEND_GIFS_DIR, file);

    const sizeBytes = processSingleGif(sourcePath, backendPath);
    console.log(`   Cleaned size: ${(sizeBytes / 1024).toFixed(1)} KB`);

    fs.copyFileSync(backendPath, frontendPath);
    if (fs.existsSync(FLUTTER_ASSETS_DIR)) {
      fs.copyFileSync(backendPath, path.join(FLUTTER_ASSETS_DIR, file));
    }
    console.log(`   Saved to backend & frontend assets/gifs/${file}`);

    const baseName = path.basename(file, '.gif');
    const publicId = `gif_${baseName}`;
    console.log(`   Uploading to Cloudinary as ${publicId}...`);
    const url = await uploadToCloudinary(backendPath, publicId);

    if (url) {
      console.log(`   ✅ Cloudinary URL: ${url}`);
      map[`assets/gifs/${file}`] = url;
      map[file] = url;
      map[`assets/gifs/${baseName}`] = url;
    } else {
      console.error(`   ❌ Failed to upload ${file} to Cloudinary!`);
    }
  }

  fs.writeFileSync(MAP_PATH, JSON.stringify(map, null, 2), 'utf8');
  fs.writeFileSync(FRONTEND_MAP_PATH, JSON.stringify(map, null, 2), 'utf8');
  console.log('\n📄 Updated cloudinary_image_map.json');

  console.log('🔄 Regenerating cloudinary_media.dart...');
  require('./generateCloudinaryDart');

  console.log('\n🎉 ALL GIFS FROM F:\\gif PROCESSED AND DEPLOYED CLEANLY!');
}

main().catch(console.error);
