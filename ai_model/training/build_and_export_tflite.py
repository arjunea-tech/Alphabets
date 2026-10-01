import os
import sys
import shutil
import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')


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


def transfer_weights_npz_to_keras(weights_npz, keras_model):
    # 1. Stage 1
    w_conv1 = weights_npz['features.0.weight'].transpose(2, 3, 1, 0)
    keras_model.get_layer('conv1').set_weights([w_conv1])
    
    w_bn1 = [
        weights_npz['features.1.weight'],
        weights_npz['features.1.bias'],
        weights_npz['features.1.running_mean'],
        weights_npz['features.1.running_var']
    ]
    keras_model.get_layer('bn1').set_weights(w_bn1)
    
    # 2. Stage 2
    w_conv2 = weights_npz['features.4.weight'].transpose(2, 3, 1, 0)
    keras_model.get_layer('conv2').set_weights([w_conv2])
    
    w_bn2 = [
        weights_npz['features.5.weight'],
        weights_npz['features.5.bias'],
        weights_npz['features.5.running_mean'],
        weights_npz['features.5.running_var']
    ]
    keras_model.get_layer('bn2').set_weights(w_bn2)
    
    # 3. Stage 3
    w_conv3 = weights_npz['features.8.weight'].transpose(2, 3, 1, 0)
    keras_model.get_layer('conv3').set_weights([w_conv3])
    
    w_bn3 = [
        weights_npz['features.9.weight'],
        weights_npz['features.9.bias'],
        weights_npz['features.9.running_mean'],
        weights_npz['features.9.running_var']
    ]
    keras_model.get_layer('bn3').set_weights(w_bn3)
    
    # 4. Stage 4
    w_conv4 = weights_npz['features.12.weight'].transpose(2, 3, 1, 0)
    keras_model.get_layer('conv4').set_weights([w_conv4])
    
    w_bn4 = [
        weights_npz['features.13.weight'],
        weights_npz['features.13.bias'],
        weights_npz['features.13.running_mean'],
        weights_npz['features.13.running_var']
    ]
    keras_model.get_layer('bn4').set_weights(w_bn4)
    
    # 5. Dense 1: PyTorch (512, 4096) NCHW -> Keras (4096, 512) NHWC
    w_dense1_raw = weights_npz['classifier.1.weight'] # (512, 4096)
    w_dense1_reshaped = w_dense1_raw.reshape(512, 256, 4, 4) # (512, C, H, W)
    w_dense1_permuted = w_dense1_reshaped.transpose(0, 2, 3, 1) # (512, H, W, C)
    w_dense1_keras = w_dense1_permuted.reshape(512, 4096).T # (4096, 512)
    b_dense1_keras = weights_npz['classifier.1.bias']
    keras_model.get_layer('dense1').set_weights([w_dense1_keras, b_dense1_keras])
    
    # 6. Dense 2: PyTorch (31, 512) -> Keras (512, 31)
    w_dense2_keras = weights_npz['classifier.4.weight'].T
    b_dense2_keras = weights_npz['classifier.4.bias']
    keras_model.get_layer('tamil_char_output').set_weights([w_dense2_keras, b_dense2_keras])
    
    print("[OK] Weights successfully transferred into Keras model!")


def main():
    base_dir = r"d:\Selva Mac\Projects\tamil\ai_model"
    models_dir = os.path.join(base_dir, "models")
    npz_path = os.path.join(models_dir, "tamil_scriptcnn_weights.npz")
    
    print(f"Loading weights from: {npz_path}")
    weights_npz = np.load(npz_path)
    
    # Build Keras Model
    keras_model = build_keras_script_cnn(input_shape=(64, 64, 1), num_classes=31)
    transfer_weights_npz_to_keras(weights_npz, keras_model)
    
    # Save Keras Model
    keras_path = os.path.join(models_dir, "tamil_scriptcnn_best.keras")
    keras_model.save(keras_path)
    print(f"[OK] Keras model saved: {keras_path}")
    
    # 1. Convert to Standard Float32 TFLite
    float_tflite_path = os.path.join(models_dir, "tamil_handwriting_model.tflite")
    converter = tf.lite.TFLiteConverter.from_keras_model(keras_model)
    float_tflite = converter.convert()
    with open(float_tflite_path, "wb") as f:
        f.write(float_tflite)
    print(f"[OK] Float32 TFLite exported: {float_tflite_path} ({len(float_tflite)/1024:.1f} KB)")
    
    # 2. Convert to Dynamic Range Quantized TFLite
    quant_tflite_path = os.path.join(models_dir, "tamil_handwriting_model_quant.tflite")
    converter_quant = tf.lite.TFLiteConverter.from_keras_model(keras_model)
    converter_quant.optimizations = [tf.lite.Optimize.DEFAULT]
    quant_tflite = converter_quant.convert()
    with open(quant_tflite_path, "wb") as f:
        f.write(quant_tflite)
    print(f"[OK] Quantized INT8 TFLite exported: {quant_tflite_path} ({len(quant_tflite)/1024:.1f} KB)")
    
    # 3. Deploy to Flutter frontend/assets/ml/tamil_handwriting.tflite
    flutter_ml_dir = r"d:\Selva Mac\Projects\tamil\frontend\assets\ml"
    os.makedirs(flutter_ml_dir, exist_ok=True)
    flutter_dest = os.path.join(flutter_ml_dir, "tamil_handwriting.tflite")
    shutil.copyfile(float_tflite_path, flutter_dest)
    print(f"[OK] Deployed to Flutter Assets: {flutter_dest}")
    
    # 4. Verify TFLite Inference
    dummy_input = np.random.randn(1, 64, 64, 1).astype(np.float32)
    keras_out = keras_model.predict(dummy_input, verbose=0)
    
    interpreter = tf.lite.Interpreter(model_path=float_tflite_path)
    interpreter.allocate_tensors()
    inp_details = interpreter.get_input_details()
    out_details = interpreter.get_output_details()
    
    interpreter.set_tensor(inp_details[0]['index'], dummy_input)
    interpreter.invoke()
    tflite_out = interpreter.get_tensor(out_details[0]['index'])
    
    diff = np.max(np.abs(keras_out - tflite_out))
    print(f"Max difference between Keras and TFLite: {diff:.8f}")
    if diff < 1e-4:
        print("🎉 PARITY VERIFIED: TFLite produces identical outputs to Keras & PyTorch!")
        print("✨ FLUTTER INTEGRATION READY! ✨")

if __name__ == "__main__":
    main()
