import sys
if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')
import json
import numpy as np
from scipy.ndimage import gaussian_filter

with open("frontend/assets/ml/character_templates.json", "r", encoding="utf-8") as f:
    data = json.load(f)

templates = data["templates"]
labels = data["labels"]

sys.path.append("ai_model/training")
from preprocess import preprocess_strokes_to_image
from generate_canonical_31_templates import canonical_strokes_bank

def jitter_strokes(strokes, offset_x=15, offset_y=-10, scale=0.92):
    res = []
    for s in strokes:
        res_s = []
        for x, y in s:
            nx = (x - 175) * scale + 175 + offset_x
            ny = (y - 175) * scale + 175 + offset_y
            res_s.append((nx, ny))
        res.append(res_s)
    return res

strokes_ch = canonical_strokes_bank["ச்"][0]
j_strokes = jitter_strokes(strokes_ch, 15, -10, 0.92)

raw_tensor = preprocess_strokes_to_image(j_strokes, canvas_size=(350, 350), target_size=(32, 32))
flat_tensor = raw_tensor.flatten()
user_active = np.sum(flat_tensor > 0.15)
u_tight = gaussian_filter(raw_tensor, sigma=0.8).flatten()
norm_ut = np.linalg.norm(u_tight)
u_field_tight = u_tight / norm_ut if norm_ut > 0 else u_tight

for label in ["ச்", "க்"]:
    tdata = templates[label]
    proto = tdata.get("prototypes", [tdata.get("raw")])[0]
    t_raw = np.array(proto, dtype=np.float32).flatten()
    t_tight = gaussian_filter(np.array(proto, dtype=np.float32), sigma=0.8).flatten()
    t_wide = gaussian_filter(np.array(proto, dtype=np.float32), sigma=1.6).flatten()
    norm_t = np.linalg.norm(t_tight)
    t_norm = t_tight / norm_t if norm_t > 0 else t_tight
    t_active = np.sum(t_raw > 0.15)

    field_sim = np.clip(np.dot(u_field_tight, t_norm), 0.0, 1.0)
    u_valid = np.sum((flat_tensor > 0.15) & (t_wide > 0.08))
    precision = u_valid / user_active if user_active > 0 else 0.0

    t_cov = np.sum((t_raw > 0.15) & (u_tight > 0.08))
    recall = t_cov / t_active if t_active > 0 else 0.0

    intersection = np.sum((flat_tensor > 0.15) & (t_raw > 0.15))
    union = user_active + t_active - intersection
    iou = intersection / union if union > 0 else 0.0
    f1 = (2 * precision * recall / (precision + recall)) if (precision + recall) > 0 else 0.0
    density_ratio = min(user_active / t_active, t_active / user_active)

    cov_gate = min(1.0, max(0.0, (recall - 0.12) / 0.25))
    prec_gate = min(1.0, max(0.0, (precision - 0.12) / 0.25))

    score = (0.35 * field_sim + 0.30 * f1 + 0.20 * min(1.0, iou * 2.0) + 0.15 * density_ratio) * cov_gate * prec_gate
    print(f"Label: {label} -> fieldSim: {field_sim:.3f}, f1: {f1:.3f}, iou: {iou:.3f}, density: {density_ratio:.3f}, recall: {recall:.3f}, prec: {precision:.3f}, SCORE: {score:.3f}")
