import sys
import os
import numpy as np
from PIL import Image
import tensorflow as tf

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

sys.path.append("ai_model/training")
from preprocess import preprocess_image, preprocess_strokes_to_image

model_path = "frontend/assets/ml/tamil_handwriting.tflite"
labels_file = "frontend/assets/ml/labels.txt"

with open(labels_file, "r", encoding="utf-8") as f:
    labels = [l.strip() for l in f if l.strip()]

interpreter = tf.lite.Interpreter(model_path=model_path)
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

target_h = int(input_details[0]['shape'][1])
target_w = int(input_details[0]['shape'][2])

def predict_tensor(tensor_img):
    if tensor_img.shape[0] != target_h or tensor_img.shape[1] != target_w:
        import cv2
        tensor_img = cv2.resize(tensor_img, (target_w, target_h), interpolation=cv2.INTER_AREA)
    inp = np.expand_dims(np.expand_dims(tensor_img, axis=0), axis=-1).astype(np.float32)
    interpreter.set_tensor(input_details[0]['index'], inp)
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]['index'])[0]
    # Softmax
    exp = np.exp(output - np.max(output))
    probs = exp / exp.sum()
    top_idxs = np.argsort(probs)[::-1]
    return [(labels[i], float(probs[i])) for i in top_idxs]

test_dir = "ai_model/dataset/test"
for char in ["அ", "ஆ", "இ", "ஈ", "உ", "ஊ", "எ", "ஏ", "ஐ", "ஒ", "ஓ", "ஔ", "க்", "ங்", "ஞ்", "த்", "ந்", "ப்", "ழ்"]:
    c_dir = os.path.join(test_dir, char)
    if not os.path.exists(c_dir):
        continue
    files = [f for f in os.listdir(c_dir) if f.lower().endswith(('.bmp', '.png', '.jpg'))][:10]
    corr = 0
    if len(files) == 0:
        continue
    for f in files:
        im = Image.open(os.path.join(c_dir, f)).convert('L')
        arr = np.array(im)
        if np.mean(arr) > 128:
            im = Image.fromarray(255 - arr)
        raw = preprocess_image(im, target_size=(target_w, target_h))
        preds = predict_tensor(raw)
        if preds[0][0] == char:
            corr += 1
    print(f"TFLite Model Accuracy for '{char}': {corr}/{len(files)} ({corr/len(files)*100:.1f}%)")

