import os
import sys
import io

sys.stdout.reconfigure(encoding='utf-8')
sys.stderr.reconfigure(encoding='utf-8')

import string
import numpy as np
from PIL import Image, ImageDraw, ImageFont

import torch
import torch.nn as nn

# 1. Architecture: ScriptCNN
class ScriptCNN(nn.Module):
    def __init__(self, num_classes=26):
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
            nn.Dropout(p=0.4),
            nn.Linear(512, num_classes),
        )

    def forward(self, x):
        x = self.features(x)
        x = self.classifier(x)
        return x

LETTERS = list(string.ascii_uppercase)
output_dir = os.path.dirname(os.path.abspath(__file__))
ckpt_path = os.path.join(output_dir, "english_best.pth")

print(f"Loading checkpoint from: {ckpt_path}...")
ckpt = torch.load(ckpt_path, map_location="cpu", weights_only=False)
model = ScriptCNN(num_classes=26)
model.load_state_dict(ckpt['state_dict'], strict=True)
model.eval()

print(f"Loaded successfully! Checkpoint Val Acc: {ckpt.get('val_acc', 'N/A')}%")

# Export ONNX
onnx_path = os.path.join(output_dir, "english_script_cnn.onnx")
dummy_input = torch.randn(1, 1, 64, 64, dtype=torch.float32)

print("Exporting model to ONNX...")
torch.onnx.export(
    model,
    dummy_input,
    onnx_path,
    export_params=True,
    opset_version=18,
    do_constant_folding=True,
    input_names=['input'],
    output_names=['output'],
)
print(f"Exported ONNX: {onnx_path} ({os.path.getsize(onnx_path) / 1024:.1f} KB)")

# Copy to frontend assets/ml
frontend_ml_dir = os.path.abspath(os.path.join(output_dir, "../frontend/assets/ml"))
if os.path.exists(frontend_ml_dir):
    frontend_onnx = os.path.join(frontend_ml_dir, "english_script_cnn.onnx")
    with open(onnx_path, 'rb') as f_in, open(frontend_onnx, 'wb') as f_out:
        f_out.write(f_in.read())
    print(f"Copied ONNX to frontend assets: {frontend_onnx}")
    
    labels_path = os.path.join(frontend_ml_dir, "english_labels.txt")
    with open(labels_path, "w", encoding="utf-8") as f:
        for l in LETTERS:
            f.write(f"{l}\n")
    print(f"Written labels file: {labels_path}")

# Run inference test
print("\nVerifying ONNX model on sample letters A-Z:")
import onnxruntime as ort
session = ort.InferenceSession(onnx_path)

font_path = "C:/Windows/Fonts/arial.ttf"
font = ImageFont.truetype(font_path, 80)
correct = 0

for char in LETTERS:
    img = Image.new("L", (160, 160), color=0)
    draw = ImageDraw.Draw(img)
    bbox = draw.textbbox((0, 0), char, font=font)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text(((160 - w) // 2 - bbox[0], (160 - h) // 2 - bbox[1]), char, fill=255, font=font)
    img_64 = img.resize((64, 64), Image.Resampling.BILINEAR)
    arr = (np.array(img_64, dtype=np.float32) / 255.0)[np.newaxis, np.newaxis, :, :]
    
    outputs = session.run(['output'], {'input': arr})[0]
    pred_idx = int(np.argmax(outputs[0]))
    pred_char = LETTERS[pred_idx]
    exp = np.exp(outputs[0] - np.max(outputs[0]))
    prob = exp / np.sum(exp)
    conf = prob[pred_idx] * 100
    
    if pred_char == char:
        correct += 1
        status = "PASS"
    else:
        status = f"FAIL (got {pred_char})"
        
    print(f"  Letter '{char}' -> Predicted '{pred_char}' ({conf:5.1f}%) | {status}")

print(f"\nFinal Accuracy: {correct}/26 ({(correct/26)*100:.1f}%)!")
