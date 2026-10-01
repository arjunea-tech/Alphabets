import os
import sys
import numpy as np
import torch

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

best_weights_path = r"d:\Selva Mac\Projects\tamil\ai_model\models\tamil_scriptcnn_best.pth"
npz_out_path = r"d:\Selva Mac\Projects\tamil\ai_model\models\tamil_scriptcnn_weights.npz"

print(f"Loading PyTorch checkpoint from: {best_weights_path}")
ckpt = torch.load(best_weights_path, map_location="cpu", weights_only=False)
state_dict = ckpt["state_dict"]

numpy_dict = {}
for k, v in state_dict.items():
    numpy_dict[k] = v.detach().cpu().numpy()
    print(f"  {k:30s}: shape {v.shape}")

np.savez(npz_out_path, **numpy_dict)
print(f"\n[OK] Exported all weights to NPZ: {npz_out_path}")
