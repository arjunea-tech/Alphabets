import os
import torch

checkpoint_path = r"d:\Selva Mac\Projects\tamil\ml_indic_recognition\tamil_best.pth"

print(f"Loading checkpoint: {checkpoint_path}")
print(f"File size: {os.path.getsize(checkpoint_path)} bytes")

# Load checkpoint (CPU)
ckpt = torch.load(checkpoint_path, map_location="cpu", weights_only=False)

print(f"\nType of loaded object: {type(ckpt)}")

if isinstance(ckpt, dict):
    print(f"\nKeys in dictionary: {list(ckpt.keys())}")
    for k in ckpt.keys():
        val = ckpt[k]
        if isinstance(val, (torch.Tensor,)):
            print(f"  Key '{k}': Tensor shape={val.shape}, dtype={val.dtype}")
        elif isinstance(val, (list, tuple)):
            print(f"  Key '{k}': List/Tuple of length {len(val)} (first 5: {val[:5]})")
        elif isinstance(val, dict):
            print(f"  Key '{k}': Dict with {len(val)} keys (first 5: {list(val.keys())[:5]})")
            # If it's a state_dict, inspect layer shapes
            if all(isinstance(v, torch.Tensor) for v in list(val.values())[:5]):
                print("    --- Layer breakdown ---")
                for lk, lv in val.items():
                    print(f"    {lk}: shape={list(lv.shape)}, dtype={lv.dtype}")
        else:
            print(f"  Key '{k}': {type(val)} = {val}")
elif isinstance(ckpt, torch.nn.Module):
    print(f"\nDirect nn.Module: {ckpt}")
else:
    print(f"\nOther object: {ckpt}")
