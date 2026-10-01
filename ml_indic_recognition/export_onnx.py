import os
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

import torch
import torch.nn as nn
import onnx
import onnxruntime as ort
import numpy as np

# 1. Define Model
class ScriptCNN(nn.Module):
    def __init__(self, num_classes=156):
        super().__init__()
        self.features = nn.Sequential(
            nn.Conv2d(1, 32, kernel_size=3, padding=1, bias=False),
            nn.BatchNorm2d(32),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(kernel_size=2, stride=2),
            
            nn.Conv2d(32, 64, kernel_size=3, padding=1, bias=False),
            nn.BatchNorm2d(64),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(kernel_size=2, stride=2),
            
            nn.Conv2d(64, 128, kernel_size=3, padding=1, bias=False),
            nn.BatchNorm2d(128),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(kernel_size=2, stride=2),
            
            nn.Conv2d(128, 256, kernel_size=3, padding=1, bias=False),
            nn.BatchNorm2d(256),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(kernel_size=2, stride=2),
        )
        self.classifier = nn.Sequential(
            nn.Flatten(),
            nn.Linear(256 * 4 * 4, 512),
            nn.ReLU(inplace=True),
            nn.Dropout(p=0.5),
            nn.Linear(512, num_classes),
        )

    def forward(self, x):
        x = self.features(x)
        x = self.classifier(x)
        return x

checkpoint_path = r"d:\Selva Mac\Projects\tamil\ml_indic_recognition\tamil_best.pth"
ckpt = torch.load(checkpoint_path, map_location="cpu", weights_only=False)

model = ScriptCNN(num_classes=156)
model.load_state_dict(ckpt['state_dict'], strict=True)
model.eval()

onnx_output_path = r"d:\Selva Mac\Projects\tamil\ml_indic_recognition\tamil_script_cnn.onnx"
dummy_input = torch.randn(1, 1, 64, 64, dtype=torch.float32)

print("Exporting PyTorch model to ONNX...")
torch.onnx.export(
    model,
    dummy_input,
    onnx_output_path,
    export_params=True,
    opset_version=14,
    do_constant_folding=True,
    input_names=['input'],
    output_names=['output'],
    dynamic_axes={'input': {0: 'batch_size'}, 'output': {0: 'batch_size'}}
)

print(f"ONNX Model saved to: {onnx_output_path}")
print(f"ONNX File Size: {os.path.getsize(onnx_output_path):,} bytes ({os.path.getsize(onnx_output_path) / (1024*1024):.2f} MB)")

# Verify ONNX model
onnx_model = onnx.load(onnx_output_path)
onnx.checker.check_model(onnx_model)
print("ONNX model verification passed!")

# Test numerical equivalence between PyTorch and ONNX Runtime
ort_session = ort.InferenceSession(onnx_output_path)

with torch.no_grad():
    pytorch_out = model(dummy_input).numpy()

ort_inputs = {ort_session.get_inputs()[0].name: dummy_input.numpy()}
ort_out = ort_session.run(None, ort_inputs)[0]

max_diff = np.max(np.abs(pytorch_out - ort_out))
print(f"Max numerical difference between PyTorch and ONNX: {max_diff:.8f}")

if max_diff < 1e-4:
    print(" PERFECT NUMERICAL PARITY CONFIRMED!")
else:
    print(f" Warning: Numerical difference is {max_diff}")
