import sys
from test_cv2_thinning import *
from test_engine_simulation import mockStrokesA, preprocess_strokes_to_image

raw_app_a = preprocess_strokes_to_image(mockStrokesA, (350, 350), (32, 32))
raw_t = thin_templates["அ"]
print("Active pixels in thin_templates['அ']:", (raw_t > 0.15).sum())

u_mask = raw_app_a > 0.15
t_mask = raw_t > 0.15

print("Active pixels in raw_app_a:", u_mask.sum())
print("Active pixels in template 'அ':", t_mask.sum())

u_dt = distance_transform_edt(~u_mask)
t_dt = dt_maps["அ"]

u_dists = t_dt[u_mask]
t_dists = u_dt[t_mask]

print(f"Mean dist user to template: {u_dists.mean():.2f}")
print(f"Mean dist template to user: {t_dists.mean():.2f}")
print(f"User within 2.5: {(u_dists <= 2.5).sum()} / {u_mask.sum()} = {(u_dists <= 2.5).sum()/u_mask.sum():.2f}")
print(f"Template within 2.5: {(t_dists <= 2.5).sum()} / {t_mask.sum()} = {(t_dists <= 2.5).sum()/t_mask.sum():.2f}")
