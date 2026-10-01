import os
import sys
import io

# Force UTF-8 on Windows stdout/stderr
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

import torch
import torch.nn as nn
from PIL import Image, ImageDraw, ImageFont, ImageOps
import torchvision.transforms as transforms
import numpy as np

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

print("==========================================================================")
print("  T3.7 Tamil Handwriting Classifier (ScriptCNN - 156 classes)")
print("  Model Checkpoint: tamil_best.pth")
print(f"  Training Epoch: {ckpt.get('epoch')}, Validation Accuracy: {ckpt.get('val_acc'):.2f}%")
print("==========================================================================")

font_path = "C:/Windows/Fonts/Nirmala.ttc"
font = ImageFont.truetype(font_path, 110, index=0)

output_dir = r"d:\Selva Mac\Projects\tamil\ml_indic_recognition\sample_images"
os.makedirs(output_dir, exist_ok=True)

def create_centered_character_image(char, size=(64, 64), padding=8):
    """
    Creates a centered, bounded handwritten character image (White stroke on Black background)
    exactly matching the standardized HPL-Tamil dataset preprocessing.
    """
    canvas_size = 200
    img = Image.new("L", (canvas_size, canvas_size), color=0)
    draw = ImageDraw.Draw(img)
    
    # Draw character in center of high-res canvas
    bbox = draw.textbbox((0, 0), char, font=font)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    x = (canvas_size - w) // 2 - bbox[0]
    y = (canvas_size - h) // 2 - bbox[1]
    draw.text((x, y), char, fill=255, font=font)
    
    # Crop to actual bounding box
    bbox_actual = img.getbbox()
    if bbox_actual is None:
        return img.resize(size)
    
    char_crop = img.crop(bbox_actual)
    cw, ch = char_crop.size
    
    # Scale aspect-preserved into target size minus padding
    target_inner_w = size[0] - 2 * padding
    target_inner_h = size[1] - 2 * padding
    scale = min(target_inner_w / cw, target_inner_h / ch)
    new_w = max(1, int(cw * scale))
    new_h = max(1, int(ch * scale))
    
    resized_char = char_crop.resize((new_w, new_h), Image.Resampling.BILINEAR)
    
    # Place in center of 64x64 black canvas
    final_img = Image.new("L", size, color=0)
    paste_x = (size[0] - new_w) // 2
    paste_y = (size[1] - new_h) // 2
    final_img.paste(resized_char, (paste_x, paste_y))
    
    return final_img

# Target test characters requested by user: அ, ஆ, இ, ஈ and others
test_characters = [
    ('அ', 'Uyir - A'),
    ('ஆ', 'Uyir - AA'),
    ('இ', 'Uyir - I'),
    ('ஈ', 'Uyir - II'),
    ('உ', 'Uyir - U'),
    ('ஊ', 'Uyir - UU'),
    ('எ', 'Uyir - E'),
    ('ஏ', 'Uyir - EE'),
    ('ஐ', 'Uyir - AI'),
    ('ஒ', 'Uyir - O'),
    ('ஓ', 'Uyir - OO'),
    ('ஔ', 'Uyir - AU'),
    ('ஃ', 'Aytham'),
    ('க', 'Mei/Uyirmei - Ka'),
    ('ச', 'Mei/Uyirmei - Sa'),
    ('த', 'Mei/Uyirmei - Tha'),
    ('ப', 'Mei/Uyirmei - Pa'),
    ('ம', 'Mei/Uyirmei - Ma'),
]

transform = transforms.Compose([
    transforms.ToTensor(), # Produces float32 tensor in range [0.0, 1.0], shape [1, 64, 64]
])

print("\n--- INFERENCE RESULTS FOR SAMPLE TAMIL CHARACTERS ---")

results = []

for char, desc in test_characters:
    img = create_centered_character_image(char, size=(64, 64), padding=8)
    filename = f"sample_{char}.png"
    img.save(os.path.join(output_dir, filename))
    
    tensor = transform(img).unsqueeze(0) # [1, 1, 64, 64]
    
    with torch.no_grad():
        logits = model(tensor)
        probabilities = torch.softmax(logits, dim=1)
        top5 = torch.topk(probabilities, 5, dim=1)
        
    top_indices = top5.indices[0].tolist()
    top_confs = [round(c * 100, 2) for c in top5.values[0].tolist()]
    
    top1_idx = top_indices[0]
    top1_conf = top_confs[0]
    
    print(f"\nCharacter '{char}' ({desc}):")
    print(f"  → Predicted Class ID : {top1_idx}")
    print(f"  → Confidence         : {top1_conf}%")
    print(f"  → Top-5 Class IDs    : {top_indices}")
    print(f"  → Top-5 Probabilities: {top_confs}%")
    
    results.append({
        'char': char,
        'desc': desc,
        'top1_idx': top1_idx,
        'top1_conf': top1_conf,
        'top5_idx': top_indices,
        'top5_conf': top_confs,
    })

print("\n==========================================================================")
print("Summary of Evaluated Core Characters:")
print("==========================================================================")
print(f"{'Character':<12} {'Description':<22} {'Class ID':<10} {'Confidence':<12}")
print("-" * 60)
for r in results:
    print(f"{r['char']:<12} {r['desc']:<22} {r['top1_idx']:<10} {r['top1_conf']:>5.2f}%")
