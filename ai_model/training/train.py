"""
End-to-End Training and TFLite Export Script for Tamil Handwritten Character Recognition.
"""

import os
import sys

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')
if sys.stderr is not None and hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(encoding='utf-8', errors='backslashreplace')

import argparse
import numpy as np
import tensorflow as tf
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint, ReduceLROnPlateau
from sklearn.metrics import classification_report, confusion_matrix, f1_score, precision_score, recall_score

# Add current directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from model import build_tamil_cnn
from preprocess import TARGET_DIMENSION, preprocess_image


def load_labels(labels_file):
    """Loads class labels from labels.txt."""
    if not os.path.exists(labels_file):
        raise FileNotFoundError(f"Labels file not found at {labels_file}")
    with open(labels_file, "r", encoding="utf-8") as f:
        labels = [line.strip() for line in f if line.strip()]
    return labels


def create_dataset_generator(data_dir, labels, is_training=True, batch_size=32):
    """
    Creates an optimized TensorFlow Dataset pipeline for training, validation, or testing.
    Loads images into memory (fast), applies custom preprocessing and data augmentation.
    """
    images = []
    class_indices = []

    label_to_idx = {label: i for i, label in enumerate(labels)}

    for label in labels:
        class_dir = os.path.join(data_dir, label)
        if not os.path.isdir(class_dir):
            continue
        for fname in os.listdir(class_dir):
            if fname.lower().endswith((".png", ".jpg", ".jpeg", ".bmp")):
                fpath = os.path.join(class_dir, fname)
                img_arr = preprocess_image(fpath, target_size=(TARGET_DIMENSION, TARGET_DIMENSION))
                images.append(np.expand_dims(img_arr, axis=-1))  # (32, 32, 1)
                class_indices.append(label_to_idx[label])

    if not images:
        return None, 0

    X = np.array(images, dtype=np.float32)
    y = tf.keras.utils.to_categorical(class_indices, num_classes=len(labels))

    dataset = tf.data.Dataset.from_tensor_slices((X, y))

    if is_training:
        dataset = dataset.shuffle(buffer_size=len(X))

        # Data augmentation pipeline
        data_augmentation = tf.keras.Sequential([
            tf.keras.layers.RandomRotation(0.06),  # ~ +/- 10 degrees
            tf.keras.layers.RandomTranslation(0.08, 0.08),  # +/- 8% translation
            tf.keras.layers.RandomZoom(0.08),  # +/- 8% zoom
        ], name="data_augmentation")

        dataset = dataset.batch(batch_size)
        dataset = dataset.map(lambda x, y: (data_augmentation(x, training=True), y),
                              num_parallel_calls=tf.data.AUTOTUNE)
    else:
        dataset = dataset.batch(batch_size)

    dataset = dataset.prefetch(tf.data.AUTOTUNE)
    return dataset, len(X)


def export_to_tflite(keras_model, output_dir, val_dataset=None):
    """
    Exports trained Keras model to both standard Float32 TFLite and Quantized TFLite formats,
    and copies to Flutter frontend/assets/ml/ directory.
    """
    import shutil
    os.makedirs(output_dir, exist_ok=True)
    float_model_path = os.path.join(output_dir, "tamil_handwriting_model.tflite")
    quant_model_path = os.path.join(output_dir, "tamil_handwriting_model_quant.tflite")

    # 1. Standard Float32 TFLite
    converter = tf.lite.TFLiteConverter.from_keras_model(keras_model)
    tflite_float_model = converter.convert()
    with open(float_model_path, "wb") as f:
        f.write(tflite_float_model)

    float_size_kb = len(tflite_float_model) / 1024.0
    print(f"\n[OK] Standard Float32 TFLite exported: {float_model_path} ({float_size_kb:.1f} KB)")

    # 2. Dynamic Range Quantized TFLite (INT8 weights, Float32 activations)
    converter_quant = tf.lite.TFLiteConverter.from_keras_model(keras_model)
    converter_quant.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_quant_model = converter_quant.convert()
    with open(quant_model_path, "wb") as f:
        f.write(tflite_quant_model)

    quant_size_kb = len(tflite_quant_model) / 1024.0
    print(f"[OK] Quantized TFLite exported: {quant_model_path} ({quant_size_kb:.1f} KB)")

    # 3. Copy to Flutter assets/ml/
    frontend_ml_dir = os.path.normpath(os.path.join(output_dir, "../../frontend/assets/ml"))
    os.makedirs(frontend_ml_dir, exist_ok=True)
    frontend_model_path = os.path.join(frontend_ml_dir, "tamil_handwriting.tflite")
    shutil.copyfile(float_model_path, frontend_model_path)
    print(f"[OK] Deployed to Flutter Assets: {frontend_model_path} ({float_size_kb:.1f} KB)")

    return float_model_path, quant_model_path, float_size_kb, quant_size_kb


def main():
    parser = argparse.ArgumentParser(description="Train Tamil Handwriting Recognition CNN Model")
    parser.add_argument("--data_dir", type=str, default="../dataset", help="Path to dataset root")
    parser.add_argument("--labels_file", type=str, default="../labels/labels.txt", help="Path to labels.txt")
    parser.add_argument("--output_dir", type=str, default="../models", help="Output directory for trained models")
    parser.add_argument("--epochs", type=int, default=40, help="Number of training epochs")
    parser.add_argument("--batch_size", type=int, default=32, help="Batch size")
    parser.add_argument("--learning_rate", type=float, default=0.001, help="Initial learning rate")
    args = parser.parse_args()

    base_dir = os.path.dirname(os.path.abspath(__file__))
    data_dir = os.path.normpath(os.path.join(base_dir, args.data_dir))
    labels_file = os.path.normpath(os.path.join(base_dir, args.labels_file))
    output_dir = os.path.normpath(os.path.join(base_dir, args.output_dir))

    print("=" * 60)
    print("AGARAM Tamil Handwritten Character Recognition Model Training")
    print("=" * 60)
    print(f"Data Directory:   {data_dir}")
    print(f"Labels File:      {labels_file}")
    print(f"Output Directory: {output_dir}")

    # Load labels
    labels = load_labels(labels_file)
    num_classes = len(labels)
    print(f"Total Character Classes: {num_classes} ({', '.join(labels[:6])}...)")

    train_dir = os.path.join(data_dir, "train")
    val_dir = os.path.join(data_dir, "validation")
    test_dir = os.path.join(data_dir, "test")

    # Verify dataset directories
    train_ds, n_train = create_dataset_generator(train_dir, labels, is_training=True, batch_size=args.batch_size)
    val_ds, n_val = create_dataset_generator(val_dir, labels, is_training=False, batch_size=args.batch_size)
    test_ds, n_test = create_dataset_generator(test_dir, labels, is_training=False, batch_size=args.batch_size)

    print(f"\nDataset Sample Counts:")
    print(f"  Training Samples:   {n_train}")
    print(f"  Validation Samples: {n_val}")
    print(f"  Test Samples:       {n_test}")

    if n_train == 0:
        print("\n[!] Warning: No training images found in dataset directory.")
        print("Please place handwritten samples in ai_model/dataset/train/<class_name>/")
        print("Or run ai_model/scripts/generate_synthetic_dataset.py to prepare baseline datasets.")
        return

    # Build CNN
    model = build_tamil_cnn(input_shape=(TARGET_DIMENSION, TARGET_DIMENSION, 1), num_classes=num_classes)
    optimizer = tf.keras.optimizers.Adam(learning_rate=args.learning_rate)
    model.compile(
        optimizer=optimizer,
        loss="categorical_crossentropy",
        metrics=["accuracy", tf.keras.metrics.TopKCategoricalAccuracy(k=3, name="top_3_accuracy")]
    )

    # Callbacks
    best_keras_path = os.path.join(output_dir, "tamil_handwriting_best.keras")
    callbacks = [
        EarlyStopping(monitor="val_accuracy", patience=8, restore_best_weights=True, verbose=1),
        ReduceLROnPlateau(monitor="val_loss", factor=0.5, patience=3, min_lr=1e-6, verbose=1),
        ModelCheckpoint(best_keras_path, monitor="val_accuracy", save_best_only=True, verbose=1),
    ]

    print("\nStarting Model Training...")
    history = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=args.epochs,
        callbacks=callbacks,
        verbose=1
    )

    # Evaluation on Test Dataset
    if n_test > 0:
        print("\nEvaluating on Test Dataset...")
        test_loss, test_acc, test_top3 = model.evaluate(test_ds, verbose=0)
        print(f"Test Loss:            {test_loss:.4f}")
        print(f"Test Accuracy (Top-1): {test_acc * 100:.2f}%")
        print(f"Test Accuracy (Top-3): {test_top3 * 100:.2f}%")

    # Export to TFLite
    export_to_tflite(model, output_dir, val_dataset=val_ds)
    print("\nTraining and Export Pipeline Complete!")


if __name__ == "__main__":
    main()
