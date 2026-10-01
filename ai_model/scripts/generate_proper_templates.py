import sys
import os
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy.ndimage import gaussian_filter

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

sys.path.append(os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../training")))
from preprocess import preprocess_image, TARGET_DIMENSION

def main():
    base_dir = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    labels_file = os.path.join(base_dir, "labels", "labels.txt")
    output_json = os.path.join(base_dir, "../frontend/assets/ml/character_templates.json")

    with open(labels_file, "r", encoding="utf-8") as f:
        labels = [l.strip() for l in f if l.strip()]

    font_path = "C:\\Windows\\Fonts\\Nirmala.ttc"
    font = ImageFont.truetype(font_path, 100)

    templates_dict = {}

    for label in labels:
        img = Image.new("L", (200, 200), 0)
        draw = ImageDraw.Draw(img)
        bbox = draw.textbbox((0, 0), label, font=font)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        draw.text(((200 - tw) // 2 - bbox[0], (200 - th) // 2 - bbox[1]), label, font=font, fill=255)

        # Apply standard bounding-box cropping & 15% padding preprocessing
        proc_arr = preprocess_image(img, target_size=(TARGET_DIMENSION, TARGET_DIMENSION))
        
        # Also compute blurred continuous field for rapid on-device chamfer matching
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

    print(f"Successfully generated calibrated templates for {len(labels)} classes at: {output_json}")

if __name__ == "__main__":
    main()
