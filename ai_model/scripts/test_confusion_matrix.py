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

def evaluate_strokes(strokes, expected_char):
    raw_tensor = preprocess_strokes_to_image(strokes, canvas_size=(350, 350), target_size=(32, 32))
    flat_tensor = raw_tensor.flatten()
    user_active = np.sum(flat_tensor > 0.15)
    
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

            cov_gate = min(1.0, max(0.0, (recall - 0.10) / 0.25))
            prec_gate = min(1.0, max(0.0, (precision - 0.10) / 0.25))

            score = (0.45 * field_sim + 0.35 * f1 + 0.15 * min(1.0, iou * 2.0) + 0.05 * density_ratio) * cov_gate * prec_gate
            if score > best_s:
                best_s = score
                best_rec = recall
                best_prec = precision
        scores[label] = best_s
        recalls[label] = best_rec
        precisions[label] = best_prec

    sorted_cand = sorted(scores.items(), key=lambda x: x[1], reverse=True)
    top1_char, top1_score = sorted_cand[0]
    exp_score = scores.get(expected_char, 0.0)
    exp_rec = recalls.get(expected_char, 0.0)
    exp_prec = precisions.get(expected_char, 0.0)
    
    is_winner = (top1_char == expected_char)
    is_match = is_winner and exp_score >= 0.35 and exp_rec >= 0.25 and exp_prec >= 0.28
    return is_match, top1_char, exp_score

# Full Cross-Letter Validation (31 x 31 = 961 combinations)
total_tests = 0
false_accepts = 0
false_rejects = 0

for drawn_char, proto_list in canonical_strokes_bank.items():
    for proto in proto_list:
        for expected_char in labels:
            total_tests += 1
            is_match, recognized_char, exp_score = evaluate_strokes(proto, expected_char)
            
            if drawn_char == expected_char:
                if not is_match:
                    print(f"[FALSE REJECT] Drawn: '{drawn_char}', Expected: '{expected_char}' -> Recognized: '{recognized_char}' (score: {exp_score:.3f})")
                    false_rejects += 1
            else:
                if is_match:
                    print(f"[FALSE ACCEPT] Drawn: '{drawn_char}', Expected: '{expected_char}' -> Falsely accepted! (score: {exp_score:.3f})")
                    false_accepts += 1

print(f"\n--- Matrix Test Results ---")
print(f"Total combinations tested: {total_tests}")
print(f"False Rejections: {false_rejects}")
print(f"False Acceptances: {false_accepts}")
if false_rejects == 0 and false_accepts == 0:
    print("PERFECT 100% ACCURACY! Zero false rejections, Zero false acceptances across all combinations!")
