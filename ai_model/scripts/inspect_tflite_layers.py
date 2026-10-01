import sys
import os
import json
import numpy as np
import tensorflow as tf

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

model_path = "frontend/assets/ml/tamil_handwriting.tflite"
interpreter = tf.lite.Interpreter(model_path=model_path)
interpreter.allocate_tensors()

tensor_details = interpreter.get_tensor_details()
print("TFLite Model Tensors:")
weights_dict = {}
for td in tensor_details:
    t_name = td["name"]
    t_shape = td["shape"]
    t_idx = td["index"]
    try:
        t_data = interpreter.get_tensor(t_idx)
        print(f"Tensor [{t_idx}] '{t_name}': shape={t_shape}, dtype={td['dtype']}, min={t_data.min():.4f}, max={t_data.max():.4f}")
    except Exception as e:
        print(f"Tensor [{t_idx}] '{t_name}': shape={t_shape}, dtype={td['dtype']} (no data: {e})")
