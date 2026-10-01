import sys
if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')
import math
import numpy as np

# Canonical stroke path definitions normalized to [0.0, 1.0] box
canonical_vector_paths = {
    "அ": [
        [(0.45, 0.20), (0.40, 0.25), (0.45, 0.31), (0.51, 0.25), (0.45, 0.20), (0.55, 0.20), (0.60, 0.27), (0.60, 0.38)],
        [(0.60, 0.38), (0.51, 0.50), (0.37, 0.61), (0.25, 0.68), (0.20, 0.74), (0.27, 0.78), (0.38, 0.74), (0.50, 0.57), (0.71, 0.57)],
        [(0.71, 0.20), (0.71, 0.57), (0.71, 0.80)],
    ],
    "ஆ": [
        [(0.45, 0.20), (0.40, 0.25), (0.45, 0.31), (0.51, 0.25), (0.45, 0.20), (0.55, 0.20), (0.60, 0.27), (0.60, 0.38)],
        [(0.60, 0.38), (0.51, 0.50), (0.37, 0.61), (0.25, 0.68), (0.20, 0.74), (0.27, 0.78), (0.38, 0.74), (0.50, 0.57), (0.71, 0.57)],
        [(0.71, 0.20), (0.71, 0.57), (0.71, 0.74), (0.80, 0.82), (0.85, 0.78), (0.81, 0.72), (0.71, 0.74)],
    ],
    "இ": [
        [(0.40, 0.22), (0.34, 0.20), (0.31, 0.25), (0.37, 0.31), (0.45, 0.28), (0.57, 0.25), (0.65, 0.31), (0.68, 0.40)],
        [(0.68, 0.40), (0.62, 0.48), (0.48, 0.51), (0.37, 0.57), (0.31, 0.65), (0.37, 0.74), (0.48, 0.74), (0.62, 0.71), (0.71, 0.74)],
    ],
    "ஈ": [
        [(0.31, 0.25), (0.31, 0.77)],
        [(0.31, 0.25), (0.68, 0.25), (0.68, 0.77)],
        [(0.50, 0.50)],
        [(0.80, 0.50)],
    ],
    "உ": [
        [(0.31, 0.34), (0.25, 0.30), (0.21, 0.34), (0.25, 0.38), (0.31, 0.35), (0.41, 0.25), (0.51, 0.25), (0.55, 0.35), (0.55, 0.45)],
        [(0.55, 0.45), (0.48, 0.60), (0.35, 0.71), (0.28, 0.78), (0.74, 0.78)],
    ],
    "ஊ": [
        [(0.25, 0.40), (0.21, 0.35), (0.17, 0.40), (0.21, 0.44), (0.25, 0.41), (0.35, 0.32), (0.45, 0.32), (0.48, 0.41), (0.48, 0.50)],
        [(0.48, 0.50), (0.42, 0.62), (0.30, 0.71), (0.24, 0.78), (0.60, 0.78)],
        [(0.62, 0.34), (0.58, 0.31), (0.57, 0.34), (0.60, 0.37), (0.65, 0.35), (0.71, 0.31), (0.74, 0.37), (0.74, 0.51), (0.65, 0.60), (0.77, 0.60)],
    ],
    "எ": [
        [(0.34, 0.51), (0.28, 0.47), (0.25, 0.51), (0.30, 0.55), (0.34, 0.52), (0.37, 0.31), (0.65, 0.31)],
        [(0.65, 0.31), (0.65, 0.78)],
    ],
    "ஏ": [
        [(0.34, 0.51), (0.28, 0.47), (0.25, 0.51), (0.30, 0.55), (0.34, 0.52), (0.37, 0.31), (0.65, 0.31)],
        [(0.65, 0.31), (0.65, 0.78)],
        [(0.34, 0.52), (0.20, 0.78)],
    ],
    "ஐ": [
        [(0.28, 0.31), (0.24, 0.28), (0.22, 0.32), (0.27, 0.35), (0.22, 0.40), (0.27, 0.42)],
        [(0.27, 0.42), (0.40, 0.28), (0.51, 0.28), (0.60, 0.37), (0.48, 0.62), (0.62, 0.62), (0.68, 0.51)],
    ],
    "ஒ": [
        [(0.34, 0.31), (0.28, 0.27), (0.25, 0.31), (0.30, 0.35), (0.35, 0.34), (0.45, 0.27), (0.54, 0.31), (0.51, 0.45)],
        [(0.51, 0.45), (0.37, 0.51), (0.40, 0.65), (0.51, 0.68), (0.62, 0.62), (0.62, 0.51), (0.71, 0.51), (0.71, 0.71)],
    ],
    "ஓ": [
        [(0.34, 0.31), (0.28, 0.27), (0.25, 0.31), (0.30, 0.35), (0.35, 0.34), (0.45, 0.27), (0.54, 0.31), (0.51, 0.45)],
        [(0.51, 0.45), (0.37, 0.51), (0.40, 0.65), (0.51, 0.68), (0.62, 0.62)],
        [(0.62, 0.62), (0.65, 0.68), (0.74, 0.68), (0.74, 0.78), (0.65, 0.78), (0.62, 0.65)],
    ],
    "ஔ": [
        [(0.22, 0.31), (0.18, 0.27), (0.15, 0.31), (0.20, 0.35), (0.24, 0.34), (0.32, 0.27), (0.40, 0.31), (0.37, 0.42)],
        [(0.37, 0.42), (0.27, 0.48), (0.30, 0.60), (0.38, 0.62), (0.47, 0.58), (0.47, 0.48), (0.54, 0.48), (0.54, 0.65)],
        [(0.62, 0.37), (0.58, 0.34), (0.57, 0.37), (0.60, 0.40), (0.65, 0.38), (0.71, 0.34), (0.74, 0.40), (0.74, 0.54), (0.65, 0.62), (0.77, 0.62)],
    ],
    "க்": [
        [(0.31, 0.31), (0.31, 0.75)],
        [(0.31, 0.31), (0.68, 0.31), (0.68, 0.75)],
        [(0.50, 0.52), (0.68, 0.52), (0.75, 0.75)],
        [(0.50, 0.18)],
    ],
    "ங்": [
        [(0.31, 0.31), (0.31, 0.75)],
        [(0.31, 0.31), (0.68, 0.31), (0.68, 0.54), (0.50, 0.54), (0.50, 0.75), (0.71, 0.75)],
        [(0.50, 0.18)],
    ],
    "ச்": [
        [(0.31, 0.31), (0.31, 0.75)],
        [(0.31, 0.31), (0.68, 0.31), (0.68, 0.75)],
        [(0.50, 0.52), (0.74, 0.52)],
        [(0.50, 0.18)],
    ],
    "ஞ்": [
        [(0.31, 0.31), (0.31, 0.75)],
        [(0.31, 0.31), (0.68, 0.31), (0.68, 0.54), (0.50, 0.54), (0.50, 0.75)],
        [(0.50, 0.62), (0.74, 0.62), (0.74, 0.75)],
        [(0.50, 0.18)],
    ],
    "ட்": [
        [(0.34, 0.31), (0.34, 0.75), (0.71, 0.75)],
        [(0.52, 0.18)],
    ],
    "ண்": [
        [(0.25, 0.40), (0.21, 0.37), (0.20, 0.41), (0.24, 0.44), (0.30, 0.41), (0.35, 0.37), (0.34, 0.44), (0.38, 0.41), (0.44, 0.37), (0.42, 0.44), (0.48, 0.41), (0.54, 0.37), (0.57, 0.42), (0.57, 0.75)],
        [(0.41, 0.18)],
    ],
    "த்": [
        [(0.31, 0.31), (0.31, 0.75)],
        [(0.31, 0.31), (0.68, 0.31), (0.68, 0.57), (0.48, 0.57), (0.48, 0.75), (0.68, 0.75), (0.74, 0.82)],
        [(0.50, 0.18)],
    ],
    "ந்": [
        [(0.31, 0.31), (0.31, 0.75)],
        [(0.31, 0.31), (0.68, 0.31), (0.68, 0.57), (0.48, 0.57), (0.48, 0.75), (0.71, 0.75)],
        [(0.50, 0.18)],
    ],
    "ப்": [
        [(0.31, 0.31), (0.31, 0.75), (0.68, 0.75), (0.68, 0.31)],
        [(0.50, 0.18)],
    ],
    "ம்": [
        [(0.31, 0.31), (0.31, 0.75), (0.68, 0.75), (0.68, 0.54), (0.31, 0.54)],
        [(0.50, 0.18)],
    ],
    "ய்": [
        [(0.31, 0.31), (0.31, 0.52), (0.42, 0.52), (0.42, 0.31), (0.42, 0.75), (0.68, 0.75), (0.68, 0.31)],
        [(0.50, 0.18)],
    ],
    "ர்": [
        [(0.34, 0.31), (0.34, 0.75)],
        [(0.34, 0.31), (0.62, 0.31), (0.62, 0.52), (0.34, 0.52)],
        [(0.48, 0.18)],
    ],
    "ல்": [
        [(0.31, 0.50), (0.25, 0.45), (0.22, 0.50), (0.27, 0.54), (0.32, 0.51), (0.41, 0.40), (0.51, 0.40), (0.60, 0.48), (0.54, 0.75)],
        [(0.42, 0.18)],
    ],
    "வ்": [
        [(0.31, 0.50), (0.25, 0.45), (0.22, 0.50), (0.27, 0.54), (0.32, 0.51), (0.41, 0.40), (0.65, 0.40), (0.65, 0.75)],
        [(0.48, 0.18)],
    ],
    "ழ்": [
        [(0.31, 0.31), (0.31, 0.75)],
        [(0.31, 0.31), (0.65, 0.31), (0.65, 0.57), (0.45, 0.57), (0.45, 0.68), (0.68, 0.68), (0.68, 0.82)],
        [(0.48, 0.18)],
    ],
    "ள்": [
        [(0.31, 0.50), (0.25, 0.45), (0.22, 0.50), (0.27, 0.54), (0.32, 0.51), (0.41, 0.40), (0.51, 0.40), (0.57, 0.45), (0.57, 0.62), (0.48, 0.75), (0.68, 0.75)],
        [(0.45, 0.18)],
    ],
    "ற்": [
        [(0.34, 0.75), (0.48, 0.31), (0.62, 0.75)],
        [(0.48, 0.18)],
    ],
    "ன்": [
        [(0.28, 0.42), (0.24, 0.40), (0.22, 0.44), (0.27, 0.47), (0.32, 0.44), (0.40, 0.38), (0.38, 0.47), (0.44, 0.44), (0.51, 0.38), (0.54, 0.44), (0.54, 0.75)],
        [(0.41, 0.18)],
    ],
    "ஃ": [
        [(0.50, 0.31)],
        [(0.35, 0.65)],
        [(0.65, 0.65)],
    ]
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

def get_character_points(letter):
    strokes = canonical_vector_paths[letter]
    all_pts = []
    for s in strokes:
        all_pts.extend(densify_stroke(s, step=0.015))
    return all_pts

# Geometric Vector Path Alignment Evaluator
def evaluate_vector_path_alignment(user_strokes, expected_char, canvas_size=(350, 350)):
    # 1. Normalize user strokes to [0, 1] relative to canvas
    user_pts = []
    w, h = canvas_size
    for s in user_strokes:
        norm_s = [(pt[0] / w, pt[1] / h) for pt in s]
        user_pts.extend(densify_stroke(norm_s, step=0.015))

    if len(user_pts) < 15:
        return False, 0.0, "போதிய எழுத்து வரிகள் வரையப்படவில்லை"

    # Also calculate bounding box of user drawing
    ux = [p[0] for p in user_pts]
    uy = [p[1] for p in user_pts]
    u_w = max(ux) - min(ux)
    u_h = max(uy) - min(uy)

    # Reject full canvas wild scribbles
    if u_w > 0.85 and u_h > 0.85:
        # Check density / total length
        total_len = len(user_pts)
        if total_len > 400:
            return False, 0.0, "எழுத்தை மட்டும் தெளிவாக எழுதவும்"

    # Reference letter checkpoints
    ref_pts = get_character_points(expected_char)
    if len(ref_pts) == 0:
        return False, 0.0, "Invalid letter"

    # Measure 1: User Precision (How close are user points to the reference letter path?)
    # Max allowed distance tolerance = 0.12 (approx 42 pixels on 350px canvas)
    user_dists = []
    for up in user_pts:
        min_d = min(math.hypot(up[0] - rp[0], up[1] - rp[1]) for rp in ref_pts)
        user_dists.append(min_d)

    # % of user points inside the allowable corridor
    valid_user_pts = sum(1 for d in user_dists if d <= 0.11)
    precision = valid_user_pts / len(user_pts)

    # Measure 2: Target Coverage / Recall (How much of the reference letter was covered by the user?)
    covered_ref_pts = 0
    for rp in ref_pts:
        min_d = min(math.hypot(rp[0] - up[0], rp[1] - up[1]) for up in user_pts)
        if min_d <= 0.11:
            covered_ref_pts += 1
    coverage = covered_ref_pts / len(ref_pts)

    # Average error distance
    avg_dist = np.mean(user_dists)
    distance_score = max(0.0, 1.0 - (avg_dist / 0.15))

    # Overall geometric score
    final_score = 0.40 * coverage + 0.40 * precision + 0.20 * distance_score

    # Strict Criteria:
    # 1. Coverage >= 55% (must trace at least 55% of the target letter)
    # 2. Precision >= 60% (at least 60% of user ink must stay on the letter path, preventing scribbles)
    # 3. Final score >= 0.55
    is_match = (coverage >= 0.50 and precision >= 0.55 and final_score >= 0.50)

    feedback = "சரியானது! 🎉" if is_match else "மீண்டும் முயற்சி செய்க"
    return is_match, final_score, feedback

# Let's test!
print("=== 1. Testing Authentic Letters ===")
for char in ["அ", "ஆ", "இ", "ஈ", "உ", "ஊ", "எ", "ஏ", "ஐ", "ஒ", "ஓ", "ஔ", "க்", "ற்"]:
    strokes = canonical_vector_paths[char]
    canvas_strokes = [[(p[0] * 350, p[1] * 350) for p in s] for s in strokes]
    m, sc, fb = evaluate_vector_path_alignment(canvas_strokes, char)
    print(f"Letter '{char}': Match={m}, Score={sc:.2f}, Feedback={fb}")

print("\n=== 2. Testing Random Scribble across canvas ===")
scribble = [
    [(x, 50 + (x % 30) * 8) for x in range(30, 320, 10)],
    [(50 + (y % 40) * 6, y) for y in range(40, 310, 12)],
    [(320 - x, x) for x in range(40, 300, 15)],
    [(x, 320 - x) for x in range(40, 300, 15)],
]
m, sc, fb = evaluate_vector_path_alignment(scribble, "அ")
print(f"Random Scribble on 'அ': Match={m}, Score={sc:.2f}, Feedback={fb}")

print("\n=== 3. Testing Single Line on 'அ' ===")
single_line = [[(175, y) for y in range(50, 300, 10)]]
m, sc, fb = evaluate_vector_path_alignment(single_line, "அ")
print(f"Single Line on 'அ': Match={m}, Score={sc:.2f}, Feedback={fb}")

print("\n=== 4. Testing Drawing 'இ' when practicing 'ஆ' ===")
strokes_i = canonical_vector_paths["இ"]
canvas_strokes_i = [[(p[0] * 350, p[1] * 350) for p in s] for s in strokes_i]
m, sc, fb = evaluate_vector_path_alignment(canvas_strokes_i, "ஆ")
print(f"Draw 'இ' for 'ஆ': Match={m}, Score={sc:.2f}, Feedback={fb}")

print("\n=== 5. Testing Drawing 'ஆ' when practicing 'அ' ===")
strokes_aa = canonical_vector_paths["ஆ"]
canvas_strokes_aa = [[(p[0] * 350, p[1] * 350) for p in s] for s in strokes_aa]
m, sc, fb = evaluate_vector_path_alignment(canvas_strokes_aa, "அ")
print(f"Draw 'ஆ' for 'அ': Match={m}, Score={sc:.2f}, Feedback={fb}")
