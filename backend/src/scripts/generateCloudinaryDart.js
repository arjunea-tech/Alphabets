/**
 * Script to generate frontend/lib/services/cloudinary_media.dart
 * from backend/database/cloudinary_image_map.json
 */
const fs = require('fs');
const path = require('path');

const mapPath = path.join(__dirname, '../../database/cloudinary_image_map.json');
const outDartPath = path.join(__dirname, '../../../frontend/lib/services/cloudinary_media.dart');

const map = JSON.parse(fs.readFileSync(mapPath, 'utf8'));

let dartContent = `// Generated Cloudinary Media Helper for AGARAM Educational Platform
// Contains CDN URLs for all frontend assets and backend images.

class CloudinaryMedia {
  static const String cloudName = 'dy8bu8suk';
  static const String folder = 'agaram_media/images';

  static const Map<String, String> _assetToCloudinaryMap = {
`;

for (const [key, url] of Object.entries(map)) {
  dartContent += `    '${key}': '${url}',\n`;
}

dartContent += `  };

  /// Resolves any asset path, filename, or URL to its Cloudinary CDN URL.
  /// If no Cloudinary match exists, returns the original path.
  static String? getUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final clean = path.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    
    // Direct match (e.g. 'assets/images/amma.jpg' or 'amma.jpg')
    if (_assetToCloudinaryMap.containsKey(clean)) {
      return _assetToCloudinaryMap[clean];
    }
    
    // Check filename without path
    final fileName = clean.split('/').last;
    if (_assetToCloudinaryMap.containsKey(fileName)) {
      return _assetToCloudinaryMap[fileName];
    }

    // Check with assets/images/ prefix
    final withPrefix = 'assets/images/' + fileName;
    if (_assetToCloudinaryMap.containsKey(withPrefix)) {
      return _assetToCloudinaryMap[withPrefix];
    }

    return clean;
  }

  /// Checks if a Cloudinary URL exists for this asset
  static bool hasCloudinaryUrl(String? path) {
    if (path == null) return false;
    final url = getUrl(path);
    return url != null && (url.startsWith('http://') || url.startsWith('https://'));
  }
}
`;

fs.writeFileSync(outDartPath, dartContent, 'utf8');
console.log('✅ Generated frontend/lib/services/cloudinary_media.dart successfully!');
