from test_cv2_thinning import *

# Let's extract the actual app stroke path for 'அ' from TamilStrokeDataRepository:
appStrokesA = [
    # Stroke 1: loop + body
    [
        (0.32 * 350, 0.36 * 350), (0.28 * 350, 0.31 * 350), (0.23 * 350, 0.36 * 350),
        (0.27 * 350, 0.42 * 350), (0.33 * 350, 0.39 * 350), (0.38 * 350, 0.30 * 350),
        (0.46 * 350, 0.23 * 350), (0.55 * 350, 0.23 * 350), (0.62 * 350, 0.30 * 350),
        (0.61 * 350, 0.40 * 350), (0.54 * 350, 0.48 * 350), (0.45 * 350, 0.54 * 350),
        (0.33 * 350, 0.61 * 350), (0.26 * 350, 0.70 * 350), (0.29 * 350, 0.78 * 350),
        (0.40 * 350, 0.81 * 350), (0.54 * 350, 0.81 * 350), (0.70 * 350, 0.78 * 350),
    ],
    # Stroke 2: horizontal bar
    [
        (0.45 * 350, 0.54 * 350), (0.58 * 350, 0.54 * 350), (0.70 * 350, 0.54 * 350),
    ],
    # Stroke 3: vertical stem
    [
        (0.70 * 350, 0.22 * 350), (0.70 * 350, 0.54 * 350), (0.70 * 350, 0.80 * 350),
    ]
]

raw_app_a = preprocess_strokes_to_image(appStrokesA, canvas_size=(350, 350), target_size=(32, 32))
u_mask = raw_app_a > 0.15
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
    
    spurious = float((u_dists > 3.5).sum() / u_pts) if u_pts > 0 else 0
    missing = float((t_dists > 3.5).sum() / t_pts) if t_pts > 0 else 0
    
    f1 = (2 * prec * rec) / (prec + rec) if (prec + rec) > 0 else 0
    score = f1 * (1.0 - 0.5 * spurious) * (1.0 - 0.5 * missing)
    scores.append((l, score, prec, rec, spurious, missing))

scores.sort(key=lambda x: x[1], reverse=True)
print("Scores for Canonical TamilStrokeDataRepository 'அ':")
for l, s, prec, rec, spur, miss in scores[:10]:
    print(f"  '{l}': score={s:.3f}, prec={prec:.2f}, rec={rec:.2f}, spur={spur:.2f}, miss={miss:.2f}")
