import sys
import os
import re
import json
import numpy as np

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

sys.path.append("ai_model/training")
from preprocess import preprocess_strokes_to_image

stroke_data_file = "frontend/lib/data/tamil_stroke_data.dart"
with open(stroke_data_file, "r", encoding="utf-8") as f:
    dart_code = f.read()

labels_file = "frontend/assets/ml/labels.txt"
with open(labels_file, "r", encoding="utf-8") as f:
    labels = [l.strip() for l in f if l.strip()]

canonical_templates = {}

for label in labels:
    # Look for 'label': ... TamilWritingLetter(
    pattern = r"'" + re.escape(label) + r"':\s*(?:const\s*)?TamilWritingLetter\((.*?)\n\s*\),"
    m = re.search(pattern, dart_code, re.DOTALL)
    if m:
        body = m.group(1)
        stroke_matches = re.findall(r"pathPoints:\s*(?:const\s*)?\[(.*?)\]", body, re.DOTALL)
        strokes = []
        for sm in stroke_matches:
            pts = []
            for pm in re.finditer(r"Offset\(\s*([0-9.]+)\s*,\s*([0-9.]+)\s*\)", sm):
                x = float(pm.group(1)) * 350.0
                y = float(pm.group(2)) * 350.0
                pts.append((x, y))
            if pts:
                strokes.append(pts)
        if strokes:
            raw_tensor = preprocess_strokes_to_image(strokes, canvas_size=(350, 350), target_size=(32, 32))
            canonical_templates[label] = raw_tensor
            active = (raw_tensor > 0.15).sum()
            print(f"  {label}: {len(strokes)} strokes, {active} active pixels")
        else:
            print(f"  {label}: NO STROKES FOUND IN DART FILE")
    else:
        print(f"  {label}: NOT MATCHED IN DART FILE")

print(f"\nTotal canonical stroke templates loaded from TamilStrokeDataRepository: {len(canonical_templates)} / {len(labels)}")
