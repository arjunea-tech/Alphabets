import sys
import os
import json
import numpy as np
from scipy.ndimage import distance_transform_edt
from PIL import Image, ImageDraw

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

def main():
    with open('d:/Selva Mac/Projects/tamil/frontend/assets/ml/character_templates.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    templates = data['templates']

    # Precompute template binary maps and distance transforms for all 31 characters
    tpl_data = {}
    for label, tpl_info in templates.items():
        arr = np.array(tpl_info['raw'], dtype=np.float32)
        binary = arr > 0.15
        dt = distance_transform_edt(~binary)
        tpl_data[label] = {
            "binary": binary,
            "dt": dt,
            "pts": np.argwhere(binary)
        }

    # 1. Single Line
    img_line = np.zeros((32, 32), dtype=np.float32)
    img_line[4:28, 16] = 1.0

    # 2. Scribble (fills canvas)
    scribble = np.zeros((32, 32), dtype=np.float32)
    for y in range(4, 28):
        for x in range(4, 28):
            if (x + y) % 3 == 0:
                scribble[y, x] = 1.0

    # 3. Other Letter ('ட')
    img_da = np.zeros((32, 32), dtype=np.float32)
    img_da[4:7, 4:28] = 1.0
    img_da[4:28, 25:28] = 1.0
    img_da[25:28, 4:28] = 1.0

    # 4. Proper 'அ'
    img_a_pil = Image.new("L", (160, 160), 0)
    d_a = ImageDraw.Draw(img_a_pil)
    d_a.ellipse([20, 20, 70, 70], outline=255, width=16) # loop
    d_a.line([45, 90, 140, 90], fill=255, width=16)      # horizontal bar
    d_a.line([140, 20, 140, 140], fill=255, width=16)    # vertical stem
    img_a = np.array(img_a_pil.resize((32, 32), Image.Resampling.BILINEAR), dtype=np.float32) / 255.0

    def evaluate_bidirectional(user_arr):
        u_bin = user_arr > 0.15
        u_pts = np.argwhere(u_bin)
        if len(u_pts) < 10:
            return [("None", 0.0)]

        u_dt = distance_transform_edt(~u_bin)

        scores = []
        for label, t_info in tpl_data.items():
            t_dt = t_info["dt"]
            t_pts = t_info["pts"]

            # 1. User -> Template avg distance (penalty for stray ink / scribbles)
            d_u_to_t = np.mean(t_dt[u_bin])

            # 2. Template -> User avg distance (penalty for missing strokes / single lines)
            d_t_to_u = np.mean(u_dt[t_info["binary"]])

            # Symmetric Chamfer distance
            sym_dist = (d_u_to_t + d_t_to_u) / 2.0

            # Convert distance in pixels to confidence (0 px = 100%, 2 px = 75%, 4 px = 45%, 6+ px = 10%)
            conf = float(np.exp(-sym_dist / 2.8))
            scores.append((label, conf, sym_dist, d_u_to_t, d_t_to_u))

        scores.sort(key=lambda x: x[1], reverse=True)
        return scores

    for name, arr in [("Single Line", img_line), ("Scribble (diagonal)", scribble), ("Other Letter ('ட')", img_da), ("Proper 'அ'", img_a)]:
        res = evaluate_bidirectional(arr)
        top = res[0]
        match_a = next(r for r in res if r[0] == 'அ')
        print(f"\nTest: {name}")
        print(f"  Top Match: '{top[0]}' -> Confidence: {top[1]*100:5.1f}% (Distance: {top[2]:.2f}px)")
        print(f"  Match 'அ': '{match_a[0]}' -> Confidence: {match_a[1]*100:5.1f}% (Distance: {match_a[2]:.2f}px, Stray: {match_a[3]:.2f}px, Miss: {match_a[4]:.2f}px)")

if __name__ == "__main__":
    main()
