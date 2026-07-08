class Kural {
  final int number;
  final String line1;
  final String line2;
  final String translation;
  final String mv;
  final String sp;
  final String mk;
  final String explanation;
  final String couplet;
  final String transliteration1;
  final String transliteration2;

  Kural({
    required this.number,
    required this.line1,
    required this.line2,
    required this.translation,
    required this.mv,
    required this.sp,
    required this.mk,
    required this.explanation,
    required this.couplet,
    required this.transliteration1,
    required this.transliteration2,
  });

  factory Kural.fromJson(Map<String, dynamic> json) {
    return Kural(
      number: json['Number'] as int,
      line1: json['Line1'] ?? '',
      line2: json['Line2'] ?? '',
      translation: json['Translation'] ?? '',
      mv: json['mv'] ?? '',
      sp: json['sp'] ?? '',
      mk: json['mk'] ?? '',
      explanation: json['explanation'] ?? '',
      couplet: json['couplet'] ?? '',
      transliteration1: json['transliteration1'] ?? '',
      transliteration2: json['transliteration2'] ?? '',
    );
  }

  /// The two Tamil lines, concatenated for display.
  String get combinedLines => '$line1\n$line2';

  /// Fetch one of the three interpretation fields by key ('mv' | 'sp' | 'mk').
  String interpretation(String key) {
    switch (key) {
      case 'mv':
        return mv;
      case 'sp':
        return sp;
      case 'mk':
        return mk;
      default:
        return mv;
    }
  }
}
