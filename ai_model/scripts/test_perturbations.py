import sys
import os
import json
import numpy as np
from scipy.ndimage import gaussian_filter, rotate, shift

sys.stdout.reconfigure(encoding='utf-8')

with open('d:/Selva Mac/Projects/tamil/frontend/assets/ml/character_templates.json', 'r', encoding='utf-8') as f:
    d = json.load(f)

labels = d['labels']
templates = d['templates']

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
    
    field = gaussian_filter(raw, sigma=1.0)
    norm = np.linalg.norm(field)
    if norm > 0:
        field = field / norm
    tpl_field[label] = field

def smooth_32x32(raw):
    kernel = np.array([[1, 2, 1], [2, 4, 2], [1, 2, 1]], dtype=np.float32) / 16.0
    from scipy.signal import convolve2d
    return convolve2d(raw, kernel, mode='same', boundary='symm')

def recognize(u_raw, expected_letter):
    u_active = np.sum(u_raw > 0.15)
    if u_active < 8:
        return {'isMatch': False, 'top1': None, 'confidence': 0.0}
    
    u_smoothed = smooth_32x32(u_raw)
    norm_u = np.linalg.norm(u_smoothed)
    u_field = u_smoothed / norm_u if norm_u > 0 else u_smoothed
    
    canvas_density = u_active / 1024.0
    scribble_penalty = 1.0 if canvas_density <= 0.35 else max(0.0, 1.0 - (canvas_density - 0.35) * 5.0)
    
    candidates = []
    
    for label in labels:
        t_raw = tpl_raw[label]
        t_field = tpl_field[label]
        t_active = tpl_active[label]
        if t_active == 0:
            continue
        
        field_sim = float(np.sum(u_field * t_field))
        field_sim = max(0.0, min(1.0, field_sim))
        
        u_valid_ink = np.sum((u_raw > 0.15) & (t_field > 0.015))
        precision = u_valid_ink / u_active if u_active > 0 else 0.0
        
        t_covered_ink = np.sum((t_raw > 0.12) & (u_smoothed > 0.02))
        recall = t_covered_ink / t_active if t_active > 0 else 0.0
        
        intersection = np.sum((u_raw > 0.15) & (t_raw > 0.12))
        union = u_active + t_active - intersection
        iou = intersection / union if union > 0 else 0.0
        
        density_ratio = min(u_active / t_active, t_active / u_active)
        
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
    expected_cand = next((c for c in candidates if c['character'] == expected_letter), None)
    
    # Requirement:
    # 1. top1 is expected letter (or top 2 within 0.03 if high confidence)
    # 2. confidence >= 0.45, recall >= 0.38, precision >= 0.32
    is_match = False
    if expected_cand is not None and top1 is not None:
        if top1['character'] == expected_letter or (expected_cand['confidence'] >= top1['confidence'] - 0.03 and expected_cand['confidence'] >= 0.50):
            if expected_cand['confidence'] >= 0.45 and expected_cand['recall'] >= 0.38 and expected_cand['precision'] >= 0.32:
                is_match = True
    
    return {
        'isMatch': is_match,
        'top1': top1['character'] if top1 else None,
        'top1_conf': top1['confidence'] if top1 else 0.0,
        'expected_conf': expected_cand['confidence'] if expected_cand else 0.0,
    }

# Perturbation test: Rotate by -6 to +6 deg, Shift by -2 to +2 pixels
passed_perturbations = 0
total_perturbations = 0

for char in labels:
    base = tpl_raw[char]
    for angle in [-6, 0, 6]:
        for shift_x in [-1, 0, 1]:
            for shift_y in [-1, 0, 1]:
                perturbed = rotate(base, angle, reshape=False, order=1)
                perturbed = shift(perturbed, [shift_y, shift_x], order=1)
                perturbed = np.clip(perturbed, 0.0, 1.0)
                
                total_perturbations += 1
                res = recognize(perturbed, char)
                if res['isMatch']:
                    passed_perturbations += 1
                else:
                    # Print if fail
                    print(f"Char '{char}' failed at angle={angle}, dx={shift_x}, dy={shift_y}: {res}")

print(f"Perturbation Robustness: {passed_perturbations}/{total_perturbations} ({passed_perturbations/total_perturbations*100:.1f}%)")
