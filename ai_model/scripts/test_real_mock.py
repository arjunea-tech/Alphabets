import sys
import os
import json
import numpy as np

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

sys.path.append("ai_model/training")
from preprocess import preprocess_strokes_to_image

mockStrokesA = [
    # 1. Top starting loop and upper arch
    [
        (160, 70), (140, 90), (160, 110), (180, 90),
        (160, 70), (195, 70), (210, 95), (210, 135),
    ],
    # 2. Swooping bottom hook going left and connecting right
    [
        (210, 135), (180, 175), (130, 215), (90, 240),
        (70, 260), (95, 275), (135, 260), (175, 200), (250, 200),
    ],
    # 3. Right vertical stem
    [
        (250, 70), (250, 200), (250, 280),
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
    t_raw = np.array(templates[label]["raw"], dtype=np.float32)
    t_tight = smooth32x32(t_raw, 1)
    t_wide = smooth32x32(t_raw, 2)
    t_norm = t_tight / (np.linalg.norm(t_tight) + 1e-6)
    t_active = (t_raw > 0.15).sum()
    
    field_sim = float(np.sum(u_norm * t_norm))
    u_valid = float(((raw_a > 0.15) & (t_wide > 0.08)).sum())
    prec = u_valid / u_active if u_active > 0 else 0
    
    t_covered = float(((t_raw > 0.15) & (u_tight > 0.08)).sum())
    rec = t_covered / t_active if t_active > 0 else 0
    
    intersection = float(((raw_a > 0.15) & (t_raw > 0.15)).sum())
    union = float(u_active + t_active - intersection)
    iou = intersection / union if union > 0 else 0
    f1 = (2 * prec * rec) / (prec + rec) if (prec + rec) > 0 else 0
    density_ratio = min(u_active / t_active, t_active / u_active) if t_active > 0 and u_active > 0 else 0
    
    cov_gate = min(1.0, max(0.0, (rec - 0.12) / 0.25))
    prec_gate = min(1.0, max(0.0, (prec - 0.12) / 0.25))
    
    s = (0.35 * field_sim + 0.30 * f1 + 0.20 * min(1.0, iou * 2.0) + 0.15 * density_ratio) * cov_gate * prec_gate
    scores.append((label, s, prec, rec, field_sim))

scores.sort(key=lambda x: x[1], reverse=True)
print("Candidate scores for real mockStrokesA in test:")
for label, s, prec, rec, fsim in scores[:10]:
    print(f"  '{label}': score={s:.3f}, prec={prec:.2f}, rec={rec:.2f}, fsim={fsim:.3f}")
