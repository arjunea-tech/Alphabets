const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

let ffmpegPath;
try {
  ffmpegPath = require('ffmpeg-static');
} catch (e) {
  console.error('ffmpeg-static not found in node_modules');
}

const assetsDirs = [
  path.join(__dirname, '../../../frontend/assets/audio'),
  path.join(__dirname, '../../../frontend/assets/sounds'),
];

function getAllMp3Files(dirPath, arrayOfFiles = []) {
  if (!fs.existsSync(dirPath)) return arrayOfFiles;
  const files = fs.readdirSync(dirPath);

  files.forEach((file) => {
    const fullPath = path.join(dirPath, file);
    if (fs.statSync(fullPath).isDirectory()) {
      getAllMp3Files(fullPath, arrayOfFiles);
    } else if (file.toLowerCase().endsWith('.mp3')) {
      arrayOfFiles.push(fullPath);
    }
  });

  return arrayOfFiles;
}

async function boostAllAudio() {
  if (!ffmpegPath || !fs.existsSync(ffmpegPath)) {
    console.error('ffmpeg binary path is invalid:', ffmpegPath);
    process.exit(1);
  }

  console.log(`Using ffmpeg at: ${ffmpegPath}`);

  let allFiles = [];
  for (const dir of assetsDirs) {
    allFiles = getAllMp3Files(dir, allFiles);
  }

  console.log(`Found ${allFiles.length} MP3 files to boost...`);

  let successCount = 0;
  let errorCount = 0;

  for (let i = 0; i < allFiles.length; i++) {
    const filePath = allFiles[i];
    const tempOut = filePath + '.boosted.mp3';

    try {
      // Apply volume filter (volume=2.5x gain) + peak limiting to keep high quality
      const cmd = `"${ffmpegPath}" -y -i "${filePath}" -af "volume=2.5" -c:a libmp3lame -q:a 2 "${tempOut}"`;
      execSync(cmd, { stdio: 'pipe' });

      if (fs.existsSync(tempOut) && fs.statSync(tempOut).size > 0) {
        fs.unlinkSync(filePath);
        fs.renameSync(tempOut, filePath);
        successCount++;
      } else {
        throw new Error('Boosted file empty or missing');
      }
    } catch (err) {
      if (fs.existsSync(tempOut)) {
        try { fs.unlinkSync(tempOut); } catch (_) {}
      }
      console.error(`Error boosting ${path.basename(filePath)}: ${err.message}`);
      errorCount++;
    }

    if ((i + 1) % 25 === 0 || i === allFiles.length - 1) {
      console.log(`Progress: ${i + 1}/${allFiles.length} files processed.`);
    }
  }

  console.log(`\n✅ Audio volume boost completed!`);
  console.log(`Success: ${successCount}, Errors: ${errorCount}`);
}

boostAllAudio();
