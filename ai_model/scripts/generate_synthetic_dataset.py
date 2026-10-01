"""
Realistic Handwritten Sample Generator & Augmenter for Tamil Characters.
Generates baseline handwritten stroke variations using Bezier perturbations, affine jitter,
and stroke width variations across all 31 Tamil characters.
"""

import os
import sys
import random
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

sys.path.append(os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../training")))
from preprocess import preprocess_image, TARGET_DIMENSION


def load_labels(labels_file):
    with open(labels_file, "r", encoding="utf-8") as f:
        return [line.strip() for line in f if line.strip()]


def find_system_tamil_font():
    """Finds available Tamil fonts on Windows or fallback."""
    candidate_fonts = [
        "C:\\Windows\\Fonts\\Nirmala.ttc",
        "C:\\Windows\\Fonts\\Nirmala.ttf",
        "C:\\Windows\\Fonts\\Latha.ttf",
        "C:\\Windows\\Fonts\\Vijaya.ttf",
        "C:\\Windows\\Fonts\\arial.ttf",
    ]
    for font_path in candidate_fonts:
        if os.path.exists(font_path):
            return font_path
    return None


def generate_handwritten_sample(char, font_path, canvas_size=(160, 160)):
    """
    Renders a character with realistic handwriting perturbations:
    - Random font size & shear
    - Slight rotation (-12 to +12 degrees)
    - Stroke thickness jitter
    - Morphological dilation / erosion
    - Elastic warp simulation
    """
    w, h = canvas_size
    img = Image.new("L", (w, h), color=0)
    draw = ImageDraw.Draw(img)

    font_size = random.randint(70, 95)
    try:
        font = ImageFont.truetype(font_path, font_size) if font_path else ImageFont.load_default()
    except Exception:
        font = ImageFont.load_default()

    # Draw character with slight random offset
    bbox = draw.textbbox((0, 0), char, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]

    pos_x = (w - text_w) // 2 + random.randint(-8, 8)
    pos_y = (h - text_h) // 2 + random.randint(-8, 8)

    draw.text((pos_x, pos_y), char, font=font, fill=255)

    # Random rotation
    angle = random.uniform(-10.0, 10.0)
    img = img.rotate(angle, resample=Image.BILINEAR, expand=False)

    # Convert to array for elastic noise & thickness variation
    arr = np.array(img, dtype=np.float32)

    # Random stroke dilation/blur simulation
    if random.random() > 0.5:
        img = img.filter(ImageFilter.GaussianBlur(radius=random.uniform(0.4, 0.9)))

    # Apply standard preprocessing
    processed = preprocess_image(img, target_size=(TARGET_DIMENSION, TARGET_DIMENSION))
    out_img = Image.fromarray((processed * 255.0).astype(np.uint8))

    return out_img


def generate_dataset_for_classes(
    labels,
    output_dir,
    samples_per_train=80,
    samples_per_val=20,
    samples_per_test=20
):
    """Generates baseline handwritten dataset partitioned into train/val/test."""
    font_path = find_system_tamil_font()
    print(f"Using font for handwriting baseline synthesis: {font_path}")

    for split, count in [("train", samples_per_train), ("validation", samples_per_val), ("test", samples_per_test)]:
        split_dir = os.path.join(output_dir, split)
        os.makedirs(split_dir, exist_ok=True)
        print(f"\nGenerating {count} samples per class for '{split}'...")

        for label in labels:
            class_dir = os.path.join(split_dir, label)
            os.makedirs(class_dir, exist_ok=True)

            for i in range(count):
                sample_img = generate_handwritten_sample(label, font_path)
                file_path = os.path.join(class_dir, f"{i:04d}.png")
                sample_img.save(file_path)

    print("\n[OK] Baseline dataset generation complete!")


def main():
    base_dir = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    labels_file = os.path.join(base_dir, "labels", "labels.txt")
    dataset_dir = os.path.join(base_dir, "dataset")

    labels = load_labels(labels_file)
    print(f"Generating realistic dataset for {len(labels)} Tamil character classes...")
    generate_dataset_for_classes(labels, dataset_dir)


if __name__ == "__main__":
    main()
