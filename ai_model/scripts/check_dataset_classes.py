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

train_dir = "ai_model/dataset/train"
labels_file = "frontend/assets/ml/labels.txt"

with open(labels_file, "r", encoding="utf-8") as f:
    labels = [l.strip() for l in f if l.strip()]

print(f"Total labels in labels.txt: {len(labels)}")
for l in labels:
    c_dir = os.path.join(train_dir, l)
    if os.path.exists(c_dir):
        files = os.listdir(c_dir)
        print(f"  {l}: {len(files)} training images in dataset/train")
    else:
        print(f"  {l}: NOT FOUND in dataset/train")
