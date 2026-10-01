import math
import numpy as np
import sys
if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

# 31 Canonical Tamil Character Skeletons (normalized 0.0 to 1.0)
canonical_skeletons = {
    "அ": {
        "strokes": [
            [(0.45, 0.20), (0.40, 0.25), (0.45, 0.31), (0.51, 0.25), (0.45, 0.20), (0.55, 0.20), (0.60, 0.27), (0.60, 0.38)],
            [(0.60, 0.38), (0.51, 0.50), (0.37, 0.61), (0.25, 0.68), (0.20, 0.74), (0.27, 0.78), (0.38, 0.74), (0.50, 0.57), (0.71, 0.57)],
            [(0.71, 0.20), (0.71, 0.57), (0.71, 0.80)],
        ],
        "forbidden_zones": [
            {"box": (0.78, 0.70, 1.0, 1.0), "name": "ஆ_tail"}, # 'அ' must not have 'ஆ' bottom-right tail
        ]
    },
    "ஆ": {
        "strokes": [
            [(0.45, 0.20), (0.40, 0.25), (0.45, 0.31), (0.51, 0.25), (0.45, 0.20), (0.55, 0.20), (0.60, 0.27), (0.60, 0.38)],
            [(0.60, 0.38), (0.51, 0.50), (0.37, 0.61), (0.25, 0.68), (0.20, 0.74), (0.27, 0.78), (0.38, 0.74), (0.50, 0.57), (0.71, 0.57)],
            [(0.71, 0.20), (0.71, 0.57), (0.71, 0.74), (0.80, 0.82), (0.85, 0.78), (0.81, 0.72), (0.71, 0.74)],
        ],
        "required_zones": [
            {"box": (0.72, 0.68, 0.95, 0.92), "min_pts": 3, "name": "ஆ_tail"},
            {"box": (0.65, 0.20, 0.78, 0.50), "min_pts": 3, "name": "top_right_stem"},
        ]
    },
    "இ": {
        "strokes": [
            [(0.40, 0.22), (0.34, 0.20), (0.31, 0.25), (0.37, 0.31), (0.45, 0.28), (0.57, 0.25), (0.65, 0.31), (0.68, 0.40)],
            [(0.68, 0.40), (0.62, 0.48), (0.48, 0.51), (0.37, 0.57), (0.31, 0.65), (0.37, 0.74), (0.48, 0.74), (0.62, 0.71), (0.71, 0.74)],
        ],
        "forbidden_zones": [
            {"box": (0.68, 0.15, 0.85, 0.45), "name": "right_vertical_stem"}, # 'இ' has no top-right vertical line
        ]
    },
    "உ": {
        "strokes": [
            [(0.31, 0.34), (0.25, 0.30), (0.21, 0.34), (0.25, 0.38), (0.31, 0.35), (0.41, 0.25), (0.51, 0.25), (0.55, 0.35), (0.55, 0.45)],
            [(0.55, 0.45), (0.48, 0.60), (0.35, 0.71), (0.28, 0.78), (0.74, 0.78)],
        ],
        "forbidden_zones": [
            {"box": (0.62, 0.15, 0.90, 0.55), "name": "top_la"},
        ]
    },
    "ஊ": {
        "strokes": [
            [(0.25, 0.40), (0.21, 0.35), (0.17, 0.40), (0.21, 0.44), (0.25, 0.41), (0.35, 0.32), (0.45, 0.32), (0.48, 0.41), (0.48, 0.50)],
            [(0.48, 0.50), (0.42, 0.62), (0.30, 0.71), (0.24, 0.78), (0.60, 0.78)],
            [(0.62, 0.34), (0.58, 0.31), (0.57, 0.34), (0.60, 0.37), (0.65, 0.35), (0.71, 0.31), (0.74, 0.37), (0.74, 0.51), (0.65, 0.60), (0.77, 0.60)],
        ],
        "required_zones": [
            {"box": (0.62, 0.15, 0.90, 0.45), "min_pts": 5, "name": "top_la"},
            {"box": (0.15, 0.55, 0.65, 0.85), "min_pts": 5, "name": "u_base"},
        ]
    },
    "ஔ": {
        "strokes": [
            [(0.22, 0.31), (0.18, 0.27), (0.15, 0.31), (0.20, 0.35), (0.24, 0.34), (0.32, 0.27), (0.40, 0.31), (0.37, 0.42)],
            [(0.37, 0.42), (0.27, 0.48), (0.30, 0.60), (0.38, 0.62), (0.47, 0.58), (0.47, 0.48), (0.54, 0.48), (0.54, 0.65)],
            [(0.62, 0.37), (0.58, 0.34), (0.57, 0.37), (0.60, 0.40), (0.65, 0.38), (0.71, 0.34), (0.74, 0.40), (0.74, 0.54), (0.65, 0.62), (0.77, 0.62)],
        ],
        "required_zones": [
            {"box": (0.55, 0.25, 0.85, 0.70), "min_pts": 5, "name": "right_la"},
            {"box": (0.10, 0.25, 0.50, 0.70), "min_pts": 5, "name": "left_o"},
        ]
    },
    "க்": {
        "strokes": [
            [(0.31, 0.31), (0.31, 0.75)],
            [(0.31, 0.31), (0.68, 0.31), (0.68, 0.75)],
            [(0.50, 0.52), (0.68, 0.52), (0.75, 0.75)],
            [(0.50, 0.18)],
        ],
        "required_zones": [
            {"box": (0.40, 0.10, 0.60, 0.25), "min_pts": 1, "name": "pulli"},
        ]
    }
}

def densify_stroke(stroke, step=0.015):
    pts = []
    if len(stroke) == 0:
        return pts
    if len(stroke) == 1:
        return [stroke[0]]
    for i in range(len(stroke) - 1):
        p1 = stroke[i]
        p2 = stroke[i + 1]
        dist = math.hypot(p2[0] - p1[0], p2[1] - p1[1])
        steps = max(int(dist / step), 1)
        for s in range(steps):
            t = s / steps
            pts.append((p1[0] + (p2[0] - p1[0]) * t, p1[1] + (p2[1] - p1[1]) * t))
    pts.append(stroke[-1])
    return pts

def is_in_box(pt, box):
    x_min, y_min, x_max, y_max = box
    return x_min <= pt[0] <= x_max and y_min <= pt[1] <= y_max

def evaluate_structural_engine(user_strokes, expected_char, canvas_size=(350, 350)):
    w, h = canvas_size
    user_pts = []
    total_stroke_len = 0.0

    for s in user_strokes:
        norm_s = [(pt[0] / w, pt[1] / h) for pt in s]
        densified = densify_stroke(norm_s, step=0.015)
        user_pts.extend(densified)
        for i in range(len(norm_s) - 1):
            total_stroke_len += math.hypot(norm_s[i+1][0] - norm_s[i][0], norm_s[i+1][1] - norm_s[i][1])

    # 1. Minimum Ink Check
    if len(user_pts) < 12 or total_stroke_len < 0.25:
        return False, 0.0, "போதிய எழுத்து வரிகள் வரையப்படவில்லை"

    # 2. Anti-Scribble Barrier (Detecting chaotic back-and-forth oscillations or excessive length)
    # Bounding box of user drawing
    ux = [p[0] for p in user_pts]
    uy = [p[1] for p in user_pts]
    u_w = max(ux) - min(ux)
    u_h = max(uy) - min(uy)
    bbox_diag = math.hypot(u_w, u_h)

    # In a clean character, total stroke length is rarely > 4.5 * diagonal
    # A scribble fills the box with massive overlapping length (ratio > 5.5)
    length_ratio = total_stroke_len / max(bbox_diag, 0.1)
    if length_ratio > 4.8 or total_stroke_len > 4.2:
        return False, 0.0, "கிறுக்கல்கள் இல்லாமல் எழுத்தை மட்டும் தெளிவாக எழுதவும்"

    # 3. Reference Path Alignment
    skel = canonical_skeletons.get(expected_char)
    if not skel:
        # Fallback for letters without dedicated rule
        return True, 0.8, "சரியானது! 🎉"

    ref_strokes = skel["strokes"]
    ref_pts = []
    for s in ref_strokes:
        ref_pts.extend(densify_stroke(s, step=0.015))

    # Calculate distance from each user point to the closest reference point
    # Allowed touch corridor radius = 0.09 (approx 31px on 350px screen)
    CORRIDOR = 0.09
    user_dists = [min(math.hypot(up[0] - rp[0], up[1] - rp[1]) for rp in ref_pts) for up in user_pts]
    valid_pts = sum(1 for d in user_dists if d <= CORRIDOR)
    precision = valid_pts / len(user_pts)

    # Calculate coverage of reference path
    covered_ref = sum(1 for rp in ref_pts if min(math.hypot(rp[0] - up[0], rp[1] - up[1]) for up in user_pts) <= CORRIDOR)
    coverage = covered_ref / len(ref_pts)

    # 4. Check Required Zones (e.g. 'ஆ' tail, 'ஊ' ள, 'க்' pulli)
    req_zones = skel.get("required_zones", [])
    for zone in req_zones:
        pts_in_zone = sum(1 for p in user_pts if is_in_box(p, zone["box"]))
        if pts_in_zone < zone.get("min_pts", 3):
            return False, 0.3, f"{expected_char} எழுத்தின் முக்கிய பகுதி விடுபட்டுள்ளது ({zone['name']})"

    # 5. Check Forbidden Zones (e.g. 'இ' must not have right vertical stem, 'அ' must not have 'ஆ' tail)
    forb_zones = skel.get("forbidden_zones", [])
    for zone in forb_zones:
        pts_in_forb = sum(1 for p in user_pts if is_in_box(p, zone["box"]))
        if pts_in_forb >= 4:
            return False, 0.3, f"{expected_char} எழுத்தில் தேவையற்ற கோடுகள் உள்ளன"

    # 6. Final Decision Rule:
    # Must have >= 50% coverage of letter AND >= 55% precision inside corridor
    score = (0.50 * coverage + 0.50 * precision)
    is_match = (coverage >= 0.48 and precision >= 0.52 and score >= 0.50)
    feedback = "சரியானது! 🎉" if is_match else "மீண்டும் முயற்சி செய்க"

    return is_match, score, feedback

# RUN TESTS
print("=== 1. Test Authentic Characters ===")
for char in ["அ", "ஆ", "இ", "உ", "ஊ", "ஔ", "க்"]:
    strokes = canonical_skeletons[char]["strokes"]
    canvas_strokes = [[(p[0] * 350, p[1] * 350) for p in s] for s in strokes]
    m, sc, fb = evaluate_structural_engine(canvas_strokes, char)
    print(f"Letter '{char}' -> Match: {m}, Score: {sc:.2f}, Feedback: {fb}")

print("\n=== 2. Test Random Scribbles ===")
scribble_dense = [
    [(x, y) for x in range(30, 320, 8) for y in [80, 160, 240]],
    [(x, 320 - x) for x in range(30, 320, 6)],
    [(320 - x, x) for x in range(30, 320, 6)],
    [(175, y) for y in range(30, 320, 5)],
]
m, sc, fb = evaluate_structural_engine(scribble_dense, "அ")
print(f"Random Dense Scribble on 'அ' -> Match: {m}, Score: {sc:.2f}, Feedback: {fb}")

print("\n=== 3. Test Single Line ===")
single_line = [[(175, y) for y in range(100, 250, 10)]]
m, sc, fb = evaluate_structural_engine(single_line, "அ")
print(f"Single Line on 'அ' -> Match: {m}, Score: {sc:.2f}, Feedback: {fb}")

print("\n=== 4. Test Drawing 'இ' when practicing 'ஆ' ===")
strokes_i = canonical_skeletons["இ"]["strokes"]
canvas_strokes_i = [[(p[0] * 350, p[1] * 350) for p in s] for s in strokes_i]
m, sc, fb = evaluate_structural_engine(canvas_strokes_i, "ஆ")
print(f"Draw 'இ' for 'ஆ' -> Match: {m}, Score: {sc:.2f}, Feedback: {fb}")

print("\n=== 5. Test Drawing 'ஆ' when practicing 'அ' ===")
strokes_aa = canonical_skeletons["ஆ"]["strokes"]
canvas_strokes_aa = [[(p[0] * 350, p[1] * 350) for p in s] for s in strokes_aa]
m, sc, fb = evaluate_structural_engine(canvas_strokes_aa, "அ")
print(f"Draw 'ஆ' for 'அ' -> Match: {m}, Score: {sc:.2f}, Feedback: {fb}")

print("\n=== 6. Test Drawing 'உ' when practicing 'ஊ' ===")
strokes_u = canonical_skeletons["உ"]["strokes"]
canvas_strokes_u = [[(p[0] * 350, p[1] * 350) for p in s] for s in strokes_u]
m, sc, fb = evaluate_structural_engine(canvas_strokes_u, "ஊ")
print(f"Draw 'உ' for 'ஊ' -> Match: {m}, Score: {sc:.2f}, Feedback: {fb}")
