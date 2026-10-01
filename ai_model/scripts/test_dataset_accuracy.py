import sys
import os
import json
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

sys.path.append("ai_model/training")
from preprocess import preprocess_image

with open("frontend/assets/ml/character_templates.json", "r", encoding="utf-8") as f:
    data = json.load(f)

templates = data["templates"]
labels = data["labels"]

def smooth32x32(src, passes=1):
    arr = src.copy()
    for _ in range(passes):
        arr = gaussian_filter(arr, sigma=0.8)
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


def evaluate_image(raw_tensor, expected_letter):
    u_tight = smooth32x32(raw_tensor, 1)
    norm_u = np.linalg.norm(u_tight)
    u_norm = u_tight / norm_u if norm_u > 0 else u_tight
    user_active = (raw_tensor > 0.15).sum()

    candidates = []
    for l in labels:
        t_raw = raw_fields[l]
        t_tight = tight_fields[l]
        t_wide = wide_fields[l]
        t_norm = norm_fields[l]
        t_active = actives[l]

        field_sim = float(np.sum(u_norm * t_norm))
        u_valid = float(((raw_tensor > 0.15) & (t_wide > 0.08)).sum())
        precision = u_valid / user_active if user_active > 0 else 0.0
        
        t_covered = float(((t_raw > 0.15) & (u_tight > 0.08)).sum())
        recall = t_covered / t_active if t_active > 0 else 0.0

        intersection = float(((raw_tensor > 0.15) & (t_raw > 0.15)).sum())
        union = float(user_active + t_active - intersection)
        iou = intersection / union if union > 0 else 0.0
        f1 = (2 * precision * recall) / (precision + recall) if (precision + recall) > 0 else 0.0
        density_ratio = min(user_active / t_active, t_active / user_active) if t_active > 0 and user_active > 0 else 0.0

        cov_gate = min(1.0, max(0.0, (recall - 0.15) / 0.25))
        prec_gate = min(1.0, max(0.0, (precision - 0.15) / 0.25))

        score = (0.35 * field_sim + 0.30 * f1 + 0.20 * min(1.0, iou * 2.0) + 0.15 * density_ratio) * cov_gate * prec_gate
        candidates.append((l, score, precision, recall))

    candidates.sort(key=lambda x: x[1], reverse=True)
    top1 = candidates[0]
    exp = next((x for x in candidates if x[0] == expected_letter), (expected_letter, 0.0, 0.0, 0.0))

    is_winner = (top1[0] == expected_letter or exp[1] >= top1[1] - 0.02)
    is_match = is_winner and exp[1] >= 0.35 and exp[3] >= 0.28 and exp[2] >= 0.30

    return is_match, top1[0], exp[1], exp[2], exp[3]

def run_tests():
    test_dir = "ai_model/dataset/test"
    if not os.path.exists(test_dir):
        test_dir = "ai_model/dataset/train"

    if not os.path.exists(test_dir):
        print(f"Dataset directory {test_dir} not found. Skipping dataset accuracy run.")
        return

    print(f"Testing on images from {test_dir}...")
    for target_letter in ["ஊ", "ஔ", "ஆ", "இ"]:
        c_dir = os.path.join(test_dir, target_letter)
        if not os.path.exists(c_dir):
            continue
        files = [f for f in os.listdir(c_dir) if f.lower().endswith(('.png', '.jpg', '.bmp'))][:20]
        correct = 0
        total = len(files)
        if total == 0:
            continue
        print(f"\n--- Testing class '{target_letter}' ({total} samples) ---")
        for f in files:
            im = Image.open(os.path.join(c_dir, f)).convert('L')
            arr = np.array(im)
            if np.mean(arr) > 128:
                im = Image.fromarray(255 - arr)
            raw = preprocess_image(im, target_size=(32, 32))
            is_match, top1, score, prec, rec = evaluate_image(raw, target_letter)
            if is_match:
                correct += 1
            else:
                print(f"  FAILED on {f}: top1='{top1}', exp_score={score:.3f}, prec={prec:.2f}, rec={rec:.2f}")
        print(f"Accuracy for '{target_letter}': {correct}/{total} ({correct/total*100:.1f}%)")

    # False positive test
    c_dir_i = os.path.join(test_dir, "இ")
    if os.path.exists(c_dir_i):
        files_i = [f for f in os.listdir(c_dir_i) if f.lower().endswith(('.png', '.jpg', '.bmp'))][:20]
        fp_count = 0
        if len(files_i) > 0:
            print(f"\n--- Testing False Positives: Draw 'இ' when expecting 'ஆ' (should be 0%) ---")
            for f in files_i:
                im = Image.open(os.path.join(c_dir_i, f)).convert('L')
                arr = np.array(im)
                if np.mean(arr) > 128:
                    im = Image.fromarray(255 - arr)
                raw = preprocess_image(im, target_size=(32, 32))
                is_match, top1, score, prec, rec = evaluate_image(raw, "ஆ")
                if is_match:
                    fp_count += 1
                    print(f"  FALSE POSITIVE on {f}: top1='{top1}', exp_score={score:.3f}, prec={prec:.2f}, rec={rec:.2f}")
            print(f"False Positives ('இ' as 'ஆ'): {fp_count}/{len(files_i)} ({fp_count/len(files_i)*100:.1f}%)")

if __name__ == '__main__':
    run_tests()

