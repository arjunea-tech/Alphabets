import sys
import json
import numpy as np

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

with open("frontend/assets/ml/character_templates.json", "r", encoding="utf-8") as f:
    data = json.load(f)

templates = data["templates"]

def smooth(src, passes=2):
    from scipy.ndimage import gaussian_filter
    arr = src.copy()
    for _ in range(passes):
        arr = gaussian_filter(arr, sigma=0.8)
    return arr

t_aa = np.array(templates["ஆ"]["raw"]).reshape(32, 32)
t_i = np.array(templates["இ"]["raw"]).reshape(32, 32)

wide_aa = smooth(t_aa, 2)
wide_i = smooth(t_i, 2)

print(f"Template ஆ active (>0.15): {(t_aa > 0.15).sum()}")
print(f"Template இ active (>0.15): {(t_i > 0.15).sum()}")

# Where does இ have ink where ஆ has NONE?
diff_i_not_aa = (t_i > 0.15) & (t_aa < 0.05)
print(f"Pixels where 'இ' has ink but 'ஆ' has NONE: {diff_i_not_aa.sum()}")

# How much of 'இ' falls into wide_aa > 0.08?
in_wide_aa = (t_i > 0.15) & (wide_aa > 0.08)
print(f"Pixels of 'இ' that fall into wide_aa > 0.08: {in_wide_aa.sum()} / {(t_i > 0.15).sum()} = {in_wide_aa.sum() / (t_i > 0.15).sum():.2f}")

# And what if we use a tighter threshold or chamfer distance?
in_tight_aa = (t_i > 0.15) & (smooth(t_aa, 1) > 0.15)
print(f"Pixels of 'இ' that fall into tight_aa > 0.15: {in_tight_aa.sum()} / {(t_i > 0.15).sum()} = {in_tight_aa.sum() / (t_i > 0.15).sum():.2f}")
