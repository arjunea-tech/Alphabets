"""
Preprocessing pipeline for Tamil Handwritten Character Recognition.
Ensures consistency between training data preprocessing and live Flutter touch stroke inference.
"""

import numpy as np
from PIL import Image, ImageOps
import os
import cv2

TARGET_DIMENSION = 32  # 32x32 pixels input tensor for lightweight mobile CNN


def preprocess_image(image_input, target_size=(TARGET_DIMENSION, TARGET_DIMENSION)):
    """
    Preprocesses a raw handwritten character image:
    1. Converts to grayscale.
    2. Inverts if white-on-black or black-on-white (ensures character is foreground / white strokes on black background).
    3. Finds tight bounding box of character and crops.
    4. Adds aspect-ratio preserving padding (centered square).
    5. Resizes to target dimension (e.g. 32x32).
    6. Normalizes pixel values to [0.0, 1.0].
    
    Args:
        image_input: PIL Image, filepath string, or numpy array.
        target_size: Tuple (width, height) for output tensor dimension.
        
    Returns:
        np.ndarray: Normalized 2D float32 array of shape (height, width) with values in [0.0, 1.0].
    """
    if isinstance(image_input, str):
        if not os.path.exists(image_input):
            raise FileNotFoundError(f"Image not found at {image_input}")
        img = Image.open(image_input).convert("L")
    elif isinstance(image_input, np.ndarray):
        if len(image_input.shape) == 3:
            img = Image.fromarray(image_input).convert("L")
        else:
            img = Image.fromarray(image_input)
    elif isinstance(image_input, Image.Image):
        img = image_input.convert("L")
    else:
        raise ValueError(f"Unsupported image input type: {type(image_input)}")

    arr = np.array(img, dtype=np.uint8)

    # Determine background vs foreground:
    # Check corner pixels to detect if background is light (white/grey)
    corner_samples = [arr[0, 0], arr[0, -1], arr[-1, 0], arr[-1, -1]]
    is_light_bg = np.mean(corner_samples) > 127

    if is_light_bg:
        # Invert so background is 0 (black) and character stroke is high intensity (>0)
        arr = 255 - arr

    # Otsu thresholding / cleaning
    _, thresh = cv2.threshold(arr, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    # Find bounding box of the character
    coords = cv2.findNonZero(thresh)
    if coords is None:
        # Blank canvas
        return np.zeros(target_size, dtype=np.float32)

    x, y, w, h = cv2.boundingRect(coords)

    # Crop the character region
    cropped = arr[y:y + h, x:x + w]

    # Pad to square canvas while preserving aspect ratio
    max_side = max(w, h)
    padding_ratio = 0.15  # 15% margin around the character
    pad_total = int(max_side * (1.0 + 2 * padding_ratio))
    square_canvas = np.zeros((pad_total, pad_total), dtype=np.uint8)

    # Center cropped character in the square canvas
    offset_x = (pad_total - w) // 2
    offset_y = (pad_total - h) // 2
    square_canvas[offset_y:offset_y + h, offset_x:offset_x + w] = cropped

    # Resize to target dimension using area interpolation
    resized = cv2.resize(square_canvas, target_size, interpolation=cv2.INTER_AREA)

    # Normalize float32 values [0.0, 1.0]
    normalized = resized.astype(np.float32) / 255.0

    return normalized


def preprocess_strokes_to_image(strokes, canvas_size=(350, 350), target_size=(TARGET_DIMENSION, TARGET_DIMENSION)):
    """
    Converts list of stroke coordinates (from Flutter gesture capture) to preprocessed ML tensor.
    
    Args:
        strokes: List of lists of (x, y) coordinates.
        canvas_size: (width, height) of writing area.
        target_size: (width, height) of output tensor.
        
    Returns:
        np.ndarray: Normalized 2D float32 array (target_size).
    """
    canvas_w, canvas_h = canvas_size
    img_canvas = np.zeros((int(canvas_h), int(canvas_w)), dtype=np.uint8)

    for stroke in strokes:
        if len(stroke) == 0:
            continue
        if len(stroke) == 1:
            pt = stroke[0]
            cv2.circle(img_canvas, (int(pt[0]), int(pt[1])), radius=6, color=255, thickness=-1)
            continue
        for i in range(len(stroke) - 1):
            p1 = (int(stroke[i][0]), int(stroke[i][1]))
            p2 = (int(stroke[i + 1][0]), int(stroke[i + 1][1]))
            cv2.line(img_canvas, p1, p2, color=255, thickness=6, lineType=cv2.LINE_AA)

    return preprocess_image(img_canvas, target_size=target_size)
