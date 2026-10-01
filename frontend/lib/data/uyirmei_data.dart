import '../models/letter_model.dart';

const List<String> uyirmeiGroupBases = [
  'க்',
  'ங்',
  'ச்',
  'ஞ்',
  'ட்',
  'ண்',
  'த்',
  'ந்',
  'ப்',
  'ம்',
  'ய்',
  'ர்',
  'ல்',
  'வ்',
  'ழ்',
  'ள்',
  'ற்',
  'ன்',
];

const List<String> uyirVowelList = [
  'அ',
  'ஆ',
  'இ',
  'ஈ',
  'உ',
  'ஊ',
  'எ',
  'ஏ',
  'ஐ',
  'ஒ',
  'ஓ',
  'ஔ',
];

final Map<String, List<String>> _uyirmeiMatrix = {
  'க்': ['க', 'கா', 'கி', 'கீ', 'கு', 'கூ', 'கெ', 'கே', 'கை', 'கொ', 'கோ', 'கௌ'],
  'ங்': ['ங', 'ஙா', 'ஙி', 'ஙீ', 'ஙு', 'ஙூ', 'ஙெ', 'ஙே', 'ஙை', 'ஙொ', 'ஙோ', 'ஙௌ'],
  'ச்': ['ச', 'சா', 'சி', 'சீ', 'சு', 'சூ', 'செ', 'சே', 'சை', 'சொ', 'சோ', 'சௌ'],
  'ஞ்': ['ஞ', 'ஞா', 'ஞி', 'ஞீ', 'ஞு', 'ஞூ', 'ஞெ', 'ஞே', 'ஞை', 'ஞொ', 'ஞோ', 'ஞௌ'],
  'ட்': ['ட', 'டா', 'டி', 'டீ', 'டு', 'டூ', 'டெ', 'டே', 'டை', 'டொ', 'டோ', 'டௌ'],
  'ண்': ['ண', 'ணா', 'ணி', 'ணீ', 'ணு', 'ணூ', 'ணெ', 'ணே', 'ணை', 'ணொ', 'ணோ', 'ணௌ'],
  'த்': ['த', 'தா', 'தி', 'தீ', 'து', 'தூ', 'தெ', 'தே', 'தை', 'தொ', 'தோ', 'தௌ'],
  'ந்': ['ந', 'நா', 'நி', 'நீ', 'நு', 'நூ', 'நெ', 'நே', 'நை', 'நொ', 'நோ', 'நௌ'],
  'ப்': ['ப', 'பா', 'பி', 'பீ', 'பு', 'பூ', 'பெ', 'பே', 'பை', 'பொ', 'போ', 'பௌ'],
  'ம்': ['ம', 'மா', 'மி', 'மீ', 'மு', 'மூ', 'மெ', 'மே', 'மை', 'மொ', 'மோ', 'மௌ'],
  'ய்': ['ய', 'யா', 'யி', 'யீ', 'யு', 'யூ', 'யெ', 'யே', 'யை', 'யொ', 'யோ', 'யௌ'],
  'ர்': ['ர', 'ரா', 'ரி', 'ரீ', 'ரு', 'ரூ', 'ரெ', 'ரே', 'ரை', 'ரொ', 'ரோ', 'ரௌ'],
  'ல்': ['ல', 'லா', 'லி', 'லீ', 'லு', 'லூ', 'லெ', 'லே', 'லை', 'லொ', 'லோ', 'லௌ'],
  'வ்': ['வ', 'வா', 'வி', 'வீ', 'வு', 'வூ', 'வெ', 'வே', 'வை', 'வொ', 'வோ', 'வௌ'],
  'ழ்': ['ழ', 'ழா', 'ழி', 'ழீ', 'ழு', 'ழூ', 'ழெ', 'ழே', 'ழை', 'ழொ', 'ழோ', 'ழௌ'],
  'ள்': ['ள', 'ளா', 'ளி', 'ளீ', 'ளு', 'ளூ', 'ளெ', 'ளே', 'ளை', 'ளொ', 'ளோ', 'ளௌ'],
  'ற்': ['ற', 'றா', 'றி', 'றீ', 'று', 'றூ', 'றெ', 'றே', 'றை', 'றொ', 'றோ', 'றௌ'],
  'ன்': ['ன', 'னா', 'னி', 'னீ', 'னு', 'னூ', 'னெ', 'னே', 'னை', 'னொ', 'னோ', 'னௌ'],
};

// Words for key representative letters
final Map<String, String> _sampleWords = {
  'க': 'கண்',
  'கா': 'காக்கை',
  'கி': 'கிளி',
  'கீ': 'கீரை',
  'கு': 'குடை',
  'கூ': 'கூடு',
  'கெ': 'கெண்டை',
  'கே': 'கேடயம்',
  'கை': 'கை',
  'கொ': 'கொக்கு',
  'கோ': 'கோழி',
  'கௌ': 'கௌதாரி',
  'ச': 'சட்டை',
  'சா': 'சாவி',
  'சி': 'சிங்கம்',
  'சீ': 'சீப்பு',
  'த': 'தவளை',
  'தா': 'தாமரை',
  'தி': 'திமிங்கலம்',
  'தீ': 'தீபம்',
  'ப': 'பந்து',
  'பா': 'பால்',
  'பி': 'பிள்ளை',
  'பீ': 'பீர்க்கு',
  'ம': 'மயில்',
  'மா': 'மாம்பழம்',
  'மி': 'மிளகாய்',
  'மீ': 'மீன்',
};

final Map<String, String> _sampleImages = {
  'க': 'assets/images/eye.jpg',
  'ப': 'assets/images/ball.jpg',
  'மீ': 'assets/images/fish.jpg',
  'கோ': 'assets/images/hen.jpg',
};

final Map<String, List<LetterModel>> uyirmeiLettersMap = _generateUyirmeiMap();

Map<String, List<LetterModel>> _generateUyirmeiMap() {
  final Map<String, List<LetterModel>> result = {};

  _uyirmeiMatrix.forEach((mei, combinations) {
    final list = <LetterModel>[];
    for (int i = 0; i < combinations.length; i++) {
      final letter = combinations[i];
      final uyir = uyirVowelList[i];
      final sample = _sampleWords[letter] ?? '$mei + $uyir = $letter';

      list.add(
        LetterModel(
          id: 'uyirmei_${mei}_$i',
          letter: letter,
          type: LetterType.uyirmei,
          word: sample,
          meaning: '$mei + $uyir = $letter',
          phonetic: '$mei + $uyir',
          iconEmoji: '✨',
          imagePath: _sampleImages[letter],
          meiBase: mei,
          uyirBase: uyir,
          explanation:
              'மெய் எழுத்து ($mei) உடன் உயிர் எழுத்து ($uyir) இணையும் போது உயிர்மெய் எழுத்து "$letter" உருவாகிறது.',
        ),
      );
    }
    result[mei] = list;
  });

  return result;
}

Map<String, List<String>> get uyirmeiMatrix => _uyirmeiMatrix;

String getUyirmeiLetter(String mei, String uyir) {
  final uyirIndex = uyirVowelList.indexOf(uyir);
  if (uyirIndex != -1 && _uyirmeiMatrix.containsKey(mei)) {
    final list = _uyirmeiMatrix[mei]!;
    if (uyirIndex < list.length) {
      return list[uyirIndex];
    }
  }
  return '';
}

String getSampleWord(String uyirmei) {
  return _sampleWords[uyirmei] ?? uyirmei;
}


