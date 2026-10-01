import sys
import os
import re
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy.ndimage import gaussian_filter

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

sys.path.append("ai_model/training")
from preprocess import preprocess_strokes_to_image, preprocess_image, TARGET_DIMENSION

stroke_file = "frontend/lib/data/tamil_stroke_data.dart"
labels_file = "frontend/assets/ml/labels.txt"
output_json = "frontend/assets/ml/character_templates.json"

with open(labels_file, "r", encoding="utf-8") as f:
    labels = [l.strip() for l in f if l.strip()]

with open(stroke_file, "r", encoding="utf-8") as f:
    dart_code = f.read()

font_path = "C:\\Windows\\Fonts\\Nirmala.ttc"
font_large = ImageFont.truetype(font_path, 110)
font_medium = ImageFont.truetype(font_path, 80)
font_small = ImageFont.truetype(font_path, 65)

def render_font_clean(char):
    img = Image.new("L", (256, 256), 0)
    draw = ImageDraw.Draw(img)
    if char == "ஊ":
        bbox_u = draw.textbbox((0, 0), "உ", font=font_large)
        tw_u = bbox_u[2] - bbox_u[0]
        th_u = bbox_u[3] - bbox_u[1]
        bbox_la = draw.textbbox((0, 0), "ள", font=font_small)
        tw_la = bbox_la[2] - bbox_la[0]
        th_la = bbox_la[3] - bbox_la[1]
        draw.text((25 - bbox_u[0], 50 - bbox_u[1]), "உ", font=font_large, fill=255)
        draw.text((150 - bbox_la[0], 35 - bbox_la[1]), "ள", font=font_small, fill=255)
    elif char == "ஔ":
        bbox_o = draw.textbbox((0, 0), "ஒ", font=font_medium)
        tw_o = bbox_o[2] - bbox_o[0]
        th_o = bbox_o[3] - bbox_o[1]
        bbox_la = draw.textbbox((0, 0), "ள", font=font_medium)
        tw_la = bbox_la[2] - bbox_la[0]
        th_la = bbox_la[3] - bbox_la[1]
        draw.text((20 - bbox_o[0], 65 - bbox_o[1]), "ஒ", font=font_medium, fill=255)
        draw.text((135 - bbox_la[0], 65 - bbox_la[1]), "ள", font=font_medium, fill=255)
    else:
        bbox = draw.textbbox((0, 0), char, font=font_large)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        draw.text(((256 - tw) // 2 - bbox[0], (256 - th) // 2 - bbox[1]), char, font=font_large, fill=255)
    return preprocess_image(img, target_size=(TARGET_DIMENSION, TARGET_DIMENSION))

templates_dict = {}

dart_letter_strokes = {}
for l in labels:
    # Find start of letter block
    key_str = f"'{l}':"
    idx = dart_code.find(key_str)
    if idx != -1:
        # Find next letter or end
        end_idx = dart_code.find("TamilWritingLetter(", idx)
        if end_idx != -1:
            # Grab up to next letter entry or 4000 chars
            chunk = dart_code[end_idx:end_idx+3500]
            # Extract LetterStrokeData blocks
            sb_matches = re.findall(r"LetterStrokeData\((.*?)\),", chunk, re.DOTALL)
            strokes = []
            for sb in sb_matches:
                pts = []
                for pm in re.finditer(r"Offset\(\s*([0-9.]+)\s*,\s*([0-9.]+)\s*\)", sb):
                    pts.append((float(pm.group(1)) * 350.0, float(pm.group(2)) * 350.0))
                if pts:
                    strokes.append(pts)
            if strokes:
                dart_letter_strokes[l] = strokes

print(f"Extracted stroke paths for {len(dart_letter_strokes)} letters from TamilStrokeDataRepository.")

for label in labels:
    font_t = render_font_clean(label)
    prototypes = [font_t.round(3).tolist()]
    
    if label in dart_letter_strokes:
        strokes = dart_letter_strokes[label]
        dart_t = preprocess_strokes_to_image(strokes, canvas_size=(350, 350), target_size=(32, 32))
        prototypes.append(dart_t.round(3).tolist())
        mean_t = (font_t + dart_t) / 2.0
    else:
        mean_t = font_t
        
    blurred = gaussian_filter(mean_t, sigma=1.0)
    norm_b = np.linalg.norm(blurred)
    if norm_b > 0:
        blurred = blurred / norm_b
        
    templates_dict[label] = {
        "raw": mean_t.round(3).tolist(),
        "prototypes": prototypes,
        "field": blurred.round(3).tolist()
    }
    print(f"Class '{label}': {len(prototypes)} prototypes loaded.")

with open(output_json, "w", encoding="utf-8") as f:
    json.dump({"labels": labels, "templates": templates_dict}, f, ensure_ascii=False)

print(f"\nSaved templates for {len(templates_dict)} classes to {output_json}!")
