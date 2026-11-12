enum LetterType {
  uyir,
  mei,
  aytham,
  uyirmei,
  english,
  vowel,
  consonant,
}


class LetterModel {
  final String id;
  final String letter;
  final LetterType type;
  final String word;
  final String meaning;
  final String phonetic;
  final String iconEmoji;
  final String? imagePath;
  final String? audioPath;
  final String? videoUrl;
  final String? explanation;
  final String? meiBase;
  final String? uyirBase;

  const LetterModel({
    required this.id,
    required this.letter,
    required this.type,
    required this.word,
    required this.meaning,
    required this.phonetic,
    required this.iconEmoji,
    this.imagePath,
    this.audioPath,
    this.videoUrl,
    this.explanation,
    this.meiBase,
    this.uyirBase,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'letter': letter,
        'type': type.name,
        'word': word,
        'meaning': meaning,
        'phonetic': phonetic,
        'iconEmoji': iconEmoji,
        'imagePath': imagePath,
        'audioPath': audioPath,
        'videoUrl': videoUrl,
        'explanation': explanation,
        'meiBase': meiBase,
        'uyirBase': uyirBase,
      };

  factory LetterModel.fromJson(Map<String, dynamic> json) => LetterModel(
        id: json['id'] as String,
        letter: json['letter'] as String,
        type: LetterType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => LetterType.uyir,
        ),
        word: (json['word'] ?? '') as String,
        meaning: (json['meaning'] ?? '') as String,
        phonetic: (json['phonetic'] ?? '') as String,
        iconEmoji: (json['icon_emoji'] ?? json['iconEmoji'] ?? '⭐') as String,
        imagePath: (json['image_path'] ?? json['imagePath']) as String?,
        audioPath: (json['audio_path'] ?? json['audioPath']) as String?,
        videoUrl: (json['video_url'] ?? json['videoUrl']) as String?,
        explanation: json['explanation'] as String?,
        meiBase: (json['mei_base'] ?? json['meiBase']) as String?,
        uyirBase: (json['uyir_base'] ?? json['uyirBase']) as String?,
      );
}

