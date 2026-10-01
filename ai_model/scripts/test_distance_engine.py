import sys
import os
import json
import numpy as np
from scipy.ndimage import distance_transform_edt, gaussian_filter
from PIL import Image, ImageDraw, ImageFont

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

sys.path.append("ai_model/training")
from preprocess import preprocess_strokes_to_image, preprocess_image

font_path = "C:\\Windows\\Fonts\\Nirmala.ttc"
font = ImageFont.truetype(font_path, 110)

labels_file = "frontend/assets/ml/labels.txt"
with open(labels_file, "r", encoding="utf-8") as f:
    labels = [l.strip() for l in f if l.strip()]

def render_clean_template(char):
    # For compound characters, ensure both components are well-proportioned
    img = Image.new("L", (256, 256), 0)
    draw = ImageDraw.Draw(img)
    bbox = draw.textbbox((0, 0), char, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text(((256 - tw) // 2 - bbox[0], (256 - th) // 2 - bbox[1]), char, font=font, fill=255)
    return preprocess_image(img, target_size=(32, 32))

templates_raw = {}
dt_maps = {}

for l in labels:
    raw = render_clean_template(l)
    templates_raw[l] = raw
    mask = raw > 0.18
    if not mask.any():
        mask = raw > 0.10
    dt_maps[l] = distance_transform_edt(~mask)

print(f"Generated clean distance-field templates for {len(labels)} classes.")

def evaluate_handwriting(user_raw, expected_letter):
    u_mask = user_raw > 0.18
    if not u_mask.any():
        u_mask = user_raw > 0.10
    if not u_mask.any():
        return {"match": False, "top1": "None", "score": 0.0, "reason": "Empty"}

    u_dt = distance_transform_edt(~u_mask)
    u_pts_count = int(u_mask.sum())

    # Density / pixel count check
    if u_pts_count < 25 or u_pts_count > 420:
        return {"match": False, "top1": "None", "score": 0.0, "reason": "Density"}

    candidates = []
    for l in labels:
        t_raw = templates_raw[l]
        t_mask = t_raw > 0.18
        if not t_mask.any():
            t_mask = t_raw > 0.10
        t_pts_count = int(t_mask.sum())
        t_dt = dt_maps[l]

        # 1. Precision: User points falling within distance d of template
        u_dists = t_dt[u_mask]
        # Soft exponential distance score: exp(- (d / 2.2)^2)
        prec_soft = float(np.mean(np.exp(- (u_dists / 2.2) ** 2)))
        prec_corridor = float((u_dists <= 2.8).sum() / u_pts_count)

        # 2. Recall: Template points covered within distance d of user strokes
        t_dists = u_dt[t_mask]
        rec_soft = float(np.mean(np.exp(- (t_dists / 2.2) ** 2)))
        rec_corridor = float((t_dists <= 2.8).sum() / t_pts_count)

        # 3. Structural Quadrant Agreement (Top-Left, Top-Right, Bottom-Left, Bottom-Right)
        u_quad = [
            float(u_mask[:16, :16].sum()), float(u_mask[:16, 16:].sum()),
            float(u_mask[16:, :16].sum()), float(u_mask[16:, 16:].sum())
        ]
        u_quad_norm = np.array(u_quad) / (u_pts_count + 1e-5)

        t_quad = [
            float(t_mask[:16, :16].sum()), float(t_mask[:16, 16:].sum()),
            float(t_mask[16:, :16].sum()), float(t_mask[16:, 16:].sum())
        ]
        t_quad_norm = np.array(t_quad) / (t_pts_count + 1e-5)
        quad_sim = float(np.sum(np.minimum(u_quad_norm, t_quad_norm)))

        # Combined F1 & Shape score
        f1_soft = (2 * prec_soft * rec_soft) / (prec_soft + rec_soft) if (prec_soft + rec_soft) > 0 else 0.0
        f1_corridor = (2 * prec_corridor * rec_corridor) / (prec_corridor + rec_corridor) if (prec_corridor + rec_corridor) > 0 else 0.0
        
        score = (0.50 * f1_soft + 0.35 * f1_corridor + 0.15 * quad_sim)
        candidates.append({
            "letter": l,
            "score": score,
            "prec": prec_corridor,
            "rec": rec_corridor,
            "quad": quad_sim
        })

    candidates.sort(key=lambda c: c["score"], reverse=True)
    top1 = candidates[0]
    exp = next(c for c in candidates if c["letter"] == expected_letter)

    # Match decision:
    # Must be top-1 winner (strict top-1)
    is_winner = (top1["letter"] == expected_letter)
    is_match = is_winner and exp["score"] >= 0.52 and exp["prec"] >= 0.52 and exp["rec"] >= 0.50

    return {
        "match": is_match,
        "top1": top1["letter"],
        "top1_score": top1["score"],
        "exp_score": exp["score"],
        "exp_prec": exp["prec"],
        "exp_rec": exp["rec"]
    }

# Let's test with synthesized strokes
from test_synthesized_strokes import raw_i, raw_aa, raw_oo, raw_au

print("\n--- Testing Strict Multi-Scale Distance Transform Engine ---")
print("1. 'இ' strokes when expecting 'இ':", evaluate_handwriting(raw_i, "இ"))
print("2. 'இ' strokes when expecting 'ஆ' (must FAIL):", evaluate_handwriting(raw_i, "ஆ"))
print("3. 'ஆ' strokes when expecting 'ஆ':", evaluate_handwriting(raw_aa, "ஆ"))
print("4. 'ஆ' strokes when expecting 'இ' (must FAIL):", evaluate_handwriting(raw_aa, "இ"))
print("5. 'ஊ' strokes when expecting 'ஊ':", evaluate_handwriting(raw_oo, "ஊ"))
print("6. 'ஔ' strokes when expecting 'ஔ':", evaluate_handwriting(raw_au, "ஔ"))
print("7. 'உ' strokes when expecting 'ஊ' (must FAIL):", evaluate_handwriting(templates_raw["உ"], "ஊ"))
print("8. 'ஒ' strokes when expecting 'ஔ' (must FAIL):", evaluate_handwriting(templates_raw["ஒ"], "ஔ"))
print("9. 'அ' strokes when expecting 'ஆ' (must FAIL):", evaluate_handwriting(templates_raw["அ"], "ஆ"))
print("10. 'ஆ' strokes when expecting 'அ' (must FAIL):", evaluate_handwriting(templates_raw["ஆ"], "அ"))
