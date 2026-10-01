import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from skimage.morphology import skeletonize
from scipy.ndimage import distance_transform_edt
import json

sys.path.append("ai_model/training")
from preprocess import TARGET_DIMENSION

labels_file = "frontend/assets/ml/labels.txt"
with open(labels_file, "r", encoding="utf-8") as f:
    labels = [l.strip() for l in f if l.strip()]

font_path = "C:\\Windows\\Fonts\\Nirmala.ttc"
font = ImageFont.truetype(font_path, 100)

skeletons = {}
dt_maps = {}

for l in labels:
    img = Image.new("L", (200, 200), 0)
    draw = ImageDraw.Draw(img)
    bbox = draw.textbbox((0, 0), l, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text(((200 - tw) // 2 - bbox[0], (200 - th) // 2 - bbox[1]), l, font=font, fill=255)
    
    arr = np.array(img) > 100
    # Find bounding box
    coords = np.argwhere(arr)
    if len(coords) == 0:
        skel_32 = np.zeros((32, 32), dtype=bool)
    else:
        ymin, xmin = coords.min(axis=0)
        ymax, xmax = coords.max(axis=0)
        h = ymax - ymin + 1
        w = xmax - xmin + 1
        cropped = arr[ymin:ymax+1, xmin:xmax+1]
        
        # Skeletonize
        skel = skeletonize(cropped)
        
        # Pad to square
        max_side = max(w, h)
        pad = int(max_side * 0.15)
        box = max_side + pad * 2
        sq = np.zeros((box, box), dtype=np.uint8)
        oy = (box - h) // 2
        ox = (box - w) // 2
        sq[oy:oy+h, ox:ox+w] = (skel * 255).astype(np.uint8)
        
        # Resize to 32x32
        res = Image.fromarray(sq).resize((32, 32), Image.Resampling.BILINEAR)
        skel_32 = np.array(res) > 30

    skeletons[l] = skel_32
    dt_maps[l] = distance_transform_edt(~skel_32)
    print(f"Skeleton '{l}': {skel_32.sum()} active pixels")

# Test with mockStrokesA
from test_engine_simulation import mockStrokesA, preprocess_strokes_to_image

raw_a = preprocess_strokes_to_image(mockStrokesA, canvas_size=(350, 350), target_size=(32, 32))
u_mask = skeletonize(raw_a > 0.15)
u_dt = distance_transform_edt(~u_mask)
u_pts = int(u_mask.sum())

scores = []
for l in labels:
    t_mask = skeletons[l]
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
    s = 0.5 * f1 + 0.5 * f1_soft
    scores.append((l, s, prec, rec))

scores.sort(key=lambda x: x[1], reverse=True)
print("\nScores for 'அ' with SKELETON MATCHING:")
for l, s, prec, rec in scores[:10]:
    print(f"  '{l}': score={s:.3f}, prec={prec:.2f}, rec={rec:.2f}")
