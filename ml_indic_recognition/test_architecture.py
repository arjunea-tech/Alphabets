import torch
import torch.nn as nn

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

print(" SUCCESS: Model architecture matches state_dict perfectly with strict=True!")
print(f"Epoch: {ckpt.get('epoch')}")
print(f"Validation Accuracy: {ckpt.get('val_acc')}%")

# Test forward pass with dummy 1x1x64x64 tensor
dummy_input = torch.randn(1, 1, 64, 64)
with torch.no_grad():
    output = model(dummy_input)
print(f"Output shape: {output.shape}")
print(f"Predicted class for dummy input: {output.argmax(dim=1).item()}")
