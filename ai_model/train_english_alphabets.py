import os
import sys
import time
import random
import string
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import TensorDataset, DataLoader

# Flush all prints immediately
def log(msg):
    print(msg, flush=True)

# -------------------------------------------------------------
# 1. Architecture: ScriptCNN (Compatible with existing system)
# -------------------------------------------------------------
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

# -------------------------------------------------------------
# 2. English Letters List (A-Z)
# -------------------------------------------------------------
LETTERS = list(string.ascii_uppercase) # 26 letters: A-Z

CANDIDATE_FONTS = [
    "C:/Windows/Fonts/arial.ttf",
    "C:/Windows/Fonts/arialbd.ttf",
    "C:/Windows/Fonts/comic.ttf",
    "C:/Windows/Fonts/comicbd.ttf",
    "C:/Windows/Fonts/calibri.ttf",
    "C:/Windows/Fonts/calibrib.ttf",
    "C:/Windows/Fonts/segoeui.ttf",
    "C:/Windows/Fonts/segoeuib.ttf",
    "C:/Windows/Fonts/consola.ttf",
    "C:/Windows/Fonts/georgia.ttf",
    "C:/Windows/Fonts/times.ttf",
    "C:/Windows/Fonts/tahoma.ttf",
    "C:/Windows/Fonts/trebuc.ttf",
    "C:/Windows/Fonts/verdana.ttf",
]
VALID_FONTS = [f for f in CANDIDATE_FONTS if os.path.exists(f)]
if not VALID_FONTS:
    VALID_FONTS = ["C:/Windows/Fonts/arial.ttf"]

log(f"Pre-loading {len(VALID_FONTS)} fonts into memory...")
PRELOADED_FONTS = []
for f in VALID_FONTS:
    for sz in [65, 75, 85, 95]:
        try:
            PRELOADED_FONTS.append(ImageFont.truetype(f, sz))
        except Exception:
            pass

log(f"Loaded {len(PRELOADED_FONTS)} font variants in memory.")

# -------------------------------------------------------------
# 3. Generate Augmented In-Memory Dataset
# -------------------------------------------------------------
def generate_dataset(samples_per_class=300, is_train=True):
    log(f"Generating {'Training' if is_train else 'Validation'} samples in RAM ({samples_per_class} per letter x 26 = {samples_per_class * 26} total)...")
    images_list = []
    labels_list = []
    
    t0 = time.time()
    for class_idx, char in enumerate(LETTERS):
        for _ in range(samples_per_class):
            font = random.choice(PRELOADED_FONTS)
            img = Image.new("L", (160, 160), color=0)
            draw = ImageDraw.Draw(img)
            
            bbox = draw.textbbox((0, 0), char, font=font)
            w = bbox[2] - bbox[0]
            h = bbox[3] - bbox[1]
            
            jitter_x = random.randint(-14, 14) if is_train else 0
            jitter_y = random.randint(-14, 14) if is_train else 0
            x = (160 - w) // 2 - bbox[0] + jitter_x
            y = (160 - h) // 2 - bbox[1] + jitter_y
            
            stroke_width = random.choice([0, 1, 2, 3]) if is_train else 1
            draw.text((x, y), char, fill=255, font=font, stroke_width=stroke_width, stroke_fill=255)
            
            if is_train:
                angle = random.uniform(-18, 18)
                img = img.rotate(angle, resample=Image.Resampling.BILINEAR)
                if random.random() > 0.5:
                    shear = random.uniform(-0.15, 0.15)
                    matrix = (1, shear, 0, 0, 1, 0)
                    img = img.transform((160, 160), Image.Transform.AFFINE, matrix, Image.Resampling.BILINEAR)
                    
            img_64 = img.resize((64, 64), Image.Resampling.BILINEAR)
            arr = np.array(img_64, dtype=np.float32) / 255.0
            
            if is_train and random.random() > 0.7:
                noise = np.random.normal(0, 0.02, arr.shape).astype(np.float32)
                arr = np.clip(arr + noise, 0.0, 1.0)
                
            images_list.append(arr[np.newaxis, :, :])
            labels_list.append(class_idx)
            
    images_tensor = torch.from_numpy(np.array(images_list, dtype=np.float32))
    labels_tensor = torch.tensor(labels_list, dtype=torch.long)
    log(f"Generated {len(images_tensor)} samples in {time.time() - t0:.2f}s! Tensor shape: {images_tensor.shape}")
    return TensorDataset(images_tensor, labels_tensor)

# -------------------------------------------------------------
# 4. Training Routine
# -------------------------------------------------------------
def main():
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    log(f"Training on device: {device}")
    
    train_dataset = generate_dataset(samples_per_class=350, is_train=True) # 9,100 samples
    val_dataset = generate_dataset(samples_per_class=60, is_train=False)    # 1,560 samples
    
    train_loader = DataLoader(train_dataset, batch_size=64, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=64, shuffle=False)
    
    model = ScriptCNN(num_classes=26).to(device)
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.AdamW(model.parameters(), lr=1e-3, weight_decay=1e-4)
    scheduler = optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=8)
    
    epochs = 8
    best_acc = 0.0
    output_dir = os.path.dirname(os.path.abspath(__file__))
    best_checkpoint_path = os.path.join(output_dir, "english_best.pth")
    
    log(f"\n=======================================================")
    log(f"Training ScriptCNN on 26 English Alphabets (A - Z)")
    log(f"=======================================================")
    
    for epoch in range(1, epochs + 1):
        t_epoch_start = time.time()
        model.train()
        total_loss = 0.0
        correct = 0
        total = 0
        
        for images, labels in train_loader:
            images, labels = images.to(device), labels.to(device)
            optimizer.zero_grad()
            outputs = model(images)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()
            
            total_loss += loss.item() * images.size(0)
            _, predicted = outputs.max(1)
            total += labels.size(0)
            correct += predicted.eq(labels).sum().item()
            
        scheduler.step()
        train_acc = 100.0 * correct / total
        train_loss = total_loss / total
        
        # Validation
        model.eval()
        val_correct = 0
        val_total = 0
        with torch.no_grad():
            for images, labels in val_loader:
                images, labels = images.to(device), labels.to(device)
                outputs = model(images)
                _, predicted = outputs.max(1)
                val_total += labels.size(0)
                val_correct += predicted.eq(labels).sum().item()
                
        val_acc = 100.0 * val_correct / val_total
        dur = time.time() - t_epoch_start
        log(f"Epoch [{epoch}/{epochs}] ({dur:4.1f}s) | Train Loss: {train_loss:.4f} | Train Acc: {train_acc:5.2f}% | Val Acc: {val_acc:5.2f}%")
        
        if val_acc > best_acc:
            best_acc = val_acc
            torch.save({
                'epoch': epoch,
                'state_dict': model.state_dict(),
                'val_acc': val_acc,
                'classes': LETTERS
            }, best_checkpoint_path)
            
    log(f"\nTraining Complete! Best Accuracy: {best_acc:.2f}%")
    log(f"Saved Checkpoint: {best_checkpoint_path}")
    
    # -------------------------------------------------------------
    # 5. Export to ONNX
    # -------------------------------------------------------------
    log("\nExporting model to ONNX...")
    model.eval()
    onnx_path = os.path.join(output_dir, "english_script_cnn.onnx")
    dummy_input = torch.randn(1, 1, 64, 64, dtype=torch.float32).to(device)
    
    torch.onnx.export(
        model,
        dummy_input,
        onnx_path,
        export_params=True,
        opset_version=14,
        do_constant_folding=True,
        input_names=['input'],
        output_names=['output'],
        dynamic_axes={'input': {0: 'batch_size'}, 'output': {0: 'batch_size'}}
    )
    log(f"Exported ONNX: {onnx_path} ({os.path.getsize(onnx_path) / 1024:.1f} KB)")
    
    # Copy to frontend assets
    frontend_ml_dir = os.path.abspath(os.path.join(output_dir, "../frontend/assets/ml"))
    if os.path.exists(frontend_ml_dir):
        frontend_onnx = os.path.join(frontend_ml_dir, "english_script_cnn.onnx")
        with open(onnx_path, 'rb') as f_in, open(frontend_onnx, 'wb') as f_out:
            f_out.write(f_in.read())
        log(f"Copied ONNX to frontend assets: {frontend_onnx}")
        
        labels_path = os.path.join(frontend_ml_dir, "english_labels.txt")
        with open(labels_path, "w", encoding="utf-8") as f:
            for l in LETTERS:
                f.write(f"{l}\n")
        log(f"Written labels file: {labels_path}")

    # -------------------------------------------------------------
    # 6. Inference Verification Test (A - Z)
    # -------------------------------------------------------------
    log("\nVerifying ONNX model on all 26 letters (A to Z)...")
    import onnxruntime as ort
    session = ort.InferenceSession(onnx_path)
    
    correct_count = 0
    font = PRELOADED_FONTS[0]
    for idx, char in enumerate(LETTERS):
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
        
        status = "PASS" if pred_char == char else f"FAIL (predicted {pred_char})"
        if pred_char == char:
            correct_count += 1
        log(f"  Letter '{char}' -> Predicted '{pred_char}' ({conf:5.1f}%) | {status}")
        
    log(f"\nFinal Test Score: {correct_count}/26 ({(correct_count/26)*100:.1f}%)")
    log("All steps completed successfully!")

if __name__ == "__main__":
    main()
