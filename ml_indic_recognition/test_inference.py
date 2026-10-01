import os
import sys
import io

# Force UTF-8 on Windows stdout/stderr
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

import torch
import torch.nn as nn
from PIL import Image, ImageDraw, ImageFont
import torchvision.transforms as transforms

# 1. Define Model Architecture
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

# 2. Load Model Checkpoint
checkpoint_path = r"d:\Selva Mac\Projects\tamil\ml_indic_recognition\tamil_best.pth"
ckpt = torch.load(checkpoint_path, map_location="cpu", weights_only=False)
model = ScriptCNN(num_classes=156)
model.load_state_dict(ckpt['state_dict'], strict=True)
model.eval()

print("Model loaded successfully!")
print(f"Total model parameters: {sum(p.numel() for p in model.parameters()):,}")

# 3. Test Tamil Characters: அ, ஆ, இ, ஈ, etc.
test_chars = ['அ', 'ஆ', 'இ', 'ஈ', 'உ', 'ஊ', 'எ', 'ஏ', 'ஐ', 'ஒ', 'ஓ', 'ஔ', 'ஃ', 'க்', 'க']

font_path = "C:/Windows/Fonts/Nirmala.ttc"
font = ImageFont.truetype(font_path, 84, index=0)

os.makedirs(r"d:\Selva Mac\Projects\tamil\ml_indic_recognition\sample_images", exist_ok=True)

def generate_sample_image(char, invert=True):
    # Render at high resolution with anti-aliasing
    img = Image.new("L", (160, 160), color=0 if invert else 255)
    draw = ImageDraw.Draw(img)
    
    bbox = draw.textbbox((0, 0), char, font=font)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    x = (160 - w) // 2 - bbox[0]
    y = (160 - h) // 2 - bbox[1]
    draw.text((x, y), char, fill=255 if invert else 0, font=font)
    
    # Resize to exact model input: 64x64
    img_64 = img.resize((64, 64), Image.Resampling.BILINEAR)
    return img_64

transform_standard = transforms.Compose([
    transforms.ToTensor(), # Converts [0..255] PIL Image to float32 Tensor [0.0..1.0] with shape [1, 64, 64]
])

print("\n==========================================================================")
print("Testing Official ScriptCNN Tamil Model on Target Characters: அ, ஆ, இ, ஈ")
print("==========================================================================")

predictions = []

for char in test_chars:
    # 1. White stroke on Black background (standard binary mask for handwriting/canvas)
    img_inv = generate_sample_image(char, invert=True)
    img_inv.save(rf"d:\Selva Mac\Projects\tamil\ml_indic_recognition\sample_images\{char}_white_on_black.png")
    
    # 2. Black stroke on White background (paper document scan)
    img_norm = generate_sample_image(char, invert=False)
    img_norm.save(rf"d:\Selva Mac\Projects\tamil\ml_indic_recognition\sample_images\{char}_black_on_white.png")
    
    t_inv = transform_standard(img_inv).unsqueeze(0)
    t_norm = transform_standard(img_norm).unsqueeze(0)
    
    with torch.no_grad():
        out_inv = model(t_inv)
        out_norm = model(t_norm)
        
        prob_inv = torch.softmax(out_inv, dim=1)
        prob_norm = torch.softmax(out_norm, dim=1)
        
        top3_inv = torch.topk(prob_inv, 3, dim=1)
        top3_norm = torch.topk(prob_norm, 3, dim=1)
        
        pred_idx_inv = top3_inv.indices[0][0].item()
        conf_inv = top3_inv.values[0][0].item()
        
        pred_idx_norm = top3_norm.indices[0][0].item()
        conf_norm = top3_norm.values[0][0].item()
        
    print(f"\nCharacter: '{char}' (Unicode: U+{ord(char):04X})")
    print(f"  ▶ [White-on-Black Canvas] Predicted Class ID: {pred_idx_inv:3d} | Confidence: {conf_inv * 100:.2f}% | Top-3 IDs: {top3_inv.indices[0].tolist()}")
    print(f"  ▶ [Black-on-White Paper]  Predicted Class ID: {pred_idx_norm:3d} | Confidence: {conf_norm * 100:.2f}% | Top-3 IDs: {top3_norm.indices[0].tolist()}")
    
    predictions.append({
        'char': char,
        'unicode': f"U+{ord(char):04X}",
        'class_inv': pred_idx_inv,
        'conf_inv': conf_inv,
        'class_norm': pred_idx_norm,
        'conf_norm': conf_norm
    })

print("\n==========================================================================")
print("Class ID Alignment Table for Uyir / Mei letters:")
print("==========================================================================")
for p in predictions:
    print(f"Letter: {p['char']} ({p['unicode']})  -->  Model Class ID: {p['class_inv']} (conf: {p['conf_inv']*100:.1f}%)")
