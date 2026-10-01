import sys
if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')
import json
import urllib.request
import urllib.parse

def recognize_tamil_handwriting_google(strokes, width=350, height=350, lang="ta"):
    """
    Calls Google's free Handwriting Recognition API.
    strokes format: list of strokes, each stroke is list of (x, y) coordinates
    """
    # Google format: [ [ [x1, x2, ...], [y1, y2, ...], [t1, t2, ...] ], ... ]
    ink = []
    t = 0
    for s in strokes:
        xs = [int(pt[0]) for pt in s]
        ys = [int(pt[1]) for pt in s]
        ts = [t + i * 20 for i in range(len(s))]
        t += len(s) * 20 + 100
        ink.append([xs, ys, ts])

    payload = {
        "app_version": 0.4,
        "api_level": "533.0",
        "device": "5",
        "input_type": "0",
        "options": "enable_pre_space",
        "requests": [
            {
                "writer_id": "user1",
                "ink": ink,
                "language": lang,
                "writing_guide": {
                    "writing_area_width": width,
                    "writing_area_height": height
                }
            }
        ]
    }

    url = "https://www.google.com.tw/inputtools/request?ime=handwriting&app=mobilesearch&cs=1&oe=UTF-8"
    req_data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=req_data,
        headers={"Content-Type": "application/json"}
    )

    try:
        with urllib.request.urlopen(req, timeout=5) as response:
            res_text = response.read().decode("utf-8")
            data = json.loads(res_text)
            if data[0] == "SUCCESS":
                candidates = data[1][0][1]
                return candidates
            else:
                return []
    except Exception as e:
        return [f"Error: {e}"]

# Test with canonical 'அ', 'ஆ', 'ஊ', 'ஔ'
sys.path.append("ai_model/scripts")
from generate_canonical_31_templates import canonical_strokes_bank

print("--- Testing Google Free Handwriting API for Tamil ---")
for letter in ["அ", "ஆ", "இ", "ஈ", "உ", "ஊ", "எ", "ஏ", "ஐ", "ஒ", "ஓ", "ஔ", "க்", "ற்"]:
    strokes = canonical_strokes_bank[letter][0]
    res = recognize_tamil_handwriting_google(strokes, lang="ta")
    print(f"Letter: '{letter}' -> Google Predictions: {res[:5] if isinstance(res, list) else res}")
