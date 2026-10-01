import sys
import json
import numpy as np

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

with open("frontend/assets/ml/character_templates.json", "r", encoding="utf-8") as f:
    data = json.load(f)

templates = data["templates"]
for l in ["அ", "ஆ", "இ", "ஊ", "ஔ", "க்", "ஞ்"]:
    raw = np.array(templates[l]["raw"]).flatten()
    unique_vals = len(np.unique(raw))
    print(f"Letter '{l}': unique pixel values = {unique_vals}, min={raw.min()}, max={raw.max()}")
