import sys
import os
import json
import numpy as np

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

sys.path.append("ai_model/training")
from preprocess import preprocess_strokes_to_image

mockStrokesA = [
    # Top-left circle + loop
    [
        (120, 130), (100, 120), (90, 140), (110, 160),
        (140, 150), (170, 180), (180, 220), (170, 260),
        (140, 280), (110, 280),
    ],
    # Horizontal connector bar
    [
        (150, 220), (190, 220), (230, 220),
    ],
    # Right vertical stem
    [
        (230, 120), (230, 180), (230, 240), (230, 290),
    ],
]

raw_a = preprocess_strokes_to_image(mockStrokesA, canvas_size=(350, 350), target_size=(32, 32))

with open("frontend/assets/ml/character_templates.json", "r", encoding="utf-8") as f:
    data = json.load(f)

templates = data["templates"]

def smooth32x32(src, passes=1):
    from scipy.ndimage import gaussian_filter
    arr = np.array(src, dtype=np.float32)
    for _ in range(passes):
        arr = gaussian_filter(arr, sigma=0.8)
    return arr

u_tight = smooth32x32(raw_a, 1)
u_norm = u_tight / np.linalg.norm(u_tight)
u_active = (raw_a > 0.15).sum()

scores = []
for label in templates:
    protos = templates[label].get("prototypes", [templates[label]["raw"]])
    best_s = 0.0
    best_rec = 0.0
    best_prec = 0.0
    for p in protos:
        p_arr = np.array(p, dtype=np.float32)
        p_tight = smooth32x32(p_arr, 1)
        p_wide = smooth32x32(p_arr, 2)
        p_norm = p_tight / (np.linalg.norm(p_tight) + 1e-6)
        t_active = (p_arr > 0.15).sum()
        
        field_sim = float(np.sum(u_norm * p_norm))
        u_valid = float(((raw_a > 0.15) & (p_wide > 0.08)).sum())
        prec = u_valid / u_active if u_active > 0 else 0
        
        t_covered = float(((p_arr > 0.15) & (u_tight > 0.08)).sum())
        rec = t_covered / t_active if t_active > 0 else 0
        
        intersection = float(((raw_a > 0.15) & (p_arr > 0.15)).sum())
        union = float(u_active + t_active - intersection)
        iou = intersection / union if union > 0 else 0
        f1 = (2 * prec * rec) / (prec + rec) if (prec + rec) > 0 else 0
        density_ratio = min(u_active / t_active, t_active / u_active) if t_active > 0 and u_active > 0 else 0
        
        cov_gate = min(1.0, max(0.0, (rec - 0.12) / 0.25))
        prec_gate = min(1.0, max(0.0, (prec - 0.12) / 0.25))
        
        s = (0.35 * field_sim + 0.30 * f1 + 0.20 * min(1.0, iou * 2.0) + 0.15 * density_ratio) * cov_gate * prec_gate
        if s > best_s:
            best_s = s
            best_rec = rec
            best_prec = prec
            
    scores.append((label, best_s, best_prec, best_rec))

scores.sort(key=lambda x: x[1], reverse=True)
for label, s, prec, rec in scores[:10]:
    print(f"Label '{label}': score={s:.3f}, prec={prec:.2f}, rec={rec:.2f}")
