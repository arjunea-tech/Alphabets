import sys
import os
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy.ndimage import gaussian_filter

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

with open('d:/Selva Mac/Projects/tamil/frontend/assets/ml/character_templates.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

labels = data['labels']
templates = data['templates']

# Precompute smoothed fields for all templates
tpl_fields = {}
tpl_raws = {}
tpl_active_counts = {}

for label in labels:
    raw = np.array(templates[label]['raw'], dtype=np.float32)
    # Gaussian blur for spatial tolerance
    field = gaussian_filter(raw, sigma=1.2)
    norm = np.linalg.norm(field)
    if norm > 0:
        field = field / norm
    tpl_fields[label] = field
    tpl_raws[label] = raw
    tpl_active_counts[label] = np.sum(raw > 0.15)

def evaluate_drawing(u_raw):
    u_active = np.sum(u_raw > 0.15)
    if u_active < 8:
        return [("Empty", 0.0)]
    
    # 1. Blur user input for spatial match
    u_field = gaussian_filter(u_raw, sigma=1.2)
    norm_u = np.linalg.norm(u_field)
    if norm_u > 0:
        u_field = u_field / norm_u
    
    scores = []
    for label in labels:
        t_raw = tpl_raws[label]
        t_field = tpl_fields[label]
        t_active = tpl_active_counts[label]
        
        # 1. Spatial field correlation (Cosine similarity of continuous Gaussian fields)
        field_sim = float(np.sum(u_field * t_field)) # ranges 0 to 1
        
        # 2. Precision: how much user ink actually matches the template
        t_mask = gaussian_filter(t_raw, sigma=0.8) > 0.08
        u_valid_ink = np.sum((u_raw > 0.15) & t_mask)
        precision = u_valid_ink / (u_active + 1e-6)
        
        # 3. Coverage / Recall: how much template is covered by user ink
        u_mask = gaussian_filter(u_raw, sigma=0.8) > 0.08
        t_covered_ink = np.sum((t_raw > 0.15) & u_mask)
        recall = t_covered_ink / (t_active + 1e-6)
        
        # 4. IoU
        intersection = np.sum((u_raw > 0.15) & (t_raw > 0.15))
        union = u_active + t_active - intersection
        iou = intersection / union if union > 0 else 0.0
        
        # 5. Density balance
        density_ratio = min(u_active / (t_active + 1e-6), t_active / (u_active + 1e-6))
        
        # 6. Global ink density penalty (rejects random canvas scribbles)
        # Legitimate Tamil characters occupy 8% to 18% of the 32x32 canvas (80 to 185 pixels).
        # Scribbles occupy > 22% (225+ pixels).
        u_canvas_density = u_active / (32.0 * 32.0)
        scribble_penalty = 1.0 if u_canvas_density <= 0.22 else max(0.0, 1.0 - (u_canvas_density - 0.22) * 6.0)
        
        # Composite score
        # Completeness gate: ensures incomplete lines or stray scribbles cannot score high
        gate = min(1.0, recall / 0.40) * min(1.0, precision / 0.45)
        score = (0.35 * field_sim + 0.30 * precision + 0.25 * recall + 0.10 * density_ratio) * scribble_penalty * gate
        
        scores.append((label, score, field_sim, precision, recall, density_ratio))


        
    scores.sort(key=lambda x: x[1], reverse=True)
    return scores

# Test 1: Real 'அ' (rasterized from font + slightly varied)
img_a = Image.new("L", (200, 200), 0)
draw = ImageDraw.Draw(img_a)
font = ImageFont.truetype("C:/Windows/Fonts/Nirmala.ttc", 90)
bbox = draw.textbbox((0, 0), "அ", font=font)
draw.text(((200 - (bbox[2]-bbox[0]))//2 - bbox[0], (200 - (bbox[3]-bbox[1]))//2 - bbox[1]), "அ", font=font, fill=255)
# Crop and resize to 32x32
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../training")))
from preprocess import preprocess_image
arr_a = preprocess_image(img_a)

# Test 2: Real 'ட்'
img_da = Image.new("L", (200, 200), 0)
draw = ImageDraw.Draw(img_da)
bbox = draw.textbbox((0, 0), "ட்", font=font)
draw.text(((200 - (bbox[2]-bbox[0]))//2 - bbox[0], (200 - (bbox[3]-bbox[1]))//2 - bbox[1]), "ட்", font=font, fill=255)
arr_da = preprocess_image(img_da)

# Test 3: Scribble
arr_scribble = np.zeros((32, 32), dtype=np.float32)
for y in range(4, 28):
    for x in range(4, 28):
        if (x * 3 + y * 7) % 5 < 3:
            arr_scribble[y, x] = 0.9

# Test 4: Single line
arr_line = np.zeros((32, 32), dtype=np.float32)
arr_line[4:28, 16] = 0.9

tests = [
    ("Actual 'அ' Drawing", arr_a, "அ"),
    ("Actual 'ட்' Drawing", arr_da, "ட்"),
    ("Scribble Across Screen", arr_scribble, "அ"),
    ("Single Vertical Line", arr_line, "அ"),
]

for name, arr, expected in tests:
    res = evaluate_drawing(arr)
    top1 = res[0]
    match_exp = next(r for r in res if r[0] == expected)
    print(f"\n==========================================")
    print(f"Test: {name} (Expected: '{expected}')")
    print(f"  Top 1 Prediction : '{top1[0]}' -> Score: {top1[1]*100:.1f}%")
    print(f"  Expected '{expected}'  : Score: {match_exp[1]*100:.1f}% (FieldSim: {match_exp[2]*100:.1f}%, Stray: {match_exp[3]*100:.1f}%, Cov: {match_exp[4]*100:.1f}%, Dens: {match_exp[5]*100:.1f}%)")
    print(f"  Top 3: {[(r[0], f'{r[1]*100:.1f}%') for r in res[:3]]}")
