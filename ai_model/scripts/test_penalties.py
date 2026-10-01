from test_cv2_thinning import *
raw_a = preprocess_strokes_to_image(mockStrokesA, canvas_size=(350, 350), target_size=(32, 32))
u_mask = raw_a > 0.15
u_dt = distance_transform_edt(~u_mask)
u_pts = int(u_mask.sum())

scores = []
for l in labels:
    t_mask = thin_templates[l] > 0.15
    t_pts = int(t_mask.sum())
    t_dt = dt_maps[l]
    
    u_dists = t_dt[u_mask]
    prec = float((u_dists <= 2.5).sum() / u_pts) if u_pts > 0 else 0
    t_dists = u_dt[t_mask]
    rec = float((t_dists <= 2.5).sum() / t_pts) if t_pts > 0 else 0
    
    # Extra spurious user ink penalty (pixels that are far d > 3.5 from template)
    spurious = float((u_dists > 3.5).sum() / u_pts) if u_pts > 0 else 0
    missing = float((t_dists > 3.5).sum() / t_pts) if t_pts > 0 else 0
    
    f1 = (2 * prec * rec) / (prec + rec) if (prec + rec) > 0 else 0
    score = f1 * (1.0 - 0.5 * spurious) * (1.0 - 0.5 * missing)
    scores.append((l, score, prec, rec, spurious, missing))

scores.sort(key=lambda x: x[1], reverse=True)
print("Scores with Spurious / Missing Stroke Penalties:")
for l, s, prec, rec, spur, miss in scores[:10]:
    print(f"  '{l}': score={s:.3f}, prec={prec:.2f}, rec={rec:.2f}, spur={spur:.2f}, miss={miss:.2f}")
