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

def evaluate_high_tolerance(strokes, expected_char):
    raw_tensor = preprocess_strokes_to_image(strokes, canvas_size=(350, 350), target_size=(32, 32))
    flat_tensor = raw_tensor.flatten()
    user_active = np.sum(flat_tensor > 0.15)
    
    if user_active < 10:
        return False, "போதிய எழுத்து வரிகள் வரையப்படவில்லை", 0.0

    u_tight = gaussian_filter(raw_tensor, sigma=0.8).flatten()
    norm_ut = np.linalg.norm(u_tight)
    u_field_tight = u_tight / norm_ut if norm_ut > 0 else u_tight

    scores = {}
    recalls = {}
    precisions = {}

    for label in labels:
        proto_list = templates[label]["prototypes"]
        best_s = 0.0
        best_rec = 0.0
        best_prec = 0.0
        for proto in proto_list:
            t_raw = np.array(proto, dtype=np.float32).flatten()
            t_tight = gaussian_filter(np.array(proto, dtype=np.float32), sigma=0.8).flatten()
            t_wide = gaussian_filter(np.array(proto, dtype=np.float32), sigma=1.8).flatten() # wider tolerance corridor for kids
            norm_t = np.linalg.norm(t_tight)
            t_norm = t_tight / norm_t if norm_t > 0 else t_tight
            t_active = np.sum(t_raw > 0.15)
            if t_active == 0:
                continue

            field_sim = np.clip(np.dot(u_field_tight, t_norm), 0.0, 1.0)
            u_valid = np.sum((flat_tensor > 0.15) & (t_wide > 0.06))
            precision = u_valid / user_active if user_active > 0 else 0.0

            t_cov = np.sum((t_raw > 0.15) & (u_tight > 0.06))
            recall = t_cov / t_active if t_active > 0 else 0.0

            # High-tolerance child fidelity score
            score = 0.50 * field_sim + 0.30 * recall + 0.20 * precision

            if score > best_s:
                best_s = score
                best_rec = recall
                best_prec = precision

        scores[label] = best_s
        recalls[label] = best_rec
        precisions[label] = best_prec

    sorted_cand = sorted(scores.items(), key=lambda x: x[1], reverse=True)
    top1_char, top1_score = sorted_cand[0]

    target_score = scores.get(expected_char, 0.0)
    target_rec = recalls.get(expected_char, 0.0)
    target_prec = precisions.get(expected_char, 0.0)

    # Strict winner requirement: Expected character must win top-1 or be within 90% of top-1
    is_match = (
        target_score >= 0.35 and 
        target_rec >= 0.16 and 
        target_prec >= 0.20 and 
        (top1_char == expected_char)
    )

    return is_match, top1_char, target_score

# Test all letters
print("--- Testing High Tolerance Engine on Canonical Letters ---")
all_good = True
for label, proto_list in canonical_strokes_bank.items():
    for p_idx, proto in enumerate(proto_list):
        m, top_c, sc = evaluate_high_tolerance(proto, label)
        if not m:
            print(f"FAILED self-match: {label} proto #{p_idx}, top: {top_c}, score: {sc:.3f}")
            all_good = False

# Cross tests: wrong letter drawings
cross_tests = [
    ("இ", "ஆ"), # draw 'இ', expect 'ஆ' -> should be False
    ("ஆ", "அ"), # draw 'ஆ', expect 'அ' -> should be False
    ("ட்", "அ"), # draw 'ட்', expect 'அ' -> should be False
    ("ப்", "ம்"), # draw 'ப்', expect 'ம்' -> should be False
    ("உ", "ஊ"), # draw 'உ', expect 'ஊ' -> should be False
]

print("\n--- Testing Cross Letter Rejections ---")
for drawn, expected in cross_tests:
    proto = canonical_strokes_bank[drawn][0] if drawn in canonical_strokes_bank else [[]]
    m, top_c, sc = evaluate_high_tolerance(proto, expected)
    print(f"Drawn '{drawn}' when expecting '{expected}' -> Match: {m}, Recognized: '{top_c}', Target Score: {sc:.3f}")
