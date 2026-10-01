"""
Dataset Acquisition & Setup Guide for Tamil Handwritten Character Datasets.
Details public datasets and automatically configures train/validation/test directory structures.
"""

import os
import sys

DATASET_INFO = {
    "hp_tamil": {
        "name": "HP Labs Tamil Isolated Handwritten Character Dataset (IWFHR)",
        "source": "HP Labs India / IWFHR",
        "description": "Contains online/offline handwritten strokes and image samples of Tamil vowels and consonants written by native speakers.",
        "url": "http://hpl.hp.com/india/research/tamil_corpus.html",
        "license": "Research / Educational Use",
        "supported_classes": 156,  # Complete Tamil alphabet
    },
    "iisc_tamil": {
        "name": "IISc MILE Tamil Handwritten Character Dataset",
        "source": "Medical Intelligence and Language Engineering Lab, Indian Institute of Science (IISc)",
        "description": "Standard benchmark dataset of isolated Tamil handwritten characters collected from diverse age groups.",
        "url": "http://mile.ee.iisc.ernet.in/",
        "license": "Academic / Non-Commercial",
        "supported_classes": 156,
    },
    "kaggle_tamil": {
        "name": "Kaggle Tamil Handwritten Characters Dataset",
        "source": "Kaggle Open Datasets",
        "description": "Standardized offline image dataset for Tamil character classification.",
        "url": "https://www.kaggle.com/datasets/gpreda/tamil-handwritten-characters",
        "license": "CC BY-SA 4.0",
        "supported_classes": 31,
    }
}


def setup_directory_structure(base_dir, labels_file):
    """Creates the dataset folder structure for all 31 classes across train, validation, and test."""
    with open(labels_file, "r", encoding="utf-8") as f:
        labels = [line.strip() for line in f if line.strip()]

    splits = ["train", "validation", "test"]
    created_dirs = 0

    for split in splits:
        split_dir = os.path.join(base_dir, "dataset", split)
        os.makedirs(split_dir, exist_ok=True)
        for label in labels:
            class_dir = os.path.join(split_dir, label)
            os.makedirs(class_dir, exist_ok=True)
            created_dirs += 1

    print(f"[OK] Initialized {created_dirs} class directories across train, validation, and test sets.")


def print_dataset_sources():
    print("=" * 65)
    print("TAMIL HANDWRITTEN CHARACTER PUBLIC DATASET SOURCES")
    print("=" * 65)
    for key, info in DATASET_INFO.items():
        print(f"\n[+] {info['name']}")
        print(f"    Source:      {info['source']}")
        print(f"    License:     {info['license']}")
        print(f"    URL:         {info['url']}")
        print(f"    Description: {info['description']}")


def main():
    base_dir = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    labels_file = os.path.join(base_dir, "labels", "labels.txt")

    print_dataset_sources()
    print("\nSetting up local dataset structure...")
    setup_directory_structure(base_dir, labels_file)
    print("\nDataset directories ready at ai_model/dataset/")


if __name__ == "__main__":
    main()
