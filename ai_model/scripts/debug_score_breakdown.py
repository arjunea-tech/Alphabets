import sys
import numpy as np
from test_engine_simulation import mockStrokesA, preprocess_strokes_to_image, smooth32x32, raw_fields, tight_fields, wide_fields, norm_fields, actives, templates

raw_tensor = preprocess_strokes_to_image(mockStrokesA, canvas_size=(350, 350), target_size=(32, 32))
u_tight = smooth32x32(raw_tensor, 1)
norm_u = np.linalg.norm(u_tight)
u_norm = u_tight / norm_u if norm_u > 0 else u_tight
u_active = (raw_tensor > 0.15).sum()

for label in ["அ", "ஆ", "இ", "ஐ", "எ"]:
    t_raw = raw_fields[label]
    t_tight = tight_fields[label]
    t_wide = wide_fields[label]
    t_norm = norm_fields[label]
    t_active = actives[label]

    field_sim = float(np.sum(u_norm * t_norm))
    u_valid = float(((raw_tensor > 0.15) & (t_wide > 0.08)).sum())
    prec = u_valid / u_active if u_active > 0 else 0
    
    t_covered = float(((t_raw > 0.15) & (u_tight > 0.08)).sum())
    rec = t_covered / t_active if t_active > 0 else 0
    
    intersection = float(((raw_tensor > 0.15) & (t_raw > 0.15)).sum())
    union = float(u_active + t_active - intersection)
    iou = intersection / union if union > 0 else 0
    f1 = (2 * prec * rec) / (prec + rec) if (prec + rec) > 0 else 0
    density_ratio = min(u_active / t_active, t_active / u_active) if t_active > 0 and u_active > 0 else 0
    
    cov_gate = min(1.0, max(0.0, (rec - 0.10) / 0.25))
    prec_gate = min(1.0, max(0.0, (prec - 0.10) / 0.25))
    
    raw_s = (0.35 * field_sim + 0.30 * f1 + 0.20 * min(1.0, iou * 2.0) + 0.15 * density_ratio)
    score = raw_s * cov_gate * prec_gate
    print(f"Letter '{label}': raw_s={raw_s:.3f}, score={score:.3f}, fsim={field_sim:.3f}, f1={f1:.3f}, iou={iou:.3f}, density={density_ratio:.3f}, prec={prec:.2f}, rec={rec:.2f}, cov_gate={cov_gate:.2f}, prec_gate={prec_gate:.2f}")
