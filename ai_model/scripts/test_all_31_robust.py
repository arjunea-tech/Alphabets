import sys
import os
import json
import numpy as np
from scipy.ndimage import gaussian_filter, rotate

sys.stdout.reconfigure(encoding='utf-8')

with open('d:/Selva Mac/Projects/tamil/frontend/assets/ml/character_templates.json', 'r', encoding='utf-8') as f:
    d = json.load(f)

labels = d['labels']
templates = d['templates']

tpl_raw = {}
tpl_field_tight = {}
tpl_field_wide = {}
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
    
    f_tight = gaussian_filter(raw, sigma=1.2)
    norm_t = np.linalg.norm(f_tight)
    tpl_field_tight[label] = f_tight / norm_t if norm_t > 0 else f_tight
    
    f_wide = gaussian_filter(raw, sigma=2.0)
    norm_w = np.linalg.norm(f_wide)
    tpl_field_wide[label] = f_wide / norm_w if norm_w > 0 else f_wide

def evaluate_handwriting(u_raw, expected_letter):
    u_active = np.sum(u_raw > 0.15)
    t_expected_active = tpl_active.get(expected_letter, 100)
    
    min_required_pixels = 20 if expected_letter == 'ஃ' else max(25, int(t_expected_active * 0.22))
    if u_active < min_required_pixels:
        return {'isMatch': False, 'expected_conf': 0.0, 'reason': 'Insufficient ink'}
    
    canvas_density = u_active / 1024.0
    if canvas_density > 0.42:
        return {'isMatch': False, 'expected_conf': 0.0, 'reason': 'Scribble fills canvas'}
    
    u_tight = gaussian_filter(u_raw, sigma=1.2)
    norm_ut = np.linalg.norm(u_tight)
    u_field_tight = u_tight / norm_ut if norm_ut > 0 else u_tight
    
    u_direct_blur = gaussian_filter(u_raw, sigma=1.0)
    
    candidates = []
    
    for label in labels:
        t_raw = tpl_raw[label]
        t_tight = tpl_field_tight[label]
        t_wide = tpl_field_wide[label]
        t_active = tpl_active[label]
        if t_active == 0: continue
        
        field_sim = float(np.sum(u_field_tight * t_tight))
        field_sim = max(0.0, min(1.0, field_sim))
        
        u_valid = np.sum((u_raw > 0.15) & (t_wide > 0.015))
        precision = u_valid / (u_active + 1e-6)
        
        t_covered = np.sum((t_raw > 0.12) & (u_direct_blur > 0.03))
        recall = t_covered / (t_active + 1e-6)
        
        overlap = np.sum((u_raw > 0.15) & (t_raw > 0.12))
        union = u_active + t_active - overlap
        iou = overlap / union if union > 0 else 0.0
        
        density_ratio = min(u_active / t_active, t_active / u_active)
        f1 = (2 * precision * recall / (precision + recall)) if (precision + recall) > 0 else 0.0
        
        coverage_gate = min(1.0, max(0.0, (recall - 0.12) / 0.18))
        precision_gate = min(1.0, max(0.0, (precision - 0.18) / 0.22))
        
        composite = (0.35 * field_sim + 0.30 * f1 + 0.20 * (iou * 2.0).clip(0, 1) + 0.15 * density_ratio) * coverage_gate * precision_gate
        confidence = float(np.clip(composite, 0.0, 1.0))
        
        candidates.append({
            'character': label,
            'confidence': confidence,
            'field_sim': field_sim,
            'precision': precision,
            'recall': recall,
            'f1': f1,
            'iou': iou,
            'density_ratio': density_ratio
        })
    
    candidates.sort(key=lambda x: x['confidence'], reverse=True)
    top1 = candidates[0] if candidates else None
    expected_cand = next((c for c in candidates if c['character'] == expected_letter), None)
    
    is_match = False
    if expected_cand is not None:
        rank = next((idx for idx, c in enumerate(candidates) if c['character'] == expected_letter), 99)
        if (rank < 8 or expected_cand['confidence'] >= 0.40) and \
           expected_cand['confidence'] >= 0.28 and \
           expected_cand['recall'] >= 0.22 and \
           expected_cand['precision'] >= 0.25:
            is_match = True
            
    return {
        'isMatch': is_match,
        'expected_conf': expected_cand['confidence'] if expected_cand else 0.0,
        'expected_rank': rank if expected_cand else 99,
        'top1': top1['character'] if top1 else None,
    }

# 1. Self-recognition for all 31 characters
all_pass = True
for c in labels:
    res = evaluate_handwriting(tpl_raw[c], c)
    if not res['isMatch']:
        print(f"Self-match failed for '{c}': {res}")
        all_pass = False

if all_pass:
    print("SUCCESS: 31/31 characters passed self-recognition!")

# 2. Slanted recognition (-12 deg to +12 deg) for all 31 characters
slanted_pass = 0
total_slanted = 0
for c in labels:
    base = tpl_raw[c]
    for angle in [-12, -6, 6, 12]:
        slanted = rotate(base, angle, reshape=False, order=1)
        slanted = np.clip(slanted, 0.0, 1.0)
        total_slanted += 1
        res = evaluate_handwriting(slanted, c)
        if res['isMatch']:
            slanted_pass += 1
        else:
            print(f"Slant failed for '{c}' at {angle} deg: {res}")

print(f"Slanted Recognition: {slanted_pass}/{total_slanted} ({slanted_pass/total_slanted*100:.1f}%)")

# 3. Random dots rejection for all 31 characters
dots_rejected = 0
for c in labels:
    res = evaluate_handwriting(np.zeros((32, 32), dtype=np.float32), c)
    if not res['isMatch']:
        dots_rejected += 1
print(f"Empty/Minimal Rejection: {dots_rejected}/{len(labels)}")
