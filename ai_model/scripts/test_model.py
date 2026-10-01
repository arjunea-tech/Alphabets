"""
Inference and Testing Script for Tamil Handwritten Character Recognition Model.
Loads exported TFLite model and tests single images or batches with confidence threshold filtering.
"""

import os
import sys

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')
if sys.stderr is not None and hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(encoding='utf-8', errors='backslashreplace')

import argparse
import numpy as np

# Add training directory for preprocessor
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../training")))
from preprocess import TARGET_DIMENSION, preprocess_image

CONFIDENCE_THRESHOLD = 0.70  # Default threshold for confident recognition


def glob_sample_image(base_dir):
    import glob
    candidates = glob.glob(os.path.normpath(os.path.join(base_dir, "../dataset/test/*/*.png")))
    if candidates:
        return candidates[0]
    candidates = glob.glob(os.path.normpath(os.path.join(base_dir, "../dataset/train/*/*.png")))
    if candidates:
        return candidates[0]
    return None


def load_labels(labels_file):
    """Loads class labels from labels.txt."""
    if not os.path.exists(labels_file):
        raise FileNotFoundError(f"Labels file not found at {labels_file}")
    with open(labels_file, "r", encoding="utf-8") as f:
        labels = [line.strip() for line in f if line.strip()]
    return labels


class TamilTFLiteClassifier:
    def __init__(self, model_path, labels_file):
        self.labels = load_labels(labels_file)

        # Try loading TFLite interpreter via tensorflow or tflite_runtime
        try:
            import tensorflow as tf
            self.interpreter = tf.lite.Interpreter(model_path=model_path)
        except ImportError:
            try:
                import tflite_runtime.interpreter as tflite
                self.interpreter = tflite.Interpreter(model_path=model_path)
            except ImportError:
                raise ImportError("Please install tensorflow or tflite-runtime: pip install tensorflow")

        self.interpreter.allocate_tensors()
        self.input_details = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()

    def predict_image(self, image_path, threshold=CONFIDENCE_THRESHOLD, top_k=3):
        """
        Runs handwriting recognition inference on an input image.
        
        Returns:
            dict: {
                'predicted_char': str,
                'confidence': float,
                'top_predictions': list of (char, prob),
                'is_confident': bool,
                'status': str
            }
        """
        # Preprocess to [32, 32] float32 normalized image
        img_arr = preprocess_image(image_path, target_size=(TARGET_DIMENSION, TARGET_DIMENSION))
        input_tensor = np.expand_dims(np.expand_dims(img_arr, axis=0), axis=-1).astype(np.float32)

        # Set tensor & invoke
        self.interpreter.set_tensor(self.input_details[0]["index"], input_tensor)
        self.interpreter.invoke()
        output_tensor = self.interpreter.get_tensor(self.output_details[0]["index"])[0]

        # Softmax probabilities if not already normalized
        if output_tensor.sum() > 0:
            probs = output_tensor / output_tensor.sum()
        else:
            probs = output_tensor

        # Get top-k predictions
        top_indices = np.argsort(probs)[::-1][:top_k]
        top_predictions = [(self.labels[idx], float(probs[idx])) for idx in top_indices]

        best_char, best_conf = top_predictions[0]
        is_confident = best_conf >= threshold

        return {
            "image_path": image_path,
            "predicted_char": best_char,
            "confidence": best_conf,
            "top_predictions": top_predictions,
            "is_confident": is_confident,
            "status": "Recognized" if is_confident else "Low Confidence"
        }


def main():
    parser = argparse.ArgumentParser(description="Test Tamil Handwriting Recognition TFLite Model")
    parser.add_argument("--image", type=str, default=None, help="Path to input handwritten image")
    parser.add_argument("--model", type=str, default="../models/tamil_handwriting_model.tflite", help="Path to TFLite model")
    parser.add_argument("--labels", type=str, default="../labels/labels.txt", help="Path to labels.txt")
    parser.add_argument("--threshold", type=float, default=CONFIDENCE_THRESHOLD, help="Confidence threshold (0.0 - 1.0)")
    args = parser.parse_args()

    base_dir = os.path.dirname(os.path.abspath(__file__))
    model_path = os.path.normpath(os.path.join(base_dir, args.model))
    labels_file = os.path.normpath(os.path.join(base_dir, args.labels))
    
    if args.image:
        image_path = os.path.normpath(os.path.join(base_dir, args.image)) if not os.path.isabs(args.image) else args.image
    else:
        # Look for any sample image in dataset
        sample_cand = glob_sample_image(base_dir)
        if sample_cand:
            image_path = sample_cand
            print(f"[i] No --image provided. Using sample image: {image_path}")
        else:
            print("[!] No --image provided and no dataset samples found. Please supply --image <path>.")
            return

    print("=" * 50)
    print("Tamil Handwritten Character Recognition - Test")
    print("=" * 50)
    print(f"Input Image:  {image_path}")
    print(f"Model File:   {model_path}")
    print(f"Threshold:    {args.threshold * 100:.1f}%\n")

    if not os.path.exists(model_path):
        print(f"[!] Error: Model file not found at {model_path}")
        print("Please train the model first by running: python training/train.py")
        return

    classifier = TamilTFLiteClassifier(model_path, labels_file)
    result = classifier.predict_image(image_path, threshold=args.threshold)

    print(f"Prediction:     {result['predicted_char']}")
    print(f"Confidence:     {result['confidence'] * 100:.1f}%")
    print(f"Status:         {result['status']}\n")

    print("Top Predictions:")
    for char, prob in result["top_predictions"]:
        bar = "#" * int(prob * 20)
        print(f"  {char}  : {prob * 100:5.1f}%  [{bar:<20}]")

    print("\nResult:")
    if result["is_confident"]:
        print(f"-> Successfully recognized as: '{result['predicted_char']}'")
    else:
        print(f"-> Unable to confidently recognize the character. (Confidence {result['confidence'] * 100:.1f}% < {args.threshold * 100:.1f}%)")


if __name__ == "__main__":
    main()
