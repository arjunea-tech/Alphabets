import sys
import os
import json
import numpy as np

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

sys.path.append(os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../training")))
from preprocess import preprocess_strokes_to_image

strokes_a = [
    # Top-left loop and upper arch
    [
        (100, 110),
        (85, 95),
        (100, 80),
        (120, 80),
        (120, 110),
        (150, 80),
        (190, 80),
        (205, 110),
        (185, 150),
        (150, 175),
    ],
    # Bottom loop curving back up
    [
        (150, 175),
        (100, 205),
        (85, 235),
        (115, 255),
        (150, 245),
        (175, 205),
    ],
    # Middle horizontal crossbar
    [
        (75, 175),
        (175, 175),
        (265, 175),
    ],
    # Right vertical stem
    [
        (265, 80),
        (265, 175),
        (265, 265),
    ]
]

u_arr = preprocess_strokes_to_image(strokes_a, canvas_size=(350, 350))

with open('d:/Selva Mac/Projects/tamil/frontend/assets/ml/character_templates.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

labels = data['labels']
templates = data['templates']

from scipy.ndimage import gaussian_filter
u_field = gaussian_filter(u_arr, sigma=1.0)
norm_u = np.linalg.norm(u_field)
if norm_u > 0:
    u_field = u_field / norm_u

u_active = np.sum(u_arr > 0.15)

scores = []
for label in ['அ', 'ஆ', 'இ', 'ஐ', 'ஒ', 'ஓ', 'க்', 'ட்']:
    t_raw = np.array(templates[label]['raw'], dtype=np.float32)
    t_field = np.array(templates[label]['field'], dtype=np.float32)
    t_active = np.sum(t_raw > 0.12)
    
    field_sim = float(np.sum(u_field * t_field))
    
    u_valid = np.sum((u_arr > 0.15) & (t_field > 0.015))
    precision = u_valid / (u_active + 1e-6)
    
    t_cov = np.sum((t_raw > 0.12) & (u_field > 0.02))
    recall = t_cov / (t_active + 1e-6)
    
    intersection = np.sum((u_arr > 0.15) & (t_raw > 0.12))
    union = u_active + t_active - intersection
    iou = intersection / union if union > 0 else 0
    f1 = 2 * precision * recall / (precision + recall + 1e-6)
    
    density_ratio = min(u_active / t_active, t_active / u_active)
    
    print(f"Letter '{label}': F1={f1*100:5.1f}%, IoU={iou*100:5.1f}%, FieldSim={field_sim*100:5.1f}%, Precision={precision*100:5.1f}%, Recall={recall*100:5.1f}%, Dens={density_ratio*100:5.1f}%")
