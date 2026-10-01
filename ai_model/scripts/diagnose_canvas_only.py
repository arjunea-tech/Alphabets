import sys
import os
import json
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

sys.stdout.reconfigure(encoding='utf-8')

img_path = "C:/Users/welcome/.gemini/antigravity-ide/brain/e81763e3-2bd6-4287-88d5-538a0eefe1bd/.user_uploaded/media_1790674269146.png"
img = Image.open(img_path).convert('RGB')
img_np = np.array(img)
h, w, _ = img_np.shape
print(f"Image size: {w}x{h}")

# The writing canvas is roughly between y=300 and y=630, x=30 and x=290
canvas_crop = img_np[290:630, 25:295]
r, g, b = canvas_crop[:,:,0].astype(int), canvas_crop[:,:,1].astype(int), canvas_crop[:,:,2].astype(int)
blue_mask = (b > 180) & (b > r + 60) & (b > g + 40)

y_indices, x_indices = np.where(blue_mask)
print(f"Found {len(y_indices)} blue pixels inside canvas area")

min_y, max_y = np.min(y_indices), np.max(y_indices)
min_x, max_x = np.min(x_indices), np.max(x_indices)

crop = blue_mask[min_y:max_y+1, min_x:max_x+1].astype(np.float32)
print(f"Cropped letter drawing dimensions: {crop.shape[1]}x{crop.shape[0]}")

# Preprocess to 32x32 with 15% padding
ch, cw = crop.shape
max_side = max(ch, cw)
pad = int(max_side * 0.15)
box_size = max_side + pad * 2

square = np.zeros((box_size, box_size), dtype=np.float32)
off_y = (box_size - ch) // 2
off_x = (box_size - cw) // 2
square[off_y:off_y+ch, off_x:off_x+cw] = crop

square_img = Image.fromarray((square * 255).astype(np.uint8)).resize((32, 32), Image.Resampling.BILINEAR)
u_raw = np.array(square_img, dtype=np.float32) / 255.0
u_active = np.sum(u_raw > 0.15)
print(f"User drawing active pixels in 32x32: {u_active}")

# Load character templates
with open('d:/Selva Mac/Projects/tamil/frontend/assets/ml/character_templates.json', 'r', encoding='utf-8') as f:
    d = json.load(f)

labels = d['labels']
templates = d['templates']

# Check how it scores against each template
for label in ['அ', 'ஆ', 'இ', 'ஈ', 'உ', 'ஊ', 'எ', 'ஏ', 'ஐ', 'ஒ', 'ஓ', 'க்', 'ங்', 'ச்', 'ட்', 'த்']:
    raw_list = templates[label]['raw']
    flat = []
    for item in raw_list:
        if isinstance(item, list):
            flat.extend(item)
        else:
            flat.append(item)
    t_raw = np.array(flat, dtype=np.float32).reshape((32, 32))
    t_active = np.sum(t_raw > 0.15)
    
    t_field = gaussian_filter(t_raw, sigma=1.5)
    norm_t = np.linalg.norm(t_field)
    if norm_t > 0: t_field /= norm_t
    
    u_field = gaussian_filter(u_raw, sigma=1.5)
    norm_u = np.linalg.norm(u_field)
    if norm_u > 0: u_field /= norm_u
    
    field_sim = float(np.sum(u_field * t_field))
    u_valid = np.sum((u_raw > 0.15) & (t_field > 0.010))
    prec = u_valid / u_active
    t_covered = np.sum((t_raw > 0.12) & (gaussian_filter(u_raw, sigma=1.5) > 0.015))
    rec = t_covered / t_active
    
    overlap = np.sum((u_raw > 0.15) & (t_raw > 0.12))
    union = u_active + t_active - overlap
    iou = overlap / union
    
    density_ratio = min(u_active / t_active, t_active / u_active)
    f1 = 2 * prec * rec / (prec + rec + 1e-6)
    
    score = (0.35 * field_sim + 0.30 * f1 + 0.20 * (iou * 2.0).clip(0, 1) + 0.15 * density_ratio)
    
    print(f"'{label}': score={score:.3f} (field_sim={field_sim:.3f}, prec={prec:.3f}, rec={rec:.3f}, f1={f1:.3f}, iou={iou:.3f}, dens={density_ratio:.3f})")
