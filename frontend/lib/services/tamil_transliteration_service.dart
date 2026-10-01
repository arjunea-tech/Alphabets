/// Service to transliterate English input text (like child's name) to beautiful Tamil script.
/// E.g. "selva" -> "செல்வா", "kavin" -> "கவின்", "priya" -> "பிரியா", "anbu" -> "அன்பு", "mithran" -> "மித்ரன்".
class TamilTransliterationService {
  TamilTransliterationService._();

  /// High-priority dictionary of popular Tamil names for instant, natural transliteration
  static final Map<String, String> _knownNames = {
    'selva': 'செல்வா',
    'selvan': 'செல்வன்',
    'selvi': 'செல்வி',
    'selvam': 'செல்வம்',
    'selvaraj': 'செல்வராஜ்',
    'chelva': 'செல்வா',
    'chelvan': 'செல்வன்',
    'chelvi': 'செல்வி',
    'kavin': 'கவின்',
    'kavya': 'காவ்யா',
    'kavi': 'கவி',
    'kavitha': 'கவிதா',
    'karthik': 'கார்த்திக்',
    'karthika': 'கார்த்திகா',
    'mithran': 'மித்ரன்',
    'mithra': 'மித்ரா',
    'kumar': 'குமார்',
    'kumaran': 'குமரன்',
    'priya': 'பிரியா',
    'anbu': 'அன்பு',
    'anbarasu': 'அன்பரசு',
    'ram': 'ராம்',
    'raam': 'ராம்',
    'raman': 'ராமன்',
    'rahul': 'ராகுல்',
    'dharun': 'தருண்',
    'tarun': 'தருண்',
    'dharani': 'தரணி',
    'dharan': 'தரன்',
    'sanjay': 'சஞ்சய்',
    'surya': 'சூர்யா',
    'soorya': 'சூர்யா',
    'vignesh': 'விக்னேஷ்',
    'vikram': 'விக்ரம்',
    'divya': 'திவ்யா',
    'deepa': 'தீபா',
    'deepak': 'தீபக்',
    'varun': 'வருண்',
    'arun': 'அருண்',
    'arjun': 'அர்ஜுன்',
    'aravind': 'அரவிந்த்',
    'nila': 'நிலா',
    'kayal': 'கயல்',
    'kayalvizhi': 'கயல்விழி',
    'mani': 'மணி',
    'murugan': 'முருகன்',
    'velan': 'வேலன்',
    'kutti': 'குட்டி',
    'kutty': 'குட்டி',
    'kuzhandhai': 'குழந்தை',
    'bala': 'பாலா',
    'balan': 'பாலன்',
    'balaji': 'பாலாஜி',
    'barath': 'பாரத்',
    'bharath': 'பாரத்',
    'bharathi': 'பாரதி',
    'bhavani': 'பவானி',
    'bhuvan': 'புவன்',
    'chandran': 'சந்திரன்',
    'charan': 'சரண்',
    'danush': 'தனுஷ்',
    'dhanush': 'தனுஷ்',
    'dinesh': 'தினேஷ்',
    'ezhil': 'எழில்',
    'ezhilarasi': 'எழிலரசி',
    'gajendran': 'கஜேந்திரன்',
    'ganesh': 'கணேஷ்',
    'gayathri': 'காயத்ரி',
    'geetha': 'கீதா',
    'gokul': 'கோகுல்',
    'gowtham': 'கௌதம்',
    'hari': 'ஹரி',
    'harish': 'ஹரிஷ்',
    'harini': 'ஹரிணி',
    'hema': 'ஹேமா',
    'ilango': 'இளங்கோ',
    'inba': 'இன்பா',
    'inban': 'இன்பன்',
    'inbavanan': 'இன்பவாணன்',
    'ishwarya': 'ஐஸ்வர்யா',
    'aishwarya': 'ஐஸ்வர்யா',
    'janani': 'ஜனனி',
    'jeeva': 'ஜீவா',
    'kala': 'கலா',
    'kamal': 'கமல்',
    'kamali': 'கமலி',
    'kannan': 'கண்ணன்',
    'krishna': 'கிருஷ்ணா',
    'lakshmi': 'லட்சுமி',
    'madhi': 'மதி',
    'madhav': 'மாதவ்',
    'madhavan': 'மாதவன்',
    'mahesh': 'மகேஷ்',
    'malini': 'மாலினி',
    'manoj': 'மனோஜ்',
    'mohan': 'மோகன்',
    'mukund': 'முகுந்த்',
    'nandhini': 'நந்தினி',
    'naveen': 'நவீன்',
    'nithya': 'நித்யா',
    'pooja': 'பூஜா',
    'prabhu': 'பிரபு',
    'prakash': 'பிரகாஷ்',
    'pranav': 'பிரணவ்',
    'prasanth': 'பிரசாந்த்',
    'prashanth': 'பிரசாந்த்',
    'praveen': 'பிரவீன்',
    'raghav': 'ராகவ்',
    'raja': 'ராஜா',
    'rajesh': 'ராஜேஷ்',
    'ramesh': 'ரமேஷ்',
    'rithvik': 'ரித்விக்',
    'rohit': 'ரோஹித்',
    'roshni': 'ரோஷ்னி',
    'sakthi': 'சக்தி',
    'sandhya': 'சந்தியா',
    'sangeetha': 'சங்கீதா',
    'sanmathi': 'சன்மதி',
    'saravanan': 'சரவணன்',
    'sathish': 'சதீஷ்',
    'satheesh': 'சதீஷ்',
    'senthamizh': 'செந்தமிழ்',
    'shankar': 'சங்கர்',
    'shanthi': 'சாந்தி',
    'shiva': 'சிவா',
    'siva': 'சிவா',
    'sneha': 'சினேகா',
    'soundarya': 'சௌந்தர்யா',
    'subash': 'சுபாஷ்',
    'sudha': 'சுதா',
    'suganya': 'சுகன்யா',
    'sujatha': 'சுஜாதா',
    'sumathi': 'சுமதி',
    'suresh': 'சுரேஷ்',
    'swathi': 'சுவாதி',
    'thamizh': 'தமிழ்',
    'tamil': 'தமிழ்',
    'thenmozhi': 'தென்மொழி',
    'uma': 'உமா',
    'usha': 'உஷா',
    'vanmathi': 'வெண்மதி',
    'vasanth': 'வசந்த்',
    'vijay': 'விஜய்',
    'vinoth': 'வினோத்',
    'vishal': 'விஷால்',
    'yamuna': 'யமுனா',
    'yazhini': 'யாழினி',
    'yuvan': 'யுவன்',
  };

  /// Transliterates text into Tamil. If already in Tamil, returns as is.
  static String toTamil(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return raw;

    // If string already contains Tamil characters and no English letters, return as is
    final hasTamil = RegExp(r'[\u0B80-\u0BFF]').hasMatch(raw);
    final hasEnglish = RegExp(r'[a-zA-Z]').hasMatch(raw);
    if (hasTamil && !hasEnglish) {
      return raw;
    }

    // Split into words to handle multi-word names like "Selva Kumar"
    final words = raw.split(RegExp(r'\s+'));
    final resultWords = <String>[];

    for (final word in words) {
      final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      if (cleanWord.isEmpty) {
        resultWords.add(word);
        continue;
      }

      // 1. Direct dictionary match
      if (_knownNames.containsKey(cleanWord)) {
        resultWords.add(_knownNames[cleanWord]!);
        continue;
      }

      // 2. Transliterate algorithmically
      resultWords.add(_phoneticToTamil(cleanWord));
    }

    return resultWords.join(' ');
  }

  /// Algorithmic English phonetic to Tamil syllabic conversion
  static String _phoneticToTamil(String word) {
    if (word.isEmpty) return '';

    final StringBuffer buffer = StringBuffer();
    int i = 0;
    final int len = word.length;

    while (i < len) {
      // 1. Check consonants at current position
      final cData = _matchConsonant(word, i);
      if (cData != null) {
        final cBase = cData.tamilBase;
        final cLen = cData.length;
        i += cLen;

        // Check if followed by vowel
        if (i < len) {
          final vData = _matchVowel(word, i);
          if (vData != null) {
            // Combine consonant + vowel sign
            buffer.write(_combineConsonantVowel(cBase, vData.vowelSign));
            i += vData.length;
          } else {
            // Consonant with pulli (e.g. க், த், ஷ்)
            buffer.write(_makeMei(cBase));
          }
        } else {
          // Word ended with consonant
          buffer.write(_makeMei(cBase));
        }
      } else {
        // Standalone vowel at beginning or after a vowel
        final vData = _matchVowel(word, i);
        if (vData != null) {
          buffer.write(vData.uyirLetter);
          i += vData.length;
        } else {
          // Unknown character, skip or preserve
          i++;
        }
      }
    }

    return buffer.toString();
  }

  static _ConsonantMatch? _matchConsonant(String text, int index) {
    final sub = text.substring(index);

    // 3-char consonants
    if (sub.startsWith('ksh')) return _ConsonantMatch('க்ஷ', 3);
    if (sub.startsWith('rra')) return _ConsonantMatch('ற', 3);
    if (sub.startsWith('nna')) return _ConsonantMatch('ண', 3);
    if (sub.startsWith('lla')) return _ConsonantMatch('ள', 3);

    // 2-char consonants
    if (sub.startsWith('zh')) return _ConsonantMatch('ழ', 2);
    if (sub.startsWith('th')) return _ConsonantMatch('த', 2);
    if (sub.startsWith('dh')) return _ConsonantMatch('த', 2);
    if (sub.startsWith('sh')) return _ConsonantMatch('ஷ', 2);
    if (sub.startsWith('ch')) return _ConsonantMatch('ச', 2);
    if (sub.startsWith('ng')) return _ConsonantMatch('ங', 2);
    if (sub.startsWith('nj')) return _ConsonantMatch('ஞ', 2);
    if (sub.startsWith('gn')) return _ConsonantMatch('ஞ', 2);
    if (sub.startsWith('kh') || sub.startsWith('gh')) return _ConsonantMatch('க', 2);
    if (sub.startsWith('ph') || sub.startsWith('bh')) return _ConsonantMatch('ப', 2);
    if (sub.startsWith('rr')) return _ConsonantMatch('ற', 2);
    if (sub.startsWith('nn')) return _ConsonantMatch('ண', 2);
    if (sub.startsWith('ll')) return _ConsonantMatch('ள', 2);

    // 1-char consonants
    final first = sub[0];
    switch (first) {
      case 'k':
      case 'g':
      case 'c':
        return _ConsonantMatch('க', 1);
      case 's':
        return _ConsonantMatch('ச', 1);
      case 'j':
        return _ConsonantMatch('ஜ', 1);
      case 't':
      case 'd':
        return _ConsonantMatch('ட', 1);
      case 'n':
        return _ConsonantMatch(sub.length == 1 ? 'ன' : 'ந', 1);
      case 'p':
      case 'b':
      case 'f':
        return _ConsonantMatch('ப', 1);
      case 'm':
        return _ConsonantMatch('ம', 1);
      case 'y':
        return _ConsonantMatch('ய', 1);
      case 'r':
        return _ConsonantMatch('ர', 1);
      case 'l':
        return _ConsonantMatch('ல', 1);
      case 'v':
      case 'w':
        return _ConsonantMatch('வ', 1);
      case 'h':
        return _ConsonantMatch('ஹ', 1);
      case 'z':
        return _ConsonantMatch('ழ', 1);
    }

    return null;
  }

  static _VowelMatch? _matchVowel(String text, int index) {
    final sub = text.substring(index);

    // 2-char vowels
    if (sub.startsWith('aa')) return _VowelMatch('ஆ', '\u0BBE', 2); // ா
    if (sub.startsWith('ee')) return _VowelMatch('ஈ', '\u0BC0', 2); // ீ
    if (sub.startsWith('ii')) return _VowelMatch('ஈ', '\u0BC0', 2); // ீ
    if (sub.startsWith('oo')) return _VowelMatch('ஊ', '\u0BC2', 2); // ூ
    if (sub.startsWith('uu')) return _VowelMatch('ஊ', '\u0BC2', 2); // ூ
    if (sub.startsWith('ae')) return _VowelMatch('ஏ', '\u0BC7', 2); // ே
    if (sub.startsWith('ai')) return _VowelMatch('ஐ', '\u0BC8', 2); // ை
    if (sub.startsWith('oa')) return _VowelMatch('ஓ', '\u0BCB', 2); // ோ
    if (sub.startsWith('au') || sub.startsWith('ou')) return _VowelMatch('ஔ', '\u0BCC', 2); // ௌ

    // 1-char vowels
    final first = sub[0];
    switch (first) {
      case 'a':
        // If at the very end of a name like "selva", "priya", "mithra", it is naturally long "ா"
        return _VowelMatch('அ', sub.length == 1 ? '\u0BBE' : '', 1);
      case 'i':
        return _VowelMatch('இ', '\u0BBF', 1); // ி
      case 'u':
        return _VowelMatch('உ', '\u0BC1', 1); // ு
      case 'e':
        return _VowelMatch('எ', '\u0BC6', 1); // ெ
      case 'o':
        return _VowelMatch('ஒ', '\u0BCA', 1); // ொ
    }

    return null;
  }

  static String _makeMei(String base) {
    return '$base\u0BCD'; // pulli
  }

  static String _combineConsonantVowel(String baseConsonant, String vowelSign) {
    if (vowelSign.isEmpty) {
      return baseConsonant; // 'a' vowel is inherent in base consonant
    }
    return '$baseConsonant$vowelSign';
  }
}

class _ConsonantMatch {
  final String tamilBase;
  final int length;
  const _ConsonantMatch(this.tamilBase, this.length);
}

class _VowelMatch {
  final String uyirLetter;
  final String vowelSign;
  final int length;
  const _VowelMatch(this.uyirLetter, this.vowelSign, this.length);
}
