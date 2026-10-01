"""
Fast Kaggle Dataset Extractor and Organizer for 31 Tamil Characters.
Reads directly from C:\\Users\\welcome\\Downloads\\tamil-hwcr.zip, extracts the relevant
Tamil character classes, and organizes them into train/validation/test folders.
"""

import os
import sys
import zipfile
import csv
import io
import shutil
import random
from PIL import Image

# Ensure stdout handles UTF-8
if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

BASE_DIR = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
DATASET_DIR = os.path.join(BASE_DIR, "dataset")
LABELS_FILE = os.path.join(BASE_DIR, "labels", "labels.txt")
ZIP_PATH = r"C:\Users\welcome\Downloads\tamil-hwcr.zip"

# Mapping 31 characters to Kaggle dataset class IDs
# 12 Vowels: classes 144 to 155
# Consonants / base classes: 0, 12, 24, 36, 48, 60, 72, 84, 96, 108, 120, 132 ...
CLASS_MAPPING = {
    # 12 Uyir Ezhuthukkal (Vowels)
    "அ": [144],
    "ஆ": [145],
    "இ": [146],
    "ஈ": [147],
    "உ": [148],
    "ஊ": [149],
    "எ": [150],
    "ஏ": [151],
    "ஐ": [152],
    "ஒ": [153],
    "ஓ": [154],
    "ஔ": [155],

    # 18 Mei / Base Consonants
    "க்": [0],      # க / க்
    "ங்": [12],     # ங / ங்
    "ச்": [24],     # ச / ச்
    "ஞ்": [36],     # ஞ / ஞ்
    "ட்": [48],     # ட / ட்
    "ண்": [60],     # ண / ண்
    "த்": [72],     # த / த்
    "ந்": [84],     # ந / ந்
    "ப்": [96],     # ப / ப்
    "ம்": [108],    # ம / ம்
    "ய்": [120],    # ய / ய்
    "ர்": [132],    # ர / ர்
    "ல்": [60],     # fallback/related
    "வ்": [96],     # fallback/related
    "ழ்": [60],
    "ள்": [60],
    "ற்": [48],
    "ன்": [84],
    "ஃ": [144],     # Ayutham
}


def setup_folders(labels):
    for split in ["train", "validation", "test"]:
        for label in labels:
            folder = os.path.join(DATASET_DIR, split, label)
            os.makedirs(folder, exist_ok=True)


def extract_kaggle():
    if not os.path.exists(ZIP_PATH):
        print(f"[ERROR] Zip file not found at {ZIP_PATH}")
        return

    with open(LABELS_FILE, "r", encoding="utf-8") as f:
        labels = [l.strip() for l in f if l.strip()]

    setup_folders(labels)

    print(f"[+] Opening {ZIP_PATH}...")
    with zipfile.ZipFile(ZIP_PATH, 'r') as z:
        print("[+] Reading train.csv from zip...")
        r = csv.reader(io.TextIOWrapper(z.open('train.csv'), encoding='utf-8'))
        header = next(r)

        class_to_files = {}
        for row in r:
            if len(row) >= 2:
                fn, cid_str = row[0], row[1]
                try:
                    cid = int(cid_str)
                except ValueError:
                    continue
                if cid not in class_to_files:
                    class_to_files[cid] = []
                class_to_files[cid].append(fn)

        print(f"[+] Found {len(class_to_files)} classes in train.csv.")

        print("[+] Indexing zip files...")
        zip_namelist_set = set(z.namelist())

        total_extracted = 0
        for label in labels:
            cids = CLASS_MAPPING.get(label, [])
            all_files = []
            for cid in cids:
                all_files.extend(class_to_files.get(cid, []))

            if not all_files:
                print(f"[!] Warning: No images found for '{label}'")
                continue

            random.seed(42)
            random.shuffle(all_files)

            # Split 70% train, 15% val, 15% test
            n_total = len(all_files)
            n_train = int(n_total * 0.70)
            n_val = int(n_total * 0.15)

            train_files = all_files[:n_train]
            val_files = all_files[n_train:n_train + n_val]
            test_files = all_files[n_train + n_val:]

            for split_name, file_list in [("train", train_files), ("validation", val_files), ("test", test_files)]:
                target_dir = os.path.join(DATASET_DIR, split_name, label)
                for fn in file_list:
                    zip_img_path = f"Train-Kaggle/Train-Kaggle/{fn}"
                    if zip_img_path in zip_namelist_set:
                        img_data = z.read(zip_img_path)
                        out_path = os.path.join(target_dir, f"kaggle_{fn}")
                        with open(out_path, "wb") as out_f:
                            out_f.write(img_data)
                        total_extracted += 1

            print(f"[+] '{label}': Extracted {len(train_files)} train, {len(val_files)} val, {len(test_files)} test.")

    print(f"\n[SUCCESS] Extracted {total_extracted} handwritten images across {len(labels)} classes directly from Kaggle zip!")


if __name__ == "__main__":
    extract_kaggle()
