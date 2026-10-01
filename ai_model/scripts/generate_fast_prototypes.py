import sys
import os
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy.ndimage import gaussian_filter

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

sys.path.append("ai_model/training")
from preprocess import preprocess_image, TARGET_DIMENSION

train_dir = "ai_model/dataset/train"
labels_file = "frontend/assets/ml/labels.txt"
output_json = "frontend/assets/ml/character_templates.json"

with open(labels_file, "r", encoding="utf-8") as f:
    labels = [l.strip() for l in f if l.strip()]

font_path = "C:\\Windows\\Fonts\\Nirmala.ttc"
font_large = ImageFont.truetype(font_path, 110)
font_medium = ImageFont.truetype(font_path, 80)
font_small = ImageFont.truetype(font_path, 65)

def render_font_template(label):
    img = Image.new("L", (256, 256), 0)
    draw = ImageDraw.Draw(img)
    if label == "ஊ":
        bbox_u = draw.textbbox((0, 0), "உ", font=font_large)
        tw_u = bbox_u[2] - bbox_u[0]
        th_u = bbox_u[3] - bbox_u[1]
        bbox_la = draw.textbbox((0, 0), "ள", font=font_small)
        tw_la = bbox_la[2] - bbox_la[0]
        th_la = bbox_la[3] - bbox_la[1]
        draw.text((25 - bbox_u[0], 50 - bbox_u[1]), "உ", font=font_large, fill=255)
        draw.text((150 - bbox_la[0], 35 - bbox_la[1]), "ள", font=font_small, fill=255)
    elif label == "ஔ":
        bbox_o = draw.textbbox((0, 0), "ஒ", font=font_medium)
        tw_o = bbox_o[2] - bbox_o[0]
        th_o = bbox_o[3] - bbox_o[1]
        bbox_la = draw.textbbox((0, 0), "ள", font=font_medium)
        tw_la = bbox_la[2] - bbox_la[0]
        th_la = bbox_la[3] - bbox_la[1]
        draw.text((20 - bbox_o[0], 65 - bbox_o[1]), "ஒ", font=font_medium, fill=255)
        draw.text((135 - bbox_la[0], 65 - bbox_la[1]), "ள", font=font_medium, fill=255)
    else:
        bbox = draw.textbbox((0, 0), label, font=font_large)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        draw.text(((256 - tw) // 2 - bbox[0], (256 - th) // 2 - bbox[1]), label, font=font_large, fill=255)
    return preprocess_image(img, target_size=(TARGET_DIMENSION, TARGET_DIMENSION))

templates_dict = {}

for label in labels:
    font_t = render_font_template(label)
    
    # Load 40 samples from dataset/train
    class_dir = os.path.join(train_dir, label)
    samples = []
    if os.path.exists(class_dir):
        files = [os.path.join(class_dir, f) for f in os.listdir(class_dir) if f.lower().endswith(('.bmp', '.png', '.jpg'))][:40]
        for fp in files:
            try:
                im = Image.open(fp).convert('L')
                arr = np.array(im)
                if np.mean(arr) > 128:
                    im = Image.fromarray(255 - arr)
                proc = preprocess_image(im, target_size=(TARGET_DIMENSION, TARGET_DIMENSION))
                samples.append(proc)
            except Exception:
                continue
                
    prototypes = [font_t.round(3).tolist()]
    
    if samples:
        # Calculate mean image
        mean_img = np.mean(samples, axis=0)
        max_m = mean_img.max()
        if max_m > 0:
            mean_img = mean_img / max_m
        prototypes.append(mean_img.round(3).tolist())
        
        # Pick 2 diverse medoid samples that have highest variance from mean
        diffs = [np.sum((s - mean_img) ** 2) for s in samples]
        sorted_indices = np.argsort(diffs)
        medoid_idx = sorted_indices[len(samples) // 2]
        variant_idx = sorted_indices[-1]
        prototypes.append(samples[medoid_idx].round(3).tolist())
        prototypes.append(samples[variant_idx].round(3).tolist())
    else:
        mean_img = font_t

    blurred = gaussian_filter(mean_img, sigma=1.0)
    norm_b = np.linalg.norm(blurred)
    if norm_b > 0:
        blurred = blurred / norm_b
        
    templates_dict[label] = {
        "raw": mean_img.round(3).tolist(),
        "prototypes": prototypes,
        "field": blurred.round(3).tolist()
    }
    print(f"Loaded {len(prototypes)} prototypes for '{label}'.")

with open(output_json, "w", encoding="utf-8") as f:
    json.dump({"labels": labels, "templates": templates_dict}, f, ensure_ascii=False)

print(f"\nSuccessfully generated multi-prototype bank for all {len(templates_dict)} classes at {output_json}!")
