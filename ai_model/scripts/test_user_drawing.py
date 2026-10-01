import sys
import os
import json
import numpy as np

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

sys.path.append(os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../training")))
from preprocess import preprocess_strokes_to_image

with open('d:/Selva Mac/Projects/tamil/frontend/assets/ml/character_templates.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

templates = data['templates']

# mockStrokesA from Dart test:
mockStrokesA = [
    # Left loop
    [
        (80, 80),
        (110, 60),
        (130, 90),
        (110, 130),
        (80, 110),
        (90, 160),
    ],
    # Middle horizontal bar
    [
        (90, 160),
        (180, 160),
        (220, 160),
    ],
    # Right vertical stem
    [
        (220, 60),
        (220, 160),
        (220, 260),
    ],
]

u_arr = preprocess_strokes_to_image(mockStrokesA, canvas_size=(350, 350))

# Evaluate matching against all templates using our multi-factor scoring
def extract_grid(arr):
    # 4x4 grid (8x8 cells)
    grid = np.zeros(16, dtype=np.float32)
    for gy in range(4):
        for gx in range(4):
            cell = arr[gy*8:(gy+1)*8, gx*8:(gx+1)*8]
            grid[gy*4 + gx] = np.mean(cell)
    return grid

u_grid = extract_grid(u_arr)
norm_u_grid = np.linalg.norm(u_grid)
norm_u = np.linalg.norm(u_arr)
u_active = np.sum(u_arr > 0.15)

scores = []
for label, t_info in templates.items():
    t_arr = np.array(t_info['raw'], dtype=np.float32)
    t_active = np.sum(t_arr > 0.12)
    if t_active == 0:
        continue
    
    overlap = np.sum((u_arr > 0.15) & (t_arr > 0.12))
    precision = overlap / u_active if u_active > 0 else 0
    recall = overlap / t_active if t_active > 0 else 0
    f1 = (2 * precision * recall) / (precision + recall) if (precision + recall) > 0 else 0
    
    union = u_active + t_active - overlap
    iou = overlap / union if union > 0 else 0
    
    norm_t = np.linalg.norm(t_arr)
    dot = np.sum(u_arr * t_arr)
    cos = dot / (norm_u * norm_t) if (norm_u * norm_t) > 0 else 0
    
    t_grid = extract_grid(t_arr)
    norm_t_grid = np.linalg.norm(t_grid)
    grid_dot = np.dot(u_grid, t_grid)
    grid_correl = grid_dot / (norm_u_grid * norm_t_grid) if (norm_u_grid * norm_t_grid) > 0 else 0
    
    density_ratio = min(u_active / t_active, t_active / u_active)
    
    composite = (0.35 * f1) + (0.25 * iou) + (0.25 * cos) + (0.15 * grid_correl)
    composite *= (density_ratio ** 0.5)
    scores.append((label, composite, f1, iou, cos, grid_correl, density_ratio))

scores.sort(key=lambda x: x[1], reverse=True)
print("Top 5 matches for mockStrokesA:")
for s in scores[:5]:
    print(f"  '{s[0]}': {s[1]*100:.1f}% (F1: {s[2]*100:.1f}%, IoU: {s[3]*100:.1f}%, Cos: {s[4]*100:.1f}%, Grid: {s[5]*100:.1f}%, Dens: {s[6]*100:.1f}%)")
