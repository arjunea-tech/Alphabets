import os
import sys
import glob
import time
import shutil
from collections import defaultdict
from PIL import Image
import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
import torchvision.transforms as transforms

# Ensure utf-8 output on Windows
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

# Define exact Hugging Face ScriptCNN architecture
class ScriptCNN(nn.Module):
    def __init__(self, num_classes=31):
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
        return self.classifier(self.features(x))


def load_labels(labels_file):
    with open(labels_file, "r", encoding="utf-8") as f:
        labels = [line.strip() for line in f if line.strip()]
    return labels


def preprocess_pil_to_64x64(pil_img):
    """
    Standardize stroke image into 64x64 canvas:
    - Invert if background is bright (white -> black bg, strokes white)
    - Threshold noise
    - Auto-crop bounding box
    - Maintain aspect ratio and scale to fit 48x48 box inside 64x64
    """
    arr = np.array(pil_img.convert('L'), dtype=np.float32)
    
    corners = [arr[0, 0], arr[0, -1], arr[-1, 0], arr[-1, -1]]
    if np.mean(corners) > 128:
        arr = 255.0 - arr
        
    arr[arr < 35] = 0
    
    coords = np.argwhere(arr > 35)
    if len(coords) > 0:
        ymin, xmin = coords.min(axis=0)
        ymax, xmax = coords.max(axis=0)
        cropped = arr[ymin:ymax+1, xmin:xmax+1]
        
        ch, cw = cropped.shape
        max_dim = max(ch, cw)
        scale = 48.0 / max_dim
        new_w = max(1, int(round(cw * scale)))
        new_h = max(1, int(round(ch * scale)))
        
        crop_pil = Image.fromarray(cropped.astype(np.uint8))
        resized_pil = crop_pil.resize((new_w, new_h), Image.Resampling.BILINEAR)
        resized_arr = np.array(resized_pil, dtype=np.float32)
        
        canvas = np.zeros((64, 64), dtype=np.float32)
        y_offset = (64 - new_h) // 2
        x_offset = (64 - new_w) // 2
        canvas[y_offset:y_offset+new_h, x_offset:x_offset+new_w] = resized_arr
        arr = canvas
    else:
        arr = np.array(pil_img.resize((64, 64), Image.Resampling.BILINEAR), dtype=np.float32)
        
    return Image.fromarray(arr.astype(np.uint8))


class TamilHandwritingDataset(Dataset):
    def __init__(self, data_dir, labels, is_train=True):
        self.samples = []
        self.label_to_idx = {l: i for i, l in enumerate(labels)}
        self.is_train = is_train
        
        for label in labels:
            folder = os.path.join(data_dir, label)
            if not os.path.isdir(folder):
                continue
            for fname in os.listdir(folder):
                if fname.lower().endswith((".png", ".jpg", ".jpeg", ".bmp")):
                    fpath = os.path.join(folder, fname)
                    self.samples.append((fpath, self.label_to_idx[label]))
                    
        # Augmentations for training
        if self.is_train:
            self.transform = transforms.Compose([
                transforms.RandomRotation(degrees=10),
                transforms.RandomAffine(degrees=0, translate=(0.08, 0.08), scale=(0.92, 1.08)),
                transforms.ToTensor(), # Converts to [0.0, 1.0]
            ])
        else:
            self.transform = transforms.Compose([
                transforms.ToTensor(),
            ])

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        fpath, label_idx = self.samples[idx]
        pil_img = Image.open(fpath)
        clean_pil = preprocess_pil_to_64x64(pil_img)
        tensor = self.transform(clean_pil)
        return tensor, label_idx


def main():
    base_dir = r"d:\Selva Mac\Projects\tamil\ai_model"
    labels_file = os.path.join(base_dir, "labels", "labels.txt")
    dataset_dir = os.path.join(base_dir, "dataset")
    models_dir = os.path.join(base_dir, "models")
    hf_ckpt_path = os.path.join(models_dir, "huggingface", "tamil_best.pth")
    
    labels = load_labels(labels_file)
    num_classes = len(labels)
    
    print("=" * 65)
    print("AGARAM Tamil Handwriting Recognition — ScriptCNN Fine-Tuning")
    print("=" * 65)
    print(f"Total Character Classes: {num_classes}")
    print(f"Hugging Face Pre-trained Checkpoint: {hf_ckpt_path}")
    
    train_ds = TamilHandwritingDataset(os.path.join(dataset_dir, "train"), labels, is_train=True)
    val_ds = TamilHandwritingDataset(os.path.join(dataset_dir, "validation"), labels, is_train=False)
    test_ds = TamilHandwritingDataset(os.path.join(dataset_dir, "test"), labels, is_train=False)
    
    print(f"Dataset Counts -> Train: {len(train_ds)}, Validation: {len(val_ds)}, Test: {len(test_ds)}")
    
    train_loader = DataLoader(train_ds, batch_size=32, shuffle=True, num_workers=0)
    val_loader = DataLoader(val_ds, batch_size=32, shuffle=False, num_workers=0)
    test_loader = DataLoader(test_ds, batch_size=32, shuffle=False, num_workers=0)
    
    # Instantiate Model
    model = ScriptCNN(num_classes=num_classes)
    
    # Load Pre-trained weights from Hugging Face for features & initial dense layer
    if os.path.exists(hf_ckpt_path):
        print("Loading pre-trained feature weights from Hugging Face...")
        ckpt = torch.load(hf_ckpt_path, map_location="cpu", weights_only=False)
        state_dict = ckpt["state_dict"] if "state_dict" in ckpt else ckpt
        
        # Filter out final classifier layer (which was 156 classes)
        filtered_dict = {}
        for k, v in state_dict.items():
            if k.startswith("classifier.4"):
                continue # Skip the 156-class layer
            filtered_dict[k] = v
            
        load_res = model.load_state_dict(filtered_dict, strict=False)
        print(f"Loaded weights successfully! (Skipped: {load_res.unexpected_keys}, Missing: {load_res.missing_keys})")
    
    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.AdamW(model.parameters(), lr=0.001, weight_decay=1e-4)
    scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode='max', factor=0.5, patience=2)
    
    best_val_acc = 0.0
    best_weights_path = os.path.join(models_dir, "tamil_scriptcnn_best.pth")
    
    epochs = 20
    print("\nStarting Training & Fine-Tuning...")
    for epoch in range(1, epochs + 1):
        t0 = time.time()
        model.train()
        train_loss = 0.0
        train_correct = 0
        total_train = 0
        
        for images, targets in train_loader:
            optimizer.zero_grad()
            outputs = model(images)
            loss = criterion(outputs, targets)
            loss.backward()
            optimizer.step()
            
            train_loss += loss.item() * len(targets)
            preds = outputs.argmax(dim=1)
            train_correct += (preds == targets).sum().item()
            total_train += len(targets)
            
        train_acc = (train_correct / total_train) * 100.0
        avg_train_loss = train_loss / total_train
        
        # Validation
        model.eval()
        val_correct = 0
        total_val = 0
        with torch.no_grad():
            for images, targets in val_loader:
                outputs = model(images)
                preds = outputs.argmax(dim=1)
                val_correct += (preds == targets).sum().item()
                total_val += len(targets)
                
        val_acc = (val_correct / total_val) * 100.0 if total_val > 0 else 0.0
        scheduler.step(val_acc)
        elapsed = time.time() - t0
        
        print(f"Epoch [{epoch:2d}/{epochs:2d}] - {elapsed:.1f}s | Train Loss: {avg_train_loss:.4f} | Train Acc: {train_acc:5.2f}% | Val Acc: {val_acc:5.2f}%", end="")
        
        if val_acc > best_val_acc:
            best_val_acc = val_acc
            torch.save({
                "epoch": epoch,
                "state_dict": model.state_dict(),
                "val_acc": val_acc,
                "labels": labels,
            }, best_weights_path)
            print("  🌟 (Saved Best Model)")
        else:
            print()
            
    print("=" * 65)
    print(f"Best Validation Accuracy: {best_val_acc:.2f}%")
    print(f"Saved Best Model to: {best_weights_path}")
    
    # Load Best Weights for Test Evaluation
    best_ckpt = torch.load(best_weights_path, map_location="cpu", weights_only=False)
    model.load_state_dict(best_ckpt["state_dict"])
    model.eval()
    
    print("\n--- Final Test Dataset Evaluation ---")
    test_top1_correct = 0
    test_top3_correct = 0
    total_test = 0
    per_class_correct = defaultdict(int)
    per_class_total = defaultdict(int)
    
    with torch.no_grad():
        for images, targets in test_loader:
            outputs = model(images)
            # Top-1
            preds = outputs.argmax(dim=1)
            test_top1_correct += (preds == targets).sum().item()
            
            # Top-3
            _, top3_preds = outputs.topk(3, dim=1)
            for i in range(len(targets)):
                if targets[i] in top3_preds[i]:
                    test_top3_correct += 1
                t_label = labels[targets[i].item()]
                per_class_total[t_label] += 1
                if preds[i] == targets[i]:
                    per_class_correct[t_label] += 1
            total_test += len(targets)
            
    test_top1_acc = (test_top1_correct / total_test) * 100.0
    test_top3_acc = (test_top3_correct / total_test) * 100.0
    
    print(f"Test Samples: {total_test}")
    print(f"Top-1 Accuracy: {test_top1_acc:.2f}%")
    print(f"Top-3 Accuracy: {test_top3_acc:.2f}%")
    
    print("\nPer-Class Accuracies:")
    for lbl in labels:
        c_tot = per_class_total[lbl]
        c_cor = per_class_correct[lbl]
        c_acc = (c_cor / c_tot * 100.0) if c_tot > 0 else 0.0
        print(f"  '{lbl}': {c_acc:5.1f}% ({c_cor}/{c_tot})")
        
    # Export to ONNX
    onnx_path = os.path.join(models_dir, "tamil_script_cnn.onnx")
    dummy_input = torch.randn(1, 1, 64, 64, dtype=torch.float32)
    torch.onnx.export(
        model,
        dummy_input,
        onnx_path,
        input_names=["input"],
        output_names=["output"],
        opset_version=18,
    )
    print(f"\n[OK] ONNX model exported: {onnx_path} ({os.path.getsize(onnx_path)/1024:.1f} KB)")


if __name__ == "__main__":
    main()
