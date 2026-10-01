import sys, os, numpy as np
from PIL import Image

sys.stdout.reconfigure(encoding='utf-8')

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

square_img = Image.fromarray((square * 255).astype(np.uint8)).resize((32, 32), Image.Resampling.BILINEAR)
u_raw = np.array(square_img, dtype=np.float32) / 255.0

print("User drawing in 32x32:")
for y in range(32):
    line = "".join(["#" if u_raw[y, x] > 0.3 else "." for x in range(32)])
    print(line)
