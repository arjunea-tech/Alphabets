import sys
import os
import json
import numpy as np
from scipy.ndimage import distance_transform_edt

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

def main():
    with open('d:/Selva Mac/Projects/tamil/frontend/assets/ml/character_templates.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    templates = data['templates']

    # Generate Signed Distance Field (SDF) for all 31 templates
    # SDF: Positive (+1.0) on stroke, decaying to -1.0 in empty background
    sdfs = {}
    for label, tpl_info in templates.items():
        tpl_raw = np.array(tpl_info['raw'], dtype=np.float32)
        binary_stroke = tpl_raw > 0.15
        if not np.any(binary_stroke):
            binary_stroke = np.ones((32, 32), dtype=bool)
            
        dist = distance_transform_edt(~binary_stroke) # distance from stroke
        # Decay: near stroke (d=0) is +1.0, d=3 is +0.37, d>5 is negative (empty background penalty)
        sdf = np.exp(-dist / 2.5) * 1.8 - 0.8
        sdfs[label] = sdf

    # 1. Scribble (fills canvas)
    scribble = np.zeros((32, 32), dtype=np.float32)
    for y in range(4, 28):
        for x in range(4, 28):
            if (x + y) % 2 == 0:
                scribble[y, x] = 1.0

    # 2. Other Letter ('ட')
    img_da = np.zeros((32, 32), dtype=np.float32)
    img_da[4:8, 4:28] = 1.0   # top bar
    img_da[4:28, 24:28] = 1.0 # right stem
    img_da[24:28, 4:28] = 1.0 # bottom bar

    # 3. Proper 'அ' (Left loop, horizontal arm, right vertical stem)
    from PIL import Image, ImageDraw
    img_a_pil = Image.new("L", (160, 160), 0)
    d_a = ImageDraw.Draw(img_a_pil)
    d_a.ellipse([20, 20, 70, 70], outline=255, width=16) # loop
    d_a.line([45, 90, 140, 90], fill=255, width=16)      # horizontal bar
    d_a.line([140, 20, 140, 140], fill=255, width=16)    # vertical stem
    img_a = np.array(img_a_pil.resize((32, 32), Image.Resampling.BILINEAR), dtype=np.float32) / 255.0

    def evaluate_sdf(user_tensor):
        u_pts = user_tensor > 0.15
        total_u = np.sum(u_pts)
        if total_u < 10:
            return [("None", 0.0)]
            
        scores = []
        for label, sdf in sdfs.items():
            # Average SDF value under user strokes
            # If user drew in correct locations: sdf > 0 -> high positive score
            # If user drew in wrong locations (scribble/wrong letter): sdf < 0 -> heavy negative penalty!
            val = np.sum(user_tensor * sdf) / np.sum(user_tensor)
            
            # Map [-0.5, +1.0] -> [0.0, 1.0]
            conf = float(np.clip((val - 0.0) / (0.85 - 0.0), 0.0, 0.98))
            scores.append((label, conf, val))
            
        scores.sort(key=lambda x: x[1], reverse=True)
        return scores

    for name, arr in [("Scribble (Cross/Grid)", scribble), ("Other Letter ('ட')", img_da), ("Proper 'அ'", img_a)]:
        res = evaluate_sdf(arr)
        top = res[0]
        match_a = next(r for r in res if r[0] == 'அ')
        print(f"\nTest: {name}")
        print(f"  Top Prediction: '{top[0]}' -> Confidence: {top[1]*100:.1f}% (raw SDF: {top[2]:.2f})")
        print(f"  Score for 'அ':       '{match_a[0]}' -> Confidence: {match_a[1]*100:.1f}% (raw SDF: {match_a[2]:.2f})")

if __name__ == "__main__":
    main()
