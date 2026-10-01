"""
Compact Convolutional Neural Network (CNN) Architecture for Tamil Handwritten Character Recognition.
Optimized for mobile inference with TensorFlow Lite.
"""

import tensorflow as tf
from tensorflow.keras import layers, models


def build_tamil_cnn(input_shape=(32, 32, 1), num_classes=31):
    """
    Constructs a lightweight, robust CNN model for mobile Tamil handwriting classification.
    
    Architecture Highlights:
    - 3 Conv blocks with residual feature extraction & BatchNormalization
    - Spatial Dropout for stroke-level regularization
    - Global Average Pooling / Dense head with dropout to prevent overfitting
    - Softmax output across 31 Tamil character classes
    
    Args:
        input_shape: Shape of input tensor (height, width, channels) = (32, 32, 1)
        num_classes: Total number of character classes (31)
        
    Returns:
        tf.keras.Model: Compiled or uncompiled Keras Model instance.
    """
    inputs = layers.Input(shape=input_shape, name="stroke_image_input")

    # Block 1: Low-level stroke edge & curve detection (32 filters)
    x = layers.Conv2D(32, (3, 3), padding="same", activation="relu", name="conv1_1")(inputs)
    x = layers.BatchNormalization(name="bn1_1")(x)
    x = layers.Conv2D(32, (3, 3), padding="same", activation="relu", name="conv1_2")(x)
    x = layers.BatchNormalization(name="bn1_2")(x)
    x = layers.MaxPooling2D((2, 2), name="pool1")(x)
    x = layers.SpatialDropout2D(0.20, name="drop1")(x)

    # Block 2: Intermediate Tamil loop/hook/stem feature extraction (64 filters)
    x = layers.Conv2D(64, (3, 3), padding="same", activation="relu", name="conv2_1")(x)
    x = layers.BatchNormalization(name="bn2_1")(x)
    x = layers.Conv2D(64, (3, 3), padding="same", activation="relu", name="conv2_2")(x)
    x = layers.BatchNormalization(name="bn2_2")(x)
    x = layers.MaxPooling2D((2, 2), name="pool2")(x)
    x = layers.SpatialDropout2D(0.25, name="drop2")(x)

    # Block 3: High-level structural character representation (128 filters)
    x = layers.Conv2D(128, (3, 3), padding="same", activation="relu", name="conv3_1")(x)
    x = layers.BatchNormalization(name="bn3_1")(x)
    x = layers.MaxPooling2D((2, 2), name="pool3")(x)
    x = layers.SpatialDropout2D(0.30, name="drop3")(x)

    # Classification Head
    x = layers.Flatten(name="flatten")(x)
    x = layers.Dense(128, activation="relu", name="dense1")(x)
    x = layers.BatchNormalization(name="bn_dense")(x)
    x = layers.Dropout(0.40, name="drop_dense")(x)

    outputs = layers.Dense(num_classes, activation="softmax", name="tamil_char_output")(x)

    model = models.Model(inputs=inputs, outputs=outputs, name="TamilHandwritingMobileCNN")
    return model


def build_script_cnn(input_shape=(64, 64, 1), num_classes=31):
    """
    Constructs the 4-stage ScriptCNN architecture matching the Hugging Face
    T3.7 Indic Recognition model (dhruv10050/t3-7-indic-recognition).
    
    Architecture:
    - Stage 1: Conv2D(32, 3x3) -> BatchNorm -> ReLU -> MaxPool2D(2x2) [Output: 32x32x32]
    - Stage 2: Conv2D(64, 3x3) -> BatchNorm -> ReLU -> MaxPool2D(2x2) [Output: 16x16x64]
    - Stage 3: Conv2D(128, 3x3) -> BatchNorm -> ReLU -> MaxPool2D(2x2) [Output: 8x8x128]
    - Stage 4: Conv2D(256, 3x3) -> BatchNorm -> ReLU -> MaxPool2D(2x2) [Output: 4x4x256]
    - Classifier Head: Flatten -> Dense(512, ReLU) -> Dropout(0.5) -> Dense(num_classes, Softmax)
    """
    inputs = layers.Input(shape=input_shape, name="indic_char_input")

    # Stage 1
    x = layers.Conv2D(32, (3, 3), padding="same", use_bias=False, name="conv1")(inputs)
    x = layers.BatchNormalization(name="bn1")(x)
    x = layers.ReLU(name="relu1")(x)
    x = layers.MaxPooling2D((2, 2), name="pool1")(x)

    # Stage 2
    x = layers.Conv2D(64, (3, 3), padding="same", use_bias=False, name="conv2")(x)
    x = layers.BatchNormalization(name="bn2")(x)
    x = layers.ReLU(name="relu2")(x)
    x = layers.MaxPooling2D((2, 2), name="pool2")(x)

    # Stage 3
    x = layers.Conv2D(128, (3, 3), padding="same", use_bias=False, name="conv3")(x)
    x = layers.BatchNormalization(name="bn3")(x)
    x = layers.ReLU(name="relu3")(x)
    x = layers.MaxPooling2D((2, 2), name="pool3")(x)

    # Stage 4
    x = layers.Conv2D(256, (3, 3), padding="same", use_bias=False, name="conv4")(x)
    x = layers.BatchNormalization(name="bn4")(x)
    x = layers.ReLU(name="relu4")(x)
    x = layers.MaxPooling2D((2, 2), name="pool4")(x)

    # Classifier Head
    x = layers.Flatten(name="flatten")(x)
    x = layers.Dense(512, activation="relu", name="dense1")(x)
    x = layers.Dropout(0.5, name="dropout")(x)
    outputs = layers.Dense(num_classes, activation="softmax", name="tamil_char_output")(x)

    model = models.Model(inputs=inputs, outputs=outputs, name="TamilScriptCNN")
    return model


if __name__ == "__main__":
    # Test model summary
    model = build_script_cnn()
    model.summary()
    print(f"\nTotal trainable parameters: {model.count_params():,}")
