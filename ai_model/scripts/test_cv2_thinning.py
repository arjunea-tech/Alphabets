import sys
import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy.ndimage import distance_transform_edt
import json

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

labels_file = "frontend/assets/ml/labels.txt"
with open(labels_file, "r", encoding="utf-8") as f:
    labels = [l.strip() for l in f if l.strip()]

font_path = "C:\\Windows\\Fonts\\Nirmala.ttc"
font = ImageFont.truetype(font_path, 80)

def render_thin_template(l):
    img = Image.new("L", (160, 160), 0)
    draw = ImageDraw.Draw(img)
    bbox = draw.textbbox((0, 0), l, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text(((160 - tw) // 2 - bbox[0], (160 - th) // 2 - bbox[1]), l, font=font, fill=255)
    
    arr = np.array(img, dtype=np.uint8)
    coords = cv2.findNonZero(arr)
    if coords is None:
        return np.zeros((32, 32), dtype=np.float32)
        
    x, y, w, h = cv2.boundingRect(coords)
    cropped = arr[y:y+h, x:x+w]
    
    max_side = max(w, h)
    pad = int(max_side * 0.15)
    box = max_side + pad * 2
    sq = np.zeros((box, box), dtype=np.uint8)
    oy = (box - h) // 2
    ox = (box - w) // 2
    sq[oy:oy+h, ox:ox+w] = cropped
    
    # Resize to 32x32
    res = cv2.resize(sq, (32, 32), interpolation=cv2.INTER_AREA)
    return res.astype(np.float32) / 255.0

thin_templates = {}
dt_maps = {}
for l in labels:
    t = render_thin_template(l)
    thin_templates[l] = t
    mask = t > 0.20
    if not mask.any(): mask = t > 0.10
    dt_maps[l] = distance_transform_edt(~mask)

# Test with mockStrokesA
from test_engine_simulation import mockStrokesA, mockStrokesDa, mockStrokesAa, preprocess_strokes_to_image

def evaluate_thin(strokes, expected_char):
    raw_a = preprocess_strokes_to_image(strokes, canvas_size=(350, 350), target_size=(32, 32))
    u_mask = raw_a > 0.20
    if not u_mask.any(): u_mask = raw_a > 0.10
    u_dt = distance_transform_edt(~u_mask)
    u_pts = int(u_mask.sum())

    scores = []
    for l in labels:
        t_mask = thin_templates[l] > 0.20
        if not t_mask.any(): t_mask = thin_templates[l] > 0.10
        t_pts = int(t_mask.sum())
        t_dt = dt_maps[l]
        
        u_dists = t_dt[u_mask]
        prec = float((u_dists <= 2.5).sum() / u_pts) if u_pts > 0 else 0
        prec_soft = float(np.mean(np.exp(- (u_dists / 1.8) ** 2)))
        
        t_dists = u_dt[t_mask]
        rec = float((t_dists <= 2.5).sum() / t_pts) if t_pts > 0 else 0
        rec_soft = float(np.mean(np.exp(- (t_dists / 1.8) ** 2)))
        
        f1 = (2 * prec * rec) / (prec + rec) if (prec + rec) > 0 else 0
        f1_soft = (2 * prec_soft * rec_soft) / (prec_soft + rec_soft) if (prec_soft + rec_soft) > 0 else 0
        
        density = min(u_pts / t_pts, t_pts / u_pts) if t_pts > 0 and u_pts > 0 else 0
        
        s = 0.40 * f1 + 0.40 * f1_soft + 0.20 * density
        scores.append((l, s, prec, rec))

    scores.sort(key=lambda x: x[1], reverse=True)
    top1 = scores[0]
    exp = next(x for x in scores if x[0] == expected_char)
    is_match = (top1[0] == expected_char) and exp[1] >= 0.50
    return is_match, top1[0], exp[1], exp[2], exp[3]

print("1. 'mockStrokesA' for 'அ':", evaluate_thin(mockStrokesA, "அ"))
print("2. 'mockStrokesDa' for 'அ':", evaluate_thin(mockStrokesDa, "அ"))
print("3. 'mockStrokesAa' for 'அ':", evaluate_thin(mockStrokesAa, "அ"))
