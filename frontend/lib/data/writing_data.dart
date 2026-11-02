class WritingLetterGuide {
  final String letter;
  final String categoryName;
  final int strokeCount;
  final String instruction;
  final List<String> strokeHints;
  final String sampleWord;
  final String sampleEmoji;
  final List<OffsetGuide> startingPoints;

  const WritingLetterGuide({
    required this.letter,
    required this.categoryName,
    required this.strokeCount,
    required this.instruction,
    required this.strokeHints,
    required this.sampleWord,
    required this.sampleEmoji,
    this.startingPoints = const [],
  });
}

class OffsetGuide {
  final double xRatio; // 0.0 to 1.0 relative to canvas width
  final double yRatio; // 0.0 to 1.0 relative to canvas height
  final String label;

  const OffsetGuide({
    required this.xRatio,
    required this.yRatio,
    required this.label,
  });
}

class WritingData {
  /// 5 English Vowels: A, E, I, O, U
  static const List<WritingLetterGuide> uyirGuides = [
    WritingLetterGuide(
      letter: 'A',
      categoryName: 'Vowel',
      strokeCount: 3,
      instruction: 'Trace the letter A with three strokes!',
      strokeHints: [
        '1. Slant up from bottom-left to top (/)',
        '2. Slant down from top to bottom-right (\\)',
        '3. Draw horizontal cross line across middle (—)',
      ],
      sampleWord: 'Apple',
      sampleEmoji: '🍎',
      startingPoints: [
        OffsetGuide(xRatio: 0.25, yRatio: 0.78, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.18, label: '2'),
        OffsetGuide(xRatio: 0.35, yRatio: 0.52, label: '3'),
      ],
    ),
    WritingLetterGuide(
      letter: 'E',
      categoryName: 'Vowel',
      strokeCount: 4,
      instruction: 'Trace letter E: vertical line and three bars!',
      strokeHints: [
        '1. Straight down from top to bottom (|)',
        '2. Top bar across (—)',
        '3. Middle bar across (-)',
        '4. Bottom bar across (_)',
      ],
      sampleWord: 'Eye',
      sampleEmoji: '👁️',
      startingPoints: [
        OffsetGuide(xRatio: 0.30, yRatio: 0.18, label: '1'),
        OffsetGuide(xRatio: 0.30, yRatio: 0.18, label: '2'),
        OffsetGuide(xRatio: 0.30, yRatio: 0.48, label: '3'),
        OffsetGuide(xRatio: 0.30, yRatio: 0.78, label: '4'),
      ],
    ),
    WritingLetterGuide(
      letter: 'I',
      categoryName: 'Vowel',
      strokeCount: 3,
      instruction: 'Trace letter I: vertical stand with top and bottom caps!',
      strokeHints: [
        '1. Straight vertical stem down (|)',
        '2. Top horizontal cap (—)',
        '3. Bottom horizontal base (—)',
      ],
      sampleWord: 'Ice cream',
      sampleEmoji: '🍦',
      startingPoints: [
        OffsetGuide(xRatio: 0.50, yRatio: 0.20, label: '1'),
        OffsetGuide(xRatio: 0.32, yRatio: 0.20, label: '2'),
        OffsetGuide(xRatio: 0.32, yRatio: 0.78, label: '3'),
      ],
    ),
    WritingLetterGuide(
      letter: 'O',
      categoryName: 'Vowel',
      strokeCount: 1,
      instruction: 'Trace a big smooth circle counter-clockwise!',
      strokeHints: [
        '1. Start at the top and loop all the way round (◯)',
      ],
      sampleWord: 'Orange',
      sampleEmoji: '🍊',
      startingPoints: [
        OffsetGuide(xRatio: 0.50, yRatio: 0.18, label: '1'),
      ],
    ),
    WritingLetterGuide(
      letter: 'U',
      categoryName: 'Vowel',
      strokeCount: 1,
      instruction: 'Trace letter U: curve down, round, and back up!',
      strokeHints: [
        '1. Down on the left, curve around bottom, and straight up (∪)',
      ],
      sampleWord: 'Umbrella',
      sampleEmoji: '☂️',
      startingPoints: [
        OffsetGuide(xRatio: 0.30, yRatio: 0.20, label: '1'),
      ],
    ),
  ];

  /// 21 English Consonants: B, C, D, F, G, H, J, K, L, M, N, P, Q, R, S, T, V, W, X, Y, Z
  static const List<WritingLetterGuide> meiGuides = [
    WritingLetterGuide(
      letter: 'B',
      categoryName: 'Consonant',
      strokeCount: 3,
      instruction: 'Trace letter B: straight down line and two round curves!',
      strokeHints: ['1. Down (|)', '2. Top bump (⊃)', '3. Bottom bump (⊃)'],
      sampleWord: 'Ball',
      sampleEmoji: '⚽',
      startingPoints: [
        OffsetGuide(xRatio: 0.30, yRatio: 0.18, label: '1'),
        OffsetGuide(xRatio: 0.30, yRatio: 0.18, label: '2'),
        OffsetGuide(xRatio: 0.30, yRatio: 0.48, label: '3'),
      ],
    ),
    WritingLetterGuide(
      letter: 'C',
      categoryName: 'Consonant',
      strokeCount: 1,
      instruction: 'Trace letter C: smooth open curve to the right!',
      strokeHints: ['1. Loop from top right down and curve bottom (⊂)'],
      sampleWord: 'Camel',
      sampleEmoji: '🐪',
      startingPoints: [
        OffsetGuide(xRatio: 0.70, yRatio: 0.24, label: '1'),
      ],
    ),
    WritingLetterGuide(
      letter: 'D',
      categoryName: 'Consonant',
      strokeCount: 2,
      instruction: 'Trace letter D: straight line and big belly curve!',
      strokeHints: ['1. Straight down (|)', '2. Big round curve right (⊃)'],
      sampleWord: 'Dog',
      sampleEmoji: '🐶',
      startingPoints: [
        OffsetGuide(xRatio: 0.30, yRatio: 0.18, label: '1'),
        OffsetGuide(xRatio: 0.30, yRatio: 0.18, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'F',
      categoryName: 'Consonant',
      strokeCount: 3,
      instruction: 'Trace letter F: stem down and two arms across!',
      strokeHints: ['1. Straight down (|)', '2. Top bar (—)', '3. Middle bar (-)'],
      sampleWord: 'Fish',
      sampleEmoji: '🐟',
      startingPoints: [
        OffsetGuide(xRatio: 0.30, yRatio: 0.18, label: '1'),
        OffsetGuide(xRatio: 0.30, yRatio: 0.18, label: '2'),
        OffsetGuide(xRatio: 0.30, yRatio: 0.48, label: '3'),
      ],
    ),
    WritingLetterGuide(
      letter: 'G',
      categoryName: 'Consonant',
      strokeCount: 2,
      instruction: 'Trace letter G: curve like C and add middle shelf!',
      strokeHints: ['1. Curve around like C', '2. Draw bar inward to middle'],
      sampleWord: 'Grape',
      sampleEmoji: '🍇',
      startingPoints: [
        OffsetGuide(xRatio: 0.70, yRatio: 0.24, label: '1'),
        OffsetGuide(xRatio: 0.70, yRatio: 0.54, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'H',
      categoryName: 'Consonant',
      strokeCount: 3,
      instruction: 'Trace letter H: two tall stems and a bridge!',
      strokeHints: ['1. Left vertical (|)', '2. Right vertical (|)', '3. Middle bridge (—)'],
      sampleWord: 'Hat',
      sampleEmoji: '🎩',
      startingPoints: [
        OffsetGuide(xRatio: 0.30, yRatio: 0.18, label: '1'),
        OffsetGuide(xRatio: 0.70, yRatio: 0.18, label: '2'),
        OffsetGuide(xRatio: 0.30, yRatio: 0.48, label: '3'),
      ],
    ),
    WritingLetterGuide(
      letter: 'J',
      categoryName: 'Consonant',
      strokeCount: 2,
      instruction: 'Trace letter J: stem curving at bottom like a hook!',
      strokeHints: ['1. Down and hook left (J)', '2. Top hat (—)'],
      sampleWord: 'Jug',
      sampleEmoji: '🫖',
      startingPoints: [
        OffsetGuide(xRatio: 0.55, yRatio: 0.20, label: '1'),
        OffsetGuide(xRatio: 0.35, yRatio: 0.20, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'K',
      categoryName: 'Consonant',
      strokeCount: 3,
      instruction: 'Trace letter K: straight stem and kicking legs!',
      strokeHints: ['1. Stem down (|)', '2. Kick up (/ )', '3. Kick down (\\)'],
      sampleWord: 'Kite',
      sampleEmoji: '🪁',
      startingPoints: [
        OffsetGuide(xRatio: 0.30, yRatio: 0.18, label: '1'),
        OffsetGuide(xRatio: 0.70, yRatio: 0.24, label: '2'),
        OffsetGuide(xRatio: 0.45, yRatio: 0.48, label: '3'),
      ],
    ),
    WritingLetterGuide(
      letter: 'L',
      categoryName: 'Consonant',
      strokeCount: 2,
      instruction: 'Trace letter L: straight down and foot right!',
      strokeHints: ['1. Straight down (|)', '2. Flat foot across (_)'],
      sampleWord: 'Lion',
      sampleEmoji: '🦁',
      startingPoints: [
        OffsetGuide(xRatio: 0.32, yRatio: 0.18, label: '1'),
        OffsetGuide(xRatio: 0.32, yRatio: 0.78, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'M',
      categoryName: 'Consonant',
      strokeCount: 4,
      instruction: 'Trace letter M: two peaks like mountains!',
      strokeHints: ['1. Left up/down', '2. Slant to middle', '3. Slant up', '4. Right down'],
      sampleWord: 'Monkey',
      sampleEmoji: '🐒',
      startingPoints: [
        OffsetGuide(xRatio: 0.25, yRatio: 0.78, label: '1'),
        OffsetGuide(xRatio: 0.25, yRatio: 0.18, label: '2'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.55, label: '3'),
        OffsetGuide(xRatio: 0.75, yRatio: 0.18, label: '4'),
      ],
    ),
    WritingLetterGuide(
      letter: 'N',
      categoryName: 'Consonant',
      strokeCount: 3,
      instruction: 'Trace letter N: up, diagonal down, straight up!',
      strokeHints: ['1. Left line (|)', '2. Diagonal (\\)', '3. Right line (|)'],
      sampleWord: 'Nest',
      sampleEmoji: '🪺',
      startingPoints: [
        OffsetGuide(xRatio: 0.28, yRatio: 0.78, label: '1'),
        OffsetGuide(xRatio: 0.28, yRatio: 0.18, label: '2'),
        OffsetGuide(xRatio: 0.72, yRatio: 0.78, label: '3'),
      ],
    ),
    WritingLetterGuide(
      letter: 'P',
      categoryName: 'Consonant',
      strokeCount: 2,
      instruction: 'Trace letter P: vertical stem and top balloon curve!',
      strokeHints: ['1. Down (|)', '2. Top curve (⊃)'],
      sampleWord: 'Penguin',
      sampleEmoji: '🐧',
      startingPoints: [
        OffsetGuide(xRatio: 0.32, yRatio: 0.18, label: '1'),
        OffsetGuide(xRatio: 0.32, yRatio: 0.18, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'Q',
      categoryName: 'Consonant',
      strokeCount: 2,
      instruction: 'Trace letter Q: circle O with a little slant tail!',
      strokeHints: ['1. Circle O (◯)', '2. Little tail slant (\\)'],
      sampleWord: 'Queen',
      sampleEmoji: '👑',
      startingPoints: [
        OffsetGuide(xRatio: 0.50, yRatio: 0.18, label: '1'),
        OffsetGuide(xRatio: 0.58, yRatio: 0.65, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'R',
      categoryName: 'Consonant',
      strokeCount: 3,
      instruction: 'Trace letter R: stem, loop, and kick leg!',
      strokeHints: ['1. Down (|)', '2. Top loop (⊃)', '3. Kick leg (\\)'],
      sampleWord: 'Rabbit',
      sampleEmoji: '🐰',
      startingPoints: [
        OffsetGuide(xRatio: 0.30, yRatio: 0.18, label: '1'),
        OffsetGuide(xRatio: 0.30, yRatio: 0.18, label: '2'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.48, label: '3'),
      ],
    ),
    WritingLetterGuide(
      letter: 'S',
      categoryName: 'Consonant',
      strokeCount: 1,
      instruction: 'Trace letter S: slither like a snake from top to bottom!',
      strokeHints: ['1. Curve left, across middle right, curve bottom left (S)'],
      sampleWord: 'Sun',
      sampleEmoji: '☀️',
      startingPoints: [
        OffsetGuide(xRatio: 0.68, yRatio: 0.25, label: '1'),
      ],
    ),
    WritingLetterGuide(
      letter: 'T',
      categoryName: 'Consonant',
      strokeCount: 2,
      instruction: 'Trace letter T: top bar and straight center stem!',
      strokeHints: ['1. Top bar across (—)', '2. Center stem down (|)'],
      sampleWord: 'Tiger',
      sampleEmoji: '🐯',
      startingPoints: [
        OffsetGuide(xRatio: 0.25, yRatio: 0.18, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.18, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'V',
      categoryName: 'Consonant',
      strokeCount: 2,
      instruction: 'Trace letter V: slant down left, slant up right!',
      strokeHints: ['1. Slant down (\\)', '2. Slant up (/)'],
      sampleWord: 'Van',
      sampleEmoji: '🚐',
      startingPoints: [
        OffsetGuide(xRatio: 0.28, yRatio: 0.18, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.78, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'W',
      categoryName: 'Consonant',
      strokeCount: 4,
      instruction: 'Trace letter W: zigzag double V!',
      strokeHints: ['1. Down', '2. Up', '3. Down', '4. Up'],
      sampleWord: 'Watermelon',
      sampleEmoji: '🍉',
      startingPoints: [
        OffsetGuide(xRatio: 0.20, yRatio: 0.18, label: '1'),
        OffsetGuide(xRatio: 0.38, yRatio: 0.78, label: '2'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.35, label: '3'),
        OffsetGuide(xRatio: 0.65, yRatio: 0.78, label: '4'),
      ],
    ),
    WritingLetterGuide(
      letter: 'X',
      categoryName: 'Consonant',
      strokeCount: 2,
      instruction: 'Trace letter X: cross two diagonals in the center!',
      strokeHints: ['1. Top-left to bottom-right (\\)', '2. Top-right to bottom-left (/)'],
      sampleWord: 'Xylophone',
      sampleEmoji: '🎶',
      startingPoints: [
        OffsetGuide(xRatio: 0.30, yRatio: 0.18, label: '1'),
        OffsetGuide(xRatio: 0.70, yRatio: 0.18, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'Y',
      categoryName: 'Consonant',
      strokeCount: 2,
      instruction: 'Trace letter Y: small v shape on top of a stand!',
      strokeHints: ['1. Short slant right (\\)', '2. Long slant left (/)'],
      sampleWord: 'Yo-yo',
      sampleEmoji: '🪀',
      startingPoints: [
        OffsetGuide(xRatio: 0.30, yRatio: 0.18, label: '1'),
        OffsetGuide(xRatio: 0.70, yRatio: 0.18, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'Z',
      categoryName: 'Consonant',
      strokeCount: 3,
      instruction: 'Trace letter Z: top bar, slant down left, bottom bar!',
      strokeHints: ['1. Top bar across (—)', '2. Diagonal slant down (/ )', '3. Bottom bar across (—)'],
      sampleWord: 'Zebra',
      sampleEmoji: '🦓',
      startingPoints: [
        OffsetGuide(xRatio: 0.30, yRatio: 0.18, label: '1'),
        OffsetGuide(xRatio: 0.70, yRatio: 0.18, label: '2'),
        OffsetGuide(xRatio: 0.30, yRatio: 0.78, label: '3'),
      ],
    ),
  ];


  /// 26 English Lowercase / Small Letters: a to z
  static const List<WritingLetterGuide> smallLetterGuides = [
    WritingLetterGuide(
      letter: 'a',
      categoryName: 'Small Letter',
      strokeCount: 2,
      instruction: 'Trace small a: round belly first, then stem down!',
      strokeHints: ['1. Curve counter-clockwise around the circle (c)', '2. Slide straight down on the right (|)'],
      sampleWord: 'apple',
      sampleEmoji: '🍎',
      startingPoints: [
        OffsetGuide(xRatio: 0.64, yRatio: 0.48, label: '1'),
        OffsetGuide(xRatio: 0.64, yRatio: 0.44, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'b',
      categoryName: 'Small Letter',
      strokeCount: 2,
      instruction: 'Trace small b: tall stem down, then curve out right!',
      strokeHints: ['1. Slide down from top line (|)', '2. Curve out to the right and down (⊃)'],
      sampleWord: 'ball',
      sampleEmoji: '⚽',
      startingPoints: [
        OffsetGuide(xRatio: 0.32, yRatio: 0.16, label: '1'),
        OffsetGuide(xRatio: 0.32, yRatio: 0.46, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'c',
      categoryName: 'Small Letter',
      strokeCount: 1,
      instruction: 'Trace small c: curve around counter-clockwise!',
      strokeHints: ['1. Curve counter-clockwise from top-right to bottom (⊂)'],
      sampleWord: 'camel',
      sampleEmoji: '🐪',
      startingPoints: [
        OffsetGuide(xRatio: 0.68, yRatio: 0.48, label: '1'),
      ],
    ),
    WritingLetterGuide(
      letter: 'd',
      categoryName: 'Small Letter',
      strokeCount: 2,
      instruction: 'Trace small d: round belly left, then tall stem down!',
      strokeHints: ['1. Curve around left (c)', '2. Tall stem straight down on right (|)'],
      sampleWord: 'dog',
      sampleEmoji: '🐶',
      startingPoints: [
        OffsetGuide(xRatio: 0.66, yRatio: 0.48, label: '1'),
        OffsetGuide(xRatio: 0.66, yRatio: 0.16, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'e',
      categoryName: 'Small Letter',
      strokeCount: 1,
      instruction: 'Trace small e: bar across middle and loop around!',
      strokeHints: ['1. Bar across, loop up, around, and open at bottom'],
      sampleWord: 'eye',
      sampleEmoji: '👁️',
      startingPoints: [
        OffsetGuide(xRatio: 0.34, yRatio: 0.62, label: '1'),
      ],
    ),
    WritingLetterGuide(
      letter: 'f',
      categoryName: 'Small Letter',
      strokeCount: 2,
      instruction: 'Trace small f: hook over the top, then cross middle!',
      strokeHints: ['1. Hook over top and stem down (f)', '2. Crossbar across middle (—)'],
      sampleWord: 'fish',
      sampleEmoji: '🐟',
      startingPoints: [
        OffsetGuide(xRatio: 0.64, yRatio: 0.22, label: '1'),
        OffsetGuide(xRatio: 0.30, yRatio: 0.46, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'g',
      categoryName: 'Small Letter',
      strokeCount: 2,
      instruction: 'Trace small g: circle belly, then tail down and hook left!',
      strokeHints: ['1. Round belly counter-clockwise', '2. Slide down past baseline and hook left'],
      sampleWord: 'grapes',
      sampleEmoji: '🍇',
      startingPoints: [
        OffsetGuide(xRatio: 0.66, yRatio: 0.48, label: '1'),
        OffsetGuide(xRatio: 0.66, yRatio: 0.44, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'h',
      categoryName: 'Small Letter',
      strokeCount: 2,
      instruction: 'Trace small h: tall stem down, then arch over right!',
      strokeHints: ['1. Tall stem straight down (|)', '2. Arch over to right and down (∩)'],
      sampleWord: 'hen',
      sampleEmoji: '🐔',
      startingPoints: [
        OffsetGuide(xRatio: 0.32, yRatio: 0.16, label: '1'),
        OffsetGuide(xRatio: 0.32, yRatio: 0.54, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'i',
      categoryName: 'Small Letter',
      strokeCount: 2,
      instruction: 'Trace small i: short stem down, then tap a dot on top!',
      strokeHints: ['1. Short stem straight down (|)', '2. Dot on top (•)'],
      sampleWord: 'ice cream',
      sampleEmoji: '🍦',
      startingPoints: [
        OffsetGuide(xRatio: 0.50, yRatio: 0.44, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.25, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'j',
      categoryName: 'Small Letter',
      strokeCount: 2,
      instruction: 'Trace small j: stem down, hook left, and tap a dot!',
      strokeHints: ['1. Stem down past line, hook left', '2. Dot on top (•)'],
      sampleWord: 'jug',
      sampleEmoji: '🏺',
      startingPoints: [
        OffsetGuide(xRatio: 0.58, yRatio: 0.44, label: '1'),
        OffsetGuide(xRatio: 0.58, yRatio: 0.25, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'k',
      categoryName: 'Small Letter',
      strokeCount: 3,
      instruction: 'Trace small k: tall stem down, slant in, slant out!',
      strokeHints: ['1. Tall stem down (|)', '2. Slant in (/)', '3. Slant out (\)'],
      sampleWord: 'kite',
      sampleEmoji: '🪁',
      startingPoints: [
        OffsetGuide(xRatio: 0.32, yRatio: 0.16, label: '1'),
        OffsetGuide(xRatio: 0.66, yRatio: 0.48, label: '2'),
        OffsetGuide(xRatio: 0.36, yRatio: 0.65, label: '3'),
      ],
    ),
    WritingLetterGuide(
      letter: 'l',
      categoryName: 'Small Letter',
      strokeCount: 1,
      instruction: 'Trace small l: straight tall stem all the way down!',
      strokeHints: ['1. Tall vertical slide down (|)'],
      sampleWord: 'leaf',
      sampleEmoji: '🍃',
      startingPoints: [
        OffsetGuide(xRatio: 0.50, yRatio: 0.16, label: '1'),
      ],
    ),
    WritingLetterGuide(
      letter: 'm',
      categoryName: 'Small Letter',
      strokeCount: 3,
      instruction: 'Trace small m: stem down and two bouncy arches!',
      strokeHints: ['1. Short stem (|)', '2. First arch (∩)', '3. Second arch (∩)'],
      sampleWord: 'mat',
      sampleEmoji: '🧘',
      startingPoints: [
        OffsetGuide(xRatio: 0.22, yRatio: 0.44, label: '1'),
        OffsetGuide(xRatio: 0.22, yRatio: 0.54, label: '2'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.54, label: '3'),
      ],
    ),
    WritingLetterGuide(
      letter: 'n',
      categoryName: 'Small Letter',
      strokeCount: 2,
      instruction: 'Trace small n: stem down and one bouncy arch!',
      strokeHints: ['1. Short stem (|)', '2. Arch over right and down (∩)'],
      sampleWord: 'number',
      sampleEmoji: '🔢',
      startingPoints: [
        OffsetGuide(xRatio: 0.32, yRatio: 0.44, label: '1'),
        OffsetGuide(xRatio: 0.32, yRatio: 0.54, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'o',
      categoryName: 'Small Letter',
      strokeCount: 1,
      instruction: 'Trace small o: round circle counter-clockwise!',
      strokeHints: ['1. Loop all the way around (◯)'],
      sampleWord: 'orange',
      sampleEmoji: '🍊',
      startingPoints: [
        OffsetGuide(xRatio: 0.50, yRatio: 0.42, label: '1'),
      ],
    ),
    WritingLetterGuide(
      letter: 'p',
      categoryName: 'Small Letter',
      strokeCount: 2,
      instruction: 'Trace small p: tail down below line, then round belly right!',
      strokeHints: ['1. Descender stem down (|)', '2. Curve around right (⊃)'],
      sampleWord: 'parrot',
      sampleEmoji: '🦜',
      startingPoints: [
        OffsetGuide(xRatio: 0.32, yRatio: 0.44, label: '1'),
        OffsetGuide(xRatio: 0.32, yRatio: 0.48, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'q',
      categoryName: 'Small Letter',
      strokeCount: 2,
      instruction: 'Trace small q: round belly left, tail down with a flick!',
      strokeHints: ['1. Round belly counter-clockwise (c)', '2. Tail straight down with flick'],
      sampleWord: 'queen',
      sampleEmoji: '👑',
      startingPoints: [
        OffsetGuide(xRatio: 0.66, yRatio: 0.48, label: '1'),
        OffsetGuide(xRatio: 0.66, yRatio: 0.44, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'r',
      categoryName: 'Small Letter',
      strokeCount: 2,
      instruction: 'Trace small r: short stem down, then little arch branch!',
      strokeHints: ['1. Short stem (|)', '2. Little branch curve right (r)'],
      sampleWord: 'rabbit',
      sampleEmoji: '🐰',
      startingPoints: [
        OffsetGuide(xRatio: 0.34, yRatio: 0.44, label: '1'),
        OffsetGuide(xRatio: 0.34, yRatio: 0.54, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 's',
      categoryName: 'Small Letter',
      strokeCount: 1,
      instruction: 'Trace small s: little snake curve through middle!',
      strokeHints: ['1. Snake curve left, cross middle, curve right (s)'],
      sampleWord: 'ship',
      sampleEmoji: '🚢',
      startingPoints: [
        OffsetGuide(xRatio: 0.64, yRatio: 0.50, label: '1'),
      ],
    ),
    WritingLetterGuide(
      letter: 't',
      categoryName: 'Small Letter',
      strokeCount: 2,
      instruction: 'Trace small t: stem down with bottom curve, then cross!',
      strokeHints: ['1. Stem down and curve right', '2. Crossbar across middle (—)'],
      sampleWord: 'tree',
      sampleEmoji: '🌳',
      startingPoints: [
        OffsetGuide(xRatio: 0.48, yRatio: 0.26, label: '1'),
        OffsetGuide(xRatio: 0.32, yRatio: 0.44, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'u',
      categoryName: 'Small Letter',
      strokeCount: 2,
      instruction: 'Trace small u: curve down and up cup, then straight stem!',
      strokeHints: ['1. Slide down, round bottom, go up (∪)', '2. Slide straight down on right (|)'],
      sampleWord: 'umbrella',
      sampleEmoji: '☂️',
      startingPoints: [
        OffsetGuide(xRatio: 0.32, yRatio: 0.44, label: '1'),
        OffsetGuide(xRatio: 0.68, yRatio: 0.44, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'v',
      categoryName: 'Small Letter',
      strokeCount: 2,
      instruction: 'Trace small v: slant down to point, slant back up!',
      strokeHints: ['1. Slant down right (\)', '2. Slant up right (/)'],
      sampleWord: 'van',
      sampleEmoji: '🚐',
      startingPoints: [
        OffsetGuide(xRatio: 0.30, yRatio: 0.44, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.84, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'w',
      categoryName: 'Small Letter',
      strokeCount: 4,
      instruction: 'Trace small w: down, up, down, up!',
      strokeHints: ['1. Down (\)', '2. Up (/)', '3. Down (\)', '4. Up (/)'],
      sampleWord: 'wheel',
      sampleEmoji: '🛞',
      startingPoints: [
        OffsetGuide(xRatio: 0.20, yRatio: 0.44, label: '1'),
        OffsetGuide(xRatio: 0.35, yRatio: 0.84, label: '2'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.54, label: '3'),
        OffsetGuide(xRatio: 0.65, yRatio: 0.84, label: '4'),
      ],
    ),
    WritingLetterGuide(
      letter: 'x',
      categoryName: 'Small Letter',
      strokeCount: 2,
      instruction: 'Trace small x: slant down-right, slant down-left cross!',
      strokeHints: ['1. Slant down right (\)', '2. Slant down left (/)'],
      sampleWord: 'xylophone',
      sampleEmoji: '🎼',
      startingPoints: [
        OffsetGuide(xRatio: 0.32, yRatio: 0.44, label: '1'),
        OffsetGuide(xRatio: 0.68, yRatio: 0.44, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'y',
      categoryName: 'Small Letter',
      strokeCount: 2,
      instruction: 'Trace small y: short slant to center, long slant down!',
      strokeHints: ['1. Short slant down right (\)', '2. Long slant down past line (/)'],
      sampleWord: 'yo-yo',
      sampleEmoji: '🪀',
      startingPoints: [
        OffsetGuide(xRatio: 0.32, yRatio: 0.44, label: '1'),
        OffsetGuide(xRatio: 0.68, yRatio: 0.44, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'z',
      categoryName: 'Small Letter',
      strokeCount: 3,
      instruction: 'Trace small z: top bar, slant down left, bottom bar!',
      strokeHints: ['1. Top bar across (—)', '2. Slant down left (/)', '3. Bottom bar across (—)'],
      sampleWord: 'zebra',
      sampleEmoji: '🦓',
      startingPoints: [
        OffsetGuide(xRatio: 0.32, yRatio: 0.44, label: '1'),
        OffsetGuide(xRatio: 0.68, yRatio: 0.44, label: '2'),
        OffsetGuide(xRatio: 0.32, yRatio: 0.84, label: '3'),
      ],
    ),
  ];

  /// All 26 English Alphabets: A to Z combined
  static List<WritingLetterGuide> get ayuthamGuides => [
        ...uyirGuides,
        ...meiGuides,
      ]..sort((a, b) => a.letter.compareTo(b.letter));

  static List<WritingLetterGuide> get uyirmeiGuides => ayuthamGuides;

  static List<WritingLetterGuide> get allGuides => ayuthamGuides;
}
