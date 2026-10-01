import sys
import numpy as np
from scipy.ndimage import distance_transform_edt
from test_engine_simulation import mockStrokesA, preprocess_strokes_to_image, templates

raw_tensor = preprocess_strokes_to_image(mockStrokesA, canvas_size=(350, 350), target_size=(32, 32))
u_mask = raw_tensor > 0.15
u_dt = distance_transform_edt(~u_mask)
u_pts = int(u_mask.sum())

scores = []
for label in templates:
    t_raw = np.array(templates[label]["raw"], dtype=np.float32)
    t_mask = t_raw > 0.15
    t_dt = distance_transform_edt(~t_mask)
    t_pts = int(t_mask.sum())
    
    # 1. User points distance to template
    u_dists = t_dt[u_mask]
    # Fraction within 2.5 pixels
    prec = float((u_dists <= 2.5).sum() / u_pts)
    prec_soft = float(np.mean(np.exp(- (u_dists / 2.0) ** 2)))
    
    # 2. Template points distance to user
    t_dists = u_dt[t_mask]
    rec = float((t_dists <= 2.5).sum() / t_pts)
    rec_soft = float(np.mean(np.exp(- (t_dists / 2.0) ** 2)))
    
    f1 = (2 * prec * rec) / (prec + rec) if (prec + rec) > 0 else 0
    f1_soft = (2 * prec_soft * rec_soft) / (prec_soft + rec_soft) if (prec_soft + rec_soft) > 0 else 0
    
    s = 0.5 * f1 + 0.5 * f1_soft
    scores.append((label, s, prec, rec))

scores.sort(key=lambda x: x[1], reverse=True)
print("Scores with Distance Transform / Chamfer:")
for label, s, prec, rec in scores[:10]:
    print(f"  '{label}': score={s:.3f}, prec={prec:.2f}, rec={rec:.2f}")
