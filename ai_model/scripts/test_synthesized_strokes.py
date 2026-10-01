import sys
import os
import json
import numpy as np

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

sys.path.append("ai_model/training")
from preprocess import preprocess_strokes_to_image

with open("frontend/assets/ml/character_templates.json", "r", encoding="utf-8") as f:
    data = json.load(f)

templates = data["templates"]
labels = data["labels"]

# Let's synthesize touch strokes for 'இ'
# A typical 'இ' drawn on 350x350 canvas:
stroke_i_1 = [(150, 100), (130, 90), (110, 110), (130, 130), (160, 130), (200, 120), (230, 140), (240, 170), (230, 200), (200, 210), (150, 200), (120, 220), (110, 250), (130, 270), (160, 270), (200, 260), (240, 270)]
stroke_i_2 = [(110, 250), (150, 250), (200, 250), (250, 250)]

strokes_i = [stroke_i_1, stroke_i_2]
raw_i = preprocess_strokes_to_image(strokes_i, canvas_size=(350, 350), target_size=(32, 32))

# Let's synthesize touch strokes for 'ஆ':
# 1. 'அ' loop
# 2. 'அ' curve & vertical
# 3. bottom loop for 'ஆ'
stroke_aa_1 = [(120, 130), (100, 120), (90, 140), (110, 160), (140, 150), (170, 180), (180, 220), (170, 260), (140, 280), (110, 280)]
stroke_aa_2 = [(150, 220), (230, 220)]
stroke_aa_3 = [(230, 120), (230, 270), (220, 290), (190, 290), (180, 270), (200, 250), (240, 260)]
strokes_aa = [stroke_aa_1, stroke_aa_2, stroke_aa_3]
raw_aa = preprocess_strokes_to_image(strokes_aa, canvas_size=(350, 350), target_size=(32, 32))

# Let's synthesize touch strokes for 'ஊ':
# 1. 'உ'
# 2. 'ள'
stroke_oo_u = [(100, 150), (80, 140), (70, 160), (90, 180), (120, 180), (140, 220), (130, 260), (100, 280), (160, 280), (200, 280)]
stroke_oo_la = [(210, 140), (190, 130), (180, 150), (200, 170), (230, 160), (230, 200), (200, 220), (240, 220)]
strokes_oo = [stroke_oo_u, stroke_oo_la]
raw_oo = preprocess_strokes_to_image(strokes_oo, canvas_size=(350, 350), target_size=(32, 32))

# Let's synthesize touch strokes for 'ஔ':
# 1. 'ஒ'
# 2. 'ள'
stroke_au_o = [(90, 140), (70, 130), (60, 150), (80, 170), (110, 160), (120, 190), (100, 220), (80, 240), (100, 270), (140, 260), (140, 220)]
stroke_au_la = [(190, 160), (170, 150), (160, 170), (180, 190), (210, 180), (210, 220), (180, 240), (220, 240)]
strokes_au = [stroke_au_o, stroke_au_la]
raw_au = preprocess_strokes_to_image(strokes_au, canvas_size=(350, 350), target_size=(32, 32))

from test_dataset_accuracy import evaluate_image

print("Evaluating synthesized stroke inputs:")
print("1. 'இ' strokes when expecting 'இ':", evaluate_image(raw_i, "இ"))
print("2. 'இ' strokes when expecting 'ஆ':", evaluate_image(raw_i, "ஆ"))
print("3. 'ஆ' strokes when expecting 'ஆ':", evaluate_image(raw_aa, "ஆ"))
print("4. 'ஆ' strokes when expecting 'இ':", evaluate_image(raw_aa, "இ"))
print("5. 'ஊ' strokes when expecting 'ஊ':", evaluate_image(raw_oo, "ஊ"))
print("6. 'ஔ' strokes when expecting 'ஔ':", evaluate_image(raw_au, "ஔ"))
