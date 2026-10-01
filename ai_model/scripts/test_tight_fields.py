import sys
import numpy as np
from test_std_a import preprocess_strokes_to_image, smooth32x32, templates, standardStrokesA

raw_std_a = preprocess_strokes_to_image(standardStrokesA, canvas_size=(350, 350), target_size=(32, 32))
u_tight = smooth32x32(raw_std_a, 1)
u_norm = u_tight / np.linalg.norm(u_tight)
u_active = (raw_std_a > 0.15).sum()

scores = []
for label in templates:
    t_raw = np.array(templates[label]["raw"], dtype=np.float32)
    t_tight = smooth32x32(t_raw, 1)
    t_norm = t_tight / (np.linalg.norm(t_tight) + 1e-6)
    t_active = (t_raw > 0.15).sum()
    
    # 1. Cosine similarity of the stroke energy fields
    cos_sim = float(np.sum(u_norm * t_norm))
    
    # 2. Precision: user ink within tight 1-pixel tolerance
    u_valid = float(((raw_std_a > 0.15) & (t_tight > 0.15)).sum())
    prec = u_valid / u_active if u_active > 0 else 0
    
    # 3. Recall: template ink covered within tight 1-pixel tolerance
    t_covered = float(((t_raw > 0.15) & (u_tight > 0.15)).sum())
    rec = t_covered / t_active if t_active > 0 else 0
    
    # 4. IoU of tight fields
    intersection = float(np.sum(np.minimum(u_tight, t_tight)))
    union = float(np.sum(np.maximum(u_tight, t_tight)))
    field_iou = intersection / union if union > 0 else 0
    
    f1 = (2 * prec * rec) / (prec + rec) if (prec + rec) > 0 else 0
    
    score = 0.40 * cos_sim + 0.35 * field_iou + 0.25 * f1
    scores.append((label, score, cos_sim, field_iou, prec, rec))

scores.sort(key=lambda x: x[1], reverse=True)
print("Scores with Tight Field IoU and Cosine Matching:")
for label, s, csim, fiou, prec, rec in scores[:10]:
    print(f"  '{label}': score={s:.3f}, cos={csim:.3f}, iou={fiou:.3f}, prec={prec:.2f}, rec={rec:.2f}")
