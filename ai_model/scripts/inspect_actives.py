import sys
if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')
import json
import numpy as np

with open("frontend/assets/ml/character_templates.json", "r", encoding="utf-8") as f:
    data = json.load(f)

templates = data["templates"]
for char, tdata in templates.items():
    raws = tdata.get("prototypes") or [tdata.get("raw")]
    actives = [int(np.sum(np.array(r) > 0.15)) for r in raws if r is not None]
    print(f"Char: {char} -> actives: {actives}")

