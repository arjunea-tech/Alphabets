import os
import sys
import json
import time
import urllib.request
import urllib.parse
from PIL import Image

sys.stdout.reconfigure(encoding='utf-8')

output_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../frontend/assets/images/alphabets"))
os.makedirs(output_dir, exist_ok=True)
images_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../frontend/assets/images"))

# 13 letters from existing local assets
LOCAL_ASSETS = {
    'B': (os.path.join(images_dir, 'ball.jpg'), 'ball.png', 'Ball'),
    'C': (os.path.join(images_dir, 'camel.jpg'), 'camel.png', 'Camel'),
    'E': (os.path.join(images_dir, 'eye.jpg'), 'eye.png', 'Eye'),
    'F': (os.path.join(images_dir, 'fish.jpg'), 'fish.png', 'Fish'),
    'H': (os.path.join(images_dir, 'hen.jpg'), 'hen.png', 'Hen'),
    'K': (os.path.join(images_dir, 'skite.jpg'), 'kite.png', 'Kite'),
    'L': (os.path.join(images_dir, 'leaf.jpg'), 'leaf.png', 'Leaf'),
    'M': (os.path.join(images_dir, 'mat.jpg'), 'mat.png', 'Mat'),
    'N': (os.path.join(images_dir, 'number.jpg'), 'number.png', 'Number'),
    'R': (os.path.join(images_dir, 'story_rabbit.jpg'), 'rabbit.png', 'Rabbit'),
    'S': (os.path.join(images_dir, 'ship.jpg'), 'ship.png', 'Ship'),
    'T': (os.path.join(images_dir, 'tree.jpg'), 'tree.png', 'Tree'),
    'W': (os.path.join(images_dir, 'wheel.jpg'), 'wheel.png', 'Wheel'),
}

# The remaining 13 letters to fetch from Wikimedia Commons
REMOTE_TARGETS = {
    'A': ('Apple', 'apple.png'),
    'D': ('Dog', 'dog.png'),
    'G': ('Grape', 'grapes.png'),
    'I': ('Ice_cream', 'ice_cream.png'),
    'J': ('Jug', 'jug.png'),
    'O': ('Orange_(fruit)', 'orange.png'),
    'P': ('Parrot', 'parrot.png'),
    'Q': ('Queen_regnant', 'queen.png'),
    'U': ('Umbrella', 'umbrella.png'),
    'V': ('Van', 'van.png'),
    'X': ('Xylophone', 'xylophone.png'),
    'Y': ('Domestic_yak', 'yak.png'),
    'Z': ('Zebra', 'zebra.png'),
}

def center_crop_and_resize(img, size=(512, 512)):
    img = img.convert("RGBA")
    w, h = img.size
    min_dim = min(w, h)
    left = (w - min_dim) // 2
    top = (h - min_dim) // 2
    img_cropped = img.crop((left, top, left + min_dim, top + min_dim))
    return img_cropped.resize(size, Image.Resampling.LANCZOS)

HEADERS = {'User-Agent': 'KidsAlphabetApp/1.0 (https://alphabets.org; contact@alphabets.org)'}

def fetch_wiki_image(title):
    api_url = f"https://en.wikipedia.org/w/api.php?action=query&titles={urllib.parse.quote(title)}&prop=pageimages&format=json&pithumbsize=600"
    req = urllib.request.Request(api_url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=12) as resp:
        data = json.loads(resp.read().decode())
        pages = data['query']['pages']
        page = next(iter(pages.values()))
        if 'thumbnail' in page:
            thumb_url = page['thumbnail']['source']
            req2 = urllib.request.Request(thumb_url, headers=HEADERS)
            with urllib.request.urlopen(req2, timeout=12) as resp2:
                return resp2.read()
    return None

manifest = {}
saved_count = 0

print("1. Processing 13 Local Assets...")
for letter, (local_path, filename, word) in sorted(LOCAL_ASSETS.items()):
    out_path = os.path.join(output_dir, filename)
    root_out_path = os.path.join(images_dir, filename)
    if os.path.exists(local_path):
        with Image.open(local_path) as img:
            sq = center_crop_and_resize(img)
            sq.save(out_path, "PNG")
            sq.save(root_out_path, "PNG")
        manifest[letter] = {'letter': letter, 'word': word, 'file': filename, 'source': 'local'}
        saved_count += 1
        print(f"  [{letter}] Reused local asset -> {filename} ({word})")
    else:
        print(f"  [{letter}] Warning: local file {local_path} not found!")

print("\n2. Fetching remaining 13 CC/Public Domain Assets...")
for letter, (title, filename) in sorted(REMOTE_TARGETS.items()):
    out_path = os.path.join(output_dir, filename)
    root_out_path = os.path.join(images_dir, filename)
    clean_word = title.split('_')[0].split('(')[0]
    
    time.sleep(1.2) # Avoid rate limits
    try:
        raw_bytes = fetch_wiki_image(title)
        if raw_bytes:
            import io
            with Image.open(io.BytesIO(raw_bytes)) as img:
                sq = center_crop_and_resize(img)
                sq.save(out_path, "PNG")
                sq.save(root_out_path, "PNG")
            manifest[letter] = {'letter': letter, 'word': clean_word, 'file': filename, 'source': 'wikimedia'}
            saved_count += 1
            print(f"  [{letter}] Downloaded -> {filename} ({clean_word})")
        else:
            print(f"  [{letter}] No thumbnail for {title}")
    except Exception as e:
        print(f"  [{letter}] Error fetching {title}: {e}")

manifest_path = os.path.join(output_dir, "alphabet_images_manifest.json")
with open(manifest_path, "w", encoding="utf-8") as f:
    json.dump(manifest, f, indent=2)

print(f"\n=======================================================")
print(f"Done! Saved {saved_count}/26 images.")
print(f"Manifest written to: {manifest_path}")
print(f"=======================================================")
