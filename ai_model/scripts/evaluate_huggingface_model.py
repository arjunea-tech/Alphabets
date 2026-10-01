import os
import sys
import glob
from collections import defaultdict, Counter
from PIL import Image
import numpy as np
import torch
import torch.nn as nn

# Ensure utf-8 output on Windows
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

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
        return self.classifier(self.features(x))

def preprocess_image(image_path):
    img = Image.open(image_path).convert('L')
    arr = np.array(img, dtype=np.float32)
    
    # Check background: if corners are bright (>128), invert so strokes are white (255) and background is black (0)
    corners = [arr[0, 0], arr[0, -1], arr[-1, 0], arr[-1, -1]]
    if np.mean(corners) > 128:
        arr = 255.0 - arr
    
    # Threshold background noise
    arr[arr < 30] = 0
    
    # Find bounding box of strokes
    coords = np.argwhere(arr > 30)
    if len(coords) > 0:
        ymin, xmin = coords.min(axis=0)
        ymax, xmax = coords.max(axis=0)
        
        # Crop to stroke bounding box
        cropped = arr[ymin:ymax+1, xmin:xmax+1]
        
        # Preserve aspect ratio and fit within 48x48 inside 64x64 canvas
        ch, cw = cropped.shape
        max_dim = max(ch, cw)
        scale = 48.0 / max_dim
        new_w = max(1, int(round(cw * scale)))
        new_h = max(1, int(round(ch * scale)))
        
        crop_pil = Image.fromarray(cropped.astype(np.uint8))
        resized_pil = crop_pil.resize((new_w, new_h), Image.Resampling.BILINEAR)
        resized_arr = np.array(resized_pil, dtype=np.float32)
        
        # Place in 64x64 canvas centered
        canvas = np.zeros((64, 64), dtype=np.float32)
        y_offset = (64 - new_h) // 2
        x_offset = (64 - new_w) // 2
        canvas[y_offset:y_offset+new_h, x_offset:x_offset+new_w] = resized_arr
        arr = canvas
    else:
        pil_img = Image.fromarray(arr.astype(np.uint8)).resize((64, 64), Image.Resampling.BILINEAR)
        arr = np.array(pil_img, dtype=np.float32)

    # Normalize to [0.0, 1.0]
    tensor = arr / 255.0
    return torch.tensor(tensor, dtype=torch.float32).unsqueeze(0).unsqueeze(0)

def main():
    base_dir = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    model_path = os.path.join(base_dir, "models", "tamil_scriptcnn_best.pth")
    if not os.path.exists(model_path):
        model_path = os.path.join(base_dir, "models", "huggingface", "tamil_best.pth")
    dataset_dir = os.path.join(base_dir, "dataset", "test")
    labels_path = os.path.join(base_dir, "labels", "labels.txt")
    
    with open(labels_path, "r", encoding="utf-8") as f:
        labels_list = [l.strip() for l in f if l.strip()]

    print(f"Loading model from: {model_path}")
    checkpoint = torch.load(model_path, map_location="cpu", weights_only=False)
    
    num_classes = len(labels_list) if "tamil_scriptcnn" in model_path else 156
    model = ScriptCNN(num_classes=num_classes)
    if "state_dict" in checkpoint:
        model.load_state_dict(checkpoint["state_dict"])
    elif "model_state_dict" in checkpoint:
        model.load_state_dict(checkpoint["model_state_dict"])
    else:
        model.load_state_dict(checkpoint)
    model.eval()
    
    # Iterate over all class folders in ai_model/dataset/test
    char_dirs = sorted([d for d in os.listdir(dataset_dir) if os.path.isdir(os.path.join(dataset_dir, d))])
    print(f"Found {len(char_dirs)} character classes in test dataset:")
    print("Classes:", " ".join(char_dirs))
    print("=" * 60)
    
    class_pred_distributions = defaultdict(Counter)
    total_images = 0
    
    for char in char_dirs:
        folder = os.path.join(dataset_dir, char)
        images = glob.glob(os.path.join(folder, "*.*"))
        total_images += len(images)
        
        for img_path in images:
            inp = preprocess_image(img_path)
            with torch.no_grad():
                out = model(inp)
                pred_idx = out.argmax(dim=1).item()
                class_pred_distributions[char][pred_idx] += 1
                
    print("\n--- Model Output Index Mapping & Distribution ---")
    mapping = {}
    for char in char_dirs:
        counts = class_pred_distributions[char]
        total_class_samples = sum(counts.values())
        if total_class_samples == 0:
            continue
        top_preds = counts.most_common(3)
        if not top_preds:
            continue
        top1_idx, top1_count = top_preds[0]
        acc = (top1_count / total_class_samples) * 100.0
        mapping[char] = (top1_idx, acc, top1_count, total_class_samples)
        
        preds_str = ", ".join([f"idx {idx}: {cnt}/{total_class_samples} ({cnt/total_class_samples*100:.1f}%)" for idx, cnt in top_preds])
        print(f"Character '{char}': Top-1 Class Index {top1_idx:3d} | Match: {acc:5.1f}% ({top1_count}/{total_class_samples}) | Top: [{preds_str}]")

    print("=" * 60)
    print(f"Tested {total_images} total test images across {len(char_dirs)} classes.")

if __name__ == "__main__":
    main()
