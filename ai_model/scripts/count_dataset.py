import os
import sys
if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

data_dir = "ai_model/dataset/Train-Kaggle"
if os.path.exists(data_dir):
    classes = os.listdir(data_dir)
    print(f"Total classes found: {len(classes)}")
    total_imgs = 0
    for c in sorted(classes):
        c_path = os.path.join(data_dir, c)
        if os.path.isdir(c_path):
            n = len([f for f in os.listdir(c_path) if f.lower().endswith(('.png', '.jpg', '.jpeg'))])
            total_imgs += n
            print(f"  Class '{c}': {n} images")
    print(f"Total training images: {total_imgs}")
else:
    print("Train directory not found.")
