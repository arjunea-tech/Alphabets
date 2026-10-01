import sys
import os
import json
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy.ndimage import gaussian_filter

sys.stdout.reconfigure(encoding='utf-8')

with open('d:/Selva Mac/Projects/tamil/frontend/assets/ml/character_templates.json', 'r', encoding='utf-8') as f:
    d = json.load(f)

labels = d['labels']
templates = d['templates']

# Prepare templates in memory
tpl_raw = {}
tpl_field = {}
tpl_active = {}

for label in labels:
    raw_list = templates[label]['raw']
    flat = []
    for item in raw_list:
        if isinstance(item, list):
            flat.extend(item)
        else:
            flat.append(item)
    raw = np.array(flat, dtype=np.float32).reshape((32, 32))
    tpl_raw[label] = raw
    active_count = np.sum(raw > 0.15)
    tpl_active[label] = active_count
    
    # field
    field = gaussian_filter(raw, sigma=1.0)
    norm = np.linalg.norm(field)
    if norm > 0:
        field = field / norm
    tpl_field[label] = field

def smooth_32x32(raw):
    # 3x3 Gaussian smoothing matching Dart implementation
    kernel = np.array([[1, 2, 1], [2, 4, 2], [1, 2, 1]], dtype=np.float32) / 16.0
    from scipy.signal import convolve2d
    return convolve2d(raw, kernel, mode='same', boundary='symm')

def recognize(u_raw, expected_letter):
    u_active = np.sum(u_raw > 0.15)
    
    # 1. Stroke count and minimum ink check
    if u_active < 8:
        return {
            'isMatch': False,
            'reason': 'Too few active pixels',
            'top1': None,
            'confidence': 0.0
        }
    
    # Gaussian smoothed user field
    u_smoothed = smooth_32x32(u_raw)
    norm_u = np.linalg.norm(u_smoothed)
    u_field = u_smoothed / norm_u if norm_u > 0 else u_smoothed
    
    # Canvas density check (reject massive scribbles filling > 45% canvas)
    canvas_density = u_active / 1024.0
    scribble_penalty = 1.0 if canvas_density <= 0.35 else max(0.0, 1.0 - (canvas_density - 0.35) * 5.0)
    
    candidates = []
    
    for label in labels:
        t_raw = tpl_raw[label]
        t_field = tpl_field[label]
        t_active = tpl_active[label]
        
        if t_active == 0:
            continue
        
        # 1. Cosine similarity of continuous spatial fields
        field_sim = float(np.sum(u_field * t_field))
        field_sim = max(0.0, min(1.0, field_sim))
        
        # 2. Precision: fraction of user ink falling within tolerance corridor of template
        u_valid_ink = np.sum((u_raw > 0.15) & (t_field > 0.015))
        precision = u_valid_ink / u_active if u_active > 0 else 0.0
        
        # 3. Recall: fraction of template skeleton covered by user drawing
        t_covered_ink = np.sum((t_raw > 0.12) & (u_smoothed > 0.02))
        recall = t_covered_ink / t_active if t_active > 0 else 0.0
        
        # 4. IoU
        intersection = np.sum((u_raw > 0.15) & (t_raw > 0.12))
        union = u_active + t_active - intersection
        iou = intersection / union if union > 0 else 0.0
        
        # 5. Density ratio
        density_ratio = min(u_active / t_active, t_active / u_active)
        
        # 6. Minimum coverage gate:
        # If user drawing only covers a tiny fraction of template, it CANNOT be this letter!
        # E.g., if recall < 0.25, score drops dramatically
        coverage_gate = min(1.0, max(0.0, (recall - 0.15) / 0.30))
        precision_gate = min(1.0, max(0.0, (precision - 0.15) / 0.30))
        
        f1 = (2 * precision * recall / (precision + recall)) if (precision + recall) > 0 else 0.0
        
        score = (0.35 * field_sim + 0.30 * f1 + 0.20 * (iou * 2.0).clip(0, 1) + 0.15 * density_ratio) * scribble_penalty * coverage_gate * precision_gate
        score = float(np.clip(score, 0.0, 1.0))
        
        candidates.append({
            'character': label,
            'confidence': score,
            'precision': precision,
            'recall': recall,
            'iou': iou,
            'field_sim': field_sim
        })
    
    candidates.sort(key=lambda x: x['confidence'], reverse=True)
    
    top1 = candidates[0] if candidates else None
    
    # Expected candidate details
    expected_cand = next((c for c in candidates if c['character'] == expected_letter), None)
    
    # STRICT MATCH RULES:
    # 1. Top-1 character MUST be the expected letter (or expected letter within 0.05 of top-1 and expected rank is top 2)
    # 2. Confidence must be >= 0.45
    # 3. Recall (coverage) must be >= 0.40 (user must have actually drawn at least 40% of the letter)
    # 4. Precision must be >= 0.35 (at least 35% of user's ink aligns with the letter)
    
    is_match = False
    if expected_cand is not None and top1 is not None:
        if (top1['character'] == expected_letter or (expected_cand['confidence'] >= top1['confidence'] - 0.05 and expected_cand['confidence'] >= 0.45)):
            if expected_cand['confidence'] >= 0.45 and expected_cand['recall'] >= 0.40 and expected_cand['precision'] >= 0.35:
                is_match = True
    
    return {
        'isMatch': is_match,
        'top1': top1['character'] if top1 else None,
        'top1_conf': top1['confidence'] if top1 else 0.0,
        'expected_conf': expected_cand['confidence'] if expected_cand else 0.0,
        'expected_recall': expected_cand['recall'] if expected_cand else 0.0,
        'expected_precision': expected_cand['precision'] if expected_cand else 0.0,
        'top3': [(c['character'], round(c['confidence'], 3)) for c in candidates[:3]]
    }

# Test 1: 3 random dots on 'ஈ' (simulating user screenshot)
u_3dots = np.zeros((32, 32), dtype=np.float32)
u_3dots[8:11, 15:18] = 1.0   # top dot
u_3dots[20:23, 10:13] = 1.0  # bottom left dot
u_3dots[19:22, 16:19] = 1.0  # bottom right dot

res1 = recognize(u_3dots, 'ஈ')
print("Test 1 (3 dots on 'ஈ' - EXPECT REJECT):", res1)

# Test 2: Correctly drawn 'ஈ' (from template + minor noise)
u_ee = tpl_raw['ஈ'].copy()
res2 = recognize(u_ee, 'ஈ')
print("Test 2 (Actual 'ஈ' - EXPECT ACCEPT):", res2)

# Test 3: Drawing 'அ' when 'ஈ' is expected (EXPECT REJECT)
u_a = tpl_raw['அ'].copy()
res3 = recognize(u_a, 'ஈ')
print("Test 3 (Drawn 'அ' for expected 'ஈ' - EXPECT REJECT):", res3)

# Test 4: Drawing 'க்' when 'க்' is expected (EXPECT ACCEPT)
u_k = tpl_raw['க்'].copy()
res4 = recognize(u_k, 'க்')
print("Test 4 (Actual 'க்' for expected 'க்' - EXPECT ACCEPT):", res4)

# Test 5: Single line scribble when 'அ' is expected (EXPECT REJECT)
u_line = np.zeros((32, 32), dtype=np.float32)
u_line[16, 5:27] = 1.0
res5 = recognize(u_line, 'அ')
print("Test 5 (Single line for 'அ' - EXPECT REJECT):", res5)
