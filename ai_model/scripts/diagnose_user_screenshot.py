import sys
import os
import json
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

sys.stdout.reconfigure(encoding='utf-8')

img_path = "C:/Users/welcome/.gemini/antigravity-ide/brain/e81763e3-2bd6-4287-88d5-538a0eefe1bd/.user_uploaded/media_1790674269146.png"

print("Loading screenshot from:", img_path)
img = Image.open(img_path).convert('RGB')
img_np = np.array(img)

# Find blue pixels in the canvas area
r, g, b = img_np[:,:,0].astype(int), img_np[:,:,1].astype(int), img_np[:,:,2].astype(int)
# Blue brush is ~ #3A86FF (R: 58, G: 134, B: 255)
# Let's find pixels where B > 200 and B > R + 60 and B > G + 40
blue_mask = (b > 180) & (b > r + 60) & (b > g + 40)

y_indices, x_indices = np.where(blue_mask)
print("Found blue pixels:", len(y_indices))

min_y, max_y = np.min(y_indices), np.max(y_indices)
min_x, max_x = np.min(x_indices), np.max(x_indices)

# Only within canvas area
crop = blue_mask[min_y:max_y+1, min_x:max_x+1].astype(np.float32)
print(f"Detected drawing bbox: {crop.shape}")

# Preprocess crop to 32x32 with 15% padding
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
print("Preprocessed user drawing active pixels:", u_active)

# Load templates
with open('d:/Selva Mac/Projects/tamil/frontend/assets/ml/character_templates.json', 'r', encoding='utf-8') as f:
    d = json.load(f)

labels = d['labels']
templates = d['templates']

tpl_raw = {}
tpl_field = {}
tpl_active = {}

for label in labels:
    raw_list = templates[label]['raw']
    flat = []
    for item in raw_list:
        if isinstance(item, list):
            flat.extend(item)
        else:
            flat.append(item)
    raw = np.array(flat, dtype=np.float32).reshape((32, 32))
    tpl_raw[label] = raw
    tpl_active[label] = np.sum(raw > 0.15)
    
    field = gaussian_filter(raw, sigma=1.2)
    norm = np.linalg.norm(field)
    if norm > 0:
        field = field / norm
    tpl_field[label] = field

def smooth_32x32(raw, sigma=1.2):
    field = gaussian_filter(raw, sigma=sigma)
    norm = np.linalg.norm(field)
    return field / norm if norm > 0 else field

u_field = smooth_32x32(u_raw, sigma=1.2)

scores = []
for label in labels:
    t_raw = tpl_raw[label]
    t_field = tpl_field[label]
    t_active = tpl_active[label]
    
    field_sim = float(np.sum(u_field * t_field))
    
    u_valid_ink = np.sum((u_raw > 0.15) & (t_field > 0.015))
    precision = u_valid_ink / (u_active + 1e-6)
    
    t_covered_ink = np.sum((t_raw > 0.12) & (gaussian_filter(u_raw, sigma=1.2) > 0.02))
    recall = t_covered_ink / (t_active + 1e-6)
    
    intersection = np.sum((u_raw > 0.15) & (t_raw > 0.12))
    union = u_active + t_active - intersection
    iou = intersection / union if union > 0 else 0.0
    
    density_ratio = min(u_active / t_active, t_active / u_active)
    
    coverage_gate = min(1.0, max(0.0, (recall - 0.15) / 0.30))
    precision_gate = min(1.0, max(0.0, (precision - 0.15) / 0.30))
    f1 = (2 * precision * recall / (precision + recall)) if (precision + recall) > 0 else 0.0
    
    score = (0.35 * field_sim + 0.30 * f1 + 0.20 * (iou * 2.0).clip(0, 1) + 0.15 * density_ratio) * coverage_gate * precision_gate
    scores.append((label, score, field_sim, precision, recall, f1, iou, density_ratio))

scores.sort(key=lambda x: x[1], reverse=True)
print("\n--- RESULTS ON USER'S EXACT DRAWING OF 'அ' ---")
for s in scores[:10]:
    print(f"Label '{s[0]}': score={s[1]:.3f} (field_sim={s[2]:.3f}, prec={s[3]:.3f}, rec={s[4]:.3f}, f1={s[5]:.3f}, iou={s[6]:.3f}, dens={s[7]:.3f})")
