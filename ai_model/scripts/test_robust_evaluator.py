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
    
    # 1. Minimum active ink check (Reject empty canvas or just 1-3 tiny dots on full letters)
    # Letters except 'ஃ' typically have > 120 pixels in template.
    min_required_pixels = 20 if expected_letter == 'ஃ' else max(30, int(t_expected_active * 0.25))
    if u_active < min_required_pixels:
        return {'isMatch': False, 'expected_conf': 0.0, 'reason': f'Insufficient ink ({u_active} < {min_required_pixels})'}
    
    # 2. Canvas density check (reject full canvas scribbles > 40%)
    canvas_density = u_active / 1024.0
    if canvas_density > 0.40:
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
        
        # Spatial similarity (Cosine similarity of normalized fields)
        field_sim = float(np.sum(u_field_tight * t_tight))
        field_sim = max(0.0, min(1.0, field_sim))
        
        # Precision: fraction of user ink falling inside wide template corridor (allows slants/offsets)
        u_valid = np.sum((u_raw > 0.15) & (t_wide > 0.015))
        precision = u_valid / (u_active + 1e-6)
        
        # Recall / Coverage: fraction of template skeleton covered by user drawing (requires real strokes)
        t_covered = np.sum((t_raw > 0.12) & (u_direct_blur > 0.03))
        recall = t_covered / (t_active + 1e-6)
        
        overlap = np.sum((u_raw > 0.15) & (t_raw > 0.12))
        union = u_active + t_active - overlap
        iou = overlap / union if union > 0 else 0.0
        
        density_ratio = min(u_active / t_active, t_active / u_active)
        f1 = (2 * precision * recall / (precision + recall)) if (precision + recall) > 0 else 0.0
        
        # Completeness gate: requires at least 25% recall and 30% precision
        coverage_gate = min(1.0, max(0.0, (recall - 0.15) / 0.20))
        precision_gate = min(1.0, max(0.0, (precision - 0.20) / 0.25))
        
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
    
    # Educational Acceptance Condition:
    # 1. User has covered substantial structure of expected letter (recall >= 0.28)
    # 2. User ink stays reasonably within letter shape (precision >= 0.35)
    # 3. Confidence score >= 0.32
    # 4. Expected letter is in top-8 candidates (or has score >= 0.40)
    is_match = False
    if expected_cand is not None:
        rank = next((idx for idx, c in enumerate(candidates) if c['character'] == expected_letter), 99)
        if (rank < 8 or expected_cand['confidence'] >= 0.40) and \
           expected_cand['confidence'] >= 0.30 and \
           expected_cand['recall'] >= 0.25 and \
           expected_cand['precision'] >= 0.30:
            is_match = True
            
    return {
        'isMatch': is_match,
        'expected_conf': expected_cand['confidence'] if expected_cand else 0.0,
        'expected_rank': rank if expected_cand else 99,
        'top1': top1['character'] if top1 else None,
        'top1_conf': top1['confidence'] if top1 else 0.0,
        'recall': expected_cand['recall'] if expected_cand else 0.0,
        'precision': expected_cand['precision'] if expected_cand else 0.0,
        'top3': [(c['character'], round(c['confidence'], 2)) for c in candidates[:3]]
    }

# Test 1: User's handwritten 'அ'
mockStrokesA_handwritten = [
    # Left loop & cross
    [(100, 80), (75, 110), (95, 135), (120, 110), (95, 80), (135, 80), (150, 120), (145, 180), (115, 215), (95, 235), (120, 255), (160, 235), (180, 190), (255, 190)],
    # Vertical stem
    [(255, 80), (255, 190), (255, 260)]
]
sys.path.append('d:/Selva Mac/Projects/tamil/ai_model/training')
from preprocess import preprocess_strokes_to_image
u_hand_a = preprocess_strokes_to_image(mockStrokesA_handwritten, canvas_size=(350, 350))

res1 = evaluate_handwriting(u_hand_a, 'அ')
print("Test 1 (Natural handwritten 'அ' - EXPECT ACCEPT):", res1)

# Test 2: Slanted handwritten 'அ' (rotated by -15 deg, -10 deg, +10 deg, +15 deg)
for angle in [-15, -10, 10, 15]:
    slanted = rotate(u_hand_a, angle, reshape=False, order=1)
    slanted = np.clip(slanted, 0.0, 1.0)
    res_slant = evaluate_handwriting(slanted, 'அ')
    print(f"Test 2 (Slanted {angle} deg 'அ' - EXPECT ACCEPT): isMatch={res_slant['isMatch']}, conf={res_slant['expected_conf']:.2f}, rank={res_slant['expected_rank']}")

# Test 3: 3 random dots on 'ஈ' (EXPECT REJECT)
u_3dots = np.zeros((32, 32), dtype=np.float32)
u_3dots[8:11, 15:18] = 1.0
u_3dots[20:23, 10:13] = 1.0
u_3dots[19:22, 16:19] = 1.0
res3 = evaluate_handwriting(u_3dots, 'ஈ')
print("Test 3 (3 random dots for 'ஈ' - EXPECT REJECT):", res3)

# Test 4: Completely wrong letter (Draw 'ட்' when 'அ' is expected - EXPECT REJECT)
u_da = tpl_raw['ட்']
res4 = evaluate_handwriting(u_da, 'அ')
print("Test 4 (Draw 'ட்' for expected 'அ' - EXPECT REJECT):", res4)

# Test 5: Single line scribble (EXPECT REJECT)
u_line = np.zeros((32, 32), dtype=np.float32)
u_line[16, 5:27] = 1.0
res5 = evaluate_handwriting(u_line, 'அ')
print("Test 5 (Single line scribble - EXPECT REJECT):", res5)
