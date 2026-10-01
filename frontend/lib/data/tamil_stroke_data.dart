import 'dart:ui';
import '../models/letter_stroke_model.dart';

/// Centralized repository containing verified stroke paths, directions, and validation rules for Tamil letters.
class TamilStrokeDataRepository {
  static final Map<String, TamilWritingLetter> _letters = {
    // ==========================================
    // 1. உயிர் எழுத்துக்கள் (12)
    // ==========================================
    'அ': TamilWritingLetter(
      letter: 'அ',
      category: 'uyir',
      sampleWord: 'அம்மா',
      sampleEmoji: '👩‍👧',
      validationRule: const LetterValidationRule(
        requireRightVerticalStem: true,
        requireTopLeftLoop: true,
        minCoverage: 0.52,
        minPrecision: 0.48,
      ),
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: சுழி & உடம்பு ⭕',
          instruction: 'மேல் சுழியில் தொடங்கி தலை வளைத்து கீழ் நோக்கி வரவும்',
          directionHint: 'loop_cw',
          startPoint: const Offset(0.32, 0.36),
          endPoint: const Offset(0.70, 0.78),
          tolerance: 0.12,
          pathPoints: const [
            Offset(0.32, 0.36),
            Offset(0.28, 0.31),
            Offset(0.23, 0.36),
            Offset(0.27, 0.42),
            Offset(0.33, 0.39),
            Offset(0.38, 0.30),
            Offset(0.46, 0.23),
            Offset(0.55, 0.23),
            Offset(0.62, 0.30),
            Offset(0.61, 0.40),
            Offset(0.54, 0.48),
            Offset(0.45, 0.54),
            Offset(0.33, 0.61),
            Offset(0.26, 0.70),
            Offset(0.29, 0.78),
            Offset(0.40, 0.81),
            Offset(0.54, 0.81),
            Offset(0.70, 0.78),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: படுக்கைக் கோடு 〰️',
          instruction: 'நடுவில் இருந்து வலதுபுறம் படுக்கைக் கோடு போடவும்',
          directionHint: 'right',
          startPoint: const Offset(0.45, 0.54),
          endPoint: const Offset(0.70, 0.54),
          tolerance: 0.12,
          pathPoints: const [
            Offset(0.45, 0.54),
            Offset(0.58, 0.54),
            Offset(0.70, 0.54),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 3,
          title: 'படி 3: நேர்க்கோடு ⬇️',
          instruction: 'மேலிருந்து கீழ் நேராக நேர்க்கோடு வரையவும்',
          directionHint: 'down',
          startPoint: const Offset(0.70, 0.22),
          endPoint: const Offset(0.70, 0.80),
          tolerance: 0.12,
          pathPoints: const [
            Offset(0.70, 0.22),
            Offset(0.70, 0.54),
            Offset(0.70, 0.80),
          ],
        ),
      ],
    ),

    'ஆ': const TamilWritingLetter(
      letter: 'ஆ',
      category: 'uyir',
      sampleWord: 'ஆடு',
      sampleEmoji: '🐐',
      validationRule: LetterValidationRule(
        requireRightVerticalStem: true,
        requireTopLeftLoop: true,
        minCoverage: 0.52,
        minPrecision: 0.48,
      ),
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: அ உடல் ⭕',
          instruction: 'அ எழுத்தைப் போல சுழித்து வளைக்கவும்',
          directionHint: 'loop_cw',
          startPoint: Offset(0.38, 0.38),
          pathPoints: [
            Offset(0.38, 0.38),
            Offset(0.34, 0.32),
            Offset(0.28, 0.36),
            Offset(0.34, 0.44),
            Offset(0.46, 0.34),
            Offset(0.56, 0.36),
            Offset(0.58, 0.44),
            Offset(0.48, 0.54),
            Offset(0.36, 0.64),
            Offset(0.37, 0.74),
            Offset(0.48, 0.78),
            Offset(0.60, 0.78),
            Offset(0.70, 0.78),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: படுக்கைக் கோடு 〰️',
          instruction: 'நடுவில் படுக்கைக் கோடு போடவும்',
          directionHint: 'right',
          startPoint: Offset(0.46, 0.54),
          pathPoints: [
            Offset(0.46, 0.54),
            Offset(0.70, 0.54),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 3,
          title: 'படி 3: கீழ் சுழி வளையம் 🔄',
          instruction: 'நேர்க்கோடு வரைந்து கீழே சுழித்து முடிக்கவும்',
          directionHint: 'down_loop',
          startPoint: Offset(0.70, 0.28),
          pathPoints: [
            Offset(0.70, 0.28),
            Offset(0.70, 0.76),
            Offset(0.72, 0.86),
            Offset(0.82, 0.86),
            Offset(0.84, 0.76),
            Offset(0.74, 0.74),
          ],
        ),
      ],
    ),

    'இ': const TamilWritingLetter(
      letter: 'இ',
      category: 'uyir',
      sampleWord: 'இலை',
      sampleEmoji: '🍃',
      validationRule: LetterValidationRule(
        requireBottomWave: true,
        minCoverage: 0.50,
        minPrecision: 0.45,
      ),
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: மேல் சுழி ⭕',
          instruction: 'மேல் சுழியில் தொடங்கி தலை வளைக்கவும்',
          directionHint: 'loop_cw',
          startPoint: Offset(0.38, 0.34),
          pathPoints: [
            Offset(0.38, 0.34),
            Offset(0.32, 0.30),
            Offset(0.30, 0.38),
            Offset(0.40, 0.42),
            Offset(0.52, 0.32),
            Offset(0.64, 0.34),
            Offset(0.64, 0.44),
            Offset(0.50, 0.52),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: கீழ் சுழல் வளைவு 〰️',
          instruction: 'கீழிறங்கி உட்புறமாக அழகாக வளைத்து முடிக்கவும்',
          directionHint: 'down_wave',
          startPoint: Offset(0.50, 0.52),
          pathPoints: [
            Offset(0.50, 0.52),
            Offset(0.36, 0.60),
            Offset(0.40, 0.74),
            Offset(0.56, 0.75),
            Offset(0.68, 0.68),
            Offset(0.66, 0.55),
            Offset(0.76, 0.55),
            Offset(0.72, 0.78),
          ],
        ),
      ],
    ),

    'ஈ': const TamilWritingLetter(
      letter: 'ஈ',
      category: 'uyir',
      sampleWord: 'ஈட்டி',
      sampleEmoji: '🗡️',
      validationRule: LetterValidationRule(
        minCoverage: 0.50,
        minPrecision: 0.45,
      ),
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: இடது நேர்க்கோடு ⬇️',
          instruction: 'இடதுபுற நேர்க்கோடு மேலிருந்து கீழ் போடவும்',
          directionHint: 'down',
          startPoint: Offset(0.34, 0.28),
          pathPoints: [
            Offset(0.34, 0.28),
            Offset(0.34, 0.76),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: மேல் & வலது கோடு ➡️⬇️',
          instruction: 'மேல் படுக்கைக் கோடு மற்றும் வலது நேர்க்கோடு வரையவும்',
          directionHint: 'right_down',
          startPoint: Offset(0.34, 0.28),
          pathPoints: [
            Offset(0.34, 0.28),
            Offset(0.68, 0.28),
            Offset(0.68, 0.76),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 3,
          title: 'படி 3: உள் & வெளிப் புள்ளிகள் • •',
          instruction: 'உள்ளேயும் வெளியேயும் இரு புள்ளிகள் வைக்கவும்',
          directionHint: 'dots',
          startPoint: Offset(0.51, 0.50),
          pathPoints: [
            Offset(0.51, 0.50),
            Offset(0.82, 0.50),
          ],
        ),
      ],
    ),

    'உ': const TamilWritingLetter(
      letter: 'உ',
      category: 'uyir',
      sampleWord: 'உரல்',
      sampleEmoji: '🥣',
      validationRule: LetterValidationRule(
        requireBaseBar: true,
        minCoverage: 0.50,
        minPrecision: 0.45,
      ),
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: சுழி & கீழ் வளைவு ⭕',
          instruction: 'சுழியிட்டு கீழ் நோக்கி வளைத்து இறங்கவும்',
          directionHint: 'loop_down',
          startPoint: Offset(0.38, 0.36),
          pathPoints: [
            Offset(0.38, 0.36),
            Offset(0.32, 0.32),
            Offset(0.30, 0.40),
            Offset(0.38, 0.42),
            Offset(0.48, 0.35),
            Offset(0.58, 0.42),
            Offset(0.50, 0.56),
            Offset(0.34, 0.68),
            Offset(0.34, 0.77),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: கீழ் படுக்கைக் கோடு ➡️',
          instruction: 'கீழே நேராக படுக்கைக் கோடு வரைந்து முடிக்கவும்',
          directionHint: 'right',
          startPoint: Offset(0.34, 0.77),
          pathPoints: [
            Offset(0.34, 0.77),
            Offset(0.72, 0.77),
          ],
        ),
      ],
    ),

    'ஊ': const TamilWritingLetter(
      letter: 'ஊ',
      category: 'uyir',
      sampleWord: 'ஊஞ்சல்',
      sampleEmoji: '🎪',
      validationRule: LetterValidationRule(
        requireBaseBar: true,
        minCoverage: 0.50,
        minPrecision: 0.45,
      ),
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: உ எழுத்து 🥣',
          instruction: 'உ எழுத்தை முதலில் எழுதவும்',
          directionHint: 'loop_right',
          startPoint: Offset(0.30, 0.40),
          pathPoints: [
            Offset(0.30, 0.40),
            Offset(0.24, 0.36),
            Offset(0.24, 0.44),
            Offset(0.32, 0.48),
            Offset(0.44, 0.40),
            Offset(0.50, 0.50),
            Offset(0.28, 0.68),
            Offset(0.28, 0.78),
            Offset(0.70, 0.78),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: மேல் ள துணைக்கால் 🎪',
          instruction: 'மேலே சிறிய ள எழுத்தை சுழிக்கவும்',
          directionHint: 'loop_cw',
          startPoint: Offset(0.54, 0.34),
          pathPoints: [
            Offset(0.54, 0.34),
            Offset(0.50, 0.28),
            Offset(0.58, 0.24),
            Offset(0.70, 0.24),
            Offset(0.76, 0.30),
            Offset(0.70, 0.38),
            Offset(0.58, 0.38),
            Offset(0.66, 0.46),
            Offset(0.78, 0.46),
          ],
        ),
      ],
    ),

    'எ': const TamilWritingLetter(
      letter: 'எ',
      category: 'uyir',
      sampleWord: 'எலி',
      sampleEmoji: '🐁',
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: கீழ் சுழி & மேல் வளைவு ⭕',
          instruction: 'கீழே சுழித்து மேலே ஏறி வலதுபுறம் கோடு போடவும்',
          directionHint: 'loop_up',
          startPoint: Offset(0.38, 0.54),
          pathPoints: [
            Offset(0.38, 0.54),
            Offset(0.32, 0.50),
            Offset(0.32, 0.58),
            Offset(0.40, 0.58),
            Offset(0.42, 0.30),
            Offset(0.68, 0.30),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: வலது நேர்க்கோடு ⬇️',
          instruction: 'வலதுபுறம் மேலிருந்து கீழ் நேர்க்கோடு போடவும்',
          directionHint: 'down',
          startPoint: Offset(0.68, 0.30),
          pathPoints: [
            Offset(0.68, 0.30),
            Offset(0.68, 0.76),
          ],
        ),
      ],
    ),

    'ஏ': const TamilWritingLetter(
      letter: 'ஏ',
      category: 'uyir',
      sampleWord: 'ஏணி',
      sampleEmoji: '🪜',
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: எ உடல் ⭕',
          instruction: 'எ எழுத்தைப் போல எழுதவும்',
          directionHint: 'loop_up',
          startPoint: Offset(0.38, 0.54),
          pathPoints: [
            Offset(0.38, 0.54),
            Offset(0.32, 0.50),
            Offset(0.32, 0.58),
            Offset(0.40, 0.58),
            Offset(0.42, 0.30),
            Offset(0.68, 0.30),
            Offset(0.68, 0.76),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: சாய்வுக்கோடு ↙️',
          instruction: 'கீழே இடதுபுறமாக சாய்வுக்கோடு இழுக்கவும்',
          directionHint: 'down_left',
          startPoint: Offset(0.38, 0.58),
          pathPoints: [
            Offset(0.38, 0.58),
            Offset(0.24, 0.80),
          ],
        ),
      ],
    ),

    'ஐ': const TamilWritingLetter(
      letter: 'ஐ',
      category: 'uyir',
      sampleWord: 'ஐந்து',
      sampleEmoji: '🖐️',
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: இடது இரட்டைச் சுழி ⭕⭕',
          instruction: 'இரட்டை சுழி வளைவை வரையவும்',
          directionHint: 'loops',
          startPoint: Offset(0.30, 0.36),
          pathPoints: [
            Offset(0.30, 0.36),
            Offset(0.24, 0.32),
            Offset(0.24, 0.40),
            Offset(0.32, 0.42),
            Offset(0.24, 0.52),
            Offset(0.30, 0.56),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: நடு & வலது வளைவுகள் 〰️',
          instruction: 'நடுவில் ஏறி வலதுபுறம் இறங்கி வளைத்து முடிக்கவும்',
          directionHint: 'wave',
          startPoint: Offset(0.30, 0.56),
          pathPoints: [
            Offset(0.30, 0.56),
            Offset(0.44, 0.40),
            Offset(0.58, 0.40),
            Offset(0.68, 0.48),
            Offset(0.56, 0.72),
            Offset(0.72, 0.72),
            Offset(0.76, 0.60),
          ],
        ),
      ],
    ),

    'ஒ': const TamilWritingLetter(
      letter: 'ஒ',
      category: 'uyir',
      sampleWord: 'ஒட்டகம்',
      sampleEmoji: '🐫',
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: மேல் சுழி & தலை ⭕',
          instruction: 'மேல் சுழியில் தொடங்கி தலை வளைத்து நடுவில் வரவும்',
          directionHint: 'loop_cw',
          startPoint: Offset(0.38, 0.36),
          pathPoints: [
            Offset(0.38, 0.36),
            Offset(0.32, 0.32),
            Offset(0.30, 0.40),
            Offset(0.38, 0.42),
            Offset(0.50, 0.34),
            Offset(0.62, 0.40),
            Offset(0.56, 0.54),
            Offset(0.40, 0.58),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: கீழ் சுழி & வால் 〰️',
          instruction: 'கீழே சுழித்து வலதுபுறம் ஏறி முடிக்கவும்',
          directionHint: 'loop_up',
          startPoint: Offset(0.40, 0.58),
          pathPoints: [
            Offset(0.40, 0.58),
            Offset(0.46, 0.74),
            Offset(0.60, 0.76),
            Offset(0.72, 0.68),
            Offset(0.72, 0.56),
            Offset(0.82, 0.56),
            Offset(0.82, 0.76),
          ],
        ),
      ],
    ),

    'ஓ': const TamilWritingLetter(
      letter: 'ஓ',
      category: 'uyir',
      sampleWord: 'ஓடம்',
      sampleEmoji: '⛵',
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: ஒ உடல் ⭕',
          instruction: 'ஒ எழுத்தைப் போல மேலே சுழித்து வளைக்கவும்',
          directionHint: 'loop_cw',
          startPoint: Offset(0.38, 0.36),
          pathPoints: [
            Offset(0.38, 0.36),
            Offset(0.32, 0.32),
            Offset(0.30, 0.40),
            Offset(0.38, 0.42),
            Offset(0.50, 0.34),
            Offset(0.62, 0.40),
            Offset(0.56, 0.54),
            Offset(0.40, 0.58),
            Offset(0.46, 0.74),
            Offset(0.60, 0.76),
            Offset(0.72, 0.68),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: கீழ் சுழி வளையம் 🔄',
          instruction: 'கீழே அழகாக சுழித்து முடிக்கவும்',
          directionHint: 'loop_cw',
          startPoint: Offset(0.72, 0.68),
          pathPoints: [
            Offset(0.72, 0.68),
            Offset(0.76, 0.74),
            Offset(0.84, 0.74),
            Offset(0.84, 0.84),
            Offset(0.74, 0.84),
            Offset(0.72, 0.72),
          ],
        ),
      ],
    ),

    'ஔ': const TamilWritingLetter(
      letter: 'ஔ',
      category: 'uyir',
      sampleWord: 'ஔவையார்',
      sampleEmoji: '👵',
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: ஒ எழுத்து ⭕',
          instruction: 'ஒ எழுத்தை முதலில் எழுதவும்',
          directionHint: 'loop_cw',
          startPoint: Offset(0.28, 0.36),
          pathPoints: [
            Offset(0.28, 0.36),
            Offset(0.22, 0.32),
            Offset(0.22, 0.40),
            Offset(0.30, 0.42),
            Offset(0.40, 0.34),
            Offset(0.48, 0.40),
            Offset(0.42, 0.54),
            Offset(0.30, 0.58),
            Offset(0.34, 0.74),
            Offset(0.46, 0.76),
            Offset(0.54, 0.68),
            Offset(0.54, 0.56),
            Offset(0.62, 0.56),
            Offset(0.62, 0.76),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: ள துணைக்கால் 🎪',
          instruction: 'அருகில் ள எழுத்தை எழுதவும்',
          directionHint: 'loop_cw',
          startPoint: Offset(0.72, 0.44),
          pathPoints: [
            Offset(0.72, 0.44),
            Offset(0.68, 0.38),
            Offset(0.76, 0.34),
            Offset(0.86, 0.34),
            Offset(0.90, 0.42),
            Offset(0.84, 0.50),
            Offset(0.74, 0.50),
            Offset(0.78, 0.64),
            Offset(0.90, 0.64),
          ],
        ),
      ],
    ),

    // ==========================================
    // 2. ஆய்த எழுத்து (1)
    // ==========================================
    'ஃ': const TamilWritingLetter(
      letter: 'ஃ',
      category: 'aytham',
      sampleWord: 'எஃகு',
      sampleEmoji: '🛡️',
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: மேல் புள்ளி •',
          instruction: 'மேல் மத்தியில் புள்ளி வைக்கவும்',
          directionHint: 'dot',
          isDot: true,
          startPoint: Offset(0.50, 0.32),
          pathPoints: [Offset(0.50, 0.32)],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: கீழ் இடது புள்ளி •',
          instruction: 'கீழே இடதுபுறத்தில் புள்ளி வைக்கவும்',
          directionHint: 'dot',
          isDot: true,
          startPoint: Offset(0.36, 0.64),
          pathPoints: [Offset(0.36, 0.64)],
        ),
        LetterStrokeData(
          strokeNumber: 3,
          title: 'படி 3: கீழ் வலது புள்ளி •',
          instruction: 'கீழே வலதுபுறத்தில் புள்ளி வைக்கவும்',
          directionHint: 'dot',
          isDot: true,
          startPoint: Offset(0.64, 0.64),
          pathPoints: [Offset(0.64, 0.64)],
        ),
      ],
    ),

    // ==========================================
    // 3. மெய் எழுத்துக்கள் (18)
    // ==========================================
    'க்': const TamilWritingLetter(
      letter: 'க்',
      category: 'mei',
      sampleWord: 'கொக்கு',
      sampleEmoji: '🦩',
      validationRule: LetterValidationRule(
        requireRightVerticalStem: true,
        requireDot: true,
        minCoverage: 0.50,
      ),
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: க உடல் 🏷️',
          instruction: 'இடது கோடு, மேல் கோடு, வலது கோடு மற்றும் நடு வளைவு வரையவும்',
          directionHint: 'down_right',
          startPoint: Offset(0.34, 0.34),
          pathPoints: [
            Offset(0.34, 0.34),
            Offset(0.34, 0.76),
            Offset(0.34, 0.34),
            Offset(0.68, 0.34),
            Offset(0.68, 0.76),
            Offset(0.50, 0.55),
            Offset(0.68, 0.55),
            Offset(0.76, 0.74),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: புள்ளி •',
          instruction: 'மேலே மத்தியில் புள்ளி வைக்கவும்',
          directionHint: 'dot',
          isDot: true,
          startPoint: Offset(0.50, 0.20),
          pathPoints: [Offset(0.50, 0.20)],
        ),
      ],
    ),

    'ங்': const TamilWritingLetter(
      letter: 'ங்',
      category: 'mei',
      sampleWord: 'சிங்கம்',
      sampleEmoji: '🦁',
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: ங உடல் 📐',
          instruction: 'ங எழுத்தின் உடலை வரையவும்',
          directionHint: 'down_right',
          startPoint: Offset(0.34, 0.34),
          pathPoints: [
            Offset(0.34, 0.34),
            Offset(0.34, 0.76),
            Offset(0.34, 0.34),
            Offset(0.68, 0.34),
            Offset(0.68, 0.56),
            Offset(0.48, 0.56),
            Offset(0.48, 0.76),
            Offset(0.70, 0.76),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: புள்ளி •',
          instruction: 'மேலே புள்ளி வைக்கவும்',
          directionHint: 'dot',
          isDot: true,
          startPoint: Offset(0.50, 0.20),
          pathPoints: [Offset(0.50, 0.20)],
        ),
      ],
    ),

    'ச்': const TamilWritingLetter(
      letter: 'ச்',
      category: 'mei',
      sampleWord: 'சக்கரம்',
      sampleEmoji: '☸️',
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: ச உடல் 📐',
          instruction: 'ச எழுத்தின் வளைவை வரையவும்',
          directionHint: 'down_right',
          startPoint: Offset(0.34, 0.34),
          pathPoints: [
            Offset(0.34, 0.34),
            Offset(0.34, 0.76),
            Offset(0.34, 0.34),
            Offset(0.68, 0.34),
            Offset(0.68, 0.76),
            Offset(0.50, 0.55),
            Offset(0.74, 0.55),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: புள்ளி •',
          instruction: 'மேலே புள்ளி வைக்கவும்',
          directionHint: 'dot',
          isDot: true,
          startPoint: Offset(0.50, 0.20),
          pathPoints: [Offset(0.50, 0.20)],
        ),
      ],
    ),

    'ட்': const TamilWritingLetter(
      letter: 'ட்',
      category: 'mei',
      sampleWord: 'பட்டம்',
      sampleEmoji: '🪁',
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: ட உடல் 📐',
          instruction: 'நேர்க்கோடு வரைந்து கீழ் படுக்கைக் கோடு போடவும்',
          directionHint: 'down_right',
          startPoint: Offset(0.34, 0.34),
          pathPoints: [
            Offset(0.34, 0.34),
            Offset(0.34, 0.76),
            Offset(0.72, 0.76),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: புள்ளி •',
          instruction: 'மேலே புள்ளி வைக்கவும்',
          directionHint: 'dot',
          isDot: true,
          startPoint: Offset(0.50, 0.20),
          pathPoints: [Offset(0.50, 0.20)],
        ),
      ],
    ),

    'த்': const TamilWritingLetter(
      letter: 'த்',
      category: 'mei',
      sampleWord: 'தவளை',
      sampleEmoji: '🐸',
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: த உடல் 🏷️',
          instruction: 'த எழுத்தை அழகாக வளைத்து எழுதவும்',
          directionHint: 'down_loop',
          startPoint: Offset(0.34, 0.34),
          pathPoints: [
            Offset(0.34, 0.34),
            Offset(0.34, 0.76),
            Offset(0.34, 0.34),
            Offset(0.68, 0.34),
            Offset(0.68, 0.60),
            Offset(0.48, 0.60),
            Offset(0.48, 0.76),
            Offset(0.68, 0.76),
            Offset(0.74, 0.86),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: புள்ளி •',
          instruction: 'மேலே புள்ளி வைக்கவும்',
          directionHint: 'dot',
          isDot: true,
          startPoint: Offset(0.50, 0.20),
          pathPoints: [Offset(0.50, 0.20)],
        ),
      ],
    ),

    'ப்': const TamilWritingLetter(
      letter: 'ப்',
      category: 'mei',
      sampleWord: 'பந்து',
      sampleEmoji: '⚽',
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: ப உடல் 🥣',
          instruction: 'இடது கோடு, கீழ் கோடு மற்றும் வலது கோடு வரையவும்',
          directionHint: 'down_right_up',
          startPoint: Offset(0.34, 0.34),
          pathPoints: [
            Offset(0.34, 0.34),
            Offset(0.34, 0.76),
            Offset(0.68, 0.76),
            Offset(0.68, 0.34),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: புள்ளி •',
          instruction: 'மேலே மத்தியில் புள்ளி வைக்கவும்',
          directionHint: 'dot',
          isDot: true,
          startPoint: Offset(0.50, 0.20),
          pathPoints: [Offset(0.50, 0.20)],
        ),
      ],
    ),

    'ம்': const TamilWritingLetter(
      letter: 'ம்',
      category: 'mei',
      sampleWord: 'மரம்',
      sampleEmoji: '🌳',
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: ம உடல் 🏷️',
          instruction: 'ப வரைந்து நடுவில் படுக்கைக் கோடு மற்றும் கீழ் வளைவு போடவும்',
          directionHint: 'down_right',
          startPoint: Offset(0.34, 0.34),
          pathPoints: [
            Offset(0.34, 0.34),
            Offset(0.34, 0.76),
            Offset(0.68, 0.76),
            Offset(0.68, 0.54),
            Offset(0.40, 0.54),
            Offset(0.40, 0.76),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: புள்ளி •',
          instruction: 'மேலே புள்ளி வைக்கவும்',
          directionHint: 'dot',
          isDot: true,
          startPoint: Offset(0.50, 0.20),
          pathPoints: [Offset(0.50, 0.20)],
        ),
      ],
    ),

    'ர்': const TamilWritingLetter(
      letter: 'ர்',
      category: 'mei',
      sampleWord: 'ரயில்',
      sampleEmoji: '🚆',
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: ர உடல் ⬇️',
          instruction: 'இடது கோடு, மேல் கோடு மற்றும் நடு கோடு வரையவும்',
          directionHint: 'down_right',
          startPoint: Offset(0.34, 0.34),
          pathPoints: [
            Offset(0.34, 0.34),
            Offset(0.34, 0.76),
            Offset(0.34, 0.34),
            Offset(0.66, 0.34),
            Offset(0.66, 0.76),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: புள்ளி •',
          instruction: 'மேலே புள்ளி வைக்கவும்',
          directionHint: 'dot',
          isDot: true,
          startPoint: Offset(0.50, 0.20),
          pathPoints: [Offset(0.50, 0.20)],
        ),
      ],
    ),

    'ல்': const TamilWritingLetter(
      letter: 'ல்',
      category: 'mei',
      sampleWord: 'லட்டு',
      sampleEmoji: '🍬',
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: ல உடல் ⭕',
          instruction: 'கீழே சுழித்து மேலே ஏறி வளைக்கவும்',
          directionHint: 'loop_up',
          startPoint: Offset(0.36, 0.60),
          pathPoints: [
            Offset(0.36, 0.60),
            Offset(0.30, 0.54),
            Offset(0.30, 0.64),
            Offset(0.38, 0.64),
            Offset(0.42, 0.38),
            Offset(0.56, 0.36),
            Offset(0.68, 0.44),
            Offset(0.62, 0.76),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: புள்ளி •',
          instruction: 'மேலே புள்ளி வைக்கவும்',
          directionHint: 'dot',
          isDot: true,
          startPoint: Offset(0.50, 0.20),
          pathPoints: [Offset(0.50, 0.20)],
        ),
      ],
    ),

    'வ்': const TamilWritingLetter(
      letter: 'வ்',
      category: 'mei',
      sampleWord: 'வண்டு',
      sampleEmoji: '🐝',
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: வ உடல் ⭕',
          instruction: 'கீழே சுழித்து வலதுபுறம் ப வரைவது போல மேலே செல்லவும்',
          directionHint: 'loop_up',
          startPoint: Offset(0.34, 0.58),
          pathPoints: [
            Offset(0.34, 0.58),
            Offset(0.28, 0.52),
            Offset(0.28, 0.62),
            Offset(0.36, 0.62),
            Offset(0.40, 0.40),
            Offset(0.52, 0.38),
            Offset(0.66, 0.44),
            Offset(0.66, 0.76),
            Offset(0.40, 0.76),
          ],
        ),
        LetterStrokeData(
          strokeNumber: 2,
          title: 'படி 2: புள்ளி •',
          instruction: 'மேலே புள்ளி வைக்கவும்',
          directionHint: 'dot',
          isDot: true,
          startPoint: Offset(0.50, 0.20),
          pathPoints: [Offset(0.50, 0.20)],
        ),
      ],
    ),

    // Sample Uyirmei: 'க'
    'க': const TamilWritingLetter(
      letter: 'க',
      category: 'uyirmei',
      sampleWord: 'கண்',
      sampleEmoji: '👁️',
      validationRule: LetterValidationRule(
        requireRightVerticalStem: true,
        minCoverage: 0.50,
      ),
      strokes: [
        LetterStrokeData(
          strokeNumber: 1,
          title: 'படி 1: க உடல் 🏷️',
          instruction: 'இடது கோடு, மேல் கோடு, வலது கோடு மற்றும் நடு வளைவு வரையவும்',
          directionHint: 'down_right',
          startPoint: Offset(0.34, 0.28),
          pathPoints: [
            Offset(0.34, 0.28),
            Offset(0.34, 0.76),
            Offset(0.34, 0.28),
            Offset(0.68, 0.28),
            Offset(0.68, 0.76),
            Offset(0.50, 0.52),
            Offset(0.68, 0.52),
            Offset(0.76, 0.74),
          ],
        ),
      ],
    ),
  };

  /// Returns structured stroke data for a letter, or generates a clean fallback.
  static TamilWritingLetter getLetter(String letter) {
    if (_letters.containsKey(letter)) {
      return _letters[letter]!;
    }
    return _generateFallbackLetter(letter);
  }

  static bool hasVerifiedLetter(String letter) => _letters.containsKey(letter);

  static List<String> getAllVerifiedLetters() => _letters.keys.toList();

  static TamilWritingLetter _generateFallbackLetter(String letter) {
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
  }
}
