import sys
import os
import json
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

sys.stdout.reconfigure(encoding='utf-8')

train_dir = "d:/Selva Mac/Projects/tamil/ai_model/dataset/train"
labels_path = "d:/Selva Mac/Projects/tamil/frontend/assets/ml/labels.txt"
output_json = "d:/Selva Mac/Projects/tamil/frontend/assets/ml/character_templates.json"

with open(labels_path, 'r', encoding='utf-8') as f:
    labels = [l.strip() for l in f if l.strip()]

sys.path.append("d:/Selva Mac/Projects/tamil/ai_model/training")
from preprocess import preprocess_image

templates_dict = {}

for label in labels:
    class_dir = os.path.join(train_dir, label)
    if not os.path.exists(class_dir):
        print(f"Warning: directory not found for {label}")
        continue
    
    img_files = [os.path.join(class_dir, f) for f in os.listdir(class_dir) if f.lower().endswith(('.bmp', '.png', '.jpg', '.jpeg'))]
    if not img_files:
        print(f"Warning: no images for {label}")
        continue
    
    accum = np.zeros((32, 32), dtype=np.float32)
    count = 0
    for img_path in img_files[:200]:
        try:
            im = Image.open(img_path).convert('L')
            arr = np.array(im)
            if np.mean(arr) > 128:
                im = Image.fromarray(255 - arr)
            proc = preprocess_image(im, target_size=(32, 32))
            accum += proc
            count += 1
        except Exception as e:
            continue
            
    if count > 0:
        mean_img = accum / count
        max_v = np.max(mean_img)
        if max_v > 0:
            mean_img = mean_img / max_v
        
        field = gaussian_filter(mean_img, sigma=1.2)
        norm_f = np.linalg.norm(field)
        if norm_f > 0:
            field = field / norm_f
            
        templates_dict[label] = {
            "raw": mean_img.round(3).tolist(),
            "field": field.round(3).tolist()
        }
        print(f"Generated authentic template for '{label}' from {count} handwritten images.")

with open(output_json, 'w', encoding='utf-8') as f:
    json.dump({"labels": labels, "templates": templates_dict}, f, ensure_ascii=False)

print(f"\nSuccessfully saved {len(templates_dict)} authentic handwritten templates to {output_json}!")
