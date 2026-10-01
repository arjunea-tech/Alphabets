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
  static const List<WritingLetterGuide> uyirGuides = [
    WritingLetterGuide(
      letter: 'அ',
      categoryName: 'உயிர் எழுத்து',
      strokeCount: 3,
      instruction: 'அ எழுத்தை அழகாக எழுதிப் பார்ப்போம்!',
      strokeHints: [
        '1. நடுவில் சுழித்து ஆரம்பிக்கவும் (O)',
        '2. வளைத்து கீழ் நோக்கி கொண்டு வரவும் (◠)',
        '3. படுக்கைக் கோடு மற்றும் நேர்க்கோடு போடவும் (— |)',
      ],
      sampleWord: 'அம்மா',
      sampleEmoji: '👩‍👧',
      startingPoints: [
        OffsetGuide(xRatio: 0.32, yRatio: 0.36, label: '1'),
        OffsetGuide(xRatio: 0.45, yRatio: 0.54, label: '2'),
        OffsetGuide(xRatio: 0.70, yRatio: 0.22, label: '3'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ஆ',
      categoryName: 'உயிர் எழுத்து',
      strokeCount: 4,
      instruction: 'ஆ எழுத்தை சுழித்து எழுதிப் பார்ப்போம்!',
      strokeHints: [
        '1. அ எழுத்தைப் போல முதலிலில் எழுதவும்',
        '2. கீழ் வலதுபுறத்தில் அழகான கீழ் சுழி சேர்க்கவும்',
      ],
      sampleWord: 'ஆடு',
      sampleEmoji: '🐐',
      startingPoints: [
        OffsetGuide(xRatio: 0.32, yRatio: 0.32, label: '1'),
        OffsetGuide(xRatio: 0.68, yRatio: 0.25, label: '2'),
        OffsetGuide(xRatio: 0.70, yRatio: 0.75, label: '3'),
      ],
    ),
    WritingLetterGuide(
      letter: 'இ',
      categoryName: 'உயிர் எழுத்து',
      strokeCount: 3,
      instruction: 'இ எழுத்தை சுருள் வளைவாக எழுதுவோம்!',
      strokeHints: [
        '1. மேல் சுழியில் தொடங்குங்கள்',
        '2. கீழிறங்கி உட்புறமாக வளைத்து முடியுங்கள்',
      ],
      sampleWord: 'இலை',
      sampleEmoji: '🍃',
      startingPoints: [
        OffsetGuide(xRatio: 0.35, yRatio: 0.28, label: '1'),
        OffsetGuide(xRatio: 0.60, yRatio: 0.60, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ஈ',
      categoryName: 'உயிர் எழுத்து',
      strokeCount: 4,
      instruction: 'ஈ எழுத்தை நேர்க்கோடுகளுடன் எழுதுவோம்!',
      strokeHints: [
        '1. இடது நேர்க்கோடு போடவும்',
        '2. படுக்கைக் கோடு மற்றும் வலது நேர்க்கோடு',
        '3. இரண்டு புள்ளிகள் வைக்கவும்',
      ],
      sampleWord: 'ஈ',
      sampleEmoji: '🪰',
      startingPoints: [
        OffsetGuide(xRatio: 0.28, yRatio: 0.30, label: '1'),
        OffsetGuide(xRatio: 0.72, yRatio: 0.30, label: '2'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.45, label: '3'),
      ],
    ),
    WritingLetterGuide(
      letter: 'உ',
      categoryName: 'உயிர் எழுத்து',
      strokeCount: 2,
      instruction: 'உ எழுத்தை வளைத்து படுக்கைக் கோடு வரைவோம்!',
      strokeHints: [
        '1. சிறிய சுழியிட்டு வலப்புறம் வளைக்கவும்',
        '2. கீழிருந்து நேராக படுக்கைக் கோடு போடவும்',
      ],
      sampleWord: 'உரல்',
      sampleEmoji: '🥣',
      startingPoints: [
        OffsetGuide(xRatio: 0.32, yRatio: 0.35, label: '1'),
        OffsetGuide(xRatio: 0.32, yRatio: 0.72, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ஊ',
      categoryName: 'உயிர் எழுத்து',
      strokeCount: 3,
      instruction: 'உ எழுதி மேலே ள சேர்ப்போம்!',
      strokeHints: [
        '1. உ எழுத்தை முதலிலில் எழுதவும்',
        '2. மேலே சிறிய ள எழுத்தை சுழிக்கவும்',
      ],
      sampleWord: 'ஊஞ்சல்',
      sampleEmoji: '🎪',
      startingPoints: [
        OffsetGuide(xRatio: 0.28, yRatio: 0.45, label: '1'),
        OffsetGuide(xRatio: 0.65, yRatio: 0.30, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'எ',
      categoryName: 'உயிர் எழுத்து',
      strokeCount: 2,
      instruction: 'எ எழுத்தை நேர்த்தியாக எழுதுவோம்!',
      strokeHints: [
        '1. சிறிய சுழியிட்டு கீழ் இறங்கவும்',
        '2. வலப்புறம் நேர்க்கோடு வரைந்து மேலெழுப்பவும்',
      ],
      sampleWord: 'எலி',
      sampleEmoji: '🐭',
      startingPoints: [
        OffsetGuide(xRatio: 0.35, yRatio: 0.35, label: '1'),
        OffsetGuide(xRatio: 0.65, yRatio: 0.40, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ஏ',
      categoryName: 'உயிர் எழுத்து',
      strokeCount: 3,
      instruction: 'ஏ எழுத்துக்கு கீழ் சாய்வுக்கோடு சேர்ப்போம்!',
      strokeHints: [
        '1. எ எழுத்தைப் போல எழுதவும்',
        '2. கீழே சாய்வுக்கோடு போடவும்',
      ],
      sampleWord: 'ஏணி',
      sampleEmoji: '🪜',
      startingPoints: [
        OffsetGuide(xRatio: 0.35, yRatio: 0.35, label: '1'),
        OffsetGuide(xRatio: 0.35, yRatio: 0.82, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ஐ',
      categoryName: 'உயிர் எழுத்து',
      strokeCount: 3,
      instruction: 'ஐ எழுத்தை சுழன்று வளைத்து எழுதுவோம்!',
      strokeHints: [
        '1. மேல் இரு சுழிகளை இணைக்கவும்',
        '2. கீழே இறங்கி அழகாக வளைக்கவும்',
      ],
      sampleWord: 'ஐந்து',
      sampleEmoji: '🖐️',
      startingPoints: [
        OffsetGuide(xRatio: 0.30, yRatio: 0.32, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.65, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ஒ',
      categoryName: 'உயிர் எழுத்து',
      strokeCount: 3,
      instruction: 'ஒ எழுத்தை சுழித்து வளைப்போம்!',
      strokeHints: [
        '1. இடதுபுற சுழியில் தொடங்கவும்',
        '2. வலப்புறம் வளைத்து கீழே முடிக்கவும்',
      ],
      sampleWord: 'ஒட்டகம்',
      sampleEmoji: '🐪',
      startingPoints: [
        OffsetGuide(xRatio: 0.32, yRatio: 0.35, label: '1'),
        OffsetGuide(xRatio: 0.65, yRatio: 0.55, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ஓ',
      categoryName: 'உயிர் எழுத்து',
      strokeCount: 4,
      instruction: 'ஓ எழுத்தின் கீழ் அழகிய சுழி சேர்ப்போம்!',
      strokeHints: [
        '1. ஒ எழுத்தைப் போல எழுதவும்',
        '2. கீழே அழகிய சுழி வளையம் இடவும்',
      ],
      sampleWord: 'ஓடம்',
      sampleEmoji: '⛵',
      startingPoints: [
        OffsetGuide(xRatio: 0.32, yRatio: 0.35, label: '1'),
        OffsetGuide(xRatio: 0.70, yRatio: 0.78, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ஔ',
      categoryName: 'உயிர் எழுத்து',
      strokeCount: 4,
      instruction: 'ஒ எழுதி பக்கத்தில் ள சேர்ப்போம்!',
      strokeHints: [
        '1. ஒ எழுத்தை இடதுபுறம் எழுதவும்',
        '2. வலதுபுறம் ள துணைக்கால் சேர்க்கவும்',
      ],
      sampleWord: 'ஔவையார்',
      sampleEmoji: '👵',
      startingPoints: [
        OffsetGuide(xRatio: 0.25, yRatio: 0.40, label: '1'),
        OffsetGuide(xRatio: 0.65, yRatio: 0.35, label: '2'),
      ],
    ),
  ];

  static const List<WritingLetterGuide> meiGuides = [
    WritingLetterGuide(
      letter: 'க்',
      categoryName: 'மெய் எழுத்து',
      strokeCount: 4,
      instruction: 'க் எழுத்தை எழுதி மேலே புள்ளி வைப்போம்!',
      strokeHints: [
        '1. இடது நேர்க்கோடு மற்றும் படுக்கைக் கோடு',
        '2. கீழ் வளைவு',
        '3. மேலே அழகான புள்ளி இடவும்',
      ],
      sampleWord: 'சக்கரம்',
      sampleEmoji: '🎡',
      startingPoints: [
        OffsetGuide(xRatio: 0.35, yRatio: 0.35, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.18, label: '•'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ங்',
      categoryName: 'மெய் எழுத்து',
      strokeCount: 4,
      instruction: 'ங் எழுத்தை எழுதி மேலே புள்ளி வைப்போம்!',
      strokeHints: [
        '1. ங எழுத்தை முதலில் எழுதவும்',
        '2. மேலே புள்ளி வைக்கவும்',
      ],
      sampleWord: 'சங்கு',
      sampleEmoji: '🐚',
      startingPoints: [
        OffsetGuide(xRatio: 0.35, yRatio: 0.35, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.18, label: '•'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ச்',
      categoryName: 'மெய் எழுத்து',
      strokeCount: 4,
      instruction: 'ச் எழுத்தை எழுதி மேலே புள்ளி வைப்போம்!',
      strokeHints: [
        '1. ச எழுத்தை அழகாக எழுதவும்',
        '2. மேலே புள்ளி இடவும்',
      ],
      sampleWord: 'தச்சர்',
      sampleEmoji: '🪚',
      startingPoints: [
        OffsetGuide(xRatio: 0.35, yRatio: 0.35, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.18, label: '•'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ஞ்',
      categoryName: 'மெய் எழுத்து',
      strokeCount: 4,
      instruction: 'ஞ் எழுத்தை எழுதி மேலே புள்ளி வைப்போம்!',
      strokeHints: [
        '1. ஞ எழுத்தை அழகாக எழுதவும்',
        '2. மேலே புள்ளி வைக்கவும்',
      ],
      sampleWord: 'ஊஞ்சல்',
      sampleEmoji: '🎪',
      startingPoints: [
        OffsetGuide(xRatio: 0.35, yRatio: 0.35, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.18, label: '•'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ட்',
      categoryName: 'மெய் எழுத்து',
      strokeCount: 3,
      instruction: 'ட் எழுத்தை நேர்க்கோடு மற்றும் புள்ளியுடன் எழுதுவோம்!',
      strokeHints: [
        '1. மேலிருந்து கீழ் நேர்க்கோடு',
        '2. வலப்புற படுக்கைக் கோடு',
        '3. மேலே புள்ளி',
      ],
      sampleWord: 'பட்டம்',
      sampleEmoji: '🪁',
      startingPoints: [
        OffsetGuide(xRatio: 0.35, yRatio: 0.30, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.18, label: '•'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ண்',
      categoryName: 'மெய் எழுத்து',
      strokeCount: 4,
      instruction: 'மூன்று சுழி இட்டு மேலே புள்ளி வைப்போம்!',
      strokeHints: [
        '1. மூன்று சுழிகளைத் தொடர்ச்சியாக வரையவும்',
        '2. மேலே புள்ளி வைக்கவும்',
      ],
      sampleWord: 'கண்',
      sampleEmoji: '👁️',
      startingPoints: [
        OffsetGuide(xRatio: 0.25, yRatio: 0.40, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.18, label: '•'),
      ],
    ),
    WritingLetterGuide(
      letter: 'த்',
      categoryName: 'மெய் எழுத்து',
      strokeCount: 4,
      instruction: 'த் எழுத்தை எழுதி மேலே புள்ளி வைப்போம்!',
      strokeHints: [
        '1. த எழுத்தை வரையவும்',
        '2. மேலே புள்ளி வைக்கவும்',
      ],
      sampleWord: 'நத்தை',
      sampleEmoji: '🐌',
      startingPoints: [
        OffsetGuide(xRatio: 0.35, yRatio: 0.35, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.18, label: '•'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ந்',
      categoryName: 'மெய் எழுத்து',
      strokeCount: 4,
      instruction: 'ந் எழுத்தை எழுதி மேலே புள்ளி வைப்போம்!',
      strokeHints: [
        '1. ந எழுத்தை அழகாக எழுதவும்',
        '2. மேலே புள்ளி வைக்கவும்',
      ],
      sampleWord: 'பந்து',
      sampleEmoji: '⚽',
      startingPoints: [
        OffsetGuide(xRatio: 0.35, yRatio: 0.35, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.18, label: '•'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ப்',
      categoryName: 'மெய் எழுத்து',
      strokeCount: 3,
      instruction: 'ப எழுதி மேலே புள்ளி வைப்போம்!',
      strokeHints: [
        '1. இடது நேர்க்கோடு மற்றும் படுக்கைக் கோடு',
        '2. வலது நேர்க்கோடு மற்றும் புள்ளி',
      ],
      sampleWord: 'கப்பல்',
      sampleEmoji: '🚢',
      startingPoints: [
        OffsetGuide(xRatio: 0.30, yRatio: 0.32, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.18, label: '•'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ம்',
      categoryName: 'மெய் எழுத்து',
      strokeCount: 4,
      instruction: 'ம எழுதி மேலே புள்ளி வைப்போம்!',
      strokeHints: [
        '1. ம எழுத்தை வட்டமாக வளைக்கவும்',
        '2. மேலே புள்ளி வைக்கவும்',
      ],
      sampleWord: 'மரம்',
      sampleEmoji: '🌳',
      startingPoints: [
        OffsetGuide(xRatio: 0.30, yRatio: 0.32, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.18, label: '•'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ய்',
      categoryName: 'மெய் எழுத்து',
      strokeCount: 4,
      instruction: 'ய எழுதி மேலே புள்ளி வைப்போம்!',
      strokeHints: [
        '1. ய எழுத்தின் இரண்டு வளைவுகள்',
        '2. மேலே புள்ளி வைக்கவும்',
      ],
      sampleWord: 'பாய்',
      sampleEmoji: '🧺',
      startingPoints: [
        OffsetGuide(xRatio: 0.30, yRatio: 0.35, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.18, label: '•'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ர்',
      categoryName: 'மெய் எழுத்து',
      strokeCount: 3,
      instruction: 'ர எழுதி மேலே புள்ளி வைப்போம்!',
      strokeHints: [
        '1. ர எழுத்தை வரையவும்',
        '2. மேலே புள்ளி வைக்கவும்',
      ],
      sampleWord: 'ஏர்',
      sampleEmoji: '🌾',
      startingPoints: [
        OffsetGuide(xRatio: 0.35, yRatio: 0.35, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.18, label: '•'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ல்',
      categoryName: 'மெய் எழுத்து',
      strokeCount: 3,
      instruction: 'ல எழுதி மேலே புள்ளி வைப்போம்!',
      strokeHints: [
        '1. ல எழுத்தை சுழிக்கவும்',
        '2. மேலே புள்ளி வைக்கவும்',
      ],
      sampleWord: 'சேவல்',
      sampleEmoji: '🐓',
      startingPoints: [
        OffsetGuide(xRatio: 0.35, yRatio: 0.40, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.18, label: '•'),
      ],
    ),
    WritingLetterGuide(
      letter: 'வ்',
      categoryName: 'மெய் எழுத்து',
      strokeCount: 3,
      instruction: 'வ் எழுத்தை எழுதி மேலே புள்ளி வைப்போம்!',
      strokeHints: [
        '1. வ எழுத்தை சுழிக்கவும்',
        '2. மேலே புள்ளி வைக்கவும்',
      ],
      sampleWord: 'செவ்வந்தி',
      sampleEmoji: '🌼',
      startingPoints: [
        OffsetGuide(xRatio: 0.35, yRatio: 0.40, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.18, label: '•'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ழ்',
      categoryName: 'மெய் எழுத்து',
      strokeCount: 4,
      instruction: 'சிறப்பு ழ் எழுத்தை எழுதி புள்ளி வைப்போம்!',
      strokeHints: [
        '1. ழ எழுத்தை வளைத்து எழுதவும்',
        '2. மேலே புள்ளி வைக்கவும்',
      ],
      sampleWord: 'யாழ்',
      sampleEmoji: '🎻',
      startingPoints: [
        OffsetGuide(xRatio: 0.30, yRatio: 0.35, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.18, label: '•'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ள்',
      categoryName: 'மெய் எழுத்து',
      strokeCount: 4,
      instruction: 'ள் எழுத்தை எழுதி மேலே புள்ளி வைப்போம்!',
      strokeHints: [
        '1. ள எழுத்தை சுழித்து எழுதவும்',
        '2. மேலே புள்ளி வைக்கவும்',
      ],
      sampleWord: 'வாள்',
      sampleEmoji: '⚔️',
      startingPoints: [
        OffsetGuide(xRatio: 0.35, yRatio: 0.40, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.18, label: '•'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ற்',
      categoryName: 'மெய் எழுத்து',
      strokeCount: 3,
      instruction: 'ற் எழுத்தை எழுதி மேலே புள்ளி வைப்போம்!',
      strokeHints: [
        '1. ற எழுத்தை வரையவும்',
        '2. மேலே புள்ளி வைக்கவும்',
      ],
      sampleWord: 'புற்று',
      sampleEmoji: '🐜',
      startingPoints: [
        OffsetGuide(xRatio: 0.35, yRatio: 0.35, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.18, label: '•'),
      ],
    ),
    WritingLetterGuide(
      letter: 'ன்',
      categoryName: 'மெய் எழுத்து',
      strokeCount: 3,
      instruction: 'இரண்டு சுழி இட்டு புள்ளி வைப்போம்!',
      strokeHints: [
        '1. இரண்டு சுழிகளை வரையவும்',
        '2. மேலே புள்ளி வைக்கவும்',
      ],
      sampleWord: 'மீன்',
      sampleEmoji: '🐟',
      startingPoints: [
        OffsetGuide(xRatio: 0.30, yRatio: 0.40, label: '1'),
        OffsetGuide(xRatio: 0.50, yRatio: 0.18, label: '•'),
      ],
    ),
  ];

  static const List<WritingLetterGuide> ayuthamGuides = [
    WritingLetterGuide(
      letter: 'ஃ',
      categoryName: 'ஆய்த எழுத்து',
      strokeCount: 3,
      instruction: 'ஃ மூன்று புள்ளிகளை முக்கோண வடிவில் வைப்போம்!',
      strokeHints: [
        '1. மேலே ஒரு புள்ளி வைக்கவும் (•)',
        '2. கீழே இடது மற்றும் வலதுபுறத்தில் இரண்டு புள்ளிகள் வைக்கவும் (• •)',
      ],
      sampleWord: 'எஃகு',
      sampleEmoji: '⚔️',
      startingPoints: [
        OffsetGuide(xRatio: 0.50, yRatio: 0.30, label: '1'),
        OffsetGuide(xRatio: 0.35, yRatio: 0.65, label: '2'),
        OffsetGuide(xRatio: 0.65, yRatio: 0.65, label: '3'),
      ],
    ),
  ];

  static const List<WritingLetterGuide> uyirmeiSampleGuides = [
    WritingLetterGuide(
      letter: 'க',
      categoryName: 'உயிர்மெய் எழுத்து',
      strokeCount: 3,
      instruction: 'க் + அ = க எழுத்தை எழுதிப் பார்ப்போம்!',
      strokeHints: [
        '1. இடது நேர்க்கோடு மற்றும் படுக்கைக் கோடு',
        '2. கீழ் வளைவு',
      ],
      sampleWord: 'கண்',
      sampleEmoji: '👁️',
      startingPoints: [
        OffsetGuide(xRatio: 0.35, yRatio: 0.35, label: '1'),
      ],
    ),
    WritingLetterGuide(
      letter: 'கா',
      categoryName: 'உயிர்மெய் எழுத்து',
      strokeCount: 4,
      instruction: 'க எழுதி பக்கத்தில் கால் (ா) சேர்ப்போம்!',
      strokeHints: [
        '1. க எழுத்தை முதலிலில் எழுதவும்',
        '2. வலப்புறம் கால் துணைக்கால் சேர்க்கவும்',
      ],
      sampleWord: 'காகம்',
      sampleEmoji: '🦅',
      startingPoints: [
        OffsetGuide(xRatio: 0.25, yRatio: 0.35, label: '1'),
        OffsetGuide(xRatio: 0.65, yRatio: 0.35, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'கி',
      categoryName: 'உயிர்மெய் எழுத்து',
      strokeCount: 4,
      instruction: 'க எழுதி மேலே இ-சுழி சேர்ப்போம்!',
      strokeHints: [
        '1. க எழுத்தை முதலிலில் எழுதவும்',
        '2. தலையில் அழகான சுழி வளைவு இடவும்',
      ],
      sampleWord: 'கிளி',
      sampleEmoji: '🦜',
      startingPoints: [
        OffsetGuide(xRatio: 0.35, yRatio: 0.40, label: '1'),
        OffsetGuide(xRatio: 0.55, yRatio: 0.20, label: '2'),
      ],
    ),
    WritingLetterGuide(
      letter: 'கீ',
      categoryName: 'உயிர்மெய் எழுத்து',
      strokeCount: 4,
      instruction: 'க எழுதி மேலே ஈ-சுழி சேர்ப்போம்!',
      strokeHints: [
        '1. க எழுத்தை எழுதவும்',
        '2. தலையில் மேல்சுழி வளையம் போடவும்',
      ],
      sampleWord: 'கீரை',
      sampleEmoji: '🥬',
      startingPoints: [
        OffsetGuide(xRatio: 0.35, yRatio: 0.40, label: '1'),
        OffsetGuide(xRatio: 0.55, yRatio: 0.18, label: '2'),
      ],
    ),
  ];
}
