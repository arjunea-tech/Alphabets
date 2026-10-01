import sys
import os
import json
import numpy as np
from PIL import Image
from sklearn.cluster import KMeans
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

templates_dict = {}

N_CLUSTERS = 3  # 3 distinct authentic handwriting prototypes per class

for label in labels:
    class_dir = os.path.join(train_dir, label)
    if not os.path.exists(class_dir):
        print(f"Warning: {class_dir} not found!")
        continue
    
    files = [os.path.join(class_dir, f) for f in os.listdir(class_dir) if f.lower().endswith(('.bmp', '.png', '.jpg'))]
    
    samples = []
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
            
    if not samples:
        continue
        
    X = np.array(samples).reshape(len(samples), -1)
    
    # Run K-Means to find N representative handwriting centroids
    kmeans = KMeans(n_clusters=min(N_CLUSTERS, len(samples)), random_state=42, n_init=10)
    kmeans.fit(X)
    
    centroids = kmeans.cluster_centers_.reshape(-1, TARGET_DIMENSION, TARGET_DIMENSION)
    
    prototypes = []
    for c in centroids:
        # Normalize peak intensity
        max_v = c.max()
        if max_v > 0:
            c_norm = c / max_v
        else:
            c_norm = c
        prototypes.append(c_norm.round(3).tolist())
        
    # Primary prototype is the overall mean
    mean_img = np.mean(samples, axis=0)
    max_m = mean_img.max()
    if max_m > 0:
        mean_img = mean_img / max_m
        
    blurred = gaussian_filter(mean_img, sigma=1.0)
    norm_b = np.linalg.norm(blurred)
    if norm_b > 0:
        blurred = blurred / norm_b
        
    templates_dict[label] = {
        "raw": mean_img.round(3).tolist(),
        "prototypes": prototypes,
        "field": blurred.round(3).tolist()
    }
    print(f"Generated {len(prototypes)} authentic prototypes for '{label}' from {len(samples)} samples.")

with open(output_json, "w", encoding="utf-8") as f:
    json.dump({"labels": labels, "templates": templates_dict}, f, ensure_ascii=False)

print(f"\nSaved multi-prototype authentic bank for {len(templates_dict)} classes to {output_json}!")
