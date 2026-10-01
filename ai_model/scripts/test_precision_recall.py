import sys
import os
import json
import numpy as np
from scipy.ndimage import gaussian_filter

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

def main():
    with open('d:/Selva Mac/Projects/tamil/frontend/assets/ml/character_templates.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    tpl_a_raw = np.array(data['templates']['அ']['raw'], dtype=np.float32)

    # 1. Single line
    line_img = np.zeros((32, 32), dtype=np.float32)
    line_img[4:28, 16] = 1.0

    # 2. Scribble / random lines
    scribble = np.zeros((32, 32), dtype=np.float32)
    for i in range(5, 25):
        scribble[i, i] = 1.0

    # 3. Full 'அ'
    a_img = np.zeros((32, 32), dtype=np.float32)
    for a in np.linspace(0, 2*np.pi, 25):
        x = int(8 + 4*np.cos(a))
        y = int(8 + 4*np.sin(a))
        a_img[y, x] = 1.0
    a_img[14, 8:24] = 1.0
    a_img[4:28, 24] = 1.0

    def evaluate(user, tpl):
        u_bin = (user > 0.1).astype(np.float32)
        t_bin = (tpl > 0.1).astype(np.float32)

        overlap = np.sum(u_bin * t_bin)
        u_area = np.sum(u_bin)
        t_area = np.sum(t_bin)
        union = np.sum((u_bin + t_bin) > 0)

        recall = overlap / t_area if t_area > 0 else 0
        precision = overlap / u_area if u_area > 0 else 0
        iou = overlap / union if union > 0 else 0
        f1 = (2 * precision * recall) / (precision + recall) if (precision + recall) > 0 else 0

        u_blur = gaussian_filter(user, sigma=1.0)
        t_blur = gaussian_filter(tpl, sigma=1.0)
        norm_ub = np.linalg.norm(u_blur)
        norm_tb = np.linalg.norm(t_blur)
        cos = np.sum(u_blur * t_blur) / (norm_ub * norm_tb) if norm_ub > 0 and norm_tb > 0 else 0

        # Structural completeness gate: must have at least 40% recall/coverage of the character
        if recall < 0.35:
            # Harsh penalty for partial/incomplete strokes (e.g. single line)
            score = cos * recall * 1.5
        else:
            score = 0.50 * cos + 0.35 * f1 + 0.15 * iou

        return score, recall, f1, cos

    for name, img in [("Single Line", line_img), ("Scribble (diagonal)", scribble), ("Proper 'அ'", a_img)]:
        s, rec, f1, cos = evaluate(img, tpl_a_raw)
        print(f"{name:20s} -> Score: {s*100:5.1f}% | Recall (Coverage): {rec*100:5.1f}% | Cos: {cos*100:5.1f}% | F1: {f1*100:5.1f}%")

if __name__ == "__main__":
    main()
