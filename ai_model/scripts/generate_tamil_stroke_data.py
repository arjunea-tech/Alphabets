"""Generate the Tamil writing-guide data used by the Flutter writing canvas.

Outputs
  frontend/lib/data/tamil_stroke_data.dart     stroke order, start/end points, paths
  frontend/lib/data/tamil_letter_outlines.dart glyph outline drawn behind the strokes

Both files share ONE normalized frame (0..1, the guide square on the canvas), so the
letter the child sees and the stroke paths/start/end points always line up.

How it works
  1. The glyph is shaped (HarfBuzz) from Noto Sans Tamil (wght 500) and scaled so its
     larger side fills FIT of the guide square, centred at (0.5, 0.5).
  2. Each stroke below is written as a few hand-placed guide points in that frame, in
     writing order. A smooth curve is fitted through them and then snapped onto the
     glyph's centre line (the ridge of the distance transform), so start/end points
     and paths sit exactly in the middle of the letter's track.
  3. The script reports any part of the glyph that no stroke covers, and any stroke
     sample that leaves the glyph, so mistakes in the spec are caught.

Stroke-order conventions (school handwriting):
  * Letters that start with a small loop (சுழி) begin at that loop.
  * Otherwise start top-left; lines go top->bottom and left->right.
  * Use one continuous stroke where the letter is written without lifting the pen.
  * The pulli (dot) and the dots of ஃ come last.

Usage:  python ai_model/scripts/generate_tamil_stroke_data.py [--preview out.png]
Requires: numpy pillow scipy fonttools uharfbuzz
"""
import argparse
import os
import re
import sys

import numpy as np
import uharfbuzz as hb
from fontTools.pens.recordingPen import DecomposingRecordingPen
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer
from PIL import Image, ImageDraw
from scipy import ndimage

if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
FONT_PATH = os.path.join(ROOT, 'ai_model', 'fonts', 'NotoSansTamil[wdth,wght].ttf')
STROKE_OUT = os.path.join(ROOT, 'frontend', 'lib', 'data', 'tamil_stroke_data.dart')
OUTLINE_OUT = os.path.join(ROOT, 'frontend', 'lib', 'data', 'tamil_letter_outlines.dart')

FIT = 0.84          # larger ink side of every letter fills 84% of the guide square
RES = 1000          # raster resolution used for centre-line snapping
SNAP_RANGE = 0.04   # how far (normalized) a guide point may move to reach the centre line
OUT_SPACING = 0.025 # spacing of the exported path points

# ---------------------------------------------------------------------------
# Stroke specification. Coordinates are in the normalized guide frame.
# ('line', label, [points...])  - a traced stroke, points in writing order
# ('dot',  label, (x, y))       - a dot / pulli (tap)
# ---------------------------------------------------------------------------
SPEC = {
    'அ': ('uyir', [
        ('line', 'சுழி + வளைவு + கோடு', [
            (0.44, 0.24), (0.50, 0.28), (0.53, 0.35), (0.50, 0.41), (0.44, 0.44),
            (0.37, 0.42), (0.34, 0.36), (0.37, 0.28), (0.45, 0.24), (0.55, 0.26),
            (0.62, 0.30), (0.67, 0.38), (0.69, 0.47), (0.66, 0.56), (0.60, 0.63),
            (0.50, 0.69), (0.35, 0.73), (0.20, 0.71), (0.13, 0.65), (0.13, 0.59),
            (0.20, 0.555), (0.40, 0.553), (0.60, 0.553), (0.76, 0.553), (0.86, 0.553)]),
        ('line', 'நேர் கோடு', [(0.877, 0.26), (0.877, 0.50), (0.877, 0.75)]),
    ]),
    'ஆ': ('uyir', [
        ('line', 'சுழி + வளைவு + கோடு', [
            (0.37, 0.24), (0.42, 0.28), (0.44, 0.33), (0.41, 0.38), (0.36, 0.40),
            (0.30, 0.38), (0.28, 0.32), (0.31, 0.26), (0.37, 0.24), (0.46, 0.26),
            (0.52, 0.31), (0.555, 0.38), (0.56, 0.44), (0.52, 0.51), (0.45, 0.57),
            (0.30, 0.62), (0.17, 0.62), (0.10, 0.57), (0.12, 0.51), (0.18, 0.49),
            (0.35, 0.49), (0.50, 0.49), (0.62, 0.49), (0.70, 0.49)]),
        ('line', 'நேர் கோடு', [(0.705, 0.26), (0.705, 0.45), (0.705, 0.62)]),
        ('line', 'வளைவு', [
            (0.705, 0.55), (0.77, 0.535), (0.84, 0.55), (0.88, 0.61), (0.87, 0.68), (0.80, 0.74),
            (0.68, 0.755), (0.57, 0.74), (0.52, 0.70), (0.535, 0.655), (0.61, 0.633)]),
    ]),
    'இ': ('uyir', [
        ('line', 'சுழி + வளைவுகள் + நேர் கோடு', [
            (0.45, 0.30), (0.51, 0.34), (0.52, 0.40), (0.48, 0.46), (0.42, 0.48), (0.36, 0.44),
            (0.35, 0.37), (0.40, 0.31), (0.47, 0.30), (0.58, 0.35), (0.62, 0.42), (0.645, 0.50),
            (0.64, 0.57), (0.60, 0.64), (0.52, 0.74), (0.445, 0.82), (0.38, 0.875), (0.28, 0.89),
            (0.19, 0.87), (0.15, 0.79), (0.17, 0.70), (0.24, 0.645), (0.35, 0.61), (0.45, 0.60),
            (0.57, 0.615), (0.67, 0.67), (0.71, 0.76), (0.68, 0.85), (0.60, 0.89), (0.51, 0.88),
            (0.445, 0.82), (0.36, 0.74), (0.27, 0.66), (0.21, 0.58), (0.19, 0.46), (0.19, 0.34),
            (0.24, 0.23), (0.33, 0.15), (0.45, 0.115), (0.57, 0.12), (0.69, 0.17), (0.77, 0.26),
            (0.81, 0.38), (0.815, 0.52), (0.815, 0.65)]),
    ]),
    'ஈ': ('uyir', [
        ('line', 'கீழிருந்து மேல் + மேல் கோடு', [(0.15, 0.79), (0.15, 0.50), (0.15, 0.195), (0.40, 0.19), (0.65, 0.19), (0.86, 0.19)]),
        ('line', 'நடுக் கோடு', [(0.58, 0.19), (0.58, 0.50), (0.58, 0.79)]),
        ('dot', 'இடது புள்ளி', (0.36, 0.50)),
        ('dot', 'வலது புள்ளி', (0.80, 0.50)),
    ]),
    'உ': ('uyir', [
        ('line', 'சுழி + வளைவு + கீழ்க் கோடு', [
            (0.24, 0.285), (0.30, 0.34), (0.31, 0.42), (0.26, 0.48), (0.18, 0.485), (0.13, 0.44),
            (0.13, 0.36), (0.18, 0.30), (0.25, 0.285), (0.34, 0.31), (0.42, 0.32), (0.48, 0.36),
            (0.505, 0.44), (0.49, 0.52), (0.42, 0.565), (0.28, 0.585), (0.16, 0.61), (0.125, 0.66),
            (0.16, 0.70), (0.35, 0.703), (0.60, 0.703), (0.88, 0.703)]),
    ]),
    'ஊ': ('uyir', [
        ('line', 'சுழி + வளைவு + கீழ்க் கோடு', [
            (0.20, 0.35), (0.245, 0.40), (0.23, 0.47), (0.18, 0.495), (0.12, 0.46), (0.11, 0.41),
            (0.15, 0.36), (0.205, 0.35), (0.27, 0.36), (0.33, 0.39), (0.36, 0.46), (0.33, 0.52),
            (0.25, 0.555), (0.15, 0.57), (0.115, 0.60), (0.15, 0.635), (0.40, 0.637), (0.65, 0.637), (0.90, 0.637)]),
        ('line', 'சுழி + வளைவு + கோடு', [
            (0.525, 0.455), (0.58, 0.45), (0.61, 0.49), (0.60, 0.54), (0.55, 0.56), (0.50, 0.53),
            (0.48, 0.47), (0.50, 0.41), (0.56, 0.37), (0.63, 0.37), (0.69, 0.39), (0.70, 0.45),
            (0.70, 0.55)]),
        ('line', 'மேல் கோடு', [(0.70, 0.365), (0.80, 0.365), (0.90, 0.365)]),
        ('line', 'நேர் கோடு', [(0.826, 0.365), (0.826, 0.46), (0.826, 0.55)]),
    ]),
    'எ': ('uyir', [
        ('line', 'சுழி + வளைவு + மேல் கோடு', [
            (0.22, 0.50), (0.31, 0.47), (0.40, 0.49), (0.45, 0.56), (0.45, 0.65), (0.40, 0.73),
            (0.30, 0.77), (0.20, 0.74), (0.13, 0.66), (0.115, 0.55), (0.14, 0.44), (0.20, 0.33),
            (0.30, 0.26), (0.45, 0.235), (0.60, 0.232), (0.75, 0.232), (0.87, 0.232)]),
        ('line', 'நேர் கோடு', [(0.68, 0.235), (0.68, 0.50), (0.68, 0.74)]),
    ]),
    'ஏ': ('uyir', [
        ('line', 'சுழி + வளைவு + மேல் கோடு', [
            (0.21, 0.38), (0.30, 0.36), (0.39, 0.39), (0.45, 0.47), (0.44, 0.57), (0.36, 0.645),
            (0.25, 0.645), (0.16, 0.57), (0.115, 0.47), (0.12, 0.36), (0.18, 0.25), (0.28, 0.17),
            (0.42, 0.13), (0.55, 0.125), (0.70, 0.125), (0.87, 0.125)]),
        ('line', 'நேர் கோடு + சாய்வு', [(0.675, 0.13), (0.675, 0.40), (0.675, 0.63), (0.64, 0.70), (0.56, 0.78), (0.49, 0.85)]),
    ]),
    'ஐ': ('uyir', [
        ('line', 'சுழி + அலை வளைவுகள்', [
            (0.29, 0.20), (0.34, 0.25), (0.35, 0.31), (0.32, 0.38), (0.24, 0.41), (0.16, 0.38),
            (0.13, 0.30), (0.14, 0.22), (0.19, 0.16), (0.26, 0.14), (0.36, 0.14), (0.45, 0.16),
            (0.51, 0.21), (0.54, 0.27), (0.54, 0.37), (0.54, 0.27), (0.57, 0.20), (0.63, 0.15),
            (0.71, 0.14), (0.80, 0.17), (0.855, 0.25), (0.855, 0.33), (0.82, 0.41), (0.75, 0.46),
            (0.64, 0.49), (0.50, 0.51), (0.35, 0.52), (0.22, 0.545), (0.15, 0.60), (0.13, 0.70),
            (0.16, 0.79), (0.23, 0.845), (0.34, 0.86), (0.45, 0.84), (0.51, 0.79), (0.54, 0.73),
            (0.54, 0.67), (0.54, 0.73), (0.57, 0.80), (0.65, 0.85), (0.75, 0.855), (0.82, 0.81),
            (0.855, 0.73), (0.865, 0.64)]),
    ]),
    'ஒ': ('uyir', [
        ('line', 'சுழி + மேல் வளைவு + உள் வளைவு', [
            (0.20, 0.31), (0.27, 0.30), (0.33, 0.33), (0.36, 0.41), (0.33, 0.49), (0.255, 0.517),
            (0.18, 0.50), (0.13, 0.43), (0.13, 0.34), (0.16, 0.26), (0.25, 0.18), (0.36, 0.145),
            (0.48, 0.139), (0.62, 0.155), (0.75, 0.21), (0.84, 0.30), (0.865, 0.385), (0.84, 0.47),
            (0.78, 0.515), (0.70, 0.51), (0.655, 0.46), (0.65, 0.39), (0.66, 0.35), (0.63, 0.328),
            (0.60, 0.335)]),
        ('line', 'நடுக் கோடு + கிடைமட்டக் கோடு', [
            (0.60, 0.335), (0.54, 0.38), (0.51, 0.45), (0.51, 0.52), (0.55, 0.60), (0.615, 0.66),
            (0.73, 0.672), (0.82, 0.673)]),
        ('line', 'கீழ் வளைவு', [
            (0.615, 0.66), (0.635, 0.69), (0.60, 0.76), (0.52, 0.83), (0.42, 0.86), (0.33, 0.85),
            (0.29, 0.79), (0.28, 0.70), (0.295, 0.645)]),
    ]),
    'ஓ': ('uyir', [
        ('line', 'சுழி + மேல் வளைவு + உள் வளைவு', [
            (0.20, 0.31), (0.27, 0.30), (0.33, 0.33), (0.36, 0.41), (0.33, 0.49), (0.255, 0.517),
            (0.18, 0.50), (0.13, 0.43), (0.13, 0.34), (0.16, 0.26), (0.25, 0.18), (0.36, 0.145),
            (0.48, 0.139), (0.62, 0.155), (0.75, 0.21), (0.84, 0.30), (0.865, 0.385), (0.84, 0.47),
            (0.78, 0.515), (0.70, 0.51), (0.655, 0.46), (0.65, 0.39), (0.66, 0.35), (0.63, 0.328),
            (0.60, 0.335)]),
        ('line', 'நடுக் கோடு + கிடைமட்டக் கோடு', [
            (0.60, 0.335), (0.54, 0.38), (0.51, 0.45), (0.51, 0.52), (0.55, 0.60), (0.615, 0.66),
            (0.73, 0.672), (0.82, 0.675)]),
        ('line', 'கீழ் வளைவு + கீழ்ச் சுழி', [
            (0.615, 0.66), (0.635, 0.69), (0.60, 0.76), (0.54, 0.83), (0.46, 0.86), (0.37, 0.865), (0.29, 0.85),
            (0.235, 0.79), (0.235, 0.71), (0.28, 0.66), (0.35, 0.65), (0.41, 0.68), (0.43, 0.74),
            (0.42, 0.795)]),
    ]),
    'ஔ': ('uyir', [
        ('line', 'சுழி + மேல் வளைவு + உள் வளைவு', [
            (0.14, 0.414), (0.175, 0.41), (0.205, 0.423), (0.22, 0.459), (0.205, 0.495),
            (0.167, 0.508), (0.13, 0.5), (0.105, 0.468), (0.105, 0.428), (0.12, 0.391),
            (0.165, 0.355), (0.22, 0.339), (0.28, 0.337), (0.35, 0.344), (0.415, 0.369),
            (0.46, 0.41), (0.472, 0.448), (0.46, 0.486), (0.43, 0.507), (0.39, 0.505),
            (0.36, 0.47), (0.34, 0.44), (0.32, 0.43)]),
        ('line', 'நடுக் கோடு + கிடைமட்டக் கோடு', [
            (0.32, 0.43), (0.30, 0.45), (0.28, 0.48), (0.28, 0.52), (0.30, 0.565),
            (0.36, 0.578), (0.415, 0.578)]),
        ('line', 'கீழ் வளைவு', [
            (0.30, 0.565), (0.33, 0.586), (0.32, 0.618), (0.28, 0.649), (0.23, 0.663),
            (0.19, 0.65), (0.18, 0.62), (0.18, 0.57)]),
        ('line', 'சுழி + வளைவு + கோடு', [
            (0.54, 0.43), (0.59, 0.42), (0.625, 0.46), (0.62, 0.51), (0.575, 0.54), (0.525, 0.51),
            (0.51, 0.45), (0.52, 0.40), (0.56, 0.35), (0.62, 0.335), (0.68, 0.35), (0.72, 0.38),
            (0.722, 0.45), (0.722, 0.53)]),
        ('line', 'மேல் கோடு', [(0.722, 0.34), (0.81, 0.34), (0.895, 0.34)]),
        ('line', 'நேர் கோடு', [(0.83, 0.34), (0.83, 0.44), (0.83, 0.53)]),
    ]),
    'ஃ': ('aytham', [
        ('line', 'மேல் வட்டம்', [(0.50, 0.12), (0.60, 0.16), (0.63, 0.26), (0.60, 0.36), (0.50, 0.40), (0.40, 0.36), (0.37, 0.26), (0.40, 0.16), (0.50, 0.12)]),
        ('line', 'இடது வட்டம்', [(0.27, 0.60), (0.37, 0.64), (0.40, 0.735), (0.37, 0.83), (0.27, 0.87), (0.17, 0.83), (0.14, 0.735), (0.17, 0.64), (0.27, 0.60)]),
        ('line', 'வலது வட்டம்', [(0.73, 0.60), (0.83, 0.64), (0.86, 0.735), (0.83, 0.83), (0.73, 0.87), (0.63, 0.83), (0.60, 0.735), (0.63, 0.64), (0.73, 0.60)]),
    ]),
    'க்': ('mei', [
        ('line', 'இடது நேர் கோடு', [(0.27, 0.385), (0.27, 0.50), (0.27, 0.61)]),
        ('line', 'மேல் கோடு', [(0.27, 0.385), (0.50, 0.385), (0.74, 0.385)]),
        ('line', 'நடுக் கோடு + கீழ் வளைவு + வளைவு', [
            (0.54, 0.385), (0.52, 0.55), (0.50, 0.70), (0.45, 0.85), (0.35, 0.875),
            (0.24, 0.85), (0.18, 0.79), (0.22, 0.68), (0.27, 0.61),
            (0.40, 0.61), (0.54, 0.61), (0.63, 0.61), (0.74, 0.63),
            (0.80, 0.69), (0.81, 0.77), (0.77, 0.84), (0.70, 0.87), (0.64, 0.87)]),
        ('dot', 'புள்ளி', (0.52, 0.15)),
    ]),
    'ங்': ('mei', [
        ('line', 'கீழிருந்து மேல் + மேல் கோடு', [(0.115, 0.83), (0.115, 0.60), (0.115, 0.40), (0.30, 0.40), (0.50, 0.40)]),
        ('line', 'நடுக் கோடு', [(0.37, 0.40), (0.37, 0.55), (0.37, 0.69)]),
        ('line', 'வளைவு', [(0.37, 0.615), (0.45, 0.60), (0.55, 0.58), (0.61, 0.61), (0.635, 0.70), (0.625, 0.79), (0.62, 0.835)]),
        ('line', 'கீழ்க் கோடு + மேல் ஏற்றம்', [(0.36, 0.835), (0.60, 0.835), (0.86, 0.835), (0.86, 0.60), (0.86, 0.41)]),
        ('dot', 'புள்ளி', (0.45, 0.19)),
    ]),
    'ச்': ('mei', [
        ('line', 'இடது நேர் கோடு', [(0.32, 0.39), (0.32, 0.50), (0.32, 0.61)]),
        ('line', 'மேல் கோடு', [(0.32, 0.385), (0.55, 0.385), (0.79, 0.385)]),
        ('line', 'நடுக் கோடு + கீழ் வளைவு + படுக்கை', [
            (0.58, 0.385), (0.58, 0.50), (0.58, 0.65), (0.55, 0.78), (0.50, 0.85),
            (0.40, 0.875), (0.28, 0.84), (0.23, 0.76), (0.235, 0.68), (0.27, 0.61),
            (0.40, 0.61), (0.60, 0.61), (0.79, 0.61)]),
        ('dot', 'புள்ளி', (0.57, 0.15)),
    ]),
    'ஞ்': ('mei', [
        ('line', 'சுழி + மேல் கோடு', [
            (0.36, 0.475), (0.42, 0.465), (0.48, 0.50), (0.505, 0.56), (0.49, 0.62), (0.42, 0.655),
            (0.34, 0.64), (0.30, 0.58), (0.29, 0.50), (0.31, 0.43), (0.36, 0.36), (0.43, 0.31),
            (0.52, 0.30), (0.66, 0.30), (0.79, 0.30)]),
        ('line', 'நேர் கோடு', [(0.66, 0.30), (0.66, 0.47), (0.66, 0.64)]),
        ('line', 'வளைவு + கீழ்ச் சுற்று', [
            (0.66, 0.495), (0.72, 0.475), (0.80, 0.48), (0.86, 0.52), (0.875, 0.60), (0.84, 0.70),
            (0.76, 0.80), (0.65, 0.86), (0.50, 0.88), (0.33, 0.86), (0.22, 0.79), (0.15, 0.68),
            (0.12, 0.55), (0.14, 0.40), (0.18, 0.29)]),
        ('dot', 'புள்ளி', (0.49, 0.13)),
    ]),
    'ட்': ('mei', [
        ('line', 'கீழ் இறக்கம் + வலப்பக்கம்', [(0.235, 0.40), (0.235, 0.65), (0.235, 0.875), (0.52, 0.875), (0.785, 0.875)]),
        ('dot', 'புள்ளி', (0.47, 0.15)),
    ]),
    'ண்': ('mei', [
        ('line', 'சுழி + மூன்று வளைவுகள் + நேர் கோடு', [
            (0.15, 0.55), (0.21, 0.55), (0.24, 0.60), (0.235, 0.66), (0.17, 0.69), (0.12, 0.665),
            (0.10, 0.60), (0.11, 0.53), (0.15, 0.47), (0.21, 0.44), (0.28, 0.44),
            (0.38, 0.46), (0.34, 0.55), (0.34, 0.65), (0.40, 0.71), (0.46, 0.65), (0.45, 0.52), (0.39, 0.46),
            (0.48, 0.44),
            (0.60, 0.46), (0.56, 0.55), (0.56, 0.65), (0.62, 0.71), (0.68, 0.65), (0.67, 0.52), (0.60, 0.46),
            (0.72, 0.44), (0.81, 0.44), (0.81, 0.56), (0.81, 0.68)]),
        ('dot', 'புள்ளி', (0.485, 0.32)),
    ]),
    'த்': ('mei', [
        ('line', 'இடது நேர் கோடு', [(0.333, 0.30), (0.333, 0.40), (0.333, 0.49)]),
        ('line', 'மேல் கோடு', [(0.333, 0.30), (0.50, 0.30), (0.678, 0.30)]),
        ('line', 'நடுக் கோடு + வளைவு + வால்', [
            (0.53, 0.30), (0.52, 0.45), (0.48, 0.58), (0.40, 0.65), (0.32, 0.645),
            (0.27, 0.60), (0.264, 0.53), (0.289, 0.47), (0.333, 0.49),
            (0.45, 0.48), (0.56, 0.48), (0.65, 0.49),
            (0.71, 0.53), (0.728, 0.60), (0.70, 0.68), (0.611, 0.745), (0.50, 0.765),
            (0.40, 0.77), (0.306, 0.778), (0.272, 0.817), (0.256, 0.889)]),
        ('dot', 'புள்ளி', (0.52, 0.13)),
    ]),
    'ந்': ('mei', [
        ('line', 'கீழிருந்து மேல் + மேல் கோடு', [(0.30, 0.64), (0.30, 0.45), (0.30, 0.30), (0.45, 0.30), (0.63, 0.30)]),
        ('line', 'நடுக் கோடு', [(0.50, 0.30), (0.50, 0.47), (0.50, 0.64)]),
        ('line', 'வளைவு', [
            (0.50, 0.47), (0.56, 0.455), (0.63, 0.45), (0.70, 0.50), (0.725, 0.60), (0.70, 0.70),
            (0.60, 0.76), (0.45, 0.77), (0.33, 0.78), (0.28, 0.82), (0.27, 0.90)]),
        ('dot', 'புள்ளி', (0.50, 0.13)),
    ]),
    'ப்': ('mei', [
        ('line', 'கீழ் இறக்கம் + வலம் + மேல் ஏற்றம்', [(0.235, 0.40), (0.235, 0.65), (0.235, 0.875), (0.50, 0.875), (0.765, 0.875), (0.765, 0.65), (0.765, 0.40)]),
        ('dot', 'புள்ளி', (0.50, 0.15)),
    ]),
    'ம்': ('mei', [
        ('line', 'கீழ் இறக்கம் + கிடைமட்டம் + வளைவு + நடுக் கோடு', [
            (0.175, 0.40), (0.175, 0.65), (0.175, 0.875), (0.35, 0.875), (0.495, 0.875),
            (0.60, 0.875), (0.70, 0.86), (0.79, 0.79), (0.82, 0.66), (0.79, 0.54),
            (0.72, 0.42), (0.65, 0.38), (0.585, 0.385), (0.53, 0.44), (0.505, 0.55),
            (0.50, 0.70), (0.495, 0.875)]),
        ('dot', 'புள்ளி', (0.485, 0.15)),
    ]),
    'ய்': ('mei', [
        ('line', 'கீழ் இறக்கம் + வளைவு + மேல் ஏற்றம்', [
            (0.14, 0.40), (0.14, 0.60), (0.145, 0.75), (0.18, 0.83), (0.245, 0.875), (0.32, 0.86),
            (0.40, 0.835), (0.417, 0.80), (0.417, 0.60), (0.417, 0.40)]),
        ('line', 'கீழ் இறக்கம் + வலம் + மேல் ஏற்றம்', [(0.417, 0.40), (0.417, 0.65), (0.42, 0.865), (0.65, 0.865), (0.855, 0.865), (0.855, 0.65), (0.855, 0.40)]),
        ('dot', 'புள்ளி', (0.50, 0.15)),
    ]),
    'ர்': ('mei', [
        ('line', 'கீழிருந்து மேல் + மேல் கோடு', [(0.315, 0.70), (0.315, 0.50), (0.315, 0.33), (0.50, 0.325), (0.70, 0.325)]),
        ('line', 'நேர் கோடு + சாய்வு', [(0.55, 0.33), (0.55, 0.50), (0.55, 0.70), (0.52, 0.76), (0.47, 0.81), (0.42, 0.865)]),
        ('dot', 'புள்ளி', (0.47, 0.14)),
    ]),
    'ல்': ('mei', [
        ('line', 'சுழி + பெரிய வளைவு', [
            (0.20, 0.61), (0.28, 0.60), (0.34, 0.65), (0.355, 0.73), (0.31, 0.80), (0.23, 0.83),
            (0.15, 0.80), (0.115, 0.72), (0.11, 0.63), (0.14, 0.53), (0.22, 0.43), (0.35, 0.39),
            (0.45, 0.42), (0.50, 0.50), (0.53, 0.65), (0.57, 0.78), (0.65, 0.83), (0.75, 0.82),
            (0.83, 0.75), (0.86, 0.63), (0.83, 0.51), (0.79, 0.42), (0.785, 0.37)]),
        ('dot', 'புள்ளி', (0.50, 0.19)),
    ]),
    'வ்': ('mei', [
        ('line', 'சுழி + வளைவு + வலம் + மேல் ஏற்றம்', [
            (0.19, 0.61), (0.28, 0.60), (0.35, 0.65), (0.375, 0.72), (0.35, 0.79), (0.27, 0.835),
            (0.18, 0.81), (0.125, 0.73), (0.105, 0.65), (0.12, 0.57), (0.17, 0.48), (0.25, 0.42),
            (0.35, 0.39), (0.46, 0.41), (0.54, 0.48), (0.585, 0.58), (0.58, 0.70), (0.565, 0.80),
            (0.565, 0.825), (0.70, 0.825), (0.87, 0.825), (0.873, 0.62), (0.873, 0.41)]),
        ('dot', 'புள்ளி', (0.51, 0.19)),
    ]),
    'ழ்': ('mei', [
        ('line', 'கீழ் இறக்கம் + படுக்கை + வளைவு + வால்', [
            (0.276, 0.311), (0.276, 0.50), (0.276, 0.65), (0.40, 0.65), (0.511, 0.65),
            (0.60, 0.65), (0.67, 0.645), (0.722, 0.60), (0.742, 0.50), (0.725, 0.39),
            (0.68, 0.315), (0.611, 0.294), (0.545, 0.32), (0.515, 0.40), (0.511, 0.50),
            (0.515, 0.655), (0.515, 0.72), (0.555, 0.775), (0.545, 0.83), (0.49, 0.875),
            (0.389, 0.888), (0.29, 0.875), (0.255, 0.825), (0.285, 0.775), (0.33, 0.76),
            (0.361, 0.756)]),
        ('line', 'சிறு கோடு', [(0.561, 0.778), (0.63, 0.778), (0.70, 0.778)]),
        ('dot', 'புள்ளி', (0.50, 0.13)),
    ]),
    'ள்': ('mei', [
        ('line', 'சுழி + வளைவு + நேர் கோடு', [
            (0.17, 0.60), (0.26, 0.59), (0.32, 0.63), (0.345, 0.70), (0.31, 0.775), (0.235, 0.80),
            (0.16, 0.77), (0.11, 0.70), (0.10, 0.61), (0.13, 0.54), (0.18, 0.47), (0.25, 0.415),
            (0.33, 0.40), (0.42, 0.42), (0.49, 0.44), (0.525, 0.47), (0.525, 0.62), (0.525, 0.78)]),
        ('line', 'மேல் கோடு', [(0.53, 0.41), (0.70, 0.41), (0.89, 0.41)]),
        ('line', 'நேர் கோடு', [(0.745, 0.41), (0.745, 0.60), (0.745, 0.78)]),
        ('dot', 'புள்ளி', (0.485, 0.22)),
    ]),
    'ற்': ('mei', [
        ('line', 'கீழிருந்து மேல் + வளைவு + நேர் கோடு', [
            (0.255, 0.64), (0.255, 0.50), (0.26, 0.40), (0.29, 0.33), (0.35, 0.30), (0.42, 0.315),
            (0.47, 0.36), (0.48, 0.45), (0.48, 0.64)]),
        ('line', 'வளைவு + கீழ் வளைவு', [
            (0.485, 0.38), (0.51, 0.33), (0.56, 0.30), (0.63, 0.295), (0.69, 0.33), (0.735, 0.42),
            (0.75, 0.52), (0.735, 0.62), (0.68, 0.70), (0.60, 0.745), (0.45, 0.77), (0.32, 0.775),
            (0.26, 0.81), (0.245, 0.89)]),
        ('dot', 'புள்ளி', (0.50, 0.13)),
    ]),
    'ன்': ('mei', [
        ('line', 'சுழி + இரு வளைவுகள் + நேர் கோடு', [
            (0.16, 0.58), (0.23, 0.575), (0.29, 0.62), (0.31, 0.67), (0.28, 0.74), (0.20, 0.76),
            (0.13, 0.72), (0.10, 0.65), (0.10, 0.58), (0.13, 0.50), (0.20, 0.44), (0.30, 0.415),
            (0.40, 0.425), (0.54, 0.44), (0.46, 0.52), (0.43, 0.65), (0.48, 0.75), (0.56, 0.75),
            (0.60, 0.65), (0.56, 0.52), (0.48, 0.44), (0.60, 0.42), (0.77, 0.42),
            (0.77, 0.58), (0.77, 0.74)]),
        ('dot', 'புள்ளி', (0.49, 0.26)),
    ]),
    'க': ('uyirmei', [
        ('line', 'இடது நேர் கோடு', [(0.27, 0.235), (0.27, 0.35), (0.27, 0.46)]),
        ('line', 'மேல் கோடு', [(0.27, 0.235), (0.50, 0.235), (0.74, 0.235)]),
        ('line', 'நடுக் கோடு + கீழ் வளைவு + வளைவு', [
            (0.54, 0.235), (0.52, 0.40), (0.50, 0.55), (0.45, 0.70), (0.35, 0.725),
            (0.24, 0.70), (0.18, 0.64), (0.22, 0.53), (0.27, 0.46),
            (0.40, 0.46), (0.54, 0.46), (0.63, 0.46), (0.74, 0.48),
            (0.80, 0.54), (0.81, 0.62), (0.77, 0.69), (0.70, 0.72), (0.64, 0.72)]),
    ]),
    'கா': ('uyirmei', [
        ('line', 'இடது நேர் கோடு', [(0.17, 0.355), (0.17, 0.43), (0.17, 0.50)]),
        ('line', 'மேல் கோடு', [(0.17, 0.355), (0.30, 0.355), (0.43, 0.355)]),
        ('line', 'நடுக் கோடு + கீழ் வளைவு + வளைவு', [
            (0.33, 0.355), (0.33, 0.45), (0.31, 0.60), (0.25, 0.64), (0.16, 0.625),
            (0.12, 0.57), (0.13, 0.50), (0.17, 0.50), (0.27, 0.49), (0.38, 0.485),
            (0.45, 0.50), (0.48, 0.56), (0.46, 0.615), (0.415, 0.636)]),
        ('line', 'கால் (ா): கீழிருந்து மேல் + மேல் கோடு', [(0.626, 0.62), (0.626, 0.48), (0.626, 0.358), (0.76, 0.358), (0.89, 0.358)]),
        ('line', 'கால் (ா): நேர் கோடு', [(0.794, 0.358), (0.794, 0.49), (0.794, 0.62)]),
    ]),
    'கி': ('uyirmei', [
        ('line', 'கீழ் இறக்கம் + வளைவு + மேல் ஏற்றம் + கொம்பு', [
            (0.21, 0.415), (0.21, 0.48), (0.205, 0.53), (0.17, 0.59), (0.15, 0.66), (0.16, 0.74),
            (0.22, 0.80), (0.30, 0.82), (0.37, 0.79), (0.42, 0.71), (0.43, 0.60), (0.43, 0.50),
            (0.43, 0.40), (0.43, 0.30), (0.46, 0.21), (0.53, 0.175), (0.62, 0.17), (0.71, 0.21),
            (0.78, 0.30), (0.80, 0.42), (0.80, 0.60), (0.80, 0.80)]),
        ('line', 'மேல் கோடு', [(0.21, 0.415), (0.40, 0.415), (0.60, 0.415)]),
        ('line', 'நடுக் கோடு + வளைவு', [(0.17, 0.62), (0.25, 0.61), (0.40, 0.605), (0.52, 0.605), (0.61, 0.625), (0.665, 0.69), (0.665, 0.77), (0.61, 0.815), (0.54, 0.82)]),
    ]),
    'கீ': ('uyirmei', [
        ('line', 'கீழ் இறக்கம் + வளைவு + மேல் ஏற்றம் + சுழி', [
            (0.256, 0.402), (0.256, 0.47), (0.25, 0.53), (0.21, 0.60), (0.17, 0.68), (0.165, 0.77),
            (0.22, 0.85), (0.322, 0.876), (0.41, 0.85), (0.47, 0.79), (0.50, 0.71), (0.51, 0.60),
            (0.51, 0.48), (0.508, 0.38), (0.506, 0.30), (0.528, 0.20), (0.58, 0.14), (0.64, 0.10),
            (0.70, 0.09), (0.77, 0.11), (0.83, 0.16), (0.85, 0.22), (0.82, 0.28), (0.75, 0.295),
            (0.69, 0.27), (0.67, 0.21), (0.69, 0.165), (0.73, 0.14)]),
        ('line', 'மேல் கோடு', [(0.256, 0.402), (0.48, 0.402), (0.706, 0.402)]),
        ('line', 'நடுக் கோடு + வளைவு', [
            (0.20, 0.645), (0.30, 0.625), (0.45, 0.622), (0.60, 0.622), (0.70, 0.65), (0.77, 0.72),
            (0.789, 0.79), (0.75, 0.85), (0.68, 0.875), (0.61, 0.872)]),
    ]),
}

DEFAULT_WORDS = {
    'கா': ('காகம்', '🐦'),
    'கி': ('கிளி', '🦜'),
    'கீ': ('கீரை', '🥬'),
}


# ---------------------------------------------------------------------------
# Glyph geometry
# ---------------------------------------------------------------------------
class GlyphFont:
    def __init__(self, path):
        vf = TTFont(path)
        self.tt = instancer.instantiateVariableFont(vf, {'wght': 500, 'wdth': 100})
        self.gs = self.tt.getGlyphSet()
        self.order = self.tt.getGlyphOrder()
        blob = hb.Blob.from_file_path(path)
        self.hb_font = hb.Font(hb.Face(blob))
        self.hb_font.set_variations({'wght': 500, 'wdth': 100})

    def contours(self, text):
        buf = hb.Buffer()
        buf.add_str(text)
        buf.guess_segment_properties()
        hb.shape(self.hb_font, buf, {})
        polys, pen_x = [], 0
        for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
            rp = DecomposingRecordingPen(self.gs)
            self.gs[self.order[info.codepoint]].draw(rp)
            for c in _flatten(rp.value):
                a = np.array(c, float)
                a[:, 0] += pen_x + pos.x_offset
                a[:, 1] = -(a[:, 1] + pos.y_offset)  # y down
                polys.append(a)
            pen_x += pos.x_advance
        return polys

    def normalized(self, text):
        polys = self.contours(text)
        allp = np.concatenate(polys)
        lo, hi = allp.min(0), allp.max(0)
        s = FIT / max(hi - lo)
        c = (lo + hi) / 2
        return [(p - c) * s + 0.5 for p in polys]


def _flatten(ops):
    contours, cur, last = [], [], None
    for op, args in ops:
        if op == 'moveTo':
            cur = [args[0]]
            last = args[0]
        elif op == 'lineTo':
            cur.append(args[0])
            last = args[0]
        elif op == 'qCurveTo':
            offs, end = list(args[:-1]), args[-1]
            if end is None:
                end = ((offs[-1][0] + offs[0][0]) / 2, (offs[-1][1] + offs[0][1]) / 2)
            p0 = last
            for i, c in enumerate(offs):
                e = end if i == len(offs) - 1 else ((c[0] + offs[i + 1][0]) / 2, (c[1] + offs[i + 1][1]) / 2)
                for t in np.linspace(0, 1, 9)[1:]:
                    cur.append(((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * c[0] + t * t * e[0],
                                (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * c[1] + t * t * e[1]))
                p0 = e
            if not offs:
                cur.append(end)
            last = end
        elif op == 'curveTo':
            c1, c2, e = args
            p0 = last
            for t in np.linspace(0, 1, 11)[1:]:
                cur.append(((1 - t) ** 3 * p0[0] + 3 * (1 - t) ** 2 * t * c1[0] + 3 * (1 - t) * t * t * c2[0] + t ** 3 * e[0],
                            (1 - t) ** 3 * p0[1] + 3 * (1 - t) ** 2 * t * c1[1] + 3 * (1 - t) * t * t * c2[1] + t ** 3 * e[1]))
            last = e
        elif op in ('closePath', 'endPath'):
            if len(cur) > 2:
                contours.append(cur)
            cur = []
    return contours


def raster(polys, res=RES):
    """Scanline fill with the non-zero winding rule (what Flutter's Path uses by default).
    Noto contours overlap and self-intersect, so an even-odd fill would punch fake holes."""
    edges = []
    for p in polys:
        q = p * res
        edges.append(np.hstack([q, np.roll(q, -1, axis=0)]))
    e = np.vstack(edges)
    x0, y0, x1, y1 = e.T
    wind = np.where(y1 > y0, 1, -1)
    mask = np.zeros((res, res), bool)
    xs = np.arange(res) + 0.5
    for row in range(res):
        yc = row + 0.5
        hit = ((y0 <= yc) & (y1 > yc)) | ((y1 <= yc) & (y0 > yc))
        if not hit.any():
            continue
        t = (yc - y0[hit]) / (y1[hit] - y0[hit])
        xi = x0[hit] + t * (x1[hit] - x0[hit])
        order = np.argsort(xi)
        xi, w = xi[order], wind[hit][order]
        cum = np.cumsum(w)
        for k in range(len(xi) - 1):
            if cum[k] != 0:
                mask[row, (xs >= xi[k]) & (xs < xi[k + 1])] = True
    return mask


def rdp(points, eps):
    if len(points) < 3:
        return points
    a, b = points[0], points[-1]
    ab = b - a
    n = np.hypot(*ab)
    if n == 0:
        d = np.hypot(*(points - a).T)
    else:
        d = np.abs(ab[0] * (points[:, 1] - a[1]) - ab[1] * (points[:, 0] - a[0])) / n
    i = int(np.argmax(d))
    if d[i] > eps:
        return np.vstack([rdp(points[:i + 1], eps)[:-1], rdp(points[i:], eps)])
    return np.array([a, b])


# ---------------------------------------------------------------------------
# Stroke fitting
# ---------------------------------------------------------------------------
def catmull_rom(pts, step=0.004):
    pts = np.array(pts, float)
    out = [pts[0]]
    for i in range(len(pts) - 1):
        p0 = pts[i - 1] if i > 0 else pts[i]
        p1, p2 = pts[i], pts[i + 1]
        p3 = pts[i + 2] if i + 2 < len(pts) else p2
        n = max(2, int(np.hypot(*(p2 - p1)) / step))
        for t in np.linspace(0, 1, n + 1)[1:]:
            t2, t3 = t * t, t * t * t
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
    return np.array(out)


def resample(path, spacing):
    seg = np.hypot(*np.diff(path, axis=0).T)
    cum = np.concatenate([[0], np.cumsum(seg)])
    total = cum[-1]
    n = max(2, int(round(total / spacing)) + 1)
    s = np.linspace(0, total, n)
    return np.stack([np.interp(s, cum, path[:, 0]), np.interp(s, cum, path[:, 1])], 1)


def smooth(arr, win):
    if win < 2 or len(arr) < 3:
        return arr
    k = np.ones(win) / win
    pad = win // 2
    padded = np.pad(arr, (pad, pad), mode='edge')
    return np.convolve(padded, k, mode='valid')[:len(arr)]


def snap_to_centerline(path, dt):
    """Move every sample along its normal to the ridge of the distance transform."""
    res = dt.shape[0]
    for _ in range(2):
        d = np.gradient(path, axis=0)
        t = d / np.maximum(np.hypot(d[:, 0], d[:, 1])[:, None], 1e-9)
        nrm = np.stack([-t[:, 1], t[:, 0]], 1)
        offs = np.linspace(-SNAP_RANGE, SNAP_RANGE, 41)
        best = np.zeros(len(path))
        for i, (p, nv) in enumerate(zip(path, nrm)):
            cand = p + offs[:, None] * nv
            ix = np.clip((cand * res).astype(int), 0, res - 1)
            vals = dt[ix[:, 1], ix[:, 0]]
            # prefer the ridge closest to the guide point when the ridge is flat
            score = vals - 0.15 * np.abs(offs)
            best[i] = offs[int(np.argmax(score))]
        best = smooth(best, 21)
        path = path + best[:, None] * nrm
    return path


def fit_stroke(guide, dt):
    dense = catmull_rom(guide)
    dense = resample(dense, 0.004)
    dense = snap_to_centerline(dense, dt)
    dense = np.stack([smooth(dense[:, 0], 5), smooth(dense[:, 1], 5)], 1)
    # keep the exact (snapped) guide endpoints so start/end markers stay on the letter
    out = resample(dense, OUT_SPACING)
    return dense, out


def snap_dot(p, mask):
    lab, _ = ndimage.label(mask)
    res = mask.shape[0]
    x, y = int(p[0] * res), int(p[1] * res)
    l = lab[y, x]
    if l == 0:
        raise ValueError(f'dot {p} is not on the glyph')
    cy, cx = ndimage.center_of_mass(lab == l)
    return np.array([cx / res, cy / res])


def direction_hint(path):
    d = np.diff(path, axis=0)
    ang = np.unwrap(np.arctan2(d[:, 1], d[:, 0]))
    turn = ang[-1] - ang[0] if len(ang) > 1 else 0
    if abs(turn) > np.radians(300):
        return 'loop_cw' if turn > 0 else 'loop_ccw'  # y axis points down
    v = path[-1] - path[0]
    if np.hypot(*v) < 0.08:
        return 'loop_cw' if turn > 0 else 'loop_ccw'
    a = np.degrees(np.arctan2(v[1], v[0]))
    names = ['right', 'right_down', 'down', 'left_down', 'left', 'left_up', 'up', 'right_up']
    return names[int(((a + 22.5) % 360) // 45)]


INSTRUCTION = {
    'down': 'மேலிருந்து கீழாக எழுதவும்',
    'up': 'கீழிருந்து மேலாக எழுதவும்',
    'right': 'இடமிருந்து வலமாக எழுதவும்',
    'left': 'வலமிருந்து இடமாக எழுதவும்',
    'right_down': 'வலப்பக்கம் கீழ் நோக்கி எழுதவும்',
    'left_down': 'இடப்பக்கம் கீழ் நோக்கி எழுதவும்',
    'right_up': 'வலப்பக்கம் மேல் நோக்கி எழுதவும்',
    'left_up': 'இடப்பக்கம் மேல் நோக்கி எழுதவும்',
    'loop_cw': 'அம்புக்குறி திசையில் சுழித்து எழுதவும்',
    'loop_ccw': 'அம்புக்குறி திசையில் சுழித்து எழுதவும்',
}


# ---------------------------------------------------------------------------
# Checks and output
# ---------------------------------------------------------------------------
def check_letter(letter, mask, dt, fitted_paths, dots):
    res = mask.shape[0]
    half = dt.max()
    problems = []
    for i, p in enumerate(fitted_paths):
        for name, q in (('start', p[0]), ('end', p[-1])):
            x, y = np.clip((q * res).astype(int), 0, res - 1)
            if dt[y, x] < 0.3 * half:
                problems.append(f'stroke {i + 1}: {name} point {np.round(q, 3)} is not inside the letter')
        ix = np.clip((p * res).astype(int), 0, res - 1)
        inside = dt[ix[:, 1], ix[:, 0]]
        off = inside < 0.35 * half
        if off.mean() > 0.03:
            bad = p[off]
            problems.append(f'stroke {i + 1}: {off.mean():.0%} of samples near/outside the edge, e.g. {np.round(bad[len(bad) // 2], 3)}')
    # coverage: every glyph pixel deep enough inside must be near some stroke
    core = dt > 0.6 * half
    ys, xs = np.nonzero(core)
    pts = np.stack([xs, ys], 1) / res
    if fitted_paths or dots:
        ref = np.concatenate(fitted_paths + [np.array(d)[None] for d in dots])
        step = max(1, len(pts) // 6000)
        sample = pts[::step]
        dmin = np.min(np.hypot(sample[:, None, 0] - ref[None, :, 0], sample[:, None, 1] - ref[None, :, 1]), axis=1)
        miss = sample[dmin > 1.6 * half + 0.01]
        if len(miss):
            problems.append(f'{len(miss) / len(sample):.1%} of glyph not covered, e.g. {np.round(miss[len(miss) // 2], 3)}')
    return problems


def fmt(v):
    return f'{v:.3f}'


def dart_string(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'") + "'"


def existing_words(path):
    words = {}
    if not os.path.exists(path):
        return words
    src = open(path, encoding='utf-8').read()
    for m in re.finditer(r"'([^']+)': const TamilWritingLetter\(\s*letter: '[^']+',\s*category: '[^']+',\s*sampleWord: '([^']*)',\s*sampleEmoji: '([^']*)'", src):
        words[m.group(1)] = (m.group(2), m.group(3))
    return words


def build(preview=None):
    font = GlyphFont(FONT_PATH)
    words = existing_words(STROKE_OUT)
    words.update({k: v for k, v in DEFAULT_WORDS.items() if k not in words})

    letters_out, outlines_out, previews = [], [], []
    total_problems = 0
    for letter, (category, strokes) in SPEC.items():
        polys = font.normalized(letter)
        mask = raster(polys)
        dt = ndimage.distance_transform_edt(mask) / RES

        fitted, exported, dots = [], [], []
        for kind, label, data in strokes:
            if kind == 'dot':
                c = snap_dot(data, mask)
                dots.append(c)
                exported.append(('dot', label, np.array([c])))
            else:
                dense, out = fit_stroke(data, dt)
                fitted.append(dense)
                exported.append(('line', label, out))

        problems = check_letter(letter, mask, dt, fitted, dots)
        status = 'OK' if not problems else 'CHECK'
        print(f'{letter}: {len(strokes)} strokes  {status}')
        for p in problems:
            print('    -', p)
        total_problems += len(problems)

        word, emoji = words.get(letter, (letter, '✏️'))
        letters_out.append(render_letter_dart(letter, category, word, emoji, exported))
        outlines_out.append(render_outline_dart(letter, polys))
        if preview:
            previews.append(preview_tile(letter, mask, exported))

    write_stroke_file(letters_out)
    write_outline_file(outlines_out)
    if preview:
        cols = 6
        rows = (len(previews) + cols - 1) // cols
        w = previews[0].width
        sheet = Image.new('RGB', (cols * w, rows * w), 'white')
        for i, im in enumerate(previews):
            sheet.paste(im, ((i % cols) * w, (i // cols) * w))
        sheet.save(preview)
        print('preview ->', preview)
    print(f'\n{len(SPEC)} letters written, {total_problems} warnings')


def render_letter_dart(letter, category, word, emoji, exported):
    lines = []
    has_dot = any(k == 'dot' for k, _, _ in exported)
    lines.append(f"    {dart_string(letter)}: const TamilWritingLetter(")
    lines.append(f"      letter: {dart_string(letter)},")
    lines.append(f"      category: {dart_string(category)},")
    lines.append(f"      sampleWord: {dart_string(word)},")
    lines.append(f"      sampleEmoji: {dart_string(emoji)},")
    rule = 'LetterValidationRule(requireDot: true)' if has_dot else 'LetterValidationRule()'
    lines.append(f"      validationRule: {rule},")
    lines.append("      strokes: [")
    for n, (kind, label, pts) in enumerate(exported, 1):
        if kind == 'dot':
            hint, instr = 'dot', 'பச்சை புள்ளியில் தொட்டு புள்ளி வைக்கவும்'
        else:
            hint = direction_hint(pts)
            instr = f'பச்சை புள்ளியில் தொடங்கி சிவப்பு புள்ளியில் முடிக்கவும்: {INSTRUCTION[hint]}'
        s, e = pts[0], pts[-1]
        lines.append("        LetterStrokeData(")
        lines.append(f"          strokeNumber: {n},")
        lines.append(f"          title: {dart_string(f'படி {n}: {label} ✍️')},")
        lines.append(f"          instruction: {dart_string(instr)},")
        lines.append(f"          directionHint: '{hint}',")
        if kind == 'dot':
            lines.append("          isDot: true,")
        lines.append(f"          startPoint: Offset({fmt(s[0])}, {fmt(s[1])}),")
        lines.append(f"          endPoint: Offset({fmt(e[0])}, {fmt(e[1])}),")
        lines.append("          tolerance: 0.10,")
        lines.append("          pathPoints: [")
        for p in pts:
            lines.append(f"            Offset({fmt(p[0])}, {fmt(p[1])}),")
        lines.append("          ],")
        lines.append("        ),")
    lines.append("      ],")
    lines.append("    ),")
    return '\n'.join(lines)


def render_outline_dart(letter, polys):
    parts = []
    for p in polys:
        q = rdp(np.vstack([p, p[:1]]), 0.0012)[:-1]
        parts.append(' '.join(f'{int(round(x * 1000))},{int(round(y * 1000))}' for x, y in q))
    return f"    {dart_string(letter)}: {dart_string('|'.join(parts))},"


HEADER = """// GENERATED FILE - do not edit by hand.
// Source: ai_model/scripts/generate_tamil_stroke_data.py (Noto Sans Tamil, OFL).
// Coordinates are normalized to the writing guide square (see WritingEngine.guideRect).
"""


def write_stroke_file(letters):
    body = '\n\n'.join(letters)
    src = f"""{HEADER}
import 'dart:ui';
import '../models/letter_stroke_model.dart';

/// Stroke order, start/end points and centre-line paths for each letter.
/// Paths are traced on the same glyph outline that the canvas draws
/// (see tamil_letter_outlines.dart), so they always sit inside the letter.
class TamilStrokeDataRepository {{
  static final Map<String, TamilWritingLetter> _letters = {{
{body}
  }};

  static TamilWritingLetter getLetter(String letter) {{
    if (_letters.containsKey(letter)) return _letters[letter]!;
    return _generateFallbackLetter(letter);
  }}

  static bool hasVerifiedLetter(String letter) => _letters.containsKey(letter);
  static List<String> getAllVerifiedLetters() => _letters.keys.toList();

  static TamilWritingLetter _generateFallbackLetter(String letter) {{
    return TamilWritingLetter(
      letter: letter,
      category: 'uyir',
      sampleWord: letter,
      sampleEmoji: '✏️',
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: எழுத்து வடிவம் ✍️',
          instruction: '$letter எழுத்தை விரலால் அழகாக எழுதிப் பழகுங்கள்',
          directionHint: 'down',
          startPoint: const Offset(0.35, 0.32),
          pathPoints: const [
            Offset(0.35, 0.32),
            Offset(0.35, 0.76),
            Offset(0.68, 0.76),
            Offset(0.68, 0.32),
            Offset(0.35, 0.32),
          ],
        ),
      ],
    );
  }}
}}
"""
    with open(STROKE_OUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write(src)


def write_outline_file(outlines):
    body = '\n'.join(outlines)
    src = f"""{HEADER}
import 'dart:ui';

/// Glyph outlines for the writing guide, in the same normalized frame as
/// [TamilStrokeDataRepository]. Each contour is "x,y x,y ..." in thousandths,
/// contours separated by '|'. Fill with the default non-zero rule.
class TamilLetterOutlines {{
  static const Map<String, String> _data = {{
{body}
  }};

  static final Map<String, List<List<Offset>>> _cache = {{}};

  static bool has(String letter) => _data.containsKey(letter);

  /// Normalized contours (0..1) for [letter], or null if not available.
  static List<List<Offset>>? contours(String letter) {{
    final raw = _data[letter];
    if (raw == null) return null;
    return _cache.putIfAbsent(letter, () {{
      return raw.split('|').map((contour) {{
        return contour.split(' ').map((pair) {{
          final i = pair.indexOf(',');
          return Offset(
            int.parse(pair.substring(0, i)) / 1000.0,
            int.parse(pair.substring(i + 1)) / 1000.0,
          );
        }}).toList();
      }}).toList();
    }});
  }}

  /// Outline path mapped into [frame] (the guide square on the canvas).
  static Path? pathFor(String letter, Rect frame) {{
    final cs = contours(letter);
    if (cs == null) return null;
    final path = Path();
    for (final c in cs) {{
      if (c.isEmpty) continue;
      path.moveTo(frame.left + c[0].dx * frame.width, frame.top + c[0].dy * frame.height);
      for (int i = 1; i < c.length; i++) {{
        path.lineTo(frame.left + c[i].dx * frame.width, frame.top + c[i].dy * frame.height);
      }}
      path.close();
    }}
    return path;
  }}
}}
"""
    with open(OUTLINE_OUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write(src)


def preview_tile(letter, mask, exported, size=320):
    colors = [(230, 57, 70), (42, 157, 143), (69, 123, 157), (244, 162, 97), (131, 56, 236)]
    small = Image.fromarray((~mask * 1).astype(np.uint8) * 40 + 200).resize((size, size)).convert('RGB')
    d = ImageDraw.Draw(small)
    for n, (kind, label, pts) in enumerate(exported):
        c = colors[n % len(colors)]
        xy = [(p[0] * size, p[1] * size) for p in pts]
        if kind == 'line':
            d.line(xy, fill=c, width=3)
            # arrow head at the end
            p, q = np.array(xy[-2]), np.array(xy[-1])
            v = (q - p) / max(np.hypot(*(q - p)), 1e-6)
            nv = np.array([-v[1], v[0]])
            d.polygon([tuple(q), tuple(q - 10 * v + 5 * nv), tuple(q - 10 * v - 5 * nv)], fill=c)
        sx, sy = xy[0]
        d.ellipse([sx - 7, sy - 7, sx + 7, sy + 7], outline=(0, 170, 0), width=3)
        d.text((sx + 8, sy - 16), str(n + 1), fill=c)
        if kind == 'line':
            ex, ey = xy[-1]
            d.rectangle([ex - 4, ey - 4, ex + 4, ey + 4], outline=(200, 0, 0), width=2)
    return small


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--preview', help='write a PNG contact sheet of all letters')
    build(ap.parse_args().preview)
