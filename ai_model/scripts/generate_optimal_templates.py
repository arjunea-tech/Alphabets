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

labels_file = "frontend/assets/ml/labels.txt"
output_json = "frontend/assets/ml/character_templates.json"

with open(labels_file, "r", encoding="utf-8") as f:
    labels = [l.strip() for l in f if l.strip()]

font_path = "C:\\Windows\\Fonts\\Nirmala.ttc"
font_large = ImageFont.truetype(font_path, 110)
font_medium = ImageFont.truetype(font_path, 80)
font_small = ImageFont.truetype(font_path, 65)

templates_dict = {}

for label in labels:
    img = Image.new("L", (256, 256), 0)
    draw = ImageDraw.Draw(img)
    
    if label == "ஊ":
        # Render 'உ' and 'ள' with clear proportions
        bbox_u = draw.textbbox((0, 0), "உ", font=font_large)
        tw_u = bbox_u[2] - bbox_u[0]
        th_u = bbox_u[3] - bbox_u[1]
        
        bbox_la = draw.textbbox((0, 0), "ள", font=font_small)
        tw_la = bbox_la[2] - bbox_la[0]
        th_la = bbox_la[3] - bbox_la[1]
        
        # 'உ' at left/bottom, 'ள' at top right
        draw.text((25 - bbox_u[0], 50 - bbox_u[1]), "உ", font=font_large, fill=255)
        draw.text((150 - bbox_la[0], 35 - bbox_la[1]), "ள", font=font_small, fill=255)
    elif label == "ஔ":
        # Render 'ஒ' and 'ள' side by side
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
        
    proc_arr = preprocess_image(img, target_size=(TARGET_DIMENSION, TARGET_DIMENSION))
    
    blurred = gaussian_filter(proc_arr, sigma=1.0)
    norm_b = np.linalg.norm(blurred)
    if norm_b > 0:
        blurred = blurred / norm_b
        
    templates_dict[label] = {
        "raw": proc_arr.round(3).tolist(),
        "field": blurred.round(3).tolist()
    }

with open(output_json, "w", encoding="utf-8") as f:
    json.dump({"labels": labels, "templates": templates_dict}, f, ensure_ascii=False)

print(f"Generated clean multi-part templates for all {len(labels)} classes in {output_json}!")
