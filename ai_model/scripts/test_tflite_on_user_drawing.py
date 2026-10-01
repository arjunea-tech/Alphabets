import sys
import os
import json
import numpy as np
from PIL import Image

sys.stdout.reconfigure(encoding='utf-8')

# Let's load the TFLite model
import tensorflow as tf

tflite_path = "d:/Selva Mac/Projects/tamil/frontend/assets/ml/tamil_handwriting.tflite"
labels_path = "d:/Selva Mac/Projects/tamil/frontend/assets/ml/labels.txt"

with open(labels_path, 'r', encoding='utf-8') as f:
    labels = [line.strip() for line in f if line.strip()]

interpreter = tf.lite.Interpreter(model_path=tflite_path)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("Model Input Details:", input_details[0]['shape'], input_details[0]['dtype'])
print("Model Output Details:", output_details[0]['shape'], output_details[0]['dtype'])

# Let's get the user's drawing from the screenshot
img_path = "C:/Users/welcome/.gemini/antigravity-ide/brain/e81763e3-2bd6-4287-88d5-538a0eefe1bd/.user_uploaded/media_1790674269146.png"
img = Image.open(img_path).convert('RGB')
img_np = np.array(img)

canvas_crop = img_np[290:630, 25:295]
r, g, b = canvas_crop[:,:,0].astype(int), canvas_crop[:,:,1].astype(int), canvas_crop[:,:,2].astype(int)
blue_mask = (b > 180) & (b > r + 60) & (b > g + 40)

y_indices, x_indices = np.where(blue_mask)
min_y, max_y = np.min(y_indices), np.max(y_indices)
min_x, max_x = np.min(x_indices), np.max(x_indices)

crop = blue_mask[min_y:max_y+1, min_x:max_x+1].astype(np.float32)
ch, cw = crop.shape
max_side = max(ch, cw)
pad = int(max_side * 0.15)
box_size = max_side + pad * 2

square = np.zeros((box_size, box_size), dtype=np.float32)
off_y = (box_size - ch) // 2
off_x = (box_size - cw) // 2
square[off_y:off_y+ch, off_x:off_x+cw] = crop

# The model input shape: (1, 32, 32, 1) or (1, 64, 64, 1)
in_shape = input_details[0]['shape']
in_dim = in_shape[1]
square_img = Image.fromarray((square * 255).astype(np.uint8)).resize((in_dim, in_dim), Image.Resampling.BILINEAR)
input_data = np.array(square_img, dtype=np.float32) / 255.0
input_tensor = np.expand_dims(np.expand_dims(input_data, axis=0), axis=-1)

interpreter.set_tensor(input_details[0]['index'], input_tensor)
interpreter.invoke()

predictions = interpreter.get_tensor(output_details[0]['index'])[0]

results = [(labels[i], float(predictions[i])) for i in range(len(labels))]
results.sort(key=lambda x: x[1], reverse=True)

print("\n--- CNN TFLITE MODEL PREDICTIONS ON USER'S DRAWING ---")
for char, conf in results[:10]:
    print(f"  {char}: {conf*100:.2f}%")
