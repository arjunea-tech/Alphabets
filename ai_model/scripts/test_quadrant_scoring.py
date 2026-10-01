import sys
import os
import json
import numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import gaussian_filter

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

def main():
    with open('d:/Selva Mac/Projects/tamil/frontend/assets/ml/character_templates.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    tpl_a_raw = np.array(data['templates']['அ']['raw'], dtype=np.float32)
    tpl_a_field = np.array(data['templates']['அ']['field'], dtype=np.float32)

    # 1. Single vertical line drawn on 200x200 canvas and scaled to 32x32 (thick stroke)
    img_line = Image.new("L", (200, 200), 0)
    d_line = ImageDraw.Draw(img_line)
    d_line.line([100, 20, 100, 180], fill=255, width=16)
    arr_line = np.array(img_line.resize((32, 32), Image.Resampling.BILINEAR), dtype=np.float32) / 255.0

    # 2. Scribble / random lines
    img_sc = Image.new("L", (200, 200), 0)
    d_sc = ImageDraw.Draw(img_sc)
    d_sc.line([20, 20, 180, 180], fill=255, width=16)
    d_sc.line([20, 180, 180, 20], fill=255, width=16)
    arr_sc = np.array(img_sc.resize((32, 32), Image.Resampling.BILINEAR), dtype=np.float32) / 255.0

    # 3. Proper 'அ' drawing (loop + bar + stem)
    img_a = Image.new("L", (200, 200), 0)
    d_a = ImageDraw.Draw(img_a)
    d_a.ellipse([25, 25, 80, 80], outline=255, width=16) # Loop
    d_a.line([50, 100, 160, 100], fill=255, width=16)    # Bar
    d_a.line([160, 25, 160, 175], fill=255, width=16)    # Stem
    arr_a = np.array(img_a.resize((32, 32), Image.Resampling.BILINEAR), dtype=np.float32) / 255.0

    def evaluate_handwriting(user_arr, tpl_raw, tpl_field):
        # 1. Stroke count & spatial quadrant coverage (top-left, top-right, bottom-left, bottom-right)
        tl = np.sum(user_arr[0:16, 0:16])
        tr = np.sum(user_arr[0:16, 16:32])
        bl = np.sum(user_arr[16:32, 0:16])
        br = np.sum(user_arr[16:32, 16:32])
        quadrant_count = sum(1 for q in [tl, tr, bl, br] if q > 1.0)

        # 2. Continuous Gaussian field correlation
        u_blur = gaussian_filter(user_arr, sigma=1.2)
        norm_u = np.linalg.norm(u_blur)
        if norm_u > 0:
            u_blur = u_blur / norm_u

        cos_sim = float(np.sum(u_blur * tpl_field))

        # 3. Structural spatial overlap
        u_bin = user_arr > 0.15
        t_bin = tpl_raw > 0.15
        overlap = np.sum(u_bin * t_bin)
        u_area = np.sum(u_bin)
        t_area = np.sum(t_bin)
        recall = overlap / t_area if t_area > 0 else 0
        precision = overlap / u_area if u_area > 0 else 0
        iou = overlap / np.sum(u_bin | t_bin) if np.sum(u_bin | t_bin) > 0 else 0

        # For 'அ', it must have ink in at least 3 quadrants (loop in TL, bar in BL/BR, stem in TR/BR)
        # Single line only touches 2 quadrants!
        is_structure_valid = (quadrant_count >= 3) and (recall >= 0.25) and (cos_sim >= 0.45)

        if not is_structure_valid:
            # Harsh penalty for partial/single lines or scribbles
            final_conf = min(0.35, cos_sim * 0.4)
        else:
            # Calibrated confidence for legitimate child handwriting
            final_conf = 0.50 * cos_sim + 0.30 * recall + 0.20 * precision
            final_conf = (final_conf - 0.20) / (0.65 - 0.20)
            final_conf = min(0.96, max(0.55, final_conf))

        return final_conf, quadrant_count, recall, cos_sim

    for name, img_arr in [("Single Line", arr_line), ("Scribble (Cross)", arr_sc), ("Proper 'அ'", arr_a)]:
        conf, quads, rec, cos = evaluate_handwriting(img_arr, tpl_a_raw, tpl_a_field)
        print(f"{name:20s} -> Confidence: {conf*100:5.1f}% | Quadrants: {quads}/4 | Recall: {rec*100:5.1f}% | Cos: {cos*100:5.1f}%")

if __name__ == "__main__":
    main()
