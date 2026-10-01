import sys, os, json, numpy as np
from scipy.ndimage import gaussian_filter, rotate

sys.stdout.reconfigure(encoding='utf-8')
sys.path.append('d:/Selva Mac/Projects/tamil/ai_model/training')
from preprocess import preprocess_strokes_to_image

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
    tpl_active[label] = np.sum(raw > 0.15)
    
    f_tight = gaussian_filter(raw, sigma=1.2)
    norm_t = np.linalg.norm(f_tight)
    tpl_field_tight[label] = f_tight / norm_t if norm_t > 0 else f_tight
    
    f_wide = gaussian_filter(raw, sigma=2.0)
    norm_w = np.linalg.norm(f_wide)
    tpl_field_wide[label] = f_wide / norm_w if norm_w > 0 else f_wide

def evaluate_handwriting(u_raw, expected_letter):
    u_active = np.sum(u_raw > 0.15)
    t_expected_active = tpl_active.get(expected_letter, 120)
    
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
    recalls = {}
    precisions = {}
    
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
        precisions[label] = precision
        
        t_covered = np.sum((t_raw > 0.12) & (u_direct_blur > 0.03))
        recall = t_covered / (t_active + 1e-6)
        recalls[label] = recall
        
        overlap = np.sum((u_raw > 0.15) & (t_raw > 0.12))
        union = u_active + t_active - overlap
        iou = overlap / union if union > 0 else 0.0
        
        density_ratio = min(u_active / t_active, t_active / u_active)
        f1 = (2 * precision * recall / (precision + recall)) if (precision + recall) > 0 else 0.0
        
        coverage_gate = min(1.0, max(0.0, (recall - 0.12) / 0.18))
        precision_gate = min(1.0, max(0.0, (precision - 0.18) / 0.22))
        
        composite = (0.35 * field_sim + 0.30 * f1 + 0.20 * (iou * 2.0).clip(0, 1) + 0.15 * density_ratio) * coverage_gate * precision_gate
        confidence = float(np.clip(composite, 0.0, 1.0))
        
        candidates.append({'character': label, 'confidence': confidence})
    
    candidates.sort(key=lambda x: x['confidence'], reverse=True)
    top1 = candidates[0] if candidates else None
    expected_cand = next((c for c in candidates if c['character'] == expected_letter), None)
    
    exp_recall = recalls.get(expected_letter, 0.0)
    exp_prec = precisions.get(expected_letter, 0.0)
    exp_conf = expected_cand['confidence'] if expected_cand else 0.0
    exp_rank = next((idx for idx, c in enumerate(candidates) if c['character'] == expected_letter), 99)
    top1_conf = top1['confidence'] if top1 else 0.0
    
    # Matching rule:
    # 1. Expected letter confidence >= 0.28, recall >= 0.22, precision >= 0.25
    # 2. Not dominated by a completely different winner (top1_conf - exp_conf <= 0.25 or exp_rank <= 4)
    is_match = False
    if expected_cand is not None:
        is_top_cohort = (exp_rank <= 4) or (top1_conf - exp_conf <= 0.25)
        if is_top_cohort and exp_conf >= 0.28 and exp_recall >= 0.22 and exp_prec >= 0.25:
            is_match = True
            
    return {
        'isMatch': is_match,
        'expected_conf': exp_conf,
        'expected_rank': exp_rank,
        'top1': top1['character'] if top1 else None,
        'top1_conf': top1_conf,
        'recall': exp_recall,
        'precision': exp_prec,
        'top3': [(c['character'], round(c['confidence'], 2)) for c in candidates[:3]]
    }

# Test 1: User handwritten 'அ'
mockA = [
    [(100, 80), (75, 110), (95, 135), (120, 110), (95, 80), (135, 80), (150, 120), (145, 180), (115, 215), (95, 235), (120, 255), (160, 235), (180, 190), (255, 190)],
    [(255, 80), (255, 190), (255, 260)]
]
u_a = preprocess_strokes_to_image(mockA, canvas_size=(350, 350))
print("Test 1 (Handwritten 'அ' for 'அ' - EXPECT ACCEPT):", evaluate_handwriting(u_a, 'அ'))

# Test 2: Slanted handwritten 'அ' (-15 deg to +15 deg)
for angle in [-15, -10, 10, 15]:
    sl = np.clip(rotate(u_a, angle, reshape=False, order=1), 0.0, 1.0)
    print(f"Test 2 (Slanted {angle} deg 'அ' - EXPECT ACCEPT):", evaluate_handwriting(sl, 'அ')['isMatch'])

# Test 3: Drawing 'ட்' for 'அ'
mockDa = [
    [(80, 80), (220, 80)],
    [(220, 80), (220, 220)],
    [(80, 220), (220, 220)],
    [(150, 40), (152, 42)]
]
u_da = preprocess_strokes_to_image(mockDa, canvas_size=(350, 350))
print("Test 3 (Drawing 'ட்' for expected 'அ' - EXPECT REJECT):", evaluate_handwriting(u_da, 'அ'))

# Test 4: 3 dots for 'ஈ'
u_3dots = np.zeros((32, 32), dtype=np.float32)
u_3dots[8:11, 15:18] = 1.0
u_3dots[20:23, 10:13] = 1.0
u_3dots[19:22, 16:19] = 1.0
print("Test 4 (3 dots for 'ஈ' - EXPECT REJECT):", evaluate_handwriting(u_3dots, 'ஈ'))
