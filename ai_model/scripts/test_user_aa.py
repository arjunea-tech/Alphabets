import sys, os, json, numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

sys.stdout.reconfigure(encoding='utf-8')

img_path = "C:/Users/welcome/.gemini/antigravity-ide/brain/e81763e3-2bd6-4287-88d5-538a0eefe1bd/.user_uploaded/media_1790675671736.png"
print("Loading:", img_path)

img = Image.open(img_path).convert('RGB')
img_np = np.array(img)
canvas_crop = img_np[290:630, 25:295]
r, g, b = canvas_crop[:,:,0].astype(int), canvas_crop[:,:,1].astype(int), canvas_crop[:,:,2].astype(int)
blue_mask = (b > 180) & (b > r + 60) & (b > g + 40)

y_indices, x_indices = np.where(blue_mask)
min_y, max_y = np.min(y_indices), np.max(y_indices)
min_x, max_x = np.min(x_indices), np.max(x_indices)

crop = blue_mask[min_y:max_y+1, min_x:max_x+1].astype(np.float32)
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

with open('d:/Selva Mac/Projects/tamil/frontend/assets/ml/character_templates.json', 'r', encoding='utf-8') as f:
    d = json.load(f)

labels = d['labels']
templates = d['templates']

tpl_raw = {}
tpl_field_tight = {}
tpl_field_wide = {}
tpl_active = {}

for label in labels:
    raw_list = templates[label]['raw']
    flat = []
    for item in raw_list:
        if isinstance(item, list): flat.extend(item)
        else: flat.append(item)
    raw = np.array(flat, dtype=np.float32).reshape((32, 32))
    tpl_raw[label] = raw
    tpl_active[label] = np.sum(raw > 0.15)
    f_tight = gaussian_filter(raw, sigma=1.2)
    norm_t = np.linalg.norm(f_tight)
    tpl_field_tight[label] = f_tight / norm_t if norm_t > 0 else f_tight
    f_wide = gaussian_filter(raw, sigma=2.0)
    norm_w = np.linalg.norm(f_wide)
    tpl_field_wide[label] = f_wide / norm_w if norm_w > 0 else f_wide

u_tight = gaussian_filter(u_raw, sigma=1.2)
norm_ut = np.linalg.norm(u_tight)
u_field_tight = u_tight / norm_ut if norm_ut > 0 else u_tight
u_direct_blur = gaussian_filter(u_raw, sigma=1.0)

candidates = []
for label in labels:
    t_raw = tpl_raw[label]
    t_tight = tpl_field_tight[label]
    t_wide = tpl_field_wide[label]
    t_active = tpl_active[label]
    if t_active == 0: continue
    
    field_sim = float(np.sum(u_field_tight * t_tight))
    field_sim = max(0.0, min(1.0, field_sim))
    
    u_valid = np.sum((u_raw > 0.15) & (t_wide > 0.015))
    precision = u_valid / (u_active + 1e-6)
    
    t_covered = np.sum((t_raw > 0.12) & (u_direct_blur > 0.03))
    recall = t_covered / (t_active + 1e-6)
    
    overlap = np.sum((u_raw > 0.15) & (t_raw > 0.12))
    union = u_active + t_active - overlap
    iou = overlap / union if union > 0 else 0.0
    
    density_ratio = min(u_active / t_active, t_active / u_active)
    f1 = (2 * precision * recall / (precision + recall)) if (precision + recall) > 0 else 0.0
    
    coverage_gate = min(1.0, max(0.0, (recall - 0.15) / 0.20))
    precision_gate = min(1.0, max(0.0, (precision - 0.20) / 0.25))
    
    score = (0.35 * field_sim + 0.30 * f1 + 0.20 * (iou * 2.0).clip(0, 1) + 0.15 * density_ratio) * coverage_gate * precision_gate
    candidates.append({'character': label, 'confidence': float(np.clip(score, 0.0, 1.0))})

candidates.sort(key=lambda x: x['confidence'], reverse=True)
print("Top 5 predictions on user's drawing:")
for c in candidates[:5]:
    print(f"  {c['character']}: {c['confidence']:.3f}")
