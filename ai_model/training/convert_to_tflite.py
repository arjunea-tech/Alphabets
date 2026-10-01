import os
import sys
import shutil
import numpy as np
import torch
import torch.nn as nn
import tensorflow as tf
try:
    import keras
    from keras import layers, models
except ImportError:
    from tensorflow import keras
    from tensorflow.keras import layers, models

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

# PyTorch ScriptCNN
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


def build_keras_script_cnn(input_shape=(64, 64, 1), num_classes=31):
    inputs = layers.Input(shape=input_shape, name="indic_char_input")

    # Stage 1
    x = layers.Conv2D(32, (3, 3), padding="same", use_bias=False, name="conv1")(inputs)
    x = layers.BatchNormalization(epsilon=1e-5, momentum=0.1, name="bn1")(x)
    x = layers.ReLU(name="relu1")(x)
    x = layers.MaxPooling2D((2, 2), name="pool1")(x)

    # Stage 2
    x = layers.Conv2D(64, (3, 3), padding="same", use_bias=False, name="conv2")(x)
    x = layers.BatchNormalization(epsilon=1e-5, momentum=0.1, name="bn2")(x)
    x = layers.ReLU(name="relu2")(x)
    x = layers.MaxPooling2D((2, 2), name="pool2")(x)

    # Stage 3
    x = layers.Conv2D(128, (3, 3), padding="same", use_bias=False, name="conv3")(x)
    x = layers.BatchNormalization(epsilon=1e-5, momentum=0.1, name="bn3")(x)
    x = layers.ReLU(name="relu3")(x)
    x = layers.MaxPooling2D((2, 2), name="pool3")(x)

    # Stage 4
    x = layers.Conv2D(256, (3, 3), padding="same", use_bias=False, name="conv4")(x)
    x = layers.BatchNormalization(epsilon=1e-5, momentum=0.1, name="bn4")(x)
    x = layers.ReLU(name="relu4")(x)
    x = layers.MaxPooling2D((2, 2), name="pool4")(x)

    # Classifier Head
    x = layers.Flatten(name="flatten")(x)
    x = layers.Dense(512, activation="relu", name="dense1")(x)
    outputs = layers.Dense(num_classes, activation="softmax", name="tamil_char_output")(x)

    return models.Model(inputs=inputs, outputs=outputs, name="TamilScriptCNN")


def transfer_weights_pytorch_to_keras(torch_model, keras_model):
    state_dict = torch_model.state_dict()
    
    # 1. Conv + BN Stage 1
    # Conv1: (32, 1, 3, 3) -> (3, 3, 1, 32)
    w_conv1 = state_dict['features.0.weight'].detach().cpu().numpy().transpose(2, 3, 1, 0)
    keras_model.get_layer('conv1').set_weights([w_conv1])
    
    # BN1: gamma, beta, mean, var
    w_bn1 = [
        state_dict['features.1.weight'].detach().cpu().numpy(),
        state_dict['features.1.bias'].detach().cpu().numpy(),
        state_dict['features.1.running_mean'].detach().cpu().numpy(),
        state_dict['features.1.running_var'].detach().cpu().numpy()
    ]
    keras_model.get_layer('bn1').set_weights(w_bn1)
    
    # 2. Conv + BN Stage 2
    # Conv2: (64, 32, 3, 3) -> (3, 3, 32, 64)
    w_conv2 = state_dict['features.4.weight'].detach().cpu().numpy().transpose(2, 3, 1, 0)
    keras_model.get_layer('conv2').set_weights([w_conv2])
    
    w_bn2 = [
        state_dict['features.5.weight'].detach().cpu().numpy(),
        state_dict['features.5.bias'].detach().cpu().numpy(),
        state_dict['features.5.running_mean'].detach().cpu().numpy(),
        state_dict['features.5.running_var'].detach().cpu().numpy()
    ]
    keras_model.get_layer('bn2').set_weights(w_bn2)
    
    # 3. Conv + BN Stage 3
    # Conv3: (128, 64, 3, 3) -> (3, 3, 64, 128)
    w_conv3 = state_dict['features.8.weight'].detach().cpu().numpy().transpose(2, 3, 1, 0)
    keras_model.get_layer('conv3').set_weights([w_conv3])
    
    w_bn3 = [
        state_dict['features.9.weight'].detach().cpu().numpy(),
        state_dict['features.9.bias'].detach().cpu().numpy(),
        state_dict['features.9.running_mean'].detach().cpu().numpy(),
        state_dict['features.9.running_var'].detach().cpu().numpy()
    ]
    keras_model.get_layer('bn3').set_weights(w_bn3)
    
    # 4. Conv + BN Stage 4
    # Conv4: (256, 128, 3, 3) -> (3, 3, 128, 256)
    w_conv4 = state_dict['features.12.weight'].detach().cpu().numpy().transpose(2, 3, 1, 0)
    keras_model.get_layer('conv4').set_weights([w_conv4])
    
    w_bn4 = [
        state_dict['features.13.weight'].detach().cpu().numpy(),
        state_dict['features.13.bias'].detach().cpu().numpy(),
        state_dict['features.13.running_mean'].detach().cpu().numpy(),
        state_dict['features.13.running_var'].detach().cpu().numpy()
    ]
    keras_model.get_layer('bn4').set_weights(w_bn4)
    
    # 5. Dense 1: PyTorch (512, 4096) -> Keras (4096, 512)
    # PyTorch flatten is NCHW (256, 4, 4), while Keras flatten is NHWC (4, 4, 256).
    # We must permute the input channels of the dense weight matrix from NCHW to NHWC!
    w_dense1_raw = state_dict['classifier.1.weight'].detach().cpu().numpy() # (512, 4096)
    w_dense1_reshaped = w_dense1_raw.reshape(512, 256, 4, 4) # (512, C, H, W)
    w_dense1_permuted = w_dense1_reshaped.transpose(0, 2, 3, 1) # (512, H, W, C)
    w_dense1_keras = w_dense1_permuted.reshape(512, 4096).T # (4096, 512)
    b_dense1_keras = state_dict['classifier.1.bias'].detach().cpu().numpy()
    keras_model.get_layer('dense1').set_weights([w_dense1_keras, b_dense1_keras])
    
    # 6. Dense 2: PyTorch (31, 512) -> Keras (512, 31)
    w_dense2_keras = state_dict['classifier.4.weight'].detach().cpu().numpy().T
    b_dense2_keras = state_dict['classifier.4.bias'].detach().cpu().numpy()
    keras_model.get_layer('tamil_char_output').set_weights([w_dense2_keras, b_dense2_keras])
    
    print("[OK] All layer weights transferred from PyTorch to Keras successfully!")


def main():
    base_dir = r"d:\Selva Mac\Projects\tamil\ai_model"
    models_dir = os.path.join(base_dir, "models")
    best_weights_path = os.path.join(models_dir, "tamil_scriptcnn_best.pth")
    
    if not os.path.exists(best_weights_path):
        print(f"Error: Best model weights not found at {best_weights_path}")
        return
        
    print(f"Loading best PyTorch weights from: {best_weights_path}")
    ckpt = torch.load(best_weights_path, map_location="cpu", weights_only=False)
    
    num_classes = len(ckpt.get("labels", [None]*31))
    torch_model = ScriptCNN(num_classes=num_classes)
    torch_model.load_state_dict(ckpt["state_dict"])
    torch_model.eval()
    
    # Build Keras model and transfer weights
    keras_model = build_keras_script_cnn(input_shape=(64, 64, 1), num_classes=num_classes)
    transfer_weights_pytorch_to_keras(torch_model, keras_model)
    
    # Save Keras Model
    keras_path = os.path.join(models_dir, "tamil_scriptcnn_best.keras")
    keras_model.save(keras_path)
    print(f"[OK] Saved Keras model: {keras_path}")
    
    # Verify Numerical Parity between PyTorch and Keras
    dummy_torch = torch.randn(1, 1, 64, 64, dtype=torch.float32)
    # Keras input is (1, 64, 64, 1)
    dummy_keras = dummy_torch.numpy().transpose(0, 2, 3, 1)
    
    with torch.no_grad():
        out_torch = torch.softmax(torch_model(dummy_torch), dim=1).numpy()
    out_keras = keras_model.predict(dummy_keras, verbose=0)
    
    diff = np.max(np.abs(out_torch - out_keras))
    print(f"Max difference between PyTorch and Keras: {diff:.8f}")
    if diff < 1e-4:
        print("  PARITY CHECK PASSED (PyTorch <-> Keras)!")
        
    # Convert to TFLite (Float32)
    tflite_path = os.path.join(models_dir, "tamil_handwriting_model.tflite")
    converter = tf.lite.TFLiteConverter.from_keras_model(keras_model)
    tflite_model = converter.convert()
    with open(tflite_path, "wb") as f:
        f.write(tflite_model)
    print(f"[OK] Standard Float32 TFLite exported: {tflite_path} ({len(tflite_model)/1024:.1f} KB)")
    
    # Convert to TFLite (Dynamic Range INT8 Quantized)
    quant_tflite_path = os.path.join(models_dir, "tamil_handwriting_model_quant.tflite")
    converter_quant = tf.lite.TFLiteConverter.from_keras_model(keras_model)
    converter_quant.optimizations = [tf.lite.Optimize.DEFAULT]
    quant_tflite_model = converter_quant.convert()
    with open(quant_tflite_path, "wb") as f:
        f.write(quant_tflite_model)
    print(f"[OK] Quantized TFLite exported: {quant_tflite_path} ({len(quant_tflite_model)/1024:.1f} KB)")
    
    # Deploy to Flutter assets/ml/
    flutter_ml_dir = r"d:\Selva Mac\Projects\tamil\frontend\assets\ml"
    os.makedirs(flutter_ml_dir, exist_ok=True)
    flutter_tflite_dest = os.path.join(flutter_ml_dir, "tamil_handwriting.tflite")
    shutil.copyfile(tflite_path, flutter_tflite_dest)
    print(f"[OK] Deployed to Flutter Assets: {flutter_tflite_dest}")
    
    # Test TFLite Interpreter
    interpreter = tf.lite.Interpreter(model_path=tflite_path)
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    interpreter.set_tensor(input_details[0]['index'], dummy_keras)
    interpreter.invoke()
    tflite_out = interpreter.get_tensor(output_details[0]['index'])
    
    tflite_diff = np.max(np.abs(out_keras - tflite_out))
    print(f"Max difference between Keras and TFLite: {tflite_diff:.8f}")
    if tflite_diff < 1e-4:
        print("  PARITY CHECK PASSED (Keras <-> TFLite)!")
        print("\nALL CONVERSIONS & CHECKS COMPLETED SUCCESSFULLY!")

if __name__ == "__main__":
    main()
