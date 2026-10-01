import sys, os, json, numpy as np
from scipy.ndimage import gaussian_filter

sys.stdout.reconfigure(encoding='utf-8')
sys.path.append('d:/Selva Mac/Projects/tamil/ai_model/training')
from preprocess import preprocess_strokes_to_image

with open('d:/Selva Mac/Projects/tamil/frontend/assets/ml/character_templates.json', 'r', encoding='utf-8') as f:
    d = json.load(f)

labels = d['labels']
templates = d['templates']

mockStrokesA = [
    # Top loop and right arch
    [
        (100, 80),
        (80, 100),
        (100, 120),
        (120, 100),
        (100, 80),
        (140, 80),
        (160, 110),
        (160, 160),
    ],
    # Hook curving rightward
    [
        (160, 160),
        (130, 200),
        (110, 230),
        (130, 250),
        (160, 230),
        (180, 180),
        (260, 180),
    ],
    # Right vertical stem
    [
        (260, 80),
        (260, 180),
        (260, 260),
    ],
]

u_arr = preprocess_strokes_to_image(mockStrokesA, canvas_size=(350, 350))

# Precompute templates
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
    
    field = gaussian_filter(raw, sigma=1.0)
    norm = np.linalg.norm(field)
    if norm > 0:
        field = field / norm
    tpl_field[label] = field

def smooth_32x32(raw):
    kernel = np.array([[1, 2, 1], [2, 4, 2], [1, 2, 1]], dtype=np.float32) / 16.0
    from scipy.signal import convolve2d
    return convolve2d(raw, kernel, mode='same', boundary='symm')

u_active = np.sum(u_arr > 0.15)
u_smoothed = smooth_32x32(u_arr)
norm_u = np.linalg.norm(u_smoothed)
u_field = u_smoothed / norm_u if norm_u > 0 else u_smoothed

scores = []
for label in labels:
    t_raw = tpl_raw[label]
    t_field = tpl_field[label]
    t_active = tpl_active[label]
    
    field_sim = float(np.sum(u_field * t_field))
    
    u_valid_ink = np.sum((u_arr > 0.15) & (t_field > 0.015))
    precision = u_valid_ink / u_active if u_active > 0 else 0.0
    
    t_covered_ink = np.sum((t_raw > 0.12) & (u_smoothed > 0.02))
    recall = t_covered_ink / t_active if t_active > 0 else 0.0
    
    intersection = np.sum((u_arr > 0.15) & (t_raw > 0.12))
    union = u_active + t_active - intersection
    iou = intersection / union if union > 0 else 0.0
    
    density_ratio = min(u_active / t_active, t_active / u_active)
    coverage_gate = min(1.0, max(0.0, (recall - 0.15) / 0.30))
    precision_gate = min(1.0, max(0.0, (precision - 0.15) / 0.30))
    f1 = (2 * precision * recall / (precision + recall)) if (precision + recall) > 0 else 0.0
    
    score = (0.35 * field_sim + 0.30 * f1 + 0.20 * (iou * 2.0).clip(0, 1) + 0.15 * density_ratio) * coverage_gate * precision_gate
    scores.append((label, score, f1, precision, recall, field_sim))

scores.sort(key=lambda x: x[1], reverse=True)
print("Top 5 for handwritten 'அ':")
for s in scores[:5]:
    print(f"  {s[0]}: score={s[1]:.3f}, f1={s[2]:.3f}, prec={s[3]:.3f}, rec={s[4]:.3f}, field_sim={s[5]:.3f}")
