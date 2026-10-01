import sys
import json
import math
if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

with open("frontend/assets/ml/character_templates.json", "r", encoding="utf-8") as f:
    data = json.load(f)

templates = data["templates"]
labels = data["labels"]

def smooth32x32(src, passes=1):
    arr = np.array(src, dtype=np.float32)
    # 3x3 gaussian filter approximation
    for _ in range(passes):
        arr = gaussian_filter(arr, sigma=1.0)
    return arr.tolist()

# Let's import canonical strokes
import sys
sys.path.append("ai_model/training")
from preprocess import preprocess_strokes_to_image

# Test stroke definitions:
test_cases = {
    "அ_authentic": [
        [(160, 70), (140, 90), (160, 110), (180, 90), (160, 70), (195, 70), (210, 95), (210, 135)],
        [(210, 135), (180, 175), (130, 215), (90, 240), (70, 260), (95, 275), (135, 260), (175, 200), (250, 200)],
        [(250, 70), (250, 200), (250, 280)],
    ],
    "ஆ_authentic": [
        [(160, 70), (140, 90), (160, 110), (180, 90), (160, 70), (195, 70), (210, 95), (210, 135)],
        [(210, 135), (180, 175), (130, 215), (90, 240), (70, 260), (95, 275), (135, 260), (175, 200), (250, 200)],
        [(250, 70), (250, 200), (250, 260), (280, 290), (300, 275), (285, 255), (250, 260)],
    ],
    "இ_authentic": [
        [(140, 80), (120, 70), (110, 90), (130, 110), (160, 100), (200, 90), (230, 110), (240, 140)],
        [(240, 140), (220, 170), (170, 180), (130, 200), (110, 230), (130, 260), (170, 260), (220, 250), (250, 260)],
    ],
    "உ_authentic": [
        [(110, 120), (90, 105), (75, 120), (90, 135), (110, 125), (145, 90), (180, 90), (195, 125), (195, 160)],
        [(195, 160), (170, 210), (125, 250), (100, 275), (260, 275)],
    ],
    "ஊ_authentic": [
        [(90, 140), (75, 125), (60, 140), (75, 155), (95, 145), (130, 115), (160, 115), (170, 145), (170, 175)],
        [(170, 175), (150, 215), (110, 245), (85, 275), (210, 275)],
        [(210, 110), (195, 100), (190, 110), (200, 120), (220, 115), (240, 100), (250, 120), (250, 170), (225, 200), (265, 200)],
    ],
    "ஒ_authentic": [
        [(120, 110), (100, 95), (90, 110), (105, 125), (125, 120), (160, 95), (190, 110), (180, 160)],
        [(180, 160), (130, 180), (140, 230), (180, 240), (220, 220), (220, 180), (250, 180), (250, 250)],
    ],
    "ஔ_authentic": [
        [(80, 110), (65, 95), (55, 110), (70, 125), (85, 120), (115, 95), (140, 110), (130, 150)],
        [(130, 150), (95, 170), (105, 210), (135, 220), (165, 205), (165, 170), (190, 170), (190, 230)],
        [(220, 120), (205, 110), (200, 120), (210, 130), (230, 125), (250, 110), (260, 130), (260, 180), (230, 210), (270, 210)],
    ],
}

def evaluate(strokes, expected_char):
    raw_tensor = preprocess_strokes_to_image(strokes, canvas_size=(350, 350), target_size=(32, 32))
    flat_tensor = raw_tensor.flatten()
    user_active = np.sum(flat_tensor > 0.15)
    
    u_tight = gaussian_filter(raw_tensor, sigma=0.8).flatten()
    norm_ut = np.linalg.norm(u_tight)
    u_field_tight = u_tight / norm_ut if norm_ut > 0 else u_tight

    scores = {}
    for label in labels:
        proto_list = templates[label]["prototypes"]
        best_s = 0.0
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

            cov_gate = min(1.0, max(0.0, (recall - 0.12) / 0.25))
            prec_gate = min(1.0, max(0.0, (precision - 0.12) / 0.25))

            score = (0.35 * field_sim + 0.30 * f1 + 0.20 * min(1.0, iou * 2.0) + 0.15 * density_ratio) * cov_gate * prec_gate
            if score > best_s:
                best_s = score
        scores[label] = best_s

    # Print top 3 candidates
    sorted_cand = sorted(scores.items(), key=lambda x: x[1], reverse=True)[:3]
    top1_char, top1_score = sorted_cand[0]
    is_match = (top1_char == expected_char) and top1_score >= 0.35
    print(f"Test Expected: '{expected_char}' -> Top1: '{top1_char}' (score: {top1_score:.3f}), Top3: {sorted_cand}, Match: {is_match}")
    return is_match

print("--- Running tests ---")
for name, strokes in test_cases.items():
    expected = name.split("_")[0]
    evaluate(strokes, expected)

print("\n--- Confusion Tests ---")
# 1. Practice 'ஆ' but draw 'இ' -> Expect false
print("Practice 'ஆ', draw 'இ':")
evaluate(test_cases["இ_authentic"], "ஆ")

# 2. Practice 'அ', draw 'ஆ' -> Expect false
print("Practice 'அ', draw 'ஆ':")
evaluate(test_cases["ஆ_authentic"], "அ")

# 3. Practice 'உ', draw 'ஊ' -> Expect false
print("Practice 'உ', draw 'ஊ':")
evaluate(test_cases["ஊ_authentic"], "உ")

# 4. Practice 'ஒ', draw 'ஔ' -> Expect false
print("Practice 'ஒ', draw 'ஔ':")
evaluate(test_cases["ஔ_authentic"], "ஒ")
