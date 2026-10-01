import sys
import os
import json
import numpy as np
from PIL import Image, ImageDraw

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

def main():
    with open('d:/Selva Mac/Projects/tamil/frontend/assets/ml/character_templates.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    templates = data['templates']

    # 1. Full scribble covering whole canvas
    scribble = np.zeros((32, 32), dtype=np.float32)
    for y in range(4, 28):
        for x in range(4, 28):
            if (x + y) % 3 == 0 or (x - y) % 3 == 0:
                scribble[y, x] = 1.0

    # 2. Other letter: 'ட'
    img_da = np.zeros((32, 32), dtype=np.float32)
    img_da[4, 4:28] = 1.0   # top bar
    img_da[4:28, 28] = 1.0  # right stem
    img_da[28, 4:28] = 1.0  # bottom bar

    # 3. Proper 'அ'
    img_a = np.zeros((32, 32), dtype=np.float32)
    for a in np.linspace(0, 2*np.pi, 25):
        x = int(8 + 4*np.cos(a))
        y = int(8 + 4*np.sin(a))
        img_a[y, x] = 1.0
    img_a[14, 8:24] = 1.0
    img_a[4:28, 24] = 1.0

    def classify(user_arr):
        u_bin = user_arr > 0.15
        results = []
        
        for label, tpl_info in templates.items():
            tpl_raw = np.array(tpl_info['raw'], dtype=np.float32)
            t_bin = tpl_raw > 0.15
            
            # 1. True Positives (Hit)
            hit = np.sum(u_bin & t_bin)
            
            # 2. False Positives (Spurious ink where template is black background)
            spurious_ink = np.sum(u_bin & (~t_bin))
            
            # 3. False Negatives (Missing ink where template has stroke)
            missing_ink = np.sum((~u_bin) & t_bin)
            
            t_area = np.sum(t_bin)
            u_area = np.sum(u_bin)
            
            # Recall = how much of template was covered
            recall = hit / t_area if t_area > 0 else 0
            # Precision = how clean user drawing is (penalizes scribbles)
            precision = hit / u_area if u_area > 0 else 0
            
            # F1 score directly punishes both scribbles (low precision) and single lines (low recall)
            if (precision + recall) > 0:
                f1 = (2 * precision * recall) / (precision + recall)
            else:
                f1 = 0.0
                
            results.append((label, f1, precision, recall))
            
        results.sort(key=lambda x: x[1], reverse=True)
        return results

    for name, arr in [("Scribble (Full)", scribble), ("Other Letter ('ட')", img_da), ("Proper 'அ'", img_a)]:
        res = classify(arr)
        top = res[0]
        match_a = next(r for r in res if r[0] == 'அ')
        print(f"\nTest: {name}")
        print(f"  Top Prediction: '{top[0]}' with Score: {top[1]*100:.1f}% (Prec: {top[2]*100:.1f}%, Rec: {top[3]*100:.1f}%)")
        print(f"  Score for 'அ':       {match_a[1]*100:.1f}% (Prec: {match_a[2]*100:.1f}%, Rec: {match_a[3]*100:.1f}%)")

if __name__ == "__main__":
    main()
