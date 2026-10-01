import sys
import json
import numpy as np

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

with open("frontend/assets/ml/character_templates.json", "r", encoding="utf-8") as f:
    data = json.load(f)

templates = data["templates"]

def print_char(char):
    raw = np.array(templates[char]["raw"]).reshape(32, 32)
    print(f"=== Letter: {char} ===")
    for r in range(0, 32, 2):
        line = ""
        for c in range(32):
            val = (raw[r, c] + raw[min(31, r+1), c]) / 2.0
            if val > 0.4:
                line += "##"
            elif val > 0.15:
                line += ".."
            else:
                line += "  "
        print(line)

print_char("ஊ")
print_char("ஔ")
print_char("ஆ")
print_char("இ")
