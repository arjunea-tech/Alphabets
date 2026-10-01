import sys
import os
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy.ndimage import gaussian_filter, binary_dilation

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

font_path = "C:\\Windows\\Fonts\\Nirmala.ttc"
try:
    font = ImageFont.truetype(font_path, 120)
except Exception:
    font = ImageFont.load_default()

labels_file = "frontend/assets/ml/labels.txt"
with open(labels_file, "r", encoding="utf-8") as f:
    labels = [l.strip() for l in f if l.strip()]

def render_canonical_skeleton(char):
    # Render at 256x256
    img = Image.new("L", (256, 256), 0)
    draw = ImageDraw.Draw(img)
    bbox = draw.textbbox((0, 0), char, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    
    # Center text
    draw.text(((256 - tw) // 2 - bbox[0], (256 - th) // 2 - bbox[1]), char, font=font, fill=255)
    
    arr = np.array(img, dtype=np.uint8)
    coords = np.argwhere(arr > 30)
    if len(coords) == 0:
        return np.zeros((32, 32), dtype=np.float32)
        
    ymin, xmin = coords.min(axis=0)
    ymax, xmax = coords.max(axis=0)
    h = ymax - ymin + 1
    w = xmax - xmin + 1
    cropped = arr[ymin:ymax+1, xmin:xmax+1]
    
    max_side = max(w, h)
    pad = int(max_side * 0.15)
    box_size = max_side + pad * 2
    canvas = np.zeros((box_size, box_size), dtype=np.uint8)
    ox = (box_size - w) // 2
    oy = (box_size - h) // 2
    canvas[oy:oy+h, ox:ox+w] = cropped
    
    # Resize to 32x32
    resized = Image.fromarray(canvas).resize((32, 32), Image.Resampling.BILINEAR)
    res_arr = np.array(resized, dtype=np.float32) / 255.0
    
    # Normalize skeleton line intensity
    max_v = res_arr.max()
    if max_v > 0:
        res_arr = res_arr / max_v
    return res_arr

canonical_skeletons = {}
for l in labels:
    skel = render_canonical_skeleton(l)
    canonical_skeletons[l] = skel
    print(f"Letter '{l}': active={((skel > 0.15).sum())}")
