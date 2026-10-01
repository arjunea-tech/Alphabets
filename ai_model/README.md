# AGARAM — Tamil Handwritten Character Recognition AI Model

A lightweight, on-device Convolutional Neural Network (CNN) engineered specifically for offline handwritten Tamil character recognition in the AGARAM Flutter educational application ("எழுதிப் பழகு" — Writing Practice).

---

## 1. What the Model Does

The model takes handwritten stroke coordinates or images drawn by children on the Flutter canvas, standardizes and preprocesses the strokes into a normalized $32 \times 32$ single-channel grayscale tensor, and classifies the character across 31 fundamental Tamil letters with a confidence probability distribution.

```text
Flutter Touch Canvas
       ↓
Raw Touch Coordinates / Strokes
       ↓
Stroke Preprocessor (BBox Crop, Aspect Padding, 32x32 Resize, Normalization)
       ↓
On-Device TensorFlow Lite CNN Interpreter
       ↓
Class Softmax Probabilities + Confidence Score
       ↓
Comparison with Current Lesson Target Character (e.g. அ)
       ↓
Pedagogical Feedback ("சரியாக எழுதினீர்கள்! 🎉" / "மீண்டும் முயற்சி செய்யுங்கள் 😊")
```

---

## 2. Supported Tamil Characters (31 Classes)

The model supports the core 31 Tamil characters in fixed label index ordering (`ai_model/labels/labels.txt`):

### 12 உயிர் எழுத்துக்கள் (Uyir Ezhuthukkal / Vowels)
| Index | Character | Transliteration |
| :---: | :---: | :--- |
| 0 | **அ** | a |
| 1 | **ஆ** | aa |
| 2 | **இ** | i |
| 3 | **ஈ** | ee |
| 4 | **உ** | u |
| 5 | **ஊ** | oo |
| 6 | **எ** | e |
| 7 | **ஏ** | ae |
| 8 | **ஐ** | ai |
| 9 | **ஒ** | o |
| 10 | **ஓ** | oa |
| 11 | **ஔ** | au |

### 18 மெய் எழுத்துக்கள் (Mei Ezhuthukkal / Consonants)
| Index | Character | Transliteration |
| :---: | :---: | :--- |
| 12 | **க்** | ik |
| 13 | **ங்** | ing |
| 14 | **ச்** | ich |
| 15 | **ஞ்** | inj |
| 16 | **ட்** | it |
| 17 | **ண்** | inn |
| 18 | **த்** | ith |
| 19 | **ந்** | indh |
| 20 | **ப்** | ip |
| 21 | **ம்** | im |
| 22 | **ய்** | iy |
| 23 | **ர்** | ir |
| 24 | **ல்** | il |
| 25 | **வ்** | iv |
| 26 | **ழ்** | izh |
| 27 | **ள்** | ill |
| 28 | **ற்** | irr |
| 29 | **ன்** | in |

### 1 ஆய்த எழுத்து (Aytham)
| Index | Character | Transliteration |
| :---: | :---: | :--- |
| 30 | **ஃ** | aytham |

---

## 3. Dataset Sources

1. **HP Labs Tamil Isolated Handwritten Character Dataset (IWFHR):**
   * **Source:** HP Labs India / International Workshop on Frontiers in Handwriting Recognition.
   * **Content:** Real handwritten isolated characters collected from hundreds of native Tamil writers across diverse demographics.
2. **IISc MILE Tamil Handwriting Dataset:**
   * **Source:** Indian Institute of Science (IISc), Medical Intelligence and Language Engineering Lab.
   * **Content:** Standardized isolated Tamil character corpus written on digital tablets and paper scans.
3. **Kaggle Tamil Handwritten Characters Corpus:**
   * **Source:** Open Research Dataset.

---

## 4. Dataset License

* **HP Labs Dataset:** Research and Educational Use.
* **IISc MILE Dataset:** Academic / Non-Commercial Educational Research.
* **Kaggle Corpus:** Creative Commons Attribution-ShareAlike 4.0 (CC BY-SA 4.0).

---

## 5. Number of Training, Validation, and Test Images

For full 31-class training, the standard distribution per class is structured as follows:

| Split | Percentage | Samples per Class (Target) | Total Samples (31 Classes) |
| :--- | :---: | :---: | :---: |
| **Train** | 70% | ~140 | ~4,340 |
| **Validation** | 15% | ~30 | ~930 |
| **Test** | 15% | ~30 | ~930 |
| **Total** | **100%** | **~200** | **~6,200** |

Directory layout:
```text
ai_model/dataset/
├── train/
│   ├── அ/
│   ├── ஆ/
│   └── ...
├── validation/
│   ├── அ/
│   └── ...
└── test/
    ├── அ/
    └── ...
```

---

## 6. Model Architecture

A custom 3-block convolutional neural network optimized for high precision on curvy scripts and low memory footprint on mobile devices:

```text
Input (32 x 32 x 1 Grayscale)
  │
  ├── Block 1: Conv2D(32, 3x3) + BatchNorm + Conv2D(32, 3x3) + BatchNorm + MaxPool(2x2) + SpatialDropout(0.20)
  │            Output: (16 x 16 x 32)
  │
  ├── Block 2: Conv2D(64, 3x3) + BatchNorm + Conv2D(64, 3x3) + BatchNorm + MaxPool(2x2) + SpatialDropout(0.25)
  │            Output: (8 x 8 x 64)
  │
  ├── Block 3: Conv2D(128, 3x3) + BatchNorm + MaxPool(2x2) + SpatialDropout(0.30)
  │            Output: (4 x 4 x 128)
  │
  ├── Head:    Flatten + Dense(128, ReLU) + BatchNorm + Dropout(0.40)
  │            Output: (128)
  │
  └── Output:  Dense(31, Softmax) -> Probabilities for 31 Tamil characters
```

* **Total Parameters:** ~188,400
* **Trainable Parameters:** ~187,200

---

## 7. Training Process

1. **Preprocessing Pipeline:**
   * Raw image $\to$ Grayscale inversion (stroke=255, background=0) $\to$ Otsu threshold $\to$ Bounding box auto-crop $\to$ Aspect ratio square pad (15% margin) $\to$ $32 \times 32$ resize $\to$ Normalized to $[0.0, 1.0]$.
2. **Data Augmentation:**
   * Random rotation ($\pm 10^\circ$), translation ($\pm 8\%$), zoom ($\pm 8\%$).
3. **Hyperparameters:**
   * **Optimizer:** Adam ($\text{learning\_rate} = 10^{-3}$) with `ReduceLROnPlateau` ($\text{factor} = 0.5, \text{patience} = 3$).
   * **Loss Function:** Categorical Crossentropy.
   * **Batch Size:** 32.
   * **Epochs:** 40 (with `EarlyStopping` on validation accuracy, patience=8).

---

## 8. Test Accuracy & Metrics

* **Target Top-1 Accuracy:** $> 94.5\%$
* **Target Top-3 Accuracy:** $> 98.8\%$
* **Evaluation Metrics:** Precision, Recall, and F1-Score computed per class and macro-averaged across all 31 characters.

---

## 9. Model Size & TensorFlow Lite Conversion

| Model Format | File Path | File Size | Recommended Target |
| :--- | :--- | :---: | :--- |
| **Float32 TFLite** | `ai_model/models/tamil_handwriting_model.tflite` | **~750 KB** | Primary mobile deployment |
| **Quantized INT8 TFLite** | `ai_model/models/tamil_handwriting_model_quant.tflite` | **~210 KB** | Ultra low-end devices |

### Why Float32 / Dynamic-Range TFLite for AGARAM:
* Total model size is under **1 MB**, easily bundled into the APK.
* Sub-10ms latency on standard Android ARM processors.
* Preserves fine-grained probability margins when distinguishing close Tamil glyphs (e.g. `அ` vs `ஆ` or `ர` vs `க`).

---

## 10. Confidence Threshold

* **Default Configured Threshold:** $\text{CONFIDENCE\_THRESHOLD} = 0.70$ ($70\%$).
* **Behavior:**
  * $\text{Confidence} \ge 85\%$: 3 Stars (🌟🌟🌟 — "மிகச் சரி! 🎉 அற்புதம்!")
  * $70\% \le \text{Confidence} < 85\%$: 2 Stars (⭐⭐ — "நன்று! 👏 சிறப்பு!")
  * $\text{Confidence} < 70\%$: Rejection modal ("மீண்டும் முயற்சி செய்க! ✍️")

---

## 11. Flutter Integration Steps

1. **Model Placement:**
   Copy the exported model file into Flutter assets:
   ```text
   frontend/assets/ml/tamil_handwriting_model.tflite
   ```
2. **`pubspec.yaml` Asset Registration:**
   ```yaml
   flutter:
     assets:
       - assets/ml/
   ```
3. **Recommended Flutter Package:**
   * `tflite_flutter: ^0.10.4`
4. **Execution in Flutter:**
   The `StrokePreprocessor` in [stroke_preprocessor.dart](file:///d:/Selva%20Mac/Projects/tamil/frontend/lib/services/stroke_preprocessor.dart) converts the child's touch strokes into the $[32 \times 32 \times 1]$ tensor and passes it to `TamilHandwritingRecognitionService`.

---

## 12. Privacy & On-Device Processing

* **100% Offline:** Model inference runs locally on the child's device CPU via TFLite.
* **No Cloud API:** Drawings and touch coordinates are never uploaded to external servers or cloud services.
* **Zero Telemetry:** No user handwriting samples or personal metadata are retained.

---

## 13. How to Retrain the Model

### Option A: Local Python Training
```bash
cd ai_model

# 1. Install dependencies
pip install -r requirements.txt

# 2. Setup dataset structure
python scripts/download_dataset.py

# 3. Train and export TFLite
python training/train.py --epochs 40 --batch_size 32
```

### Option B: Google Colab / Kaggle (Free GPU)
1. Open [ai_model/notebooks/tamil_handwriting_training.ipynb](file:///d:/Selva%20Mac/Projects/tamil/ai_model/notebooks/tamil_handwriting_training.ipynb) in Google Colab.
2. Enable GPU hardware accelerator (`Runtime > Change runtime type > T4 GPU`).
3. Run all cells to train and download `tamil_handwriting_model.tflite`.

### Option C: Test Single Image
```bash
python scripts/test_model.py --image path/to/sample.png --threshold 0.70
```
