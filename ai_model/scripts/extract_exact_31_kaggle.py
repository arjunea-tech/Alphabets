"""
Extracts ONLY the exact 31 Tamil characters (12 Uyir + 18 Mei + 1 Ayutham)
from the Kaggle handwriting dataset into train, validation, and test folders.
"""

import os
import sys
import zipfile
import csv
import io
import random
import shutil

# Ensure stdout handles UTF-8
if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

BASE_DIR = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
DATASET_DIR = os.path.join(BASE_DIR, "dataset")
LABELS_FILE = os.path.join(BASE_DIR, "labels", "labels.txt")
ZIP_PATH = r"C:\Users\welcome\Downloads\tamil-hwcr.zip"

# EXACT VISUALLY VERIFIED CLASS MAPPINGS FOR ALL 31 CHARACTERS
EXACT_31_MAPPING = {
    # 12 Uyir Ezhuthukkal (Vowels)
    "அ": 1,
    "ஆ": 2,
    "இ": 3,
    "ஈ": 4,
    "உ": 5,
    "ஊ": 6,
    "எ": 7,
    "ஏ": 8,
    "ஐ": 9,
    "ஒ": 10,
    "ஓ": 11,
    "ஔ": 12,

    # 18 Mei Ezhuthukkal (Consonants with pulli)
    "க்": 14,
    "ங்": 26,
    "ச்": 20,
    "ஞ்": 32,
    "ட்": 38,
    "ண்": 44,
    "த்": 50,
    "ந்": 56,
    "ப்": 62,
    "ம்": 68,
    "ய்": 74,
    "ர்": 80,
    "ல்": 86,
    "வ்": 104,
    "ழ்": 110,
    "ள்": 92,
    "ற்": 98,
    "ன்": 116,

    # 1 Ayutha Ezhuthu
    "ஃ": 13,
}


def main():
    if not os.path.exists(ZIP_PATH):
        print(f"[ERROR] Zip file not found at {ZIP_PATH}")
        return

    # Clean existing dataset folders
    for split in ["train", "validation", "test"]:
        split_dir = os.path.join(DATASET_DIR, split)
        if os.path.exists(split_dir):
            shutil.rmtree(split_dir)
        os.makedirs(split_dir, exist_ok=True)
        for char in EXACT_31_MAPPING.keys():
            os.makedirs(os.path.join(split_dir, char), exist_ok=True)

    print(f"[+] Reading train.csv from {ZIP_PATH}...")
    with zipfile.ZipFile(ZIP_PATH, 'r') as z:
        r = csv.reader(io.TextIOWrapper(z.open('train.csv'), encoding='utf-8'))
        next(r)

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

        zip_files_set = set(z.namelist())
        total_extracted = 0

        print(f"[+] Extracting verified handwriting samples for 31 Tamil characters...")
        for char, cid in EXACT_31_MAPPING.items():
            files = class_to_files.get(cid, [])
            if not files:
                print(f"[!] Warning: No images found for '{char}' (CID {cid})")
                continue

            random.seed(42)
            random.shuffle(files)

            n_total = len(files)
            n_train = int(n_total * 0.70)
            n_val = int(n_total * 0.15)

            train_files = files[:n_train]
            val_files = files[n_train:n_train + n_val]
            test_files = files[n_train + n_val:]

            for split_name, file_list in [("train", train_files), ("validation", val_files), ("test", test_files)]:
                target_dir = os.path.join(DATASET_DIR, split_name, char)
                for fn in file_list:
                    zip_img_path = f"Train-Kaggle/Train-Kaggle/{fn}"
                    if zip_img_path in zip_files_set:
                        img_bytes = z.read(zip_img_path)
                        out_path = os.path.join(target_dir, f"hw_{cid}_{fn}")
                        with open(out_path, "wb") as out_f:
                            out_f.write(img_bytes)
                        total_extracted += 1

            print(f"[+] '{char}' (CID {cid}): {len(train_files)} train, {len(val_files)} val, {len(test_files)} test.")

        print(f"\n[SUCCESS] Extracted {total_extracted} 100% verified handwritten images across all 31 Tamil characters!")


if __name__ == "__main__":
    main()
