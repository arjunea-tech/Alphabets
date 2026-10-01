import sys
import os
import json
import numpy as np
from scipy.ndimage import gaussian_filter

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

with open("frontend/assets/ml/character_templates.json", "r", encoding="utf-8") as f:
    data = json.load(f)

templates = data["templates"]
labels = data["labels"]

# Smooth 32x32 simulation matching Dart
def smooth32x32(src, passes=1):
    kernel = np.array([
        [1.0, 2.0, 1.0],
        [2.0, 4.0, 2.0],
        [1.0, 2.0, 1.0]
    ], dtype=np.float32) / 16.0
    arr = src.copy()
    for _ in range(passes):
        arr = gaussian_filter(arr, sigma=0.8) # similar to 3x3 kernel
    return arr

tight_fields = {}
wide_fields = {}
norm_fields = {}
raw_fields = {}
actives = {}

for l, val in templates.items():
    raw = np.array(val["raw"], dtype=np.float32)
    raw_fields[l] = raw
    tight = smooth32x32(raw, 1)
    wide = smooth32x32(raw, 2)
    tight_fields[l] = tight
    wide_fields[l] = wide
    actives[l] = (raw > 0.15).sum()
    norm = np.linalg.norm(tight)
    norm_fields[l] = tight / norm if norm > 0 else tight

print("Checking letter cross-matching scores in current Dart engine:")

def evaluate_sim(drawn_letter, expected_letter):
    raw_user = raw_fields[drawn_letter]
    user_tight = tight_fields[drawn_letter]
    user_norm = norm_fields[drawn_letter]
    user_active = actives[drawn_letter]

    # Calculate scores for all labels
    results = []
    for l in labels:
        t_raw = raw_fields[l]
        t_tight = tight_fields[l]
        t_wide = wide_fields[l]
        t_norm = norm_fields[l]
        t_active = actives[l]

        field_sim = float(np.sum(user_norm * t_norm))
        u_valid = float(((raw_user > 0.15) & (t_wide > 0.08)).sum())
        precision = u_valid / user_active if user_active > 0 else 0.0
        
        t_covered = float(((t_raw > 0.15) & (user_tight > 0.08)).sum())
        recall = t_covered / t_active if t_active > 0 else 0.0

        intersection = float(((raw_user > 0.15) & (t_raw > 0.15)).sum())
        union = float(user_active + t_active - intersection)
        iou = intersection / union if union > 0 else 0.0
        f1 = (2 * precision * recall) / (precision + recall) if (precision + recall) > 0 else 0.0
        density_ratio = min(user_active / t_active, t_active / user_active)

        cov_gate = min(1.0, max(0.0, (recall - 0.15) / 0.25))
        prec_gate = min(1.0, max(0.0, (precision - 0.15) / 0.25))

        score = (0.35 * field_sim + 0.30 * f1 + 0.20 * min(1.0, iou * 2.0) + 0.15 * density_ratio) * cov_gate * prec_gate
        results.append((l, score, field_sim, precision, recall, f1))

    results.sort(key=lambda x: x[1], reverse=True)
    top1 = results[0]
    exp_res = next(x for x in results if x[0] == expected_letter)
    
    is_winner = (top1[0] == expected_letter or exp_res[1] >= top1[1] - 0.02)
    is_match = is_winner and exp_res[1] >= 0.35 and exp_res[4] >= 0.28 and exp_res[3] >= 0.30

    print(f"Drawn: {drawn_letter} | Expected: {expected_letter} -> Match: {is_match} | Top1: {top1[0]} ({top1[1]:.3f}) | Expected Score: {exp_res[1]:.3f} (P={exp_res[3]:.2f}, R={exp_res[4]:.2f})")

# Let's test the specific problem cases:
print("\n--- Testing 'இ' drawn when expecting 'ஆ' ---")
evaluate_sim("இ", "ஆ")

print("\n--- Testing 'ஆ' drawn when expecting 'இ' ---")
evaluate_sim("ஆ", "இ")

print("\n--- Testing 'ஊ' drawn when expecting 'ஊ' ---")
evaluate_sim("ஊ", "ஊ")

print("\n--- Testing 'ஔ' drawn when expecting 'ஔ' ---")
evaluate_sim("ஔ", "ஔ")

print("\n--- Testing 'உ' drawn when expecting 'ஊ' ---")
evaluate_sim("உ", "ஊ")

print("\n--- Testing 'ஒ' drawn when expecting 'ஔ' ---")
evaluate_sim("ஒ", "ஔ")
