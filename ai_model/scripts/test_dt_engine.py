import sys
import os
import json
import numpy as np
from scipy.ndimage import distance_transform_edt
from PIL import Image, ImageDraw, ImageFont

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

sys.path.append("ai_model/training")
from preprocess import preprocess_strokes_to_image

# Let's load or generate clean canonical templates
font_path = "C:\\Windows\\Fonts\\Nirmala.ttc"
font = ImageFont.truetype(font_path, 120)

labels_file = "frontend/assets/ml/labels.txt"
with open(labels_file, "r", encoding="utf-8") as f:
    labels = [l.strip() for l in f if l.strip()]

def render_canonical_skeleton(char):
    img = Image.new("L", (256, 256), 0)
    draw = ImageDraw.Draw(img)
    bbox = draw.textbbox((0, 0), char, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text(((256 - tw) // 2 - bbox[0], (256 - th) // 2 - bbox[1]), char, font=font, fill=255)
    
    arr = np.array(img, dtype=np.uint8)
    coords = np.argwhere(arr > 30)
    if len(coords) == 0:
        return np.zeros((32, 32), dtype=np.float32)
    ymin, xmin = coords.min(axis=0)
    ymax, xmax = coords.max(axis=0)
    h = ymax - ymin + 1
    w = xmax - xmin + 1
    cropped = arr[ymin:ymax+1, xmin:xmax+1]
    
    max_side = max(w, h)
    pad = int(max_side * 0.15)
    box_size = max_side + pad * 2
    canvas = np.zeros((box_size, box_size), dtype=np.uint8)
    ox = (box_size - w) // 2
    oy = (box_size - h) // 2
    canvas[oy:oy+h, ox:ox+w] = cropped
    
    resized = Image.fromarray(canvas).resize((32, 32), Image.Resampling.BILINEAR)
    res_arr = np.array(resized, dtype=np.float32) / 255.0
    return res_arr

templates = {}
dt_maps = {} # Distance transform maps for each template: distance from each pixel to nearest template pixel

for l in labels:
    skel = render_canonical_skeleton(l)
    templates[l] = skel
    # Binary mask of template stroke
    mask = skel > 0.20
    if not mask.any():
        mask = skel > 0.10
    # distance to nearest mask pixel (0 at stroke, increasing away)
    dt = distance_transform_edt(~mask)
    dt_maps[l] = dt

print(f"Generated distance transforms for all {len(labels)} labels.")

def recognize_dt(raw_user, expected_letter):
    u_mask = raw_user > 0.20
    if not u_mask.any():
        u_mask = raw_user > 0.10
    if not u_mask.any():
        return False, "None", 0.0, 0.0, 0.0

    u_dt = distance_transform_edt(~u_mask)
    user_pts_count = u_mask.sum()

    results = []
    for l in labels:
        t_mask = templates[l] > 0.20
        if not t_mask.any():
            t_mask = templates[l] > 0.10
        t_pts_count = t_mask.sum()

        t_dt = dt_maps[l]

        # 1. Precision: How close are user points to template?
        # User points with distance <= 2.5 pixels to template
        u_dists = t_dt[u_mask]
        # Soft exponential distance score: exp(-d / 1.5)
        prec_score = float(np.mean(np.exp(-u_dists / 1.5)))
        prec_corridor = float((u_dists <= 2.5).sum() / user_pts_count)

        # 2. Recall: How close are template points to user drawing?
        t_dists = u_dt[t_mask]
        rec_score = float(np.mean(np.exp(-t_dists / 1.5)))
        rec_corridor = float((t_dists <= 2.5).sum() / t_pts_count)

        # F1 combination
        f1_soft = (2 * prec_score * rec_score) / (prec_score + rec_score) if (prec_score + rec_score) > 0 else 0.0
        f1_corridor = (2 * prec_corridor * rec_corridor) / (prec_corridor + rec_corridor) if (prec_corridor + rec_corridor) > 0 else 0.0

        final_score = 0.5 * f1_soft + 0.5 * f1_corridor
        results.append((l, final_score, prec_corridor, rec_corridor))

    results.sort(key=lambda x: x[1], reverse=True)
    top1 = results[0]
    exp = next(x for x in results if x[0] == expected_letter)

    is_winner = (top1[0] == expected_letter or exp[1] >= top1[1] - 0.03)
    is_match = is_winner and exp[1] >= 0.50 and exp[2] >= 0.50 and exp[3] >= 0.50

    return is_match, top1[0], exp[1], exp[2], exp[3]

# Let's test synthesized strokes from test_synthesized_strokes.py
from test_synthesized_strokes import raw_i, raw_aa, raw_oo, raw_au

print("\n--- Testing with Chamfer / DT Corridor Engine ---")
print("1. 'இ' strokes when expecting 'இ':", recognize_dt(raw_i, "இ"))
print("2. 'இ' strokes when expecting 'ஆ':", recognize_dt(raw_i, "ஆ"))
print("3. 'ஆ' strokes when expecting 'ஆ':", recognize_dt(raw_aa, "ஆ"))
print("4. 'ஆ' strokes when expecting 'இ':", recognize_dt(raw_aa, "இ"))
print("5. 'ஊ' strokes when expecting 'ஊ':", recognize_dt(raw_oo, "ஊ"))
print("6. 'ஔ' strokes when expecting 'ஔ':", recognize_dt(raw_au, "ஔ"))
