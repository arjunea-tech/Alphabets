import sys
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import os

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')


def generate_letter_image(char, size=32):
    # Render Tamil letter into 32x32 image using Nirmala UI
    img = Image.new("L", (128, 128), 0)
    draw = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype("C:/Windows/Fonts/Nirmala.ttc", 90)
    except:
        font = ImageFont.load_default()
    
    bbox = draw.textbbox((0, 0), char, font=font)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    x = (128 - w) // 2 - bbox[0]
    y = (128 - h) // 2 - bbox[1]
    draw.text((x, y), char, fill=255, font=font)
    
    # Resize to 32x32
    img32 = img.resize((size, size), Image.Resampling.BILINEAR)
    arr = np.array(img32, dtype=np.float32) / 255.0
    return arr

def main():
    with open('d:/Selva Mac/Projects/tamil/frontend/assets/ml/labels.txt', 'r', encoding='utf-8') as f:
        labels = [l.strip() for l in f.readlines() if l.strip()]

    print(f"Loaded {len(labels)} labels: {labels}")

    # Generate reference templates for all 31 labels
    templates = {}
    for l in labels:
        templates[l] = generate_letter_image(l)

    # Test cases:
    # 1. Real 'அ'
    img_a = generate_letter_image('அ')
    # 2. Real 'ஆ'
    img_aa = generate_letter_image('ஆ')
    # 3. Real 'ட்'
    img_da = generate_letter_image('ட்')
    # 4. Real 'க' / 'க்'
    img_k = generate_letter_image('க்')
    # 5. Scribble
    scribble = np.zeros((32, 32), dtype=np.float32)
    for y in range(4, 28):
        for x in range(4, 28):
            if (x * 3 + y * 7) % 5 < 3:
                scribble[y, x] = 0.9
    # 6. Single line
    line = np.zeros((32, 32), dtype=np.float32)
    line[4:28, 16] = 0.9

    # Let's test an algorithm:
    # Feature 1: Spatial Grid (4x4 zones = 16 features)
    # Feature 2: IoU (Intersection over Union) with soft overlap
    # Feature 3: Directional gradients / centroid alignment
    # Feature 4: Penalty for excessive stray ink
    def score_match(u_arr, t_arr):
        u_bin = u_arr > 0.15
        t_bin = t_arr > 0.15
        
        u_count = np.sum(u_bin)
        t_count = np.sum(t_bin)
        if u_count == 0 or t_count == 0:
            return 0.0
        
        # 1. Direct overlap (Intersection)
        intersection = np.sum(u_bin & t_bin)
        union = np.sum(u_bin | t_bin)
        iou = intersection / union if union > 0 else 0.0
        
        # 2. Precision (How much of user drawing is actually in the letter)
        precision = intersection / u_count if u_count > 0 else 0.0
        
        # 3. Recall (How much of the letter did the user cover)
        recall = intersection / t_count if t_count > 0 else 0.0
        
        # 4. F1 Score
        f1 = (2 * precision * recall) / (precision + recall) if (precision + recall) > 0 else 0.0
        
        # 5. Soft cosine similarity on smoothed tensors
        dot = np.sum(u_arr * t_arr)
        norm_u = np.linalg.norm(u_arr)
        norm_t = np.linalg.norm(t_arr)
        cos = dot / (norm_u * norm_t) if (norm_u * norm_t) > 0 else 0.0
        
        # 6. Grid zone 4x4 correlation
        u_grid = u_arr.reshape(4, 8, 4, 8).mean(axis=(1, 3)).flatten()
        t_grid = t_arr.reshape(4, 8, 4, 8).mean(axis=(1, 3)).flatten()
        grid_dot = np.dot(u_grid, t_grid) / (np.linalg.norm(u_grid) * np.linalg.norm(t_grid) + 1e-6)
        
        # 7. Density balance penalty
        density_ratio = min(u_count / (t_count + 1e-6), t_count / (u_count + 1e-6))
        
        # Final combined score
        # Precision & F1 strongly punish scribbles!
        # Recall & Density ratio strongly punish single lines / missing parts!
        # Grid correlation & Cosine distinguish subtle letter shapes!
        combined = 0.35 * f1 + 0.25 * iou + 0.25 * cos + 0.15 * grid_dot
        combined = combined * (density_ratio ** 0.5)
        
        return float(combined)

    # 7. Hand-drawn 'அ' (slightly imperfect with strokes)
    img_hand_a = Image.new("L", (128, 128), 0)
    d_ha = ImageDraw.Draw(img_hand_a)
    # Child draws loop at top-left
    d_ha.arc([22, 25, 68, 72], start=0, end=360, fill=255, width=12)
    # Loop tail to middle
    d_ha.line([(45, 68), (45, 95), (105, 95)], fill=255, width=12)
    # Vertical line on right
    d_ha.line([(105, 20), (105, 110)], fill=255, width=12)
    arr_hand_a = np.array(img_hand_a.resize((32, 32), Image.Resampling.BILINEAR), dtype=np.float32) / 255.0

    test_inputs = [
        ("Simulated Hand-drawn 'அ'", arr_hand_a, "அ"),
        ("Font 'அ'", img_a, "அ"),
        ("Font 'ஆ'", img_aa, "ஆ"),
        ("Font 'ட்'", img_da, "ட்"),
        ("Font 'க்'", img_k, "க்"),
        ("Scribble", scribble, "அ"),
        ("Single Vertical Line", line, "அ"),
    ]

    for name, user_input, expected in test_inputs:
        results = []
        for l in labels:
            sc = score_match(user_input, templates[l])
            results.append((l, sc))
        results.sort(key=lambda x: x[1], reverse=True)
        top1 = results[0]
        top_exp = next(r for r in results if r[0] == expected)
        print(f"\n--- Test: {name} (Expected: '{expected}') ---")
        print(f"  Top 1 Predicted: '{top1[0]}' (Score: {top1[1]*100:.1f}%)")
        print(f"  Expected Match '{expected}': (Score: {top_exp[1]*100:.1f}%)")
        print(f"  Top 3: {[(r[0], f'{r[1]*100:.1f}%') for r in results[:3]]}")


if __name__ == "__main__":
    main()
