import sys
if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')
import json
import numpy as np

with open("frontend/assets/ml/character_templates.json", "r", encoding="utf-8") as f:
    data = json.load(f)

templates = data["templates"]
labels = data["labels"]

dart_code = """// Auto-generated Canonical Tamil Multi-Prototype Handwriting Bank
// Covers all 31 Tamil Letters: 12 Uyir + 18 Mei + 1 Aytham

class CanonicalTamilTemplates {
  static const List<String> supportedLetters = [
"""

for l in labels:
    dart_code += f"    '{l}',\n"

dart_code += """  ];

  /// Raw 32x32 prototype arrays for all 31 Tamil characters (flattened 1024 floats)
  static final Map<String, List<List<double>>> rawPrototypes = {
"""

for l in labels:
    protos = templates[l]["prototypes"]
    dart_code += f"    '{l}': [\n"
    for p in protos:
        flat = []
        if isinstance(p[0], list):
            for row in p:
                flat.extend(row)
        else:
            flat = p
        dart_code += "      [\n"
        for r in range(32):
            row_vals = flat[r*32 : (r+1)*32]
            row_str = ", ".join(f"{float(v):.2f}" for v in row_vals)
            dart_code += f"        {row_str},\n"
        dart_code += "      ],\n"
    dart_code += "    ],\n"

dart_code += """  };
}
"""

with open("frontend/lib/data/canonical_tamil_templates.dart", "w", encoding="utf-8") as f:
    f.write(dart_code)

print("Generated frontend/lib/data/canonical_tamil_templates.dart successfully!")
