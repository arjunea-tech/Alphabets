import os
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

import torch
import torch.nn as nn
from PIL import Image, ImageDraw, ImageFont
import numpy as np

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

# Let's inspect weights of the first layer (features.0.weight) to understand input expectation
first_conv_weight = model.features[0].weight.data # shape [32, 1, 3, 3]
print("First Conv layer weight stats:")
print(f"  Mean: {first_conv_weight.mean().item():.4f}")
print(f"  Std:  {first_conv_weight.std().item():.4f}")
print(f"  Min:  {first_conv_weight.min().item():.4f}, Max: {first_conv_weight.max().item():.4f}")

# Inspect Batch Normalization running mean and var of first layer
bn1_mean = model.features[1].running_mean.data
bn1_var = model.features[1].running_var.data
print("\nFirst BatchNorm layer stats (gives insight into training distribution!):")
print(f"  Running Mean min/max: {bn1_mean.min().item():.4f} / {bn1_mean.max().item():.4f} (avg: {bn1_mean.mean().item():.4f})")
print(f"  Running Var  min/max: {bn1_var.min().item():.4f} / {bn1_var.max().item():.4f} (avg: {bn1_var.mean().item():.4f})")

# Let's test with real hand-drawn strokes (e.g. simulating the user writing 'அ', 'ஆ', 'இ', 'ஈ')
def draw_handwritten_a():
    img = Image.new("L", (128, 128), color=0)
    draw = ImageDraw.Draw(img)
    # Draw curves of Tamil letter 'அ'
    points_loop = [(40, 45), (48, 38), (60, 40), (66, 50), (62, 65), (50, 72), (38, 75), (30, 85), (35, 100), (52, 105), (75, 102), (95, 95)]
    points_horizontal = [(62, 65), (85, 65), (95, 65)]
    points_vertical = [(95, 45), (95, 105)]
    
    draw.line(points_loop, fill=255, width=6, joint="curve")
    draw.line(points_horizontal, fill=255, width=6, joint="curve")
    draw.line(points_vertical, fill=255, width=6, joint="curve")
    
    return img.resize((64, 64), Image.Resampling.BILINEAR)

img_a = draw_handwritten_a()
img_a.save(r"d:\Selva Mac\Projects\tamil\ml_indic_recognition\sample_images\drawn_a.png")

t_a = torch.from_numpy(np.array(img_a, dtype=np.float32) / 255.0).unsqueeze(0).unsqueeze(0)
with torch.no_grad():
    out = model(t_a)
    prob = torch.softmax(out, dim=1)
    top5 = torch.topk(prob, 5, dim=1)
    
print("\n--- Testing Hand-drawn 'அ' ---")
print(f"Top 5 classes: {top5.indices[0].tolist()}")
print(f"Top 5 probabilities: {[round(p * 100, 2) for p in top5.values[0].tolist()]}")
