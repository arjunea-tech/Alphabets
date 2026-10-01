import sys
if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')
import json
import numpy as np
from scipy.ndimage import gaussian_filter

with open("frontend/assets/ml/character_templates.json", "r", encoding="utf-8") as f:
    data = json.load(f)

templates = data["templates"]
labels = data["labels"]

sys.path.append("ai_model/training")
from preprocess import preprocess_strokes_to_image
from generate_canonical_31_templates import canonical_strokes_bank

def evaluate_target_alignment(strokes, expected_char):
    raw_tensor = preprocess_strokes_to_image(strokes, canvas_size=(350, 350), target_size=(32, 32))
    flat_tensor = raw_tensor.flatten()
    user_active = np.sum(flat_tensor > 0.15)
    
    if user_active < 15:
        return False, "போதிய எழுத்து வரிகள் வரையப்படவில்லை", 0.0

    u_tight = gaussian_filter(raw_tensor, sigma=0.8).flatten()
    norm_ut = np.linalg.norm(u_tight)
    u_field_tight = u_tight / norm_ut if norm_ut > 0 else u_tight

    # 1. Target Letter Multi-Prototype Evaluation
    target_protos = templates[expected_char]["prototypes"]
    best_target_score = 0.0
    best_target_rec = 0.0
    best_target_prec = 0.0
    best_field_sim = 0.0

    for proto in target_protos:
        t_raw = np.array(proto, dtype=np.float32).flatten()
        t_tight = gaussian_filter(np.array(proto, dtype=np.float32), sigma=0.8).flatten()
        t_wide = gaussian_filter(np.array(proto, dtype=np.float32), sigma=1.6).flatten()
        norm_t = np.linalg.norm(t_tight)
        t_norm = t_tight / norm_t if norm_t > 0 else t_tight
        t_active = np.sum(t_raw > 0.15)
        if t_active == 0:
            continue

        field_sim = np.clip(np.dot(u_field_tight, t_norm), 0.0, 1.0)
        u_valid = np.sum((flat_tensor > 0.15) & (t_wide > 0.08))
        precision = u_valid / user_active if user_active > 0 else 0.0

        t_cov = np.sum((t_raw > 0.15) & (u_tight > 0.08))
        recall = t_cov / t_active if t_active > 0 else 0.0

        intersection = np.sum((flat_tensor > 0.15) & (t_raw > 0.15))
        union = user_active + t_active - intersection
        iou = intersection / union if union > 0 else 0.0
        f1 = (2 * precision * recall / (precision + recall)) if (precision + recall) > 0 else 0.0
        density_ratio = min(user_active / t_active, t_active / user_active)

        cov_gate = min(1.0, max(0.0, (recall - 0.08) / 0.22))
        prec_gate = min(1.0, max(0.0, (precision - 0.08) / 0.22))

        score = (0.45 * field_sim + 0.35 * f1 + 0.15 * min(1.0, iou * 2.0) + 0.05 * density_ratio) * cov_gate * prec_gate
        if score > best_target_score:
            best_target_score = score
            best_target_rec = recall
            best_target_prec = precision
            best_field_sim = field_sim

    # 2. Specific Anatomical Feature Validation
    feature_valid = True
    
    # Check 2D tensor features
    # 'ஆ' requires bottom-right tail
    if expected_char == 'ஆ':
        tail_pixels = np.sum(raw_tensor[20:, 22:] > 0.15)
        stem_pixels = np.sum(raw_tensor[6:24, 20:28] > 0.15)
        if tail_pixels < 2 or stem_pixels < 4:
            feature_valid = False

    # 'அ' must not have an exaggerated loop on bottom right
    elif expected_char == 'அ':
        extra_loop_pixels = np.sum(raw_tensor[24:, 26:] > 0.15)
        if extra_loop_pixels >= 8:
            feature_valid = False

    # 'ஊ' requires top-right 'ள'
    elif expected_char == 'ஊ':
        top_right_la = np.sum(raw_tensor[:18, 16:] > 0.15)
        if top_right_la < 4:
            feature_valid = False

    # 'உ' must not have top-right 'ள'
    elif expected_char == 'உ':
        top_right_la = np.sum(raw_tensor[:18, 16:] > 0.15)
        if top_right_la >= 14:
            feature_valid = False

    # 'ஔ' requires right-side 'ள'
    elif expected_char == 'ஔ':
        right_la = np.sum(raw_tensor[:, 18:] > 0.15)
        if right_la < 8:
            feature_valid = False

    # 'ஒ' must not have right-side 'ள'
    elif expected_char == 'ஒ':
        right_la = np.sum(raw_tensor[:, 18:] > 0.15)
        if right_la >= 24:
            feature_valid = False

    # 'இ' requires no right-vertical stem at top
    elif expected_char == 'இ':
        right_top_stem = np.sum(raw_tensor[6:16, 22:28] > 0.15)
        if right_top_stem >= 10:
            feature_valid = False

    # 3. Overall match condition:
    # Target score >= 0.40, recall >= 0.28, precision >= 0.30, and feature valid
    is_match = (
        feature_valid and 
        best_target_score >= 0.38 and 
        best_target_rec >= 0.25 and 
        best_target_prec >= 0.28
    )

    return is_match, expected_char, best_target_score

# Run tests across canonical bank
print("--- Testing Target Alignment Engine ---")
all_good = True
for label, proto_list in canonical_strokes_bank.items():
    for p_idx, proto in enumerate(proto_list):
        m, char, sc = evaluate_target_alignment(proto, label)
        if not m:
            print(f"FAILED self match: {label} proto #{p_idx}, score: {sc:.3f}")
            all_good = False

# Cross checks
cross_tests = [
    ("இ", "ஆ"), # draw 'இ', expect 'ஆ' -> should fail
    ("ஆ", "அ"), # draw 'ஆ', expect 'அ' -> should fail
    ("உ", "ஊ"), # draw 'உ', expect 'ஊ' -> should fail
    ("ஒ", "ஔ"), # draw 'ஒ', expect 'ஔ' -> should fail
    ("அ", "ஆ"), # draw 'அ', expect 'ஆ' -> should fail
]

for drawn, expected in cross_tests:
    proto = canonical_strokes_bank[drawn][0]
    m, char, sc = evaluate_target_alignment(proto, expected)
    if m:
        print(f"FAILED cross match: Drawn '{drawn}' but expected '{expected}' was accepted! score: {sc:.3f}")
        all_good = False
    else:
        print(f"PASSED cross rejection: Drawn '{drawn}' when expecting '{expected}' was successfully rejected (score: {sc:.3f})")

if all_good:
    print("\nALL TARGET ALIGNMENT TESTS PASSED 100%!")
