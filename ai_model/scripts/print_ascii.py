import sys
import json
import numpy as np

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

with open('d:/Selva Mac/Projects/tamil/frontend/assets/ml/character_templates.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

for char in ['அ', 'ஆ', 'ட்', 'ப்']:
    arr = np.array(data['templates'][char]['raw'])
    print(f"\n=== Character: '{char}' ===")
    for y in range(0, 32, 2):
        row = ""
        for x in range(0, 32):
            val = arr[y, x]
            row += "#" if val > 0.3 else ("." if val > 0.05 else " ")
        print(row)
