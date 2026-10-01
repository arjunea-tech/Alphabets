import sys
import os
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFont

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

sys.path.append(os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../training")))
from preprocess import preprocess_image, preprocess_strokes_to_image

with open('d:/Selva Mac/Projects/tamil/frontend/assets/ml/character_templates.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

labels = data['labels']
templates = data['templates']

font = ImageFont.truetype("C:/Windows/Fonts/Nirmala.ttc", 90)

# Generate test inputs for all 31 letters
for test_char in ['அ', 'ஆ', 'இ', 'ஈ', 'உ', 'ஊ', 'எ', 'ஏ', 'ஐ', 'ஒ', 'ஓ', 'ஔ', 'க்', 'ங்', 'ச்', 'ஞ்', 'ட்', 'ண்', 'த்', 'ந்', 'ப்', 'ம்', 'ய்', 'ர்', 'ல்', 'வ்', 'ழ்', 'ள்', 'ற்', 'ன்', 'ஃ']:
    img = Image.new("L", (200, 200), 0)
    draw = ImageDraw.Draw(img)
    bbox = draw.textbbox((0, 0), test_char, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text(((200 - tw)//2 - bbox[0], (200 - th)//2 - bbox[1]), test_char, font=font, fill=255)
    
    u_raw = preprocess_image(img)
    
    # Evaluate with current templates
    from scipy.ndimage import gaussian_filter
    u_field = gaussian_filter(u_raw, sigma=1.0)
    norm_u = np.linalg.norm(u_field)
    if norm_u > 0:
        u_field = u_field / norm_u
        
    u_active = np.sum(u_raw > 0.15)
    
    scores = []
    for label in labels:
        t_raw = np.array(templates[label]['raw'], dtype=np.float32)
        t_field = np.array(templates[label]['field'], dtype=np.float32)
        t_active = np.sum(t_raw > 0.12)
        if t_active == 0:
            continue
            
        field_sim = float(np.sum(u_field * t_field))
        
        u_valid = np.sum((u_raw > 0.15) & (t_field > 0.02))
        precision = u_valid / (u_active + 1e-6)
        
        t_cov = np.sum((t_raw > 0.12) & (u_field > 0.02))
        recall = t_cov / (t_active + 1e-6)
        
        density_ratio = min(u_active / t_active, t_active / u_active)
        
        u_canvas_dens = u_active / 1024.0
        scrib_pen = 1.0 if u_canvas_dens <= 0.30 else max(0.0, 1.0 - (u_canvas_dens - 0.30) * 4.0)
        
        gate = min(1.0, recall / 0.40) * min(1.0, precision / 0.45)
        score = (0.35 * field_sim + 0.30 * precision + 0.25 * recall + 0.10 * density_ratio) * scrib_pen * gate
        scores.append((label, score))
        
    scores.sort(key=lambda x: x[1], reverse=True)
    top1 = scores[0]
    is_correct = top1[0] == test_char
    status = "OK" if is_correct else f"FAIL (Predicted '{top1[0]}' instead)"
    print(f"Letter '{test_char}': Top1 = '{top1[0]}' ({top1[1]*100:.1f}%) -> {status}")
